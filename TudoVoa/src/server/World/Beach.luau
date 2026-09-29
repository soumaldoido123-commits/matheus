--!nonstrict
--[[
	Beach: a Praia dos Ventos (sul). Deque, farol giratorio, cabanas, guarda-sois, palmeiras,
	navio pirata com bau e canhao, boias e balsa com cama elastica.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Build = require(script.Parent:WaitForChild("Build"))
local Nature = require(script.Parent:WaitForChild("Nature"))
local Hub = require(script.Parent:WaitForChild("Hub"))
local Interactive = require(script.Parent:WaitForChild("Interactive"))

local Beach = {}

local M = Enum.Material
local P = Config.Palette
local SEA = Config.World.SeaLevel
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function pier(folder: Folder, x: number, z0: number, z1: number)
	local m = Build.model(folder, "Pier")
	local y = SEA + 4.2
	local n = math.floor((z1 - z0) / 6)
	for i = 0, n do
		local z = z0 + i * 6
		Build.block(m, CFrame.new(x, y, z), Vector3.new(14, 0.8, 6.2), rgb(176, 128, 88), M.WoodPlanks)
		if i % 2 == 0 then
			for _, sx in { -6.4, 6.4 } do
				Build.cyl(m, CFrame.new(x + sx, y - 6, z), 14, 1.2, rgb(110, 76, 50), M.Wood)
			end
		end
	end
	for i = 0, n, 3 do
		for _, sx in { -7, 7 } do
			Build.lamp(m, Vector3.new(x + sx, y + 0.4, z0 + i * 6), 8, rgb(255, 220, 160))
		end
	end
	-- fim do deque: plataforma redonda com cadeira e boia
	local endZ = z0 + n * 6 + 8
	Build.cyl(m, CFrame.new(x, y, endZ), 0.8, 26, rgb(176, 128, 88), M.WoodPlanks)
	local sign = Build.block(m, CFrame.new(x, y + 9, endZ + 10), Vector3.new(14, 3.4, 0.5), rgb(30, 80, 130), M.SmoothPlastic)
	Build.label(sign, "⚓ DEQUE DOS VENTOS", { color = P.White })
	Beach.pierEnd = Vector3.new(x, y, endZ)
end

local function lighthouse(folder: Folder, x: number, z: number)
	local y = Build.y(x, z)
	local m = Build.model(folder, "Lighthouse")
	Build.foundation(m, CFrame.new(x, y, z), Vector3.new(20, 1, 20), rgb(200, 190, 180), M.Slate)
	local segs = 6
	for i = 0, segs - 1 do
		local d = 11 - i * 0.9
		local c = (i % 2 == 0) and rgb(240, 60, 70) or rgb(250, 250, 255)
		Build.cyl(m, CFrame.new(x, y + 1 + i * 6 + 3, z), 6, d, c, M.SmoothPlastic)
	end
	local topY = y + 1 + segs * 6
	Build.cyl(m, CFrame.new(x, topY + 0.6, z), 1.2, 12, rgb(50, 54, 90), M.Metal)
	local lamp = Build.cyl(m, CFrame.new(x, topY + 3.4, z), 4.4, 5.6, rgb(255, 240, 170), M.Neon, { collide = false, transparency = 0.15 })
	Build.light(lamp, rgb(255, 240, 170), 4, 90, false)
	Build.cyl(m, CFrame.new(x, topY + 6.6, z), 1.6, 8, rgb(240, 60, 70), M.SmoothPlastic)
	Build.ball(m, CFrame.new(x, topY + 8.4, z), 5, rgb(240, 60, 70), M.SmoothPlastic, { collide = false })
	-- feixe giratorio
	local sweep = Build.model(m, "Beam")
	local pivot = Build.block(sweep, CFrame.new(x, topY + 3.4, z), Vector3.one, P.Ink, M.SmoothPlastic, { collide = false, transparency = 1, query = false })
	sweep.PrimaryPart = pivot
	local beam = Build.block(sweep, CFrame.new(x, topY + 3.4, z + 34), Vector3.new(3, 3, 64), rgb(255, 245, 190), M.Neon, { collide = false, transparency = 0.7, shadow = false })
	beam.CanQuery = false
	local beam2 = Build.block(sweep, CFrame.new(x, topY + 3.4, z - 34), Vector3.new(3, 3, 64), rgb(255, 245, 190), M.Neon, { collide = false, transparency = 0.7, shadow = false })
	beam2.CanQuery = false
	Build.spin(sweep, "Y", 45)
	Nature.reserve(x, z, 16)
end

local function umbrella(folder: Folder, pos: Vector3, color: Color3, rng: Random)
	local m = Build.model(folder, "Umbrella")
	local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), math.rad(rng:NextNumber(-8, 8)))
	Build.cyl(m, cf * CFrame.new(0, 5, 0), 10, 0.5, rgb(240, 240, 245), M.Metal)
	local tiers = { { 13, 1 }, { 9.5, 1.3 }, { 5.5, 1.6 } }
	local y = 9.6
	for i, t in tiers do
		Build.cyl(m, cf * CFrame.new(0, y + i * 0.55, 0), t[2], t[1], (i % 2 == 0) and rgb(255, 255, 255) or color, M.Fabric, { collide = false })
	end
	Build.block(m, CFrame.new(pos + Vector3.new(4.4, 0.4, 2)), Vector3.new(4, 0.3, 7), color, M.Fabric, { collide = false })
	m.PrimaryPart = nil
