--!nonstrict
--[[
	Snow: a Montanha Gelada (norte). Pinheiros nevados, cabana, iglu, bonecos de neve,
	rampa de esqui, lago congelado, bandeira no pico e a entrada da Caverna de Cristal.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Build = require(script.Parent:WaitForChild("Build"))
local Nature = require(script.Parent:WaitForChild("Nature"))
local WorldGen = require(script.Parent:WaitForChild("WorldGen"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Pickups = require(script.Parent.Parent:WaitForChild("Pickups"))

local Snow = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function cabin(folder: Folder, x: number, z: number)
	local y = Build.y(x, z)
	local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, 0))
	local m = Build.house(folder, cf, Vector3.new(22, 11, 16), rgb(168, 116, 76), rgb(240, 248, 255), "Cabin")
	-- neve sobre o telhado
	Build.block(m, cf * CFrame.new(0, 18.2, 0), Vector3.new(24, 1, 18), rgb(250, 252, 255), M.Snow, { collide = false })
	-- chamine com fumaca
	local chim = Build.block(m, cf * CFrame.new(6, 18, -3), Vector3.new(3, 8, 3), rgb(120, 96, 90), M.Brick)
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, 4.4, 0)
	att.Parent = chim
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = SMOKE
	smoke.Rate = 8
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 6) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(rgb(230, 230, 240))
	smoke.Parent = att
	-- luz quente na janela
	local lamp = Build.ball(m, cf * CFrame.new(0, 7, 8.6), 2, rgb(255, 210, 120), M.Neon, { collide = false })
	Build.light(lamp, rgb(255, 200, 120), 2, 26, false)
	Nature.reserve(x, z, 20)
end

local function igloo(folder: Folder, x: number, z: number)
	local y = Build.y(x, z)
	local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, 0))
	local m = Build.model(folder, "Igloo")
	local dome = Build.ball(m, cf * CFrame.new(0, 0, 0), 18, rgb(238, 246, 255), M.Snow)
	Build.cyl(m, cf * CFrame.new(0, 1.8, 8.8) * CFrame.Angles(math.pi / 2, 0, 0), 6, 6.4, rgb(226, 238, 252), M.Snow)
	Build.block(m, cf * CFrame.new(0, 2.2, 12) , Vector3.new(4, 4, 1), rgb(30, 40, 80), M.SmoothPlastic, { collide = false })
	local lamp = Build.ball(m, cf * CFrame.new(0, 5, 6), 1.6, rgb(150, 220, 255), M.Neon, { collide = false })
	Build.light(lamp, rgb(150, 220, 255), 1.5, 22, false)
	m.PrimaryPart = dome
	Nature.reserve(x, z, 14)
end

local function snowman(folder: Folder, pos: Vector3, rng: Random)
	local m = Build.model(folder, "Snowman")
	local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	local s = rng:NextNumber(0.9, 1.5)
	local white = rgb(248, 250, 255)
	local b1 = Build.ball(m, cf * CFrame.new(0, 2.6 * s, 0), 5.6 * s, white, M.Snow)
	Build.ball(m, cf * CFrame.new(0, 6.4 * s, 0), 4 * s, white, M.Snow, { collide = false })
	Build.ball(m, cf * CFrame.new(0, 9.4 * s, 0), 3 * s, white, M.Snow, { collide = false })
	Build.cyl(m, cf * CFrame.new(0, 11.2 * s, 0), 0.3 * s, 3.4 * s, rgb(40, 40, 60), M.Fabric, { collide = false })
	Build.cyl(m, cf * CFrame.new(0, 12.2 * s, 0), 1.8 * s, 2 * s, rgb(40, 40, 60), M.Fabric, { collide = false })
	Build.cyl(m, cf * CFrame.new(0, 9.4 * s, 1.7 * s) * CFrame.Angles(math.pi / 2, 0, 0), 1.6 * s, 0.5 * s, rgb(255, 130, 30), M.SmoothPlastic, { collide = false })
	for _, sx in { -0.6, 0.6 } do
		Build.ball(m, cf * CFrame.new(sx * s, 10 * s, 1.3 * s), 0.4 * s, rgb(20, 20, 20), M.SmoothPlastic, { collide = false })
	end
	for _, sx in { -1, 1 } do
		Build.cyl(m, cf * CFrame.new(sx * 3.4 * s, 7 * s, 0) * CFrame.Angles(0, 0, sx * math.rad(-50)), 4.4 * s, 0.35 * s, rgb(110, 76, 44), M.Wood, { collide = false })
	end
	m.PrimaryPart = b1
	Build.sway(b1, 1.5, 4)
