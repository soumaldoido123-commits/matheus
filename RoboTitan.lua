--[[
=====================================================================================
   TITAN X-9: CIDADE EM RUÍNAS
   Jogo completo em UM ÚNICO script: robô gigante + cidade destrutível com interiores
=====================================================================================

  COMO INSTALAR
   1. Abra o Roblox Studio e crie um jogo novo do tipo "Baseplate".
   2. No Explorer: StarterPlayer > StarterPlayerScripts
   3. Clique no "+" ao lado de StarterPlayerScripts > LocalScript
   4. Apague o conteúdo do LocalScript e cole ESTE código inteiro.
   5. Aperte Play (F5). A cidade é gerada, o menu aparece e é só jogar.

  MODOS DE JOGO
   MISSÃO ... Ondas de drones cada vez maiores. A cada 5 ondas vem a NAVE-MÃE.
              Você tem 3 vidas. Drones destruídos às vezes soltam reparos/energia.
   LIVRE .... Sem limite: destrua a cidade inteira, chame drones com T.

  CONTROLES (dentro do robô)
   V ............ Entrar / sair do robô (se estiver longe, convoca o robô até você)
   W A S D ...... Andar                      Mouse ........ Mirar / câmera
   Botão esq. ... Canhão laser (segure)      Roda do mouse  Zoom
   Espaço ....... Pular / impulso do jetpack / subir voando
   Ctrl esq. .... Descer (no modo voo)
   Shift esq. ... Turbo (com turbo você ATRAVESSA paredes!)
   F ............ Modo voo                   E ............ Mísseis teleguiados
   Q ............ Escudo de energia          R ............ Scanner
   G ............ Impacto sísmico (no ar: mergulha e esmaga o chão)
   L ............ Faróis                     C ............ Trocar cor do robô
   K ............ Acenar                     T ............ Drones (modo livre)
   N ............ Avançar o relógio (dia/noite)
   X (2 vezes) .. Autodestruição             P ............ Pausar
   H ............ Ajuda

  A CIDADE
   - Prédios feitos de paredes, janelas e lajes. Tudo quebra em pedaços.
   - Se a base de um prédio for destruída (ou boa parte dele), ele DESMORONA.
   - Lojas com interior: mercado, pizzaria, café, banco e fliperama. Dá pra
     sair do robô (V) e entrar a pé.
   - Trânsito com carros que param para você e explodem em cadeia.
   - Postes, árvores, praça com fonte, parques, estacionamentos.
   - Ciclo de dia e noite com luzes nas janelas e nos postes.
   - Otimizado: interiores e luzes só são carregados perto da câmera,
     escombros têm limite e somem sozinhos, geração em etapas.

  OBSERVAÇÃO
   Tudo é criado no cliente (LocalScript), então é um jogo para 1 jogador:
   outros jogadores não enxergam o robô nem a cidade.
=====================================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

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
	BOSS_HEALTH = 1500,
	BOSS_DAMAGE = 50,
	PICKUP_CHANCE = 0.25,

	LIVES = 3,
	WAVE_DELAY = 8,
	BOSS_EVERY = 5,

	CAMERA_DISTANCE = 30,
	CAMERA_MIN = 12,
	CAMERA_MAX = 90,
	MOUSE_SENSITIVITY = 0.004,

	CITY = {
		GRID = 5, -- quarteirões por lado (5x5)
		BLOCK = 110, -- tamanho do quarteirão
		ROAD = 30, -- largura da rua
		SIDEWALK_H = 0.6,
		FLOOR_H = 14, -- altura de cada andar
		WALL_T = 1, -- espessura das paredes
		SEG_W = 16, -- largura de cada pedaço de parede
		DOOR_W = 8,
		DOOR_H = 10,
		WALL_HP = 60,
		SLAB_HP = 200,
		PROP_HP = 25,
		CAR_HP = 45,
		SHOP_CHANCE = 0.5,
		TRAFFIC_CARS = 16,
		TRAFFIC_SPEED = 30,
		MAX_DEBRIS = 220,
		DEBRIS_LIFE = 7,
		COLLAPSE_RATIO = 0.35, -- desmorona ao perder 35% da estrutura...
		GROUND_COLLAPSE_RATIO = 0.55, -- ...ou 55% das paredes do térreo
		INTERIOR_LOD = 170,
		LIGHT_LOD = 110,
		DAY_LENGTH = 480, -- segundos para um dia completo
	},

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
local CITY = CONFIG.CITY

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
	gameState = "loading", -- loading | menu | playing | paused | gameover
	mode = "missao", -- missao | livre
	runId = 0,

	piloting = false,
	dead = false,
	health = CONFIG.MAX_HEALTH,
	energy = CONFIG.MAX_ENERGY,
	lives = CONFIG.LIVES,
	flying = false,
	shield = false,
	lights = true,
	turbo = false,
	firing = false,
	slamming = false,
	themeIndex = 1,
	score = 0,
	wave = 0,
	dronesKilled = 0,
	playTime = 0,
	nextWaveTimer = nil :: number?,

	rootCF = CFrame.new(0, 10, 0),
	velocity = Vector3.zero,
	onGround = false,
	yaw = 0,

	camYaw = 0,
	camPitch = -0.25,
	camDist = CONFIG.CAMERA_DISTANCE,
	shake = 0,
	menuAngle = 0,

	walkPhase = 0,
	lastStepSign = 1,
	aimPoint = Vector3.zero,
	jetBoost = 0,
	waveTime = 0,
	destructArmed = 0,
	showHelp = false,

	cooldowns = { missile = 0, scan = 0, slam = 0, laser = 0 },
}

-- Funções usadas antes de serem definidas
local notify, damageRobot, damageArea, collapseBuilding
local startGame, showMenu, resumeGame

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

local function rand(a, b)
	return a + math.random() * (b - a)
end

local function pick(list)
	return list[math.random(1, #list)]
end

local function isDown(key)
	return UserInputService:IsKeyDown(key)
end

local function theme()
	return THEMES[State.themeIndex]
end

local function torsoCenter()
	return State.rootCF.Position + Vector3.new(0, 3.5, 0)
end

local function isPlaying()
	return State.gameState == "playing"
end

---------------------------------------------------------------------------------------
-- PASTAS NO WORKSPACE
---------------------------------------------------------------------------------------
for _, name in ipairs({ "RoboTitan", "RoboTitan_Efeitos", "RoboTitan_Drones", "RoboTitan_Cidade", "RoboTitan_Escombros" }) do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local robotModel = new("Model", { Name = "RoboTitan", Parent = workspace })
local effects = new("Folder", { Name = "RoboTitan_Efeitos", Parent = workspace })
local droneFolder = new("Folder", { Name = "RoboTitan_Drones", Parent = workspace })
local cityFolder = new("Folder", { Name = "RoboTitan_Cidade", Parent = workspace })
local debrisFolder = new("Folder", { Name = "RoboTitan_Escombros", Parent = workspace })

-- rayWorld: chão, paredes, câmera (ignora robô, efeitos, drones, escombros e o personagem)
-- rayAim: mira, laser, mísseis (acerta drones e a cidade)
local rayWorld = RaycastParams.new()
rayWorld.FilterType = Enum.RaycastFilterType.Exclude
local rayAim = RaycastParams.new()
rayAim.FilterType = Enum.RaycastFilterType.Exclude

local function refreshFilters()
	local ignore = { robotModel, effects, debrisFolder }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	rayAim.FilterDescendantsInstances = ignore
	local worldIgnore = table.clone(ignore)
	table.insert(worldIgnore, droneFolder)
	rayWorld.FilterDescendantsInstances = worldIgnore
end
refreshFilters()

local cityOverlap = OverlapParams.new()
cityOverlap.FilterType = Enum.RaycastFilterType.Include
cityOverlap.FilterDescendantsInstances = { cityFolder }
cityOverlap.MaxParts = 600

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
	local holder: Instance = workspace
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
		local dist = (position - camera.CFrame.Position).Magnitude
		amount = amount * math.clamp(1 - dist / 250, 0, 1)
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

local function dust(position, size, duration)
	local p = makePart({ Size = Vector3.one, Transparency = 1, Position = position, Parent = effects })
	local emitter = new("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(150, 140, 130)),
		Size = NumberSequence.new(size * 0.5, size),
		Transparency = NumberSequence.new(0.3, 1),
		Lifetime = NumberRange.new(2, 4),
		Speed = NumberRange.new(4, 12),
		SpreadAngle = Vector2.new(180, 30),
		Rate = 25,
		Parent = p,
	})
	task.delay(duration, function()
		emitter.Enabled = false
	end)
	Debris:AddItem(p, duration + 5)
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
		CastShadow = false,
		Parent = effects,
	})
	local light = new("PointLight", { Color = color, Range = math.min(radius * 2, 60), Brightness = 5, Parent = ball })
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
		CastShadow = false,
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
-- ILUMINAÇÃO
---------------------------------------------------------------------------------------
Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 135)
Lighting.EnvironmentDiffuseScale = 0.5
Lighting.EnvironmentSpecularScale = 0.5
if not Lighting:FindFirstChildOfClass("Atmosphere") then
	new("Atmosphere", {
		Density = 0.28,
		Offset = 0.1,
		Haze = 1.2,
		Glare = 0.2,
		Color = Color3.fromRGB(200, 205, 215),
		Decay = Color3.fromRGB(110, 115, 130),
		Parent = Lighting,
	})
end
if not Lighting:FindFirstChild("RoboTitanBloom") then
	new("BloomEffect", { Name = "RoboTitanBloom", Intensity = 0.6, Size = 24, Threshold = 1.6, Parent = Lighting })
end

---------------------------------------------------------------------------------------
-- INTERFACE (HUD E MENUS)
---------------------------------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("RoboTitanHUD")
if oldGui then
	oldGui:Destroy()
end

local UI = {}
local accentStrokes = {}
local accentTexts = {}

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

local function makeButton(parent, text, position, callback)
	local button = new("TextButton", {
		Size = UDim2.fromOffset(300, 52),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(20, 24, 34),
		AutoButtonColor = true,
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		Parent = parent,
	}, { corner(10), accentStroke(2) })
	button.MouseButton1Click:Connect(callback)
	return button
end

local gui = new("ScreenGui", {
	Name = "RoboTitanHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 5,
	Parent = playerGui,
})

-- Vinheta de dano
UI.vignette = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = gui,
})

-- Container do HUD de jogo (escondido em menus)
UI.hud = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})

-- Painel principal
UI.panel = new("Frame", {
	Size = UDim2.fromOffset(310, 234),
	Position = UDim2.fromOffset(16, 56),
	BackgroundColor3 = Color3.fromRGB(10, 12, 18),
	BackgroundTransparency = 0.25,
	Parent = UI.hud,
}, { corner(10), accentStroke(2) })

UI.titleLabel = label({
	Size = UDim2.new(1, -24, 0, 26),
	Position = UDim2.fromOffset(12, 8),
	Text = "◆ " .. CONFIG.NAME,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	Parent = UI.panel,
})
table.insert(accentTexts, UI.titleLabel)