end

local function hut(folder: Folder, x: number, z: number, color: Color3)
	local y = Build.y(x, z)
	local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, 0))
	local m = Build.model(folder, "Hut")
	Build.foundation(m, cf, Vector3.new(14, 1, 12), rgb(200, 170, 130), M.Wood)
	local body = Build.block(m, cf * CFrame.new(0, 4.5, 0), Vector3.new(12, 8, 10), color, M.WoodPlanks)
	for _, sgn in { -1, 1 } do
		Build.block(m, cf * CFrame.new(sgn * 3.8, 10.4, 0) * CFrame.Angles(0, 0, -sgn * math.rad(34)), Vector3.new(8.4, 1, 12.4), rgb(216, 176, 90), M.Fabric)
	end
	Build.block(m, cf * CFrame.new(0, 3, 5.05), Vector3.new(3, 6, 0.3), rgb(100, 66, 44), M.Wood)
	local win = Build.block(m, cf * CFrame.new(4, 5, 5.05), Vector3.new(2.6, 2.6, 0.3), rgb(170, 226, 255), M.Glass)
	win.Transparency = 0.3
	m.PrimaryPart = body
	Nature.reserve(x, z, 10)
end

local function sandcastle(folder: Folder, x: number, z: number)
	local y = Build.y(x, z)
	local sand = rgb(238, 208, 140)
	local m = Build.model(folder, "Sandcastle")
	local cf = CFrame.new(x, y, z)
	Build.block(m, cf * CFrame.new(0, 2.5, 0), Vector3.new(16, 5, 16), sand, M.Sand)
	for _, sx in { -8, 8 } do
		for _, sz in { -8, 8 } do
			Build.cyl(m, cf * CFrame.new(sx, 5, sz), 10, 4.4, sand, M.Sand)
			Build.cyl(m, cf * CFrame.new(sx, 11, sz), 3, 5.4, rgb(255, 120, 150), M.SmoothPlastic, { collide = false })
		end
	end
	Build.cyl(m, cf * CFrame.new(0, 8, 0), 8, 6, sand, M.Sand)
	local flag = Build.block(m, cf * CFrame.new(1.5, 15, 0), Vector3.new(3, 2, 0.2), P.Red, M.Fabric, { collide = false })
	Build.sway(flag, 12, 1.5)
	Build.block(m, cf * CFrame.new(0, 13, 0), Vector3.new(0.3, 6, 0.3), rgb(230, 230, 240), M.Metal)
	Nature.reserve(x, z, 14)
