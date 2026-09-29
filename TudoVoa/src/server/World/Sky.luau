--!nonstrict
--[[
	Sky: decoracao das ilhas flutuantes + tubos de vento que levam ate elas.
	(A Ilha da Arena e a Ilha do Golem sao completadas pelos modulos de atividades.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Build = require(script.Parent:WaitForChild("Build"))
local WorldGen = require(script.Parent:WaitForChild("WorldGen"))
local Hub = require(script.Parent:WaitForChild("Hub"))
local Interactive = require(script.Parent:WaitForChild("Interactive"))
local Zones = require(script.Parent.Parent:WaitForChild("Zones"))

local Sky = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Procura terreno seco caminhando em direcao ao centro
local function findLand(x: number, z: number): (number, number)
	local dir = Vector3.new(-x, 0, -z)
	if dir.Magnitude < 1 then
		return x, z
	end
	dir = dir.Unit
	for i = 0, 30 do
		local px, pz = x + dir.X * i * 12, z + dir.Z * i * 12
		local pos, normal = Build.ground(px, pz)
		if pos and normal.Y > 0.82 and pos.Y > Config.World.SeaLevel + 3 then
			return px, pz
		end
	end
	return x, z
end

local TUBES = {
	Arena = { offset = Vector3.new(1, 0, 0), color = rgb(94, 234, 212) },
	Crystal = { offset = Vector3.new(-0.77, 0, -0.64), color = rgb(120, 240, 255) },
	Boss = { offset = Vector3.new(0.83, 0, 0.56), color = rgb(255, 120, 90) },
	Treasure = { offset = Vector3.new(0.35, 0, -0.94), color = rgb(255, 210, 70) },
	Garden = { offset = Vector3.new(-0.74, 0, -0.68), color = rgb(150, 255, 120) },
}

local function crystalIsland(folder: Folder, isl, rng: Random, addSlot)
	local top = WorldGen.islandTop(isl)
	for i = 1, 16 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * isl.radius * 0.85
		local h = rng:NextNumber(8, 26)
		local color = Color3.fromHSV(rng:NextNumber(0.45, 0.85), 0.55, 1)
		local cf = CFrame.new(isl.pos.X + math.cos(a) * r, top + h * 0.45, isl.pos.Z + math.sin(a) * r) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6.28), rng:NextNumber(-0.2, 0.2))
		local c = Build.block(folder, cf, Vector3.new(rng:NextNumber(2.5, 4.5), h, rng:NextNumber(2.5, 4.5)), color, M.Neon, { transparency = 0.15 })
		Build.pulse(c, 0.4, 2.2, 3 + rng:NextNumber(0, 3))
		if i % 3 == 0 then
			Build.light(c, color, 2, 40, false)
		end
	end
	for _ = 1, 10 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * isl.radius * 0.8
		Build.tree(folder, Vector3.new(isl.pos.X + math.cos(a) * r, top - 0.4, isl.pos.Z + math.sin(a) * r), "mushroom", rng:NextNumber(0.9, 1.6), rng)
	end
	for _ = 1, 10 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * isl.radius * 0.7
		addSlot(Vector3.new(isl.pos.X + math.cos(a) * r, top + 1, isl.pos.Z + math.sin(a) * r), "Sky")
	end
end

local function treasureIsland(folder: Folder, isl, rng: Random, addSlot)
	local top = WorldGen.islandTop(isl)
	Interactive.chest(folder, Vector3.new(isl.pos.X, top, isl.pos.Z), "Tesouro do Céu", 900, 1200, rgb(255, 214, 80))
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		Build.tree(folder, Vector3.new(isl.pos.X + math.cos(a) * 30, top - 0.4, isl.pos.Z + math.sin(a) * 30), "palm", 1.3, rng, Vector3.new(0.1, 0, 0.06))
	end
	for i = 1, 6 do
		addSlot(Vector3.new(isl.pos.X + rng:NextNumber(-25, 25), top + 1, isl.pos.Z + rng:NextNumber(-25, 25)), "Sky")
	end
end

local function flower(folder: Folder, pos: Vector3, size: number, rng: Random)
	local m = Build.model(folder, "GiantFlower")
	local color = Color3.fromHSV(rng:NextNumber(0, 1), 0.6, 1)
	local stem = Build.cyl(m, CFrame.new(pos + Vector3.new(0, size * 3, 0)), size * 6, size * 0.9, rgb(70, 190, 90), M.Grass)
	local head = CFrame.new(pos + Vector3.new(0, size * 6.4, 0))
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local pet = Build.ball(m, head * CFrame.new(math.cos(a) * size * 2.4, 0, math.sin(a) * size * 2.4), size * 2.6, color, M.SmoothPlastic, { collide = false })
		pet.Size = Vector3.new(size * 2.6, size * 1.2, size * 2.6)
	end
	local core = Build.ball(m, head * CFrame.new(0, size * 0.4, 0), size * 2.4, rgb(255, 220, 60), M.SmoothPlastic, { collide = false })
	m.PrimaryPart = stem
	Build.sway(stem, 3, 3.5 + rng:NextNumber(0, 2))
	_ = core
end

local function ring(folder: Folder, pos: Vector3, radius: number, color: Color3, rotY: number)
	local m = Build.model(folder, "FlyRing")
	local pivot = Build.block(m, CFrame.new(pos), Vector3.one, P.Ink, M.SmoothPlastic, { collide = false, transparency = 1, query = false })
	m.PrimaryPart = pivot
	local n = 16
	for i = 1, n do
		local a = i / n * math.pi * 2
		Build.ball(m, CFrame.new(pos) * CFrame.Angles(0, rotY, 0) * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0), 2.4, color, M.Neon, { collide = false, shadow = false })
	end
	Build.bob(pivot, 1.5, 4)
	Build.spin(m, "Z", 14)