local function makeBar(y, color)
	local holder = new("Frame", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(12, y),
		BackgroundColor3 = Color3.fromRGB(25, 28, 36),
		Parent = UI.panel,
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

UI.hpFill, UI.hpText = makeBar(40, Color3.fromRGB(60, 220, 90))
UI.enFill, UI.enText = makeBar(64, Color3.fromRGB(0, 170, 255))

UI.infoLabels = {}
for i = 1, 5 do
	UI.infoLabels[i] = label({
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(12, 88 + (i - 1) * 20),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(210, 220, 235),
		Parent = UI.panel,
	})
end
UI.warningLabel = label({
	Size = UDim2.new(1, -24, 0, 18),
	Position = UDim2.fromOffset(12, 196),
	TextSize = 13,
	TextColor3 = Color3.fromRGB(255, 70, 70),
	Text = "",
	Parent = UI.panel,
})

-- Objetivo (topo)
UI.objectiveLabel = label({
	Size = UDim2.new(1, 0, 0, 28),
	Position = UDim2.fromOffset(0, 14),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	TextStrokeTransparency = 0.3,
	Text = "",
	Parent = UI.hud,
})

-- Barra de habilidades
UI.SLOTS = {
	{ id = "missile", key = "E", name = "Míssil" },
	{ id = "shield", key = "Q", name = "Escudo" },
	{ id = "scan", key = "R", name = "Scanner" },
	{ id = "slam", key = "G", name = "Impacto" },
	{ id = "fly", key = "F", name = "Voo" },
	{ id = "lights", key = "L", name = "Faróis" },
}
UI.slotUI = {}
UI.abilityBar = new("Frame", {
	Size = UDim2.fromOffset(#UI.SLOTS * 78, 70),
	Position = UDim2.new(0.5, 0, 1, -86),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Parent = UI.hud,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})
for i, slot in ipairs(UI.SLOTS) do
	local stroke = new("UIStroke", { Color = Color3.fromRGB(90, 95, 110), Thickness = 1.5 })
	local frame = new("Frame", {
		Size = UDim2.fromOffset(70, 64),
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = 0.2,
		LayoutOrder = i,
		ClipsDescendants = true,
		Parent = UI.abilityBar,
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
	UI.slotUI[slot.id] = { frame = frame, overlay = overlay, stroke = stroke }
end

-- Mira
UI.crosshair = new("Frame", {
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = UI.hud,
})
UI.crossParts = {}
for _, spec in ipairs({
	-- tamanho, posição, âncora
	{ UDim2.fromOffset(2, 10), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0) },
	{ UDim2.fromOffset(2, 10), UDim2.fromScale(0.5, 1), Vector2.new(0.5, 1) },
	{ UDim2.fromOffset(10, 2), UDim2.fromScale(0, 0.5), Vector2.new(0, 0.5) },
	{ UDim2.fromOffset(10, 2), UDim2.fromScale(1, 0.5), Vector2.new(1, 0.5) },
	{ UDim2.fromOffset(4, 4), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5) },
}) do
	table.insert(UI.crossParts, new("Frame", {
		Size = spec[1],
		Position = spec[2],
		AnchorPoint = spec[3],
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = UI.crosshair,
	}))
end

-- Radar
UI.RADAR_RANGE = 250
UI.radar = new("Frame", {
	Size = UDim2.fromOffset(170, 170),
	Position = UDim2.new(1, -186, 1, -186),
	BackgroundColor3 = Color3.fromRGB(5, 20, 15),
	BackgroundTransparency = 0.2,
	ClipsDescendants = true,
	Parent = UI.hud,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), accentStroke(2) })
for _, scale in ipairs({ 0.66, 0.33 }) do
	new("Frame", {
		Size = UDim2.fromScale(scale, scale),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = UI.radar,
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
	Parent = UI.radar,
}, { corner(2) })
label({
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.fromOffset(0, 8),
	Text = "RADAR",
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextColor3 = Color3.fromRGB(120, 255, 180),
	Parent = UI.radar,
})
UI.radarBlips = {}

-- Aviso para entrar
UI.promptLabel = label({
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 1, -130),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 20,
	TextStrokeTransparency = 0.3,
	Text = "",
	Parent = UI.hud,
})

-- Notificações
UI.notifyLabel = label({
	Size = UDim2.new(1, 0, 0, 36),
	Position = UDim2.new(0, 0, 0, 90),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 26,
	Font = Enum.Font.GothamBlack,
	Text = "",
	TextTransparency = 1,
	TextStrokeTransparency = 1,
	ZIndex = 5,
	Parent = gui,
})
UI.notifyToken = 0
function notify(text, color)
	UI.notifyToken += 1
	local token = UI.notifyToken
	UI.notifyLabel.Text = text
	UI.notifyLabel.TextColor3 = color or theme().accent
	UI.notifyLabel.TextTransparency = 0
	UI.notifyLabel.TextStrokeTransparency = 0.3
	task.delay(2.2, function()
		if token == UI.notifyToken then
			TweenService:Create(UI.notifyLabel, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- Painel de ajuda
UI.HELP_TEXT = table.concat({
	"<b>V</b>  entrar / sair  (longe = convocar robô)",
	"<b>W A S D</b>  andar    <b>Mouse</b>  mirar",
	"<b>Botão esquerdo</b>  canhão laser",
	"<b>Espaço</b>  pular / impulso / subir",
	"<b>Ctrl</b>  descer no voo    <b>Shift</b>  turbo",
	"<b>F</b>  modo voo    <b>E</b>  mísseis teleguiados",
	"<b>Q</b>  escudo    <b>R</b>  scanner",
	"<b>G</b>  impacto sísmico    <b>L</b>  faróis",
	"<b>C</b>  trocar cor    <b>K</b>  acenar",
	"<b>T</b>  drones (modo livre)    <b>N</b>  dia/noite",
	"<b>X</b> (2x)  autodestruição    <b>P</b>  pausar",
	"<b>Roda do mouse</b>  zoom    <b>H</b>  esta ajuda",
	"",
	"<i>Dica: com turbo o robô atravessa paredes.</i>",
	"<i>Destrua a base de um prédio para derrubá-lo!</i>",
}, "\n")
UI.helpPanel = new("Frame", {
	Size = UDim2.fromOffset(420, 420),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(10, 12, 18),
	BackgroundTransparency = 0.1,
	Visible = false,
	ZIndex = 10,
	Parent = gui,
}, { corner(12), accentStroke(2) })
label({
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.fromOffset(0, 8),
	Text = "CONTROLES — " .. CONFIG.NAME,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 10,
	Parent = UI.helpPanel,
})
label({
	Size = UDim2.new(1, -40, 1, -90),
	Position = UDim2.fromOffset(20, 50),
	Text = UI.HELP_TEXT,
	RichText = true,
	TextSize = 15,
	Font = Enum.Font.Gotham,
	LineHeight = 1.2,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 10,
	Parent = UI.helpPanel,
})
label({
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 1, -34),
	Text = "Aperte H para fechar",
	TextSize = 13,
	TextColor3 = Color3.fromRGB(150, 160, 180),
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 10,
	Parent = UI.helpPanel,
})

-- Tela de carregamento
UI.loadingFrame = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(6, 8, 12),
	ZIndex = 20,
	Parent = gui,
})
UI.loadingTitle = label({
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0.5, -90),
	Text = CONFIG.NAME,
	TextSize = 54,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 21,
	Parent = UI.loadingFrame,
})
table.insert(accentTexts, UI.loadingTitle)
UI.loadingStatus = label({
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 0.5, -20),
	Text = "CONSTRUINDO A CIDADE...",
	TextSize = 16,
	TextColor3 = Color3.fromRGB(170, 180, 200),
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 21,
	Parent = UI.loadingFrame,
})
UI.loadingBarBg = new("Frame", {
	Size = UDim2.fromOffset(400, 14),
	Position = UDim2.new(0.5, 0, 0.5, 20),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(25, 28, 36),
	ZIndex = 21,
	Parent = UI.loadingFrame,
}, { corner(7) })
UI.loadingBar = new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = THEMES[1].accent,
	ZIndex = 22,
	Parent = UI.loadingBarBg,
}, { corner(7) })

-- Menu principal
UI.menuFrame = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.5,
	Visible = false,
	ZIndex = 15,
	Parent = gui,
})
UI.menuTitle = label({
	Size = UDim2.new(1, 0, 0, 90),
	Position = UDim2.new(0, 0, 0.5, -250),
	Text = CONFIG.NAME,
	TextSize = 84,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextStrokeTransparency = 0.4,
	Parent = UI.menuFrame,
})
table.insert(accentTexts, UI.menuTitle)
label({
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.new(0, 0, 0.5, -160),
	Text = "CIDADE EM RUÍNAS",
	TextSize = 28,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextStrokeTransparency = 0.4,
	Parent = UI.menuFrame,
})
makeButton(UI.menuFrame, "▶  MODO MISSÃO", UDim2.new(0.5, 0, 0.5, -80), function()
	task.spawn(startGame, "missao")
end)
makeButton(UI.menuFrame, "⚡  MODO LIVRE", UDim2.new(0.5, 0, 0.5, -16), function()
	task.spawn(startGame, "livre")
end)
makeButton(UI.menuFrame, "?  CONTROLES", UDim2.new(0.5, 0, 0.5, 48), function()
	State.showHelp = not State.showHelp
end)
label({
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0.5, 120),
	Text = "MISSÃO: sobreviva às ondas de drones e derrote a Nave-Mãe (3 vidas)\nLIVRE: destrua a cidade inteira sem limites",
	TextSize = 15,
	Font = Enum.Font.GothamMedium,
	TextColor3 = Color3.fromRGB(200, 210, 225),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextStrokeTransparency = 0.5,
	Parent = UI.menuFrame,
})

-- Pausa
UI.pauseFrame = new("Frame", {
	Size = UDim2.fromOffset(360, 250),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(10, 12, 18),
	BackgroundTransparency = 0.1,
	Visible = false,
	ZIndex = 15,
	Parent = gui,
}, { corner(12), accentStroke(2) })
label({
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.fromOffset(0, 16),
	Text = "PAUSADO",
	TextSize = 34,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = UI.pauseFrame,
})
makeButton(UI.pauseFrame, "CONTINUAR", UDim2.new(0.5, 0, 0, 90), function()
	resumeGame()
end)
makeButton(UI.pauseFrame, "MENU PRINCIPAL", UDim2.new(0.5, 0, 0, 160), function()
	showMenu()
end)

-- Fim de jogo
UI.gameOverFrame = new("Frame", {
	Size = UDim2.fromOffset(420, 420),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(10, 12, 18),
	BackgroundTransparency = 0.1,
	Visible = false,
	ZIndex = 15,
	Parent = gui,
}, { corner(12), accentStroke(2) })
label({
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.fromOffset(0, 16),
	Text = "FIM DE JOGO",
	TextSize = 36,
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(255, 80, 80),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = UI.gameOverFrame,
})
UI.gameOverStats = label({
	Size = UDim2.new(1, -40, 0, 170),
	Position = UDim2.fromOffset(20, 76),
	Text = "",
	TextSize = 17,
	Font = Enum.Font.GothamMedium,
	LineHeight = 1.3,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = UI.gameOverFrame,
})
makeButton(UI.gameOverFrame, "JOGAR DE NOVO", UDim2.new(0.5, 0, 0, 270), function()
	task.spawn(startGame, State.mode)
end)
makeButton(UI.gameOverFrame, "MENU PRINCIPAL", UDim2.new(0.5, 0, 0, 338), function()
	showMenu()
end)

