--!nonstrict
--[[
	Fx (cliente): efeitos visuais e sonoros — impactos, explosoes, ondas, confete,
	tremor de camera, pisca vermelho ao ser atingido, numeros flutuantes.
]]

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Store = require(script.Parent:WaitForChild("Store"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local Fx = {}

local P = Config.Palette
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local rng = Random.new()

-- Tremor de camera ------------------------------------------------------------------------------------------

local shakeAmount = 0

function Fx.shake(intensity: number)
	if Store.setting("Shake") == false then
		return
	end
	shakeAmount = math.min(1.6, math.max(shakeAmount, intensity))
end

function Fx.shakeAt(position: Vector3, intensity: number, maxDist: number?)
	local md = maxDist or 160
	local d = (camera.CFrame.Position - position).Magnitude
	local k = math.clamp(1 - d / md, 0, 1)
	if k > 0 then
		Fx.shake(intensity * k)
	end
end

-- Pontos de emissao ---------------------------------------------------------------------------------------------

local function anchorAt(position: Vector3, lifetime: number): (Part, Attachment)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = workspace
	local a = Instance.new("Attachment")
	a.Parent = p
	Debris:AddItem(p, lifetime)
	return p, a
end

local function emitter(att: Attachment, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.Rate = 0
	for k, v in props do
		e[k] = v
	end
	e.Parent = att
	return e
end

local function ns(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function fadeOut(from: number?): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from or 0), NumberSequenceKeypoint.new(1, 1) })
end

-- Anel horizontal que se expande (onda de choque)
local function ring(position: Vector3, color: Color3, finalDiameter: number, time: number, thickness: number?)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.15
	p.Size = Vector3.new(thickness or 0.6, 2, 2)
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(thickness or 0.6, finalDiameter, finalDiameter),
		Transparency = 1,
	}):Play()
	Debris:AddItem(p, time + 0.1)
end

local function flash(position: Vector3, color: Color3, range: number, time: number)
	local p, a = anchorAt(position, time + 0.2)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 6
	l.Shadows = false
	l.Parent = a
	TweenService:Create(l, TweenInfo.new(time), { Brightness = 0 }):Play()
	return p
end

-- Efeitos -----------------------------------------------------------------------------------------------------------

local function matSound(mat: string?): (number, string)
	if mat == "Metal" or mat == "DiamondPlate" or mat == "CorrodedMetal" then
		return 1.5, "Impact"
	elseif mat == "Grass" or mat == "LeafyGrass" or mat == "Sand" or mat == "Snow" or mat == "Fabric" or mat == "Mud" or mat == "Ground" then
		return 1.1, "Soft"
	elseif mat == "Wood" or mat == "WoodPlanks" then
		return 0.9, "Soft"
	end
	return 1.0, "Impact"
end

local handlers = {}

function handlers.impact(pos: Vector3, mag: number, extra)
	local color = (extra and extra.color) or Color3.fromRGB(220, 220, 230)
	local _, att = anchorAt(pos, 3)
	emitter(att, {
		Texture = SMOKE,
		Lifetime = NumberRange.new(0.4, 0.9),
		Speed = NumberRange.new(8, 22 * (0.4 + mag)),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(1.2 + mag * 2, 0.2),
		Transparency = fadeOut(0.35),
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5)),
		Drag = 4,
	}):Emit(math.floor(4 + mag * 12))
	if mag > 0.3 then
		emitter(att, {
			Lifetime = NumberRange.new(0.3, 0.6),
			Speed = NumberRange.new(20, 50),
			SpreadAngle = Vector2.new(180, 180),
			Size = ns(0.5, 0),
			LightEmission = 1,
			Color = ColorSequence.new(P.Accent, Color3.new(1, 1, 1)),
		}):Emit(math.floor(mag * 10))
	end
	local pitch, snd = matSound(extra and extra.mat)
	Audio.at(snd, pos, 0.25 + mag * 0.7, pitch * (0.9 + rng:NextNumber(0, 0.3)))
	Fx.shakeAt(pos, mag * 0.35, 90)
end

