--!nonstrict
--[[
	Cave: a Caverna de Cristal (dentro da Montanha Gelada): camara com cristais brilhantes,
	cogumelos luminosos, moedas escondidas e um portal de volta para a praca.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Build = require(script.Parent:WaitForChild("Build"))
local WorldGen = require(script.Parent:WaitForChild("WorldGen"))
local Interactive = require(script.Parent:WaitForChild("Interactive"))
local Pickups = require(script.Parent.Parent:WaitForChild("Pickups"))

local Cave = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function crystalCluster(folder: Folder, pos: Vector3, rng: Random)
	local hue = rng:NextNumber(0.45, 0.9)
	local m = Build.model(folder, "CrystalCluster")
	local n = rng:NextInteger(3, 6)
	for i = 1, n do
		local h = rng:NextNumber(4, 13)
		local color = Color3.fromHSV((hue + rng:NextNumber(-0.05, 0.05)) % 1, 0.55, 1)
		local cf = CFrame.new(pos + Vector3.new(rng:NextNumber(-3, 3), h * 0.4, rng:NextNumber(-3, 3))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4))
		local c = Build.block(m, cf, Vector3.new(rng:NextNumber(1.2, 2.6), h, rng:NextNumber(1.2, 2.6)), color, M.Neon, { transparency = 0.12, collide = false })
		if i == 1 then
			Build.light(c, color, 3, 36, false)
			Build.pulse(c, 0.5, 2, 2 + rng:NextNumber(0, 3))
		end
	end
	return m
end

local function glowShroom(folder: Folder, pos: Vector3, rng: Random)
	local m = Build.model(folder, "GlowShroom")
	local s = rng:NextNumber(0.8, 1.6)
	Build.cyl(m, CFrame.new(pos + Vector3.new(0, 2 * s, 0)), 4 * s, 1.2 * s, rgb(230, 240, 255), M.SmoothPlastic, { collide = false })
	local cap = Build.ball(m, CFrame.new(pos + Vector3.new(0, 4.3 * s, 0)), 5 * s, rgb(90, 255, 200), M.Neon, { collide = false })
	cap.Size = Vector3.new(5 * s, 2.6 * s, 5 * s)
	Build.light(cap, rgb(90, 255, 200), 1.6, 20, false)
	Build.pulse(cap, 0.5, 2, 3)
end

function Cave.build(rng: Random, addSlot)
	local chamber = WorldGen.Cave.chamber
	if not chamber then
		return
	end
	local folder = Build.folder("Cave")

	-- encontra pontos do chao dentro da camara
	local floorPoints = {}
	for _ = 1, 90 do
		local origin = chamber + Vector3.new(rng:NextNumber(-42, 42), rng:NextNumber(4, 22), rng:NextNumber(-42, 42))
		local pos, normal = Build.groundFrom(origin, 60)
		if pos and (pos - chamber).Magnitude < 60 and normal.Y > 0.6 then
			table.insert(floorPoints, { pos = pos, normal = normal })
		end
	end
	for i, fp in floorPoints do
		if i % 3 == 0 then
			glowShroom(folder, fp.pos, rng)
		else
			crystalCluster(folder, fp.pos, rng)
		end
	end

	-- moedas escondidas e brinquedos raros
	local coins = 0
	for _, fp in floorPoints do
		if coins < 14 and rng:NextNumber() < 0.35 then
			Pickups.placeStatic(fp.pos + Vector3.new(0, 3, 0), 25, 120)
			coins += 1
		end
	end
	local slots = 0
	for _, fp in floorPoints do
		if slots < 8 and rng:NextNumber() < 0.3 then
			addSlot(fp.pos + Vector3.new(0, 1, 0), "Cave")
			slots += 1
		end
	end

	-- luz ambiente da camara
	local lampPart = Build.block(folder, CFrame.new(chamber + Vector3.new(0, 24, 0)), Vector3.one, P.Ink, M.SmoothPlastic, { collide = false, transparency = 1, query = false })
	Build.light(lampPart, rgb(140, 200, 255), 2.4, 120, false)

	-- portal de retorno para a praca
	local center = floorPoints[1] and floorPoints[1].pos or chamber
	local ppos = Build.groundFrom(chamber + Vector3.new(0, 10, 0), 60) or center
	local hubY = Build.y(0, 0)
	Interactive.portal(folder, ppos + Vector3.new(0, 0.6, 0), Vector3.new(0, hubY + 6, 30), "Voltar à Praça", P.Purple)
end

return Cave