local function flashDamage(amount)
	UI.vignette.BackgroundTransparency = math.clamp(1 - amount, 0.55, 0.95)
	TweenService:Create(UI.vignette, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
end

local function flashHitmarker()
	for _, f in ipairs(UI.crossParts) do
		f.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	end
	task.delay(0.08, function()
		for _, f in ipairs(UI.crossParts) do
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
for _, j in ipairs({ "legL", "legR" }) do
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
	for _, l in ipairs(accentTexts) do
		l.TextColor3 = t.accent
	end
	UI.loadingBar.BackgroundColor3 = t.accent
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
-- CIDADE: dados
-- Cada coisa destrutível é uma "unidade" (parede, laje, poste, carro...) formada
-- por uma ou mais peças. City.partInfo liga cada peça à sua unidade.
---------------------------------------------------------------------------------------
local City = {
	generation = 0,
	partInfo = {},
	buildings = {},
	interiors = {},
	streetlights = {},
	traffic = {},
	debris = {},
	collapsing = {},
	windows = {},
	roadCenters = {},
	half = 0,
	totalMass = 0,
	lostMass = 0,
	buildingsDestroyed = 0,
	dirty = false,
	isNight = false,
	generating = false,
}

local groundFolder, buildingsFolder, propsFolder, interiorsFolder, trafficFolder

local BUILDING_STYLES = {
	{ wall = Color3.fromRGB(190, 185, 175), trim = Color3.fromRGB(120, 118, 112), glass = Color3.fromRGB(110, 150, 190), material = Enum.Material.Concrete },
	{ wall = Color3.fromRGB(150, 80, 60), trim = Color3.fromRGB(90, 85, 80), glass = Color3.fromRGB(90, 120, 150), material = Enum.Material.Brick },
	{ wall = Color3.fromRGB(70, 80, 95), trim = Color3.fromRGB(45, 50, 60), glass = Color3.fromRGB(80, 170, 220), material = Enum.Material.Metal },
	{ wall = Color3.fromRGB(225, 220, 205), trim = Color3.fromRGB(160, 150, 130), glass = Color3.fromRGB(120, 140, 160), material = Enum.Material.SmoothPlastic },
	{ wall = Color3.fromRGB(120, 125, 130), trim = Color3.fromRGB(80, 82, 88), glass = Color3.fromRGB(60, 200, 190), material = Enum.Material.Concrete },
	{ wall = Color3.fromRGB(200, 170, 120), trim = Color3.fromRGB(130, 110, 80), glass = Color3.fromRGB(100, 130, 170), material = Enum.Material.Sandstone },
}

local CAR_COLORS = {
	Color3.fromRGB(200, 30, 30),
	Color3.fromRGB(30, 80, 200),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(25, 25, 28),
	Color3.fromRGB(240, 190, 20),
	Color3.fromRGB(40, 150, 70),
	Color3.fromRGB(150, 150, 160),
}

local AXES = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
local WINDOW_NIGHT = Color3.fromRGB(255, 215, 140)

-- Contador para gerar a cidade em etapas (evita travar o jogo)
local genCounter = 0
local function cityPart(parent, size, cf, color, material, extra)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanTouch = false
	p.CanCollide = true
	p.CanQuery = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	p.Parent = parent
	-- Só pausa durante a geração da cidade (nunca dentro do loop do jogo)
	if City.generating then
		genCounter += 1
		if genCounter % 400 == 0 then
			task.wait()
		end
	end
	return p
end

local function newUnit(kind, hp, mass, building)
	return { kind = kind, hp = hp, maxHp = hp, mass = mass, parts = {}, building = building, broken = false }
end

local function addToUnit(unit, part)
	table.insert(unit.parts, part)
	City.partInfo[part] = unit
	return part
end

---------------------------------------------------------------------------------------
-- CIDADE: destruição
---------------------------------------------------------------------------------------
local function spawnDebris(part, impactPos)
	if part.Transparency >= 1 then
		return
	end
	local size = part.Size
	local volume = size.X * size.Y * size.Z
	local count = math.clamp(math.floor(volume / 60), 1, 4)
	for _ = 1, count do
		if #City.debris >= CITY.MAX_DEBRIS then
			local oldest = table.remove(City.debris, 1)
			if oldest and oldest.part.Parent then
				oldest.part:Destroy()
			end
		end
		local chunkSize = Vector3.new(
			math.clamp(size.X * rand(0.3, 0.6), 0.6, 6),
			math.clamp(size.Y * rand(0.3, 0.6), 0.6, 6),
			math.clamp(size.Z * rand(0.3, 0.6), 0.6, 6)
		)
		local offset = Vector3.new(rand(-0.4, 0.4) * size.X, rand(-0.4, 0.4) * size.Y, rand(-0.4, 0.4) * size.Z)
		local cf = part.CFrame * CFrame.new(offset)
		local chunk = makePart({
			Size = chunkSize,
			CFrame = cf * CFrame.Angles(rand(0, 3), rand(0, 3), rand(0, 3)),
			Color = part.Color,
			Material = part.Material,
			Transparency = part.Transparency,
			Anchored = false,
			CanCollide = true,
			CastShadow = false,
			Parent = debrisFolder,
		})
		local dir = cf.Position - impactPos
		dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
		chunk.AssemblyLinearVelocity = dir * rand(15, 45) + Vector3.new(0, rand(10, 30), 0)
		chunk.AssemblyAngularVelocity = Vector3.new(rand(-6, 6), rand(-6, 6), rand(-6, 6))
		table.insert(City.debris, { part = chunk, time = os.clock() })
	end
end

local function breakUnit(unit, impactPos)
	if unit.broken then
		return
	end
	unit.broken = true
	City.dirty = true
	local origin = unit.parts[1] and unit.parts[1].Position or impactPos
	for _, p in ipairs(unit.parts) do
		City.partInfo[p] = nil
		if p.Parent then
			spawnDebris(p, impactPos)
			p:Destroy()
		end
	end
	if isPlaying() then
		State.score += 5
	end
	local b = unit.building
	if b and not b.collapsed and unit.mass > 0 then
		b.lostMass += unit.mass
		City.lostMass += unit.mass
		if unit.ground then
			b.groundLost += 1
		end
		if b.lostMass / b.totalMass >= CITY.COLLAPSE_RATIO
			or (b.groundTotal > 0 and b.groundLost / b.groundTotal >= CITY.GROUND_COLLAPSE_RATIO)
		then
			collapseBuilding(b)
		end
	end
	if unit.onBreak then
		unit.onBreak(unit, origin)
	end
end

local function damageUnit(unit, amount, position)
	if unit.broken then
		return
	end
	unit.hp -= amount
	if unit.glass and unit.hp < unit.maxHp * 0.75 then
		local glass = unit.glass
		unit.glass = nil
		City.partInfo[glass] = nil
		if glass.Parent then
			spark(glass.Position, Color3.fromRGB(200, 230, 255), 12, 20)
			glass:Destroy()
		end
	end
	if unit.hp <= 0 then
		breakUnit(unit, position)
	end
end

local function damageCity(position, radius, amount)
	local parts = workspace:GetPartBoundsInRadius(position, radius, cityOverlap)
	local hits = {}
	for _, part in ipairs(parts) do
		local unit = City.partInfo[part]
		if unit and not hits[unit] then
			local dist = (part.Position - position).Magnitude
			hits[unit] = math.max(0.35, 1 - dist / (radius * 1.5))
		end
	end
	for unit, falloff in pairs(hits) do
		damageUnit(unit, amount * falloff, position)
	end
end

local function spawnRubble(b)
	local color = b.style.wall:Lerp(Color3.fromRGB(80, 80, 80), 0.4)
	for _ = 1, 10 do
		local s = Vector3.new(rand(6, 14), rand(3, 7), rand(6, 14))
		local cf = b.cf * CFrame.new(rand(-0.4, 0.4) * b.w, s.Y * 0.3, rand(-0.4, 0.4) * b.d)
			* CFrame.Angles(rand(-0.3, 0.3), rand(0, 3), rand(-0.3, 0.3))
		cityPart(groundFolder, s, cf, color, b.style.material)
	end
end

function collapseBuilding(b)
	if b.collapsed then
		return
	end
	b.collapsed = true
	City.lostMass += (b.totalMass - b.lostMass)
	City.buildingsDestroyed += 1
	for _, u in ipairs(b.units) do
		u.broken = true
		for _, p in ipairs(u.parts) do
			City.partInfo[p] = nil
		end
	end
	if b.interior then
		b.interior.dead = true
		b.interior.folder:Destroy()
	end
	local base = b.cf.Position
	for _, corner in ipairs({ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }) do
		dust(base + Vector3.new(corner.X * b.w / 2, 2, corner.Z * b.d / 2), 18, 3)
	end
	dust(base + Vector3.new(0, b.height * 0.5, 0), 25, 2)
	playSound(CONFIG.SOUNDS.explosion, 1, 0.3, base)
	addShake(2.5, base)
	if isPlaying() then
		State.score += 500
		notify("PRÉDIO DESMORONOU!  +500", Color3.fromRGB(255, 190, 60))
	end
	table.insert(City.collapsing, {
		b = b,
		t = 0,
		dur = 2.5 + b.height / 70,
		tiltX = rand(-0.25, 0.25),
		tiltZ = rand(-0.25, 0.25),
	})
end

local function carExplode(unit, origin)
	if unit.model then
		unit.model:Destroy()
	end
	if unit.traffic then
		unit.traffic.dead = true
	end
	explosion(origin, 12, Color3.fromRGB(255, 120, 30))
	local wreck = makePart({
		Size = Vector3.new(5, 1.5, 9),
		CFrame = CFrame.new(origin),
		Color = Color3.fromRGB(30, 28, 26),
		Material = Enum.Material.CorrodedMetal,
		CanCollide = true,
		Parent = effects,
	})
	new("Fire", { Size = 6, Heat = 8, Parent = wreck })
	Debris:AddItem(wreck, 10)
	if isPlaying() then
		State.score += 50
	end
	-- reação em cadeia (no próximo quadro, para não aninhar demais)
	task.defer(function()
		damageCity(origin, 14, 80)
		damageArea(origin, 16, 80)
		if not State.dead and (origin - torsoCenter()).Magnitude < 14 then
			damageRobot(25, origin)
		end
	end)
end

---------------------------------------------------------------------------------------
-- CIDADE: objetos
---------------------------------------------------------------------------------------
local function makeCar(cf, color, parent)
	local model = new("Model", { Name = "Carro", Parent = parent })
	local unit = newUnit("car", CITY.CAR_HP, 0)
	unit.model = model
	local function cp(size, localCF, col, material, shape)
		return addToUnit(unit, cityPart(model, size, cf * localCF, col, material, {
			Shape = shape or Enum.PartType.Block,
			CastShadow = false,
		}))
	end
	cp(Vector3.new(5, 1.6, 10), CFrame.new(0, 1.7, 0), color, Enum.Material.SmoothPlastic)
	cp(Vector3.new(4.6, 1.5, 5), CFrame.new(0, 3.2, 0.5), Color3.fromRGB(30, 40, 55), Enum.Material.Glass)
	for _, x in ipairs({ -2.4, 2.4 }) do
		for _, z in ipairs({ -3.2, 3.2 }) do
			cp(Vector3.new(1, 1.8, 1.8), CFrame.new(x, 0.9, z), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, CYL)
		end
	end
	cp(Vector3.new(4, 0.5, 0.2), CFrame.new(0, 1.9, -5.05), Color3.fromRGB(255, 250, 220), Enum.Material.Neon)
	cp(Vector3.new(4, 0.5, 0.2), CFrame.new(0, 1.9, 5.05), Color3.fromRGB(255, 30, 30), Enum.Material.Neon)
	model.WorldPivot = cf
	unit.onBreak = carExplode
	return model, unit
end

local function makeStreetlight(pos, armDir)
	local unit = newUnit("prop", CITY.PROP_HP, 0)
	local metal = Color3.fromRGB(60, 60, 65)
	addToUnit(unit, cityPart(propsFolder, Vector3.new(0.6, 14, 0.6), CFrame.new(pos + Vector3.new(0, 7, 0)), metal, Enum.Material.Metal, { CastShadow = false }))
	local top = pos + Vector3.new(0, 13.8, 0)
	local armCF = CFrame.lookAt(top, top + armDir) * CFrame.new(0, 0, -2)
	addToUnit(unit, cityPart(propsFolder, Vector3.new(0.4, 0.4, 4), armCF, metal, Enum.Material.Metal, { CastShadow = false }))
	local bulb = addToUnit(unit, cityPart(propsFolder, Vector3.new(1.6, 0.5, 1.6), armCF * CFrame.new(0, -0.4, -1.8), Color3.fromRGB(200, 200, 190), Enum.Material.Glass, { CastShadow = false }))
	local light = new("PointLight", { Range = 40, Brightness = 1.6, Color = Color3.fromRGB(255, 210, 150), Enabled = false, Parent = bulb })
	table.insert(City.streetlights, { bulb = bulb, light = light, pos = bulb.Position })
end

local function makeTree(pos)
	local unit = newUnit("prop", CITY.PROP_HP, 0)
	local h = rand(5, 8)
	addToUnit(unit, cityPart(propsFolder, Vector3.new(1.2, h, 1.2), CFrame.new(pos + Vector3.new(0, h / 2, 0)), Color3.fromRGB(100, 70, 45), Enum.Material.Wood))
	local s1 = rand(6, 8)
	addToUnit(unit, cityPart(propsFolder, Vector3.one * s1, CFrame.new(pos + Vector3.new(0, h + 1.5, 0)), Color3.fromRGB(60, 140, 60), Enum.Material.Grass, { Shape = BALL }))
	local s2 = rand(4, 5)
	addToUnit(unit, cityPart(propsFolder, Vector3.one * s2, CFrame.new(pos + Vector3.new(rand(-1.5, 1.5), h + 4, rand(-1.5, 1.5))), Color3.fromRGB(80, 160, 70), Enum.Material.Grass, { Shape = BALL }))
end

local function makeBench(cf)
	local unit = newUnit("prop", CITY.PROP_HP, 0)
	local wood = Color3.fromRGB(140, 100, 60)
	addToUnit(unit, cityPart(propsFolder, Vector3.new(5, 0.4, 1.6), cf * CFrame.new(0, 1.6, 0), wood, Enum.Material.Wood))
	addToUnit(unit, cityPart(propsFolder, Vector3.new(5, 1.6, 0.3), cf * CFrame.new(0, 2.6, 0.75), wood, Enum.Material.Wood))
	for _, x in ipairs({ -2, 2 }) do
		addToUnit(unit, cityPart(propsFolder, Vector3.new(0.4, 1.4, 1.4), cf * CFrame.new(x, 0.7, 0), Color3.fromRGB(50, 50, 55), Enum.Material.Metal))
	end
end

---------------------------------------------------------------------------------------
-- CIDADE: lojas com interior
-- p(tamanho, x, yDaBase, z, cor, material, extras) cria um móvel dentro da loja.
-- Coordenadas locais: porta em -Z (frente), fundo em +Z.
---------------------------------------------------------------------------------------
local BOX_COLORS = {
	Color3.fromRGB(230, 70, 60),
	Color3.fromRGB(60, 150, 230),
	Color3.fromRGB(250, 200, 50),
	Color3.fromRGB(90, 200, 90),
	Color3.fromRGB(240, 130, 40),
	Color3.fromRGB(180, 90, 200),
}
local WOOD = Color3.fromRGB(140, 100, 60)
local DARK_METAL = Color3.fromRGB(60, 60, 66)
local FH = CITY.FLOOR_H

local SHOPS = {
	{
		name = "MERCADO",
		color = Color3.fromRGB(90, 220, 100),
		floor = Color3.fromRGB(220, 220, 215),
		build = function(p, iw, id)
			for i = -1, 1 do
				local x = i * math.min(9, iw / 4)
				p(Vector3.new(2, 6, id * 0.45), x, 0.2, 2, Color3.fromRGB(150, 150, 155), Enum.Material.Metal)
				for level = 1, 3 do
					p(Vector3.new(2.8, 1, id * 0.43), x, level * 1.8, 2, pick(BOX_COLORS), Enum.Material.SmoothPlastic)
				end
			end
			p(Vector3.new(6, 3.5, 2), iw / 2 - 5, 0.2, -id / 2 + 5, WOOD, Enum.Material.Wood)
			p(Vector3.new(1.5, 1.2, 1), iw / 2 - 5, 3.7, -id / 2 + 5, Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
		end,
	},
	{
		name = "PIZZARIA",
		color = Color3.fromRGB(255, 120, 40),
		floor = Color3.fromRGB(160, 50, 40),
		build = function(p, iw, id)
			for _, x in ipairs({ -iw / 4, iw / 4 }) do
				for _, z in ipairs({ -id / 6, id / 6 }) do
					p(Vector3.new(4, 0.4, 4), x, 3, z, Color3.fromRGB(230, 230, 225), Enum.Material.Fabric)
					p(Vector3.new(0.6, 3, 0.6), x, 0.2, z, DARK_METAL, Enum.Material.Metal)
					p(Vector3.new(1.8, 2, 1.8), x - 3, 0.2, z, WOOD, Enum.Material.Wood)
					p(Vector3.new(1.8, 2, 1.8), x + 3, 0.2, z, WOOD, Enum.Material.Wood)
				end
			end
			p(Vector3.new(7, 6, 3), 0, 0.2, id / 2 - 2.5, Color3.fromRGB(150, 70, 50), Enum.Material.Brick)
			p(Vector3.new(3, 1.5, 0.3), 0, 2, id / 2 - 4.1, Color3.fromRGB(255, 120, 30), Enum.Material.Neon)
		end,
	},
	{
		name = "CAFÉ",
		color = Color3.fromRGB(230, 180, 120),
		floor = Color3.fromRGB(120, 85, 60),
		build = function(p, iw, id)
			p(Vector3.new(iw * 0.6, 3.5, 2), 0, 0.2, id / 2 - 4, WOOD, Enum.Material.Wood)
			p(Vector3.new(2, 2, 1.5), iw * 0.15, 3.7, id / 2 - 4, Color3.fromRGB(180, 180, 185), Enum.Material.Metal)
			for _, x in ipairs({ -iw / 5, iw / 5 }) do
				p(Vector3.new(3, 0.3, 3), x, 3, -id / 8, WOOD, Enum.Material.Wood)
				p(Vector3.new(0.5, 3, 0.5), x, 0.2, -id / 8, DARK_METAL, Enum.Material.Metal)
			end
			p(Vector3.new(2.5, 2.5, id * 0.5), -iw / 2 + 1.5, 0.2, 0, Color3.fromRGB(110, 60, 40), Enum.Material.Fabric)
			p(Vector3.new(1, 4, id * 0.5), -iw / 2 + 0.6, 0.2, 0, Color3.fromRGB(110, 60, 40), Enum.Material.Fabric)
		end,
	},
	{
		name = "BANCO",
		color = Color3.fromRGB(255, 215, 80),
		floor = Color3.fromRGB(235, 235, 240),
		build = function(p, iw, id)
			p(Vector3.new(iw - 6, 4, 1.6), 0, 0.2, id * 0.1, Color3.fromRGB(90, 60, 45), Enum.Material.Wood)
			p(Vector3.new(iw - 6, 4, 0.2), 0, 4.2, id * 0.1, Color3.fromRGB(180, 220, 240), Enum.Material.Glass, { Transparency = 0.6 })
			p(Vector3.new(8, 8, 1), 0, 0.2, id / 2 - 1.2, Color3.fromRGB(120, 125, 130), Enum.Material.DiamondPlate)
			p(Vector3.new(2, 2, 0.3), 0, 3.2, id / 2 - 1.85, Color3.fromRGB(255, 200, 60), Enum.Material.Neon)
			for i = -1, 1 do
				p(Vector3.new(1.5, 0.8, 0.8), i * 2, 0.2, id / 2 - 4, Color3.fromRGB(255, 200, 40), Enum.Material.Foil)
			end
			p(Vector3.new(4, 0.1, id * 0.4), 0, 0.2, -id / 4, Color3.fromRGB(150, 20, 30), Enum.Material.Fabric)
		end,
	},
	{
		name = "FLIPERAMA",
		color = Color3.fromRGB(255, 60, 220),
		floor = Color3.fromRGB(35, 20, 50),
		build = function(p, iw, id)
			for _, side in ipairs({ -1, 1 }) do
				for k = 0, 2 do
					local z = -id / 4 + k * id / 4
					p(Vector3.new(2.5, 6, 3), side * (iw / 2 - 2), 0.2, z, Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic)
					p(Vector3.new(0.2, 2, 2.2), side * (iw / 2 - 3.3), 3.2, z, pick(BOX_COLORS), Enum.Material.Neon)
				end
			end
			p(Vector3.new(6, 0.3, 6), 0, 0.2, 0, Color3.fromRGB(60, 200, 255), Enum.Material.Neon)
		end,
	},
}

local function buildInterior(b, shop)
	local folder = new("Folder", { Name = "Interior_" .. shop.name })
	local iw, id = b.w - 2 * CITY.WALL_T, b.d - 2 * CITY.WALL_T
	local function p(size, x, bottomY, z, color, material, extra)
		local part = cityPart(folder, size, b.cf * CFrame.new(x, bottomY + size.Y / 2, z), color, material, extra)
		part.CastShadow = false
		local unit = newUnit("prop", CITY.PROP_HP, 0, b)
		table.insert(b.units, unit)
		return addToUnit(unit, part)
	end
	p(Vector3.new(iw, 0.2, id), 0, 0, 0, shop.floor, Enum.Material.Marble)
	for _, z in ipairs({ -id / 4, id / 4 }) do
		local lamp = p(Vector3.new(6, 0.3, 2), 0, FH - 1.5, z, Color3.fromRGB(255, 250, 235), Enum.Material.Neon)
		new("PointLight", { Range = 26, Brightness = 1.3, Color = Color3.fromRGB(255, 235, 200), Parent = lamp })
	end
	shop.build(p, iw, id)
	local interior = { folder = folder, pos = (b.cf * CFrame.new(0, 5, 0)).Position, loaded = false, dead = false }
	b.interior = interior
	table.insert(City.interiors, interior)
end

---------------------------------------------------------------------------------------
-- CIDADE: prédios
-- Paredes divididas em pedaços por andar (cada pedaço = parede + janela) e uma laje
-- por andar. O prédio inteiro é um Model para poder desmoronar com PivotTo.
---------------------------------------------------------------------------------------
local function buildBuilding(center, w, d, floors, frontDir, style, shop)
	local model = new("Model", { Name = "Predio", Parent = buildingsFolder })
	local bcf = CFrame.lookAt(center, center + frontDir)
	model.WorldPivot = bcf
	local b = {
		model = model,
		cf = bcf,
		w = w,
		d = d,
		height = floors * FH,
		style = style,
		units = {},
		totalMass = 0,
		lostMass = 0,
		groundTotal = 0,
		groundLost = 0,
		collapsed = false,
	}
	local T = CITY.WALL_T

	local function part(size, localCF, color, material, extra)
		return cityPart(model, size, bcf * localCF, color, material, extra)
	end
	local function unit(kind, hp, mass, isGround)
		local u = newUnit(kind, hp, mass, b)
		u.ground = isGround
		table.insert(b.units, u)
		b.totalMass += mass
		if isGround then
			b.groundTotal += 1
		end
		return u
	end

	local sides = {
		{ center = Vector3.new(0, 0, -d / 2), tangent = Vector3.xAxis, length = w, normal = -Vector3.zAxis, front = true },
		{ center = Vector3.new(0, 0, d / 2), tangent = Vector3.xAxis, length = w, normal = Vector3.zAxis },
		{ center = Vector3.new(-w / 2, 0, 0), tangent = Vector3.zAxis, length = d, normal = -Vector3.xAxis },
		{ center = Vector3.new(w / 2, 0, 0), tangent = Vector3.zAxis, length = d, normal = Vector3.xAxis },
	}

	for f = 0, floors - 1 do
		local y0 = f * FH
		local isGround = f == 0
		for _, side in ipairs(sides) do
			local n = math.max(1, math.floor(side.length / CITY.SEG_W + 0.5))
			local segLen = side.length / n
			local doorIndex = math.ceil(n / 2)
			local rot = CFrame.fromMatrix(Vector3.zero, side.tangent, Vector3.yAxis)
			for s = 1, n do
				local along = -side.length / 2 + segLen * (s - 0.5)
				local basePos = side.center + side.tangent * along
				local u = unit("wall", CITY.WALL_HP * (isGround and 1.5 or 1), 1, isGround)
				if isGround and shop and side.front and s == doorIndex then
					-- Porta da loja: viga em cima + colunas dos lados
					local headerH = FH - CITY.DOOR_H
					addToUnit(u, part(Vector3.new(segLen, headerH, T), CFrame.new(basePos + Vector3.new(0, CITY.DOOR_H + headerH / 2, 0)) * rot, style.wall, style.material))
					local pillarW = (segLen - CITY.DOOR_W) / 2
					if pillarW > 0.3 then
						for _, sgn in ipairs({ -1, 1 }) do
							local pillarPos = side.center + side.tangent * (along + sgn * (CITY.DOOR_W / 2 + pillarW / 2)) + Vector3.new(0, CITY.DOOR_H / 2, 0)
							addToUnit(u, part(Vector3.new(pillarW, CITY.DOOR_H, T), CFrame.new(pillarPos) * rot, style.wall, style.material))
						end
					end
				else
					addToUnit(u, part(Vector3.new(segLen, FH, T), CFrame.new(basePos + Vector3.new(0, y0 + FH / 2, 0)) * rot, style.wall, style.material))
					local shopFront = isGround and shop and side.front
					local gh = shopFront and FH * 0.55 or FH * 0.45
					local gy = y0 + (shopFront and FH * 0.4 or FH * 0.55)
					local gpos = basePos + side.normal * (T / 2 + 0.1) + Vector3.new(0, gy, 0)
					local glass = addToUnit(u, part(Vector3.new(segLen * 0.75, gh, 0.2), CFrame.new(gpos) * rot, style.glass, Enum.Material.Glass, {
						Transparency = 0.35,
						CastShadow = false,
					}))
					u.glass = glass
					table.insert(City.windows, { part = glass, color = style.glass })
				end
			end
		end
		-- Laje (teto deste andar / chão do próximo)
		local slab = unit("slab", CITY.SLAB_HP, 3, false)
		addToUnit(slab, part(Vector3.new(w + 0.4, 1, d + 0.4), CFrame.new(0, y0 + FH - 0.5, 0), style.trim, Enum.Material.Concrete))
	end

	-- Detalhes do telhado
	local roofY = floors * FH
	if math.random() < 0.7 then
		local ac = unit("prop", CITY.PROP_HP, 0, false)
		addToUnit(ac, part(Vector3.new(6, 3, 5), CFrame.new(rand(-w / 4, w / 4), roofY + 1.5, rand(-d / 4, d / 4)), Color3.fromRGB(170, 170, 175), Enum.Material.Metal))
	end
	if floors >= 8 then
		local antenna = unit("prop", CITY.PROP_HP, 0, false)
		addToUnit(antenna, part(Vector3.new(0.6, 14, 0.6), CFrame.new(0, roofY + 7, 0), DARK_METAL, Enum.Material.Metal, { CastShadow = false }))
		addToUnit(antenna, part(Vector3.one * 1.2, CFrame.new(0, roofY + 14.5, 0), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, { Shape = BALL, CastShadow = false }))
	end

	-- Loja: letreiro + interior
	if shop then
		local sign = unit("prop", CITY.PROP_HP, 0, false)
		local signPart = addToUnit(sign, part(Vector3.new(math.min(18, w * 0.6), 3, 0.5), CFrame.new(0, CITY.DOOR_H + 2, -d / 2 - T / 2 - 0.3), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic))
		local surface = new("SurfaceGui", { Face = Enum.NormalId.Front, LightInfluence = 0, PixelsPerStud = 30, Parent = signPart })
		new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = shop.name,
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
			TextColor3 = shop.color,
			Parent = surface,
		})
		buildInterior(b, shop)
	end

	City.totalMass += b.totalMass
	table.insert(City.buildings, b)
	return b
end

---------------------------------------------------------------------------------------
-- CIDADE: quarteirões
---------------------------------------------------------------------------------------
local function buildPlaza(base)
	local B = CITY.BLOCK
	cityPart(groundFolder, Vector3.new(B - 8, 0.1, B - 8), CFrame.new(base + Vector3.new(0, 0.05, 0)), Color3.fromRGB(170, 120, 100), Enum.Material.Brick)
	-- Fonte
	local f = base + Vector3.new(0, 0, -25)
	cityPart(groundFolder, Vector3.new(2, 22, 22), CFrame.new(f + Vector3.new(0, 1, 0)) * AXIS_Y, Color3.fromRGB(200, 200, 195), Enum.Material.Concrete, { Shape = CYL })
	cityPart(groundFolder, Vector3.new(0.3, 20, 20), CFrame.new(f + Vector3.new(0, 1.8, 0)) * AXIS_Y, Color3.fromRGB(60, 140, 220), Enum.Material.Glass, { Shape = CYL, Transparency = 0.3, CanCollide = false })
	cityPart(groundFolder, Vector3.new(7, 2.5, 2.5), CFrame.new(f + Vector3.new(0, 3.5, 0)) * AXIS_Y, Color3.fromRGB(200, 200, 195), Enum.Material.Concrete, { Shape = CYL })
	local top = cityPart(groundFolder, Vector3.one * 2.5, CFrame.new(f + Vector3.new(0, 7.5, 0)), THEMES[1].accent, Enum.Material.Neon, { Shape = BALL })
	new("PointLight", { Range = 20, Brightness = 2, Color = THEMES[1].accent, Parent = top })
	-- Árvores e bancos
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		makeTree(base + Vector3.new(math.cos(a) * 42, 0, math.sin(a) * 42))
	end
	for _, x in ipairs({ -18, 18 }) do
		makeBench(CFrame.new(base + Vector3.new(x, 0, -25)) * CFrame.Angles(0, math.rad(90) * (x > 0 and 1 or -1), 0))
	end
end

local function buildPark(base)
	local B = CITY.BLOCK
	cityPart(groundFolder, Vector3.new(B - 6, 0.1, B - 6), CFrame.new(base + Vector3.new(0, 0.05, 0)), Color3.fromRGB(80, 150, 70), Enum.Material.Grass)
	cityPart(groundFolder, Vector3.new(0.3, 18, 18), CFrame.new(base + Vector3.new(15, 0.15, 10)) * AXIS_Y, Color3.fromRGB(60, 130, 200), Enum.Material.Glass, { Shape = CYL, Transparency = 0.2 })
	for _ = 1, 9 do
		makeTree(base + Vector3.new(rand(-B / 2 + 10, B / 2 - 10), 0, rand(-B / 2 + 10, B / 2 - 10)))
	end
	makeBench(CFrame.new(base + Vector3.new(-15, 0, -20)))
	makeBench(CFrame.new(base + Vector3.new(-15, 0, 20)) * CFrame.Angles(0, math.pi, 0))
end

local function buildParking(base)
	local B = CITY.BLOCK
	cityPart(groundFolder, Vector3.new(B - 6, 0.1, B - 6), CFrame.new(base + Vector3.new(0, 0.05, 0)), Color3.fromRGB(55, 55, 60), Enum.Material.Asphalt)
	for k = -3, 3 do
		for _, z in ipairs({ -15, 15 }) do
			cityPart(groundFolder, Vector3.new(0.4, 0.05, 12), CFrame.new(base + Vector3.new(k * 8 - 4, 0.12, z)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { CanQuery = false })
		end
	end
	for k = -3, 2 do
		for _, z in ipairs({ -15, 15 }) do
			if math.random() < 0.7 then
				local pos = base + Vector3.new(k * 8, 0, z)
				makeCar(CFrame.lookAt(pos, pos + Vector3.new(0, 0, z > 0 and -1 or 1)), pick(CAR_COLORS), propsFolder)
			end
		end
	end
end

local function buildLots(center, base)
	local downtown = math.clamp(1 - Vector3.new(center.X, 0, center.Z).Magnitude / 420, 0, 1)
	if math.random() < 0.15 + downtown * 0.35 then
		-- Arranha-céu ocupando o quarteirão todo
		local floors = math.floor(rand(7, 10) + downtown * 6)
		buildBuilding(base, rand(56, 72), rand(56, 72), floors, pick(AXES), pick(BUILDING_STYLES), math.random() < 0.6 and pick(SHOPS) or nil)
		return
	end
	for _, ox in ipairs({ -1, 1 }) do
		for _, oz in ipairs({ -1, 1 }) do
			local lot = base + Vector3.new(ox * 27, 0, oz * 27)
			if math.random() < 0.88 then
				local floors = math.floor(rand(2, 4.99) + downtown * rand(0, 7))
				local front = math.random() < 0.5 and Vector3.new(ox, 0, 0) or Vector3.new(0, 0, oz)
				local shop = math.random() < CITY.SHOP_CHANCE and pick(SHOPS) or nil
				buildBuilding(lot, rand(26, 38), rand(26, 38), floors, front, pick(BUILDING_STYLES), shop)
			else
				makeTree(lot)
			end
		end
	end
end

local function buildBlock(center, isPlaza)
	local B = CITY.BLOCK
	local top = 0.2 + CITY.SIDEWALK_H
	cityPart(groundFolder, Vector3.new(B, CITY.SIDEWALK_H, B), CFrame.new(center + Vector3.new(0, 0.2 + CITY.SIDEWALK_H / 2, 0)), Color3.fromRGB(175, 175, 170), Enum.Material.Concrete)
	local base = center + Vector3.new(0, top, 0)

	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			makeStreetlight(base + Vector3.new(sx * (B / 2 - 2), 0, sz * (B / 2 - 2)), Vector3.new(sx, 0, 0))
		end
	end

	-- Carros estacionados na beira da rua
	for _, normal in ipairs(AXES) do
		if math.random() < 0.5 then
			local tangent = Vector3.new(normal.Z, 0, normal.X)
			local pos = center + normal * (B / 2 + 3) + tangent * rand(-35, 35) + Vector3.new(0, 0.2, 0)
			makeCar(CFrame.lookAt(pos, pos + tangent), pick(CAR_COLORS), propsFolder)
		end
	end

	if isPlaza then
		buildPlaza(base)
		return
	end
	local r = math.random()
	if r < 0.1 then
		buildPark(base)
	elseif r < 0.18 then
		buildParking(base)
	else
		buildLots(center, base)
	end
end

---------------------------------------------------------------------------------------
-- CIDADE: trânsito
---------------------------------------------------------------------------------------
local function spawnTrafficCar()
	if #City.roadCenters == 0 then
		return
	end
	local alongX = math.random() < 0.5
	local dir = math.random() < 0.5 and 1 or -1
	local rc = pick(City.roadCenters)
	local lane = rc + (alongX and dir or -dir) * 6.5
	local t = rand(-City.half, City.half)
	local pos = alongX and Vector3.new(t, 0.2, lane) or Vector3.new(lane, 0.2, t)
	local heading = alongX and Vector3.new(dir, 0, 0) or Vector3.new(0, 0, dir)
	local model, unit = makeCar(CFrame.lookAt(pos, pos + heading), pick(CAR_COLORS), trafficFolder)
	local car = { model = model, unit = unit, pos = pos, heading = heading, alongX = alongX, dir = dir, speed = CITY.TRAFFIC_SPEED, dead = false }
	unit.traffic = car
	table.insert(City.traffic, car)
end

local function updateTraffic(dt)
	local robotPos = State.rootCF.Position
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local charPos = hrp and (hrp :: BasePart).Position

	local function isAhead(car, target, maxAhead, maxSide)
		local rel = target - car.pos
		rel = Vector3.new(rel.X, 0, rel.Z)
		local ahead = rel:Dot(car.heading)
		if ahead <= 0 or ahead > maxAhead then
			return false
		end
		return (rel - car.heading * ahead).Magnitude < maxSide
	end

	for i = #City.traffic, 1, -1 do
		local car = City.traffic[i]
		if car.dead or not car.model.Parent then
			table.remove(City.traffic, i)
			local gen = City.generation
			task.delay(10, function()
				if City.generation == gen then
					spawnTrafficCar()
				end
			end)
		else
			local blocked = isAhead(car, robotPos, 24, 8) or (charPos ~= nil and isAhead(car, charPos, 16, 5))
			if not blocked then
				for _, other in ipairs(City.traffic) do
					if other ~= car and not other.dead and isAhead(car, other.pos, 14, 3) then
						blocked = true
						break
					end
				end
			end
			local target = blocked and 0 or CITY.TRAFFIC_SPEED
			car.speed += (target - car.speed) * math.min(1, dt * (blocked and 6 or 1.5))
			car.pos += car.heading * car.speed * dt
			local coord = car.alongX and car.pos.X or car.pos.Z
			if coord * car.dir > City.half then
				local reset = -City.half * car.dir
				car.pos = car.alongX and Vector3.new(reset, car.pos.Y, car.pos.Z) or Vector3.new(car.pos.X, car.pos.Y, reset)
			end
			car.model:PivotTo(CFrame.lookAt(car.pos, car.pos + car.heading))
		end
	end
end

---------------------------------------------------------------------------------------
-- CIDADE: dia/noite, LOD e escombros
---------------------------------------------------------------------------------------
local function setNight(night)
	City.isNight = night
	for _, sl in ipairs(City.streetlights) do
		if sl.bulb.Parent then
			sl.bulb.Material = night and Enum.Material.Neon or Enum.Material.Glass
			sl.bulb.Color = night and Color3.fromRGB(255, 220, 160) or Color3.fromRGB(200, 200, 190)
		end
	end
	local gen = City.generation
	task.spawn(function()
		for i, win in ipairs(City.windows) do
			if City.generation ~= gen or City.isNight ~= night then
				return
			end
			local g = win.part
			if g.Parent then
				if night and i % 3 ~= 0 then
					g.Material = Enum.Material.Neon
					g.Color = WINDOW_NIGHT:Lerp(win.color, math.random() * 0.3)
					g.Transparency = 0.15
				else
					g.Material = Enum.Material.Glass
					g.Color = win.color
					g.Transparency = 0.35
				end
			end
			if i % 400 == 0 then
				task.wait()
			end
		end
	end)
end

local function isNightTime()
	local t = Lighting.ClockTime
	return t >= 18 or t < 6.2
end

local lodTimer = 0
local function updateLOD(dt)
	lodTimer += dt
	if lodTimer < 0.4 then
		return
	end
	lodTimer = 0
	local focus = camera.CFrame.Position
	for _, it in ipairs(City.interiors) do
		if not it.dead then
			local want = (it.pos - focus).Magnitude < CITY.INTERIOR_LOD
			if want ~= it.loaded then
				it.loaded = want
				it.folder.Parent = want and interiorsFolder or nil
			end
		end
	end
	for _, sl in ipairs(City.streetlights) do
		sl.light.Enabled = City.isNight and sl.bulb.Parent ~= nil and (sl.pos - focus).Magnitude < CITY.LIGHT_LOD
	end
end

local function updateCity(dt)
	-- Dia e noite
	Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / CITY.DAY_LENGTH) % 24
	if isNightTime() ~= City.isNight then
		setNight(isNightTime())
	end

	-- Escombros somem depois de um tempo
	local now = os.clock()
	while City.debris[1] and now - City.debris[1].time > CITY.DEBRIS_LIFE do
		local d = table.remove(City.debris, 1)
		if d.part.Parent then
			TweenService:Create(d.part, TweenInfo.new(0.6), { Transparency = 1 }):Play()
			Debris:AddItem(d.part, 0.7)
		end
	end

	-- Prédios desmoronando
	for i = #City.collapsing, 1, -1 do
		local c = City.collapsing[i]
		c.t += dt
		local a = math.min(1, c.t / c.dur)
		local ease = a * a
		local b = c.b
		if b.model.Parent then
			b.model:PivotTo(b.cf * CFrame.new(0, -b.height * ease, 0) * CFrame.Angles(c.tiltX * ease, 0, c.tiltZ * ease))
		end
		addShake(dt * 2, b.cf.Position)
		if a >= 1 then
			b.model:Destroy()
			spawnRubble(b)
			table.remove(City.collapsing, i)
		end
	end

	updateTraffic(dt)
	updateLOD(dt)
end

---------------------------------------------------------------------------------------
-- CIDADE: geração
---------------------------------------------------------------------------------------
local function generateCity()
	City.generating = true
	UI.loadingFrame.Visible = true
	UI.loadingBar.Size = UDim2.fromScale(0, 1)
	UI.loadingStatus.Text = "CONSTRUINDO A CIDADE..."

	-- Limpa a cidade anterior
	City.generation += 1
	for _, it in ipairs(City.interiors) do
		it.folder:Destroy()
	end
	cityFolder:ClearAllChildren()
	debrisFolder:ClearAllChildren()
	City.partInfo = {}
	City.buildings = {}
	City.interiors = {}
	City.streetlights = {}
	City.traffic = {}
	City.debris = {}
	City.collapsing = {}
	City.windows = {}
	City.roadCenters = {}
	City.totalMass = 0
	City.lostMass = 0
	City.buildingsDestroyed = 0

	groundFolder = new("Folder", { Name = "Chao", Parent = cityFolder })
	buildingsFolder = new("Folder", { Name = "Predios", Parent = cityFolder })
	propsFolder = new("Folder", { Name = "Objetos", Parent = cityFolder })
	interiorsFolder = new("Folder", { Name = "Interiores", Parent = cityFolder })
	trafficFolder = new("Folder", { Name = "Transito", Parent = cityFolder })

	local pitch = CITY.BLOCK + CITY.ROAD
	local half = (CITY.GRID * pitch + CITY.ROAD) / 2
	City.half = half

	-- Asfalto e faixas amarelas
	cityPart(groundFolder, Vector3.new(half * 2, 2, half * 2), CFrame.new(0, -0.8, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Asphalt)
	for k = 0, CITY.GRID do
		local c = -half + CITY.ROAD / 2 + k * pitch
		table.insert(City.roadCenters, c)
		local lineProps = { CanQuery = false, CastShadow = false }
		cityPart(groundFolder, Vector3.new(half * 2, 0.05, 0.5), CFrame.new(0, 0.22, c), Color3.fromRGB(240, 200, 40), Enum.Material.SmoothPlastic, lineProps)
		cityPart(groundFolder, Vector3.new(0.5, 0.05, half * 2), CFrame.new(c, 0.22, 0), Color3.fromRGB(240, 200, 40), Enum.Material.SmoothPlastic, lineProps)
	end

	-- Quarteirões (o do meio é a praça onde o jogo começa)
	local offset = (CITY.GRID + 1) / 2
	local mid = math.ceil(CITY.GRID / 2)
	local total = CITY.GRID * CITY.GRID
	local done = 0
	for i = 1, CITY.GRID do
		for j = 1, CITY.GRID do
			local center = Vector3.new((i - offset) * pitch, 0, (j - offset) * pitch)
			buildBlock(center, i == mid and j == mid)
			done += 1
			UI.loadingBar.Size = UDim2.fromScale(done / total, 1)
			UI.loadingStatus.Text = ("CONSTRUINDO A CIDADE... %d%%"):format(math.floor(done / total * 100))
			task.wait()
		end
	end

	for _ = 1, CITY.TRAFFIC_CARS do
		spawnTrafficCar()
	end

	City.dirty = false
	lodTimer = 1 -- força atualizar LOD no próximo quadro
	setNight(isNightTime())
	City.generating = false
	UI.loadingFrame.Visible = false
end

---------------------------------------------------------------------------------------
-- DRONES INIMIGOS
---------------------------------------------------------------------------------------
local drones = {}
local partToDrone = {}
local enemyShots = {}
local pickups = {}

local function spawnPickup(position)
	local repair = math.random() < 0.5
	local color = repair and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(60, 180, 255)
	local part = makePart({
		Shape = BALL,
		Size = Vector3.one * 2.5,
		Color = color,
		Material = Enum.Material.Neon,
		Position = position,
		CastShadow = false,
		Parent = effects,
	})
	new("PointLight", { Color = color, Range = 12, Brightness = 2, Parent = part })
	table.insert(pickups, { part = part, repair = repair, pos = position, life = 25 })
end

local function updatePickups(dt)
	for i = #pickups, 1, -1 do
		local pk = pickups[i]
		pk.life -= dt
		local groundY = findGroundY(pk.pos)
		if pk.pos.Y > groundY + 2.5 then
			pk.pos = Vector3.new(pk.pos.X, math.max(groundY + 2.5, pk.pos.Y - 40 * dt), pk.pos.Z)
		end
		pk.part.Position = pk.pos + Vector3.new(0, math.sin(os.clock() * 4) * 0.4, 0)
		local collected = not State.dead and (pk.pos - torsoCenter()).Magnitude < 11
		if collected then
			if pk.repair then
				State.health = math.min(CONFIG.MAX_HEALTH, State.health + 150)
				notify("+150 INTEGRIDADE", Color3.fromRGB(80, 255, 120))
			else
				State.energy = CONFIG.MAX_ENERGY
				notify("ENERGIA RECARREGADA", Color3.fromRGB(60, 180, 255))
			end
			spark(pk.pos, pk.part.Color, 20, 20)
		end
		if collected or pk.life <= 0 then
			pk.part:Destroy()
			table.remove(pickups, i)
		end
	end
end

local function spawnDrone(position, isBoss)
	if #drones >= CONFIG.MAX_DRONES and not isBoss then
		return
	end
	local s = isBoss and 3.5 or 1
	local eyeColor = isBoss and Color3.fromRGB(200, 60, 255) or Color3.fromRGB(255, 30, 30)
	local model = new("Model", { Name = isBoss and "NaveMae" or "Drone", Parent = droneFolder })
	local body = makePart({
		Name = "Corpo",
		Shape = BALL,
		Size = Vector3.one * 3 * s,
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
		CanQuery = true,
		Parent = model,
	})
	local eye = makePart({
		Name = "Olho",
		Shape = BALL,
		Size = Vector3.one * 1.3 * s,
		Color = eyeColor,
		Material = Enum.Material.Neon,
		CanQuery = true,
		Parent = model,
	})
	local ring = makePart({
		Name = "Anel",
		Shape = CYL,
		Size = Vector3.new(0.3, 5, 5) * s,
		Color = Color3.fromRGB(90, 90, 100),
		Material = Enum.Material.Metal,
		CanQuery = true,
		Parent = model,
	})
	new("PointLight", { Color = eyeColor, Range = 10 * s, Brightness = 2, Parent = eye })
	local billboard = new("BillboardGui", {
		Size = UDim2.new(4 * s, 0, 0.4 * s, 0),
		StudsOffset = Vector3.new(0, 3 * s, 0),
		AlwaysOnTop = true,
		Adornee = body,
		Parent = body,
	})
	local barBg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = billboard })
	local bar = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = eyeColor, BorderSizePixel = 0, Parent = barBg })
	if isBoss then
		label({
			Size = UDim2.new(1, 0, 2, 0),
			Position = UDim2.fromScale(0, -2.2),
			Text = "NAVE-MÃE",
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
			TextColor3 = eyeColor,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = billboard,
		})
	end

	local maxHp = isBoss and CONFIG.BOSS_HEALTH or CONFIG.DRONE_HEALTH
	local drone = {
		model = model,
		body = body,
		eye = eye,
		ring = ring,
		bar = bar,
		isBoss = isBoss,
		eyeColor = eyeColor,
		scale = s,
		hp = maxHp,
		maxHp = maxHp,
		pos = position,
		angle = math.random() * math.pi * 2,
		radius = isBoss and 90 or 35 + math.random() * 40,
		height = isBoss and 55 or 14 + math.random() * 20,
		orbitSpeed = (math.random() < 0.5 and -1 or 1) * (isBoss and 0.15 or 0.3 + math.random() * 0.4),
		fireTimer = 2 + math.random() * CONFIG.DRONE_FIRE_MAX,
		spin = 0,
	}
	partToDrone[body] = drone
	partToDrone[eye] = drone
	partToDrone[ring] = drone
	table.insert(drones, drone)
	spark(position, eyeColor, 20, 20)
