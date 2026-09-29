--!nonstrict
--[[
	Ambient: particulas ambiente que seguem o jogador e mudam com a regiao
	(polen, neve, brasas, esporos de caverna, brilhos no ceu).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Ambient = {}

local player = Players.LocalPlayer
local P = Config.Palette

local part, emitters
local currentPreset = nil
local lastIndoorCheck = 0
local indoor = false

local function ns(a, b)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function makeEmitter(att: Attachment, props)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Enabled = true
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	for k, v in props do
		e[k] = v
	end
	e.Parent = att
	return e
end

local function build()
	part = Instance.new("Part")
	part.Name = "TV_AmbientEmitter"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(110, 2, 110)
	part.Parent = workspace
	local att = Instance.new("Attachment")
	att.Parent = part
	emitters = {
		pollen = makeEmitter(att, {
			Lifetime = NumberRange.new(6, 10),
			Speed = NumberRange.new(0.5, 2),
			SpreadAngle = Vector2.new(180, 180),
			Size = ns(0.35, 0.1),
			LightEmission = 0.7,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.3), NumberSequenceKeypoint.new(1, 1) }),
			Color = ColorSequence.new(Color3.fromRGB(255, 240, 170), Color3.fromRGB(255, 255, 255)),
			Acceleration = Vector3.new(0.6, 0.2, 0.3),
		}),
		snow = makeEmitter(att, {
			Lifetime = NumberRange.new(6, 8),
			Speed = NumberRange.new(4, 9),
			EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(20, 20),
			Size = ns(0.5, 0.4),
			LightEmission = 0.3,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.1), NumberSequenceKeypoint.new(1, 0.5) }),
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			Acceleration = Vector3.new(3, 0, 1.5),
		}),
		embers = makeEmitter(att, {
			Lifetime = NumberRange.new(3, 5),
			Speed = NumberRange.new(7, 14),
			EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(30, 30),
			Size = ns(0.6, 0),
			LightEmission = 1,
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 70, 20)),
			Acceleration = Vector3.new(2, 4, 1),
		}),
		spores = makeEmitter(att, {
			Lifetime = NumberRange.new(5, 9),
			Speed = NumberRange.new(0.5, 3),
			SpreadAngle = Vector2.new(180, 180),
			Size = ns(0.7, 0.2),
			LightEmission = 1,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(1, 1) }),
			Color = ColorSequence.new(P.Accent2, P.Pink),
			Acceleration = Vector3.new(0, 0.8, 0),
		}),
		sparkle = makeEmitter(att, {
			Lifetime = NumberRange.new(4, 7),
			Speed = NumberRange.new(1, 4),
			SpreadAngle = Vector2.new(180, 180),
			Size = ns(0.6, 0),
			LightEmission = 1,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.2), NumberSequenceKeypoint.new(1, 1) }),
			Color = ColorSequence.new(P.Accent2, P.Purple),
		}),
	}
end

local RATES = {
	pollen = { pollen = 5 },
	snow = { snow = 70 },
	embers = { embers = 22 },
	spores = { spores = 14 },
	sparkle = { sparkle = 8 },
}

local function setPreset(name: string)
	if name == currentPreset then
		return
	end
	currentPreset = name
	local rates = RATES[name] or {}
	for id, e in emitters do
		e.Rate = rates[id] or 0
	end
end

local function presetFor(zone: string?, y: number): string
	if indoor then
		return "spores"
	end
	if y > Config.World.SkyY - 60 then
		return "sparkle"
	end
	if zone == Config.Biomes.Snow.name then
		return "snow"
	elseif zone == Config.Biomes.Volcano.name then
		return "embers"
	elseif zone == Config.Biomes.Hub.name then
		return "sparkle"
	end
	return "pollen"
end

function Ambient.init()
	build()
	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		local now = os.clock()
		if now - lastIndoorCheck > 1 then
			lastIndoorCheck = now
			-- ha terreno/teto acima do jogador? (caverna)
			local hit = workspace:Raycast(hrp.Position, Vector3.new(0, 90, 0))
			indoor = hit ~= nil and hit.Instance == workspace.Terrain
			setPreset(presetFor(player:GetAttribute("Zone"), hrp.Position.Y))
		end
		part.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 26, 0))
	end)
end

return Ambient