end

local function skiJump(folder: Folder, x: number, z: number)
	local y = Build.y(x, z)
	local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, 0))
	local m = Build.model(folder, "SkiJump")
	Build.foundation(m, cf, Vector3.new(24, 1, 46))
	local ramp = Build.wedge(m, cf * CFrame.new(0, 6, 4) * CFrame.Angles(0, math.pi, 0), Vector3.new(20, 12, 34), rgb(240, 248, 255), M.Ice)
	ramp.Reflectance = 0.08
	for _, sx in { -10.4, 10.4 } do
		Build.block(m, cf * CFrame.new(sx, 6, 4), Vector3.new(0.8, 12.6, 34.6), rgb(255, 90, 70), M.SmoothPlastic, { collide = false })
		local flag = Build.block(m, cf * CFrame.new(sx, 14, -11), Vector3.new(0.3, 3, 4), rgb(255, 210, 60), M.Fabric, { collide = false })
		Build.sway(flag, 8, 1.8)
		Build.block(m, cf * CFrame.new(sx, 10, -11), Vector3.new(0.4, 10, 0.4), rgb(230, 230, 240), M.Metal)
	end
	local sign = Build.block(m, cf * CFrame.new(0, 16, -14), Vector3.new(14, 3, 0.5), rgb(40, 60, 120), M.SmoothPlastic)
	Build.label(sign, "🎿 RAMPA DE ESQUI", { color = P.White })
	Nature.reserve(x, z, 30)
end

local function summit(folder: Folder)
	local c = Config.Biomes.Snow.center
	-- acha o ponto mais alto perto do centro
	local bx, bz, by = c.X, c.Y, -1e9
	for dx = -70, 70, 7 do
		for dz = -70, 70, 7 do
			local h = WorldGen.height(c.X + dx, c.Y + dz)
			if h > by then
				bx, bz, by = c.X + dx, c.Y + dz, h
			end
		end
	end
	local y = Build.y(bx, bz)
	local m = Build.model(folder, "Summit")
	Build.cyl(m, CFrame.new(bx, y + 9, bz), 18, 0.8, rgb(230, 230, 240), M.Metal)
	local flag = Build.block(m, CFrame.new(bx + 3.2, y + 15, bz), Vector3.new(6, 4, 0.3), P.Pink, M.Fabric, { collide = false })
	Build.sway(flag, 10, 1.6)
	local orb = Build.ball(m, CFrame.new(bx, y + 19.5, bz), 3, P.Accent, M.Neon, { collide = false })
	Build.light(orb, P.Accent, 2.4, 50, false)
	Build.pulse(orb, 1, 4, 1.4)
	Build.bob(orb, 0.6, 2.5)
	local base = Build.cyl(m, CFrame.new(bx, y + 0.8, bz), 1.6, 8, rgb(70, 76, 120), M.Slate)
	local pp = Build.prompt(base, "Plantar bandeira", "Pico da Montanha", "summit", 0.6)
	pp.MaxActivationDistance = 14
	local last = {}
	pp.Triggered:Connect(function(player)
		if not Data.isLoaded(player) then
			return
		end
		local now = os.clock()
		if last[player] and now - last[player] < 300 then
			Remotes.get("Notify"):FireClient(player, "A bandeira já está plantada. Volte mais tarde!", "bad")
			return
		end
		last[player] = now
		Data.addXP(player, 60)
		Pickups.burst(Vector3.new(bx, y + 6, bz), 150, 15)
		Remotes.get("Announce"):FireClient(player, "PICO CONQUISTADO!", "Você escalou a montanha inteira", 2.6, P.Accent)
		Remotes.get("Fx"):FireAllClients("confetti", Vector3.new(bx, y + 8, bz), 1.4, nil)
	end)
	Nature.reserve(bx, bz, 12)
	Snow.summitPos = Vector3.new(bx, y, bz)
