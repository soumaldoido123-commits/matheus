--[[
=====================================================================================
   ROBÔ TITAN X-9  —  Mecha de tecnologia avançada, controlável, em UM ÚNICO script
=====================================================================================

  COMO INSTALAR
   1. Abra o Roblox Studio com o seu jogo (ou um "Baseplate" novo).
   2. No Explorer: StarterPlayer > StarterPlayerScripts
   3. Clique no "+" ao lado de StarterPlayerScripts > LocalScript
   4. Apague o conteúdo do LocalScript e cole ESTE código inteiro.
   5. Aperte Play (F5). O robô aparece na sua frente. Aperte V para entrar.

  CONTROLES (dentro do robô)
   V ............ Entrar / sair do robô (se estiver longe, convoca o robô até você)
   W A S D ...... Andar
   Mouse ........ Mirar / girar a câmera      Roda do mouse ... Zoom
   Botão esq. ... Canhão laser (segure)
   Espaço ....... Pular (no ar: impulso do jetpack) / subir voando
   Ctrl esq. .... Descer (no modo voo)
   Shift esq. ... Turbo
   F ............ Liga/desliga modo VOO
   E ............ Mísseis teleguiados
   Q ............ Escudo de energia
   R ............ Scanner (revela inimigos)
   G ............ Impacto sísmico (no ar: mergulha e esmaga o chão)
   L ............ Faróis
   C ............ Trocar cor/tema do robô
   K ............ Acenar
   T ............ Chamar onda de drones de treino
   X (2 vezes) .. Autodestruição
   H ............ Mostrar/esconder ajuda

  OBSERVAÇÃO
   Tudo é criado no cliente (LocalScript): você vê e controla o robô, os drones
   e os efeitos. Outros jogadores não enxergam o robô.
=====================================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

---------------------------------------------------------------------------------------
-- CONFIGURAÇÕES (mude à vontade)
---------------------------------------------------------------------------------------
local CONFIG = {
	NAME = "TITAN X-9",

	MAX_HEALTH = 1000,
	MAX_ENERGY = 100,
	ENERGY_REGEN = 14, -- por segundo

	WALK_SPEED = 28,
	TURBO_SPEED = 55,
	FLY_SPEED = 70,
	FLY_TURBO_SPEED = 130,
	JUMP_POWER = 75,
	JET_BOOST_COST = 15,
	GRAVITY = 150,
	HIP_HEIGHT = 5.6, -- altura do quadril até o chão
	TURN_SPEED = 8,
	ENTER_DISTANCE = 25,

	LASER_DAMAGE = 18,
	LASER_RATE = 0.09,
	LASER_COST = 1.2,
	LASER_RANGE = 1000,

	MISSILE_DAMAGE = 120,
	MISSILE_RADIUS = 18,
	MISSILE_SPEED = 120,
	MISSILE_COOLDOWN = 1.2,
	MISSILE_COST = 15,

	SHIELD_DRAIN = 12,
	SCAN_COOLDOWN = 6,
	SCAN_RANGE = 400,
	SCAN_COST = 10,
	SLAM_DAMAGE = 150,
	SLAM_RADIUS = 35,
	SLAM_COOLDOWN = 5,
	SLAM_COST = 20,
	FLY_DRAIN = 7,
	TURBO_DRAIN = 9,

	DRONES_PER_WAVE = 5,
	MAX_DRONES = 25,
	DRONE_HEALTH = 100,
	DRONE_DAMAGE = 35,
	DRONE_FIRE_MIN = 1.8,
	DRONE_FIRE_MAX = 3.5,
	DRONE_SHOT_SPEED = 80,

	CAMERA_DISTANCE = 30,
	CAMERA_MIN = 12,
	CAMERA_MAX = 90,
	MOUSE_SENSITIVITY = 0.004,

	SOUNDS = {
		laser = "rbxasset://sounds/electronicpingshort.wav",
		missile = "rbxasset://sounds/Rocket shot.wav",
		explosion = "rbxasset://sounds/collide.wav",
		jump = "rbxasset://sounds/action_jump.mp3",
		land = "rbxasset://sounds/action_jump_land.mp3",
		hit = "rbxasset://sounds/paintball.wav",
		whoosh = "rbxasset://sounds/Rocket whoosh 01.wav",
	},
}

local THEMES = {
	{ name = "Titânio Azul", primary = Color3.fromRGB(200, 205, 215), secondary = Color3.fromRGB(45, 50, 60), accent = Color3.fromRGB(0, 200, 255) },
	{ name = "Carmesim", primary = Color3.fromRGB(170, 20, 30), secondary = Color3.fromRGB(35, 35, 40), accent = Color3.fromRGB(255, 170, 0) },
	{ name = "Verde Tóxico", primary = Color3.fromRGB(70, 85, 70), secondary = Color3.fromRGB(25, 30, 25), accent = Color3.fromRGB(80, 255, 80) },
	{ name = "Ouro Real", primary = Color3.fromRGB(215, 170, 50), secondary = Color3.fromRGB(40, 35, 30), accent = Color3.fromRGB(255, 60, 200) },
	{ name = "Stealth", primary = Color3.fromRGB(35, 35, 40), secondary = Color3.fromRGB(15, 15, 18), accent = Color3.fromRGB(255, 40, 40) },
}

---------------------------------------------------------------------------------------
-- ESTADO
---------------------------------------------------------------------------------------
local State = {
	piloting = false,
	dead = false,
	health = CONFIG.MAX_HEALTH,
	energy = CONFIG.MAX_ENERGY,
	flying = false,
	shield = false,
	lights = true,
	turbo = false,
	firing = false,
	slamming = false,
	themeIndex = 1,
	score = 0,
	wave = 0,

	rootCF = CFrame.new(0, 10, 0),
	velocity = Vector3.zero,
	onGround = false,
	yaw = 0,

	camYaw = 0,
	camPitch = -0.25,
	camDist = CONFIG.CAMERA_DISTANCE,
	shake = 0,

	walkPhase = 0,
	lastStepSign = 1,
	aimPoint = Vector3.zero,
	jetBoost = 0,
	waveTime = 0,
	destructArmed = 0,
	showHelp = true,

	cooldowns = { missile = 0, scan = 0, slam = 0, laser = 0 },
}

---------------------------------------------------------------------------------------
-- UTILITÁRIOS
---------------------------------------------------------------------------------------
local function new(className, props, children)
	local inst = Instance.new(className)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function makePart(props)
	local base = {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	return new("Part", base)
end

local function lerpAngle(a, b, t)
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * t
end

local function isDown(key)
	return UserInputService:IsKeyDown(key)
end

local function theme()
	return THEMES[State.themeIndex]
end

---------------------------------------------------------------------------------------
-- PASTAS NO WORKSPACE
---------------------------------------------------------------------------------------
for _, name in ipairs({ "RoboTitan", "RoboTitan_Efeitos", "RoboTitan_Drones" }) do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local robotModel = new("Model", { Name = "RoboTitan", Parent = workspace })
local effects = new("Folder", { Name = "RoboTitan_Efeitos", Parent = workspace })
local droneFolder = new("Folder", { Name = "RoboTitan_Drones", Parent = workspace })

-- rayWorld: chão, paredes, câmera (ignora robô, efeitos, drones e o personagem)
-- rayAim: mira, laser, mísseis (acerta drones)
local rayWorld = RaycastParams.new()
rayWorld.FilterType = Enum.RaycastFilterType.Exclude
local rayAim = RaycastParams.new()
rayAim.FilterType = Enum.RaycastFilterType.Exclude

local function refreshFilters()
	local ignore = { robotModel, effects }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	rayAim.FilterDescendantsInstances = ignore
	local worldIgnore = table.clone(ignore)
	table.insert(worldIgnore, droneFolder)
	rayWorld.FilterDescendantsInstances = worldIgnore
end
refreshFilters()

local function findGroundY(pos)
	local hit = workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -600, 0), rayWorld)
	return hit and hit.Position.Y or pos.Y
end

---------------------------------------------------------------------------------------
-- SOM E EFEITOS
---------------------------------------------------------------------------------------
local function playSound(id, volume, pitch, position)
	if not id then
		return
	end
	local holder = workspace
	if position then
		holder = makePart({ Size = Vector3.one, Transparency = 1, Position = position, Parent = effects })
		Debris:AddItem(holder, 4)
	end
	local sound = new("Sound", {
		SoundId = id,
		Volume = volume or 0.6,
		PlaybackSpeed = pitch or 1,
		RollOffMaxDistance = 400,
		Parent = holder,
	})
	pcall(function()
		sound:Play()
	end)
	Debris:AddItem(sound, 4)
end

local function addShake(amount, position)
	if position then
		local dist = (position - State.rootCF.Position).Magnitude
		amount = amount * math.clamp(1 - dist / 200, 0, 1)
	end
	State.shake = math.min(State.shake + amount, 3)
end

local function spark(position, color, count, speed)
	local p = makePart({ Size = Vector3.one * 0.2, Transparency = 1, Position = position, Parent = effects })
	local emitter = new("ParticleEmitter", {
		Color = ColorSequence.new(color),
		LightEmission = 1,
		Size = NumberSequence.new(0.5, 0),
		Speed = NumberRange.new((speed or 20) * 0.5, speed or 20),
		Lifetime = NumberRange.new(0.2, 0.5),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -40, 0),
		Rate = 0,
		Parent = p,
	})
	emitter:Emit(count or 10)
	Debris:AddItem(p, 1)
