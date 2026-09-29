--!nonstrict
--[[
	Arena: "Arena do Caos" na ilha flutuante sobre a praca.
	Plataforma suspensa: quem cai perde a rodada. Robos rolantes vem em ondas e tentam te empurrar
	para fora — agarre-os e arremesse-os para o vazio! Tambem serve para duelos entre jogadores.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Server = script.Parent.Parent
local Build = require(Server:WaitForChild("World"):WaitForChild("Build"))
local WorldGen = require(Server:WaitForChild("World"):WaitForChild("WorldGen"))
local Hub = require(Server:WaitForChild("World"):WaitForChild("Hub"))
local Data = require(Server:WaitForChild("Data"))
local Quests = require(Server:WaitForChild("Quests"))
local Physics = require(Server:WaitForChild("Physics"))
local Ragdoll = require(Server:WaitForChild("Ragdoll"))

local Arena = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local PLATFORM_R = 56
local PLATFORM_LIFT = 46 -- altura da plataforma acima da grama da ilha
local MAX_WAVE = 8

local center: Vector3 -- centro da plataforma (topo)
local floorTop: number
local folder: Folder
local botFolder: Folder
local scoreLabels = {}

local state = "idle"
local wave = 0
local bots = {} -- { part, kind, born, lastBump }
local inArena = {} -- [player] = true
local emptySince = nil
local countdownEnd = 0
local idleUntil = 0
local presenceTicks = 0
local lastBumpAt = {} -- [player] = t
local lastText = ""

-- Robos -----------------------------------------------------------------------------------------------------------------------------

local KINDS = {
	basic = { size = 4.2, density = 1.2, color = rgb(90, 190, 255), accel = 46, maxSpeed = 24, bump = 60, name = "Robô" },
	jumper = { size = 3.6, density = 1.0, color = rgb(255, 180, 60), accel = 40, maxSpeed = 22, bump = 55, hop = true, name = "Saltador" },
	tank = { size = 7, density = 2.6, color = rgb(255, 90, 100), accel = 34, maxSpeed = 18, bump = 90, name = "Tanque" },
	boss = { size = 12, density = 3.4, color = rgb(190, 90, 255), accel = 30, maxSpeed = 15, bump = 120, name = "Chefe Robô", boss = true },
}

local function spawnBot(kind: string, pos: Vector3)
	local def = KINDS[kind]
	local m = Instance.new("Model")
	m.Name = "ArenaBot_" .. kind
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.one * def.size
	body.Color = def.color
	body.Material = M.Metal
	body.Position = pos
	body.CustomPhysicalProperties = PhysicalProperties.new(def.density, 0.25, 0.35, 1, 1)
	body.Parent = m
	m.PrimaryPart = body

	local function deco(offset: CFrame, size: Vector3, color: Color3, material: any, shape: any?): Part
		local p = Instance.new("Part")
		p.Shape = shape or Enum.PartType.Block
		p.Size = size
		p.CFrame = body.CFrame * offset
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.Massless = true
		p.CanTouch = false
		p.Parent = m
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = p
		w.Parent = p
		return p
	end
	local s = def.size
	-- olhos (para -Z)
	for _, sx in { -0.24, 0.24 } do
		deco(CFrame.new(sx * s, 0.18 * s, -0.42 * s), Vector3.one * s * 0.3, rgb(255, 255, 255), M.SmoothPlastic, Enum.PartType.Ball)
		deco(CFrame.new(sx * s, 0.18 * s, -0.53 * s), Vector3.one * s * 0.14, rgb(20, 20, 30), M.SmoothPlastic, Enum.PartType.Ball)
	end
	deco(CFrame.new(0, 0.62 * s, 0), Vector3.new(0.07 * s, 0.35 * s, 0.07 * s), rgb(200, 200, 210), M.Metal)
	local bulb = deco(CFrame.new(0, 0.85 * s, 0), Vector3.one * s * 0.16, def.boss and rgb(255, 80, 200) or rgb(255, 90, 90), M.Neon, Enum.PartType.Ball)
	if def.boss then
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 80, 200)
		l.Range = 30
		l.Brightness = 2
		l.Parent = bulb
	end
	-- listra
	local band = deco(CFrame.new(0, 0, 0), Vector3.new(0.3 * s, s * 1.02, s * 1.02), rgb(30, 34, 60), M.Metal, Enum.PartType.Cylinder)
	band.Color = rgb(30, 34, 60)

	m.Parent = botFolder
	CollectionService:AddTag(body, Config.Tags.Grabbable)
	body:SetAttribute("Behavior", "none")
	body:SetAttribute("Bot", true)
	body:SetAttribute("BotKind", kind)
	pcall(function()
		body:SetNetworkOwner(nil)
	end)
	table.insert(bots, { part = body, model = m, kind = kind, born = os.clock(), lastHop = 0, def = def })
	return body
end

local function removeBot(rec)
	local i = table.find(bots, rec)
	if i then
		table.remove(bots, i)
	end
	if rec.model and rec.model.Parent then
		rec.model:Destroy()
	end
end

local function clearBots()
	for i = #bots, 1, -1 do
		removeBot(bots[i])
	end
end

-- Presenca na plataforma -------------------------------------------------------------------------------------------------------------------

local function onPlatform(pos: Vector3): boolean
	local flat = Vector3.new(pos.X - center.X, 0, pos.Z - center.Z).Magnitude
	return flat < PLATFORM_R + 2 and pos.Y > floorTop - 4 and pos.Y < floorTop + 60
end

local function nearestPlayerTo(pos: Vector3)
	local best, bestD, bestChar = nil, 1e9, nil
	for player in inArena do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - pos).Magnitude
			if d < bestD then
				best, bestD, bestChar = hrp, d, char
			end
		end
	end
	return best, bestD, bestChar
