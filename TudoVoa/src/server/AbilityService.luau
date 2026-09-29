--!nonstrict
--[[
	Abilities (servidor): valida e executa as habilidades.
	Cliente pede (UseAbility), servidor confere nivel, recarga, alcance e aplica o efeito.
	  pull    puxa um objeto mirado ate voce
	  dash    impulso (o cliente aplica a velocidade; servidor so controla a recarga e o visual)
	  stasis  congela/descongela um objeto no ar (vira plataforma)
	  shock   onda de choque em volta
	  bubble  bolha anti-gravidade no ponto mirado
	  hook    gancho: te puxa ate o ponto mirado
	  shield  escudo: ninguem agarra nem empurra
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local AbilityDefs = require(Shared:WaitForChild("AbilityDefs"))
local Util = require(Shared:WaitForChild("Util"))

local Data = require(script.Parent:WaitForChild("Data"))
local Grab = require(script.Parent:WaitForChild("Grab"))
local Physics = require(script.Parent:WaitForChild("Physics"))
local Blasts = require(script.Parent:WaitForChild("Blasts"))

local Abilities = {}

local cooldowns = {} -- [player] = { [id] = os.clock() ate quando }
local frozen = {} -- [player] = { root, ... }
local hooks = {} -- [player] = { align, att, anchor, expire, point }

local MAX_FROZEN = 5
local FREEZE_TIME = 32

local function cooldownFor(player: Player, def): number
	local scale = 1 - 0.06 * Data.getUpgrade(player, "Cooldown")
	return def.cooldown * math.max(0.4, scale)
end

local function isObject(root: any): boolean
	return typeof(root) == "Instance"
		and root:IsA("BasePart")
		and root:IsDescendantOf(workspace)
		and CollectionService:HasTag(root, Config.Tags.Grabbable)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return (a - b).Magnitude
end

-- Estase -----------------------------------------------------------------------------------------------

local function unfreeze(root: BasePart)
	if not root.Parent then
		return
	end
	root:SetAttribute("Frozen", nil)
	root.Anchored = false
	root.AssemblyLinearVelocity = Vector3.zero
	local model = root:FindFirstAncestorOfClass("Model")
	local hl = (model or root):FindFirstChild("TV_FrozenHL")
	if hl then
		hl:Destroy()
	end
	Util.setAll(model and model.PrimaryPart == root and model or root, "Anchored", false)
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
end

local function freeze(player: Player, root: BasePart)
	local list = frozen[player]
	if not list then
		list = {}
		frozen[player] = list
	end
	while #list >= MAX_FROZEN do
		local old = table.remove(list, 1)
		if old and old.Parent then
			unfreeze(old)
		end
	end
	local model = root:FindFirstAncestorOfClass("Model")
	if not (model and model.PrimaryPart == root) then
		model = nil
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	Util.setAll(model or root, "Anchored", true)
	root:SetAttribute("Frozen", os.clock())
	local hl = Instance.new("Highlight")
	hl.Name = "TV_FrozenHL"
	hl.FillColor = Color3.fromRGB(120, 220, 255)
	hl.FillTransparency = 0.72
	hl.OutlineColor = Color3.fromRGB(230, 250, 255)
	hl.OutlineTransparency = 0.1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = model or root
	hl.Parent = model or root
	table.insert(list, root)
	Remotes.get("Fx"):FireAllClients("freeze", root.Position, 1, nil)

	task.delay(FREEZE_TIME, function()
		if root.Parent and root:GetAttribute("Frozen") then
			unfreeze(root)
			local i = table.find(list, root)
			if i then
				table.remove(list, i)
			end
		end
	end)
end

local function doStasis(player: Player, hrp: BasePart, target: any)
	-- descongelar?
	if isObject(target) and target:GetAttribute("Frozen") then
		if flatDistance(target.Position, hrp.Position) > 150 then
			return false
		end
		unfreeze(target)
		local list = frozen[player]
		if list then
			local i = table.find(list, target)
			if i then
				table.remove(list, i)
			end
		end
		Remotes.get("Fx"):FireAllClients("unfreeze", target.Position, 1, nil)
		return true
	end
	-- congelar o que esta segurando
	local held = Grab.holdsOf(player)
	local hold
	for _, h in held do
		if h.kind == "object" and (target == nil or h.key == target) then
			hold = h
			break
		end
	end
	local root
	if hold then
		root = hold.key
		Grab.forceRelease(root, "freeze")
	elseif isObject(target) and not target:GetAttribute("HeldBy") and not target.Anchored then
		root = target
		if flatDistance(root.Position, hrp.Position) > 130 then
			return false
		end
	end
	if not root or not root.Parent then
		return false
	end
	freeze(player, root)
	return true
end

-- Gancho ---------------------------------------------------------------------------------------------------

local function stopHook(player: Player)
	local h = hooks[player]
	if not h then
		return
	end
	hooks[player] = nil
	for _, o in { h.align, h.att, h.anchor } do
		if o and o.Parent then
			o:Destroy()
		end
	end
	player:SetAttribute("HookPoint", nil)
end

local function doHook(player: Player, hrp: BasePart, point: any)
	if typeof(point) ~= "Vector3" then
		return false
	end
	local def = AbilityDefs.ById.hook
	local off = point - hrp.Position
	if off.Magnitude > def.range + 15 or off.Magnitude < 8 then
		return false
	end
	-- o ponto tem que estar "perto" de uma superficie de verdade (nao no ar)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(hrp.Position, off.Unit * (off.Magnitude + 6), params)
	if not hit or (hit.Position - point).Magnitude > 9 then
		return false
	end
	stopHook(player)

	local mass = Physics.characterMass(player.Character)
	local anchor = Instance.new("Part")
	anchor.Name = "TV_HookAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = hit.Position
	anchor.Parent = workspace

	local att = Instance.new("Attachment")
	att.Name = "TV_HookAtt"
	att.Parent = hrp

	local align = Instance.new("AlignPosition")
	align.Name = "TV_HookAlign"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.Position = hit.Position + hit.Normal * 3.5
	align.MaxVelocity = 115
	align.Responsiveness = 11
	align.MaxForce = mass * 9000
	align.RigidityEnabled = false
	align.ApplyAtCenterOfMass = true
	align.Parent = hrp

	hooks[player] = { align = align, att = att, anchor = anchor, expire = os.clock() + 2.6, point = hit.Position }
	player:SetAttribute("HookPoint", hit.Position)
	Remotes.get("AbilityFx"):FireAllClients("hook", player.UserId, hit.Position, nil)
	return true
end

-- Pull ---------------------------------------------------------------------------------------------------------

local function doPull(player: Player, hrp: BasePart, target: any)
	if not isObject(target) or target.Anchored or target:GetAttribute("HeldBy") then
		return false
	end
	local def = AbilityDefs.ById.pull
	local off = (hrp.Position + Vector3.new(0, 3, 0)) - target.Position
	if off.Magnitude > def.range + 20 then
		return false
	end
	local mass = target.AssemblyMass
	if mass > Grab.maxMass(player) then
		return false
	end
	Physics.setOwner(target, nil)
	local speed = math.clamp(off.Magnitude * 1.7, 45, 140)
	target.AssemblyLinearVelocity = off.Unit * speed
	target.AssemblyAngularVelocity = Util.randomUnit() * 4
	Remotes.get("AbilityFx"):FireAllClients("pull", player.UserId, target.Position, nil)
	return true
end

-- Registro ------------------------------------------------------------------------------------------------------

local function handleUse(player: Player, id: any, arg: any)
	if type(id) ~= "string" then
		return
	end
	local def = AbilityDefs.ById[id]
	if not def or not Data.isLoaded(player) then
		return
	end
	local d = Data.get(player)
	if d.Level < def.level then
		Remotes.get("Notify"):FireClient(player, def.name .. " libera no nível " .. def.level, "bad")
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return
	end
	local cds = cooldowns[player]
	if not cds then
		cds = {}
		cooldowns[player] = cds
	end
	local now = os.clock()
	if cds[id] and now < cds[id] - 0.15 then
		return
	end

	local ok = false
	if id == "pull" then
		ok = doPull(player, hrp, arg)
	elseif id == "dash" then
		ok = true
		Remotes.get("AbilityFx"):FireAllClients("dash", player.UserId, hrp.Position, nil)
	elseif id == "stasis" then
		ok = doStasis(player, hrp, arg)
	elseif id == "shock" then
		ok = true
		Blasts.shock(player, hrp.Position, def.radius, 125)
	elseif id == "bubble" then
		if typeof(arg) == "Vector3" and (arg - hrp.Position).Magnitude <= def.range + 20 then
			Blasts.bubble(arg + Vector3.new(0, def.radius * 0.35, 0), def.radius, def.duration, player)
			ok = true
		end
	elseif id == "hook" then
		ok = doHook(player, hrp, arg)
	elseif id == "shield" then
		player:SetAttribute("ShieldUntil", workspace:GetServerTimeNow() + def.duration)
		Remotes.get("AbilityFx"):FireAllClients("shield", player.UserId, hrp.Position, def.duration)
		ok = true
	end

	if ok then
		cds[id] = now + cooldownFor(player, def)
	else
		Remotes.get("AbilityFx"):FireClient(player, "fail", player.UserId, hrp.Position, id)
	end
end

function Abilities.init()
	Remotes.get("UseAbility").OnServerEvent:Connect(function(player, id, arg)
		local ok, err = pcall(handleUse, player, id, arg)
		if not ok then
			warn("[Abilities] erro:", err)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, h in hooks do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp or now >= h.expire or (hrp.Position - h.point).Magnitude < 9 then
				stopHook(player)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		stopHook(player)
		cooldowns[player] = nil
		local list = frozen[player]
		if list then
			for _, r in list do
				if r.Parent then
					unfreeze(r)
				end
			end
		end
		frozen[player] = nil
	end)
end

return Abilities
