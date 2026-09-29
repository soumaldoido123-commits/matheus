--!nonstrict
--[[
	Atmosphere: iluminacao, ceu, efeitos de pos-processamento e ciclo de dia/noite.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Atmosphere = {}

Atmosphere.DayLength = 960 -- segundos para um dia completo

local function clearOld()
	for _, c in Lighting:GetChildren() do
		if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("ColorCorrectionEffect") or c:IsA("SunRaysEffect") or c:IsA("DepthOfFieldEffect") or c:IsA("Clouds") then
			c:Destroy()
		end
	end
end

function Atmosphere.init()
	clearOld()

	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0.1
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.18
	Lighting.GeographicLatitude = 22
	Lighting.Ambient = Color3.fromRGB(70, 74, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 130, 170)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 236, 205)
	Lighting.ClockTime = 15.3
	pcall(function()
		Lighting.FogEnd = 100000
	end)

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 16
	sky.MoonAngularSize = 14
	sky.StarCount = 4500
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atm = Instance.new("Atmosphere")
	atm.Density = 0.32
	atm.Offset = 0.22
	atm.Color = Color3.fromRGB(196, 214, 255)
	atm.Decay = Color3.fromRGB(255, 190, 170)
	atm.Glare = 0.35
	atm.Haze = 1.1
	atm.Parent = Lighting

	local clouds = Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = workspace.Terrain

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.55
	bloom.Size = 26
	bloom.Threshold = 1.0
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.0
	cc.Contrast = 0.1
	cc.Saturation = 0.22
	cc.TintColor = Color3.fromRGB(255, 248, 240)
	cc.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.1
	rays.Spread = 0.6
	rays.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.FarIntensity = 0.12
	dof.FocusDistance = 120
	dof.InFocusRadius = 70
	dof.NearIntensity = 0
	dof.Parent = Lighting

	pcall(function()
		SoundService.AmbientReverb = Enum.ReverbType.Forest
	end)

	-- ciclo dia/noite
	local speed = 24 / Atmosphere.DayLength
	RunService.Heartbeat:Connect(function(dt)
		Lighting.ClockTime = (Lighting.ClockTime + dt * speed) % 24
	end)
end

return Atmosphere