end

local function explosion(position, radius, color)
	color = color or Color3.fromRGB(255, 140, 30)
	local ball = makePart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one,
		Position = position,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.1,
		Parent = effects,
	})
	local light = new("PointLight", { Color = color, Range = radius * 2, Brightness = 5, Parent = ball })
	TweenService:Create(ball, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * radius * 2,
		Transparency = 1,
	}):Play()
	TweenService:Create(light, TweenInfo.new(0.45), { Brightness = 0 }):Play()
	Debris:AddItem(ball, 0.6)

	local ring = makePart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 1, 1),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
		Parent = effects,
	})
	TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, radius * 3, radius * 3),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.6)

	spark(position, color, 40, 45)
	spark(position, Color3.fromRGB(60, 60, 60), 20, 15)
	playSound(CONFIG.SOUNDS.explosion, 1, 0.5 + math.random() * 0.2, position)
	addShake(radius / 12, position)
end

local function laserBeam(from, to, color, width)
	local dist = (to - from).Magnitude
	if dist < 0.1 then
		return
	end
	local beam = makePart({
		Size = Vector3.new(width, width, dist),
		CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2),
		Color = color,
		Material = Enum.Material.Neon,
		CastShadow = false,
		Parent = effects,
	})
	TweenService:Create(beam, TweenInfo.new(0.15), { Transparency = 1, Size = Vector3.new(0, 0, dist) }):Play()
	Debris:AddItem(beam, 0.2)
end

---------------------------------------------------------------------------------------
-- INTERFACE (HUD)
---------------------------------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("RoboTitanHUD")
if oldGui then
	oldGui:Destroy()
end

local accentStrokes = {}

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function accentStroke(thickness)
	local s = new("UIStroke", { Color = THEMES[1].accent, Thickness = thickness or 1.5, Transparency = 0.15 })
	table.insert(accentStrokes, s)
	return s
end

local function label(props)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	return new("TextLabel", base)
end

local gui = new("ScreenGui", {
	Name = "RoboTitanHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Vinheta de dano
local vignette = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = gui,
})

-- Painel principal
local panel = new("Frame", {
	Size = UDim2.fromOffset(290, 200),
	Position = UDim2.fromOffset(16, 56),
	BackgroundColor3 = Color3.fromRGB(10, 12, 18),
	BackgroundTransparency = 0.25,
	Parent = gui,
}, { corner(10), accentStroke(2) })

local titleLabel = label({
	Size = UDim2.new(1, -24, 0, 26),
	Position = UDim2.fromOffset(12, 8),
	Text = "◆ " .. CONFIG.NAME,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	Parent = panel,
})

local function makeBar(y, color)
	local holder = new("Frame", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(12, y),
		BackgroundColor3 = Color3.fromRGB(25, 28, 36),
		Parent = panel,
	}, { corner(6) })
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = holder }, { corner(6) })
	local text = label({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 12,
		ZIndex = 2,
		TextStrokeTransparency = 0.5,
		Parent = holder,
	})
	return fill, text
end

local hpFill, hpText = makeBar(40, Color3.fromRGB(60, 220, 90))
local enFill, enText = makeBar(64, Color3.fromRGB(0, 170, 255))

local infoLabels = {}
for i = 1, 4 do
	infoLabels[i] = label({
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(12, 88 + (i - 1) * 20),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(210, 220, 235),
		Parent = panel,
	})
end
local warningLabel = label({
	Size = UDim2.new(1, -24, 0, 18),
	Position = UDim2.fromOffset(12, 172),
	TextSize = 13,
	TextColor3 = Color3.fromRGB(255, 70, 70),
	Text = "",
	Parent = panel,
})

-- Barra de habilidades
local SLOTS = {
	{ id = "missile", key = "E", name = "Míssil" },
	{ id = "shield", key = "Q", name = "Escudo" },
	{ id = "scan", key = "R", name = "Scanner" },
	{ id = "slam", key = "G", name = "Impacto" },
	{ id = "fly", key = "F", name = "Voo" },
	{ id = "lights", key = "L", name = "Faróis" },
}
local slotUI = {}
local abilityBar = new("Frame", {
	Size = UDim2.fromOffset(#SLOTS * 78, 70),
	Position = UDim2.new(0.5, 0, 1, -86),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})
for i, slot in ipairs(SLOTS) do
	local stroke = new("UIStroke", { Color = Color3.fromRGB(90, 95, 110), Thickness = 1.5 })
	local frame = new("Frame", {
		Size = UDim2.fromOffset(70, 64),
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = 0.2,
		LayoutOrder = i,
		ClipsDescendants = true,
		Parent = abilityBar,
	}, { corner(8), stroke })
	local overlay = new("Frame", {
		Size = UDim2.fromScale(1, 0),
		Position = UDim2.fromScale(0, 1),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = frame,
	})
	label({
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 6),
		Text = slot.key,
		TextSize = 24,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = frame,
	})
	label({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 40),
		Text = slot.name,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(190, 200, 215),
		ZIndex = 2,
		Parent = frame,
	})
	slotUI[slot.id] = { frame = frame, overlay = overlay, stroke = stroke }
end

-- Mira
local crosshair = new("Frame", {
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
local crossParts = {}
for _, spec in ipairs({
	-- tamanho, posição, âncora
	{ UDim2.fromOffset(2, 10), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0) },
	{ UDim2.fromOffset(2, 10), UDim2.fromScale(0.5, 1), Vector2.new(0.5, 1) },
	{ UDim2.fromOffset(10, 2), UDim2.fromScale(0, 0.5), Vector2.new(0, 0.5) },
	{ UDim2.fromOffset(10, 2), UDim2.fromScale(1, 0.5), Vector2.new(1, 0.5) },
	{ UDim2.fromOffset(4, 4), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5) },
}) do
	table.insert(crossParts, new("Frame", {
		Size = spec[1],
		Position = spec[2],
		AnchorPoint = spec[3],
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = crosshair,
	}))
end

-- Radar
local RADAR_RANGE = 250
local radar = new("Frame", {
	Size = UDim2.fromOffset(170, 170),
	Position = UDim2.new(1, -186, 1, -186),
	BackgroundColor3 = Color3.fromRGB(5, 20, 15),
	BackgroundTransparency = 0.2,
	ClipsDescendants = true,
	Parent = gui,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), accentStroke(2) })
for _, scale in ipairs({ 0.66, 0.33 }) do
	new("Frame", {
		Size = UDim2.fromScale(scale, scale),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = radar,
	}, {
		new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		new("UIStroke", { Color = Color3.fromRGB(60, 160, 120), Transparency = 0.5 }),
	})
end
new("Frame", {
	Size = UDim2.fromOffset(8, 8),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 3,
	Parent = radar,
}, { corner(2) })
label({
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.fromOffset(0, 8),
	Text = "RADAR",
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextColor3 = Color3.fromRGB(120, 255, 180),
	Parent = radar,
})
local radarBlips = {}

-- Notificações
local notifyLabel = label({
	Size = UDim2.new(1, 0, 0, 36),
	Position = UDim2.new(0, 0, 0, 90),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 26,
	Font = Enum.Font.GothamBlack,
	Text = "",
	TextTransparency = 1,
	TextStrokeTransparency = 1,
	Parent = gui,
})
local notifyToken = 0
local function notify(text, color)
	notifyToken += 1
	local token = notifyToken
	notifyLabel.Text = text
	notifyLabel.TextColor3 = color or theme().accent
	notifyLabel.TextTransparency = 0
	notifyLabel.TextStrokeTransparency = 0.3
	task.delay(2.2, function()
		if token == notifyToken then
			TweenService:Create(notifyLabel, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- Aviso para entrar
local promptLabel = label({
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 1, -130),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 20,
	TextStrokeTransparency = 0.3,
	Text = "",
	Parent = gui,
})

-- Painel de ajuda
local HELP_TEXT = table.concat({
	"<b>V</b>  entrar / sair  (longe = convocar robô)",
	"<b>W A S D</b>  andar    <b>Mouse</b>  mirar",
	"<b>Botão esquerdo</b>  canhão laser",
	"<b>Espaço</b>  pular / impulso / subir",
	"<b>Ctrl</b>  descer no voo    <b>Shift</b>  turbo",
	"<b>F</b>  modo voo    <b>E</b>  mísseis teleguiados",
	"<b>Q</b>  escudo    <b>R</b>  scanner",
	"<b>G</b>  impacto sísmico    <b>L</b>  faróis",
	"<b>C</b>  trocar cor    <b>K</b>  acenar",
	"<b>T</b>  chamar drones de treino",
	"<b>X</b> (2x)  autodestruição",
	"<b>Roda do mouse</b>  zoom    <b>H</b>  esta ajuda",
}, "\n")
local helpPanel = new("Frame", {
	Size = UDim2.fromOffset(400, 360),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(10, 12, 18),
	BackgroundTransparency = 0.1,
	Parent = gui,
}, { corner(12), accentStroke(2) })
label({
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.fromOffset(0, 8),
	Text = "CONTROLES — " .. CONFIG.NAME,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = helpPanel,
})
label({
	Size = UDim2.new(1, -40, 1, -90),
	Position = UDim2.fromOffset(20, 50),
	Text = HELP_TEXT,
	RichText = true,
	TextSize = 15,
	Font = Enum.Font.Gotham,
	LineHeight = 1.25,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = helpPanel,
})
label({
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 1, -34),
	Text = "Aperte H para fechar",
	TextSize = 13,
	TextColor3 = Color3.fromRGB(150, 160, 180),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = helpPanel,
})

