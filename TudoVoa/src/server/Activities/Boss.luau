--!nonstrict
--[[
	Boss: o GOLEM SUCATA, chefao co-op da Ilha do Golem.
	- Modelo articulado animado pelo servidor (20 Hz): andar, respirar, pisao, arremesso de pedras
	- Voce causa dano arremessando objetos NO NUCLEO brilhante do peito (massa x velocidade)
	- Pisao: aviso vermelho no chao; PULE para escapar da onda de choque
	- Pedras que ele joga viram municao para voces devolverem
	- Fases (75/50/25%): ele cambaleia (dano dobrado) e depois fica mais rapido
	- Recompensa proporcional ao dano de cada jogador
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Server = script.Parent.Parent
local Build = require(Server:WaitForChild("World"):WaitForChild("Build"))
local WorldGen = require(Server:WaitForChild("World"):WaitForChild("WorldGen"))
local Interactive = require(Server:WaitForChild("World"):WaitForChild("Interactive"))
local Data = require(Server:WaitForChild("Data"))
local Quests = require(Server:WaitForChild("Quests"))
local Physics = require(Server:WaitForChild("Physics"))
local Ragdoll = require(Server:WaitForChild("Ragdoll"))
local Blasts = require(Server:WaitForChild("Blasts"))
local Pickups = require(Server:WaitForChild("Pickups"))
local ToySpawner = require(Server:WaitForChild("ToySpawner"))

local Boss = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local FIRST_SPAWN = 150 -- segundos depois do servidor abrir
local COOLDOWN = 420
local MAX_ACTIVE = 600

local folder: Folder
local island
local groundY: number
local rockFolder: Folder

local golem = nil -- estado do chefao ativo
local nextSpawnAt = os.clock() + FIRST_SPAWN

-- Rig ------------------------------------------------------------------------------------------------------------------------------------------------------

local function newPart(model: Model, name: string, size: Vector3, color: Color3, material: any, shape: any?, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Cria o golem e devolve { model, parts = { {part, offset, group} }, core, head }
local function buildGolem(rootCF: CFrame)
	local model = Instance.new("Model")
	model.Name = "GolemSucata"
	local stone = rgb(120, 112, 138)
	local dark = rgb(78, 72, 96)
	local metal = rgb(150, 160, 180)
	local parts = {}
	local function add(name: string, offset: Vector3, size: Vector3, color: Color3, material: any, group: string, shape: any?, collide: boolean?)
		local p = newPart(model, name, size, color, material, shape, collide)
		table.insert(parts, { part = p, offset = offset, group = group })
		return p
	end

	-- pernas e pes (grupo legL/legR gira no quadril)
	for _, s in { -1, 1 } do
		local g = s < 0 and "legL" or "legR"
		add("Foot" .. g, Vector3.new(s * 7.5, 2, -1), Vector3.new(11, 4, 15), dark, M.Slate, g)
		add("Leg" .. g, Vector3.new(s * 7.5, 14, 0), Vector3.new(8.4, 20, 8.4), stone, M.Slate, g)
		add("Knee" .. g, Vector3.new(s * 7.5, 15, -4.6), Vector3.new(5, 5, 2), metal, M.Metal, g, nil, false)
	end
	add("Hips", Vector3.new(0, 27, 0), Vector3.new(21, 6, 13), dark, M.Slate, "body")
	add("Torso", Vector3.new(0, 43, 0), Vector3.new(26, 28, 15), stone, M.Slate, "body")
	add("Belly", Vector3.new(0, 34, -7.8), Vector3.new(18, 8, 1.6), metal, M.DiamondPlate, "body", nil, false)
	local core = add("Core", Vector3.new(0, 45, -8.4), Vector3.one * 9.5, rgb(255, 120, 60), M.Neon, "body", Enum.PartType.Ball, false)
	core.CanTouch = true
	-- placas de sucata nas costas
	add("Scrap1", Vector3.new(-6, 48, 8.8), Vector3.new(10, 14, 2.4), metal, M.CorrodedMetal, "body", nil, false)
	add("Scrap2", Vector3.new(7, 44, 9), Vector3.new(9, 16, 2.4), rgb(180, 120, 80), M.CorrodedMetal, "body", nil, false)
	-- cabeca
	local head = add("Head", Vector3.new(0, 62, -1), Vector3.new(13, 11, 12), stone, M.Slate, "head")
	add("EyeL", Vector3.new(-3, 63, -7.2), Vector3.new(3.6, 2, 0.8), rgb(255, 90, 60), M.Neon, "head", nil, false)
	add("EyeR", Vector3.new(3, 63, -7.2), Vector3.new(3.6, 2, 0.8), rgb(255, 90, 60), M.Neon, "head", nil, false)
	add("Jaw", Vector3.new(0, 57.6, -5), Vector3.new(9, 2.4, 3), dark, M.Slate, "head", nil, false)
	for i, x in { -3.6, 0, 3.6 } do
		add("Crystal" .. i, Vector3.new(x, 69 + (i == 2 and 2 or 0), -1), Vector3.new(2.2, 6 + (i == 2 and 3 or 0), 2.2), rgb(120, 240, 255), M.Neon, "head", nil, false)
	end
	-- bracos (giram no ombro)
	for _, s in { -1, 1 } do
		local g = s < 0 and "armL" or "armR"
		add("Shoulder" .. g, Vector3.new(s * 16.5, 53, 0), Vector3.one * 11.5, metal, M.Metal, g, Enum.PartType.Ball)
		add("ArmUp" .. g, Vector3.new(s * 18.5, 43, 0), Vector3.new(7, 18, 7), stone, M.Slate, g)
		add("ArmLow" .. g, Vector3.new(s * 18.5, 27, -2), Vector3.new(8.4, 16, 8.4), dark, M.Slate, g)
		add("Fist" .. g, Vector3.new(s * 18.5, 16, -2), Vector3.one * 12.5, stone, M.Slate, g, Enum.PartType.Ball)
	end

	model.PrimaryPart = parts[1].part
	model.Parent = folder
	return {
		model = model,
		parts = parts,
		core = core,
		head = head,
		rootCF = rootCF,
	}
end

local SHOULDER = { armL = Vector3.new(-16.5, 53, 0), armR = Vector3.new(16.5, 53, 0) }
local HIP = { legL = Vector3.new(-7.5, 28, 0), legR = Vector3.new(7.5, 28, 0) }

-- Aplica a pose. pose = { rootCF, armL, armR, legL, legR, headPitch }
local function applyPose(g, pose)
	local root = pose.rootCF
	for _, rec in g.parts do
		local cf = CFrame.new(rec.offset)
		local group = rec.group
		if group == "armL" or group == "armR" then
			local pivot = SHOULDER[group]
			cf = CFrame.new(pivot) * CFrame.Angles(pose[group], 0, (group == "armL" and -1 or 1) * (pose.armSpread or 0)) * CFrame.new(rec.offset - pivot)
		elseif group == "legL" or group == "legR" then
			local pivot = HIP[group]
			cf = CFrame.new(pivot) * CFrame.Angles(pose[group], 0, 0) * CFrame.new(rec.offset - pivot)
		elseif group == "head" then
			local pivot = Vector3.new(0, 56, 0)
			cf = CFrame.new(pivot) * CFrame.Angles(pose.headPitch or 0, pose.headYaw or 0, 0) * CFrame.new(rec.offset - pivot)
		end
		rec.part.CFrame = root * cf
	end
end

-- Estado/IA -----------------------------------------------------------------------------------------------------------------------------------------------------------------

local function playersNearby(radius: number)
	local out = {}
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local flat = Vector3.new(hrp.Position.X - island.pos.X, 0, hrp.Position.Z - island.pos.Z).Magnitude
			if flat < radius and math.abs(hrp.Position.Y - groundY) < 60 then
				table.insert(out, { player = p, hrp = hrp, char = char })
			end
		end
	end
	return out
end

local function broadcastState(final: string?)
	if not golem then
		return
	end
	Remotes.get("BossState"):FireAllClients({
		active = final == nil,
		name = "Golem Sucata",
		hp = math.max(0, golem.hp),
		maxHp = golem.maxHp,
		phase = golem.phase,
		pos = golem.rootCF.Position,
		result = final,
	})
end

local function spawnRock(pos: Vector3, vel: Vector3?, thrown: boolean)
	local size = math.random(38, 52) / 10
	local rock = Instance.new("Part")
	rock.Name = "GolemRock"
	rock.Shape = Enum.PartType.Ball
	rock.Size = Vector3.one * size
	rock.Color = rgb(128, 120, 146)
	rock.Material = M.Slate
	rock.CustomPhysicalProperties = PhysicalProperties.new(1.6, 0.6, 0.15, 1, 1)
	rock.Position = pos
	rock.Parent = rockFolder
	CollectionService:AddTag(rock, Config.Tags.Grabbable)
	rock:SetAttribute("Behavior", "heavy")
	pcall(function()
		rock:SetNetworkOwner(nil)
	end)
	if vel then
		rock.AssemblyLinearVelocity = vel
	end
	if thrown then
		local done = false
		rock.Touched:Connect(function(other)
			if done or not rock.Parent or other:IsDescendantOf(golem and golem.model or folder) then
				return
			end
			if os.clock() - (rock:GetAttribute("BornT") or 0) < 0.25 then
				return
			end
			done = true
			local char, player = Physics.characterOf(other)
			if char and player and not Physics.isProtected(player) then
				local dir = Util.safeUnit(rock.AssemblyLinearVelocity, Vector3.zAxis)
				Ragdoll.knock(char, 2.4)
				Physics.launch(char, dir * 70 + Vector3.new(0, 34, 0))
				Remotes.get("Struck"):FireClient(player, 0.8, dir)
			end
			Blasts.push(rock.Position, 14, 60, { fx = "explosion", noCharacters = true })
		end)
	end
	rock:SetAttribute("BornT", os.clock())
	task.delay(45, function()
		if rock.Parent and not rock:GetAttribute("HeldBy") then
			rock:Destroy()
		end
	end)
	return rock
end

local function damage(amount: number, player: Player?)
	if not golem or golem.dead then
		return
	end
	if golem.phaseStagger then
		amount *= 2
	end
	golem.hp -= amount
	if player then
		golem.damageBy[player.UserId] = (golem.damageBy[player.UserId] or 0) + amount
		Quests.report(player, "boss", amount)
	end
	-- fases
	local frac = golem.hp / golem.maxHp
	local nextPhase = (frac < 0.25 and 4) or (frac < 0.5 and 3) or (frac < 0.75 and 2) or 1
	if nextPhase > golem.phase then
		golem.phase = nextPhase
		golem.staggerUntil = os.clock() + 5.5
		golem.phaseStagger = true
		golem.action = { kind = "stagger", t0 = os.clock() }
		Remotes.get("Announce"):FireAllClients("O GOLEM CAMBALEIA!", "Dano dobrado por alguns segundos!", 2.5, P.Accent)
		Remotes.get("Fx"):FireAllClients("shock", golem.rootCF.Position + Vector3.new(0, 30, 0), 2, nil)
		for i = 1, 3 do
			local a = math.random() * math.pi * 2
			spawnRock(golem.rootCF.Position + Vector3.new(math.cos(a) * 30, 50, math.sin(a) * 30), nil, false)
		end
		Pickups.burst(golem.rootCF.Position + Vector3.new(0, 30, -12), 80 * nextPhase, 12)
	end
	-- brilho no nucleo
	golem.core.Color = rgb(255, 255, 200)
	task.delay(0.12, function()
		if golem and golem.core.Parent then
			golem.core.Color = rgb(255, 120, 60)
		end
	end)
	if golem.hp <= 0 then
		golem.dead = true
	end
end

local function onCoreTouched(other: BasePart)
	if not golem or golem.dead then
		return
	end
	local thrower = other:GetAttribute("Thrower")
	if not thrower then
		return
	end
	local speed = other.AssemblyLinearVelocity.Magnitude
	if speed < 34 then
		return
	end
	local last = golem.hitLog[other]
	if last and os.clock() - last < 0.7 then
		return
	end
	golem.hitLog[other] = os.clock()
	local player = Players:GetPlayerByUserId(thrower)
	local mass = other.AssemblyMass
	local dmg = math.clamp(mass * speed / 45, 3, 300)
	damage(dmg, player)
	Remotes.get("Fx"):FireAllClients("impact", golem.core.Position, 1, { mat = "Metal", color = rgb(255, 200, 120) })
	if player then
		Remotes.get("ScorePopup"):FireClient(player, golem.core.Position + Vector3.new(0, 8, -6), string.format("-%d", math.floor(dmg)), golem.phaseStagger and P.Pink or P.Accent)
	end
end

-- Ataques -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function telegraphStomp(pos: Vector3)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = M.Neon
	ring.Color = P.Red
	ring.Transparency = 0.5
	ring.Size = Vector3.new(0.4, 4, 4)
	ring.CFrame = CFrame.new(pos.X, groundY + 0.5, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.4, 128, 128), Transparency = 0.8 }):Play()
	task.delay(1.5, function()
		ring:Destroy()
	end)
end

local function stompImpact(pos: Vector3)
	local radius = 64
	Remotes.get("Fx"):FireAllClients("explosion", Vector3.new(pos.X, groundY + 2, pos.Z), 1.5, nil)
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and not Physics.isProtected(p) then
			local off = Vector3.new(hrp.Position.X - pos.X, 0, hrp.Position.Z - pos.Z)
			local flatD = off.Magnitude
			local height = hrp.Position.Y - groundY
			if flatD < radius and height < 7.5 then
				local dir = Util.safeUnit(off, Vector3.zAxis)
				local fall = 1 - flatD / radius
				Ragdoll.knock(char, 2.6)
				Physics.launch(char, dir * (60 + 70 * fall) + Vector3.new(0, 55 + 30 * fall, 0))
				Remotes.get("Struck"):FireClient(p, 0.6 + fall * 0.4, dir)
			end
		end
	end
	Blasts.push(Vector3.new(pos.X, groundY + 2, pos.Z), radius, 80, { fx = false, noCharacters = true })
end

local function pickTarget(list)
	if #list == 0 then
		return nil
	end
	return list[math.random(1, #list)]
end

local function startAction(g, kind: string)
	g.action = { kind = kind, t0 = os.clock() }
end

-- Laco de animacao/IA ----------------------------------------------------------------------------------------------------------------------------------------------------------

local function stepGolem(dt: number)
	local g = golem
	local now = os.clock()
	local center = Vector3.new(island.pos.X, groundY, island.pos.Z)
	local near = playersNearby(150)

	-- termina cambaleio
	if g.phaseStagger and now > g.staggerUntil then
		g.phaseStagger = false
		g.action = nil
		g.attackDelay = 1.5
	end

	-- alvo mais proximo
	local target, targetD = nil, 1e9
	for _, n in near do
		local d = (Vector3.new(n.hrp.Position.X, 0, n.hrp.Position.Z) - Vector3.new(g.rootCF.Position.X, 0, g.rootCF.Position.Z)).Magnitude
		if d < targetD then
			target, targetD = n, d
		end
	end

	local pos = g.rootCF.Position
	local yaw = g.yaw
	local walking = false

	local action = g.action
	local speedMul = 1 + (g.phase - 1) * 0.25

	if not action and target then
		-- gira e anda em direcao ao alvo
		local dir = Vector3.new(target.hrp.Position.X - pos.X, 0, target.hrp.Position.Z - pos.Z)
		local wanted = math.atan2(-dir.X, -dir.Z)
		local diff = (wanted - yaw + math.pi) % (math.pi * 2) - math.pi
		yaw += math.clamp(diff, -1.4 * dt, 1.4 * dt)
		if targetD > 34 and dir.Magnitude > 1 then
			local step = dir.Unit * 8.5 * speedMul * dt
			local newPos = pos + step
			if Vector3.new(newPos.X - center.X, 0, newPos.Z - center.Z).Magnitude < island.radius - 28 then
				pos = newPos
			end
			walking = true
		end
		-- escolhe o ataque
		g.attackDelay -= dt
		if g.attackDelay <= 0 then
			g.attackDelay = math.max(2.2, 4.2 - g.phase * 0.5)
			if targetD < 55 and math.random() < 0.7 then
				startAction(g, "stomp")
			else
				startAction(g, "throw")
				g.action.target = pickTarget(near)
			end
		end
	end

	local t = now - g.t0
	local pose = { armL = 0, armR = 0, legL = 0, legR = 0, headPitch = 0, headYaw = 0, armSpread = 0 }
	local lift = 0
	local sink = 0

	if walking then
		local w = t * 4.2 * speedMul
		pose.legL = math.sin(w) * 0.55
		pose.legR = -math.sin(w) * 0.55
		pose.armL = -math.sin(w) * 0.35
		pose.armR = math.sin(w) * 0.35
		lift = math.abs(math.sin(w)) * 1.4
		-- passos fazem o chao tremer
		local stepPhase = math.floor(w / math.pi)
		if stepPhase ~= g.lastStep then
			g.lastStep = stepPhase
			Remotes.get("Fx"):FireAllClients("thud", pos, 0.35, nil)
		end
	else
		pose.armL = math.sin(t * 1.4) * 0.06
		pose.armR = -math.sin(t * 1.4) * 0.06
		lift = math.sin(t * 1.4) * 0.35
	end

	if action then
		local a = now - action.t0
		if action.kind == "stomp" then
			-- 0-0.9 sobe os bracos, 0.9-1.7 pula, 1.7 pisa
			if a < 0.9 then
				pose.armL = -2.5 * (a / 0.9)
				pose.armR = -2.5 * (a / 0.9)
				pose.armSpread = 0.4
				if not action.telegraphed then
					action.telegraphed = true
					telegraphStomp(pos)
					Remotes.get("Fx"):FireAllClients("fuse", pos, 1, nil)
				end
			elseif a < 1.7 then
				local ph = (a - 0.9) / 0.8
				pose.armL = -2.5 + 3.3 * ph
				pose.armR = -2.5 + 3.3 * ph
				lift = 22 * math.sin(math.pi * ph)
				pose.legL = -0.4
				pose.legR = -0.4
			else
				if not action.impact then
					action.impact = true
					stompImpact(pos)
				end
				pose.armL = 0.8
				pose.armR = 0.8
				sink = 3
				if a > 2.4 then
					g.action = nil
				end
			end
		elseif action.kind == "throw" then
			-- braco direito para tras (0-0.7), solta a pedra (0.7), segue (ate 1.3)
			if a < 0.7 then
				pose.armR = -2.9 * (a / 0.7)
				pose.armL = 0.5
				pose.legL = 0.15
			else
				local ph = math.min(1, (a - 0.7) / 0.35)
				pose.armR = -2.9 + 4.4 * ph
				if not action.released then
					action.released = true
					local tgt = action.target
					local hand = pos + (CFrame.Angles(0, yaw, 0) * Vector3.new(18.5, 48, -6))
					local from = hand
					local goal = tgt and tgt.hrp and (tgt.hrp.Position + tgt.hrp.AssemblyLinearVelocity * 0.6) or (pos + Vector3.new(0, 0, -60))
					local v = Interactive.ballistic(from, goal, 38) or (Util.safeUnit(goal - from, Vector3.zAxis) * 120)
					spawnRock(from, v, true)
					Remotes.get("Fx"):FireAllClients("thud", from, 0.5, nil)
				end
				if a > 1.6 then
					g.action = nil
				end
			end
		elseif action.kind == "stagger" then
			sink = 12
			pose.armL = 0.9 + math.sin(now * 9) * 0.1
			pose.armR = 0.9 + math.sin(now * 9 + 1) * 0.1
			pose.headPitch = 0.55
			pose.legL = -0.6
			pose.legR = -0.6
		end
	end

	g.yaw = yaw
	g.rootCF = CFrame.new(pos.X, groundY + lift - sink, pos.Z) * CFrame.Angles(0, yaw, 0)
	pose.rootCF = g.rootCF
	applyPose(g, pose)
end

-- Ciclo de vida -------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function finish(result: string)
	local g = golem
	if not g then
		return
	end
	golem = nil
	if result == "defeated" then
		local total = 0
		for _, v in g.damageBy do
			total += v
		end
		Remotes.get("Announce"):FireAllClients("GOLEM DERROTADO!", "Recompensas para todos que ajudaram", 4, P.Accent)
		Remotes.get("Fx"):FireAllClients("explosion", g.rootCF.Position + Vector3.new(0, 30, 0), 2.2, nil)
		Remotes.get("Fx"):FireAllClients("confetti", g.rootCF.Position + Vector3.new(0, 40, 0), 2, nil)
		for userId, dmg in g.damageBy do
			local p = Players:GetPlayerByUserId(userId)
			if p and Data.isLoaded(p) then
				local share = dmg / math.max(total, 1)
				local coins = math.floor(200 + 1100 * share)
				Data.addCoins(p, coins, "Golem derrotado")
				Data.addXP(p, math.floor(coins * 1.2))
				Data.addStat(p, "BossDamage", math.floor(dmg))
			end
		end
		Pickups.burst(g.rootCF.Position + Vector3.new(0, 40, -10), 500, 36)
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			ToySpawner.spawnAt("cristal", g.rootCF.Position + Vector3.new(math.cos(a) * 24, 30, math.sin(a) * 24))
		end
		-- desmonta o golem com efeito
		for _, rec in g.parts do
			local p = rec.part
			p.Anchored = false
			p.CanCollide = true
			p.AssemblyLinearVelocity = Vector3.new(math.random(-40, 40), math.random(30, 80), math.random(-40, 40))
			task.delay(6, function()
				if p.Parent then
					p:Destroy()
				end
			end)
		end
		task.delay(6.5, function()
			if g.model.Parent then
				g.model:Destroy()
			end
		end)
	else
		Remotes.get("Announce"):FireAllClients("O Golem foi embora...", "Ninguém o derrotou a tempo", 3, P.Muted)
		g.model:Destroy()
	end
	Remotes.get("BossState"):FireAllClients({
		active = false,
		name = "Golem Sucata",
		hp = 0,
		maxHp = g.maxHp,
		phase = g.phase,
		result = result,
	})
	nextSpawnAt = os.clock() + COOLDOWN
	for _, r in rockFolder:GetChildren() do
		r:Destroy()
	end
end

local function summon()
	local center = Vector3.new(island.pos.X, groundY, island.pos.Z)
	local count = math.clamp(#Players:GetPlayers(), 1, 8)
	local maxHp = 3200 + 1300 * count
	local g = buildGolem(CFrame.new(center + Vector3.new(0, 0, -30)))
	g.hp = maxHp
	g.maxHp = maxHp
	g.phase = 1
	g.dead = false
	g.damageBy = {}
	g.hitLog = {}
	g.t0 = os.clock()
	g.born = os.clock()
	g.yaw = 0
	g.attackDelay = 3
	g.lastStep = 0
	g.action = nil
	g.staggerUntil = 0
	g.phaseStagger = false
	g.core.Touched:Connect(onCoreTouched)
	Build.billboard(g.head, "🗿 GOLEM SUCATA", { size = UDim2.fromOffset(300, 50), color = P.Accent, offset = Vector3.new(0, 14, 0), maxDistance = 500 })
	golem = g
	Remotes.get("Announce"):FireAllClients("O GOLEM SUCATA DESPERTOU!", "Ilha do Golem — use o tubo de vento laranja e arremesse no núcleo brilhante!", 5, rgb(255, 140, 80))
	Remotes.get("Fx"):FireAllClients("explosion", g.rootCF.Position + Vector3.new(0, 20, 0), 1.6, nil)
	broadcastState()
end

local function step(dt: number)
	local now = os.clock()
	if not golem then
		if now >= nextSpawnAt then
			summon()
		end
		return
	end
	if golem.dead then
		finish("defeated")
		return
	end
	if now - golem.born > MAX_ACTIVE then
		finish("timeout")
		return
	end
	local ok, err = pcall(stepGolem, dt)
	if not ok then
		warn("[Boss] erro:", err)
		finish("timeout")
	end
end

function Boss.summon()
	if not golem then
		summon()
	end
end

function Boss.init()
	island = WorldGen.getIsland("Boss")
	groundY = WorldGen.islandTop(island)
	folder = Build.folder("Boss")
	rockFolder = Build.folder("BossRocks")

	-- pedras iniciais espalhadas na ilha (municao)
	local rng = Random.new(Config.World.Seed + 66)
	local function scatterRocks()
		for i = 1, 8 do
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(30, island.radius - 26)
			spawnRock(Vector3.new(island.pos.X + math.cos(a) * r, groundY + 4, island.pos.Z + math.sin(a) * r), nil, false)
		end
	end
	scatterRocks()

	local acc, accBroadcast, accRocks = 0, 0, 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		accBroadcast += dt
		accRocks += dt
		if acc >= 0.05 then
			local d = acc
			acc = 0
			step(d)
		end
		if golem and accBroadcast >= 0.5 then
			accBroadcast = 0
			broadcastState()
		end
		-- reabastece municao em volta da ilha durante a luta
		if golem and accRocks >= 6 then
			accRocks = 0
			if #rockFolder:GetChildren() < 12 then
				local a = rng:NextNumber(0, math.pi * 2)
				local r = rng:NextNumber(30, island.radius - 26)
				spawnRock(Vector3.new(island.pos.X + math.cos(a) * r, groundY + 30, island.pos.Z + math.sin(a) * r), nil, false)
			end
		end
	end)
end

return Boss