end

local function spawnWave()
	State.wave += 1
	local center = State.rootCF.Position
	local boss = State.wave % CONFIG.BOSS_EVERY == 0
	local count = boss and math.floor(State.wave / 2) or CONFIG.DRONES_PER_WAVE + State.wave - 1
	for _ = 1, count do
		local a = math.random() * math.pi * 2
		spawnDrone(center + Vector3.new(math.cos(a) * 90, 30 + math.random() * 20, math.sin(a) * 90), false)
	end
	if boss then
		spawnDrone(center + Vector3.new(0, 90, -140), true)
		notify("ONDA " .. State.wave .. " — A NAVE-MÃE CHEGOU!", Color3.fromRGB(200, 80, 255))
	else
		notify("ONDA " .. State.wave .. " — DRONES CHEGANDO!", Color3.fromRGB(255, 80, 80))
	end
end

local function removeDrone(drone)
	local index = table.find(drones, drone)
	if index then
		table.remove(drones, index)
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
			drone.eye.Color = drone.eyeColor
		end
	end)
	drone.bar.Size = UDim2.fromScale(math.max(drone.hp, 0) / drone.maxHp, 1)
	if drone.hp <= 0 then
		explosion(drone.pos, 8 * drone.scale, Color3.fromRGB(255, 120, 30))
		removeDrone(drone)
		if isPlaying() then
			State.dronesKilled += 1
			State.score += drone.isBoss and 2000 or 100
		end
		if drone.isBoss then
			notify("NAVE-MÃE DESTRUÍDA!  +2000", Color3.fromRGB(200, 80, 255))
			for _ = 1, 3 do
				spawnPickup(drone.pos + Vector3.new(rand(-8, 8), 0, rand(-8, 8)))
			end
		elseif math.random() < CONFIG.PICKUP_CHANCE then
			spawnPickup(drone.pos)
		end
		if #drones == 0 and isPlaying() then
			State.score += 500
			notify("ONDA " .. State.wave .. " CONCLUÍDA!  +500", Color3.fromRGB(90, 255, 120))
		end
	end