local function flashDamage(amount)
	vignette.BackgroundTransparency = math.clamp(1 - amount, 0.55, 0.95)
	TweenService:Create(vignette, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
end

local function flashHitmarker()
	for _, f in ipairs(crossParts) do
		f.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	end
	task.delay(0.08, function()
		for _, f in ipairs(crossParts) do
			f.BackgroundColor3 = Color3.new(1, 1, 1)
		end
	end)
end

---------------------------------------------------------------------------------------
-- CONSTRUÇÃO DO ROBÔ
-- Cada peça pertence a uma "articulação". A posição final é:
--   mundo(articulação) * posiçãoLocalDaPeça
---------------------------------------------------------------------------------------
local JOINTS = {
	torso = { parent = "root", offset = CFrame.new(0, 0, 0) },
	head = { parent = "torso", offset = CFrame.new(0, 5.2, 0) },
	armL = { parent = "torso", offset = CFrame.new(-3.4, 4.3, 0) },
	armR = { parent = "torso", offset = CFrame.new(3.4, 4.3, 0) },
	legL = { parent = "root", offset = CFrame.new(-1.4, 0, 0) },
	legR = { parent = "root", offset = CFrame.new(1.4, 0, 0) },
	jet = { parent = "torso", offset = CFrame.new(0, 3.2, 2) },
	shoulder = { parent = "torso", offset = CFrame.new(-2.3, 5.6, 0.4) },
}
local JOINT_ORDER = { "torso", "head", "armL", "armR", "legL", "legR", "jet", "shoulder" }
local anim = {}
for _, name in ipairs(JOINT_ORDER) do
	anim[name] = CFrame.identity
end

local ROLE_MATERIAL = {
	primary = Enum.Material.Metal,
	secondary = Enum.Material.DiamondPlate,
	dark = Enum.Material.SmoothPlastic,
	accent = Enum.Material.Neon,
	hidden = Enum.Material.SmoothPlastic,
}

local pieces = {}
local pieceParts = {}
local pieceCFrames = {}

local function addPiece(joint, name, size, localCF, role, shape)
	local part = makePart({
		Name = name,
		Size = size,
		Shape = shape or Enum.PartType.Block,
		Material = ROLE_MATERIAL[role],
		Transparency = role == "hidden" and 1 or 0,
		CastShadow = role ~= "accent" and role ~= "hidden",
		Parent = robotModel,
	})
	local piece = { part = part, joint = joint, localCF = localCF, role = role, baseTransparency = part.Transparency }
	table.insert(pieces, piece)
	table.insert(pieceParts, part)
	return part
end

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local AXIS_Y = CFrame.Angles(0, 0, math.rad(90)) -- cilindro em pé
local AXIS_Z = CFrame.Angles(0, math.rad(90), 0) -- cilindro apontando pra frente

-- Pernas
for _, side in ipairs({ { "legL", -1 }, { "legR", 1 } }) do
	local j = side[1]
	addPiece(j, "Quadril", Vector3.one * 1.8, CFrame.new(), "secondary", BALL)
	addPiece(j, "Coxa", Vector3.new(1.6, 2.6, 1.8), CFrame.new(0, -1.5, 0), "primary")
	addPiece(j, "Joelho", Vector3.new(1.9, 1.3, 1.3), CFrame.new(0, -2.9, -0.1), "secondary", CYL)
	addPiece(j, "LuzJoelho", Vector3.new(0.4, 0.4, 0.2), CFrame.new(0, -2.9, -0.95), "accent")
	addPiece(j, "Canela", Vector3.new(1.5, 2.4, 1.7), CFrame.new(0, -4.2, 0), "primary")
	addPiece(j, "Pistao", Vector3.new(0.3, 2, 0.3), CFrame.new(0, -4.1, 1), "dark")
	addPiece(j, "Pe", Vector3.new(2, 0.8, 3), CFrame.new(0, -5.2, -0.4), "secondary")
	addPiece(j, "Dedo", Vector3.new(2, 0.5, 0.6), CFrame.new(0, -5.35, -2.1), "primary")
end

-- Tronco
addPiece("torso", "Pelvis", Vector3.new(3.6, 1.2, 2.4), CFrame.new(0, 0.3, 0), "secondary")
addPiece("torso", "Abdomen", Vector3.new(3, 1.6, 2.2), CFrame.new(0, 1.6, 0), "dark")
addPiece("torso", "Peito", Vector3.new(5.2, 3, 3.2), CFrame.new(0, 3.8, 0), "primary")
addPiece("torso", "Placa", Vector3.new(3.6, 2, 0.3), CFrame.new(0, 3.9, -1.7), "secondary")
local core = addPiece("torso", "Nucleo", Vector3.new(0.4, 1.4, 1.4), CFrame.new(0, 3.9, -1.9) * AXIS_Z, "accent", CYL)
addPiece("torso", "OmbreiraL", Vector3.new(1.9, 1, 2.8), CFrame.new(-3.3, 5.2, 0), "primary")
addPiece("torso", "OmbreiraR", Vector3.new(1.9, 1, 2.8), CFrame.new(3.3, 5.2, 0), "primary")
addPiece("torso", "Pescoco", Vector3.new(1, 1, 1), CFrame.new(0, 5.3, 0) * AXIS_Y, "dark", CYL)
addPiece("torso", "VentL", Vector3.new(0.1, 1.6, 0.3), CFrame.new(-2.65, 3.7, -0.8), "accent")
addPiece("torso", "VentR", Vector3.new(0.1, 1.6, 0.3), CFrame.new(2.65, 3.7, -0.8), "accent")
local coreLight = new("PointLight", { Range = 14, Brightness = 2, Parent = core })

-- Cabeça
addPiece("head", "Cabeca", Vector3.new(2.4, 1.8, 2.4), CFrame.new(0, 0.9, 0), "primary")
local visor = addPiece("head", "Visor", Vector3.new(2, 0.5, 0.2), CFrame.new(0, 1, -1.25), "accent")
addPiece("head", "Mandibula", Vector3.new(1.8, 0.5, 0.4), CFrame.new(0, 0.3, -1.1), "secondary")
addPiece("head", "Crista", Vector3.new(0.4, 0.5, 2.2), CFrame.new(0, 2, 0), "secondary")
addPiece("head", "Antena", Vector3.new(0.15, 1.4, 0.15), CFrame.new(0.8, 2.4, 0.4), "dark")
addPiece("head", "PontaAntena", Vector3.one * 0.4, CFrame.new(0.8, 3.1, 0.4), "accent", BALL)
local headlight = new("SpotLight", {
	Face = Enum.NormalId.Front,
	Range = 60,
	Angle = 60,
	Brightness = 4,
	Parent = visor,
})

-- Braços
for _, side in ipairs({ "armL", "armR" }) do
	addPiece(side, "Ombro", Vector3.one * 1.8, CFrame.new(), "secondary", BALL)
	addPiece(side, "Braco", Vector3.new(1.4, 2.4, 1.4), CFrame.new(0, -1.6, 0), "primary")
	addPiece(side, "Cotovelo", Vector3.one * 1.3, CFrame.new(0, -3, 0), "secondary", BALL)
	addPiece(side, "Antebraco", Vector3.new(1.7, 2.4, 1.8), CFrame.new(0, -4.3, 0), "primary")
	addPiece(side, "Faixa", Vector3.new(1.75, 0.25, 1.85), CFrame.new(0, -4.8, 0), "accent")
end
addPiece("armL", "Garra", Vector3.new(1.2, 1, 1.2), CFrame.new(0, -5.9, 0), "secondary")
addPiece("armL", "Dedo1", Vector3.new(0.3, 0.9, 0.3), CFrame.new(0.35, -6.7, -0.3), "dark")
addPiece("armL", "Dedo2", Vector3.new(0.3, 0.9, 0.3), CFrame.new(-0.35, -6.7, -0.3), "dark")
addPiece("armL", "Dedo3", Vector3.new(0.3, 0.9, 0.3), CFrame.new(0, -6.7, 0.4), "dark")
addPiece("armR", "Canhao", Vector3.new(0.9, 2.4, 0.9), CFrame.new(0, -6.2, 0) * AXIS_Y, "dark", CYL)
addPiece("armR", "BocaCanhao", Vector3.new(1.2, 0.3, 1.2), CFrame.new(0, -7.4, 0) * AXIS_Y, "accent", CYL)
local MUZZLE_OFFSET = CFrame.new(0, -7.8, 0)

-- Jetpack
addPiece("jet", "Mochila", Vector3.new(3, 3, 1.4), CFrame.new(0, 0, 0.3), "secondary")
addPiece("jet", "Tanque", Vector3.new(0.8, 2.6, 0.8), CFrame.new(0, 0.1, 1.1) * AXIS_Y, "primary", CYL)
addPiece("jet", "BocalL", Vector3.new(1, 1, 1), CFrame.new(-0.9, -1.8, 0.4) * AXIS_Y, "dark", CYL)
addPiece("jet", "BocalR", Vector3.new(1, 1, 1), CFrame.new(0.9, -1.8, 0.4) * AXIS_Y, "dark", CYL)
local jetEmitters = {}
local jetLights = {}
for _, x in ipairs({ -0.9, 0.9 }) do
	local anchor = addPiece("jet", "Chama", Vector3.one * 0.3, CFrame.new(x, -2.4, 0.4), "hidden")
	table.insert(jetEmitters, new("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/fire_main.dds",
		LightEmission = 1,
		Size = NumberSequence.new(1.2, 0),
		Lifetime = NumberRange.new(0.15, 0.3),
		Speed = NumberRange.new(25, 35),
		SpreadAngle = Vector2.new(8, 8),
		EmissionDirection = Enum.NormalId.Bottom,
		Rate = 90,
		Enabled = false,
		Parent = anchor,
	}))
	table.insert(jetLights, new("PointLight", { Range = 12, Brightness = 3, Enabled = false, Parent = anchor }))
