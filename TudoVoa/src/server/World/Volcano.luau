--!nonstrict
--[[
	Volcano: o Vulcao Furioso e o deserto (leste). Lava na cratera, gêiseres que lancam,
	espinhos de obsidiana, piramide, cactos, oasis e a catapulta antiga.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Build = require(script.Parent:WaitForChild("Build"))
local Nature = require(script.Parent:WaitForChild("Nature"))
local WorldGen = require(script.Parent:WaitForChild("WorldGen"))
local Hub = require(script.Parent:WaitForChild("Hub"))
local Pickups = require(script.Parent.Parent:WaitForChild("Pickups"))

local Volcano = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function craterGlow(folder: Folder)
	local c = Config.Biomes.Volcano.center
	local y = Build.y(c.X, c.Y)
	Volcano.craterPos = Vector3.new(c.X, y, c.Y)
	local m = Build.model(folder, "CraterGlow")
	-- disco brilhante sobre a lava
	local glow = Build.cyl(m, CFrame.new(c.X, y + 1.2, c.Y), 0.4, 62, rgb(255, 110, 30), M.Neon, { collide = false, transparency = 0.35, shadow = false })
	glow.CanQuery = false
	Build.light(glow, rgb(255, 120, 40), 6, 120, false)
	Build.pulse(glow, 3, 8, 3)

	-- brasas + fumaca subindo
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, 6, 0)
	att.Parent = glow
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = FIRE
	embers.Rate = 30
	embers.Lifetime = NumberRange.new(3, 6)
	embers.Speed = NumberRange.new(20, 50)
	embers.EmissionDirection = Enum.NormalId.Top
	embers.SpreadAngle = Vector2.new(22, 22)
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.4), NumberSequenceKeypoint.new(1, 0) })
	embers.Color = ColorSequence.new(rgb(255, 220, 90), rgb(255, 70, 20))
	embers.LightEmission = 1
	embers.Acceleration = Vector3.new(0, -8, 0)
	embers.Parent = att
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = SMOKE
	smoke.Rate = 10
	smoke.Lifetime = NumberRange.new(6, 10)
	smoke.Speed = NumberRange.new(14, 26)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.SpreadAngle = Vector2.new(14, 14)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 60) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(rgb(70, 62, 72))
	smoke.Parent = att

	-- rochas de lava flutuando (bolhas de magma)
	local rng = Random.new(Config.World.Seed + 5)
	for i = 1, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(4, 24)
		local b = Build.ball(m, CFrame.new(c.X + math.cos(a) * r, y + 2, c.Y + math.sin(a) * r), rng:NextNumber(2, 4.5), rgb(255, 150, 40), M.Neon, { collide = false, shadow = false })
		Build.bob(b, 1.2, 1.6 + rng:NextNumber(0, 1.5))
	end
end

local function geyser(folder: Folder, pos: Vector3)
	local m = Build.model(folder, "Geyser")
	Build.cyl(m, CFrame.new(pos + Vector3.new(0, 0.8, 0)), 1.6, 9, rgb(50, 44, 58), M.Basalt)
	local rim = Build.cyl(m, CFrame.new(pos + Vector3.new(0, 1.7, 0)), 0.3, 7, rgb(255, 120, 40), M.Neon, { name = "PadTop" })
	Build.tag(rim, "TV_JumpPad", { Power = 150, DirX = 0, DirY = 1, DirZ = 0 })
	Build.pulse(rim, 1, 4, 1.7)
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, 1, 0)
	att.Parent = rim
	local steam = Instance.new("ParticleEmitter")
	steam.Texture = SMOKE
	steam.Rate = 16
	steam.Lifetime = NumberRange.new(1.4, 2.4)
	steam.Speed = NumberRange.new(30, 50)
	steam.EmissionDirection = Enum.NormalId.Top
	steam.SpreadAngle = Vector2.new(8, 8)
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 10) })
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	steam.Color = ColorSequence.new(rgb(255, 230, 210))
	steam.Parent = att
end

local function spire(folder: Folder, pos: Vector3, rng: Random)
	local h = rng:NextNumber(14, 34)
	local cf = CFrame.new(pos + Vector3.new(0, h * 0.4, 0)) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 6.28), rng:NextNumber(-0.15, 0.15))
	Build.block(folder, cf, Vector3.new(rng:NextNumber(4, 7), h, rng:NextNumber(4, 7)), rgb(30, 26, 44), M.Basalt)
	if rng:NextNumber() < 0.4 then
		local crack = Build.block(folder, cf * CFrame.new(0, h * 0.1, 2.9), Vector3.new(0.6, h * 0.6, 0.3), rgb(255, 110, 30), M.Neon, { collide = false, shadow = false })
		Build.pulse(crack, 0.5, 2.5, 2.2)
	end
end