function handlers.explosion(pos: Vector3, scale: number)
	scale = math.max(scale, 0.6)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 170, 60)
	ball.Size = Vector3.one * 2
	ball.Position = pos
	ball.Parent = workspace
	TweenService:Create(ball, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * 34 * scale, Transparency = 1 }):Play()
	Debris:AddItem(ball, 0.6)
	ring(pos - Vector3.new(0, 1, 0), Color3.fromRGB(255, 220, 140), 70 * scale, 0.6, 1.2)
	ring(pos, Color3.fromRGB(255, 130, 60), 46 * scale, 0.45, 0.8)
	flash(pos, Color3.fromRGB(255, 190, 110), 90 * scale, 0.5)
	local _, att = anchorAt(pos, 4)
	emitter(att, {
		Texture = FIRE,
		Lifetime = NumberRange.new(0.6, 1.4),
		Speed = NumberRange.new(30 * scale, 80 * scale),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(6 * scale, 0.5),
		LightEmission = 1,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 70, 20)),
		Transparency = fadeOut(0),
		Drag = 2,
	}):Emit(math.floor(50 * scale))
	emitter(att, {
		Texture = SMOKE,
		Lifetime = NumberRange.new(1.6, 3.2),
		Speed = NumberRange.new(12 * scale, 34 * scale),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(8 * scale, 24 * scale),
		Color = ColorSequence.new(Color3.fromRGB(80, 74, 84)),
		Transparency = fadeOut(0.3),
		Drag = 1.5,
	}):Emit(math.floor(22 * scale))
	Audio.at("Explosion", pos, 1, 0.85 + rng:NextNumber(0, 0.25), 420)
	Fx.shakeAt(pos, 1.3 * scale, 260)
end

function handlers.shock(pos: Vector3, scale: number)
	ring(pos - Vector3.new(0, 2, 0), P.Accent2, 86 * math.max(scale, 0.5), 0.5, 0.7)
	ring(pos - Vector3.new(0, 1, 0), Color3.new(1, 1, 1), 60 * math.max(scale, 0.5), 0.4, 0.4)
	local _, att = anchorAt(pos, 3)
	emitter(att, {
		Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(30, 70),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(1, 0),
		LightEmission = 1,
		Color = ColorSequence.new(P.Accent2, Color3.new(1, 1, 1)),
	}):Emit(40)
	Audio.at("Explosion", pos, 0.6, 1.6, 260)
	Fx.shakeAt(pos, 0.8, 140)
end

function handlers.bubble(pos: Vector3, scale: number)
	ring(pos - Vector3.new(0, 3, 0), P.Purple, 60 * math.max(scale, 0.5), 0.6, 0.6)
	local _, att = anchorAt(pos, 3)
	emitter(att, {
		Lifetime = NumberRange.new(1, 2),
		Speed = NumberRange.new(4, 16),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(1.4, 0),
		LightEmission = 1,
		Color = ColorSequence.new(P.Purple, P.Accent2),
	}):Emit(36)
	Audio.at("Charge", pos, 0.6, 0.6)
end

function handlers.coin(pos: Vector3)
	local _, att = anchorAt(pos, 2)
	emitter(att, {
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(0.9, 0),
		LightEmission = 1,
		Color = ColorSequence.new(P.Accent, Color3.new(1, 1, 1)),
	}):Emit(8)
	Audio.ui("Coin", 0.35, 1.5 + rng:NextNumber(0, 0.3))
end

function handlers.confetti(pos: Vector3, scale: number)
	local _, att = anchorAt(pos, 5)
	local colors = { P.Pink, P.Accent, P.Accent2, P.Blue, P.Green, P.Purple }
	for _, c in colors do
		emitter(att, {
			Lifetime = NumberRange.new(2, 3.4),
			Speed = NumberRange.new(30 * math.max(scale, 0.6), 80 * math.max(scale, 0.6)),
			SpreadAngle = Vector2.new(60, 60),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -70, 0),
			Size = ns(0.9, 0.9),
			RotSpeed = NumberRange.new(-300, 300),
			Rotation = NumberRange.new(0, 360),
			LightEmission = 0.4,
			Color = ColorSequence.new(c),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) }),
		}):Emit(math.floor(16 * math.max(scale, 0.6)))
	end
	Audio.at("LevelUp", pos, 0.35, 1.2)