end

-- Lançador de mísseis no ombro
addPiece("shoulder", "BaseLancador", Vector3.new(1.2, 0.8, 1.2), CFrame.new(), "dark")
addPiece("shoulder", "Lancador", Vector3.new(1.6, 1, 2.2), CFrame.new(0, 0.8, 0), "primary")
addPiece("shoulder", "Tubo1", Vector3.new(0.35, 0.35, 0.1), CFrame.new(-0.4, 0.8, -1.15), "accent")
addPiece("shoulder", "Tubo2", Vector3.new(0.35, 0.35, 0.1), CFrame.new(0.4, 0.8, -1.15), "accent")

-- Escudo
local shieldPart = makePart({
	Name = "Escudo",
	Shape = BALL,
	Size = Vector3.one * 17,
	Material = Enum.Material.ForceField,
	Transparency = 1,
	CastShadow = false,
	Parent = robotModel,
})

local function applyTheme()
	local t = theme()
	for _, p in ipairs(pieces) do
		if p.role == "primary" then
			p.part.Color = t.primary
		elseif p.role == "secondary" then
			p.part.Color = t.secondary
		elseif p.role == "dark" then
			p.part.Color = t.secondary:Lerp(Color3.new(0, 0, 0), 0.4)
		elseif p.role == "accent" then
			p.part.Color = t.accent
		end
	end
	shieldPart.Color = t.accent
	coreLight.Color = t.accent
	headlight.Color = t.accent:Lerp(Color3.new(1, 1, 1), 0.7)
	for _, l in ipairs(jetLights) do
		l.Color = t.accent
	end
	for _, e in ipairs(jetEmitters) do
		e.Color = ColorSequence.new(t.accent, Color3.fromRGB(255, 120, 20))
	end
	for _, s in ipairs(accentStrokes) do
		s.Color = t.accent
	end
	titleLabel.TextColor3 = t.accent
end
applyTheme()

local function setRobotVisible(visible)
	for _, p in ipairs(pieces) do
		p.part.Transparency = visible and p.baseTransparency or 1
	end
end

---------------------------------------------------------------------------------------
-- CINEMÁTICA: calcula onde cada articulação está no mundo
---------------------------------------------------------------------------------------
local jointWorld = {}

local function computeJoints()
	jointWorld.root = State.rootCF
	local aiming = State.piloting and not State.dead
	for _, name in ipairs(JOINT_ORDER) do
		local j = JOINTS[name]
		local base = jointWorld[j.parent] * j.offset
		if aiming and (name == "armR" or name == "shoulder") and (State.aimPoint - base.Position).Magnitude > 6 then
			local look = CFrame.lookAt(base.Position, State.aimPoint)
			if name == "armR" then
				-- o braço aponta para baixo (-Y); gira 90° para apontar para a mira
				jointWorld[name] = look * CFrame.Angles(math.rad(90), 0, 0) * anim[name]
			else
				jointWorld[name] = look * anim[name]
			end
		else
			jointWorld[name] = base * anim[name]
		end
	end
end

local function applyPieces()
	for i, p in ipairs(pieces) do
		pieceCFrames[i] = jointWorld[p.joint] * p.localCF
	end
	workspace:BulkMoveTo(pieceParts, pieceCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	shieldPart.CFrame = State.rootCF * CFrame.new(0, 2.5, 0)
end

---------------------------------------------------------------------------------------
-- DRONES DE TREINO
---------------------------------------------------------------------------------------
local drones = {}
local partToDrone = {}
local enemyShots = {}
local damageRobot -- declarado mais abaixo

local function spawnDrone(position)
	if #drones >= CONFIG.MAX_DRONES then
		return
	end
	local model = new("Model", { Name = "DroneTreino", Parent = droneFolder })
	local body = makePart({
		Name = "Corpo",
		Shape = BALL,
		Size = Vector3.one * 3,
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
		CanQuery = true,
		Parent = model,
	})
	local eye = makePart({
		Name = "Olho",
		Shape = BALL,
		Size = Vector3.one * 1.3,
		Color = Color3.fromRGB(255, 30, 30),
		Material = Enum.Material.Neon,
		CanQuery = true,
		Parent = model,
	})
	local ring = makePart({
		Name = "Anel",
		Shape = CYL,
		Size = Vector3.new(0.3, 5, 5),
		Color = Color3.fromRGB(90, 90, 100),
		Material = Enum.Material.Metal,
		CanQuery = true,
		Parent = model,
	})
	new("PointLight", { Color = Color3.fromRGB(255, 40, 40), Range = 10, Brightness = 2, Parent = eye })
	local billboard = new("BillboardGui", {
		Size = UDim2.new(4, 0, 0.4, 0),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		Adornee = body,
		Parent = body,
	})
	local barBg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = billboard })
	local bar = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 60, 60), BorderSizePixel = 0, Parent = barBg })

	local drone = {
		model = model,
		body = body,
		eye = eye,
		ring = ring,
		bar = bar,
		hp = CONFIG.DRONE_HEALTH,
		pos = position,
		angle = math.random() * math.pi * 2,
		radius = 35 + math.random() * 40,
		height = 12 + math.random() * 20,
		orbitSpeed = (math.random() < 0.5 and -1 or 1) * (0.3 + math.random() * 0.4),
		fireTimer = CONFIG.DRONE_FIRE_MIN + math.random() * CONFIG.DRONE_FIRE_MAX,
		spin = 0,
	}
	partToDrone[body] = drone
	partToDrone[eye] = drone
	partToDrone[ring] = drone
	table.insert(drones, drone)
	spark(position, Color3.fromRGB(255, 60, 60), 20, 20)
end

local function spawnWave()
	State.wave += 1
	local center = State.rootCF.Position
	for i = 1, CONFIG.DRONES_PER_WAVE + State.wave - 1 do
		local a = math.random() * math.pi * 2
		spawnDrone(center + Vector3.new(math.cos(a) * 90, 30 + math.random() * 20, math.sin(a) * 90))
	end
	notify("ONDA " .. State.wave .. " — DRONES CHEGANDO!", Color3.fromRGB(255, 80, 80))
end

local function removeDrone(drone)
	for i, d in ipairs(drones) do
		if d == drone then
			table.remove(drones, i)
			break
		end
	end
	partToDrone[drone.body] = nil
	partToDrone[drone.eye] = nil
	partToDrone[drone.ring] = nil
	drone.model:Destroy()
end