end

function damageArea(position, radius, amount)
	-- copia a lista porque drones podem ser removidos durante o loop
	for _, drone in ipairs(table.clone(drones)) do
		local dist = (drone.pos - position).Magnitude
		if dist <= radius + 2 * drone.scale then
			damageDrone(drone, amount * (1 - math.min(dist / radius, 1) * 0.5))
		end
	end
end

local function fireEnemyShot(from, dir, isBoss)
	local color = isBoss and Color3.fromRGB(200, 80, 255) or Color3.fromRGB(255, 40, 40)
	local shot = makePart({
		Shape = BALL,
		Size = Vector3.one * (isBoss and 1.8 or 1.1),
		Color = color,
		Material = Enum.Material.Neon,
		CastShadow = false,
		Position = from,
		Parent = effects,
	})
	new("PointLight", { Color = color, Range = 8, Parent = shot })
	table.insert(enemyShots, {
		part = shot,
		pos = from,
		vel = dir * CONFIG.DRONE_SHOT_SPEED,
		damage = isBoss and CONFIG.BOSS_DAMAGE or CONFIG.DRONE_DAMAGE,
		life = 5,
	})
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
		drone.eye.CFrame = cf * CFrame.new(0, 0, -1.2 * drone.scale)
		drone.ring.CFrame = cf * CFrame.Angles(0, 0, drone.spin) * CFrame.Angles(0, math.rad(90), 0)

		drone.fireTimer -= dt
		if drone.fireTimer <= 0 and not State.dead and isPlaying() then
			local interval = CONFIG.DRONE_FIRE_MIN + math.random() * (CONFIG.DRONE_FIRE_MAX - CONFIG.DRONE_FIRE_MIN)
			drone.fireTimer = drone.isBoss and interval * 0.6 or interval
			if (drone.pos - robotPos).Magnitude < 280 then
				local from = drone.pos + cf.LookVector * 2 * drone.scale
				local aim = torsoCenter() + State.velocity * 0.3
				local dir = (aim - from).Unit
				local shots = drone.isBoss and 5 or 1
				for k = 1, shots do
					local spread = (k - (shots + 1) / 2) * 0.12
					fireEnemyShot(from, CFrame.Angles(0, spread, 0):VectorToWorldSpace(dir), drone.isBoss)
				end
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
			damageRobot(shot.damage, newPos)
			done = true
		elseif not done then
			local hit = workspace:Raycast(shot.pos, step, rayWorld)
			if hit then
				spark(hit.Position, Color3.fromRGB(255, 60, 60), 8)
				local unit = City.partInfo[hit.Instance]
				if unit then
					damageUnit(unit, 20, hit.Position)
				end
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
		local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: any)
		controls = module:GetControls()
		if State.gameState ~= "playing" then
			controls:Disable()
		end
	end)