end

local function gardenIsland(folder: Folder, isl, rng: Random, addSlot)
	local top = WorldGen.islandTop(isl)
	for _ = 1, 16 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * isl.radius * 0.85
		flower(folder, Vector3.new(isl.pos.X + math.cos(a) * r, top - 0.4, isl.pos.Z + math.sin(a) * r), rng:NextNumber(0.9, 1.8), rng)
	end
	-- aneis flutuantes (para atravessar voando)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		ring(folder, Vector3.new(isl.pos.X + math.cos(a) * 30, top + 18 + i * 4, isl.pos.Z + math.sin(a) * 30), 11, Color3.fromHSV(i / 4, 0.7, 1), a)
	end
	for _ = 1, 10 do
		addSlot(Vector3.new(isl.pos.X + rng:NextNumber(-40, 40), top + 1, isl.pos.Z + rng:NextNumber(-40, 40)), "Sky")
	end
end

local function bossIslandDeco(folder: Folder, isl, rng: Random)
	local top = WorldGen.islandTop(isl)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local r = isl.radius * 0.93
		local h = rng:NextNumber(10, 22)
		Build.block(folder, CFrame.new(isl.pos.X + math.cos(a) * r, top + h / 2, isl.pos.Z + math.sin(a) * r) * CFrame.Angles(0, -a, 0), Vector3.new(5, h, 5), rgb(110, 100, 130), M.Slate)
		if i % 2 == 0 then
			local o = Build.ball(folder, CFrame.new(isl.pos.X + math.cos(a) * r, top + h + 2, isl.pos.Z + math.sin(a) * r), 3.4, rgb(255, 110, 70), M.Neon, { collide = false })
			Build.light(o, rgb(255, 110, 70), 2, 30, false)
			Build.pulse(o, 0.6, 3, 2.4)
		end
	end
end

function Sky.build(rng: Random, addSlot)
	local folder = Build.folder("Sky")
	for _, isl in WorldGen.SkyIslands do
		Zones.registerSkyName(isl.pos, isl.radius, isl.name, "☁️")
		local t = TUBES[isl.id]
		if t then
			local dist = isl.radius + 9
			local x = isl.pos.X + t.offset.X * dist
			local z = isl.pos.Z + t.offset.Z * dist
			if isl.id ~= "Arena" then
				x, z = findLand(x, z)
			end
			local m = Hub.windTube(folder, x, z, WorldGen.islandTop(isl) + 4, isl.name, t.color)
			local zone = m:FindFirstChild("WindZone")
			if zone then
				zone:SetAttribute("PullX", isl.pos.X)
				zone:SetAttribute("PullZ", isl.pos.Z)
			end
			isl.tube = Vector3.new(x, 0, z)
		end
	end

	crystalIsland(folder, WorldGen.getIsland("Crystal"), rng, addSlot)
	treasureIsland(folder, WorldGen.getIsland("Treasure"), rng, addSlot)
	gardenIsland(folder, WorldGen.getIsland("Garden"), rng, addSlot)
	bossIslandDeco(folder, WorldGen.getIsland("Boss"), rng)

	-- "ilhotas" decorativas ao longe (so visuais)
	for i = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(420, 900)
		local y = Config.World.SkyY + rng:NextNumber(-90, 260)
		local p = Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
		local m = Build.model(folder, "Islet")
		local s = rng:NextNumber(14, 34)
		local top = Build.ball(m, CFrame.new(p), s, rgb(96, 190, 96), M.Grass, { collide = false })
		top.Size = Vector3.new(s, s * 0.25, s)
		local rock = Build.ball(m, CFrame.new(p - Vector3.new(0, s * 0.3, 0)), s * 0.8, rgb(128, 122, 140), M.Slate, { collide = false })
		rock.Size = Vector3.new(s * 0.8, s * 0.7, s * 0.8)
		m.PrimaryPart = top
		Build.bob(top, 2, 6 + rng:NextNumber(0, 5))
		Build.bob(rock, 2, 6 + rng:NextNumber(0, 5))
	end
end

return Sky