local function damageDrone(drone, amount)
	if drone.hp <= 0 then
		return
	end
	drone.hp -= amount
	drone.eye.Color = Color3.new(1, 1, 1)
	task.delay(0.06, function()
		if drone.eye.Parent then
			drone.eye.Color = Color3.fromRGB(255, 30, 30)
		end
	end)
	drone.bar.Size = UDim2.fromScale(math.max(drone.hp, 0) / CONFIG.DRONE_HEALTH, 1)
	if drone.hp <= 0 then
		explosion(drone.pos, 8, Color3.fromRGB(255, 120, 30))
		removeDrone(drone)
		State.score += 100
		if #drones == 0 then
			State.score += 500
			notify("ONDA " .. State.wave .. " CONCLUÍDA!  +500", Color3.fromRGB(90, 255, 120))
		end
	end
end

local function damageArea(position, radius, amount)
	-- copia a lista porque drones podem ser removidos durante o loop
	for _, drone in ipairs(table.clone(drones)) do
		local dist = (drone.pos - position).Magnitude
		if dist <= radius then
			damageDrone(drone, amount * (1 - dist / radius * 0.5))
		end
	end
end

local function torsoCenter()
	return State.rootCF.Position + Vector3.new(0, 3.5, 0)
end

local function updateDrones(dt)
	local robotPos = State.rootCF.Position
	for _, drone in ipairs(drones) do
		drone.angle += dt * drone.orbitSpeed
		local target = robotPos
			+ Vector3.new(math.cos(drone.angle) * drone.radius, drone.height, math.sin(drone.angle) * drone.radius)
		drone.pos = drone.pos:Lerp(target, math.min(1, dt * 1.2))
		drone.spin += dt * 4
		local cf = CFrame.lookAt(drone.pos, torsoCenter())
		drone.body.CFrame = cf
		drone.eye.CFrame = cf * CFrame.new(0, 0, -1.2)
		drone.ring.CFrame = cf * CFrame.Angles(0, 0, drone.spin) * CFrame.Angles(0, math.rad(90), 0)

		drone.fireTimer -= dt
		if drone.fireTimer <= 0 and not State.dead then
			drone.fireTimer = CONFIG.DRONE_FIRE_MIN + math.random() * (CONFIG.DRONE_FIRE_MAX - CONFIG.DRONE_FIRE_MIN)
			if (drone.pos - robotPos).Magnitude < 260 then
				local from = drone.pos + cf.LookVector * 2
				local aim = torsoCenter() + State.velocity * 0.3
				local shot = makePart({
					Shape = BALL,
					Size = Vector3.one * 1.1,
					Color = Color3.fromRGB(255, 40, 40),
					Material = Enum.Material.Neon,
					CastShadow = false,
					Position = from,
					Parent = effects,
				})
				new("PointLight", { Color = Color3.fromRGB(255, 40, 40), Range = 8, Parent = shot })
				table.insert(enemyShots, {
					part = shot,
					pos = from,
					vel = (aim - from).Unit * CONFIG.DRONE_SHOT_SPEED,
					life = 5,
				})
			end
		end
	end

	for i = #enemyShots, 1, -1 do
		local shot = enemyShots[i]
		shot.life -= dt
		local step = shot.vel * dt
		local newPos = shot.pos + step
		local done = shot.life <= 0
		if not done and not State.dead and (newPos - torsoCenter()).Magnitude < 5.5 then
			damageRobot(CONFIG.DRONE_DAMAGE, newPos)
			done = true
		elseif not done then
			local hit = workspace:Raycast(shot.pos, step, rayWorld)
			if hit then
				spark(hit.Position, Color3.fromRGB(255, 60, 60), 8)
				done = true
			end
		end
		if done then
			shot.part:Destroy()
			table.remove(enemyShots, i)
		else
			shot.pos = newPos
			shot.part.Position = newPos
		end
	end
end

---------------------------------------------------------------------------------------
-- PILOTO (personagem do jogador)
---------------------------------------------------------------------------------------
local controls
task.spawn(function()
	pcall(function()
		local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		controls = module:GetControls()
	end)
end)

local function getCharacterParts()
	local char = player.Character
	if not char then
		return nil, nil
	end
	return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function setCharacterHidden(hidden)
	local char = player.Character
	if not char then
		return
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d.LocalTransparencyModifier = hidden and 1 or 0
		end
	end
end

local function placeRobotNear(position, lookVector)
	local flat = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local spot = position + flat.Unit * 14
	local y = findGroundY(spot) + CONFIG.HIP_HEIGHT
	State.yaw = math.atan2(flat.X, flat.Z) -- robô fica de frente para o jogador
	State.rootCF = CFrame.new(spot.X, y, spot.Z) * CFrame.Angles(0, State.yaw, 0)
	State.velocity = Vector3.zero
end

local function exitRobot()
	if not State.piloting then
		return
	end
	State.piloting = false
	State.firing = false
	State.flying = false
	local hrp, humanoid = getCharacterParts()
	if hrp then
		hrp.Anchored = false
		hrp.CFrame = State.rootCF * CFrame.new(-7, -2, 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
	setCharacterHidden(false)
	if controls then
		controls:Enable()
	end
	camera.CameraType = Enum.CameraType.Custom
	if humanoid then
		camera.CameraSubject = humanoid
	end
	camera.FieldOfView = 70
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	notify("VOCÊ SAIU DO ROBÔ")
end

local function enterRobot()
	local hrp, humanoid = getCharacterParts()
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return
	end
	local dist = (hrp.Position - State.rootCF.Position).Magnitude
	if dist > CONFIG.ENTER_DISTANCE or State.dead then
		if State.dead then
			notify("ROBÔ EM RECONSTRUÇÃO...", Color3.fromRGB(255, 170, 60))
			return
		end
		explosion(State.rootCF.Position, 6, theme().accent)
		placeRobotNear(hrp.Position, hrp.CFrame.LookVector)
		explosion(State.rootCF.Position, 10, theme().accent)
		playSound(CONFIG.SOUNDS.whoosh, 0.8)
		notify("ROBÔ CONVOCADO! Aperte V para entrar")
		return
	end
	State.piloting = true
	hrp.Anchored = true
	if controls then
		controls:Disable()
	end
	State.camYaw = State.yaw
	State.camPitch = -0.2
	camera.CameraType = Enum.CameraType.Scriptable
	playSound(CONFIG.SOUNDS.whoosh, 0.6, 1.3)
	notify("SISTEMAS ONLINE — BEM-VINDO, PILOTO")
end

local function hookCharacter(char)
	refreshFilters()
	local humanoid = char:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(function()
			if State.piloting then
				exitRobot()
			end
		end)
	end
end
player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	task.spawn(hookCharacter, player.Character)
end

---------------------------------------------------------------------------------------
-- DANO / DESTRUIÇÃO DO ROBÔ
---------------------------------------------------------------------------------------
local function destroyRobot()
	if State.dead then
		return
	end
	State.dead = true
	State.health = 0
	State.flying = false
	State.shield = false
	State.firing = false
	local center = torsoCenter()
	explosion(center, 25, Color3.fromRGB(255, 100, 20))
	task.delay(0.2, function()
		explosion(center + Vector3.new(3, 4, 0), 15)
	end)
	task.delay(0.4, function()
		explosion(center + Vector3.new(-3, 1, 2), 18)
	end)
	setRobotVisible(false)
	notify("ROBÔ DESTRUÍDO — reconstruindo em 5s", Color3.fromRGB(255, 70, 70))
	task.delay(5, function()
		State.dead = false
		State.health = CONFIG.MAX_HEALTH
		State.energy = CONFIG.MAX_ENERGY
		State.velocity = Vector3.zero
		setRobotVisible(true)
		explosion(torsoCenter(), 12, theme().accent)
		notify("ROBÔ RECONSTRUÍDO!", Color3.fromRGB(90, 255, 120))
	end)
end

function damageRobot(amount, hitPos)
	if State.dead then
		return
	end
	if State.shield then
		State.energy = math.max(0, State.energy - amount * 0.3)
		spark(hitPos, theme().accent, 15, 25)
		if State.energy <= 0 then
			State.shield = false
			notify("ESCUDO SOBRECARREGADO!", Color3.fromRGB(255, 170, 60))
		end
		return
	end
	State.health -= amount
	spark(hitPos, Color3.fromRGB(255, 200, 80), 15, 25)
	playSound(CONFIG.SOUNDS.hit, 0.8, 0.8, hitPos)
	addShake(0.6)
	if State.piloting then
		flashDamage(amount / 100)
	end
	if State.health <= 0 then
		destroyRobot()
	end
end

---------------------------------------------------------------------------------------
-- ARMAS E HABILIDADES
---------------------------------------------------------------------------------------
local missiles = {}

local function fireLaser()
	local muzzle = (jointWorld.armR * MUZZLE_OFFSET).Position
	local dir = State.aimPoint - muzzle
	if dir.Magnitude < 1 then
		return
	end
	local hit = workspace:Raycast(muzzle, dir.Unit * CONFIG.LASER_RANGE, rayAim)
	local endPos = hit and hit.Position or muzzle + dir.Unit * CONFIG.LASER_RANGE
	local t = theme()
	laserBeam(muzzle, endPos, t.accent, 0.45)
	laserBeam(muzzle, endPos, Color3.new(1, 1, 1), 0.15)
	spark(muzzle, t.accent, 4, 10)
	playSound(CONFIG.SOUNDS.laser, 0.35, 1.4 + math.random() * 0.2)
	addShake(0.05)
	anim.armR = anim.armR * CFrame.new(0, 0.4, 0) -- recuo
	if hit then
		spark(hit.Position, t.accent, 8, 20)
		local drone = partToDrone[hit.Instance]
		if drone then
			damageDrone(drone, CONFIG.LASER_DAMAGE)
			flashHitmarker()
		end
	end
end

local function findMissileTarget()
	local best, bestDist = nil, 80
	for _, drone in ipairs(drones) do
		local d = (drone.pos - State.aimPoint).Magnitude
		if d < bestDist then
			best, bestDist = drone, d
		end
	end
	return best
end

local function fireMissiles()
	if State.cooldowns.missile > 0 or State.energy < CONFIG.MISSILE_COST then
		return
	end
	State.cooldowns.missile = CONFIG.MISSILE_COOLDOWN
	State.energy -= CONFIG.MISSILE_COST
	local target = findMissileTarget()
	local t = theme()
	for _, x in ipairs({ -0.4, 0.4 }) do
		local spawnCF = jointWorld.shoulder * CFrame.new(x, 0.8, -1.5)
		local part = makePart({
			Name = "Missil",
			Size = Vector3.new(0.5, 0.5, 2.2),
			CFrame = spawnCF,
			Color = Color3.fromRGB(220, 220, 225),
			Material = Enum.Material.Metal,
			Parent = effects,
		})
		local a0 = new("Attachment", { Position = Vector3.new(0, 0.2, 1.1), Parent = part })
		local a1 = new("Attachment", { Position = Vector3.new(0, -0.2, 1.1), Parent = part })
		new("Trail", {
			Attachment0 = a0,
			Attachment1 = a1,
			Color = ColorSequence.new(t.accent, Color3.fromRGB(80, 80, 80)),
			Lifetime = 0.5,
			LightEmission = 1,
			Transparency = NumberSequence.new(0, 1),
			Parent = part,
		})
		new("ParticleEmitter", {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(150, 150, 150)),
			Size = NumberSequence.new(0.8, 2.5),
			Transparency = NumberSequence.new(0.4, 1),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(1, 3),
			Rate = 40,
			Parent = a0,
		})
		new("PointLight", { Color = Color3.fromRGB(255, 150, 50), Range = 8, Brightness = 3, Parent = part })
		table.insert(missiles, {
			part = part,
			pos = spawnCF.Position,
			vel = spawnCF.LookVector * CONFIG.MISSILE_SPEED * 0.5 + Vector3.new(x * 20, 15, 0),
			target = target,
			targetPos = State.aimPoint,
			life = 6,
		})
	end
	playSound(CONFIG.SOUNDS.missile, 0.8)
	addShake(0.3)
