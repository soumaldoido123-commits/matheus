--!nonstrict
--[[
	Nature: espalha arvores, pedras e plantas pelo terreno respeitando material, inclinacao,
	estradas e areas reservadas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local Build = require(script.Parent:WaitForChild("Build"))
local WorldGen = require(script.Parent:WaitForChild("WorldGen"))

local Nature = {}

local M = Enum.Material

Nature.Reserved = {} -- { { x, z, r } } areas onde nao espalhar nada

function Nature.reserve(x: number, z: number, r: number)
	table.insert(Nature.Reserved, { x = x, z = z, r = r })
end

local function isReserved(x: number, z: number, extra: number): boolean
	for _, a in Nature.Reserved do
		local dx, dz = x - a.x, z - a.z
		if dx * dx + dz * dz < (a.r + extra) ^ 2 then
			return true
		end
	end
	return false
end

-- opts:
--   center: Vector2, radius: number  (regiao circular)
--   materials: { [Enum.Material]: true }  (onde pode nascer)
--   minNormalY: number (0.86 padrao)
--   minRoad: number (12), hubClear: number (100)
--   kinds: { {kind, weight} }, scale: {min, max}
--   place: function(parent, pos, kind, scale, rng) -> nil (opcional, substitui Build.tree)
function Nature.scatter(parent: Instance, rng: Random, count: number, opts)
	local placed = 0
	local attempts = 0
	local maxAttempts = count * 8
	local c = opts.center
	local hubClear = opts.hubClear or 100
	local minRoad = opts.minRoad or 12
	local minNormal = opts.minNormalY or 0.86
	while placed < count and attempts < maxAttempts do
		attempts += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * opts.radius
		local x, z = c.X + math.cos(a) * r, c.Y + math.sin(a) * r
		if math.sqrt(x * x + z * z) < hubClear then
			continue
		end
		if WorldGen.roadDistance(x, z) < minRoad then
			continue
		end
		if isReserved(x, z, opts.clearance or 0) then
			continue
		end
		local pos, normal, material = Build.ground(x, z)
		if not pos or normal.Y < minNormal then
			continue
		end
		if opts.materials and not opts.materials[material] then
			continue
		end
		if pos.Y < (opts.minY or Config.World.SeaLevel + 3) or pos.Y > (opts.maxY or 400) then
			continue
		end
		local kind = Util.weightedPick(opts.kinds, function(k)
			return k[2]
		end, rng)[1]
		local scale = rng:NextNumber(opts.scale[1], opts.scale[2])
		if opts.place then
			opts.place(parent, pos, kind, scale, rng)
		else
			Build.tree(parent, pos - Vector3.new(0, 0.6, 0), kind, scale, rng)
		end
		placed += 1
		if placed % 25 == 0 then
			task.wait()
		end
	end
	return placed
end

function Nature.rocks(parent: Instance, rng: Random, count: number, opts)
	opts.kinds = { { "rock", 1 } }
	opts.scale = opts.scale or { 3, 9 }
	opts.place = function(p, pos, _, scale, r)
		Build.rock(p, pos + Vector3.new(0, scale * 0.15, 0), scale, opts.color, r)
	end
	return Nature.scatter(parent, rng, count, opts)
end

Nature.GRASS = { [M.Grass] = true, [M.LeafyGrass] = true, [M.Ground] = true }
Nature.SAND = { [M.Sand] = true, [M.Sandstone] = true }
Nature.SNOW = { [M.Snow] = true, [M.Glacier] = true }

return Nature