end)

local function setControls(enabled)
	if controls then
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end
end

local function getCharacterParts(): (BasePart?, Humanoid?)
	local char = player.Character
	if not char then
		return nil, nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?, char:FindFirstChildOfClass("Humanoid")
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

local function exitRobot(silent)
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
	setControls(isPlaying())
	camera.CameraType = Enum.CameraType.Custom
	if humanoid then
		camera.CameraSubject = humanoid
	end
	camera.FieldOfView = 70
	if not silent then
		notify("VOCÊ SAIU DO ROBÔ — aperte V para voltar")
	end
end

local function enterRobot(force)
	local hrp, humanoid = getCharacterParts()
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return
	end
	if State.dead then
		notify("ROBÔ EM RECONSTRUÇÃO...", Color3.fromRGB(255, 170, 60))
		return
	end
	local dist = (hrp.Position - State.rootCF.Position).Magnitude
	if dist > CONFIG.ENTER_DISTANCE and not force then
		explosion(State.rootCF.Position, 6, theme().accent)
		placeRobotNear(hrp.Position, hrp.CFrame.LookVector)
		explosion(State.rootCF.Position, 10, theme().accent)
		playSound(CONFIG.SOUNDS.whoosh, 0.8)
		notify("ROBÔ CONVOCADO! Aperte V para entrar")
		return
	end
	State.piloting = true
	hrp.Anchored = true
	setControls(false)
	State.camYaw = State.yaw
	State.camPitch = -0.2
	camera.CameraType = Enum.CameraType.Scriptable
	playSound(CONFIG.SOUNDS.whoosh, 0.6, 1.3)
	if not force then
		notify("SISTEMAS ONLINE — BEM-VINDO, PILOTO")
	end