end

local function updateMissiles(dt)
	for i = #missiles, 1, -1 do
		local m = missiles[i]
		m.life -= dt
		if m.target and m.target.hp > 0 then
			m.targetPos = m.target.pos
		end
		local desired = (m.targetPos - m.pos)
		if desired.Magnitude > 0.1 then
			m.vel = m.vel:Lerp(desired.Unit * CONFIG.MISSILE_SPEED, math.min(1, dt * 5))
		end
		local step = m.vel * dt
		local hit = workspace:Raycast(m.pos, step, rayAim)
		local explodeAt
		if hit then
			explodeAt = hit.Position
		elseif (m.pos - m.targetPos).Magnitude < 4 or m.life <= 0 then
			explodeAt = m.pos
		end
		if explodeAt then
			explosion(explodeAt, CONFIG.MISSILE_RADIUS * 0.6, Color3.fromRGB(255, 130, 30))
			damageArea(explodeAt, CONFIG.MISSILE_RADIUS, CONFIG.MISSILE_DAMAGE)
			m.part:Destroy()
			table.remove(missiles, i)
		else
			m.pos += step
			if step.Magnitude > 0.01 then
				m.part.CFrame = CFrame.lookAt(m.pos, m.pos + step)
			end
		end
	end
end

local function toggleShield()
	if not State.shield and State.energy < 10 then
		notify("ENERGIA INSUFICIENTE", Color3.fromRGB(255, 170, 60))
		return
	end
	State.shield = not State.shield
	shieldPart.Transparency = State.shield and 0 or 1
	playSound(CONFIG.SOUNDS.whoosh, 0.5, State.shield and 1.6 or 0.8)
	notify(State.shield and "ESCUDO ATIVADO" or "ESCUDO DESATIVADO")
end

local function toggleFlight()
	if not State.flying and State.energy < 10 then
		notify("ENERGIA INSUFICIENTE", Color3.fromRGB(255, 170, 60))
		return
	end
	State.flying = not State.flying
	if State.flying then
		State.velocity += Vector3.new(0, 30, 0)
	end
	notify(State.flying and "MODO VOO" or "MODO CAMINHADA")
end

local function scan()
	if State.cooldowns.scan > 0 or State.energy < CONFIG.SCAN_COST then
		return
	end
	State.cooldowns.scan = CONFIG.SCAN_COOLDOWN
	State.energy -= CONFIG.SCAN_COST
	local ball = makePart({
		Shape = BALL,
		Size = Vector3.one * 4,
		Position = torsoCenter(),
		Color = theme().accent,
		Material = Enum.Material.ForceField,
		CastShadow = false,
		Parent = effects,
	})
	TweenService:Create(ball, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * CONFIG.SCAN_RANGE * 2,
		Transparency = 1,
	}):Play()
	Debris:AddItem(ball, 1.3)
	local found = 0
	for _, drone in ipairs(drones) do
		if (drone.pos - State.rootCF.Position).Magnitude <= CONFIG.SCAN_RANGE then
			found += 1
			local h = new("Highlight", {
				FillColor = Color3.fromRGB(255, 40, 40),
				OutlineColor = Color3.new(1, 1, 1),
				FillTransparency = 0.4,
				Adornee = drone.model,
				Parent = drone.model,
			})
			Debris:AddItem(h, 6)
		end
	end
	playSound(CONFIG.SOUNDS.laser, 0.6, 0.6)
	notify(("SCANNER: %d ALVO(S) DETECTADO(S)"):format(found))
end

local function shockwave()
	local pos = State.rootCF.Position - Vector3.new(0, CONFIG.HIP_HEIGHT - 0.3, 0)
	local ring = makePart({
		Shape = CYL,
		Size = Vector3.new(0.6, 4, 4),
		CFrame = CFrame.new(pos) * AXIS_Y,
		Color = theme().accent,
		Material = Enum.Material.Neon,
		CastShadow = false,
		Parent = effects,
	})
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.3, CONFIG.SLAM_RADIUS * 2, CONFIG.SLAM_RADIUS * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.7)
	explosion(pos, 10, theme().accent)
	spark(pos, Color3.fromRGB(120, 110, 100), 40, 35)
	damageArea(pos, CONFIG.SLAM_RADIUS * 1.5, CONFIG.SLAM_DAMAGE)
	addShake(2)
end

local function groundSlam()
	if State.cooldowns.slam > 0 or State.energy < CONFIG.SLAM_COST then
		return
	end
	State.cooldowns.slam = CONFIG.SLAM_COOLDOWN
	State.energy -= CONFIG.SLAM_COST
	if State.onGround then
		shockwave()
	else
		State.flying = false
		State.slamming = true
		playSound(CONFIG.SOUNDS.whoosh, 0.9, 0.7)
	end
end

local function onLand(fallSpeed)
	if State.slamming then
		State.slamming = false
		shockwave()
	elseif fallSpeed > 50 then
		addShake(fallSpeed / 120)
		spark(State.rootCF.Position - Vector3.new(0, CONFIG.HIP_HEIGHT, 0), Color3.fromRGB(130, 120, 110), 20, 20)
		playSound(CONFIG.SOUNDS.land, 1, 0.6)
	end
end

local function jump()
	if State.flying then
		return
	end
	if State.onGround then
		State.velocity = Vector3.new(State.velocity.X, CONFIG.JUMP_POWER, State.velocity.Z)
		playSound(CONFIG.SOUNDS.jump, 0.8, 0.7)
	elseif State.energy >= CONFIG.JET_BOOST_COST then
		State.energy -= CONFIG.JET_BOOST_COST
		State.velocity = Vector3.new(State.velocity.X, CONFIG.JUMP_POWER * 0.9, State.velocity.Z)
		State.jetBoost = 0.5
		playSound(CONFIG.SOUNDS.whoosh, 0.7, 1.2)
	end
end

local function selfDestruct()
	if State.destructArmed > 0 then
		State.destructArmed = 0
		damageArea(torsoCenter(), 70, 999)
		destroyRobot()
	else
		State.destructArmed = 2
		notify("AUTODESTRUIÇÃO: aperte X de novo para confirmar", Color3.fromRGB(255, 60, 60))
	end