end

function handlers.splat(pos: Vector3, mag: number, extra)
	local color = (extra and extra.color) or P.Red
	local _, att = anchorAt(pos, 3)
	emitter(att, {
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(14, 50),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -90, 0),
		Size = ns(1.6, 0.4),
		Color = ColorSequence.new(color),
		Transparency = fadeOut(0),
	}):Emit(math.floor(26 + mag * 20))
	Audio.at("Soft", pos, 0.9, 0.55)
	Fx.shakeAt(pos, 0.3, 80)
end

function handlers.fuse(pos: Vector3)
	Audio.at("Charge", pos, 0.6, 1.8, 120)
end

function handlers.oof(pos: Vector3)
	Audio.at("Oof", pos, 0.9, 0.95 + rng:NextNumber(0, 0.2), 140)
end

function handlers.squeak(pos: Vector3, mag: number)
	Audio.at("Coin", pos, 0.5, 2.2 + rng:NextNumber(0, 0.6) - mag * 0.4, 100)
end

function handlers.bounce(pos: Vector3, mag: number)
	Audio.at("Bounce", pos, 0.4 + mag * 0.5, 1.1 + rng:NextNumber(0, 0.5), 110)
	ring(pos, Color3.new(1, 1, 1), 8 + mag * 10, 0.3, 0.2)
end

function handlers.thud(pos: Vector3, mag: number)
	Audio.at("Impact", pos, 0.6 + mag * 0.4, 0.55, 200)
	Fx.shakeAt(pos, mag * 0.6, 130)
end

function handlers.sparkle(pos: Vector3)
	local _, att = anchorAt(pos, 2)
	emitter(att, {
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(6, 18),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(1.2, 0),
		LightEmission = 1,
		Color = ColorSequence.new(P.Accent2, Color3.new(1, 1, 1)),
	}):Emit(16)
	Audio.at("Coin", pos, 0.35, 2.4)
end

function handlers.cannon(pos: Vector3, _, extra)
	local dir = (extra and extra.dir) or Vector3.yAxis
	flash(pos, Color3.fromRGB(255, 200, 120), 60, 0.4)
	local p, att = anchorAt(pos + dir * 4, 4)
	p.CFrame = CFrame.lookAt(p.Position, p.Position + dir)
	emitter(att, {
		Texture = SMOKE,
		Lifetime = NumberRange.new(0.8, 1.8),
		Speed = NumberRange.new(20, 60),
		SpreadAngle = Vector2.new(20, 20),
		EmissionDirection = Enum.NormalId.Front,
		Size = ns(4, 16),
		Color = ColorSequence.new(Color3.fromRGB(190, 190, 200)),
		Transparency = fadeOut(0.3),
	}):Emit(24)
	emitter(att, {
		Texture = FIRE,
		Lifetime = NumberRange.new(0.3, 0.7),
		Speed = NumberRange.new(30, 90),
		SpreadAngle = Vector2.new(24, 24),
		EmissionDirection = Enum.NormalId.Front,
		Size = ns(3, 0),
		LightEmission = 1,
		Color = ColorSequence.new(Color3.fromRGB(255, 230, 130), Color3.fromRGB(255, 80, 20)),
	}):Emit(30)
	Audio.at("Explosion", pos, 1, 1.3, 400)
	Fx.shakeAt(pos, 1.0, 200)
end

function handlers.teleport(pos: Vector3)
	ring(pos - Vector3.new(0, 3, 0), P.Purple, 30, 0.6, 0.5)
	flash(pos, P.Purple, 50, 0.5)
	Audio.at("Charge", pos, 0.7, 1.3)
end

function handlers.freeze(pos: Vector3)
	local _, att = anchorAt(pos, 2.5)
	emitter(att, {
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(6, 18),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(1.3, 0),
		LightEmission = 0.8,
		Color = ColorSequence.new(Color3.fromRGB(150, 230, 255), Color3.new(1, 1, 1)),
	}):Emit(28)
	Audio.at("Charge", pos, 0.6, 0.7)