end

local function ship(folder: Folder, x: number, z: number)
	local m = Build.model(folder, "PirateShip")
	local y = SEA + 3
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(-25), math.rad(4))
	local wood = rgb(128, 84, 54)
	local dark = rgb(90, 58, 38)
	-- casco
	local hull = Build.block(m, cf * CFrame.new(0, 0, 0), Vector3.new(20, 9, 56), wood, M.WoodPlanks)
	Build.wedge(m, cf * CFrame.new(0, 0, -32) * CFrame.Angles(0, math.pi, 0), Vector3.new(20, 9, 8), wood, M.WoodPlanks)
	Build.wedge(m, cf * CFrame.new(0, 0, 31.5), Vector3.new(20, 9, 7), wood, M.WoodPlanks)
	Build.block(m, cf * CFrame.new(0, 5, 0), Vector3.new(20.8, 1.2, 56.8), dark, M.Wood, { collide = false })
	-- convés: piso
	Build.block(m, cf * CFrame.new(0, 4.6, 0), Vector3.new(18, 0.8, 54), rgb(190, 146, 100), M.WoodPlanks)
	-- amuradas
	for _, sx in { -9.6, 9.6 } do
		Build.block(m, cf * CFrame.new(sx, 7, 0), Vector3.new(0.8, 4, 54), dark, M.Wood)
	end
	-- mastros e velas
	for i, mz in { -12, 8 } do
		Build.cyl(m, cf * CFrame.new(0, 20, mz), 34, 1.6, dark, M.Wood)
		local sail = Build.block(m, cf * CFrame.new(0, 22 - i * 1.5, mz + 1), Vector3.new(16, 16, 0.6), rgb(250, 244, 232), M.Fabric, { collide = false })
		Build.sway(sail, 4, 3)
		Build.block(m, cf * CFrame.new(0, 29 - i * 1.5, mz + 0.8), Vector3.new(17, 1, 1), dark, M.Wood, { collide = false })
	end
	-- bandeira pirata
	local flag = Build.block(m, cf * CFrame.new(1.6, 38.6, -12), Vector3.new(4, 3, 0.3), rgb(24, 24, 30), M.Fabric, { collide = false })
	Build.sway(flag, 14, 1.4)
	Build.ball(flag, flag.CFrame * CFrame.new(0, 0, 0.2), 1.2, rgb(245, 245, 245), M.SmoothPlastic, { collide = false })
	-- lanternas
	for _, lz in { -22, 20 } do
		local l = Build.ball(m, cf * CFrame.new(0, 8.5, lz), 1.6, rgb(255, 210, 120), M.Neon, { collide = false })
		Build.light(l, rgb(255, 200, 120), 2, 30, false)
	end
	m.PrimaryPart = hull

	local world = cf * CFrame.new(0, 5.5, 18)
	Interactive.chest(folder, world.Position + Vector3.new(0, 0, 0), "Baú do Pirata", 220, 400, rgb(255, 210, 70))
	Beach.shipDeck = (cf * CFrame.new(0, 6, -20)).Position
	Nature.reserve(x, z, 40)
	local pos = (cf * CFrame.new(0, 5.4, -10)).Position
	return pos
end

local function buoys(folder: Folder, rng: Random)
	for i = 1, 16 do
		local x = rng:NextNumber(-260, 260)
		local z = rng:NextNumber(470, 640)
		local m = Build.model(folder, "Buoy")
		local color = (i % 2 == 0) and P.Red or P.Accent
		local b = Build.cyl(m, CFrame.new(x, SEA + 0.6, z), 3.2, 3.4, color, M.SmoothPlastic, { collide = false })
		Build.cyl(m, CFrame.new(x, SEA + 2.6, z), 1.4, 3.42, rgb(255, 255, 255), M.SmoothPlastic, { collide = false })
		Build.ball(m, CFrame.new(x, SEA + 4, z), 1.4, P.Accent2, M.Neon, { collide = false })
		Build.bob(b, 0.5, 2.5 + rng:NextNumber(0, 2))
		m.PrimaryPart = b
	end