end

---------------------------------------------------------------------------------------
-- ENTRADA (TECLADO / MOUSE)
---------------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local key = input.KeyCode

	if key == Enum.KeyCode.V then
		if State.piloting then
			exitRobot()
		else
			enterRobot()
		end
		return
	elseif key == Enum.KeyCode.H then
		State.showHelp = not State.showHelp
		return
	end

	if not State.piloting or State.dead then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.firing = true
	elseif key == Enum.KeyCode.Space then
		jump()
	elseif key == Enum.KeyCode.F then
		toggleFlight()
	elseif key == Enum.KeyCode.E then
		fireMissiles()
	elseif key == Enum.KeyCode.Q then
		toggleShield()
	elseif key == Enum.KeyCode.R then
		scan()
	elseif key == Enum.KeyCode.G then
		groundSlam()
	elseif key == Enum.KeyCode.L then
		State.lights = not State.lights
		notify(State.lights and "FARÓIS LIGADOS" or "FARÓIS DESLIGADOS")
	elseif key == Enum.KeyCode.C then
		State.themeIndex = State.themeIndex % #THEMES + 1
		applyTheme()
		notify("TEMA: " .. theme().name:upper())
	elseif key == Enum.KeyCode.K then
		State.waveTime = 3
	elseif key == Enum.KeyCode.T then
		spawnWave()
	elseif key == Enum.KeyCode.X then
		selfDestruct()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.firing = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not State.piloting then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		State.camYaw -= input.Delta.X * CONFIG.MOUSE_SENSITIVITY
		State.camPitch = math.clamp(State.camPitch - input.Delta.Y * CONFIG.MOUSE_SENSITIVITY, -1.2, 0.9)
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		State.camDist = math.clamp(State.camDist - input.Position.Z * 4, CONFIG.CAMERA_MIN, CONFIG.CAMERA_MAX)
	end
end)

---------------------------------------------------------------------------------------
-- FÍSICA DO ROBÔ
---------------------------------------------------------------------------------------
local function updatePhysics(dt)
	local pos = State.rootCF.Position
	local vel = State.velocity
	local canControl = State.piloting and not State.dead

	local moveDir = Vector3.zero
	if canControl then
		local f, r = 0, 0
		if isDown(Enum.KeyCode.W) then f += 1 end
		if isDown(Enum.KeyCode.S) then f -= 1 end
		if isDown(Enum.KeyCode.D) then r += 1 end
		if isDown(Enum.KeyCode.A) then r -= 1 end
		local forward = Vector3.new(-math.sin(State.camYaw), 0, -math.cos(State.camYaw))
		local right = Vector3.new(math.cos(State.camYaw), 0, -math.sin(State.camYaw))
		local m = forward * f + right * r
		if m.Magnitude > 0 then
			moveDir = m.Unit
		end
	end
	State.turbo = canControl and isDown(Enum.KeyCode.LeftShift) and moveDir.Magnitude > 0 and State.energy > 1

	if State.flying then
		local speed = State.turbo and CONFIG.FLY_TURBO_SPEED or CONFIG.FLY_SPEED
		local up = 0
		if canControl then
			if isDown(Enum.KeyCode.Space) then up += 1 end
			if isDown(Enum.KeyCode.LeftControl) then up -= 1 end
		end
		local desired = moveDir * speed + Vector3.new(0, up * speed * 0.6, 0)
		vel = vel:Lerp(desired, math.min(1, dt * 4))
	else
		local speed = State.turbo and CONFIG.TURBO_SPEED or CONFIG.WALK_SPEED
		local horizontal = Vector3.new(vel.X, 0, vel.Z):Lerp(moveDir * speed, math.min(1, dt * (State.onGround and 10 or 2.5)))
		local vy = State.slamming and -220 or (vel.Y - CONFIG.GRAVITY * dt)
		vel = Vector3.new(horizontal.X, vy, horizontal.Z)
	end

	-- Paredes: desliza ao longo delas
	local horizontal = Vector3.new(vel.X, 0, vel.Z)
	if horizontal.Magnitude > 0.01 then
		local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), horizontal.Unit * (horizontal.Magnitude * dt + 2.5), rayWorld)
		if hit and hit.Normal.Y < 0.6 then
			local n = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
			if n.Magnitude > 0.01 then
				n = n.Unit
				local into = horizontal:Dot(n)
				if into < 0 then
					horizontal -= n * into
				end
			end
			vel = Vector3.new(horizontal.X, vel.Y, horizontal.Z)
		end
	end

	local newPos = pos + vel * dt

	-- Chão
	local wasOnGround = State.onGround
	State.onGround = false
	local groundHit = workspace:Raycast(newPos + Vector3.new(0, 4, 0), Vector3.new(0, -(CONFIG.HIP_HEIGHT + 7), 0), rayWorld)
	if groundHit and vel.Y <= 0.01 then
		local standY = groundHit.Position.Y + CONFIG.HIP_HEIGHT
		local sticking = wasOnGround and not State.flying and newPos.Y - standY < 1.5
		if newPos.Y <= standY or sticking then
			newPos = Vector3.new(newPos.X, standY, newPos.Z)
			if not wasOnGround then
				onLand(-vel.Y)
			end
			vel = Vector3.new(vel.X, 0, vel.Z)
			State.onGround = true
		end
	end

	-- Caiu no vazio: volta para o centro do mapa
	if newPos.Y < workspace.FallenPartsDestroyHeight + 30 then
		newPos = Vector3.new(0, findGroundY(Vector3.new(0, 200, 0)) + CONFIG.HIP_HEIGHT, 0)
		vel = Vector3.zero
		notify("ROBÔ RESGATADO DO VAZIO", Color3.fromRGB(255, 170, 60))
	end

	if canControl then
		State.yaw = lerpAngle(State.yaw, State.camYaw, math.min(1, dt * CONFIG.TURN_SPEED))
	end
	State.velocity = vel
	State.rootCF = CFrame.new(newPos) * CFrame.Angles(0, State.yaw, 0)
end

local function updateEnergy(dt)
	local drain = 0
	if State.flying then drain += CONFIG.FLY_DRAIN end
	if State.shield then drain += CONFIG.SHIELD_DRAIN end
	if State.turbo then drain += CONFIG.TURBO_DRAIN end
	local regen = drain > 0 and 0 or CONFIG.ENERGY_REGEN
	State.energy = math.clamp(State.energy + (regen - drain) * dt, 0, CONFIG.MAX_ENERGY)
	if State.energy <= 0 then
		if State.flying then
			State.flying = false
			notify("SEM ENERGIA PARA VOAR", Color3.fromRGB(255, 170, 60))
		end
		if State.shield then
			State.shield = false
		end
	end
	shieldPart.Transparency = State.shield and 0 or 1
end

---------------------------------------------------------------------------------------
-- CÂMERA E MIRA
---------------------------------------------------------------------------------------
local function updateCamera(dt)
	if not State.piloting then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	local focus = State.rootCF.Position + Vector3.new(0, 7.5, 0)
	local rotation = CFrame.Angles(0, State.camYaw, 0) * CFrame.Angles(State.camPitch, 0, 0)
	local desired = (CFrame.new(focus) * rotation * CFrame.new(3, 1.5, State.camDist)).Position
	local dir = desired - focus
	local hit = workspace:Raycast(focus, dir, rayWorld)
	local camPos = hit and (hit.Position - dir.Unit) or desired

	State.shake = math.max(0, State.shake - dt * 3)
	local s = State.shake * 0.04
	local shakeCF = CFrame.Angles((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s)
	camera.CFrame = CFrame.new(camPos) * rotation * shakeCF

	local targetFov = State.turbo and 85 or 70
	camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 5)

	local camCF = camera.CFrame
	local aimHit = workspace:Raycast(camCF.Position, camCF.LookVector * CONFIG.LASER_RANGE, rayAim)
	State.aimPoint = aimHit and aimHit.Position or camCF.Position + camCF.LookVector * CONFIG.LASER_RANGE
end

---------------------------------------------------------------------------------------
-- ANIMAÇÃO PROCEDURAL
---------------------------------------------------------------------------------------
local clock = 0