end

local function hookCharacter(char)
	refreshFilters()
	local humanoid = char:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(function()
			if State.piloting then
				exitRobot(true)
			end
		end)
	end
	if State.gameState ~= "playing" then
		setControls(false)
	end
end
player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	task.spawn(hookCharacter, player.Character)
end

---------------------------------------------------------------------------------------
-- DANO / DESTRUIÇÃO DO ROBÔ
---------------------------------------------------------------------------------------
local gameOver -- definido mais abaixo

local function destroyRobot()
	if State.dead then
		return
	end
	State.dead = true
	State.health = 0
	State.flying = false
	State.shield = false
	State.firing = false
	State.slamming = false
	local center = torsoCenter()
	explosion(center, 25, Color3.fromRGB(255, 100, 20))
	task.delay(0.2, function()
		explosion(center + Vector3.new(3, 4, 0), 15)
	end)
	task.delay(0.4, function()
		explosion(center + Vector3.new(-3, 1, 2), 18)
	end)
	damageCity(center, 20, 120)
	setRobotVisible(false)

	local runId = State.runId
	if State.mode == "missao" and isPlaying() then
		State.lives -= 1
		if State.lives <= 0 then
			notify("SEM VIDAS RESTANTES!", Color3.fromRGB(255, 70, 70))
			task.delay(3, function()
				if State.runId == runId and State.gameState == "playing" then
					gameOver()
				end
			end)
			return
		end
		notify(("ROBÔ DESTRUÍDO — %d VIDA(S) RESTANTE(S)"):format(State.lives), Color3.fromRGB(255, 70, 70))
	else
		notify("ROBÔ DESTRUÍDO — reconstruindo em 5s", Color3.fromRGB(255, 70, 70))
	end
	task.delay(5, function()
		if State.runId ~= runId then
			return
		end
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
	if State.dead or not isPlaying() then
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
		local unit = City.partInfo[hit.Instance]
		if drone then
			damageDrone(drone, CONFIG.LASER_DAMAGE)
			flashHitmarker()
		elseif unit then
			damageUnit(unit, CONFIG.LASER_DAMAGE * 1.5, hit.Position)
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
		local desired = m.targetPos - m.pos
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
			damageCity(explodeAt, CONFIG.MISSILE_RADIUS, 150)
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
				FillColor = drone.eyeColor,
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
	dust(pos, 12, 1)
	damageArea(pos, CONFIG.SLAM_RADIUS * 1.5, CONFIG.SLAM_DAMAGE)
	damageCity(pos, CONFIG.SLAM_RADIUS, 200)
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
		damageCity(State.rootCF.Position - Vector3.new(0, CONFIG.HIP_HEIGHT, 0), 6, fallSpeed)
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
		local center = torsoCenter()
		damageArea(center, 70, 999)
		damageCity(center, 60, 600)
		destroyRobot()
	else
		State.destructArmed = 2
		notify("AUTODESTRUIÇÃO: aperte X de novo para confirmar", Color3.fromRGB(255, 60, 60))
	end
end

---------------------------------------------------------------------------------------
-- FLUXO DO JOGO (menu, partida, pausa, fim)
---------------------------------------------------------------------------------------
local function clearEnemies()
	for i = #drones, 1, -1 do
		removeDrone(drones[i])
	end
	for _, s in ipairs(enemyShots) do
		s.part:Destroy()
	end
	table.clear(enemyShots)
	for _, m in ipairs(missiles) do
		m.part:Destroy()
	end
	table.clear(missiles)
	for _, pk in ipairs(pickups) do
		pk.part:Destroy()
	end
	table.clear(pickups)
end

local PLAZA_SPAWN = Vector3.new(0, 5, 34)

function startGame(mode)
	if State.gameState == "loading" then
		return
	end
	UI.menuFrame.Visible = false
	UI.gameOverFrame.Visible = false
	UI.pauseFrame.Visible = false
	State.showHelp = false
	if State.piloting then
		exitRobot(true)
	end
	clearEnemies()
	if City.dirty then
		State.gameState = "loading"
		generateCity()
	end

	State.runId += 1
	State.mode = mode
	State.dead = false
	State.health = CONFIG.MAX_HEALTH
	State.energy = CONFIG.MAX_ENERGY
	State.lives = CONFIG.LIVES
	State.flying = false
	State.shield = false
	State.slamming = false
	State.score = 0
	State.wave = 0
	State.dronesKilled = 0
	State.playTime = 0
	State.nextWaveTimer = 5
	State.shake = 0
	for k in pairs(State.cooldowns) do
		State.cooldowns[k] = 0
	end

	local hrp = getCharacterParts()
	if hrp then
		hrp.Anchored = false
		hrp.CFrame = CFrame.new(PLAZA_SPAWN)
	end
	State.yaw = 0
	State.rootCF = CFrame.new(0, findGroundY(Vector3.new(0, 0, 18)) + CONFIG.HIP_HEIGHT, 18)
	State.velocity = Vector3.zero
	setRobotVisible(true)

	State.gameState = "playing"
	camera.CameraType = Enum.CameraType.Custom
	enterRobot(true)
	if mode == "missao" then
		notify("MODO MISSÃO — sobreviva às ondas!", Color3.fromRGB(255, 200, 60))
	else
		notify("MODO LIVRE — destrua a cidade!", Color3.fromRGB(255, 200, 60))
	end
end

function showMenu()
	if State.piloting then
		exitRobot(true)
	end
	clearEnemies()
	State.gameState = "menu"
	State.runId += 1
	setControls(false)
	UI.menuFrame.Visible = true
	UI.pauseFrame.Visible = false
	UI.gameOverFrame.Visible = false
	State.showHelp = false
end

local function pauseGame()
	if State.gameState ~= "playing" then
		return
	end
	State.gameState = "paused"
	State.firing = false
	UI.pauseFrame.Visible = true
	setControls(false)
end

function resumeGame()
	if State.gameState ~= "paused" then
		return
	end
	State.gameState = "playing"
	UI.pauseFrame.Visible = false
	setControls(not State.piloting)
end

function gameOver()
	State.gameState = "gameover"
	if State.piloting then
		exitRobot(true)
	end
	clearEnemies()
	setControls(false)
	local minutes = math.floor(State.playTime / 60)
	local seconds = math.floor(State.playTime % 60)
	local destruction = City.totalMass > 0 and City.lostMass / City.totalMass * 100 or 0
	UI.gameOverStats.Text = table.concat({
		("PONTOS: %d"):format(State.score),
		("ONDAS: %d"):format(State.wave),
		("DRONES ABATIDOS: %d"):format(State.dronesKilled),
		("PRÉDIOS DERRUBADOS: %d"):format(City.buildingsDestroyed),
		("DESTRUIÇÃO DA CIDADE: %d%%"):format(math.floor(destruction)),
		("TEMPO: %d:%02d"):format(minutes, seconds),
	}, "\n")
	UI.gameOverFrame.Visible = true
end

---------------------------------------------------------------------------------------
-- ENTRADA (TECLADO / MOUSE)
---------------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local key = input.KeyCode

	if key == Enum.KeyCode.P then
		if State.gameState == "playing" then
			pauseGame()
		elseif State.gameState == "paused" then
			resumeGame()
		end
		return
	elseif key == Enum.KeyCode.H then
		State.showHelp = not State.showHelp
		return
	end

	if not isPlaying() then
		return
	end

	if key == Enum.KeyCode.V then
		if State.piloting then
			exitRobot()
		else
			enterRobot()
		end
		return
	elseif key == Enum.KeyCode.N then
		Lighting.ClockTime = (Lighting.ClockTime + 6) % 24
		notify(("RELÓGIO: %02d:00"):format(math.floor(Lighting.ClockTime)))
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
		if State.mode == "livre" then
			spawnWave()
		else
			notify("NO MODO MISSÃO AS ONDAS VÊM SOZINHAS!", Color3.fromRGB(255, 170, 60))
		end
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
	if not State.piloting or not isPlaying() then
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
	local canControl = State.piloting and not State.dead and isPlaying()

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

	-- Paredes: com turbo (ou contra objetos pequenos) o robô quebra o que estiver na frente;
	-- se não quebrar, desliza ao longo da parede
	local horizontal = Vector3.new(vel.X, 0, vel.Z)
	if horizontal.Magnitude > 0.01 then
		local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), horizontal.Unit * (horizontal.Magnitude * dt + 2.5), rayWorld)
		if hit and hit.Normal.Y < 0.6 then
			local unit = City.partInfo[hit.Instance]
			if unit and (State.turbo or unit.kind == "prop" or unit.kind == "car") then
				damageUnit(unit, 250, hit.Position)
				addShake(0.4)
			end
			if not (unit and unit.broken) then
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

	-- Caiu no vazio: volta para a praça
	if newPos.Y < workspace.FallenPartsDestroyHeight + 30 then
		newPos = Vector3.new(0, findGroundY(Vector3.new(0, 200, 18)) + CONFIG.HIP_HEIGHT, 18)
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
		State.shield = false
	end
	shieldPart.Transparency = (State.shield and not State.dead) and 0 or 1