local function pyramid(folder: Folder, x: number, z: number)
	local y = Build.y(x, z)
	local m = Build.model(folder, "Pyramid")
	local size = 64
	local layers = 9
	Build.foundation(m, CFrame.new(x, y, z), Vector3.new(size + 4, 1, size + 4), rgb(220, 180, 120), M.Sandstone)
	for i = 0, layers - 1 do
		local s = size * (1 - i / layers)
		Build.block(m, CFrame.new(x, y + 3.6 * i + 2, z), Vector3.new(s, 3.6, s), rgb(236 - i * 3, 196 - i * 3, 128), M.Sandstone)
	end
	local cap = Build.block(m, CFrame.new(x, y + 3.6 * layers + 2.2, z), Vector3.new(6, 4, 6), P.Accent, M.Neon)
	Build.light(cap, P.Accent, 3, 60, false)
	Build.bob(cap, 0.5, 3)
	Build.spin(cap, "Y", 30)
	Build.billboard(cap, "🔺 Topo da Pirâmide", { color = P.Accent, offset = Vector3.new(0, 6, 0) })
	Pickups.placeStatic(Vector3.new(x, y + 3.6 * layers + 8, z), 60, 90)
	-- entrada
	local door = Build.block(m, CFrame.new(x, y + 5, z - size / 2 - 0.05), Vector3.new(8, 10, 0.6), rgb(50, 30, 30), M.SmoothPlastic, { collide = false })
	door.Transparency = 0.1
	Nature.reserve(x, z, size * 0.8)
	Volcano.pyramidTop = Vector3.new(x, y + 3.6 * layers + 4, z)
end

local function obelisk(folder: Folder, pos: Vector3, rng: Random)
	local m = Build.model(folder, "Obelisk")
	local cf = CFrame.new(pos)
	Build.block(m, cf * CFrame.new(0, 1, 0), Vector3.new(6, 2, 6), rgb(200, 160, 100), M.Sandstone)
	Build.block(m, cf * CFrame.new(0, 12, 0), Vector3.new(3.4, 20, 3.4), rgb(230, 190, 120), M.Sandstone)
	local tip = Build.wedge(m, cf * CFrame.new(0, 23.4, 0), Vector3.new(3.4, 3.4, 3.4), rgb(255, 210, 90), M.Neon, { collide = false })
	tip.CFrame = cf * CFrame.new(0, 23.4, 0) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	Build.pulse(tip, 0.6, 2.4, 2.5)
end

function Volcano.build(rng: Random, addSlot)
	local folder = Build.folder("Volcano")
	local c = Config.Biomes.Volcano.center

	craterGlow(folder)

	-- gêiseres em anel ao redor da base
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + 0.2
		local r = 150 + (i % 3) * 18
		local x, z = c.X + math.cos(a) * r, c.Y + math.sin(a) * r
		local pos, normal, mat = Build.ground(x, z)
		if pos and normal.Y > 0.8 and mat ~= M.Water then
			geyser(folder, pos)
		end
	end

	-- espinhos de obsidiana
	Nature.scatter(folder, rng, 60, {
		center = c,
		radius = 210,
		materials = { [M.Basalt] = true, [M.Slate] = true, [M.Rock] = true },
		kinds = { { "spire", 1 } },
		scale = { 1, 1 },
		minNormalY = 0.5,
		minY = 20,
		clearance = 3,
		place = function(parent, pos, _, _, r)
			spire(parent, pos, r)
		end,
	})

	-- deserto
	pyramid(folder, c.X + 190, c.Y + 190)
	for i = 1, 5 do
		local a = rng:NextNumber(0, math.pi * 2)
		local pos = Build.ground(c.X + math.cos(a) * 200, c.Y + math.sin(a) * 200)
		if pos and pos.Y > 4 then
			obelisk(folder, pos, rng)
		end
	end
	Nature.scatter(folder, rng, 70, {
		center = c,
		radius = 300,
		materials = Nature.SAND,
		kinds = { { "cactus", 5 }, { "palm", 1 } },
		scale = { 0.8, 1.8 },
		minNormalY = 0.85,
		clearance = 4,
	})
	Nature.rocks(folder, rng, 24, { center = c, radius = 300, materials = Nature.SAND, color = rgb(220, 170, 120), clearance = 3 })

	-- palmeiras no oasis
	local oasis = WorldGen.Lakes[3]
	for i = 0, 8 do
		local a = i / 9 * math.pi * 2
		local pos = Build.ground(oasis.x + math.cos(a) * (oasis.r + 6), oasis.z + math.sin(a) * (oasis.r + 6))
		if pos then
			Build.tree(folder, pos, "palm", rng:NextNumber(1.1, 1.6), rng, Vector3.new(0.1, 0, 0.08))
		end
	end

	Hub.jumpPad(folder, Vector3.new(c.X - 90, Build.y(c.X - 90, c.Y) + 1.6, c.Y), 130, rgb(255, 120, 40), Vector3.new(-0.4, 1, 0))

	for _ = 1, 22 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * 240
		local pos, normal = Build.ground(c.X + math.cos(a) * r, c.Y + math.sin(a) * r)
		if pos and normal.Y > 0.85 and pos.Y > 4 and pos.Y < 110 then
			addSlot(pos, "Volcano")
		end
	end
end

return Volcano