end

local function broadcast()
	local payload = { state = state, wave = wave, maxWave = MAX_WAVE, bots = #bots, countdown = math.max(0, math.ceil(countdownEnd - os.clock())) }
	for player in inArena do
		Remotes.get("ArenaState"):FireClient(player, payload)
	end
	local text
	if state == "idle" then
		text = "ARENA DO CAOS\nSuba na plataforma para começar!"
	elseif state == "countdown" then
		text = string.format("PREPARAR!\n%d", payload.countdown)
	else
		text = string.format("ONDA %d/%d\nRobôs: %d", wave, MAX_WAVE, #bots)
	end
	if text ~= lastText then
		lastText = text
		for _, l in scoreLabels do
			l.Text = text
		end
	end
end

local function creditFor(inst: Instance, model: Model?): Player?
	local id = inst:GetAttribute("LastThrower") or (model and model:GetAttribute("LastHitBy"))
	local t = inst:GetAttribute("LastThrowT") or (model and model:GetAttribute("LastHitTime"))
	if id and t and os.clock() - t < 14 then
		return Players:GetPlayerByUserId(id)
	end
	return nil
end

local function giveWaveReward(w: number, final: boolean)
	for player in inArena do
		if Data.isLoaded(player) then
			local coins = 25 + w * 18 + (final and 300 or 0)
			Data.addCoins(player, coins, final and "Arena vencida" or ("Onda " .. w))
			Data.addXP(player, coins)
			if final then
				Data.addStat(player, "Wins", 1)
			end
		end
	end
end

local function startWave(w: number)
	wave = w
	state = "wave"
	local plan = {}
	local nBasic = 2 + w
	for _ = 1, nBasic do
		table.insert(plan, "basic")
	end
	if w >= 2 then
		for _ = 1, math.floor(w / 2) + 1 do
			table.insert(plan, "jumper")
		end
	end
	if w >= 4 then
		for _ = 1, math.floor((w - 2) / 2) do
			table.insert(plan, "tank")
		end
	end
	if w == 5 or w == MAX_WAVE then
		table.insert(plan, "boss")
	end
	local rng = Random.new()
	for _, kind in plan do
		if #bots >= 26 then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(30, PLATFORM_R - 6)
		spawnBot(kind, center + Vector3.new(math.cos(a) * r, 14 + rng:NextNumber(0, 8), math.sin(a) * r))
	end
	for player in inArena do
		Remotes.get("Announce"):FireClient(player, w == MAX_WAVE and "ONDA FINAL!" or ("ONDA " .. w), #plan .. " robôs a caminho", 2.2, w == MAX_WAVE and P.Pink or P.Accent2)
	end
	Remotes.get("Fx"):FireAllClients("shock", center + Vector3.new(0, 4, 0), 1.5, nil)
end

-- Laco principal (0.15 s): robos ---------------------------------------------------------------------------------------------------------------

local function botStep()
	local now = os.clock()
	for i = #bots, 1, -1 do
		local rec = bots[i]
		local p = rec.part
		if not p.Parent then
			table.remove(bots, i)
		elseif p.Position.Y < floorTop - 14 or now - rec.born > 240 then
			-- caiu do palco: quem arremessou por ultimo ganha creditos
			local killer = p.Position.Y < floorTop - 14 and creditFor(p, rec.model) or nil
			if killer and Data.isLoaded(killer) then
				local coins = (rec.kind == "boss" and 200) or (rec.kind == "tank" and 30) or 12
				Data.addCoins(killer, coins, "derrubou " .. rec.def.name)
				Data.addXP(killer, coins)
				Quests.report(killer, "bot", 1)
				Remotes.get("ScorePopup"):FireClient(killer, p.Position + Vector3.new(0, 10, 0), "+" .. coins .. " 🪙", P.Green)
			end
			removeBot(rec)
		elseif not p:GetAttribute("HeldBy") and not CollectionService:HasTag(p, Config.Tags.Airborne) then
			local hrp, dist = nearestPlayerTo(p.Position)
			if hrp then
				local dir = Vector3.new(hrp.Position.X - p.Position.X, 0, hrp.Position.Z - p.Position.Z)
				if dir.Magnitude > 0.1 then
					dir = dir.Unit
					local v = p.AssemblyLinearVelocity
					local flatSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
					if flatSpeed < rec.def.maxSpeed then
						p:ApplyImpulse(dir * p.AssemblyMass * rec.def.accel * 0.15)
					end
					if rec.def.hop and now - rec.lastHop > 1.8 and dist < 40 then
						rec.lastHop = now
						p:ApplyImpulse(Vector3.new(dir.X * 14, 62, dir.Z * 14) * p.AssemblyMass)
					end
				end
				-- empurrao
				if dist < p.Size.X / 2 + 3.6 then
					local char = hrp.Parent
					local player = Players:GetPlayerFromCharacter(char)
					if player and not Physics.isProtected(player) then
						local last = lastBumpAt[player]
						if not last or now - last > 2.2 then
							lastBumpAt[player] = now
							local away = Util.safeUnit(Vector3.new(hrp.Position.X - p.Position.X, 0, hrp.Position.Z - p.Position.Z), Vector3.zAxis)
							Ragdoll.knock(char, 1.4)
							Physics.launch(char, away * rec.def.bump + Vector3.new(0, 26, 0))
							Remotes.get("Struck"):FireClient(player, 0.5, away)
							Remotes.get("Fx"):FireAllClients("impact", hrp.Position, 0.7, { mat = "Metal", color = rec.def.color })
						end
					end
				end
			end
		end
	end
end

-- Laco lento (0.5 s): jogadores, ondas ---------------------------------------------------------------------------------------------------------

local function playerStep()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local pos = hrp.Position
			if onPlatform(pos) then
				if not inArena[player] then
					inArena[player] = true
					player:SetAttribute("InArena", true)
					Remotes.get("Notify"):FireClient(player, "⚔️ Você entrou na Arena do Caos!", "info")
				end
			elseif inArena[player] then
				-- saiu da plataforma: caiu (abaixo) ou pulou fora
				inArena[player] = nil
				player:SetAttribute("InArena", nil)
				if pos.Y < floorTop - 6 then
					Remotes.get("Notify"):FireClient(player, "💥 Você caiu da arena!", "bad")
					local killer = creditFor(hrp, char)
					if killer and killer ~= player and Data.isLoaded(killer) then
						Data.addCoins(killer, 30, "derrubou " .. player.DisplayName)
						Data.addXP(killer, 25)
					end
				end
			end
		elseif inArena[player] then
			inArena[player] = nil
			player:SetAttribute("InArena", nil)
		end
	end

	local count = 0
	for _ in inArena do
		count += 1
	end

	if state == "idle" then
		if count > 0 and now > idleUntil then
			presenceTicks += 1
			if presenceTicks >= 3 then
				state = "countdown"
				countdownEnd = now + 5
			end
		else
			presenceTicks = 0
		end
	elseif state == "countdown" then
		if count == 0 then
			state = "idle"
		elseif now >= countdownEnd then
			startWave(1)
		end
	elseif state == "wave" then
		if count == 0 then
			emptySince = emptySince or now
			if now - emptySince > 12 then
				clearBots()
				state = "idle"
				wave = 0
				emptySince = nil
				idleUntil = now + 4
			end
		else
			emptySince = nil
			if #bots == 0 then
				local final = wave >= MAX_WAVE
				giveWaveReward(wave, final)
				if final then
					for player in inArena do
						Remotes.get("Announce"):FireClient(player, "ARENA CONQUISTADA!", "Você derrotou todas as ondas", 4, P.Accent)
					end
					Remotes.get("Fx"):FireAllClients("confetti", center + Vector3.new(0, 6, 0), 1.8, nil)
					state = "idle"
					wave = 0
					idleUntil = now + 20
				else
					state = "countdown"
					countdownEnd = now + 4
					-- proxima onda depois da contagem
					task.delay(4, function()
						if state == "countdown" and wave < MAX_WAVE then
							startWave(wave + 1)
						end
					end)
				end
			end
		end
	end
	broadcast()
end

-- Construcao ---------------------------------------------------------------------------------------------------------------------------------

local function buildPlatform()
	local isl = WorldGen.getIsland("Arena")
	local top = WorldGen.islandTop(isl)
	floorTop = top + PLATFORM_LIFT + 2
	center = Vector3.new(isl.pos.X, floorTop, isl.pos.Z)
	local c = CFrame.new(center.X, floorTop - 2, center.Z)

	local m = Build.model(folder, "ArenaPlatform")
	-- coluna central e pedestal
	Build.cyl(m, CFrame.new(center.X, top + PLATFORM_LIFT / 2 - 2, center.Z), PLATFORM_LIFT + 4, 22, rgb(90, 84, 130), M.Marble)
	Build.cyl(m, CFrame.new(center.X, top + 2, center.Z), 4, 34, rgb(110, 100, 160), M.Marble)
	-- piso
	Build.cyl(m, c, 4, PLATFORM_R * 2, rgb(40, 36, 78), M.Marble, { name = "ArenaFloor" })
	Build.cyl(m, c * CFrame.new(0, 2.05, 0), 0.3, PLATFORM_R * 2 - 3, rgb(60, 54, 110), M.SmoothPlastic, { collide = false })
	Build.cyl(m, c * CFrame.new(0, 2.15, 0), 0.2, PLATFORM_R * 2 + 0.5, P.Pink, M.Neon, { collide = false, shadow = false })
	Build.cyl(m, c * CFrame.new(0, 2.25, 0), 0.3, PLATFORM_R * 2 - 8, rgb(40, 36, 78), M.Marble, { collide = false })
	for i = 1, 4 do
		Build.cyl(m, c * CFrame.new(0, 2.4, 0), 0.1, PLATFORM_R * 2 - i * 16, i % 2 == 0 and P.Accent2 or P.Purple, M.Neon, { collide = false, shadow = false, transparency = 0.5 })
	end
	-- pilares de luz ao redor
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local px, pz = center.X + math.cos(a) * (PLATFORM_R + 1), center.Z + math.sin(a) * (PLATFORM_R + 1)
		Build.cyl(m, CFrame.new(px, floorTop + 6, pz), 12, 2.2, rgb(70, 66, 120), M.Metal)
		local orb = Build.ball(m, CFrame.new(px, floorTop + 13.5, pz), 3.4, Color3.fromHSV(i / 8, 0.6, 1), M.Neon, { collide = false })
		Build.light(orb, Color3.fromHSV(i / 8, 0.6, 1), 2, 40, false)
		Build.pulse(orb, 0.8, 3, 2 + i * 0.2)
	end
	-- placar sobre a coluna
	local pole = Build.cyl(m, CFrame.new(center.X, floorTop + 20, center.Z), 40, 4, rgb(80, 74, 130), M.Metal, { collide = false })
	local screen = Build.block(m, CFrame.new(center.X, floorTop + 44, center.Z), Vector3.new(30, 12, 1), rgb(20, 22, 50), M.SmoothPlastic, { collide = false })
	local screen2 = Build.block(m, CFrame.new(center.X, floorTop + 44, center.Z), Vector3.new(1, 12, 30), rgb(20, 22, 50), M.SmoothPlastic, { collide = false })
	table.insert(scoreLabels, Build.label(screen, "ARENA DO CAOS", { color = P.Accent, face = Enum.NormalId.Front, ppu = 30 }))
	table.insert(scoreLabels, Build.label(screen, "ARENA DO CAOS", { color = P.Accent, face = Enum.NormalId.Back, ppu = 30, name = "Label2" }))
	table.insert(scoreLabels, Build.label(screen2, "ARENA DO CAOS", { color = P.Accent, face = Enum.NormalId.Right, ppu = 30, name = "Label3" }))
	table.insert(scoreLabels, Build.label(screen2, "ARENA DO CAOS", { color = P.Accent, face = Enum.NormalId.Left, ppu = 30, name = "Label4" }))

	-- jump pads na base para subir na plataforma
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local px, pz = center.X + math.cos(a) * 26, center.Z + math.sin(a) * 26
		local dir = Vector3.new(-math.cos(a) * 0.35, 1, -math.sin(a) * 0.35)
		Hub.jumpPad(m, Vector3.new(px, top + 1.6, pz), 190, Color3.fromHSV(i / 4, 0.7, 1), dir)
	end
	Build.billboard(pole, "⚔️ ARENA DO CAOS", { size = UDim2.fromOffset(340, 60), color = P.Accent, offset = Vector3.new(0, 26, 0), maxDistance = 400 })
end

local function decorateIsland()
	local isl = WorldGen.getIsland("Arena")
	local top = WorldGen.islandTop(isl)
	local rng = Random.new(Config.World.Seed + 44)
	-- arvores e bancos ao redor (torcida)
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local r = 84 + rng:NextNumber(-4, 4)
		Build.tree(folder, Vector3.new(isl.pos.X + math.cos(a) * r, top - 0.4, isl.pos.Z + math.sin(a) * r), (i % 2 == 0) and "round" or "oak", rng:NextNumber(0.9, 1.4), rng)
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.2
		local cf = CFrame.new(isl.pos.X + math.cos(a) * 70, top + 1, isl.pos.Z + math.sin(a) * 70) * CFrame.Angles(0, -a + math.pi / 2, 0)
		Build.block(folder, cf * CFrame.new(0, 0.9, 0), Vector3.new(8, 0.7, 2.4), rgb(190, 130, 80), M.Wood)
		Build.block(folder, cf * CFrame.new(0, 2.3, -1), Vector3.new(8, 2.2, 0.5), rgb(190, 130, 80), M.Wood)
	end
end

function Arena.init()
	folder = Build.folder("Arena")
	botFolder = Build.folder("ArenaBots")
	buildPlatform()
	decorateIsland()

	local acc, acc2 = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		acc2 += dt
		if acc >= 0.15 then
			acc = 0
			if #bots > 0 then
				local ok, err = pcall(botStep)
				if not ok then
					warn("[Arena] erro nos robos:", err)
				end
			end
		end
		if acc2 >= 0.5 then
			acc2 = 0
			local ok, err = pcall(playerStep)
			if not ok then
				warn("[Arena] erro:", err)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		inArena[p] = nil
		lastBumpAt[p] = nil
	end)
end

return Arena