end

---------------------------------------------------------------------------------------
-- CÂMERA E MIRA
---------------------------------------------------------------------------------------
local function updateCamera(dt)
	camera.CameraType = Enum.CameraType.Scriptable

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

local function updateMenuCamera(dt)
	State.menuAngle += dt * 0.05
	camera.CameraType = Enum.CameraType.Scriptable
	local a = State.menuAngle
	camera.CFrame = CFrame.lookAt(Vector3.new(math.cos(a) * 330, 150, math.sin(a) * 330), Vector3.new(0, 20, 0))
	camera.FieldOfView = 70
end

---------------------------------------------------------------------------------------
-- ANIMAÇÃO PROCEDURAL
---------------------------------------------------------------------------------------
local clock = 0

local function updateAnimation(dt)
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

		-- Passos: som, tremor e esmagar coisas
		local sign = s >= 0 and 1 or -1
		if sign ~= State.lastStepSign and speed > 3 then
			State.lastStepSign = sign
			playSound(CONFIG.SOUNDS.land, 0.4, 0.5)
			if State.piloting then
				addShake(0.12 * amount)
			end
			damageCity(State.rootCF.Position - Vector3.new(0, CONFIG.HIP_HEIGHT - 1, 0), 3.5, 40)
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
	local inGame = State.gameState == "playing" or State.gameState == "paused"
	UI.hud.Visible = inGame
	UI.helpPanel.Visible = State.showHelp
	if not inGame then
		return
	end

	local hpRatio = math.clamp(State.health / CONFIG.MAX_HEALTH, 0, 1)
	UI.hpFill.Size = UDim2.fromScale(hpRatio, 1)
	UI.hpFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(60, 220, 90), hpRatio)
	UI.hpText.Text = ("INTEGRIDADE  %d / %d"):format(math.max(0, math.floor(State.health)), CONFIG.MAX_HEALTH)
	UI.enFill.Size = UDim2.fromScale(State.energy / CONFIG.MAX_ENERGY, 1)
	UI.enText.Text = ("ENERGIA  %d%%"):format(math.floor(State.energy / CONFIG.MAX_ENERGY * 100))

	local mode = State.dead and "DESTRUÍDO"
		or not State.piloting and "A PÉ"
		or State.slamming and "MERGULHO"
		or State.flying and (State.turbo and "VOO TURBO" or "VOO")
		or State.turbo and "TURBO"
		or State.onGround and "CAMINHADA"
		or "NO AR"
	local destruction = City.totalMass > 0 and City.lostMass / City.totalMass * 100 or 0
	local altitude = State.rootCF.Position.Y - CONFIG.HIP_HEIGHT - findGroundY(State.rootCF.Position)
	UI.infoLabels[1].Text = ("MODO: %s   VEL: %d"):format(mode, math.floor(State.velocity.Magnitude))
	UI.infoLabels[2].Text = ("ALTITUDE: %d   HORA: %02d:%02d"):format(
		math.floor(math.max(0, altitude)),
		math.floor(Lighting.ClockTime),
		math.floor(Lighting.ClockTime % 1 * 60)
	)
	UI.infoLabels[3].Text = ("PONTOS: %d   DRONES ABATIDOS: %d"):format(State.score, State.dronesKilled)
	UI.infoLabels[4].Text = ("DESTRUIÇÃO: %d%%   PRÉDIOS: %d/%d"):format(math.floor(destruction), City.buildingsDestroyed, #City.buildings)
	if State.mode == "missao" then
		UI.infoLabels[5].Text = "VIDAS: " .. string.rep("♥ ", math.max(State.lives, 0))
	else
		UI.infoLabels[5].Text = "VIDAS: ∞   TEMA: " .. theme().name
	end

	if hpRatio < 0.25 and not State.dead then
		UI.warningLabel.Text = (clock % 0.8 < 0.4) and "⚠ INTEGRIDADE CRÍTICA ⚠" or ""
	else
		UI.warningLabel.Text = ""
	end

	-- Objetivo
	if State.mode == "missao" then
		local boss
		for _, d in ipairs(drones) do
			if d.isBoss then
				boss = d
			end
		end
		if boss then
			UI.objectiveLabel.Text = ("ONDA %d — DERROTE A NAVE-MÃE (%d%%)"):format(State.wave, math.floor(boss.hp / boss.maxHp * 100))
			UI.objectiveLabel.TextColor3 = Color3.fromRGB(210, 120, 255)
		elseif #drones > 0 then
			UI.objectiveLabel.Text = ("ONDA %d — DRONES RESTANTES: %d"):format(State.wave, #drones)
			UI.objectiveLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
		else
			UI.objectiveLabel.Text = ("PRÓXIMA ONDA EM %d s"):format(math.ceil(State.nextWaveTimer or 0))
			UI.objectiveLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
		end
	else
		UI.objectiveLabel.Text = ("MODO LIVRE — DESTRUIÇÃO %d%%"):format(math.floor(destruction))
		UI.objectiveLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	end

	local cooldownMax = { missile = CONFIG.MISSILE_COOLDOWN, scan = CONFIG.SCAN_COOLDOWN, slam = CONFIG.SLAM_COOLDOWN }
	for id, max in pairs(cooldownMax) do
		UI.slotUI[id].overlay.Size = UDim2.fromScale(1, math.clamp(State.cooldowns[id] / max, 0, 1))
	end
	local toggles = { shield = State.shield, fly = State.flying, lights = State.lights }
	for id, on in pairs(toggles) do
		UI.slotUI[id].stroke.Color = on and theme().accent or Color3.fromRGB(90, 95, 110)
		UI.slotUI[id].stroke.Thickness = on and 3 or 1.5
	end

	UI.crosshair.Visible = State.piloting and not State.dead
	UI.abilityBar.Visible = State.piloting

	if State.piloting then
		UI.promptLabel.Text = ""
	else
		local hrp = getCharacterParts()
		local near = hrp and (hrp.Position - State.rootCF.Position).Magnitude <= CONFIG.ENTER_DISTANCE
		UI.promptLabel.Text = near and "Aperte  V  para ENTRAR no robô" or "Aperte  V  para CONVOCAR o robô"
	end

	-- Radar
	for i, drone in ipairs(drones) do
		local blip = UI.radarBlips[i]
		if not blip then
			blip = new("Frame", {
				Size = UDim2.fromOffset(7, 7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 2,
				Parent = UI.radar,
			}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			UI.radarBlips[i] = blip
		end
		local rel = State.rootCF:PointToObjectSpace(drone.pos)
		local flat = Vector2.new(rel.X, rel.Z) / UI.RADAR_RANGE * 80
		if flat.Magnitude > 78 then
			flat = flat.Unit * 78
		end
		blip.Position = UDim2.new(0.5, flat.X, 0.5, flat.Y)
		blip.Size = drone.isBoss and UDim2.fromOffset(13, 13) or UDim2.fromOffset(7, 7)
		blip.BackgroundColor3 = drone.eyeColor
		blip.Visible = true
	end
	for i = #drones + 1, #UI.radarBlips do
		UI.radarBlips[i].Visible = false
	end
end

---------------------------------------------------------------------------------------
-- LOOP PRINCIPAL
---------------------------------------------------------------------------------------
local function mainLoop(dt)
	dt = math.min(dt, 0.1)
	clock += dt
	local gs = State.gameState

	-- Mouse preso só quando pilotando; livre em menus
	if gs == "playing" and State.piloting then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		if State.piloting or gs ~= "playing" then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		UserInputService.MouseIconEnabled = true
	end

	if gs == "loading" then
		updateMenuCamera(dt)
		return
	end
	if gs == "paused" then
		updateHUD()
		return
	end
	if gs == "menu" then
		updateMenuCamera(dt)
	end

	for k, v in pairs(State.cooldowns) do
		State.cooldowns[k] = math.max(0, v - dt)
	end
	State.jetBoost = math.max(0, State.jetBoost - dt)
	State.destructArmed = math.max(0, State.destructArmed - dt)

	-- Ondas automáticas no modo missão
	if gs == "playing" then
		State.playTime += dt
		if State.mode == "missao" and not State.dead and #drones == 0 then
			State.nextWaveTimer = (State.nextWaveTimer or CONFIG.WAVE_DELAY) - dt
			if State.nextWaveTimer <= 0 then
				State.nextWaveTimer = nil
				spawnWave()
			end
		end
	end

	if not State.dead then
		updatePhysics(dt)
		updateEnergy(dt)
	end
	if gs == "playing" and State.piloting then
		updateCamera(dt)
	end

	if gs == "playing" and State.piloting and State.firing and not State.dead
		and State.cooldowns.laser <= 0 and State.energy >= CONFIG.LASER_COST
	then
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
	updatePickups(dt)
	updateCity(dt)
	updateHUD()
end

---------------------------------------------------------------------------------------
-- INÍCIO
---------------------------------------------------------------------------------------
task.spawn(function()
	RunService:BindToRenderStep("RoboTitan", Enum.RenderPriority.Camera.Value + 1, mainLoop)
	generateCity()
	State.rootCF = CFrame.new(0, findGroundY(Vector3.new(0, 0, 18)) + CONFIG.HIP_HEIGHT, 18)
	computeJoints()
	applyPieces()
	showMenu()
end)
