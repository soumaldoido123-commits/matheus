--!nonstrict
--[[
	Grab: o servidor do "cabo de energia".
	O CLIENTE faz o movimento (constraints locais) porque ele vira dono da fisica do objeto.
	O SERVIDOR: valida quem pode agarrar o que, entrega o dono da fisica, cuida de
	escapar (espernear), coleira de distancia, arremesso (limites anti-trapaca),
	rastreio de distancia/recorde e impactos.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Data = require(script.Parent:WaitForChild("Data"))
local Physics = require(script.Parent:WaitForChild("Physics"))
local Ragdoll = require(script.Parent:WaitForChild("Ragdoll"))
local Scoring = require(script.Parent:WaitForChild("Scoring"))
local Impact = require(script.Parent:WaitForChild("Impact"))

local Grab = {}

local holds = {} -- [player] = { hold, ... }
local byKey = {} -- [BasePart] = hold
local tracking = {} -- arremessos em andamento
local struggles = {} -- [vitima] = { value, last, hold }
local releasedAt = {} -- [model] = os.clock()

-- Limites (dependem dos upgrades) ---------------------------------------------------------

function Grab.range(player: Player): number
	return Config.Grab.BaseRange + Config.Grab.RangePerLevel * Data.getUpgrade(player, "Range")
end

function Grab.holdMax(player: Player): number
	return Config.Grab.HoldMaxBase + Config.Grab.HoldMaxPerLevel * Data.getUpgrade(player, "Range")
end

function Grab.maxMass(player: Player): number
	return Config.Grab.MaxMassBase + Config.Grab.MaxMassPerLevel * Data.getUpgrade(player, "Strength")
end

function Grab.maxHolds(player: Player): number
	return 1 + Data.getUpgrade(player, "DoubleTether")
end

-- Velocidade de arremesso (mesma formula do cliente)
function Grab.throwSpeed(player: Player, mass: number, charge: number): number
	local T = Config.Throw
	local factor = math.clamp((T.RefMass / math.max(mass, 0.5)) ^ T.MassExponent, 0.2, 1.6)
	local power = 1 + T.PowerPerLevel * Data.getUpgrade(player, "Power")
	local speed = Util.lerp(T.MinSpeed, T.MaxSpeed, charge ^ 0.85) * factor * power
	return math.min(speed, T.MaxSpeedHard)
end

function Grab.holdsOf(player: Player): { any }
	return holds[player] or {}
end

function Grab.holdOfKey(key: Instance): any
	return byKey[key]
end

function Grab.isHeld(inst: Instance): boolean
	return inst:GetAttribute("HeldBy") ~= nil
end

-- Classificacao ------------------------------------------------------------------------------

-- retorna kind ("object" | "character"), model, targetPlayer, root
local function classify(player: Player, part: any)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then
		return nil
	end
	local model, targetPlayer = Physics.characterOf(part)
	if model then
		if model == player.Character then
			return nil
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return nil
		end
		if not targetPlayer and not CollectionService:HasTag(model, Config.Tags.Grabbable) then
			return nil
		end
		return "character", model, targetPlayer, Physics.holdPartOfCharacter(model)
	end
	local root = part.AssemblyRootPart or part
	if root.Anchored then
		return nil
	end
	if not CollectionService:HasTag(root, Config.Tags.Grabbable) then
		return nil
	end
	return "object", root:FindFirstAncestorOfClass("Model"), nil, root
end

local function holdsFolder(character: Model): Folder
	local f = character:FindFirstChild("TV_Holds")
	if not f then
		f = Instance.new("Folder")
		f.Name = "TV_Holds"
		f.Parent = character
	end
	return f
end

-- Termina um hold. reason: "client" | "throw" | "escaped" | "leash" | "gone" | "died" | "force"
local function endHold(hold, reason: string)
	if hold.ended then
		return
	end
	hold.ended = true
	local player = hold.player

	local list = holds[player]
	if list then
		local idx = table.find(list, hold)
		if idx then
			table.remove(list, idx)
		end
		if #list == 0 then
			holds[player] = nil
		end
	end
	byKey[hold.key] = nil
	if hold.ov and hold.ov.Parent then
		hold.ov:Destroy()
	end

	local target = hold.model or hold.key
	if hold.key.Parent then
		hold.key:SetAttribute("HeldBy", nil)
	end
	if hold.kind == "character" and hold.model then
		hold.model:SetAttribute("HeldBy", nil)
		releasedAt[hold.model] = os.clock()
		if hold.targetPlayer then
			struggles[hold.targetPlayer] = nil
			Remotes.get("HoldedBy"):FireClient(hold.targetPlayer, nil, 0)
		end
		Ragdoll.setHeld(hold.model, false, reason == "throw" and 1.2 or nil)
	end

	local immediate = reason ~= "throw" and reason ~= "client"
	task.delay(Config.Grab.ReleaseGrace, function()
		if target.Parent then
			Physics.setGroup(target, hold.kind == "character" and Config.Groups.Players or Config.Groups.Default)
		end
	end)
	local function giveBack()
		if not target.Parent then
			return
		end
		if hold.kind == "character" then
			Physics.setOwnerAuto(target)
		elseif not hold.key:GetAttribute("HeldBy") and not CollectionService:HasTag(hold.key, Config.Tags.Airborne) then
			Physics.setOwner(target, nil)
		end
	end
	if immediate then
		giveBack()
	else
		task.delay(Config.Grab.OwnerLinger, giveBack)
	end

	if reason ~= "client" and reason ~= "throw" and player.Parent then
		Remotes.get("ForceRelease"):FireClient(player, hold.key, reason)
	end
end

function Grab.releaseAll(player: Player, reason: string?)
	local list = holds[player]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		endHold(list[i], reason or "force")
	end
end

function Grab.forceRelease(key: Instance, reason: string?)
	local hold = byKey[key]
	if hold then
		endHold(hold, reason or "force")
	end
end

-- Agarrar --------------------------------------------------------------------------------------

local function handleGrab(player: Player, part: any)
	if not Data.isLoaded(player) then
		return false, "Carregando seus dados..."
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return false, "Você está fora de combate"
	end
	local list = holds[player]
	if list and #list >= Grab.maxHolds(player) then
		return false, "Mãos ocupadas"
	end
	local kind, model, targetPlayer, root = classify(player, part)
	if not kind then
		return false, "Não dá para agarrar isso"
	end

	local reach = Grab.range(player) + 14 + root.Size.Magnitude * 0.5
	if (root.Position - hrp.Position).Magnitude > reach then
		return false, "Longe demais"
	end
	if root:GetAttribute("HeldBy") or (model and kind == "character" and model:GetAttribute("HeldBy")) then
		return false, "Alguém já está segurando"
	end

	local mass
	if kind == "character" then
		if player:GetAttribute("Peaceful") == true then
			return false, "Modo Pacífico ligado: você não pode agarrar pessoas"
		end
		if player:GetAttribute("SafeZone") == true then
			return false, "Zona segura: sem agarrar pessoas"
		end
		if targetPlayer and Physics.isProtected(targetPlayer) then
			return false, "Esse jogador está protegido"
		end
		local last = releasedAt[model]
		if last and os.clock() - last < Config.Grab.CharacterGrabCooldown then
			return false, "Calma!"
		end
		mass = Physics.characterMass(model)
		if mass > Grab.maxMass(player) then
			return false, "Pesado demais!"
		end
	else
		mass = root.AssemblyMass
		if mass > Grab.maxMass(player) then
			return false, "Pesado demais! Suba o upgrade de Força"
		end
	end

	-- objeto: so o modelo do brinquedo (quando a raiz e o PrimaryPart) muda de grupo/dono
	local target = model or root
	if kind == "object" and not (model and model.PrimaryPart == root) then
		model = nil
		target = root
	end

	local hold = {
		player = player,
		key = root,
		kind = kind,
		model = model,
		targetPlayer = targetPlayer,
		mass = mass,
		since = os.clock(),
	}

	Physics.setOwner(target, player)
	Physics.setGroup(target, Config.Groups.Held)
	root:SetAttribute("HeldBy", player.UserId)
	if kind == "character" then
		model:SetAttribute("HeldBy", player.UserId)
	end

	local ov = Instance.new("ObjectValue")
	ov.Name = "Hold"
	ov.Value = root
	ov:SetAttribute("Kind", kind)
	ov.Parent = holdsFolder(char)
	hold.ov = ov

	if not holds[player] then
		holds[player] = {}
	end
	table.insert(holds[player], hold)
	byKey[root] = hold

	if kind == "character" then
		Ragdoll.enable(model, { duration = 1, held = true })
		if targetPlayer then
			struggles[targetPlayer] = { value = 0, last = 0, hold = hold }
			Remotes.get("HoldedBy"):FireClient(targetPlayer, player.DisplayName, 0)
		end
		model:SetAttribute("LastHitBy", player.UserId)
		model:SetAttribute("LastHitTime", os.clock())
	end

	return true, { kind = kind, key = root, model = model, mass = mass }
end

-- Arremesso --------------------------------------------------------------------------------------

local function finalize(rec, index: number?)
	if rec.finalized then
		return
	end
	rec.finalized = true
	if index then
		table.remove(tracking, index)
	else
		local i = table.find(tracking, rec)
		if i then
			table.remove(tracking, i)
		end
	end
	Impact.finish(rec)

	local key = rec.key
	local alive = key.Parent ~= nil
	if alive then
		CollectionService:RemoveTag(key, Config.Tags.Airborne)
		key:SetAttribute("Thrower", nil)
		key:SetAttribute("ThrowClock", nil)
		local target = rec.model or key
		if rec.kind == "character" then
			Physics.setOwnerAuto(target)
		elseif not key:GetAttribute("HeldBy") then
			Physics.setOwner(target, nil)
		end
	end

	local thrower = rec.thrower
	if thrower and thrower.Parent then
		local pos = alive and key.Position or rec.lastPos
		if pos and pos.Y > Config.World.KillY then
			local distance = Util.flat(pos - rec.origin).Magnitude
			if distance >= Config.Throw.DistanceMin then
				local bonus = 1
				local label = nil
				if rec.kind == "character" then
					bonus = 1.5
					label = "Pessoa voadora!"
				elseif rec.behavior == "crystal" then
					bonus = 2
					label = "Cristal!"
				end
				Scoring.throwLanded(thrower, distance, bonus, pos, label)
			end
		end
	end
end

local function doThrow(player: Player, key: any, dir: any, charge: any)
	if typeof(key) ~= "Instance" or typeof(dir) ~= "Vector3" or type(charge) ~= "number" then
		return
	end
	local hold = byKey[key]
	if not hold or hold.player ~= player then
		return
	end
	if dir.Magnitude < 0.5 or dir.Magnitude ~= dir.Magnitude then
		return
	end
	charge = math.clamp(charge, Config.Throw.MinCharge, 1)
	local expected = Grab.throwSpeed(player, hold.mass, charge)

	local kind = hold.kind
	local model = hold.model
	local parts
	if kind == "character" then
		parts = {}
		for _, n in { "HumanoidRootPart", "UpperTorso", "Torso", "Head" } do
			local p = model:FindFirstChild(n)
			if p then
				table.insert(parts, p)
			end
		end
	else
		parts = { key }
	end

	local rec = {
		key = key,
		parts = parts,
		model = model,
		thrower = player,
		kind = kind,
		mass = hold.mass,
		behavior = (kind == "object") and (key:GetAttribute("Behavior") or "none") or "person",
		t0 = os.clock(),
		origin = key.Position,
		lastPos = key.Position,
		rest = 0,
		maxSpeed = expected * 1.35 + 30,
	}

	endHold(hold, "throw")

	key:SetAttribute("Thrower", player.UserId)
	key:SetAttribute("ThrowClock", workspace:GetServerTimeNow())
	if kind == "object" then
		CollectionService:AddTag(key, Config.Tags.Airborne)
	end
	table.insert(tracking, rec)
	Impact.begin(rec)
end

-- Laços periódicos -----------------------------------------------------------------------------

local function trackingStep(dt: number)
	local now = os.clock()
	for i = #tracking, 1, -1 do
		local rec = tracking[i]
		local key = rec.key
		if not key.Parent then
			finalize(rec, i)
		else
			rec.lastPos = key.Position
			local v = key.AssemblyLinearVelocity
			local speed = v.Magnitude
			local age = now - rec.t0
			if age < 1.5 and speed > rec.maxSpeed then
				key.AssemblyLinearVelocity = v.Unit * rec.maxSpeed
			end
			if age > 0.6 and speed < Config.Throw.LandSpeed then
				rec.rest += dt
			else
				rec.rest = 0
			end
			if rec.rest >= Config.Throw.LandTime or age > Config.Throw.TrackTimeout or key.Position.Y < Config.World.KillY then
				finalize(rec, i)
			end
		end
	end
end

local function escape(hold)
	local victim = hold.targetPlayer
	local model = hold.model
	local holder = hold.player
	endHold(hold, "escaped")
	if victim then
		victim:SetAttribute("ImmuneUntil", workspace:GetServerTimeNow() + 2.5)
		Remotes.get("Notify"):FireClient(victim, "Você escapou! 🕊️", "good")
	end
	if model then
		local root = Physics.rootOfCharacter(model)
		local hrp = holder.Character and holder.Character:FindFirstChild("HumanoidRootPart")
		if root and hrp then
			local away = Util.safeUnit(Util.flat(root.Position - hrp.Position), Vector3.zAxis)
			Physics.launch(model, away * 55 + Vector3.new(0, 40, 0))
		end
	end
	Remotes.get("Notify"):FireClient(holder, "Ele escapou!", "bad")
end

local function leashStep(dt: number)
	-- coleira de distancia
	for player, list in holds do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		for i = #list, 1, -1 do
			local hold = list[i]
			if not hold.ended then
				local key = hold.key
				local bad = false
				if not hrp or not hum or hum.Health <= 0 then
					bad = true
				elseif not key.Parent or not key:IsDescendantOf(workspace) then
					bad = true
				elseif (key.Position - hrp.Position).Magnitude > Grab.holdMax(player) + Config.Grab.ServerLeash then
					bad = true
				elseif hold.kind == "character" then
					local th = hold.model and hold.model:FindFirstChildOfClass("Humanoid")
					if not th or th.Health <= 0 then
						bad = true
					end
				end
				if bad then
					endHold(hold, "leash")
				end
			end
		end
	end
	-- espernear: decaimento e progresso
	for victim, st in struggles do
		local needed = math.max(6, Config.Ragdoll.StruggleNeeded - Config.Ragdoll.StrugglePerLevel * Data.getUpgrade(victim, "Escape"))
		st.value = math.max(0, st.value - (Config.Ragdoll.StruggleDecay / needed) * dt)
		if victim.Parent and st.hold and not st.hold.ended then
			Remotes.get("HoldedBy"):FireClient(victim, st.hold.player.DisplayName, st.value)
		end
	end
end

local function onPlayerGone(player: Player)
	Grab.releaseAll(player, "gone")
	-- se era vitima
	local st = struggles[player]
	if st and st.hold then
		endHold(st.hold, "gone")
	end
	struggles[player] = nil
	for key, hold in byKey do
		if hold.targetPlayer == player then
			endHold(hold, "gone")
		end
	end
end

function Grab.init()
	Remotes.get("Grab").OnServerInvoke = function(player, part, _aim)
		local ok, a, b = pcall(handleGrab, player, part)
		if not ok then
			warn("[Grab] erro:", a)
			return false, "Erro interno"
		end
		return a, b
	end

	Remotes.get("Release").OnServerEvent:Connect(function(player, key)
		if typeof(key) ~= "Instance" then
			return
		end
		local hold = byKey[key]
		if hold and hold.player == player then
			endHold(hold, "client")
		end
	end)

	Remotes.get("Throw").OnServerEvent:Connect(function(player, key, dir, charge)
		local ok, err = pcall(doThrow, player, key, dir, charge)
		if not ok then
			warn("[Grab] erro no arremesso:", err)
		end
	end)

	Remotes.get("Struggle").OnServerEvent:Connect(function(player)
		local st = struggles[player]
		if not st or not st.hold or st.hold.ended then
			return
		end
		local now = os.clock()
		if now - st.last < 0.06 then
			return
		end
		st.last = now
		local needed = math.max(6, Config.Ragdoll.StruggleNeeded - Config.Ragdoll.StrugglePerLevel * Data.getUpgrade(player, "Escape"))
		st.value += 1 / needed
		if st.value >= Config.Ragdoll.StruggleMax then
			escape(st.hold)
		end
	end)

	local acc = 0
	local accTrack = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		accTrack += dt
		if accTrack >= 0.1 then
			trackingStep(accTrack)
			accTrack = 0
		end
		if acc >= 0.25 then
			leashStep(acc)
			acc = 0
		end
	end)

	Players.PlayerRemoving:Connect(onPlayerGone)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function()
			Grab.releaseAll(player, "died")
			local st = struggles[player]
			if st and st.hold then
				endHold(st.hold, "died")
			end
		end)
	end)
	for _, p in Players:GetPlayers() do
		p.CharacterRemoving:Connect(function()
			Grab.releaseAll(p, "died")
		end)
	end
end

return Grab