local function updateAnimation(dt)
	clock += dt
	local vel = State.velocity
	local localVel = State.rootCF:VectorToObjectSpace(vel)
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local amount = math.clamp(speed / CONFIG.WALK_SPEED, 0, 1.4)
	local target = {}

	if State.onGround and not State.flying then
		State.walkPhase += dt * speed * 0.3
		local s = math.sin(State.walkPhase)
		target.legL = CFrame.Angles(s * 0.6 * amount, 0, 0)
		target.legR = CFrame.Angles(-s * 0.6 * amount, 0, 0)
		target.armL = CFrame.Angles(-s * 0.5 * amount, 0, -0.08)
		target.armR = CFrame.Angles(s * 0.5 * amount, 0, 0.08)
		local bob = math.abs(math.cos(State.walkPhase)) * 0.35 * amount + math.sin(clock * 2) * 0.05
		target.torso = CFrame.new(0, bob, 0) * CFrame.Angles(localVel.Z * 0.004, 0, -localVel.X * 0.004)

		-- Passos: som + tremor
		local sign = s >= 0 and 1 or -1
		if sign ~= State.lastStepSign and speed > 3 then
			State.lastStepSign = sign
			playSound(CONFIG.SOUNDS.land, 0.4, 0.5)
			if State.piloting then
				addShake(0.12 * amount)
			end
		end
	elseif State.flying then
		target.legL = CFrame.Angles(-0.35 + math.sin(clock * 3) * 0.05, 0, 0)
		target.legR = CFrame.Angles(-0.25 + math.sin(clock * 3 + 1) * 0.05, 0, 0)
		target.armL = CFrame.Angles(-0.2, 0, -0.25)
		target.armR = CFrame.Angles(-0.2, 0, 0.25)
		target.torso = CFrame.new(0, math.sin(clock * 2) * 0.3, 0)
			* CFrame.Angles(localVel.Z * 0.006, 0, -localVel.X * 0.006)
	else
		target.legL = CFrame.Angles(0.4, 0, 0)
		target.legR = CFrame.Angles(-0.2, 0, 0)
		target.armL = CFrame.Angles(0.3, 0, -0.5)
		target.armR = CFrame.Angles(0.3, 0, 0.5)
		target.torso = CFrame.Angles(localVel.Z * 0.004, 0, 0)
	end

	-- Aceno
	if State.waveTime > 0 then
		State.waveTime -= dt
		target.armL = CFrame.Angles(0, 0, -2.6 + math.sin(clock * 12) * 0.35)
	end

	-- Cabeça segue a mira
	if State.piloting and not State.dead then
		local headPos = (State.rootCF * CFrame.new(0, 6, 0)).Position
		local dir = State.aimPoint - headPos
		if dir.Magnitude > 1 then
			local localDir = State.rootCF:VectorToObjectSpace(dir.Unit)
			local pitch = math.clamp(math.asin(math.clamp(localDir.Y, -1, 1)), -0.5, 0.6)
			local yaw = math.clamp(math.atan2(-localDir.X, -localDir.Z), -0.8, 0.8)
			target.head = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		end
		target.armR = CFrame.identity -- o braço direito é apontado pela mira
		target.shoulder = CFrame.identity
	else
		target.head = CFrame.Angles(math.sin(clock * 0.7) * 0.1, math.sin(clock * 0.5) * 0.4, 0)
		target.shoulder = CFrame.Angles(0, math.sin(clock * 0.5) * 0.3, 0)
	end

	target.jet = CFrame.Angles(State.flying and 0.25 or 0, 0, 0)

	local alpha = math.min(1, dt * 12)
	for _, name in ipairs(JOINT_ORDER) do
		anim[name] = anim[name]:Lerp(target[name] or CFrame.identity, alpha)
	end

	-- Efeitos visuais contínuos
	local jetOn = not State.dead and (State.flying or State.jetBoost > 0 or State.slamming or (State.turbo and State.onGround))
	for _, e in ipairs(jetEmitters) do
		e.Enabled = jetOn
	end
	for _, l in ipairs(jetLights) do
		l.Enabled = jetOn
	end
	headlight.Enabled = State.lights and not State.dead
	coreLight.Brightness = 1.5 + math.sin(clock * 4) * 0.8
end

---------------------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------------------
local function updateHUD()
	local hpRatio = math.clamp(State.health / CONFIG.MAX_HEALTH, 0, 1)
	hpFill.Size = UDim2.fromScale(hpRatio, 1)
	hpFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(60, 220, 90), hpRatio)
	hpText.Text = ("INTEGRIDADE  %d / %d"):format(math.max(0, math.floor(State.health)), CONFIG.MAX_HEALTH)
	enFill.Size = UDim2.fromScale(State.energy / CONFIG.MAX_ENERGY, 1)
	enText.Text = ("ENERGIA  %d%%"):format(math.floor(State.energy / CONFIG.MAX_ENERGY * 100))

	local mode = State.dead and "DESTRUÍDO"
		or State.slamming and "MERGULHO"
		or State.flying and (State.turbo and "VOO TURBO" or "VOO")
		or State.turbo and "TURBO"
		or State.onGround and "CAMINHADA"
		or "NO AR"
	local groundY = findGroundY(State.rootCF.Position)
	infoLabels[1].Text = "MODO: " .. mode
	infoLabels[2].Text = ("VELOCIDADE: %d studs/s"):format(math.floor(State.velocity.Magnitude))
	infoLabels[3].Text = ("ALTITUDE: %d   TEMA: %s"):format(math.floor(State.rootCF.Position.Y - CONFIG.HIP_HEIGHT - groundY), theme().name)
	infoLabels[4].Text = ("PONTOS: %d   ONDA: %d   DRONES: %d"):format(State.score, State.wave, #drones)

	if hpRatio < 0.25 and not State.dead then
		warningLabel.Text = (clock % 0.8 < 0.4) and "⚠ INTEGRIDADE CRÍTICA ⚠" or ""
	else
		warningLabel.Text = ""
	end

	local cooldownMax = { missile = CONFIG.MISSILE_COOLDOWN, scan = CONFIG.SCAN_COOLDOWN, slam = CONFIG.SLAM_COOLDOWN }
	for id, max in pairs(cooldownMax) do
		slotUI[id].overlay.Size = UDim2.fromScale(1, math.clamp(State.cooldowns[id] / max, 0, 1))
	end
	local toggles = { shield = State.shield, fly = State.flying, lights = State.lights }
	for id, on in pairs(toggles) do
		slotUI[id].stroke.Color = on and theme().accent or Color3.fromRGB(90, 95, 110)
		slotUI[id].stroke.Thickness = on and 3 or 1.5
	end

	crosshair.Visible = State.piloting and not State.dead
	abilityBar.Visible = State.piloting
	helpPanel.Visible = State.showHelp

	if State.piloting then
		promptLabel.Text = ""
	else
		local hrp = getCharacterParts()
		local near = hrp and (hrp.Position - State.rootCF.Position).Magnitude <= CONFIG.ENTER_DISTANCE
		promptLabel.Text = near and "Aperte  V  para ENTRAR no robô" or "Aperte  V  para CONVOCAR o robô"
	end

	-- Radar
	for i, drone in ipairs(drones) do
		local blip = radarBlips[i]
		if not blip then
			blip = new("Frame", {
				Size = UDim2.fromOffset(7, 7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 60, 60),
				ZIndex = 2,
				Parent = radar,
			}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			radarBlips[i] = blip
		end
		local rel = State.rootCF:PointToObjectSpace(drone.pos)
		local flat = Vector2.new(rel.X, rel.Z) / RADAR_RANGE * 80
		if flat.Magnitude > 78 then
			flat = flat.Unit * 78
		end
		blip.Position = UDim2.new(0.5, flat.X, 0.5, flat.Y)
		blip.Visible = true
	end
	for i = #drones + 1, #radarBlips do
		radarBlips[i].Visible = false
	end
end

---------------------------------------------------------------------------------------
-- LOOP PRINCIPAL
---------------------------------------------------------------------------------------
local function mainLoop(dt)
	dt = math.min(dt, 0.1)

	for k, v in pairs(State.cooldowns) do
		State.cooldowns[k] = math.max(0, v - dt)
	end
	State.jetBoost = math.max(0, State.jetBoost - dt)
	State.destructArmed = math.max(0, State.destructArmed - dt)

	if not State.dead then
		updatePhysics(dt)
		updateEnergy(dt)
	end
	updateCamera(dt)

	if State.piloting and State.firing and not State.dead and State.cooldowns.laser <= 0 and State.energy >= CONFIG.LASER_COST then
		State.cooldowns.laser = CONFIG.LASER_RATE
		State.energy -= CONFIG.LASER_COST
		computeJoints()
		fireLaser()
	end

	updateAnimation(dt)
	computeJoints()
	if not State.dead then
		applyPieces()
	end

	-- Mantém o piloto escondido dentro do peito do robô
	if State.piloting then
		local hrp = getCharacterParts()
		if hrp then
			hrp.CFrame = jointWorld.torso * CFrame.new(0, 3.5, 0)
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		setCharacterHidden(true)
	end

	updateMissiles(dt)
	updateDrones(dt)
	updateHUD()
end

-- Posiciona o robô na frente do jogador quando ele aparecer
task.spawn(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if hrp then
		placeRobotNear(hrp.Position, hrp.CFrame.LookVector)
	end
	computeJoints()
	applyPieces()
	RunService:BindToRenderStep("RoboTitan", Enum.RenderPriority.Camera.Value + 1, mainLoop)
	notify(CONFIG.NAME .. " PRONTO — aperte V para entrar")
	task.delay(8, function()
		State.showHelp = false
	end)
end)