end

local function raft(folder: Folder, x: number, z: number)
	local m = Build.model(folder, "Raft")
	local y = SEA + 0.6
	local deck = Build.block(m, CFrame.new(x, y, z), Vector3.new(24, 1.2, 24), rgb(176, 128, 88), M.WoodPlanks)
	for i = -2, 2 do
		Build.cyl(m, CFrame.new(x + i * 5, y - 0.3, z) * CFrame.Angles(math.pi / 2, 0, 0), 24.4, 2.4, rgb(120, 84, 56), M.Wood, { collide = false })
	end
	Hub.jumpPad(m, Vector3.new(x, y + 0.6, z), 125, P.Pink)
	-- flamingo bóia
	local fl = Build.cyl(m, CFrame.new(x + 30, SEA + 0.8, z + 6), 1.6, 7, rgb(255, 130, 180), M.SmoothPlastic, { collide = false })
	Build.ball(m, CFrame.new(x + 30, SEA + 4, z + 6), 2.6, rgb(255, 130, 180), M.SmoothPlastic, { collide = false })
	Build.bob(fl, 0.4, 3)
	Build.billboard(deck, "Balsa Saltitante", { color = P.Accent2, offset = Vector3.new(0, 6, 0) })
end

function Beach.build(rng: Random, addSlot)
	local folder = Build.folder("Beach")
	local c = Config.Biomes.Beach.center

	pier(folder, 20, 392, 520)
	lighthouse(folder, -120, 392)
	hut(folder, -70, 372, rgb(255, 130, 150))
	hut(folder, 100, 372, rgb(120, 210, 255))
	hut(folder, 170, 350, rgb(255, 214, 96))
	sandcastle(folder, -20, 360)
	sandcastle(folder, 240, 380)
	local shipPos = ship(folder, 150, 495)
	buoys(folder, rng)
	raft(folder, -110, 520)
	raft(folder, 200, 600)

	-- canhao do navio: dispara para o mar aberto (recorde de distancia)
	Interactive.cannon(folder, shipPos, Vector3.new(120, SEA + 2, 900), "Canhão Pirata", { angle = 45, color = rgb(50, 50, 60) })
	Interactive.signpost(folder, Vector3.new(60, 0, 340), "🏖️ PRAIA DOS VENTOS", Vector3.new(0, 0, -1))

	-- guarda-sois
	local colors = { P.Red, P.Blue, P.Pink, P.Accent, P.Green, P.Purple }
	local placed = 0
	for _ = 1, 60 do
		if placed >= 16 then
			break
		end
		local x, z = c.X + rng:NextNumber(-230, 230), c.Y + rng:NextNumber(-10, 60)
		local pos, normal, mat = Build.ground(x, z)
		if pos and normal.Y > 0.9 and mat == M.Sand and pos.Y > SEA + 2 then
			umbrella(folder, pos, colors[placed % #colors + 1], rng)
			placed += 1
		end
	end

	Nature.scatter(folder, rng, 80, {
		center = c,
		radius = 260,
		materials = Nature.SAND,
		kinds = { { "palm", 1 } },
		scale = { 1, 1.7 },
		minNormalY = 0.9,
		minY = SEA + 3,
		clearance = 5,
		hubClear = 130,
	})
	Nature.scatter(folder, rng, 40, {
		center = c,
		radius = 240,
		materials = Nature.GRASS,
		kinds = { { "palm", 2 }, { "round", 1 } },
		scale = { 1, 1.6 },
		clearance = 4,
		hubClear = 130,
	})

	for _ = 1, 28 do
		local x, z = c.X + rng:NextNumber(-230, 230), c.Y + rng:NextNumber(-40, 70)
		local pos, normal = Build.ground(x, z)
		if pos and normal.Y > 0.9 and pos.Y > SEA + 2 then
			addSlot(pos, "Beach")
		end
	end
end

return Beach