end
handlers.unfreeze = handlers.freeze

function handlers.spawn(pos: Vector3)
	local _, att = anchorAt(pos, 2.5)
	emitter(att, {
		Texture = SMOKE,
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(6, 16),
		SpreadAngle = Vector2.new(180, 180),
		Size = ns(2, 6),
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		Transparency = fadeOut(0.3),
	}):Emit(14)
	Audio.at("Soft", pos, 0.6, 1.4)
end

-- Numeros flutuantes no mundo -----------------------------------------------------------------------------------------

function Fx.popup(position: Vector3, text: string, color: Color3?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(300, 60)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 400
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color or P.Accent
	t.TextStrokeTransparency = 0.2
	t.TextStrokeColor3 = P.Ink
	t.Parent = gui
	TweenService:Create(p, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = position + Vector3.new(0, 9, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(p, 2)
end

-- Flash vermelho de dano -------------------------------------------------------------------------------------------------

local flashGui
local flashFrame

local function ensureFlash()
	if flashGui then
		return
	end
	flashGui = Instance.new("ScreenGui")
	flashGui.Name = "TV_Fx"
	flashGui.IgnoreGuiInset = true
	flashGui.ResetOnSpawn = false
	flashGui.DisplayOrder = 30
	flashGui.Parent = player:WaitForChild("PlayerGui")
	flashFrame = Instance.new("Frame")
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.Parent = flashGui
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.85),
		NumberSequenceKeypoint.new(1, 0.85),
	})
	g.Rotation = 0
	g.Parent = flashFrame
end

function Fx.screenFlash(color: Color3?, strength: number?)
	ensureFlash()
	flashFrame.BackgroundColor3 = color or Color3.fromRGB(255, 60, 60)
	flashFrame.BackgroundTransparency = 1 - math.clamp(strength or 0.5, 0, 0.8)
	TweenService:Create(flashFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

-- FOV: pulso temporario (arremesso, impulso...)
local fovKick = 0
function Fx.fovKick(amount: number)
	fovKick = math.max(fovKick, amount)
end
Fx.baseFov = 70

function Fx.init()
	RunService:BindToRenderStep("TV_FxCamera", Enum.RenderPriority.Camera.Value + 5, function(dt)
		camera = workspace.CurrentCamera
		if shakeAmount > 0.002 then
			local s = shakeAmount
			camera.CFrame = camera.CFrame
				* CFrame.new(rng:NextNumber(-1, 1) * s * 0.35, rng:NextNumber(-1, 1) * s * 0.35, 0)
				* CFrame.Angles(rng:NextNumber(-1, 1) * s * 0.012, rng:NextNumber(-1, 1) * s * 0.012, rng:NextNumber(-1, 1) * s * 0.02)
			shakeAmount = math.max(0, shakeAmount - dt * (1.6 + shakeAmount * 2))
		end
		if fovKick > 0.05 then
			camera.FieldOfView = camera.FieldOfView + fovKick
			fovKick = fovKick * math.exp(-dt * 7)
		end
	end)

	Remotes.get("Fx").OnClientEvent:Connect(function(kind, pos, force, extra)
		local h = handlers[kind]
		if h and typeof(pos) == "Vector3" then
			local ok, err = pcall(h, pos, force or 1, extra)
			if not ok then
				warn("[Fx] erro em", kind, err)
			end
		end
	end)

	Remotes.get("ScorePopup").OnClientEvent:Connect(function(pos, text, color)
		if typeof(pos) == "Vector3" then
			Fx.popup(pos, text, color)
		end
	end)

	Remotes.get("Struck").OnClientEvent:Connect(function(force)
		Fx.shake(0.4 + (force or 0.5) * 1.1)
		Fx.screenFlash(nil, 0.25 + (force or 0.5) * 0.3)
		Audio.ui("Oof", 0.5, 1)
	end)
end

Fx.handlers = handlers

return Fx
