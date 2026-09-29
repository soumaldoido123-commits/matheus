--!nonstrict
--[[
	Hub: a Praca Cosmica (centro do mapa). Zona segura, spawn, monumento, loja,
	caça-moedas, placar de recordes, portoes dos biomas e o elevador de vento para a Arena.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Build = require(script.Parent:WaitForChild("Build"))
local WorldGen = require(script.Parent:WaitForChild("WorldGen"))
local Server = script.Parent.Parent
local Data = require(Server:WaitForChild("Data"))
local Board = require(Server:WaitForChild("Board"))
local Pickups = require(Server:WaitForChild("Pickups"))

local Hub = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local P = Config.Palette
local M = Enum.Material

-- Plaza em aneis -----------------------------------------------------------------------------------

local function plaza(folder: Folder, gy: number)
	local c = CFrame.new(0, gy, 0)
	Build.cyl(folder, c * CFrame.new(0, -0.9, 0), 4.6, 132, rgb(226, 218, 240), M.Marble, { name = "PlazaOuter" })
	Build.cyl(folder, c * CFrame.new(0, -0.55, 0), 4.6, 108, rgb(255, 240, 214), M.Marble, { name = "PlazaMid" })
	Build.cyl(folder, c * CFrame.new(0, -0.2, 0), 4.6, 76, rgb(142, 226, 214), M.Marble, { name = "PlazaInner" })
	-- anel de neon na borda do miolo
	Build.cyl(folder, c * CFrame.new(0, 2.15, 0), 0.25, 76.5, P.Accent, M.Neon, { collide = false, name = "PlazaRim" })
	Build.cyl(folder, c * CFrame.new(0, 2.15, 0), 0.26, 74, rgb(142, 226, 214), M.Marble, { collide = false })

	-- rosa dos ventos no chao: 8 raios de neon
	for i = 0, 7 do
		local a = i * math.pi / 4
		local len = (i % 2 == 0) and 34 or 22
		Build.block(
			folder,
			c * CFrame.Angles(0, a, 0) * CFrame.new(0, 2.2, -(len / 2 + 8)),
			Vector3.new(1.6, 0.2, len),
			(i % 2 == 0) and P.Pink or P.Blue,
			M.Neon,
			{ collide = false, shadow = false }
		)
	end
	-- pontinhos de neon em circulo
	for i = 0, 35 do
		local a = i / 36 * math.pi * 2
		Build.ball(folder, c * CFrame.new(math.cos(a) * 52, 2.4, math.sin(a) * 52), 1.4, P.Accent2, M.Neon, { collide = false, shadow = false })
	end
end

-- Monumento central ------------------------------------------------------------------------------------

local function monument(folder: Folder, gy: number)
	local m = Build.model(folder, "Monument")
	local base = CFrame.new(0, gy + 2, 0)
	Build.cyl(m, base * CFrame.new(0, 1, 0), 2, 22, rgb(200, 190, 230), M.Marble)
	Build.cyl(m, base * CFrame.new(0, 3, 0), 2, 16, rgb(160, 150, 210), M.Marble)
	Build.cyl(m, base * CFrame.new(0, 12, 0), 18, 4.6, rgb(120, 110, 190), M.Marble)
	-- cristal flutuante
	local crystal = Build.ball(m, base * CFrame.new(0, 27, 0), 9, P.Purple, M.Neon, { collide = false, name = "Crystal" })
	crystal.Transparency = 0.1
	Build.light(crystal, P.Purple, 3, 60, false)
	Build.bob(crystal, 1.6, 4)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Rate = 18
	sparkles.Lifetime = NumberRange.new(1.5, 3)
	sparkles.Speed = NumberRange.new(2, 6)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Color = ColorSequence.new(P.Accent2, P.Pink)
	sparkles.Parent = crystal

	-- aneis de esferas orbitando (giram no cliente)
	for ringIdx = 1, 3 do
		local orbit = Build.model(m, "Orbit" .. ringIdx)
		local pivot = Build.block(orbit, base * CFrame.new(0, 27, 0), Vector3.one, P.Ink, M.SmoothPlastic, { collide = false, transparency = 1, query = false })
		orbit.PrimaryPart = pivot
		local n = 5 + ringIdx * 2
		local radius = 8 + ringIdx * 3.2
		for i = 1, n do
			local a = i / n * math.pi * 2
			local color = Color3.fromHSV((i / n + ringIdx * 0.2) % 1, 0.7, 1)
			Build.ball(orbit, pivot.CFrame * CFrame.new(math.cos(a) * radius, math.sin(a * 2) * 1.2, math.sin(a) * radius), 1.8 + ringIdx * 0.3, color, M.Neon, { collide = false, shadow = false })
		end
		Build.spin(orbit, "Y", (ringIdx % 2 == 0 and -1 or 1) * (18 + ringIdx * 9))
	end
	-- placa
	local plaque = Build.block(m, base * CFrame.new(0, 3.2, 9.05), Vector3.new(9, 2.6, 0.4), rgb(40, 36, 80), M.SmoothPlastic)
	Build.label(plaque, "TUDO VOA!", { color = P.Accent })
end

-- Postes, bancos, canteiros ------------------------------------------------------------------------------------

local function decoration(folder: Folder, gy: number, rng: Random)
	for i = 0, 7 do
		local a = (i + 0.5) / 8 * math.pi * 2
		Build.lamp(folder, Vector3.new(math.cos(a) * 60, gy + 1.4, math.sin(a) * 60), 13, (i % 2 == 0) and rgb(255, 226, 150) or rgb(170, 240, 255))
	end
	-- bancos entre os postes
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local cf = CFrame.new(math.cos(a) * 58, gy + 2.2, math.sin(a) * 58) * CFrame.Angles(0, -a + math.pi / 2, 0)
		local m = Build.model(folder, "Bench")
		Build.block(m, cf * CFrame.new(0, 0.9, 0), Vector3.new(7, 0.6, 2.2), rgb(190, 130, 80), M.Wood)
		Build.block(m, cf * CFrame.new(0, 2.1, -0.9), Vector3.new(7, 1.6, 0.4), rgb(190, 130, 80), M.Wood)
		for _, x in { -3, 3 } do
			Build.block(m, cf * CFrame.new(x, 0.3, 0), Vector3.new(0.5, 1.2, 2), rgb(60, 60, 84), M.Metal)
		end
	end
	-- canteiros de flores (circulos de bolas coloridas)
	for i = 0, 3 do
		local a = (i + 0.5) / 4 * math.pi * 2 + math.pi / 8
		local cx, cz = math.cos(a) * 40, math.sin(a) * 40
		Build.cyl(folder, CFrame.new(cx, gy + 2.6, cz), 1.2, 12, rgb(120, 90, 70), M.Slate)
		for k = 1, 9 do
			local aa = k / 9 * math.pi * 2
			local color = Color3.fromHSV(rng:NextNumber(0, 1), 0.65, 1)
			local f = Build.ball(folder, CFrame.new(cx + math.cos(aa) * 3.6, gy + 3.6, cz + math.sin(aa) * 3.6), 1.8, color, M.SmoothPlastic, { collide = false })
			Build.sway(f, 6, 2.5)
		end
		Build.ball(folder, CFrame.new(cx, gy + 4, cz), 3, rgb(255, 230, 90), M.SmoothPlastic, { collide = false })
	end
end

-- Loja de brinquedos -------------------------------------------------------------------------------------------------

local function shop(folder: Folder, gy: number)
	local pos = Vector3.new(-56, gy, 44)
	local cf = CFrame.lookAt(pos, Vector3.new(0, gy, 0))
	local m = Build.house(folder, cf, Vector3.new(24, 12, 16), rgb(255, 150, 200), rgb(255, 210, 80), "ToyShop")
	-- toldo listrado
	for i = -3, 3 do
		local c = (i % 2 == 0) and rgb(255, 255, 255) or rgb(255, 70, 110)
		Build.block(m, cf * CFrame.new(i * 3.4, 8.2, 11) * CFrame.Angles(math.rad(-22), 0, 0), Vector3.new(3.4, 0.5, 6), c, M.Fabric)
	end
	local sign = Build.block(m, cf * CFrame.new(0, 15.6, 8.2), Vector3.new(22, 4, 0.6), rgb(50, 40, 110), M.SmoothPlastic)
	Build.label(sign, "🧸 LOJA DE BRINQUEDOS", { color = P.Accent })
	-- balcao e prompt
	local counter = Build.block(m, cf * CFrame.new(0, 2.6, 10.2), Vector3.new(12, 2.2, 2.2), rgb(150, 100, 70), M.Wood)
	Build.prompt(counter, "Abrir loja", "Loja de Brinquedos", "shop")
	-- vitrine com brinquedos giratorios
	for i, color in { P.Pink, P.Blue, P.Green } do
		local b = Build.ball(m, cf * CFrame.new((i - 2) * 6, 5.5, 10.4), 2.4, color, M.Neon, { collide = false })
		Build.bob(b, 0.4, 2 + i * 0.4)
	end
end

-- Cata-moedas (slot machine) -------------------------------------------------------------------------------------------------

local function slotMachine(folder: Folder, gy: number)
	local pos = Vector3.new(56, gy, 40)
	local cf = CFrame.lookAt(pos, Vector3.new(0, gy, 0))
	local m = Build.model(folder, "SlotMachine")
	Build.foundation(m, cf, Vector3.new(9, 1, 7))
	local body = Build.block(m, cf * CFrame.new(0, 6.5, 0), Vector3.new(8, 12, 5), rgb(220, 50, 70), M.SmoothPlastic)
	Build.block(m, cf * CFrame.new(0, 12.8, 0), Vector3.new(9, 1.6, 6), P.Accent, M.Neon, { collide = false })
	local screen = Build.block(m, cf * CFrame.new(0, 8, 2.55), Vector3.new(6, 4, 0.3), rgb(20, 24, 50), M.SmoothPlastic)
	Build.label(screen, "🪙 🍒 💎", { color = P.White })
	local head = Build.block(m, cf * CFrame.new(0, 12.3, 2.6), Vector3.new(7.2, 1.6, 0.3), rgb(255, 230, 90), M.Neon, { collide = false })
	Build.label(head, "CAÇA-MOEDAS", { color = rgb(120, 20, 40), stroke = false })
	-- alavanca
	local lever = Build.cyl(m, cf * CFrame.new(4.9, 9, 0) * CFrame.Angles(0, 0, math.rad(-20)), 5, 0.6, rgb(200, 200, 210), M.Metal)
	Build.ball(m, cf * CFrame.new(5.6, 11.4, 0), 1.8, P.Red, M.SmoothPlastic, { collide = false })
	Build.light(head, P.Accent, 1.5, 24, false)
	Build.pulse(head, 0.8, 2.6, 1.2)
	local pp = Build.prompt(body, "Puxar alavanca", "Caça-moedas (a cada 15 min)", "slot", 0.3)
	pp.MaxActivationDistance = 14

	pp.Triggered:Connect(function(player)
		if not Data.isLoaded(player) then
			return
		end
		local d = Data.get(player)
		local remaining = (d.LastSlot + Config.Economy.SlotCooldown) - os.time()
		if remaining > 0 then
			Remotes.get("Notify"):FireClient(player, string.format("O caça-moedas recarrega em %s", Util.formatTime(remaining)), "bad")
			return
		end
		Data.set(player, "LastSlot", os.time())
		local base = math.random(Config.Economy.SlotMin, Config.Economy.SlotMax)
		local coins = math.floor(base * (1 + d.Level * 0.06))
		Pickups.burst(lever.Position + Vector3.new(0, 4, 0), coins, math.clamp(coins // 10, 6, 24))
		Remotes.get("Fx"):FireAllClients("confetti", lever.Position + Vector3.new(0, 4, 0), 1.2, nil)
		Remotes.get("Announce"):FireClient(player, "JACKPOT!", coins .. " moedas caíram!", 2.2, P.Accent)
	end)
end

-- Placar de recordes -----------------------------------------------------------------------------------------------------------------

local function leaderboard(folder: Folder, gy: number)
	local pos = Vector3.new(0, gy, -84)
	local cf = CFrame.lookAt(pos, Vector3.new(0, gy, 0))
	local m = Build.model(folder, "Leaderboard")
	Build.foundation(m, cf, Vector3.new(34, 1, 5))
	for _, x in { -15, 15 } do
		Build.block(m, cf * CFrame.new(x, 9, 0), Vector3.new(2, 18, 2), rgb(60, 56, 110), M.Metal)
	end
	local panel = Build.block(m, cf * CFrame.new(0, 13, 0), Vector3.new(32, 18, 1), rgb(24, 26, 56), M.SmoothPlastic)
	Build.block(m, cf * CFrame.new(0, 13, 0.15), Vector3.new(33, 19, 0.8), P.Accent, M.Neon, { collide = false, shadow = false }).Transparency = 0.6

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Board"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 90)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = P.Accent
	title.Text = "🏆 MAIORES ARREMESSOS"
	title.Parent = gui

	local rows = {}
	for i = 1, 10 do
		local row = Instance.new("TextLabel")
		row.BackgroundTransparency = 1
		row.Position = UDim2.new(0, 60, 0, 100 + (i - 1) * 60)
		row.Size = UDim2.new(1, -120, 0, 56)
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = (i == 1) and P.Accent or ((i <= 3) and P.Accent2 or P.White)
		row.Text = ""
		row.Parent = gui
		rows[i] = row
	end

	local function refresh()
		local top = Board.top()
		for i = 1, 10 do
			local e = top[i]
			if e then
				rows[i].Text = string.format("%d.  %s  —  %d studs", i, e.name, e.value)
			else
				rows[i].Text = string.format("%d.  ---", i)
			end
		end
	end
	refresh()
	Board.Changed:Connect(function()
		task.delay(1, refresh)
	end)
	task.spawn(function()
		while true do
			task.wait(45)
			refresh()
		end
	end)
end

-- Portoes dos biomas ------------------------------------------------------------------------------------------------------------------------

local function gates(folder: Folder)
	for key, b in Config.Biomes do
		if key ~= "Hub" then
			local dir = Vector3.new(b.center.X, 0, b.center.Y).Unit
			local flat = dir * 112
			local y = Build.y(flat.X, flat.Z)
			local origin = Vector3.new(flat.X, y, flat.Z)
			local cf = CFrame.lookAt(origin, origin + dir)
			local m = Build.model(folder, "Gate_" .. key)
			for _, x in { -11, 11 } do
				Build.foundation(m, cf * CFrame.new(x, 0, 0), Vector3.new(4, 1, 4))
				Build.block(m, cf * CFrame.new(x, 8, 0), Vector3.new(3.4, 16, 3.4), rgb(100, 90, 170), M.Marble)
				local orb = Build.ball(m, cf * CFrame.new(x, 17.6, 0), 3.4, P.Accent2, M.Neon, { collide = false })
				Build.light(orb, P.Accent2, 1.6, 22, false)
				Build.bob(orb, 0.5, 3)
			end
			local beam = Build.block(m, cf * CFrame.new(0, 16.2, 0), Vector3.new(26, 4.4, 2), rgb(60, 54, 120), M.SmoothPlastic)
			Build.label(beam, b.icon .. " " .. string.upper(b.name), { color = P.Accent, face = Enum.NormalId.Front })
			Build.label(beam, "PRAÇA CÓSMICA", { color = P.Accent2, face = Enum.NormalId.Back })
		end
	end
end

-- Elevador de vento para a Arena (ilha flutuante sobre a praca) --------------------------------------------------------------------------------

function Hub.windTube(folder: Folder, x: number, z: number, topY: number, name: string, color: Color3?)
	local baseY = Build.y(x, z)
	local height = topY - baseY
	local c = color or P.Accent2
	local m = Build.model(folder, "Wind_" .. name)
	-- base luminosa
	Build.cyl(m, CFrame.new(x, baseY + 0.4, z), 1.2, 22, rgb(50, 60, 110), M.Metal)
	Build.cyl(m, CFrame.new(x, baseY + 1.1, z), 0.3, 18, c, M.Neon, { collide = false, shadow = false })
	-- tubo translucido (zona de vento)
	local tube = Build.cyl(m, CFrame.new(x, baseY + height / 2, z), height, 16, c, M.Neon, { collide = false, transparency = 0.86, shadow = false, name = "WindZone" })
	tube.CanQuery = false
	Build.tag(tube, "TV_Wind", { Speed = 78, Top = topY, Radius = 8.5 })
	-- particulas subindo
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, -height / 2, 0)
	att.Parent = tube
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 40
	pe.Lifetime = NumberRange.new(3, 5)
	pe.Speed = NumberRange.new(38, 60)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.SpreadAngle = Vector2.new(4, 4)
	pe.Shape = Enum.ParticleEmitterShape.Cylinder
	pe.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0.2) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	pe.Color = ColorSequence.new(c, Color3.new(1, 1, 1))
	pe.LightEmission = 1
	pe.Parent = att
	local label = Build.block(m, CFrame.new(x, baseY + 9, z), Vector3.one, P.Ink, M.SmoothPlastic, { collide = false, transparency = 1, query = false })
	Build.billboard(label, "⬆ " .. name, { size = UDim2.fromOffset(260, 46), color = c, offset = Vector3.new(0, 4, 0) })
	return m
end

-- Trampolins de chao (jump pads) --------------------------------------------------------------------------------------------------------------------

function Hub.jumpPad(folder: Folder, pos: Vector3, power: number, color: Color3?, dirVec: Vector3?)
	local c = color or P.Pink
	local m = Build.model(folder, "JumpPad")
	Build.cyl(m, CFrame.new(pos + Vector3.new(0, 0.5, 0)), 1, 9, rgb(50, 56, 100), M.Metal)
	local pad = Build.cyl(m, CFrame.new(pos + Vector3.new(0, 1.1, 0)), 0.4, 7.4, c, M.Neon, { name = "PadTop" })
	Build.tag(pad, "TV_JumpPad", { Power = power, DirX = dirVec and dirVec.X or 0, DirY = dirVec and dirVec.Y or 1, DirZ = dirVec and dirVec.Z or 0 })
	Build.pulse(pad, 0.7, 2.2, 1.3)
	return pad
end

-- Spawn ------------------------------------------------------------------------------------------------------------------------------------------------

local function spawns(gy: number)
	local folder = Build.folder("Spawns")
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.3
		local s = Instance.new("SpawnLocation")
		s.Name = "Spawn" .. i
		s.Anchored = true
		s.CanCollide = false
		s.Neutral = true
		s.Duration = 0
		s.Transparency = 1
		s.Size = Vector3.new(6, 1, 6)
		s.CFrame = CFrame.new(math.cos(a) * 26, gy + 2.6, math.sin(a) * 26)
		s.Parent = folder
	end
end

-- Arvores em volta da praca -------------------------------------------------------------------------------------------------------------------------------

local function trees(folder: Folder, rng: Random)
	for _ = 1, 70 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(74, 118)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if WorldGen.roadDistance(x, z) > 14 then
			local pos = Build.ground(x, z)
			if pos then
				Build.tree(folder, pos, (rng:NextNumber() < 0.7) and "oak" or "round", rng:NextNumber(0.9, 1.5), rng)
			end
		end
	end
end

function Hub.build()
	local folder = Build.folder("Hub")
	local rng = Random.new(Config.World.Seed + 1)
	local gy = Build.y(0, 0)

	plaza(folder, gy)
	monument(folder, gy)
	decoration(folder, gy, rng)
	shop(folder, gy)
	slotMachine(folder, gy)
	leaderboard(folder, gy)
	gates(folder)
	trees(folder, rng)
	spawns(gy)

	-- jump pads em volta
	for i = 0, 5 do
		local a = (i + 0.5) / 6 * math.pi * 2 + math.pi / 12
		Hub.jumpPad(folder, Vector3.new(math.cos(a) * 88, gy + 1.6, math.sin(a) * 88), 105, Color3.fromHSV(i / 6, 0.7, 1))
	end
	_ = Players
end

return Hub