end

local function caveEntrance(folder: Folder)
	local e = WorldGen.Cave.entranceWorld
	if not e then
		return
	end
	local dir = WorldGen.Cave.direction
	local cf = CFrame.lookAt(e, e + dir)
	local m = Build.model(folder, "CaveEntrance")
	-- moldura de madeira
	for _, sx in { -8, 8 } do
		Build.block(m, cf * CFrame.new(sx, 0, 0), Vector3.new(2.4, 18, 2.4), rgb(122, 84, 52), M.Wood)
	end
	Build.block(m, cf * CFrame.new(0, 9.6, 0), Vector3.new(19, 2.4, 2.6), rgb(122, 84, 52), M.Wood)
	local sign = Build.block(m, cf * CFrame.new(0, 13, 0.4), Vector3.new(16, 3.4, 0.6), rgb(44, 38, 100), M.SmoothPlastic)
	Build.label(sign, "💎 CAVERNA DE CRISTAL", { color = rgb(120, 240, 255) })
	for _, sx in { -6, 6 } do
		local lamp = Build.ball(m, cf * CFrame.new(sx, 6, -1.6), 1.6, rgb(120, 240, 255), M.Neon, { collide = false })
		Build.light(lamp, rgb(120, 240, 255), 2, 28, false)
		Build.bob(lamp, 0.3, 2.4)
	end
	Nature.reserve(e.X, e.Z, 24)
end

function Snow.build(rng: Random, addSlot)
	local folder = Build.folder("Snow")
	local c = Config.Biomes.Snow.center

	-- pinheiros: neve e pradarias nevadas
	Nature.scatter(folder, rng, 170, {
		center = c,
		radius = 300,
		materials = { [M.Snow] = true, [M.Glacier] = true, [M.Grass] = true, [M.LeafyGrass] = true },
		kinds = { { "snowpine", 5 }, { "pine", 2 } },
		scale = { 0.9, 1.8 },
		maxY = 140,
		minNormalY = 0.8,
		clearance = 3,
	})
	Nature.rocks(folder, rng, 34, {
		center = c,
		radius = 300,
		materials = { [M.Snow] = true, [M.Rock] = true, [M.Glacier] = true },
		color = rgb(200, 206, 220),
		maxY = 220,
		minNormalY = 0.6,
		clearance = 2,
	})

	cabin(folder, -20, -290)
	igloo(folder, 210, -300)
	skiJump(folder, -110, -330)
	for i = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(70, 110)
		local lake = WorldGen.Lakes[2]
		local x, z = lake.x + math.cos(a) * r, lake.z + math.sin(a) * r
		local pos, normal = Build.ground(x, z)
		if pos and normal.Y > 0.8 then
			snowman(folder, pos, rng)
		end
	end
	-- lampioes em volta do lago congelado
	local lake = WorldGen.Lakes[2]
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local pos = Build.ground(lake.x + math.cos(a) * (lake.r + 4), lake.z + math.sin(a) * (lake.r + 4))
		if pos then
			Build.lamp(folder, pos, 9, rgb(170, 230, 255))
		end
	end
	summit(folder)
	caveEntrance(folder)

	for _ = 1, 24 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * 250
		local pos, normal = Build.ground(c.X + math.cos(a) * r, c.Y + math.sin(a) * r)
		if pos and normal.Y > 0.86 and pos.Y > 4 and pos.Y < 130 then
			addSlot(pos, "Snow")
		end
	end
	-- os blocos de gelo aparecem mais no lago
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		addSlot(Vector3.new(lake.x + math.cos(a) * 30, lake.water + 2, lake.z + math.sin(a) * 30), "Snow")
	end
end

return Snow
