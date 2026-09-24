--[[
=====================================================================================
   TITAN X-9: CIDADE EM RUÍNAS
   Jogo completo em UM ÚNICO script: robôs gigantes + cidade destrutível
=====================================================================================

  COMO INSTALAR
   1. Abra o Roblox Studio e crie um jogo novo do tipo "Baseplate".
   2. No Explorer: StarterPlayer > StarterPlayerScripts
   3. Clique no "+" ao lado de StarterPlayerScripts > LocalScript
   4. Apague o conteúdo do LocalScript e cole ESTE código inteiro.
   5. Aperte Play (F5). A cidade é gerada, o menu aparece e é só jogar.

  ROBÔS (escolha na garagem do menu; no modo livre troque com 1, 2, 3 e 4)
   TITAN X-9 ...... Equilibrado: laser de precisão, mísseis e voo.
   GOLIAS MK-II ... Tanque pesado: canhão de plasma explosivo, 4 mísseis, muita blindagem.
   FALCÃO ......... Caça veloz: metralhadora rotativa, voo rápido e barato.
   BERSERKER ...... Brutamontes: lança-chamas e socos que derrubam prédios.

  MODOS DE JOGO
   MISSÃO ... Ondas cada vez maiores de drones, tanques, helicópteros e robôs
              inimigos. A cada 5 ondas vem a NAVE-MÃE. 3 vidas.
   LIVRE .... Sem limites: destrua a cidade inteira, chame inimigos com T.

  CONTROLES (dentro do robô)
   V ............ Entrar / sair do robô (longe = convoca o robô até você)
   W A S D ...... Andar                      Mouse ........ Mirar / câmera
   Botão esq. ... Arma principal (segure)    Roda do mouse  Zoom
   Espaço ....... Pular / impulso / subir voando
   Ctrl esq. .... Descer (no modo voo)
   Shift esq. ... Turbo (com turbo você ATRAVESSA paredes!)
   B ............ Soco                       F ............ Modo voo
   E ............ Mísseis teleguiados        Q ............ Escudo de energia
   R ............ Scanner                    G ............ Impacto sísmico
   L ............ Faróis                     C ............ Trocar cor do robô
   K ............ Acenar                     T ............ Inimigos (modo livre)
   1 2 3 4 ...... Trocar de robô (modo livre)
   N ............ Avançar o relógio          X (2 vezes) .. Autodestruição
   P ............ Pausar                     H ............ Ajuda

  A CIDADE
   - Prédios feitos de paredes, janelas e lajes. Tudo quebra em pedaços e pega fogo.
   - Se a base de um prédio for destruída (ou boa parte dele), ele DESMORONA.
   - Lojas com interior: mercado, pizzaria, café, banco e fliperama.
   - Trânsito, carros que explodem em cadeia, postes, árvores, hidrantes,
     lixeiras, pontos de ônibus, letreiros luminosos, praça, parques.
   - Ciclo de dia e noite, nuvens, raios de sol e janelas acesas à noite.
   - Otimizado: interiores e luzes só perto da câmera, limite de escombros,
     qualidade gráfica ajustável no menu (BAIXO / MÉDIO / ALTO).

  OBSERVAÇÃO
   Tudo é criado no cliente (LocalScript): é um jogo para 1 jogador.
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
	MAX_ENERGY = 100,
	GRAVITY = 150,
	TURN_SPEED = 8,
	ENTER_DISTANCE = 30,
	JET_BOOST_COST = 15,
	LASER_RANGE = 1000,

	MISSILE_DAMAGE = 120,
	MISSILE_RADIUS = 18,
	MISSILE_SPEED = 120,
	MISSILE_COOLDOWN = 1.2,
	MISSILE_COST = 15,

	PUNCH_COOLDOWN = 0.8,
	PUNCH_COST = 8,
	SHIELD_DRAIN = 12,
	SCAN_COOLDOWN = 6,
	SCAN_RANGE = 450,
	SCAN_COST = 10,
	SLAM_DAMAGE = 150,
	SLAM_RADIUS = 35,
	SLAM_COOLDOWN = 5,
	SLAM_COST = 20,
	TURBO_DRAIN = 9,

	MAX_ENEMIES = 30,
	BOSS_HEALTH = 2500,
	PICKUP_CHANCE = 0.25,
	LIVES = 3,
	WAVE_DELAY = 8,
	BOSS_EVERY = 5,

	CAMERA_DISTANCE = 30,
	CAMERA_MIN = 12,
	CAMERA_MAX = 90,
	MOUSE_SENSITIVITY = 0.004,

	WEAPONS = {
		laser = { name = "LASER", rate = 0.09, cost = 1.2, damage = 18, cityDamage = 27 },
		plasma = { name = "PLASMA", rate = 0.55, cost = 9, damage = 90, radius = 13, cityDamage = 130, speed = 170 },
		minigun = { name = "METRALHADORA", rate = 0.05, cost = 0.45, damage = 7, cityDamage = 12, spread = 0.025 },
		flame = { name = "LANÇA-CHAMAS", rate = 0.06, cost = 0.8, damage = 7, cityDamage = 18, range = 48 },
	},

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
		MAX_FIRES = 14,
		COLLAPSE_RATIO = 0.35, -- desmorona ao perder 35% da estrutura...
		GROUND_COLLAPSE_RATIO = 0.55, -- ...ou 55% das paredes do térreo
		DAY_LENGTH = 480, -- segundos para um dia completo
		DEBRIS_LIFE = 7,
		-- Estes três mudam conforme a qualidade gráfica escolhida no menu
		MAX_DEBRIS = 220,
		INTERIOR_LOD = 170,
		LIGHT_LOD = 110,
	},

	-- Qualidade gráfica: BAIXO, MÉDIO, ALTO
	QUALITY = {
		{ name = "BAIXO", debris = 60, interior = 100, light = 70, shadows = false, effects = false, props = false },
		{ name = "MÉDIO", debris = 140, interior = 170, light = 110, shadows = true, effects = true, props = true },
		{ name = "ALTO", debris = 240, interior = 240, light = 160, shadows = true, effects = true, props = true },
	},

	SOUNDS = {
		laser = "rbxasset://sounds/electronicpingshort.wav",
		missile = "rbxasset://sounds/Rocket shot.wav",
		explosion = "rbxasset://sounds/collide.wav",
		jump = "rbxasset://sounds/action_jump.mp3",
		land = "rbxasset://sounds/action_jump_land.mp3",
		hit = "rbxasset://sounds/paintball.wav",
		whoosh = "rbxasset://sounds/Rocket whoosh 01.wav",
		punch = "rbxasset://sounds/swordslash.wav",
		gun = "rbxasset://sounds/paintball.wav",
	},
}
local CITY = CONFIG.CITY

local THEMES = {
	{ name = "Titânio Azul", primary = Color3.fromRGB(200, 205, 215), secondary = Color3.fromRGB(45, 50, 60), accent = Color3.fromRGB(0, 200, 255) },
	{ name = "Carmesim", primary = Color3.fromRGB(170, 20, 30), secondary = Color3.fromRGB(35, 35, 40), accent = Color3.fromRGB(255, 170, 0) },
	{ name = "Verde Tóxico", primary = Color3.fromRGB(70, 85, 70), secondary = Color3.fromRGB(25, 30, 25), accent = Color3.fromRGB(80, 255, 80) },
	{ name = "Ouro Real", primary = Color3.fromRGB(215, 170, 50), secondary = Color3.fromRGB(40, 35, 30), accent = Color3.fromRGB(255, 60, 200) },
	{ name = "Stealth", primary = Color3.fromRGB(35, 35, 40), secondary = Color3.fromRGB(15, 15, 18), accent = Color3.fromRGB(255, 40, 40) },
	{ name = "Militar", primary = Color3.fromRGB(100, 110, 75), secondary = Color3.fromRGB(45, 48, 40), accent = Color3.fromRGB(255, 150, 0) },
	{ name = "Ártico", primary = Color3.fromRGB(230, 235, 240), secondary = Color3.fromRGB(60, 70, 90), accent = Color3.fromRGB(0, 255, 200) },
}

-- Os robôs jogáveis. scale muda o tamanho do robô inteiro.
local ROBOTS = {
	{
		id = "titan", name = "TITAN X-9", role = "EQUILIBRADO",
		desc = "Laser de precisão, mísseis teleguiados e voo. Bom em tudo.",
		scale = 1, health = 1000, walk = 28, turbo = 55, jump = 75,
		canFly = true, flySpeed = 70, flyTurbo = 130, flyDrain = 7,
		weapon = "laser", missiles = 2, punch = 1, energyRegen = 14, theme = 1,
	},
	{
		id = "golias", name = "GOLIAS MK-II", role = "TANQUE PESADO",
		desc = "Canhão de plasma explosivo, 4 mísseis e blindagem dupla. Lento e não voa.",
		scale = 1.35, health = 2200, walk = 20, turbo = 38, jump = 62,
		canFly = false, flySpeed = 0, flyTurbo = 0, flyDrain = 0,
		weapon = "plasma", missiles = 4, punch = 1.6, energyRegen = 18, theme = 6,
	},
	{
		id = "falcao", name = "FALCÃO", role = "CAÇA VELOZ",
		desc = "Metralhadora rotativa, muito rápido e voa quase sem gastar energia.",
		scale = 0.85, health = 650, walk = 38, turbo = 75, jump = 90,
		canFly = true, flySpeed = 100, flyTurbo = 180, flyDrain = 2.5,
		weapon = "minigun", missiles = 2, punch = 0.8, energyRegen = 16, theme = 7,
	},
	{
		id = "berserker", name = "BERSERKER", role = "CORPO A CORPO",
		desc = "Lança-chamas e socos que derrubam prédios. O soco dá uma investida.",
		scale = 1.1, health = 1500, walk = 32, turbo = 62, jump = 85,
		canFly = false, flySpeed = 0, flyTurbo = 0, flyDrain = 0,
		weapon = "flame", missiles = 2, punch = 2.5, energyRegen = 16, theme = 2,
	},
}

---------------------------------------------------------------------------------------
-- ESTADO
---------------------------------------------------------------------------------------
local State = {
	gameState = "loading", -- loading | menu | playing | paused | gameover
	mode = "missao", -- missao | livre
	runId = 0,
	quality = 3,
	best = { missao = 0, livre = 0 },

	piloting = false,
	dead = false,
	health = 1000,
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
	combo = 0,
	comboTimer = 0,
	wave = 0,
	kills = 0,
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

	aimPoint = Vector3.zero,
	jetBoost = 0,
	waveTime = 0,
	punchTime = 0,
	dashTime = 0,
	destructArmed = 0,
	showHelp = false,

	cooldowns = { missile = 0, scan = 0, slam = 0, laser = 0, punch = 0 },
}

-- Funções compartilhadas entre as seções do script
local Game = {}
local UI = {}

-- O robô do jogador (preenchido por Game.setRobot)
local Mech = { index = 1, def = ROBOTS[1], scale = 1, rig = nil :: any, shield = nil :: any }

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

local function isPlaying()
	return State.gameState == "playing"
end

function Game.torsoCenter()
	return State.rootCF.Position + Vector3.new(0, 3.5 * Mech.scale, 0)
end

function Game.hip()
	return 5.6 * Mech.scale
end

---------------------------------------------------------------------------------------
-- PASTAS NO WORKSPACE
---------------------------------------------------------------------------------------
for _, name in ipairs({ "RoboTitan", "RoboTitan_Efeitos", "RoboTitan_Drones", "RoboTitan_Inimigos", "RoboTitan_Cidade", "RoboTitan_Escombros" }) do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local F = {
	robot = new("Folder", { Name = "RoboTitan", Parent = workspace }),
	effects = new("Folder", { Name = "RoboTitan_Efeitos", Parent = workspace }),
	enemies = new("Folder", { Name = "RoboTitan_Inimigos", Parent = workspace }),
	city = new("Folder", { Name = "RoboTitan_Cidade", Parent = workspace }),
	debris = new("Folder", { Name = "RoboTitan_Escombros", Parent = workspace }),
}

-- rayWorld: chão, paredes, câmera (ignora robô, efeitos, inimigos, escombros e o personagem)
-- rayAim: mira e armas (acerta inimigos e a cidade)
local rayWorld = RaycastParams.new()
rayWorld.FilterType = Enum.RaycastFilterType.Exclude
local rayAim = RaycastParams.new()
rayAim.FilterType = Enum.RaycastFilterType.Exclude

local function refreshFilters()
	local ignore = { F.robot, F.effects, F.debris }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	rayAim.FilterDescendantsInstances = ignore
	local worldIgnore = table.clone(ignore)
	table.insert(worldIgnore, F.enemies)
	rayWorld.FilterDescendantsInstances = worldIgnore
end
refreshFilters()

local cityOverlap = OverlapParams.new()
cityOverlap.FilterType = Enum.RaycastFilterType.Include
cityOverlap.FilterDescendantsInstances = { F.city }
cityOverlap.MaxParts = 600

local function findGroundY(pos)
	local hit = workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -600, 0), rayWorld)
	return hit and hit.Position.Y or pos.Y
end

---------------------------------------------------------------------------------------
-- SOM E EFEITOS
---------------------------------------------------------------------------------------
local FX = {}

function FX.sound(id, volume, pitch, position)
	if not id then
		return
	end
	local holder: Instance = workspace
	if position then
		holder = makePart({ Size = Vector3.one, Transparency = 1, Position = position, Parent = F.effects })
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

function FX.shake(amount, position)
	if position then
		local dist = (position - camera.CFrame.Position).Magnitude
		amount = amount * math.clamp(1 - dist / 250, 0, 1)
	end
	State.shake = math.min(State.shake + amount, 3)
end

function FX.spark(position, color, count, speed)
	local p = makePart({ Size = Vector3.one * 0.2, Transparency = 1, Position = position, Parent = F.effects })
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

function FX.dust(position, size, duration)
	local p = makePart({ Size = Vector3.one, Transparency = 1, Position = position, Parent = F.effects })
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

function FX.explosion(position, radius, color)
	color = color or Color3.fromRGB(255, 140, 30)
	local ball = makePart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one,
		Position = position,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.1,
		CastShadow = false,
		Parent = F.effects,
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
		Parent = F.effects,
	})
	TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, radius * 3, radius * 3),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.6)

	FX.spark(position, color, 40, 45)
	FX.spark(position, Color3.fromRGB(60, 60, 60), 20, 15)
	if CONFIG.QUALITY[State.quality].effects and radius >= 8 then
		FX.dust(position, radius * 0.8, 0.4)
	end
	FX.sound(CONFIG.SOUNDS.explosion, 1, 0.5 + math.random() * 0.2, position)
	FX.shake(radius / 12, position)
end

function FX.beam(from, to, color, width, duration)
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
		Parent = F.effects,
	})
	TweenService:Create(beam, TweenInfo.new(duration or 0.15), { Transparency = 1, Size = Vector3.new(0, 0, dist) }):Play()
	Debris:AddItem(beam, (duration or 0.15) + 0.05)
end

-- Números de dano que saltam do alvo
local activeNumbers = 0
function FX.damageNumber(position, amount, color)
	if activeNumbers > 25 or amount < 1 then
		return
	end
	activeNumbers += 1
	local anchor = makePart({ Size = Vector3.one * 0.2, Transparency = 1, Position = position, Parent = F.effects })
	local gui = new("BillboardGui", {
		Size = UDim2.fromOffset(90, 34),
		StudsOffset = Vector3.new(rand(-1, 1), 1, 0),
		AlwaysOnTop = true,
		Parent = anchor,
	})
	local text = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = tostring(math.floor(amount)),
		TextColor3 = color or Color3.fromRGB(255, 230, 90),
		TextStrokeTransparency = 0.2,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		Parent = gui,
	})
	TweenService:Create(gui, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 7, 0) }):Play()
	TweenService:Create(text, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.85, function()
		activeNumbers -= 1
		anchor:Destroy()
	end)
end

---------------------------------------------------------------------------------------
-- ILUMINAÇÃO E CÉU
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
local POST = {
	bloom = Lighting:FindFirstChild("RoboTitanBloom") or new("BloomEffect", { Name = "RoboTitanBloom", Intensity = 0.6, Size = 24, Threshold = 1.6, Parent = Lighting }),
	sunRays = Lighting:FindFirstChild("RoboTitanSol") or new("SunRaysEffect", { Name = "RoboTitanSol", Intensity = 0.06, Spread = 0.6, Parent = Lighting }),
	color = Lighting:FindFirstChild("RoboTitanCor") or new("ColorCorrectionEffect", { Name = "RoboTitanCor", Brightness = 0.02, Contrast = 0.08, Saturation = 0.12, Parent = Lighting }),
}
if workspace.Terrain and not workspace.Terrain:FindFirstChildOfClass("Clouds") then
	new("Clouds", { Cover = 0.55, Density = 0.6, Color = Color3.fromRGB(245, 245, 250), Parent = workspace.Terrain })
end

function Game.applyQuality()
	local q = CONFIG.QUALITY[State.quality]
	CITY.MAX_DEBRIS = q.debris
	CITY.INTERIOR_LOD = q.interior
	CITY.LIGHT_LOD = q.light
	Lighting.GlobalShadows = q.shadows
	POST.bloom.Enabled = q.effects
	POST.sunRays.Enabled = State.quality == 3
	POST.color.Enabled = q.effects
end
Game.applyQuality()

---------------------------------------------------------------------------------------
-- INTERFACE (HUD E MENUS)
---------------------------------------------------------------------------------------
do
	local playerGui = player:WaitForChild("PlayerGui")
	local oldGui = playerGui:FindFirstChild("RoboTitanHUD")
	if oldGui then
		oldGui:Destroy()
	end

	UI.accentStrokes = {}
	UI.accentTexts = {}

	local function corner(radius)
		return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
	end
	UI.corner = corner

	local function accentStroke(thickness)
		local s = new("UIStroke", { Color = THEMES[1].accent, Thickness = thickness or 1.5, Transparency = 0.15 })
		table.insert(UI.accentStrokes, s)
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
	UI.label = label

	local function makeButton(parent, text, position, callback, width)
		local button = new("TextButton", {
			Size = UDim2.fromOffset(width or 300, 50),
			Position = position,
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(20, 24, 34),
			AutoButtonColor = true,
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 19,
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
	UI.gui = gui

	-- Vinheta de dano
	UI.vignette = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = gui,
	})

	-- Container do HUD de jogo (escondido em menus)
	UI.hud = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })

	-- Painel principal
	UI.panel = new("Frame", {
		Size = UDim2.fromOffset(320, 238),
		Position = UDim2.fromOffset(16, 56),
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = 0.25,
		Parent = UI.hud,
	}, { corner(10), accentStroke(2) })
	UI.titleLabel = label({
		Size = UDim2.new(1, -24, 0, 26),
		Position = UDim2.fromOffset(12, 8),
		Text = "",
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		Parent = UI.panel,
	})
	table.insert(UI.accentTexts, UI.titleLabel)

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
		Position = UDim2.fromOffset(12, 198),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 70, 70),
		Text = "",
		Parent = UI.panel,
	})

	-- Objetivo (topo) e combo
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
	UI.comboLabel = label({
		Size = UDim2.fromOffset(240, 60),
		Position = UDim2.new(1, -24, 0, 60),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 40,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(255, 200, 40),
		TextStrokeTransparency = 0.2,
		Text = "",
		Parent = UI.hud,
	})

	-- Feed de abates (direita)
	UI.feed = new("Frame", {
		Size = UDim2.fromOffset(300, 200),
		Position = UDim2.new(1, -24, 0, 124),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Parent = UI.hud,
	}, {
		new("UIListLayout", {
			Padding = UDim.new(0, 4),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Barra de habilidades
	UI.SLOTS = {
		{ id = "weapon", key = "LMB", name = "" },
		{ id = "punch", key = "B", name = "Soco" },
		{ id = "missile", key = "E", name = "Mísseis" },
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
			SortOrder = Enum.SortOrder.LayoutOrder,
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
			TextSize = slot.key == "LMB" and 18 or 24,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 2,
			Parent = frame,
		})
		local nameLabel = label({
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.fromOffset(0, 40),
			Text = slot.name,
			TextSize = 11,
			TextScaled = false,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = Color3.fromRGB(190, 200, 215),
			ZIndex = 2,
			Parent = frame,
		})
		UI.slotUI[slot.id] = { frame = frame, overlay = overlay, stroke = stroke, name = nameLabel }
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
	UI.RADAR_RANGE = 300
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

	-- Painel de ajuda
	local HELP_TEXT = table.concat({
		"<b>V</b>  entrar / sair  (longe = convocar robô)",
		"<b>W A S D</b>  andar    <b>Mouse</b>  mirar",
		"<b>Botão esquerdo</b>  arma principal    <b>B</b>  soco",
		"<b>Espaço</b>  pular / impulso / subir",
		"<b>Ctrl</b>  descer no voo    <b>Shift</b>  turbo",
		"<b>F</b>  voo    <b>E</b>  mísseis teleguiados",
		"<b>Q</b>  escudo    <b>R</b>  scanner    <b>G</b>  impacto",
		"<b>L</b>  faróis    <b>C</b>  cor    <b>K</b>  acenar",
		"<b>T</b>  inimigos    <b>1-4</b>  trocar robô  (modo livre)",
		"<b>N</b>  dia/noite    <b>P</b>  pausar",
		"<b>X</b> (2x)  autodestruição    <b>H</b>  esta ajuda",
		"",
		"<i>Com turbo o robô atravessa paredes.</i>",
		"<i>Destrua a base de um prédio para derrubá-lo!</i>",
		"<i>Destruição seguida aumenta o COMBO de pontos.</i>",
	}, "\n")
	UI.helpPanel = new("Frame", {
		Size = UDim2.fromOffset(440, 430),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 30,
		Parent = gui,
	}, { corner(12), accentStroke(2) })
	label({
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.fromOffset(0, 8),
		Text = "CONTROLES",
		TextSize = 22,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 30,
		Parent = UI.helpPanel,
	})
	label({
		Size = UDim2.new(1, -40, 1, -90),
		Position = UDim2.fromOffset(20, 50),
		Text = HELP_TEXT,
		RichText = true,
		TextSize = 15,
		Font = Enum.Font.Gotham,
		LineHeight = 1.15,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 30,
		Parent = UI.helpPanel,
	})
	label({
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 1, -34),
		Text = "Aperte H para fechar",
		TextSize = 13,
		TextColor3 = Color3.fromRGB(150, 160, 180),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 30,
		Parent = UI.helpPanel,
	})

	-- Tela de carregamento
	UI.loadingFrame = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(6, 8, 12),
		ZIndex = 40,
		Parent = gui,
	})
	local loadingTitle = label({
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 0.5, -90),
		Text = "TITAN X-9",
		TextSize = 54,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 41,
		Parent = UI.loadingFrame,
	})
	table.insert(UI.accentTexts, loadingTitle)
	UI.loadingStatus = label({
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0.5, -20),
		Text = "CONSTRUINDO A CIDADE...",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(170, 180, 200),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 41,
		Parent = UI.loadingFrame,
	})
	local loadingBarBg = new("Frame", {
		Size = UDim2.fromOffset(400, 14),
		Position = UDim2.new(0.5, 0, 0.5, 20),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(25, 28, 36),
		ZIndex = 41,
		Parent = UI.loadingFrame,
	}, { corner(7) })
	UI.loadingBar = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = THEMES[1].accent,
		ZIndex = 42,
		Parent = loadingBarBg,
	}, { corner(7) })

	-- Menu principal (esquerda) + garagem (direita)
	UI.menuFrame = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 15,
		Parent = gui,
	})
	local left = new("Frame", {
		Size = UDim2.new(0, 460, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = UI.menuFrame,
	}, {
		new("UIGradient", {
			Transparency = NumberSequence.new(0, 1),
		}),
	})
	local menuTitle = label({
		Size = UDim2.new(1, -60, 0, 80),
		Position = UDim2.new(0, 40, 0.5, -270),
		Text = "TITAN X-9",
		TextSize = 70,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.4,
		Parent = left,
	})
	table.insert(UI.accentTexts, menuTitle)
	label({
		Size = UDim2.new(1, -60, 0, 30),
		Position = UDim2.new(0, 44, 0.5, -192),
		Text = "CIDADE EM RUÍNAS",
		TextSize = 24,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.4,
		Parent = left,
	})
	makeButton(left, "▶  MODO MISSÃO", UDim2.new(0, 190, 0.5, -130), function()
		task.spawn(Game.startGame, "missao")
	end)
	makeButton(left, "⚡  MODO LIVRE", UDim2.new(0, 190, 0.5, -70), function()
		task.spawn(Game.startGame, "livre")
	end)
	UI.qualityButton = makeButton(left, "GRÁFICOS: ALTO", UDim2.new(0, 190, 0.5, -10), function()
		State.quality = State.quality % #CONFIG.QUALITY + 1
		Game.applyQuality()
		UI.qualityButton.Text = "GRÁFICOS: " .. CONFIG.QUALITY[State.quality].name
	end)
	makeButton(left, "?  CONTROLES", UDim2.new(0, 190, 0.5, 50), function()
		State.showHelp = not State.showHelp
	end)
	UI.bestLabel = label({
		Size = UDim2.new(1, -60, 0, 60),
		Position = UDim2.new(0, 44, 0.5, 116),
		Text = "",
		TextSize = 15,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(200, 210, 225),
		TextStrokeTransparency = 0.5,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = left,
	})

	-- Garagem: cartão do robô
	local card = new("Frame", {
		Size = UDim2.fromOffset(380, 300),
		Position = UDim2.new(1, -30, 1, -30),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = 0.15,
		Parent = UI.menuFrame,
	}, { corner(12), accentStroke(2) })
	label({
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 10),
		Text = "GARAGEM",
		TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 160, 180),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})
	UI.robotName = label({
		Size = UDim2.new(1, -100, 0, 36),
		Position = UDim2.fromOffset(50, 32),
		Text = "",
		TextSize = 28,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})
	table.insert(UI.accentTexts, UI.robotName)
	UI.robotRole = label({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 68),
		Text = "",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(255, 200, 80),
		Parent = card,
	})
	UI.robotDesc = label({
		Size = UDim2.new(1, -40, 0, 44),
		Position = UDim2.fromOffset(20, 90),
		Text = "",
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(210, 215, 225),
		Parent = card,
	})
	local function arrow(text, x, delta)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.fromOffset(x, 30),
			BackgroundColor3 = Color3.fromRGB(20, 24, 34),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 22,
			Font = Enum.Font.GothamBlack,
			Parent = card,
		}, { corner(8), accentStroke(1.5) })
		b.MouseButton1Click:Connect(function()
			Game.setRobot((Mech.index - 1 + delta) % #ROBOTS + 1)
			Game.placeRobotInPlaza()
		end)
	end
	arrow("◀", 10, -1)
	arrow("▶", 330, 1)
	UI.statBars = {}
	for i, statName in ipairs({ "BLINDAGEM", "VELOCIDADE", "PODER DE FOGO", "MOBILIDADE" }) do
		local y = 142 + (i - 1) * 36
		label({
			Size = UDim2.fromOffset(140, 18),
			Position = UDim2.fromOffset(20, y),
			Text = statName,
			TextSize = 13,
			Parent = card,
		})
		local bg = new("Frame", {
			Size = UDim2.fromOffset(200, 12),
			Position = UDim2.fromOffset(160, y + 3),
			BackgroundColor3 = Color3.fromRGB(30, 34, 44),
			Parent = card,
		}, { corner(6) })
		UI.statBars[i] = new("Frame", {
			Size = UDim2.fromScale(0.5, 1),
			BackgroundColor3 = THEMES[1].accent,
			Parent = bg,
		}, { corner(6) })
	end

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
		Game.resumeGame()
	end)
	makeButton(UI.pauseFrame, "MENU PRINCIPAL", UDim2.new(0.5, 0, 0, 160), function()
		Game.showMenu()
	end)

	-- Fim de jogo
	UI.gameOverFrame = new("Frame", {
		Size = UDim2.fromOffset(440, 460),
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
		Size = UDim2.new(1, -40, 0, 210),
		Position = UDim2.fromOffset(20, 76),
		Text = "",
		TextSize = 17,
		Font = Enum.Font.GothamMedium,
		LineHeight = 1.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = UI.gameOverFrame,
	})
	makeButton(UI.gameOverFrame, "JOGAR DE NOVO", UDim2.new(0.5, 0, 0, 310), function()
		task.spawn(Game.startGame, State.mode)
	end)
	makeButton(UI.gameOverFrame, "MENU PRINCIPAL", UDim2.new(0.5, 0, 0, 376), function()
		Game.showMenu()
	end)
end

local notifyToken = 0
function Game.notify(text, color)
	notifyToken += 1
	local token = notifyToken
	UI.notifyLabel.Text = text
	UI.notifyLabel.TextColor3 = color or theme().accent
	UI.notifyLabel.TextTransparency = 0
	UI.notifyLabel.TextStrokeTransparency = 0.3
	task.delay(2.2, function()
		if token == notifyToken then
			TweenService:Create(UI.notifyLabel, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local feedOrder = 0
function Game.feed(text, color)
	feedOrder += 1
	local items = {}
	for _, c in ipairs(UI.feed:GetChildren()) do
		if c:IsA("TextLabel") then
			table.insert(items, c)
		end
	end
	if #items >= 6 then
		items[1]:Destroy()
	end
	local item = UI.label({
		Size = UDim2.fromOffset(300, 24),
		Text = text,
		TextSize = 17,
		Font = Enum.Font.GothamBlack,
		TextColor3 = color or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextStrokeTransparency = 0.3,
		LayoutOrder = feedOrder,
		Parent = UI.feed,
	})
	task.delay(2.5, function()
		if item.Parent then
			TweenService:Create(item, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			Debris:AddItem(item, 0.6)
		end
	end)
end

-- Pontos com combo: destruição seguida multiplica os pontos (até x5)
function Game.addScore(points, text, color)
	if not isPlaying() then
		return
	end
	State.combo += 1
	State.comboTimer = 3
	local mult = math.min(5, 1 + math.floor(State.combo / 10))
	State.score += points * mult
	if text then
		Game.feed(("+%d  %s"):format(points * mult, text), color)
	end
end

function Game.flashDamage(amount)
	UI.vignette.BackgroundTransparency = math.clamp(1 - amount, 0.55, 0.95)
	TweenService:Create(UI.vignette, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
end

function Game.flashHitmarker()
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
-- MONTAGEM DOS ROBÔS (usado pelo jogador e pelos robôs inimigos)
-- Cada peça pertence a uma "articulação". A posição final é:
--   mundo(articulação) * posiçãoLocalDaPeça
---------------------------------------------------------------------------------------
local Rig = {}
local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local AXIS_Y = CFrame.Angles(0, 0, math.rad(90)) -- cilindro em pé
local AXIS_Z = CFrame.Angles(0, math.rad(90), 0) -- cilindro apontando pra frente

do
	local BASE_JOINTS = {
		torso = { parent = "root", offset = Vector3.new(0, 0, 0) },
		head = { parent = "torso", offset = Vector3.new(0, 5.2, 0) },
		armL = { parent = "torso", offset = Vector3.new(-3.4, 4.3, 0) },
		armR = { parent = "torso", offset = Vector3.new(3.4, 4.3, 0) },
		legL = { parent = "root", offset = Vector3.new(-1.4, 0, 0) },
		legR = { parent = "root", offset = Vector3.new(1.4, 0, 0) },
		jet = { parent = "torso", offset = Vector3.new(0, 3.2, 2) },
		shoulder = { parent = "torso", offset = Vector3.new(-2.3, 5.6, 0.4) },
		shoulderR = { parent = "torso", offset = Vector3.new(2.3, 5.6, 0.4) },
	}
	local JOINT_ORDER = { "torso", "head", "armL", "armR", "legL", "legR", "jet", "shoulder", "shoulderR" }
	local AIMED = { armR = true, shoulder = true, shoulderR = true }
	local ROLE_MATERIAL = {
		primary = Enum.Material.Metal,
		secondary = Enum.Material.DiamondPlate,
		dark = Enum.Material.SmoothPlastic,
		accent = Enum.Material.Neon,
		hidden = Enum.Material.SmoothPlastic,
	}
	Rig.JOINT_ORDER = JOINT_ORDER

	function Rig.build(def, colors, parent, queryable)
		local s = def.scale
		local rig = {
			def = def,
			scale = s,
			hip = 5.6 * s,
			model = new("Model", { Name = def.name, Parent = parent }),
			pieces = {},
			parts = {},
			cframes = {},
			joints = {},
			anim = {},
			world = {},
			jetEmitters = {},
			jetLights = {},
			pods = {},
			walkPhase = 0,
			lastStep = 1,
		}
		for name, j in pairs(BASE_JOINTS) do
			rig.joints[name] = { parent = j.parent, offset = CFrame.new(j.offset * s) }
		end
		for _, n in ipairs(JOINT_ORDER) do
			rig.anim[n] = CFrame.identity
		end

		local function add(joint, name, size, localCF, role, shape)
			local part = makePart({
				Name = name,
				Size = size * s,
				Shape = shape or Enum.PartType.Block,
				Material = ROLE_MATERIAL[role],
				Transparency = role == "hidden" and 1 or 0,
				CastShadow = role ~= "accent" and role ~= "hidden",
				CanQuery = queryable == true and role ~= "hidden",
				Parent = rig.model,
			})
			local lcf = CFrame.new(localCF.Position * s) * localCF.Rotation
			table.insert(rig.pieces, { part = part, joint = joint, localCF = lcf, role = role, baseTransparency = part.Transparency })
			table.insert(rig.parts, part)
			return part
		end
		local style = def.id

		-- Pernas
		for _, j in ipairs({ "legL", "legR" }) do
			add(j, "Quadril", Vector3.one * 1.8, CFrame.new(), "secondary", BALL)
			add(j, "Coxa", Vector3.new(1.6, 2.6, 1.8), CFrame.new(0, -1.5, 0), "primary")
			add(j, "Joelho", Vector3.new(1.9, 1.3, 1.3), CFrame.new(0, -2.9, -0.1), "secondary", CYL)
			add(j, "LuzJoelho", Vector3.new(0.4, 0.4, 0.2), CFrame.new(0, -2.9, -0.95), "accent")
			add(j, "Canela", Vector3.new(1.5, 2.4, 1.7), CFrame.new(0, -4.2, 0), "primary")
			add(j, "Pistao", Vector3.new(0.3, 2, 0.3), CFrame.new(0, -4.1, 1), "dark")
			add(j, "Pe", Vector3.new(2, 0.8, 3), CFrame.new(0, -5.2, -0.4), "secondary")
			add(j, "Dedo", Vector3.new(2, 0.5, 0.6), CFrame.new(0, -5.35, -2.1), "primary")
			if style == "golias" then
				add(j, "Joelheira", Vector3.new(2, 1.5, 0.6), CFrame.new(0, -2.9, -1.1), "primary")
				add(j, "Caneleira", Vector3.new(1.9, 2, 0.4), CFrame.new(0, -4.3, -1), "secondary")
			end
		end

		-- Tronco
		add("torso", "Pelvis", Vector3.new(3.6, 1.2, 2.4), CFrame.new(0, 0.3, 0), "secondary")
		add("torso", "Abdomen", Vector3.new(3, 1.6, 2.2), CFrame.new(0, 1.6, 0), "dark")
		add("torso", "Peito", Vector3.new(5.2, 3, 3.2), CFrame.new(0, 3.8, 0), "primary")
		add("torso", "Placa", Vector3.new(3.6, 2, 0.3), CFrame.new(0, 3.9, -1.7), "secondary")
		local core = add("torso", "Nucleo", Vector3.new(0.4, 1.4, 1.4), CFrame.new(0, 3.9, -1.9) * AXIS_Z, "accent", CYL)
		add("torso", "Pescoco", Vector3.new(1, 1, 1), CFrame.new(0, 5.3, 0) * AXIS_Y, "dark", CYL)
		add("torso", "VentL", Vector3.new(0.1, 1.6, 0.3), CFrame.new(-2.65, 3.7, -0.8), "accent")
		add("torso", "VentR", Vector3.new(0.1, 1.6, 0.3), CFrame.new(2.65, 3.7, -0.8), "accent")
		if style == "golias" then
			add("torso", "OmbreiraL", Vector3.new(2.8, 1.5, 3.6), CFrame.new(-3.6, 5.4, 0), "primary")
			add("torso", "OmbreiraR", Vector3.new(2.8, 1.5, 3.6), CFrame.new(3.6, 5.4, 0), "primary")
			add("torso", "Blindagem", Vector3.new(6, 2.2, 3.8), CFrame.new(0, 3.3, -0.1), "secondary")
			add("torso", "Saia", Vector3.new(4.4, 1, 3), CFrame.new(0, -0.3, 0), "secondary")
		else
			add("torso", "OmbreiraL", Vector3.new(1.9, 1, 2.8), CFrame.new(-3.3, 5.2, 0), "primary")
			add("torso", "OmbreiraR", Vector3.new(1.9, 1, 2.8), CFrame.new(3.3, 5.2, 0), "primary")
		end
		if style == "berserker" then
			for _, x in ipairs({ -3.3, 3.3 }) do
				for _, z in ipairs({ -0.8, 0.8 }) do
					add("torso", "Espinho", Vector3.new(0.4, 1.4, 0.4), CFrame.new(x, 6.1, z) * CFrame.Angles(0, 0, x > 0 and -0.3 or 0.3), "dark")
				end
			end
		end
		rig.coreLight = new("PointLight", { Range = 14 * s, Brightness = 2, Parent = core })
		rig.smoke = new("ParticleEmitter", {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(40, 40, 40)),
			Size = NumberSequence.new(1 * s, 4 * s),
			Transparency = NumberSequence.new(0.3, 1),
			Lifetime = NumberRange.new(1.5, 2.5),
			Speed = NumberRange.new(4, 8),
			Rate = 12,
			Enabled = false,
			Parent = core,
		})

		-- Cabeça
		add("head", "Cabeca", Vector3.new(2.4, 1.8, 2.4), CFrame.new(0, 0.9, 0), "primary")
		local visor = add("head", "Visor", Vector3.new(2, 0.5, 0.2), CFrame.new(0, 1, -1.25), "accent")
		add("head", "Mandibula", Vector3.new(1.8, 0.5, 0.4), CFrame.new(0, 0.3, -1.1), "secondary")
		add("head", "Crista", Vector3.new(0.4, 0.5, 2.2), CFrame.new(0, 2, 0), "secondary")
		add("head", "Antena", Vector3.new(0.15, 1.4, 0.15), CFrame.new(0.8, 2.4, 0.4), "dark")
		add("head", "PontaAntena", Vector3.one * 0.4, CFrame.new(0.8, 3.1, 0.4), "accent", BALL)
		if style == "berserker" then
			add("head", "ChifreL", Vector3.new(0.4, 1.8, 0.4), CFrame.new(-1.2, 2.2, -0.2) * CFrame.Angles(0, 0, 0.5), "dark")
			add("head", "ChifreR", Vector3.new(0.4, 1.8, 0.4), CFrame.new(1.2, 2.2, -0.2) * CFrame.Angles(0, 0, -0.5), "dark")
		elseif style == "falcao" then
			add("head", "Barbatana", Vector3.new(0.2, 1.2, 2), CFrame.new(0, 2.3, 0.3), "accent")
		end
		rig.headlight = new("SpotLight", { Face = Enum.NormalId.Front, Range = 60, Angle = 60, Brightness = 4, Parent = visor })

		-- Braços
		for _, side in ipairs({ "armL", "armR" }) do
			add(side, "Ombro", Vector3.one * 1.8, CFrame.new(), "secondary", BALL)
			add(side, "Braco", Vector3.new(1.4, 2.4, 1.4), CFrame.new(0, -1.6, 0), "primary")
			add(side, "Cotovelo", Vector3.one * 1.3, CFrame.new(0, -3, 0), "secondary", BALL)
			add(side, "Antebraco", Vector3.new(1.7, 2.4, 1.8), CFrame.new(0, -4.3, 0), "primary")
			add(side, "Faixa", Vector3.new(1.75, 0.25, 1.85), CFrame.new(0, -4.8, 0), "accent")
		end
		if style == "berserker" then
			add("armL", "Punho", Vector3.new(2.2, 2, 2.2), CFrame.new(0, -6.2, 0), "secondary")
			add("armL", "Soqueira", Vector3.new(2.3, 0.5, 0.6), CFrame.new(0, -6.9, -0.9), "accent")
		else
			add("armL", "Garra", Vector3.new(1.2, 1, 1.2), CFrame.new(0, -5.9, 0), "secondary")
			add("armL", "Dedo1", Vector3.new(0.3, 0.9, 0.3), CFrame.new(0.35, -6.7, -0.3), "dark")
			add("armL", "Dedo2", Vector3.new(0.3, 0.9, 0.3), CFrame.new(-0.35, -6.7, -0.3), "dark")
			add("armL", "Dedo3", Vector3.new(0.3, 0.9, 0.3), CFrame.new(0, -6.7, 0.4), "dark")
		end

		-- Arma no braço direito
		local weapon = def.weapon
		local muzzleY = 7.8
		if weapon == "plasma" then
			add("armR", "CanhaoPlasma", Vector3.new(3.4, 1.7, 1.7), CFrame.new(0, -6.6, 0) * AXIS_Y, "dark", CYL)
			add("armR", "Bobina1", Vector3.new(0.3, 2, 2), CFrame.new(0, -5.9, 0) * AXIS_Y, "accent", CYL)
			add("armR", "Bobina2", Vector3.new(0.3, 2, 2), CFrame.new(0, -7.3, 0) * AXIS_Y, "accent", CYL)
			muzzleY = 8.6
		elseif weapon == "minigun" then
			add("armR", "Carcaca", Vector3.new(1, 1.4, 1.4), CFrame.new(0, -5.6, 0) * AXIS_Y, "dark", CYL)
			for k = 0, 2 do
				local a = k / 3 * math.pi * 2
				add("armR", "Cano", Vector3.new(0.3, 3.2, 0.3), CFrame.new(math.cos(a) * 0.4, -7.2, math.sin(a) * 0.4), "secondary")
			end
			add("armR", "Boca", Vector3.new(0.3, 1.3, 1.3), CFrame.new(0, -8.7, 0) * AXIS_Y, "accent", CYL)
			muzzleY = 8.9
		elseif weapon == "flame" then
			add("armR", "Bocal", Vector3.new(2, 1.1, 1.1), CFrame.new(0, -6.1, 0) * AXIS_Y, "dark", CYL)
			add("armR", "Chama", Vector3.new(0.3, 1.3, 1.3), CFrame.new(0, -7.2, 0) * AXIS_Y, "accent", CYL)
			add("armR", "TanqueBraco", Vector3.new(2, 0.8, 0.8), CFrame.new(0, -4.3, 1.1) * AXIS_Y, "secondary", CYL)
			muzzleY = 7.6
		else
			add("armR", "Canhao", Vector3.new(0.9, 2.4, 0.9), CFrame.new(0, -6.2, 0) * AXIS_Y, "dark", CYL)
			add("armR", "BocaCanhao", Vector3.new(1.2, 0.3, 1.2), CFrame.new(0, -7.4, 0) * AXIS_Y, "accent", CYL)
		end
		rig.muzzleOffset = CFrame.new(0, -muzzleY * s, 0)
		local muzzle = add("armR", "Saida", Vector3.one * 0.2, CFrame.new(0, -muzzleY, 0), "hidden")
		if weapon == "flame" then
			rig.flame = new("ParticleEmitter", {
				Texture = "rbxasset://textures/particles/fire_main.dds",
				Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 60, 20)),
				LightEmission = 1,
				Size = NumberSequence.new(1.5 * s, 6 * s),
				Transparency = NumberSequence.new(0.1, 1),
				Lifetime = NumberRange.new(0.5, 0.7),
				Speed = NumberRange.new(70, 90),
				SpreadAngle = Vector2.new(10, 10),
				EmissionDirection = Enum.NormalId.Bottom,
				Rate = 120,
				Enabled = false,
				Parent = muzzle,
			})
		end
		rig.muzzleLight = new("PointLight", { Range = 16 * s, Brightness = 0, Parent = muzzle })

		-- Jetpack
		add("jet", "Mochila", Vector3.new(3, 3, 1.4), CFrame.new(0, 0, 0.3), "secondary")
		if style == "berserker" then
			add("jet", "TanqueL", Vector3.new(2.6, 0.9, 0.9), CFrame.new(-0.8, 0.1, 1.2) * AXIS_Y, "primary", CYL)
			add("jet", "TanqueR", Vector3.new(2.6, 0.9, 0.9), CFrame.new(0.8, 0.1, 1.2) * AXIS_Y, "primary", CYL)
		else
			add("jet", "Tanque", Vector3.new(0.8, 2.6, 0.8), CFrame.new(0, 0.1, 1.1) * AXIS_Y, "primary", CYL)
		end
		if style == "falcao" then
			add("jet", "AsaL", Vector3.new(4.6, 0.25, 1.6), CFrame.new(-2.6, 0.6, 0.5) * CFrame.Angles(0, 0, math.rad(20)), "primary")
			add("jet", "AsaR", Vector3.new(4.6, 0.25, 1.6), CFrame.new(2.6, 0.6, 0.5) * CFrame.Angles(0, 0, math.rad(-20)), "primary")
			add("jet", "PontaAsaL", Vector3.new(0.3, 0.3, 1.7), CFrame.new(-4.8, 1.4, 0.5), "accent")
			add("jet", "PontaAsaR", Vector3.new(0.3, 0.3, 1.7), CFrame.new(4.8, 1.4, 0.5), "accent")
		end
		add("jet", "BocalL", Vector3.new(1, 1, 1), CFrame.new(-0.9, -1.8, 0.4) * AXIS_Y, "dark", CYL)
		add("jet", "BocalR", Vector3.new(1, 1, 1), CFrame.new(0.9, -1.8, 0.4) * AXIS_Y, "dark", CYL)
		for _, x in ipairs({ -0.9, 0.9 }) do
			local anchor = add("jet", "Jato", Vector3.one * 0.3, CFrame.new(x, -2.4, 0.4), "hidden")
			table.insert(rig.jetEmitters, new("ParticleEmitter", {
				Texture = "rbxasset://textures/particles/fire_main.dds",
				LightEmission = 1,
				Size = NumberSequence.new(1.2 * s, 0),
				Lifetime = NumberRange.new(0.15, 0.3),
				Speed = NumberRange.new(25, 35),
				SpreadAngle = Vector2.new(8, 8),
				EmissionDirection = Enum.NormalId.Bottom,
				Rate = 90,
				Enabled = false,
				Parent = anchor,
			}))
			table.insert(rig.jetLights, new("PointLight", { Range = 12 * s, Brightness = 3, Enabled = false, Parent = anchor }))
		end

		-- Lançadores de mísseis nos ombros
		local function launcher(joint)
			add(joint, "BaseLancador", Vector3.new(1.2, 0.8, 1.2), CFrame.new(), "dark")
			add(joint, "Lancador", Vector3.new(1.6, 1, 2.2), CFrame.new(0, 0.8, 0), "primary")
			add(joint, "Tubo1", Vector3.new(0.35, 0.35, 0.1), CFrame.new(-0.4, 0.8, -1.15), "accent")
			add(joint, "Tubo2", Vector3.new(0.35, 0.35, 0.1), CFrame.new(0.4, 0.8, -1.15), "accent")
			table.insert(rig.pods, { joint = joint, offset = CFrame.new(-0.4 * s, 0.8 * s, -1.5 * s) })
			table.insert(rig.pods, { joint = joint, offset = CFrame.new(0.4 * s, 0.8 * s, -1.5 * s) })
		end
		launcher("shoulder")
		if (def.missiles or 2) >= 4 then
			launcher("shoulderR")
		end

		return rig
	end

	function Rig.paint(rig, t)
		for _, p in ipairs(rig.pieces) do
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
		rig.coreLight.Color = t.accent
		rig.headlight.Color = t.accent:Lerp(Color3.new(1, 1, 1), 0.7)
		rig.muzzleLight.Color = t.accent
		for _, l in ipairs(rig.jetLights) do
			l.Color = t.accent
		end
		for _, e in ipairs(rig.jetEmitters) do
			e.Color = ColorSequence.new(t.accent, Color3.fromRGB(255, 120, 20))
		end
	end

	function Rig.setVisible(rig, visible)
		for _, p in ipairs(rig.pieces) do
			p.part.Transparency = visible and p.baseTransparency or 1
		end
	end

	-- Calcula onde cada articulação está no mundo. Com aimPoint, o braço
	-- direito e os lançadores apontam para a mira.
	function Rig.compute(rig, rootCF, aimPoint)
		local w = rig.world
		w.root = rootCF
		for _, name in ipairs(JOINT_ORDER) do
			local j = rig.joints[name]
			local base = w[j.parent] * j.offset
			local a = rig.anim[name]
			if aimPoint and AIMED[name] and (aimPoint - base.Position).Magnitude > 6 * rig.scale then
				local look = CFrame.lookAt(base.Position, aimPoint)
				if name == "armR" then
					-- o braço aponta para baixo (-Y); gira 90° para apontar para a mira
					w[name] = look * CFrame.Angles(math.rad(90), 0, 0) * a
				else
					w[name] = look * a
				end
			else
				w[name] = base * a
			end
		end
	end

	function Rig.apply(rig)
		for i, p in ipairs(rig.pieces) do
			rig.cframes[i] = rig.world[p.joint] * p.localCF
		end
		workspace:BulkMoveTo(rig.parts, rig.cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end

	function Rig.muzzle(rig)
		return (rig.world.armR * rig.muzzleOffset).Position
	end

	-- Animação procedural. st = { vel, rootCF, onGround, flying, aiming, aimPoint,
	-- waving, punching, slamming, turbo, jetBoost, dead, clock }
	-- Retorna true quando o robô dá um passo.
	function Rig.animate(rig, dt, st)
		local vel = st.vel
		local localVel = st.rootCF:VectorToObjectSpace(vel)
		local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		local walkRef = 28 * rig.scale
		local amount = math.clamp(speed / walkRef, 0, 1.4)
		local clock = st.clock
		local target = {}
		local stepped = false

		if st.onGround and not st.flying then
			rig.walkPhase += dt * speed * 0.3 / rig.scale
			local s = math.sin(rig.walkPhase)
			target.legL = CFrame.Angles(s * 0.6 * amount, 0, 0)
			target.legR = CFrame.Angles(-s * 0.6 * amount, 0, 0)
			target.armL = CFrame.Angles(-s * 0.5 * amount, 0, -0.08)
			target.armR = CFrame.Angles(s * 0.5 * amount, 0, 0.08)
			local bob = (math.abs(math.cos(rig.walkPhase)) * 0.35 * amount + math.sin(clock * 2) * 0.05) * rig.scale
			target.torso = CFrame.new(0, bob, 0) * CFrame.Angles(localVel.Z * 0.004, 0, -localVel.X * 0.004)
			local sign = s >= 0 and 1 or -1
			if sign ~= rig.lastStep and speed > 3 then
				rig.lastStep = sign
				stepped = true
			end
		elseif st.flying then
			target.legL = CFrame.Angles(-0.35 + math.sin(clock * 3) * 0.05, 0, 0)
			target.legR = CFrame.Angles(-0.25 + math.sin(clock * 3 + 1) * 0.05, 0, 0)
			target.armL = CFrame.Angles(-0.2, 0, -0.25)
			target.armR = CFrame.Angles(-0.2, 0, 0.25)
			target.torso = CFrame.new(0, math.sin(clock * 2) * 0.3, 0) * CFrame.Angles(localVel.Z * 0.006, 0, -localVel.X * 0.006)
		else
			target.legL = CFrame.Angles(0.4, 0, 0)
			target.legR = CFrame.Angles(-0.2, 0, 0)
			target.armL = CFrame.Angles(0.3, 0, -0.5)
			target.armR = CFrame.Angles(0.3, 0, 0.5)
			target.torso = CFrame.Angles(localVel.Z * 0.004, 0, 0)
		end

		if st.waving then
			target.armL = CFrame.Angles(0, 0, -2.6 + math.sin(clock * 12) * 0.35)
		end
		if st.punching then
			-- braço esquerdo esticado para a frente
			target.armL = CFrame.Angles(math.rad(95), 0, 0.15)
			target.torso = (target.torso or CFrame.identity) * CFrame.Angles(0, 0.35, 0)
		end

		if st.aiming then
			local headPos = (st.rootCF * CFrame.new(0, 6 * rig.scale, 0)).Position
			local dir = st.aimPoint - headPos
			if dir.Magnitude > 1 then
				local localDir = st.rootCF:VectorToObjectSpace(dir.Unit)
				local pitch = math.clamp(math.asin(math.clamp(localDir.Y, -1, 1)), -0.5, 0.6)
				local yaw = math.clamp(math.atan2(-localDir.X, -localDir.Z), -0.8, 0.8)
				target.head = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
			end
			target.armR = CFrame.identity -- o braço direito é apontado pela mira
			target.shoulder = CFrame.identity
			target.shoulderR = CFrame.identity
		else
			target.head = CFrame.Angles(math.sin(clock * 0.7) * 0.1, math.sin(clock * 0.5) * 0.4, 0)
			target.shoulder = CFrame.Angles(0, math.sin(clock * 0.5) * 0.3, 0)
			target.shoulderR = CFrame.Angles(0, -math.sin(clock * 0.5) * 0.3, 0)
		end
		target.jet = CFrame.Angles(st.flying and 0.25 or 0, 0, 0)

		local alpha = math.min(1, dt * (st.punching and 25 or 12))
		for _, name in ipairs(JOINT_ORDER) do
			rig.anim[name] = rig.anim[name]:Lerp(target[name] or CFrame.identity, alpha)
		end

		local jetOn = not st.dead and (st.flying or (st.jetBoost or 0) > 0 or st.slamming or (st.turbo and st.onGround))
		for _, e in ipairs(rig.jetEmitters) do
			e.Enabled = jetOn
		end
		for _, l in ipairs(rig.jetLights) do
			l.Enabled = jetOn
		end
		rig.coreLight.Brightness = 1.5 + math.sin(clock * 4) * 0.8
		rig.muzzleLight.Brightness = math.max(0, rig.muzzleLight.Brightness - dt * 30)
		return stepped
	end
end

---------------------------------------------------------------------------------------
-- ROBÔ DO JOGADOR
---------------------------------------------------------------------------------------
function Game.applyTheme()
	local t = theme()
	if Mech.rig then
		Rig.paint(Mech.rig, t)
	end
	if Mech.shield then
		Mech.shield.Color = t.accent
	end
	for _, s in ipairs(UI.accentStrokes) do
		s.Color = t.accent
	end
	for _, l in ipairs(UI.accentTexts) do
		l.TextColor3 = t.accent
	end
	for _, b in ipairs(UI.statBars) do
		b.BackgroundColor3 = t.accent
	end
	UI.loadingBar.BackgroundColor3 = t.accent
end

function Game.updateGarage()
	local def = Mech.def
	local firepower = { laser = 0.6, plasma = 1, minigun = 0.75, flame = 0.85 }
	UI.robotName.Text = def.name
	UI.robotRole.Text = def.role .. "  •  " .. CONFIG.WEAPONS[def.weapon].name
	UI.robotDesc.Text = def.desc
	local stats = {
		def.health / 2200,
		def.turbo / 75,
		firepower[def.weapon] * (0.8 + def.missiles * 0.05),
		def.canFly and def.flyTurbo / 180 or def.jump / 140,
	}
	for i, v in ipairs(stats) do
		UI.statBars[i].Size = UDim2.fromScale(math.clamp(v, 0.08, 1), 1)
	end
	UI.titleLabel.Text = "◆ " .. def.name
	UI.slotUI.weapon.name.Text = CONFIG.WEAPONS[def.weapon].name
end

function Game.setRobot(index)
	if Mech.rig then
		Mech.rig.model:Destroy()
	end
	if Mech.shield then
		Mech.shield:Destroy()
	end
	Mech.index = index
	Mech.def = ROBOTS[index]
	Mech.scale = Mech.def.scale
	State.themeIndex = Mech.def.theme
	Mech.rig = Rig.build(Mech.def, theme(), F.robot, false)
	Mech.shield = makePart({
		Name = "Escudo",
		Shape = BALL,
		Size = Vector3.one * 17 * Mech.scale,
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CastShadow = false,
		Parent = F.robot,
	})
	State.health = Mech.def.health
	State.flying = false
	Game.applyTheme()
	Game.updateGarage()
	Rig.compute(Mech.rig, State.rootCF, nil)
	Rig.apply(Mech.rig)
end
Game.setRobot(1)

---------------------------------------------------------------------------------------
-- CIDADE
-- Cada coisa destrutível é uma "unidade" (parede, laje, poste, carro...) formada
-- por uma ou mais peças. City.partInfo liga cada peça à sua unidade.
---------------------------------------------------------------------------------------
local City = {
	generation = 0,
	generating = false,
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
	fires = 0,
	dirty = false,
	isNight = false,
	folders = {} :: any,
}

do
	local BUILDING_STYLES = {
		{ wall = Color3.fromRGB(190, 185, 175), trim = Color3.fromRGB(120, 118, 112), glass = Color3.fromRGB(110, 150, 190), material = Enum.Material.Concrete },
		{ wall = Color3.fromRGB(150, 80, 60), trim = Color3.fromRGB(90, 85, 80), glass = Color3.fromRGB(90, 120, 150), material = Enum.Material.Brick },
		{ wall = Color3.fromRGB(70, 80, 95), trim = Color3.fromRGB(45, 50, 60), glass = Color3.fromRGB(80, 170, 220), material = Enum.Material.Metal },
		{ wall = Color3.fromRGB(225, 220, 205), trim = Color3.fromRGB(160, 150, 130), glass = Color3.fromRGB(120, 140, 160), material = Enum.Material.SmoothPlastic },
		{ wall = Color3.fromRGB(120, 125, 130), trim = Color3.fromRGB(80, 82, 88), glass = Color3.fromRGB(60, 200, 190), material = Enum.Material.Concrete },
		{ wall = Color3.fromRGB(200, 170, 120), trim = Color3.fromRGB(130, 110, 80), glass = Color3.fromRGB(100, 130, 170), material = Enum.Material.Sandstone },
		{ wall = Color3.fromRGB(95, 60, 55), trim = Color3.fromRGB(60, 45, 40), glass = Color3.fromRGB(150, 170, 190), material = Enum.Material.Brick },
	}
	local CAR_COLORS = {
		Color3.fromRGB(200, 30, 30),
		Color3.fromRGB(30, 80, 200),
		Color3.fromRGB(240, 240, 240),
		Color3.fromRGB(25, 25, 28),
		Color3.fromRGB(240, 190, 20),
		Color3.fromRGB(40, 150, 70),
		Color3.fromRGB(150, 150, 160),
		Color3.fromRGB(255, 120, 20),
	}
	local ADS = {
		{ text = "ROBO-COLA", color = Color3.fromRGB(255, 50, 50) },
		{ text = "TITAN CORP", color = Color3.fromRGB(0, 200, 255) },
		{ text = "PIZZA 24H", color = Color3.fromRGB(255, 160, 30) },
		{ text = "MEGA SHOP", color = Color3.fromRGB(255, 60, 220) },
		{ text = "NEO BANK", color = Color3.fromRGB(80, 255, 120) },
		{ text = "CYBER TV", color = Color3.fromRGB(180, 100, 255) },
		{ text = "HOTEL LUX", color = Color3.fromRGB(255, 220, 90) },
	}
	local AXES = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
	local WINDOW_NIGHT = Color3.fromRGB(255, 215, 140)
	local FH = CITY.FLOOR_H
	local WOOD = Color3.fromRGB(140, 100, 60)
	local DARK_METAL = Color3.fromRGB(60, 60, 66)
	City.AXES = AXES
	City.CAR_COLORS = CAR_COLORS

	-- Cria uma peça da cidade (pausando de vez em quando só durante a geração)
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

	-----------------------------------------------------------------------------------
	-- Destruição
	-----------------------------------------------------------------------------------
	local function spawnDebris(part, impactPos)
		if part.Transparency >= 1 then
			return
		end
		local size = part.Size
		local volume = size.X * size.Y * size.Z
		local count = math.clamp(math.floor(volume / 60), 1, State.quality == 1 and 2 or 4)
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
				Parent = F.debris,
			})
			local dir = cf.Position - impactPos
			dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
			chunk.AssemblyLinearVelocity = dir * rand(15, 45) + Vector3.new(0, rand(10, 30), 0)
			chunk.AssemblyAngularVelocity = Vector3.new(rand(-6, 6), rand(-6, 6), rand(-6, 6))
			table.insert(City.debris, { part = chunk, time = os.clock() })
		end
	end

	local function makeFire(position)
		if City.fires >= CITY.MAX_FIRES or not CONFIG.QUALITY[State.quality].effects then
			return
		end
		City.fires += 1
		local p = makePart({ Size = Vector3.one, Transparency = 1, Position = position, Parent = F.effects })
		new("Fire", { Size = rand(6, 10), Heat = 12, Parent = p })
		new("ParticleEmitter", {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(35, 35, 35)),
			Size = NumberSequence.new(4, 12),
			Transparency = NumberSequence.new(0.4, 1),
			Lifetime = NumberRange.new(3, 5),
			Speed = NumberRange.new(6, 10),
			Rate = 6,
			Parent = p,
		})
		new("PointLight", { Color = Color3.fromRGB(255, 140, 40), Range = 18, Brightness = 2, Parent = p })
		local gen = City.generation
		task.delay(25, function()
			p:Destroy()
			if City.generation == gen then
				City.fires -= 1
			end
		end)
	end

	City.makeFire = makeFire

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
		Game.addScore(5)
		local b = unit.building
		if b and not b.collapsed and unit.mass > 0 then
			b.lostMass += unit.mass
			City.lostMass += unit.mass
			if unit.ground then
				b.groundLost += 1
			end
			if math.random() < 0.12 then
				makeFire(origin)
			end
			if b.lostMass / b.totalMass >= CITY.COLLAPSE_RATIO
				or (b.groundTotal > 0 and b.groundLost / b.groundTotal >= CITY.GROUND_COLLAPSE_RATIO)
			then
				City.collapseBuilding(b)
			end
		end
		if unit.onBreak then
			unit.onBreak(unit, origin)
		end
	end

	function City.damageUnit(unit, amount, position)
		if unit.broken then
			return
		end
		unit.hp -= amount
		if unit.glass and unit.hp < unit.maxHp * 0.75 then
			local glass = unit.glass
			unit.glass = nil
			City.partInfo[glass] = nil
			if glass.Parent then
				FX.spark(glass.Position, Color3.fromRGB(200, 230, 255), 12, 20)
				glass:Destroy()
			end
		end
		if unit.hp <= 0 then
			breakUnit(unit, position)
		end
	end

	function City.damageCity(position, radius, amount)
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
			City.damageUnit(unit, amount * falloff, position)
		end
	end

	local function spawnRubble(b)
		local color = b.style.wall:Lerp(Color3.fromRGB(80, 80, 80), 0.4)
		for _ = 1, 10 do
			local s = Vector3.new(rand(6, 14), rand(3, 7), rand(6, 14))
			local cf = b.cf * CFrame.new(rand(-0.4, 0.4) * b.w, s.Y * 0.3, rand(-0.4, 0.4) * b.d)
				* CFrame.Angles(rand(-0.3, 0.3), rand(0, 3), rand(-0.3, 0.3))
			cityPart(City.folders.ground, s, cf, color, b.style.material)
		end
		makeFire(b.cf.Position + Vector3.new(0, 4, 0))
	end

	function City.collapseBuilding(b)
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
		for _, c in ipairs({ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }) do
			FX.dust(base + Vector3.new(c.X * b.w / 2, 2, c.Z * b.d / 2), 18, 3)
		end
		FX.dust(base + Vector3.new(0, b.height * 0.5, 0), 25, 2)
		FX.sound(CONFIG.SOUNDS.explosion, 1, 0.3, base)
		FX.shake(2.5, base)
		if isPlaying() then
			Game.addScore(500, "PRÉDIO DERRUBADO", Color3.fromRGB(255, 190, 60))
			Game.notify("PRÉDIO DESMORONOU!", Color3.fromRGB(255, 190, 60))
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
		FX.explosion(origin, 12, Color3.fromRGB(255, 120, 30))
		local wreck = makePart({
			Size = Vector3.new(5, 1.5, 9),
			CFrame = CFrame.new(origin),
			Color = Color3.fromRGB(30, 28, 26),
			Material = Enum.Material.CorrodedMetal,
			CanCollide = true,
			Parent = F.effects,
		})
		new("Fire", { Size = 6, Heat = 8, Parent = wreck })
		Debris:AddItem(wreck, 10)
		Game.addScore(50, "CARRO", Color3.fromRGB(255, 140, 60))
		-- reação em cadeia (no próximo quadro, para não aninhar demais)
		task.defer(function()
			City.damageCity(origin, 14, 80)
			Game.damageArea(origin, 16, 80)
			if not State.dead and (origin - Game.torsoCenter()).Magnitude < 14 * Mech.scale then
				Game.damageRobot(25, origin)
			end
		end)
	end

	-----------------------------------------------------------------------------------
	-- Objetos
	-----------------------------------------------------------------------------------
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
	City.makeCar = makeCar

	local function propUnit()
		return newUnit("prop", CITY.PROP_HP, 0)
	end

	local function makeStreetlight(pos, armDir)
		local unit = propUnit()
		local metal = Color3.fromRGB(60, 60, 65)
		addToUnit(unit, cityPart(City.folders.props, Vector3.new(0.6, 14, 0.6), CFrame.new(pos + Vector3.new(0, 7, 0)), metal, Enum.Material.Metal, { CastShadow = false }))
		local top = pos + Vector3.new(0, 13.8, 0)
		local armCF = CFrame.lookAt(top, top + armDir) * CFrame.new(0, 0, -2)
		addToUnit(unit, cityPart(City.folders.props, Vector3.new(0.4, 0.4, 4), armCF, metal, Enum.Material.Metal, { CastShadow = false }))
		local bulb = addToUnit(unit, cityPart(City.folders.props, Vector3.new(1.6, 0.5, 1.6), armCF * CFrame.new(0, -0.4, -1.8), Color3.fromRGB(200, 200, 190), Enum.Material.Glass, { CastShadow = false }))
		local light = new("PointLight", { Range = 40, Brightness = 1.6, Color = Color3.fromRGB(255, 210, 150), Enabled = false, Parent = bulb })
		table.insert(City.streetlights, { bulb = bulb, light = light, pos = bulb.Position })
	end

	local function makeTree(pos)
		local unit = propUnit()
		local h = rand(5, 8)
		local props = City.folders.props
		addToUnit(unit, cityPart(props, Vector3.new(1.2, h, 1.2), CFrame.new(pos + Vector3.new(0, h / 2, 0)), Color3.fromRGB(100, 70, 45), Enum.Material.Wood))
		local s1 = rand(6, 8)
		addToUnit(unit, cityPart(props, Vector3.one * s1, CFrame.new(pos + Vector3.new(0, h + 1.5, 0)), Color3.fromRGB(60, 140, 60), Enum.Material.Grass, { Shape = BALL }))
		local s2 = rand(4, 5)
		addToUnit(unit, cityPart(props, Vector3.one * s2, CFrame.new(pos + Vector3.new(rand(-1.5, 1.5), h + 4, rand(-1.5, 1.5))), Color3.fromRGB(80, 160, 70), Enum.Material.Grass, { Shape = BALL }))
	end

	local function makeBench(cf)
		local unit = propUnit()
		local props = City.folders.props
		addToUnit(unit, cityPart(props, Vector3.new(5, 0.4, 1.6), cf * CFrame.new(0, 1.6, 0), WOOD, Enum.Material.Wood))
		addToUnit(unit, cityPart(props, Vector3.new(5, 1.6, 0.3), cf * CFrame.new(0, 2.6, 0.75), WOOD, Enum.Material.Wood))
		for _, x in ipairs({ -2, 2 }) do
			addToUnit(unit, cityPart(props, Vector3.new(0.4, 1.4, 1.4), cf * CFrame.new(x, 0.7, 0), Color3.fromRGB(50, 50, 55), Enum.Material.Metal))
		end
	end

	local function makeHydrant(pos)
		local unit = propUnit()
		local red = Color3.fromRGB(200, 30, 30)
		addToUnit(unit, cityPart(City.folders.props, Vector3.new(2.2, 1, 1), CFrame.new(pos + Vector3.new(0, 1.1, 0)) * AXIS_Y, red, Enum.Material.Metal, { Shape = CYL, CastShadow = false }))
		addToUnit(unit, cityPart(City.folders.props, Vector3.one * 1.1, CFrame.new(pos + Vector3.new(0, 2.3, 0)), red, Enum.Material.Metal, { Shape = BALL, CastShadow = false }))
		unit.onBreak = function(_, origin)
			-- jato de água
			local p = makePart({ Size = Vector3.one, Transparency = 1, Position = origin, Parent = F.effects })
			new("ParticleEmitter", {
				Color = ColorSequence.new(Color3.fromRGB(170, 210, 255)),
				Size = NumberSequence.new(0.8, 2),
				Transparency = NumberSequence.new(0.2, 1),
				Lifetime = NumberRange.new(1, 1.5),
				Speed = NumberRange.new(30, 40),
				SpreadAngle = Vector2.new(8, 8),
				Acceleration = Vector3.new(0, -60, 0),
				EmissionDirection = Enum.NormalId.Top,
				Rate = 80,
				Parent = p,
			})
			Debris:AddItem(p, 8)
		end
	end

	local function makeBin(pos)
		local unit = propUnit()
		addToUnit(unit, cityPart(City.folders.props, Vector3.new(1.6, 2.6, 1.6), CFrame.new(pos + Vector3.new(0, 1.3, 0)), Color3.fromRGB(40, 110, 60), Enum.Material.Metal, { CastShadow = false }))
	end

	local function makeBusStop(cf)
		local unit = propUnit()
		local props = City.folders.props
		local metal = Color3.fromRGB(70, 75, 85)
		addToUnit(unit, cityPart(props, Vector3.new(8, 0.3, 3), cf * CFrame.new(0, 7, 0), metal, Enum.Material.Metal))
		addToUnit(unit, cityPart(props, Vector3.new(8, 5, 0.2), cf * CFrame.new(0, 4, 1.4), Color3.fromRGB(150, 190, 220), Enum.Material.Glass, { Transparency = 0.5, CastShadow = false }))
		for _, x in ipairs({ -3.8, 3.8 }) do
			addToUnit(unit, cityPart(props, Vector3.new(0.3, 7, 0.3), cf * CFrame.new(x, 3.5, 1.3), metal, Enum.Material.Metal, { CastShadow = false }))
		end
		addToUnit(unit, cityPart(props, Vector3.new(6, 0.4, 1.2), cf * CFrame.new(0, 1.6, 0.8), WOOD, Enum.Material.Wood))
	end

	-----------------------------------------------------------------------------------
	-- Lojas com interior
	-- p(tamanho, x, yDaBase, z, cor, material, extras) cria um móvel dentro da loja.
	-- Coordenadas locais: porta em -Z (frente), fundo em +Z.
	-----------------------------------------------------------------------------------
	local BOX_COLORS = {
		Color3.fromRGB(230, 70, 60),
		Color3.fromRGB(60, 150, 230),
		Color3.fromRGB(250, 200, 50),
		Color3.fromRGB(90, 200, 90),
		Color3.fromRGB(240, 130, 40),
		Color3.fromRGB(180, 90, 200),
	}
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

	-----------------------------------------------------------------------------------
	-- Prédios: paredes em pedaços por andar (parede + janela) e uma laje por andar.
	-- O prédio inteiro é um Model para poder desmoronar com PivotTo.
	-----------------------------------------------------------------------------------
	local function buildBuilding(center, w, d, floors, frontDir, style, shop)
		local model = new("Model", { Name = "Predio", Parent = City.folders.buildings })
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
			interior = nil :: any,
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

		local doorSegLen = CITY.SEG_W
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
						doorSegLen = segLen
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
			if f == floors - 1 then
				-- Parapeito do telhado
				for _, side in ipairs(sides) do
					local rot = CFrame.fromMatrix(Vector3.zero, side.tangent, Vector3.yAxis)
					local pos = side.center * 1.0 + Vector3.new(0, y0 + FH + 0.75, 0)
					addToUnit(slab, part(Vector3.new(side.length + 0.4, 1.5, 0.8), CFrame.new(pos) * rot, style.trim, Enum.Material.Concrete, { CastShadow = false }))
				end
			end
		end

		-- Detalhes do telhado
		local roofY = floors * FH
		if math.random() < 0.7 then
			local ac = unit("prop", CITY.PROP_HP, 0, false)
			addToUnit(ac, part(Vector3.new(6, 3, 5), CFrame.new(rand(-w / 4, w / 4), roofY + 1.5, rand(-d / 4, d / 4)), Color3.fromRGB(170, 170, 175), Enum.Material.Metal))
		end
		if floors >= 3 and floors <= 7 and math.random() < 0.35 then
			local tank = unit("prop", CITY.PROP_HP, 0, false)
			local tx, tz = rand(-w / 4, w / 4), rand(-d / 4, d / 4)
			addToUnit(tank, part(Vector3.new(6, 6, 6), CFrame.new(tx, roofY + 5, tz) * AXIS_Y, Color3.fromRGB(120, 85, 55), Enum.Material.Wood, { Shape = CYL }))
			for _, o in ipairs({ Vector3.new(-2, 0, -2), Vector3.new(2, 0, -2), Vector3.new(-2, 0, 2), Vector3.new(2, 0, 2) }) do
				addToUnit(tank, part(Vector3.new(0.4, 2, 0.4), CFrame.new(tx + o.X, roofY + 1, tz + o.Z), DARK_METAL, Enum.Material.Metal, { CastShadow = false }))
			end
		end
		if floors >= 6 and math.random() < 0.45 then
			-- Letreiro luminoso no telhado
			local ad = pick(ADS)
			local sign = unit("prop", CITY.PROP_HP * 2, 0, false)
			local sw = math.min(30, w * 0.7)
			for _, x in ipairs({ -sw / 3, sw / 3 }) do
				addToUnit(sign, part(Vector3.new(0.6, 6, 0.6), CFrame.new(x, roofY + 3, -d / 4), DARK_METAL, Enum.Material.Metal, { CastShadow = false }))
			end
			local board = addToUnit(sign, part(Vector3.new(sw, 8, 0.6), CFrame.new(0, roofY + 10, -d / 4), Color3.fromRGB(15, 15, 20), Enum.Material.SmoothPlastic))
			local surface = new("SurfaceGui", { Face = Enum.NormalId.Front, LightInfluence = 0, PixelsPerStud = 20, Parent = board })
			new("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = ad.text,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
				TextColor3 = ad.color,
				Parent = surface,
			})
			new("PointLight", { Color = ad.color, Range = 24, Brightness = 1.5, Parent = board })
		end
		if floors >= 8 then
			local antenna = unit("prop", CITY.PROP_HP, 0, false)
			addToUnit(antenna, part(Vector3.new(0.6, 14, 0.6), CFrame.new(0, roofY + 7, d / 4), DARK_METAL, Enum.Material.Metal, { CastShadow = false }))
			addToUnit(antenna, part(Vector3.one * 1.2, CFrame.new(0, roofY + 14.5, d / 4), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, { Shape = BALL, CastShadow = false }))
		end

		-- Loja: letreiro, toldo e interior
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
			addToUnit(sign, part(Vector3.new(doorSegLen + 2, 0.4, 3.5), CFrame.new(0, CITY.DOOR_H + 0.2, -d / 2 - 2) * CFrame.Angles(-0.25, 0, 0), shop.color, Enum.Material.Fabric, { CastShadow = false }))
			buildInterior(b, shop)
		end

		City.totalMass += b.totalMass
		table.insert(City.buildings, b)
		return b
	end

	-----------------------------------------------------------------------------------
	-- Quarteirões
	-----------------------------------------------------------------------------------
	local function buildPlaza(base)
		local B = CITY.BLOCK
		local ground = City.folders.ground
		cityPart(ground, Vector3.new(B - 8, 0.1, B - 8), CFrame.new(base + Vector3.new(0, 0.05, 0)), Color3.fromRGB(170, 120, 100), Enum.Material.Brick)
		local f = base + Vector3.new(0, 0, -25)
		cityPart(ground, Vector3.new(2, 22, 22), CFrame.new(f + Vector3.new(0, 1, 0)) * AXIS_Y, Color3.fromRGB(200, 200, 195), Enum.Material.Concrete, { Shape = CYL })
		cityPart(ground, Vector3.new(0.3, 20, 20), CFrame.new(f + Vector3.new(0, 1.8, 0)) * AXIS_Y, Color3.fromRGB(60, 140, 220), Enum.Material.Glass, { Shape = CYL, Transparency = 0.3, CanCollide = false })
		cityPart(ground, Vector3.new(7, 2.5, 2.5), CFrame.new(f + Vector3.new(0, 3.5, 0)) * AXIS_Y, Color3.fromRGB(200, 200, 195), Enum.Material.Concrete, { Shape = CYL })
		local top = cityPart(ground, Vector3.one * 2.5, CFrame.new(f + Vector3.new(0, 7.5, 0)), THEMES[1].accent, Enum.Material.Neon, { Shape = BALL })
		new("PointLight", { Range = 20, Brightness = 2, Color = THEMES[1].accent, Parent = top })
		local water = makePart({ Size = Vector3.one, Transparency = 1, Position = f + Vector3.new(0, 8, 0), Parent = ground })
		new("ParticleEmitter", {
			Color = ColorSequence.new(Color3.fromRGB(170, 210, 255)),
			Size = NumberSequence.new(0.6, 1.4),
			Transparency = NumberSequence.new(0.3, 1),
			Lifetime = NumberRange.new(1, 1.4),
			Speed = NumberRange.new(12, 16),
			SpreadAngle = Vector2.new(25, 25),
			Acceleration = Vector3.new(0, -40, 0),
			EmissionDirection = Enum.NormalId.Top,
			Rate = 40,
			Parent = water,
		})
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
		cityPart(City.folders.ground, Vector3.new(B - 6, 0.1, B - 6), CFrame.new(base + Vector3.new(0, 0.05, 0)), Color3.fromRGB(80, 150, 70), Enum.Material.Grass)
		cityPart(City.folders.ground, Vector3.new(0.3, 18, 18), CFrame.new(base + Vector3.new(15, 0.15, 10)) * AXIS_Y, Color3.fromRGB(60, 130, 200), Enum.Material.Glass, { Shape = CYL, Transparency = 0.2 })
		for _ = 1, 9 do
			makeTree(base + Vector3.new(rand(-B / 2 + 10, B / 2 - 10), 0, rand(-B / 2 + 10, B / 2 - 10)))
		end
		makeBench(CFrame.new(base + Vector3.new(-15, 0, -20)))
		makeBench(CFrame.new(base + Vector3.new(-15, 0, 20)) * CFrame.Angles(0, math.pi, 0))
	end

	local function buildParking(base)
		local B = CITY.BLOCK
		cityPart(City.folders.ground, Vector3.new(B - 6, 0.1, B - 6), CFrame.new(base + Vector3.new(0, 0.05, 0)), Color3.fromRGB(55, 55, 60), Enum.Material.Asphalt)
		for k = -3, 3 do
			for _, z in ipairs({ -15, 15 }) do
				cityPart(City.folders.ground, Vector3.new(0.4, 0.05, 12), CFrame.new(base + Vector3.new(k * 8 - 4, 0.12, z)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { CanQuery = false })
			end
		end
		for k = -3, 2 do
			for _, z in ipairs({ -15, 15 }) do
				if math.random() < 0.7 then
					local pos = base + Vector3.new(k * 8, 0, z)
					makeCar(CFrame.lookAt(pos, pos + Vector3.new(0, 0, z > 0 and -1 or 1)), pick(CAR_COLORS), City.folders.props)
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
		cityPart(City.folders.ground, Vector3.new(B, CITY.SIDEWALK_H, B), CFrame.new(center + Vector3.new(0, 0.2 + CITY.SIDEWALK_H / 2, 0)), Color3.fromRGB(175, 175, 170), Enum.Material.Concrete)
		local base = center + Vector3.new(0, top, 0)

		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				makeStreetlight(base + Vector3.new(sx * (B / 2 - 2), 0, sz * (B / 2 - 2)), Vector3.new(sx, 0, 0))
			end
		end

		for _, normal in ipairs(AXES) do
			local tangent = Vector3.new(normal.Z, 0, normal.X)
			-- Carros estacionados na beira da rua
			if math.random() < 0.5 then
				local pos = center + normal * (B / 2 + 3) + tangent * rand(-35, 35) + Vector3.new(0, 0.2, 0)
				makeCar(CFrame.lookAt(pos, pos + tangent), pick(CAR_COLORS), City.folders.props)
			end
			-- Calçada: árvores, hidrante, lixeira, ponto de ônibus
			if CONFIG.QUALITY[State.quality].props and not isPlaza then
				local edge = base + normal * (B / 2 - 4)
				for _, t in ipairs({ -32, 32 }) do
					if math.random() < 0.6 then
						makeTree(edge + tangent * t)
					end
				end
				local r = math.random()
				if r < 0.35 then
					makeHydrant(edge + tangent * rand(-15, 15))
				elseif r < 0.65 then
					makeBin(edge + tangent * rand(-15, 15))
				elseif r < 0.8 then
					local pos = edge + tangent * rand(-12, 12)
					makeBusStop(CFrame.lookAt(pos, pos + normal))
				end
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

	-----------------------------------------------------------------------------------
	-- Trânsito
	-----------------------------------------------------------------------------------
	function City.nearestRoad(v)
		local best, bestD = 0, math.huge
		for _, c in ipairs(City.roadCenters) do
			local d = math.abs(c - v)
			if d < bestD then
				best, bestD = c, d
			end
		end
		return best
	end

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
		local model, unit = makeCar(CFrame.lookAt(pos, pos + heading), pick(CAR_COLORS), City.folders.traffic)
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
				local blocked = isAhead(car, robotPos, 24 * Mech.scale, 8 * Mech.scale) or (charPos ~= nil and isAhead(car, charPos, 16, 5))
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

	-----------------------------------------------------------------------------------
	-- Dia/noite, LOD e escombros
	-----------------------------------------------------------------------------------
	function City.setNight(night)
		City.isNight = night
		for _, sl in ipairs(City.streetlights) do
			if sl.bulb.Parent then
				sl.bulb.Material = night and Enum.Material.Neon or Enum.Material.Glass
				sl.bulb.Color = night and Color3.fromRGB(255, 220, 160) or Color3.fromRGB(200, 200, 190)
			end
		end
		POST.sunRays.Intensity = night and 0 or 0.06
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

	function City.isNightTime()
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
					it.folder.Parent = want and City.folders.interiors or nil
				end
			end
		end
		for _, sl in ipairs(City.streetlights) do
			sl.light.Enabled = City.isNight and sl.bulb.Parent ~= nil and (sl.pos - focus).Magnitude < CITY.LIGHT_LOD
		end
	end

	function City.update(dt)
		Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / CITY.DAY_LENGTH) % 24
		if City.isNightTime() ~= City.isNight then
			City.setNight(City.isNightTime())
		end

		local now = os.clock()
		while City.debris[1] and now - City.debris[1].time > CITY.DEBRIS_LIFE do
			local d = table.remove(City.debris, 1)
			if d.part.Parent then
				TweenService:Create(d.part, TweenInfo.new(0.6), { Transparency = 1 }):Play()
				Debris:AddItem(d.part, 0.7)
			end
		end

		for i = #City.collapsing, 1, -1 do
			local c = City.collapsing[i]
			c.t += dt
			local a = math.min(1, c.t / c.dur)
			local ease = a * a
			local b = c.b
			if b.model.Parent then
				b.model:PivotTo(b.cf * CFrame.new(0, -b.height * ease, 0) * CFrame.Angles(c.tiltX * ease, 0, c.tiltZ * ease))
			end
			FX.shake(dt * 2, b.cf.Position)
			if a >= 1 then
				b.model:Destroy()
				spawnRubble(b)
				table.remove(City.collapsing, i)
			end
		end

		updateTraffic(dt)
		updateLOD(dt)
	end

	function City.forceLOD()
		lodTimer = 1
	end

	-----------------------------------------------------------------------------------
	-- Geração
	-----------------------------------------------------------------------------------
	function City.generate()
		City.generating = true
		UI.loadingFrame.Visible = true
		UI.loadingBar.Size = UDim2.fromScale(0, 1)
		UI.loadingStatus.Text = "CONSTRUINDO A CIDADE..."

		City.generation += 1
		for _, it in ipairs(City.interiors) do
			it.folder:Destroy()
		end
		F.city:ClearAllChildren()
		F.debris:ClearAllChildren()
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
		City.fires = 0

		City.folders = {
			ground = new("Folder", { Name = "Chao", Parent = F.city }),
			buildings = new("Folder", { Name = "Predios", Parent = F.city }),
			props = new("Folder", { Name = "Objetos", Parent = F.city }),
			interiors = new("Folder", { Name = "Interiores", Parent = F.city }),
			traffic = new("Folder", { Name = "Transito", Parent = F.city }),
		}

		local pitch = CITY.BLOCK + CITY.ROAD
		local half = (CITY.GRID * pitch + CITY.ROAD) / 2
		City.half = half

		-- Asfalto e faixas amarelas
		cityPart(City.folders.ground, Vector3.new(half * 2, 2, half * 2), CFrame.new(0, -0.8, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Asphalt)
		for k = 0, CITY.GRID do
			local c = -half + CITY.ROAD / 2 + k * pitch
			table.insert(City.roadCenters, c)
			local lineProps = { CanQuery = false, CastShadow = false }
			cityPart(City.folders.ground, Vector3.new(half * 2, 0.05, 0.5), CFrame.new(0, 0.22, c), Color3.fromRGB(240, 200, 40), Enum.Material.SmoothPlastic, lineProps)
			cityPart(City.folders.ground, Vector3.new(0.5, 0.05, half * 2), CFrame.new(c, 0.22, 0), Color3.fromRGB(240, 200, 40), Enum.Material.SmoothPlastic, lineProps)
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
		lodTimer = 1
		City.setNight(City.isNightTime())
		City.generating = false
		UI.loadingFrame.Visible = false
	end
end

---------------------------------------------------------------------------------------
-- INIMIGOS, PROJÉTEIS E ITENS
---------------------------------------------------------------------------------------
local E = { list = {}, partMap = {}, projectiles = {}, pickups = {} }
local clock = 0

do
	local KINDS = {
		drone = { name = "DRONE", hp = 100, reward = 100, color = Color3.fromRGB(255, 40, 40), radius = 2.5 },
		boss = { name = "NAVE-MÃE", hp = CONFIG.BOSS_HEALTH, reward = 2000, color = Color3.fromRGB(200, 60, 255), radius = 9 },
		gunship = { name = "HELICÓPTERO", hp = 350, reward = 250, color = Color3.fromRGB(255, 170, 40), radius = 7 },
		tank = { name = "TANQUE", hp = 450, reward = 300, color = Color3.fromRGB(255, 220, 60), radius = 7 },
		mech = { name = "MECH INIMIGO", hp = 700, reward = 500, color = Color3.fromRGB(255, 80, 80), radius = 6 },
	}
	E.KINDS = KINDS
	local ENEMY_MECH = { id = "inimigo", name = "MECH INIMIGO", scale = 0.95, weapon = "laser", missiles = 2 }
	local ENEMY_COLORS = { primary = Color3.fromRGB(60, 60, 68), secondary = Color3.fromRGB(25, 25, 30), accent = Color3.fromRGB(255, 40, 40) }
	local ARMY = Color3.fromRGB(75, 85, 55)
	local ARMY_DARK = Color3.fromRGB(35, 38, 30)

	-----------------------------------------------------------------------------------
	-- Construção
	-----------------------------------------------------------------------------------
	local function newEnemy(kind, pos)
		local info = KINDS[kind]
		local e = {
			kind = kind,
			name = info.name,
			hp = info.hp,
			maxHp = info.hp,
			reward = info.reward,
			color = info.color,
			radius = info.radius,
			pos = pos,
			centerOffset = Vector3.zero,
			model = new("Model", { Name = info.name, Parent = F.enemies }),
			pieces = {},
			parts = {},
			cfs = {},
			alive = true,
			fireTimer = rand(2, 4),
			angle = math.random() * math.pi * 2,
			spin = 0,
			heading = Vector3.new(0, 0, -1),
		}
		return e
	end

	local function piece(e, size, localCF, color, material, shape, tag)
		local p = makePart({
			Size = size,
			Color = color,
			Material = material,
			Shape = shape or Enum.PartType.Block,
			CanQuery = true,
			Parent = e.model,
		})
		table.insert(e.pieces, { part = p, localCF = localCF, tag = tag })
		table.insert(e.parts, p)
		E.partMap[p] = e
		return p
	end

	local function pose(e, cf, tagged)
		for i, pc in ipairs(e.pieces) do
			local base = pc.tag and tagged and tagged[pc.tag] or cf
			e.cfs[i] = base * pc.localCF
		end
		workspace:BulkMoveTo(e.parts, e.cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end

	local function addBar(e, adornee, width, offsetY, showName)
		local billboard = new("BillboardGui", {
			Size = UDim2.new(width, 0, width * 0.1, 0),
			StudsOffset = Vector3.new(0, offsetY, 0),
			AlwaysOnTop = true,
			MaxDistance = 400,
			Adornee = adornee,
			Parent = adornee,
		})
		local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = billboard })
		e.bar = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = e.color, BorderSizePixel = 0, Parent = bg })
		if showName then
			UI.label({
				Size = UDim2.new(1, 0, 2, 0),
				Position = UDim2.fromScale(0, -2.2),
				Text = e.name,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
				TextColor3 = e.color,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = billboard,
			})
		end
	end

	local function buildDrone(e, s)
		local body = piece(e, Vector3.one * 3 * s, CFrame.identity, Color3.fromRGB(40, 40, 45), Enum.Material.Metal, BALL)
		e.eye = piece(e, Vector3.one * 1.3 * s, CFrame.new(0, 0, -1.2 * s), e.color, Enum.Material.Neon, BALL)
		piece(e, Vector3.new(0.3, 5, 5) * s, CFrame.identity, Color3.fromRGB(90, 90, 100), Enum.Material.Metal, CYL, "ring")
		new("PointLight", { Color = e.color, Range = 10 * s, Brightness = 2, Parent = e.eye })
		addBar(e, body, 4 * s, 3 * s, s > 1)
	end

	local function buildGunship(e)
		local body = piece(e, Vector3.new(6, 4, 12), CFrame.identity, ARMY, Enum.Material.Metal)
		piece(e, Vector3.new(4.6, 2.6, 4), CFrame.new(0, 0.6, -5.5), Color3.fromRGB(30, 40, 50), Enum.Material.Glass)
		piece(e, Vector3.new(4, 2.4, 2.4), CFrame.new(0, -0.4, -7.6), ARMY, Enum.Material.Metal)
		piece(e, Vector3.new(1.6, 1.6, 10), CFrame.new(0, 0.8, 10), ARMY, Enum.Material.Metal)
		piece(e, Vector3.new(0.4, 3.4, 2.2), CFrame.new(0, 2.4, 14.4), ARMY_DARK, Enum.Material.Metal)
		piece(e, Vector3.new(11, 0.4, 2.4), CFrame.new(0, -0.8, 0), ARMY_DARK, Enum.Material.Metal)
		for _, x in ipairs({ -5, 5 }) do
			piece(e, Vector3.new(1.1, 1.1, 3.6), CFrame.new(x, -1.4, -0.4), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
			piece(e, Vector3.new(0.4, 0.4, 10), CFrame.new(x * 0.5, -2.8, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
		end
		piece(e, Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 2.4, 0), ARMY_DARK, Enum.Material.Metal)
		piece(e, Vector3.new(28, 0.3, 1.2), CFrame.identity, Color3.fromRGB(25, 25, 25), Enum.Material.Metal, nil, "rotor")
		piece(e, Vector3.new(1.2, 0.3, 28), CFrame.identity, Color3.fromRGB(25, 25, 25), Enum.Material.Metal, nil, "rotor")
		piece(e, Vector3.new(0.3, 4.4, 0.6), CFrame.identity, Color3.fromRGB(25, 25, 25), Enum.Material.Metal, nil, "tail")
		local light = piece(e, Vector3.one * 0.5, CFrame.new(0, -2.1, 3), Color3.fromRGB(255, 40, 40), Enum.Material.Neon, BALL)
		new("SpotLight", { Face = Enum.NormalId.Bottom, Range = 60, Angle = 50, Brightness = 3, Color = Color3.fromRGB(255, 250, 220), Parent = light })
		addBar(e, body, 10, 5, false)
		e.burst = 0
		e.burstTimer = 0
	end

	local function buildTank(e)
		local hull = piece(e, Vector3.new(9, 3, 13), CFrame.new(0, 2.8, 0), ARMY, Enum.Material.Metal)
		piece(e, Vector3.new(9, 1.6, 3), CFrame.new(0, 3.6, -6.4) * CFrame.Angles(0.45, 0, 0), ARMY, Enum.Material.Metal)
		for _, x in ipairs({ -5.2, 5.2 }) do
			piece(e, Vector3.new(2.6, 2.8, 14.5), CFrame.new(x, 1.6, 0), ARMY_DARK, Enum.Material.DiamondPlate)
		end
		piece(e, Vector3.new(6.5, 2.4, 6.5), CFrame.identity, ARMY, Enum.Material.Metal, nil, "turret")
		piece(e, Vector3.new(1, 1, 9), CFrame.new(0, 0.2, -7.5), ARMY_DARK, Enum.Material.Metal, nil, "turret")
		piece(e, Vector3.new(2, 0.5, 2), CFrame.new(0, 1.4, 1), ARMY_DARK, Enum.Material.Metal, nil, "turret")
		piece(e, Vector3.new(6.6, 0.3, 0.3), CFrame.new(0, -0.6, -3.3), Color3.fromRGB(255, 50, 50), Enum.Material.Neon, nil, "turret")
		addBar(e, hull, 9, 6, false)
		e.centerOffset = Vector3.new(0, 3.5, 0)
	end

	local function buildMech(e)
		local rig = Rig.build(ENEMY_MECH, ENEMY_COLORS, F.enemies, true)
		Rig.paint(rig, ENEMY_COLORS)
		e.model:Destroy()
		e.model = rig.model
		e.rig = rig
		e.parts = rig.parts
		for _, p in ipairs(rig.parts) do
			E.partMap[p] = e
		end
		local chest = rig.model:FindFirstChild("Peito")
		addBar(e, chest, 8, 5, true)
		e.centerOffset = Vector3.new(0, rig.hip + 3.5 * rig.scale, 0)
		e.vel = Vector3.zero
	end

	-----------------------------------------------------------------------------------
	-- Criação, dano e morte
	-----------------------------------------------------------------------------------
	local function groundSpawn()
		local r = State.rootCF.Position
		local sgn = math.random() < 0.5 and 1 or -1
		if math.random() < 0.5 then
			local z = City.nearestRoad(r.Z + rand(-150, 150))
			local x = math.clamp(r.X + sgn * rand(200, 260), -City.half, City.half)
			return Vector3.new(x, 0.2, z), "x"
		else
			local x = City.nearestRoad(r.X + rand(-150, 150))
			local z = math.clamp(r.Z + sgn * rand(200, 260), -City.half, City.half)
			return Vector3.new(x, 0.2, z), "z"
		end
	end

	function E.spawn(kind, position)
		if #E.list >= CONFIG.MAX_ENEMIES and kind ~= "boss" then
			return nil
		end
		local center = State.rootCF.Position
		local e
		if kind == "drone" or kind == "boss" then
			local a = math.random() * math.pi * 2
			local pos = position or center + Vector3.new(math.cos(a) * 110, 40 + math.random() * 20, math.sin(a) * 110)
			if kind == "boss" then
				pos = center + Vector3.new(0, 100, -150)
			end
			e = newEnemy(kind, pos)
			local s = kind == "boss" and 3.5 or 1
			e.scale = s
			e.orbit = kind == "boss" and 90 or 35 + math.random() * 40
			e.height = kind == "boss" and 55 or 14 + math.random() * 20
			e.orbitSpeed = (math.random() < 0.5 and -1 or 1) * (kind == "boss" and 0.15 or 0.3 + math.random() * 0.4)
			e.summonTimer = 12
			buildDrone(e, s)
		elseif kind == "gunship" then
			local a = math.random() * math.pi * 2
			e = newEnemy(kind, center + Vector3.new(math.cos(a) * 250, 60, math.sin(a) * 250))
			buildGunship(e)
		elseif kind == "tank" then
			local pos, axis = groundSpawn()
			e = newEnemy(kind, pos)
			e.axis = axis
			buildTank(e)
		elseif kind == "mech" then
			local pos, axis = groundSpawn()
			e = newEnemy(kind, pos)
			e.axis = axis
			buildMech(e)
		end
		table.insert(E.list, e)
		FX.spark(e.pos + e.centerOffset, e.color, 20, 20)
		return e
	end

	function E.remove(e)
		e.alive = false
		local index = table.find(E.list, e)
		if index then
			table.remove(E.list, index)
		end
		for _, p in ipairs(e.parts) do
			E.partMap[p] = nil
		end
		e.model:Destroy()
	end

	function E.spawnPickup(position)
		local repair = math.random() < 0.5
		local color = repair and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(60, 180, 255)
		local part = makePart({
			Shape = BALL,
			Size = Vector3.one * 2.5,
			Color = color,
			Material = Enum.Material.Neon,
			Position = position,
			CastShadow = false,
			Parent = F.effects,
		})
		new("PointLight", { Color = color, Range = 12, Brightness = 2, Parent = part })
		table.insert(E.pickups, { part = part, repair = repair, pos = position, life = 25 })
	end

	local function kill(e)
		local center = e.pos + e.centerOffset
		FX.explosion(center, e.radius * 1.8, Color3.fromRGB(255, 120, 30))
		if e.kind == "mech" or e.kind == "tank" or e.kind == "boss" then
			task.delay(0.25, function()
				FX.explosion(center + Vector3.new(rand(-3, 3), 2, rand(-3, 3)), e.radius * 1.2)
			end)
		end
		E.remove(e)
		State.kills += 1
		Game.addScore(e.reward, e.name, e.color)
		if e.kind == "boss" then
			Game.notify("NAVE-MÃE DESTRUÍDA!", Color3.fromRGB(200, 80, 255))
			for _ = 1, 3 do
				E.spawnPickup(center + Vector3.new(rand(-8, 8), 0, rand(-8, 8)))
			end
		elseif math.random() < ((e.kind == "tank" or e.kind == "mech") and 0.5 or CONFIG.PICKUP_CHANCE) then
			E.spawnPickup(center)
		end
		if #E.list == 0 and isPlaying() then
			Game.addScore(500, "ONDA CONCLUÍDA", Color3.fromRGB(90, 255, 120))
			Game.notify("ONDA " .. State.wave .. " CONCLUÍDA!", Color3.fromRGB(90, 255, 120))
		end
	end

	function E.damage(e, amount, hitPos, quiet)
		if not e.alive then
			return
		end
		e.hp -= amount
		if not quiet then
			FX.damageNumber(hitPos or e.pos + e.centerOffset, amount)
		end
		if e.bar then
			e.bar.Size = UDim2.fromScale(math.max(e.hp, 0) / e.maxHp, 1)
		end
		if e.eye then
			e.eye.Color = Color3.new(1, 1, 1)
			task.delay(0.06, function()
				if e.eye.Parent then
					e.eye.Color = e.color
				end
			end)
		end
		if e.hp <= 0 then
			kill(e)
		end
	end

	function Game.damageArea(position, radius, amount)
		-- copia a lista porque inimigos podem ser removidos durante o loop
		for _, e in ipairs(table.clone(E.list)) do
			local center = e.pos + e.centerOffset
			local dist = (center - position).Magnitude
			if dist <= radius + e.radius then
				E.damage(e, amount * (1 - math.min(dist / radius, 1) * 0.5), center)
			end
		end
	end

	-----------------------------------------------------------------------------------
	-- Projéteis (do jogador e dos inimigos)
	-- o = { from, dir, speed, color, size, damage, radius, cityDamage, friendly, life }
	-----------------------------------------------------------------------------------
	function E.fireProjectile(o)
		local size = o.size or 1
		local part = makePart({
			Shape = BALL,
			Size = Vector3.one * size,
			Color = o.color,
			Material = Enum.Material.Neon,
			CastShadow = false,
			Position = o.from,
			Parent = F.effects,
		})
		if size >= 1 then
			new("PointLight", { Color = o.color, Range = size * 8, Brightness = 2, Parent = part })
		end
		table.insert(E.projectiles, {
			part = part,
			pos = o.from,
			vel = o.dir.Unit * o.speed,
			life = o.life or 5,
			damage = o.damage,
			radius = o.radius or 0,
			cityDamage = o.cityDamage or 20,
			friendly = o.friendly,
			color = o.color,
		})
	end

	function E.updateProjectiles(dt)
		local torso = Game.torsoCenter()
		for i = #E.projectiles, 1, -1 do
			local pr = E.projectiles[i]
			pr.life -= dt
			local step = pr.vel * dt
			local newPos = pr.pos + step
			local done = pr.life <= 0
			local hitPos, hitInst, hitRobot = nil, nil, false
			if not done and not pr.friendly and not State.dead and (newPos - torso).Magnitude < 5.5 * Mech.scale then
				hitPos, hitRobot, done = newPos, true, true
				Game.damageRobot(pr.damage, newPos)
			end
			if not done then
				local hit = workspace:Raycast(pr.pos, step, pr.friendly and rayAim or rayWorld)
				if hit then
					hitPos, hitInst, done = hit.Position, hit.Instance, true
				end
			end
			if done then
				if hitPos then
					if pr.radius > 0 then
						FX.explosion(hitPos, pr.radius, pr.color)
						if pr.friendly then
							Game.damageArea(hitPos, pr.radius * 1.3, pr.damage)
						elseif not hitRobot and not State.dead and (hitPos - torso).Magnitude < pr.radius * 1.3 then
							Game.damageRobot(pr.damage * 0.6, hitPos)
						end
						City.damageCity(hitPos, pr.radius, pr.cityDamage)
					else
						FX.spark(hitPos, pr.color, 8)
						if hitInst then
							local e = pr.friendly and E.partMap[hitInst]
							if e then
								E.damage(e, pr.damage, hitPos)
							end
							local unit = City.partInfo[hitInst]
							if unit then
								City.damageUnit(unit, pr.cityDamage, hitPos)
							end
						end
					end
				end
				pr.part:Destroy()
				table.remove(E.projectiles, i)
			else
				pr.pos = newPos
				pr.part.Position = newPos
			end
		end
	end

	function E.updatePickups(dt)
		for i = #E.pickups, 1, -1 do
			local pk = E.pickups[i]
			pk.life -= dt
			local groundY = findGroundY(pk.pos)
			if pk.pos.Y > groundY + 2.5 then
				pk.pos = Vector3.new(pk.pos.X, math.max(groundY + 2.5, pk.pos.Y - 40 * dt), pk.pos.Z)
			end
			pk.part.Position = pk.pos + Vector3.new(0, math.sin(clock * 4) * 0.4, 0)
			local collected = not State.dead and (pk.pos - Game.torsoCenter()).Magnitude < 11 * Mech.scale
			if collected then
				if pk.repair then
					State.health = math.min(Mech.def.health, State.health + Mech.def.health * 0.15)
					Game.feed("+15% INTEGRIDADE", Color3.fromRGB(80, 255, 120))
				else
					State.energy = CONFIG.MAX_ENERGY
					Game.feed("ENERGIA CHEIA", Color3.fromRGB(60, 180, 255))
				end
				FX.spark(pk.pos, pk.part.Color, 20, 20)
			end
			if collected or pk.life <= 0 then
				pk.part:Destroy()
				table.remove(E.pickups, i)
			end
		end
	end

	-----------------------------------------------------------------------------------
	-- Comportamento
	-----------------------------------------------------------------------------------
	-- Anda pelas ruas: alterna entre ruas no eixo X e no eixo Z até chegar
	-- ao cruzamento mais perto do alvo
	local function roadNavigate(e, dt, speed, target)
		local p = e.pos
		local step = speed * dt
		if e.axis == "x" then
			local goal = City.nearestRoad(target.X)
			local dx = goal - p.X
			if math.abs(dx) <= step then
				e.pos = Vector3.new(goal, p.Y, p.Z)
				e.axis = "z"
			else
				local sgn = math.sign(dx)
				e.pos = p + Vector3.new(sgn * step, 0, 0)
				e.heading = Vector3.new(sgn, 0, 0)
			end
		else
			local goal = City.nearestRoad(target.Z)
			local dz = goal - p.Z
			if math.abs(dz) <= step then
				e.pos = Vector3.new(p.X, p.Y, goal)
				e.axis = "x"
			else
				local sgn = math.sign(dz)
				e.pos = p + Vector3.new(0, 0, sgn * step)
				e.heading = Vector3.new(0, 0, sgn)
			end
		end
	end

	local function canShoot()
		return isPlaying() and not State.dead
	end

	local function updateDrone(e, dt, robotPos, torso)
		e.angle += dt * e.orbitSpeed
		local target = robotPos + Vector3.new(math.cos(e.angle) * e.orbit, e.height, math.sin(e.angle) * e.orbit)
		e.pos = e.pos:Lerp(target, math.min(1, dt * 1.2))
		e.spin += dt * 4
		local cf = CFrame.lookAt(e.pos, torso)
		pose(e, cf, { ring = cf * CFrame.Angles(0, 0, e.spin) * CFrame.Angles(0, math.rad(90), 0) })

		local boss = e.kind == "boss"
		e.fireTimer -= dt
		if e.fireTimer <= 0 and canShoot() then
			e.fireTimer = rand(1.8, 3.5) * (boss and 0.6 or 1)
			if (e.pos - robotPos).Magnitude < 300 then
				local from = e.pos + cf.LookVector * 2 * e.scale
				local dir = ((torso + State.velocity * 0.3) - from).Unit
				local shots = boss and 5 or 1
				for k = 1, shots do
					local spread = (k - (shots + 1) / 2) * 0.12
					E.fireProjectile({
						from = from,
						dir = CFrame.Angles(0, spread, 0):VectorToWorldSpace(dir),
						speed = 80,
						color = e.color,
						size = boss and 1.8 or 1.1,
						damage = boss and 50 or 35,
					})
				end
			end
		end
		if boss then
			e.summonTimer -= dt
			if e.summonTimer <= 0 then
				e.summonTimer = 12
				local drones = 0
				for _, other in ipairs(E.list) do
					if other.kind == "drone" then
						drones += 1
					end
				end
				if drones < 8 then
					for _ = 1, 2 do
						E.spawn("drone", e.pos + Vector3.new(rand(-10, 10), -8, rand(-10, 10)))
					end
				end
			end
		end
	end

	local function updateGunship(e, dt, robotPos, torso)
		e.angle += dt * 0.3
		local target = robotPos + Vector3.new(math.cos(e.angle) * 120, 50 + math.sin(e.angle * 2) * 10, math.sin(e.angle) * 120)
		e.pos = e.pos:Lerp(target, math.min(1, dt * 0.7))
		local cf = CFrame.lookAt(e.pos, Vector3.new(robotPos.X, e.pos.Y, robotPos.Z)) * CFrame.Angles(-0.12, 0, math.sin(e.angle * 3) * 0.1)
		e.spin += dt * 25
		pose(e, cf, {
			rotor = cf * CFrame.new(0, 2.9, 0) * CFrame.Angles(0, e.spin, 0),
			tail = cf * CFrame.new(0.8, 1.4, 14.4) * CFrame.Angles(e.spin * 1.5, 0, 0),
		})
		e.fireTimer -= dt
		if e.fireTimer <= 0 and canShoot() and (e.pos - robotPos).Magnitude < 320 then
			e.fireTimer = 5
			e.burst = 8
		end
		if e.burst > 0 then
			e.burstTimer -= dt
			if e.burstTimer <= 0 then
				e.burstTimer = 0.1
				e.burst -= 1
				local from = (cf * CFrame.new(e.burst % 2 == 0 and -5 or 5, -1.4, -2.5)).Position
				local dir = (torso + Vector3.new(rand(-3, 3), rand(-3, 3), rand(-3, 3)) - from).Unit
				E.fireProjectile({ from = from, dir = dir, speed = 170, color = Color3.fromRGB(255, 220, 90), size = 0.6, damage = 12, cityDamage = 25 })
			end
		end
	end

	local function updateTank(e, dt, robotPos, torso)
		local flat = Vector3.new(robotPos.X - e.pos.X, 0, robotPos.Z - e.pos.Z).Magnitude
		if flat > 100 then
			roadNavigate(e, dt, 16, robotPos)
		end
		local baseCF = CFrame.lookAt(e.pos, e.pos + e.heading)
		local turretCenter = e.pos + Vector3.new(0, 5.4, 0)
		local turretCF = CFrame.lookAt(turretCenter, Vector3.new(robotPos.X, turretCenter.Y, robotPos.Z))
		pose(e, baseCF, { turret = turretCF })
		e.fireTimer -= dt
		if e.fireTimer <= 0 and canShoot() and flat < 230 then
			e.fireTimer = 3.5
			local from = (turretCF * CFrame.new(0, 0.2, -12)).Position
			E.fireProjectile({
				from = from,
				dir = (torso - from).Unit,
				speed = 140,
				color = Color3.fromRGB(255, 150, 40),
				size = 1.4,
				damage = 70,
				radius = 8,
				cityDamage = 90,
			})
			FX.spark(from, Color3.fromRGB(255, 180, 60), 15, 25)
			FX.sound(CONFIG.SOUNDS.missile, 0.7, 0.5, from)
		end
	end

	local function updateMech(e, dt, robotPos, torso)
		local rig = e.rig
		local flat = Vector3.new(robotPos.X - e.pos.X, 0, robotPos.Z - e.pos.Z).Magnitude
		local old = e.pos
		if flat > 90 then
			roadNavigate(e, dt, 16, robotPos)
		end
		e.vel = (e.pos - old) / math.max(dt, 1e-3)
		local look = e.vel.Magnitude > 1 and e.heading or Vector3.new(robotPos.X - e.pos.X, 0, robotPos.Z - e.pos.Z)
		local yaw = look.Magnitude > 0.01 and math.atan2(-look.X, -look.Z) or 0
		e.rootCF = CFrame.new(e.pos.X, e.pos.Y + rig.hip, e.pos.Z) * CFrame.Angles(0, yaw, 0)
		Rig.animate(rig, dt, {
			vel = e.vel,
			rootCF = e.rootCF,
			onGround = true,
			flying = false,
			aiming = true,
			aimPoint = torso,
			clock = clock,
		})
		Rig.compute(rig, e.rootCF, torso)
		Rig.apply(rig)
		e.fireTimer -= dt
		if e.fireTimer <= 0 and canShoot() and flat < 220 then
			e.fireTimer = 1.3
			local muzzle = Rig.muzzle(rig)
			local hits = math.random() < 0.6
			local point = torso + Vector3.new(rand(-1, 1), rand(-1, 1), rand(-1, 1)) * (hits and 2 or 12)
			FX.beam(muzzle, point, Color3.fromRGB(255, 40, 40), 0.5, 0.2)
			rig.muzzleLight.Brightness = 4
			if hits then
				Game.damageRobot(25, point)
			else
				FX.spark(point, Color3.fromRGB(255, 60, 60), 8)
				City.damageCity(point, 3, 20)
			end
		end
	end

	function E.update(dt)
		local robotPos = State.rootCF.Position
		local torso = Game.torsoCenter()
		for _, e in ipairs(table.clone(E.list)) do
			if e.alive then
				if e.kind == "drone" or e.kind == "boss" then
					updateDrone(e, dt, robotPos, torso)
				elseif e.kind == "gunship" then
					updateGunship(e, dt, robotPos, torso)
				elseif e.kind == "tank" then
					updateTank(e, dt, robotPos, torso)
				elseif e.kind == "mech" then
					updateMech(e, dt, robotPos, torso)
				end
			end
		end
	end

	function E.spawnWave()
		State.wave += 1
		local w = State.wave
		local boss = w % CONFIG.BOSS_EVERY == 0
		local counts = {
			{ "drone", boss and math.floor(w / 2) or 3 + w },
			{ "tank", math.floor(w / 2) },
			{ "gunship", math.floor((w - 1) / 3) },
			{ "mech", math.floor(w / 4) },
		}
		for _, c in ipairs(counts) do
			for _ = 1, c[2] do
				E.spawn(c[1])
			end
		end
		if boss then
			E.spawn("boss")
			Game.notify("ONDA " .. w .. " — A NAVE-MÃE CHEGOU!", Color3.fromRGB(200, 80, 255))
		else
			Game.notify("ONDA " .. w .. " — INIMIGOS CHEGANDO!", Color3.fromRGB(255, 80, 80))
		end
	end

	function E.clear()
		for i = #E.list, 1, -1 do
			E.remove(E.list[i])
		end
		for _, pr in ipairs(E.projectiles) do
			pr.part:Destroy()
		end
		table.clear(E.projectiles)
		for _, pk in ipairs(E.pickups) do
			pk.part:Destroy()
		end
		table.clear(E.pickups)
	end
end

---------------------------------------------------------------------------------------
-- PILOTO (personagem do jogador)
---------------------------------------------------------------------------------------
local Pilot = {}
do
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

	function Pilot.setControls(enabled)
		if controls then
			if enabled then
				controls:Enable()
			else
				controls:Disable()
			end
		end
	end

	function Pilot.parts(): (BasePart?, Humanoid?)
		local char = player.Character
		if not char then
			return nil, nil
		end
		return char:FindFirstChild("HumanoidRootPart") :: BasePart?, char:FindFirstChildOfClass("Humanoid")
	end

	function Pilot.setHidden(hidden)
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

	function Pilot.placeRobotNear(position, lookVector)
		local flat = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flat.Magnitude < 0.01 then
			flat = Vector3.new(0, 0, -1)
		end
		local spot = position + flat.Unit * 14 * Mech.scale
		State.yaw = math.atan2(flat.X, flat.Z) -- robô fica de frente para o jogador
		State.rootCF = CFrame.new(spot.X, findGroundY(spot) + Game.hip(), spot.Z) * CFrame.Angles(0, State.yaw, 0)
		State.velocity = Vector3.zero
	end

	function Pilot.exit(silent)
		if not State.piloting then
			return
		end
		State.piloting = false
		State.firing = false
		State.flying = false
		if Mech.rig.flame then
			Mech.rig.flame.Enabled = false
		end
		local hrp, humanoid = Pilot.parts()
		if hrp then
			hrp.Anchored = false
			hrp.CFrame = State.rootCF * CFrame.new(-7 * Mech.scale, -2 * Mech.scale, 0)
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		Pilot.setHidden(false)
		Pilot.setControls(isPlaying())
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then
			camera.CameraSubject = humanoid
		end
		camera.FieldOfView = 70
		if not silent then
			Game.notify("VOCÊ SAIU DO ROBÔ — aperte V para voltar")
		end
	end

	function Pilot.enter(force)
		local hrp, humanoid = Pilot.parts()
		if not hrp or not humanoid or humanoid.Health <= 0 then
			return
		end
		if State.dead then
			Game.notify("ROBÔ EM RECONSTRUÇÃO...", Color3.fromRGB(255, 170, 60))
			return
		end
		local dist = (hrp.Position - State.rootCF.Position).Magnitude
		if dist > CONFIG.ENTER_DISTANCE * Mech.scale and not force then
			FX.explosion(State.rootCF.Position, 6, theme().accent)
			Pilot.placeRobotNear(hrp.Position, hrp.CFrame.LookVector)
			FX.explosion(State.rootCF.Position, 10, theme().accent)
			FX.sound(CONFIG.SOUNDS.whoosh, 0.8)
			Game.notify("ROBÔ CONVOCADO! Aperte V para entrar")
			return
		end
		State.piloting = true
		hrp.Anchored = true
		Pilot.setControls(false)
		State.camYaw = State.yaw
		State.camPitch = -0.2
		camera.CameraType = Enum.CameraType.Scriptable
		FX.sound(CONFIG.SOUNDS.whoosh, 0.6, 1.3)
		if not force then
			Game.notify("SISTEMAS ONLINE — BEM-VINDO, PILOTO")
		end
	end

	local function hookCharacter(char)
		refreshFilters()
		local humanoid = char:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				if State.piloting then
					Pilot.exit(true)
				end
			end)
		end
		if State.gameState ~= "playing" then
			Pilot.setControls(false)
		end
	end
	player.CharacterAdded:Connect(hookCharacter)
	if player.Character then
		task.spawn(hookCharacter, player.Character)
	end
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
	State.slamming = false
	if Mech.rig.flame then
		Mech.rig.flame.Enabled = false
	end
	local center = Game.torsoCenter()
	local s = Mech.scale
	FX.explosion(center, 25 * s, Color3.fromRGB(255, 100, 20))
	task.delay(0.2, function()
		FX.explosion(center + Vector3.new(3, 4, 0) * s, 15 * s)
	end)
	task.delay(0.4, function()
		FX.explosion(center + Vector3.new(-3, 1, 2) * s, 18 * s)
	end)
	City.damageCity(center, 20 * s, 120)
	Rig.setVisible(Mech.rig, false)

	local runId = State.runId
	if State.mode == "missao" and isPlaying() then
		State.lives -= 1
		if State.lives <= 0 then
			Game.notify("SEM VIDAS RESTANTES!", Color3.fromRGB(255, 70, 70))
			task.delay(3, function()
				if State.runId == runId and State.gameState == "playing" then
					Game.gameOver()
				end
			end)
			return
		end
		Game.notify(("ROBÔ DESTRUÍDO — %d VIDA(S) RESTANTE(S)"):format(State.lives), Color3.fromRGB(255, 70, 70))
	else
		Game.notify("ROBÔ DESTRUÍDO — reconstruindo em 5s", Color3.fromRGB(255, 70, 70))
	end
	task.delay(5, function()
		if State.runId ~= runId then
			return
		end
		State.dead = false
		State.health = Mech.def.health
		State.energy = CONFIG.MAX_ENERGY
		State.velocity = Vector3.zero
		Rig.setVisible(Mech.rig, true)
		FX.explosion(Game.torsoCenter(), 12, theme().accent)
		Game.notify("ROBÔ RECONSTRUÍDO!", Color3.fromRGB(90, 255, 120))
	end)
end

function Game.damageRobot(amount, hitPos)
	if State.dead or not isPlaying() then
		return
	end
	if State.shield then
		State.energy = math.max(0, State.energy - amount * 0.3)
		FX.spark(hitPos, theme().accent, 15, 25)
		if State.energy <= 0 then
			State.shield = false
			Game.notify("ESCUDO SOBRECARREGADO!", Color3.fromRGB(255, 170, 60))
		end
		return
	end
	State.health -= amount
	FX.spark(hitPos, Color3.fromRGB(255, 200, 80), 15, 25)
	FX.sound(CONFIG.SOUNDS.hit, 0.8, 0.8, hitPos)
	FX.shake(0.6)
	if State.piloting then
		Game.flashDamage(amount / 100)
	end
	if State.health <= 0 then
		destroyRobot()
	end
end

---------------------------------------------------------------------------------------
-- ARMAS E HABILIDADES
---------------------------------------------------------------------------------------
local Weapons = { missiles = {} }
do
	local function hitscan(muzzle, dir, damage, cityDamage)
		local hit = workspace:Raycast(muzzle, dir * CONFIG.LASER_RANGE, rayAim)
		local endPos = hit and hit.Position or muzzle + dir * CONFIG.LASER_RANGE
		if hit then
			local e = E.partMap[hit.Instance]
			local unit = City.partInfo[hit.Instance]
			if e then
				E.damage(e, damage, hit.Position)
				Game.flashHitmarker()
			elseif unit then
				City.damageUnit(unit, cityDamage, hit.Position)
			end
		end
		return endPos, hit
	end

	local shotCount = 0
	function Weapons.firePrimary()
		local rig = Mech.rig
		local weapon = Mech.def.weapon
		local W = CONFIG.WEAPONS[weapon]
		local t = theme()
		local muzzle = Rig.muzzle(rig)
		local dir = State.aimPoint - muzzle
		if dir.Magnitude < 1 then
			return
		end
		dir = dir.Unit
		shotCount += 1
		rig.muzzleLight.Brightness = 4

		if weapon == "laser" then
			local endPos, hit = hitscan(muzzle, dir, W.damage, W.cityDamage)
			FX.beam(muzzle, endPos, t.accent, 0.45)
			FX.beam(muzzle, endPos, Color3.new(1, 1, 1), 0.15)
			FX.spark(muzzle, t.accent, 4, 10)
			if hit then
				FX.spark(hit.Position, t.accent, 8, 20)
			end
			FX.sound(CONFIG.SOUNDS.laser, 0.35, 1.4 + math.random() * 0.2)
			FX.shake(0.05)
			rig.anim.armR = rig.anim.armR * CFrame.new(0, 0.4, 0)
		elseif weapon == "minigun" then
			local sp = W.spread
			dir = (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(rand(-sp, sp), rand(-sp, sp), 0)).LookVector
			local endPos, hit = hitscan(muzzle, dir, W.damage, W.cityDamage)
			FX.beam(muzzle, endPos, Color3.fromRGB(255, 220, 120), 0.18, 0.06)
			if hit and shotCount % 2 == 0 then
				FX.spark(hit.Position, Color3.fromRGB(255, 200, 100), 5, 20)
			end
			if shotCount % 2 == 0 then
				FX.sound(CONFIG.SOUNDS.gun, 0.25, 1.8)
			end
			FX.shake(0.03)
			rig.anim.armR = rig.anim.armR * CFrame.new(0, 0.15, 0)
		elseif weapon == "plasma" then
			E.fireProjectile({
				from = muzzle,
				dir = dir,
				speed = W.speed,
				color = t.accent,
				size = 1.8 * Mech.scale,
				damage = W.damage,
				radius = W.radius,
				cityDamage = W.cityDamage,
				friendly = true,
				life = 4,
			})
			FX.spark(muzzle, t.accent, 15, 20)
			FX.sound(CONFIG.SOUNDS.missile, 0.8, 0.6)
			FX.shake(0.5)
			rig.anim.armR = rig.anim.armR * CFrame.new(0, 1.2, 0)
		elseif weapon == "flame" then
			if rig.flame then
				rig.flame.Enabled = true
			end
			for _, e in ipairs(table.clone(E.list)) do
				local center = e.pos + e.centerOffset
				local to = center - muzzle
				if to.Magnitude < W.range + e.radius and to.Unit:Dot(dir) > 0.93 then
					E.damage(e, W.damage, center, shotCount % 5 ~= 0)
				end
			end
			if shotCount % 2 == 0 then
				-- o jato de fogo queima o que estiver na frente
				local hit = workspace:Raycast(muzzle, dir * W.range * Mech.scale, rayAim)
				if hit then
					local unit = City.partInfo[hit.Instance]
					if unit then
						City.damageUnit(unit, W.cityDamage * 2, hit.Position)
					end
					City.damageCity(hit.Position, 4 * Mech.scale, W.cityDamage)
					if math.random() < 0.02 then
						City.makeFire(hit.Position)
					end
				end
			end
		end
	end

	local function findMissileTarget()
		local best, bestDist = nil, 90
		for _, e in ipairs(E.list) do
			local d = (e.pos + e.centerOffset - State.aimPoint).Magnitude
			if d < bestDist then
				best, bestDist = e, d
			end
		end
		return best
	end

	function Weapons.fireMissiles()
		if State.cooldowns.missile > 0 or State.energy < CONFIG.MISSILE_COST then
			return
		end
		State.cooldowns.missile = CONFIG.MISSILE_COOLDOWN
		State.energy -= CONFIG.MISSILE_COST
		local target = findMissileTarget()
		local t = theme()
		local rig = Mech.rig
		for i = 1, math.min(Mech.def.missiles, #rig.pods) do
			local pod = rig.pods[i]
			local spawnCF = rig.world[pod.joint] * pod.offset
			local part = makePart({
				Name = "Missil",
				Size = Vector3.new(0.5, 0.5, 2.2),
				CFrame = spawnCF,
				Color = Color3.fromRGB(220, 220, 225),
				Material = Enum.Material.Metal,
				Parent = F.effects,
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
			local side = (i % 2 == 0) and 1 or -1
			table.insert(Weapons.missiles, {
				part = part,
				pos = spawnCF.Position,
				vel = spawnCF.LookVector * CONFIG.MISSILE_SPEED * 0.5 + spawnCF.RightVector * side * 20 + Vector3.new(0, 15, 0),
				target = target,
				targetPos = State.aimPoint,
				life = 6,
			})
		end
		FX.sound(CONFIG.SOUNDS.missile, 0.8)
		FX.shake(0.3)
	end

	function Weapons.updateMissiles(dt)
		for i = #Weapons.missiles, 1, -1 do
			local m = Weapons.missiles[i]
			m.life -= dt
			if m.target and m.target.alive then
				m.targetPos = m.target.pos + m.target.centerOffset
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
				FX.explosion(explodeAt, CONFIG.MISSILE_RADIUS * 0.6, Color3.fromRGB(255, 130, 30))
				Game.damageArea(explodeAt, CONFIG.MISSILE_RADIUS, CONFIG.MISSILE_DAMAGE)
				City.damageCity(explodeAt, CONFIG.MISSILE_RADIUS, 150)
				m.part:Destroy()
				table.remove(Weapons.missiles, i)
			else
				m.pos += step
				if step.Magnitude > 0.01 then
					m.part.CFrame = CFrame.lookAt(m.pos, m.pos + step)
				end
			end
		end
	end

	function Weapons.punch()
		if State.cooldowns.punch > 0 or State.energy < CONFIG.PUNCH_COST then
			return
		end
		State.cooldowns.punch = CONFIG.PUNCH_COOLDOWN
		State.energy -= CONFIG.PUNCH_COST
		State.punchTime = 0.3
		local power = Mech.def.punch
		local s = Mech.scale
		if power >= 2 then
			-- Investida do Berserker
			State.velocity += State.rootCF.LookVector * 90
			State.dashTime = 0.25
		end
		FX.sound(CONFIG.SOUNDS.punch, 0.9, 0.6)
		task.delay(0.1, function()
			if State.dead then
				return
			end
			local hitPos = (State.rootCF * CFrame.new(-1.5 * s, 4 * s, -7 * s)).Position
			City.damageCity(hitPos, 7 * s, 220 * power)
			Game.damageArea(hitPos, 9 * s, 140 * power)
			FX.spark(hitPos, theme().accent, 25, 35)
			FX.shake(0.5 * power)
		end)
	end

	function Weapons.toggleShield()
		if not State.shield and State.energy < 10 then
			Game.notify("ENERGIA INSUFICIENTE", Color3.fromRGB(255, 170, 60))
			return
		end
		State.shield = not State.shield
		FX.sound(CONFIG.SOUNDS.whoosh, 0.5, State.shield and 1.6 or 0.8)
		Game.notify(State.shield and "ESCUDO ATIVADO" or "ESCUDO DESATIVADO")
	end

	function Weapons.toggleFlight()
		if not Mech.def.canFly then
			Game.notify(Mech.def.name .. " NÃO VOA — use o pulo (Espaço)", Color3.fromRGB(255, 170, 60))
			return
		end
		if not State.flying and State.energy < 10 then
			Game.notify("ENERGIA INSUFICIENTE", Color3.fromRGB(255, 170, 60))
			return
		end
		State.flying = not State.flying
		if State.flying then
			State.velocity += Vector3.new(0, 30, 0)
		end
		Game.notify(State.flying and "MODO VOO" or "MODO CAMINHADA")
	end

	function Weapons.scan()
		if State.cooldowns.scan > 0 or State.energy < CONFIG.SCAN_COST then
			return
		end
		State.cooldowns.scan = CONFIG.SCAN_COOLDOWN
		State.energy -= CONFIG.SCAN_COST
		local ball = makePart({
			Shape = BALL,
			Size = Vector3.one * 4,
			Position = Game.torsoCenter(),
			Color = theme().accent,
			Material = Enum.Material.ForceField,
			CastShadow = false,
			Parent = F.effects,
		})
		TweenService:Create(ball, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.one * CONFIG.SCAN_RANGE * 2,
			Transparency = 1,
		}):Play()
		Debris:AddItem(ball, 1.3)
		local found = 0
		for _, e in ipairs(E.list) do
			if (e.pos - State.rootCF.Position).Magnitude <= CONFIG.SCAN_RANGE then
				found += 1
				local h = new("Highlight", {
					FillColor = e.color,
					OutlineColor = Color3.new(1, 1, 1),
					FillTransparency = 0.4,
					Adornee = e.model,
					Parent = e.model,
				})
				Debris:AddItem(h, 6)
			end
		end
		FX.sound(CONFIG.SOUNDS.laser, 0.6, 0.6)
		Game.notify(("SCANNER: %d ALVO(S) DETECTADO(S)"):format(found))
	end

	function Weapons.shockwave()
		local s = Mech.scale
		local pos = State.rootCF.Position - Vector3.new(0, Game.hip() - 0.3, 0)
		local ring = makePart({
			Shape = CYL,
			Size = Vector3.new(0.6, 4, 4),
			CFrame = CFrame.new(pos) * AXIS_Y,
			Color = theme().accent,
			Material = Enum.Material.Neon,
			CastShadow = false,
			Parent = F.effects,
		})
		TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.3, CONFIG.SLAM_RADIUS * 2 * s, CONFIG.SLAM_RADIUS * 2 * s),
			Transparency = 1,
		}):Play()
		Debris:AddItem(ring, 0.7)
		FX.explosion(pos, 10 * s, theme().accent)
		FX.dust(pos, 12, 1)
		Game.damageArea(pos, CONFIG.SLAM_RADIUS * 1.5 * s, CONFIG.SLAM_DAMAGE)
		City.damageCity(pos, CONFIG.SLAM_RADIUS * s, 200)
		FX.shake(2)
	end

	function Weapons.groundSlam()
		if State.cooldowns.slam > 0 or State.energy < CONFIG.SLAM_COST then
			return
		end
		State.cooldowns.slam = CONFIG.SLAM_COOLDOWN
		State.energy -= CONFIG.SLAM_COST
		if State.onGround then
			Weapons.shockwave()
		else
			State.flying = false
			State.slamming = true
			FX.sound(CONFIG.SOUNDS.whoosh, 0.9, 0.7)
		end
	end

	function Weapons.onLand(fallSpeed)
		if State.slamming then
			State.slamming = false
			Weapons.shockwave()
		elseif fallSpeed > 50 then
			local feet = State.rootCF.Position - Vector3.new(0, Game.hip(), 0)
			FX.shake(fallSpeed / 120)
			FX.spark(feet, Color3.fromRGB(130, 120, 110), 20, 20)
			FX.sound(CONFIG.SOUNDS.land, 1, 0.6)
			City.damageCity(feet, 6 * Mech.scale, fallSpeed)
		end
	end

	function Weapons.jump()
		if State.flying then
			return
		end
		if State.onGround then
			State.velocity = Vector3.new(State.velocity.X, Mech.def.jump, State.velocity.Z)
			FX.sound(CONFIG.SOUNDS.jump, 0.8, 0.7)
		elseif State.energy >= CONFIG.JET_BOOST_COST then
			State.energy -= CONFIG.JET_BOOST_COST
			State.velocity = Vector3.new(State.velocity.X, Mech.def.jump * 0.9, State.velocity.Z)
			State.jetBoost = 0.5
			FX.sound(CONFIG.SOUNDS.whoosh, 0.7, 1.2)
		end
	end

	function Weapons.selfDestruct()
		if State.destructArmed > 0 then
			State.destructArmed = 0
			local center = Game.torsoCenter()
			Game.damageArea(center, 70, 999)
			City.damageCity(center, 60, 600)
			destroyRobot()
		else
			State.destructArmed = 2
			Game.notify("AUTODESTRUIÇÃO: aperte X de novo para confirmar", Color3.fromRGB(255, 60, 60))
		end
	end
end

---------------------------------------------------------------------------------------
-- FLUXO DO JOGO (menu, partida, pausa, fim)
---------------------------------------------------------------------------------------
local PLAZA_SPAWN = Vector3.new(0, 5, 34)

local function clearCombat()
	E.clear()
	for _, m in ipairs(Weapons.missiles) do
		m.part:Destroy()
	end
	table.clear(Weapons.missiles)
end

local function updateBest()
	State.best[State.mode] = math.max(State.best[State.mode], State.score)
	UI.bestLabel.Text = ("RECORDE MISSÃO: %d\nRECORDE LIVRE: %d"):format(State.best.missao, State.best.livre)
end

function Game.placeRobotInPlaza()
	State.yaw = 0
	State.rootCF = CFrame.new(0, findGroundY(Vector3.new(0, 0, 18)) + Game.hip(), 18)
	State.velocity = Vector3.zero
	Rig.compute(Mech.rig, State.rootCF, nil)
	Rig.apply(Mech.rig)
end

function Game.startGame(mode)
	if State.gameState == "loading" then
		return
	end
	UI.menuFrame.Visible = false
	UI.gameOverFrame.Visible = false
	UI.pauseFrame.Visible = false
	State.showHelp = false
	if State.piloting then
		Pilot.exit(true)
	end
	clearCombat()
	if City.dirty then
		State.gameState = "loading"
		City.generate()
	end

	State.runId += 1
	State.mode = mode
	State.dead = false
	State.health = Mech.def.health
	State.energy = CONFIG.MAX_ENERGY
	State.lives = CONFIG.LIVES
	State.flying = false
	State.shield = false
	State.slamming = false
	State.score = 0
	State.combo = 0
	State.wave = 0
	State.kills = 0
	State.playTime = 0
	State.nextWaveTimer = 5
	State.shake = 0
	for k in pairs(State.cooldowns) do
		State.cooldowns[k] = 0
	end

	local hrp = Pilot.parts()
	if hrp then
		hrp.Anchored = false
		hrp.CFrame = CFrame.new(PLAZA_SPAWN)
	end
	Game.placeRobotInPlaza()
	Rig.setVisible(Mech.rig, true)

	State.gameState = "playing"
	camera.CameraType = Enum.CameraType.Custom
	Pilot.enter(true)
	if mode == "missao" then
		Game.notify("MODO MISSÃO — sobreviva às ondas!", Color3.fromRGB(255, 200, 60))
	else
		Game.notify("MODO LIVRE — destrua a cidade!", Color3.fromRGB(255, 200, 60))
	end
end

function Game.showMenu()
	if State.gameState == "playing" or State.gameState == "paused" or State.gameState == "gameover" then
		updateBest()
	end
	if State.piloting then
		Pilot.exit(true)
	end
	clearCombat()
	State.gameState = "menu"
	State.runId += 1
	State.dead = false
	Rig.setVisible(Mech.rig, true)
	Pilot.setControls(false)
	UI.menuFrame.Visible = true
	UI.pauseFrame.Visible = false
	UI.gameOverFrame.Visible = false
	State.showHelp = false
	Game.placeRobotInPlaza()
	updateBest()
end

local function pauseGame()
	if State.gameState ~= "playing" then
		return
	end
	State.gameState = "paused"
	State.firing = false
	UI.pauseFrame.Visible = true
	Pilot.setControls(false)
end

function Game.resumeGame()
	if State.gameState ~= "paused" then
		return
	end
	State.gameState = "playing"
	UI.pauseFrame.Visible = false
	Pilot.setControls(not State.piloting)
end

function Game.gameOver()
	updateBest()
	State.gameState = "gameover"
	if State.piloting then
		Pilot.exit(true)
	end
	clearCombat()
	Pilot.setControls(false)
	local minutes = math.floor(State.playTime / 60)
	local seconds = math.floor(State.playTime % 60)
	local destruction = City.totalMass > 0 and City.lostMass / City.totalMass * 100 or 0
	UI.gameOverStats.Text = table.concat({
		("ROBÔ: %s"):format(Mech.def.name),
		("PONTOS: %d"):format(State.score),
		("RECORDE: %d"):format(State.best[State.mode]),
		("ONDAS: %d"):format(State.wave),
		("INIMIGOS ABATIDOS: %d"):format(State.kills),
		("PRÉDIOS DERRUBADOS: %d"):format(City.buildingsDestroyed),
		("DESTRUIÇÃO DA CIDADE: %d%%"):format(math.floor(destruction)),
		("TEMPO: %d:%02d"):format(minutes, seconds),
	}, "\n")
	UI.gameOverFrame.Visible = true
end

local function swapRobot(index)
	if index == Mech.index or State.dead then
		return
	end
	local pos = State.rootCF.Position - Vector3.new(0, Game.hip(), 0)
	FX.explosion(pos + Vector3.new(0, 5, 0), 10, theme().accent)
	Game.setRobot(index)
	State.rootCF = CFrame.new(pos + Vector3.new(0, Game.hip(), 0)) * CFrame.Angles(0, State.yaw, 0)
	State.energy = CONFIG.MAX_ENERGY
	Game.notify("ROBÔ: " .. Mech.def.name, theme().accent)
end

---------------------------------------------------------------------------------------
-- ENTRADA (TECLADO / MOUSE)
---------------------------------------------------------------------------------------
local ROBOT_KEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4 }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local key = input.KeyCode

	if key == Enum.KeyCode.P then
		if State.gameState == "playing" then
			pauseGame()
		elseif State.gameState == "paused" then
			Game.resumeGame()
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
			Pilot.exit()
		else
			Pilot.enter()
		end
		return
	elseif key == Enum.KeyCode.N then
		Lighting.ClockTime = (Lighting.ClockTime + 6) % 24
		Game.notify(("RELÓGIO: %02d:00"):format(math.floor(Lighting.ClockTime)))
		return
	end

	if not State.piloting or State.dead then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.firing = true
	elseif key == Enum.KeyCode.Space then
		Weapons.jump()
	elseif key == Enum.KeyCode.B then
		Weapons.punch()
	elseif key == Enum.KeyCode.F then
		Weapons.toggleFlight()
	elseif key == Enum.KeyCode.E then
		Weapons.fireMissiles()
	elseif key == Enum.KeyCode.Q then
		Weapons.toggleShield()
	elseif key == Enum.KeyCode.R then
		Weapons.scan()
	elseif key == Enum.KeyCode.G then
		Weapons.groundSlam()
	elseif key == Enum.KeyCode.L then
		State.lights = not State.lights
		Game.notify(State.lights and "FARÓIS LIGADOS" or "FARÓIS DESLIGADOS")
	elseif key == Enum.KeyCode.C then
		State.themeIndex = State.themeIndex % #THEMES + 1
		Game.applyTheme()
		Game.notify("TEMA: " .. theme().name:upper())
	elseif key == Enum.KeyCode.K then
		State.waveTime = 3
	elseif key == Enum.KeyCode.T then
		if State.mode == "livre" then
			E.spawnWave()
		else
			Game.notify("NO MODO MISSÃO AS ONDAS VÊM SOZINHAS!", Color3.fromRGB(255, 170, 60))
		end
	elseif ROBOT_KEYS[key] then
		if State.mode == "livre" then
			swapRobot(ROBOT_KEYS[key])
		else
			Game.notify("TROQUE DE ROBÔ NA GARAGEM DO MENU", Color3.fromRGB(255, 170, 60))
		end
	elseif key == Enum.KeyCode.X then
		Weapons.selfDestruct()
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
	local def = Mech.def
	local s = Mech.scale
	local hip = Game.hip()
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
	local dashing = (State.dashTime or 0) > 0

	if State.flying then
		local speed = State.turbo and def.flyTurbo or def.flySpeed
		local up = 0
		if canControl then
			if isDown(Enum.KeyCode.Space) then up += 1 end
			if isDown(Enum.KeyCode.LeftControl) then up -= 1 end
		end
		local desired = moveDir * speed + Vector3.new(0, up * speed * 0.6, 0)
		vel = vel:Lerp(desired, math.min(1, dt * 4))
	else
		local speed = State.turbo and def.turbo or def.walk
		local horizontal = Vector3.new(vel.X, 0, vel.Z)
		if not dashing then
			horizontal = horizontal:Lerp(moveDir * speed, math.min(1, dt * (State.onGround and 10 or 2.5)))
		end
		local vy = State.slamming and -220 or (vel.Y - CONFIG.GRAVITY * dt)
		vel = Vector3.new(horizontal.X, vy, horizontal.Z)
	end

	-- Paredes: com turbo/investida (ou contra objetos pequenos) o robô quebra o que
	-- estiver na frente; se não quebrar, desliza ao longo da parede
	local horizontal = Vector3.new(vel.X, 0, vel.Z)
	if horizontal.Magnitude > 0.01 then
		local hit = workspace:Raycast(pos + Vector3.new(0, 2 * s, 0), horizontal.Unit * (horizontal.Magnitude * dt + 2.5 * s), rayWorld)
		if hit and hit.Normal.Y < 0.6 then
			local unit = City.partInfo[hit.Instance]
			if unit and (State.turbo or dashing or unit.kind == "prop" or unit.kind == "car") then
				City.damageUnit(unit, 250 * math.max(1, s), hit.Position)
				FX.shake(0.4)
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
	local groundHit = workspace:Raycast(newPos + Vector3.new(0, 4 * s, 0), Vector3.new(0, -(hip + 7 * s), 0), rayWorld)
	if groundHit and vel.Y <= 0.01 then
		local standY = groundHit.Position.Y + hip
		local sticking = wasOnGround and not State.flying and newPos.Y - standY < 1.5 * s
		if newPos.Y <= standY or sticking then
			newPos = Vector3.new(newPos.X, standY, newPos.Z)
			if not wasOnGround then
				Weapons.onLand(-vel.Y)
			end
			vel = Vector3.new(vel.X, 0, vel.Z)
			State.onGround = true
		end
	end

	-- Caiu no vazio: volta para a praça
	if newPos.Y < workspace.FallenPartsDestroyHeight + 30 then
		newPos = Vector3.new(0, findGroundY(Vector3.new(0, 200, 18)) + hip, 18)
		vel = Vector3.zero
		Game.notify("ROBÔ RESGATADO DO VAZIO", Color3.fromRGB(255, 170, 60))
	end

	if canControl then
		State.yaw = lerpAngle(State.yaw, State.camYaw, math.min(1, dt * CONFIG.TURN_SPEED))
	end
	State.velocity = vel
	State.rootCF = CFrame.new(newPos) * CFrame.Angles(0, State.yaw, 0)
end

local function updateEnergy(dt)
	local drain = 0
	if State.flying then drain += Mech.def.flyDrain end
	if State.shield then drain += CONFIG.SHIELD_DRAIN end
	if State.turbo then drain += CONFIG.TURBO_DRAIN end
	local regen = drain > 0 and 0 or Mech.def.energyRegen
	State.energy = math.clamp(State.energy + (regen - drain) * dt, 0, CONFIG.MAX_ENERGY)
	if State.energy <= 0 then
		if State.flying then
			State.flying = false
			Game.notify("SEM ENERGIA PARA VOAR", Color3.fromRGB(255, 170, 60))
		end
		State.shield = false
	end
	Mech.shield.Transparency = (State.shield and not State.dead) and 0 or 1
	Mech.shield.CFrame = State.rootCF * CFrame.new(0, 2.5 * Mech.scale, 0)
	Mech.rig.smoke.Enabled = not State.dead and State.health < Mech.def.health * 0.35
end

---------------------------------------------------------------------------------------
-- CÂMERA E MIRA
---------------------------------------------------------------------------------------
local function updateCamera(dt)
	camera.CameraType = Enum.CameraType.Scriptable
	local s = Mech.scale
	local focus = State.rootCF.Position + Vector3.new(0, 7.5 * s, 0)
	local rotation = CFrame.Angles(0, State.camYaw, 0) * CFrame.Angles(State.camPitch, 0, 0)
	local desired = (CFrame.new(focus) * rotation * CFrame.new(3 * s, 1.5 * s, State.camDist * s)).Position
	local dir = desired - focus
	local hit = workspace:Raycast(focus, dir, rayWorld)
	local camPos = hit and (hit.Position - dir.Unit) or desired

	State.shake = math.max(0, State.shake - dt * 3)
	local k = State.shake * 0.04
	local shakeCF = CFrame.Angles((math.random() - 0.5) * k, (math.random() - 0.5) * k, (math.random() - 0.5) * k)
	camera.CFrame = CFrame.new(camPos) * rotation * shakeCF

	local targetFov = (State.turbo or (State.dashTime or 0) > 0) and 85 or 70
	camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 5)

	local camCF = camera.CFrame
	local aimHit = workspace:Raycast(camCF.Position, camCF.LookVector * CONFIG.LASER_RANGE, rayAim)
	State.aimPoint = aimHit and aimHit.Position or camCF.Position + camCF.LookVector * CONFIG.LASER_RANGE
end

-- Câmera do menu: gira ao redor do robô escolhido (vitrine da garagem)
local function updateMenuCamera(dt)
	State.menuAngle += dt * 0.12
	camera.CameraType = Enum.CameraType.Scriptable
	local s = Mech.scale
	local focus = State.rootCF.Position + Vector3.new(0, 2 * s, 0)
	local a = State.menuAngle
	local camPos = focus + Vector3.new(math.cos(a) * 26 * s, 6 * s, math.sin(a) * 26 * s)
	local base = CFrame.lookAt(camPos, focus)
	camera.CFrame = CFrame.lookAt(camPos, focus - base.RightVector * 7 * s)
	camera.FieldOfView = 70
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
	local def = Mech.def

	local hpRatio = math.clamp(State.health / def.health, 0, 1)
	UI.hpFill.Size = UDim2.fromScale(hpRatio, 1)
	UI.hpFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(60, 220, 90), hpRatio)
	UI.hpText.Text = ("INTEGRIDADE  %d / %d"):format(math.max(0, math.floor(State.health)), def.health)
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
	local altitude = State.rootCF.Position.Y - Game.hip() - findGroundY(State.rootCF.Position)
	UI.infoLabels[1].Text = ("MODO: %s   VEL: %d"):format(mode, math.floor(State.velocity.Magnitude))
	UI.infoLabels[2].Text = ("ALTITUDE: %d   HORA: %02d:%02d"):format(
		math.floor(math.max(0, altitude)),
		math.floor(Lighting.ClockTime),
		math.floor(Lighting.ClockTime % 1 * 60)
	)
	UI.infoLabels[3].Text = ("PONTOS: %d   ABATES: %d"):format(State.score, State.kills)
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

	-- Combo
	local mult = math.min(5, 1 + math.floor(State.combo / 10))
	UI.comboLabel.Text = mult > 1 and ("COMBO x%d"):format(mult) or ""

	-- Objetivo
	if State.mode == "missao" then
		local boss
		for _, e in ipairs(E.list) do
			if e.kind == "boss" then
				boss = e
			end
		end
		if boss then
			UI.objectiveLabel.Text = ("ONDA %d — DERROTE A NAVE-MÃE (%d%%)"):format(State.wave, math.floor(boss.hp / boss.maxHp * 100))
			UI.objectiveLabel.TextColor3 = Color3.fromRGB(210, 120, 255)
		elseif #E.list > 0 then
			UI.objectiveLabel.Text = ("ONDA %d — INIMIGOS RESTANTES: %d"):format(State.wave, #E.list)
			UI.objectiveLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
		else
			UI.objectiveLabel.Text = ("PRÓXIMA ONDA EM %d s"):format(math.ceil(State.nextWaveTimer or 0))
			UI.objectiveLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
		end
	else
		UI.objectiveLabel.Text = ("MODO LIVRE — DESTRUIÇÃO %d%%"):format(math.floor(destruction))
		UI.objectiveLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	end

	local cooldownMax = { missile = CONFIG.MISSILE_COOLDOWN, scan = CONFIG.SCAN_COOLDOWN, slam = CONFIG.SLAM_COOLDOWN, punch = CONFIG.PUNCH_COOLDOWN }
	for id, max in pairs(cooldownMax) do
		UI.slotUI[id].overlay.Size = UDim2.fromScale(1, math.clamp(State.cooldowns[id] / max, 0, 1))
	end
	local toggles = { shield = State.shield, fly = State.flying, lights = State.lights, weapon = State.firing }
	for id, on in pairs(toggles) do
		UI.slotUI[id].stroke.Color = on and theme().accent or Color3.fromRGB(90, 95, 110)
		UI.slotUI[id].stroke.Thickness = on and 3 or 1.5
	end
	UI.slotUI.fly.overlay.Size = UDim2.fromScale(1, def.canFly and 0 or 1)

	UI.crosshair.Visible = State.piloting and not State.dead
	UI.abilityBar.Visible = State.piloting

	if State.piloting then
		UI.promptLabel.Text = ""
	else
		local hrp = Pilot.parts()
		local near = hrp and (hrp.Position - State.rootCF.Position).Magnitude <= CONFIG.ENTER_DISTANCE * Mech.scale
		UI.promptLabel.Text = near and "Aperte  V  para ENTRAR no robô" or "Aperte  V  para CONVOCAR o robô"
	end

	-- Radar
	for i, e in ipairs(E.list) do
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
		local rel = State.rootCF:PointToObjectSpace(e.pos)
		local flat = Vector2.new(rel.X, rel.Z) / UI.RADAR_RANGE * 80
		if flat.Magnitude > 78 then
			flat = flat.Unit * 78
		end
		blip.Position = UDim2.new(0.5, flat.X, 0.5, flat.Y)
		blip.Size = e.kind == "boss" and UDim2.fromOffset(13, 13) or (e.kind == "drone" and UDim2.fromOffset(6, 6) or UDim2.fromOffset(9, 9))
		blip.BackgroundColor3 = e.color
		blip.Visible = true
	end
	for i = #E.list + 1, #UI.radarBlips do
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
	State.punchTime = math.max(0, State.punchTime - dt)
	State.waveTime = math.max(0, State.waveTime - dt)
	State.dashTime = math.max(0, (State.dashTime or 0) - dt)
	State.comboTimer -= dt
	if State.comboTimer <= 0 then
		State.combo = 0
	end

	-- Ondas automáticas no modo missão
	if gs == "playing" then
		State.playTime += dt
		if State.mode == "missao" and not State.dead and #E.list == 0 then
			State.nextWaveTimer = (State.nextWaveTimer or CONFIG.WAVE_DELAY) - dt
			if State.nextWaveTimer <= 0 then
				State.nextWaveTimer = nil
				E.spawnWave()
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

	local rig = Mech.rig
	local aiming = State.piloting and not State.dead and gs == "playing"
	local W = CONFIG.WEAPONS[Mech.def.weapon]
	if aiming and State.firing and State.cooldowns.laser <= 0 and State.energy >= W.cost then
		State.cooldowns.laser = W.rate
		State.energy -= W.cost
		Rig.compute(rig, State.rootCF, State.aimPoint)
		Weapons.firePrimary()
	end
	if rig.flame and (not State.firing or not aiming) then
		rig.flame.Enabled = false
	end

	local stepped = Rig.animate(rig, dt, {
		vel = State.velocity,
		rootCF = State.rootCF,
		onGround = State.onGround,
		flying = State.flying,
		aiming = aiming,
		aimPoint = State.aimPoint,
		waving = State.waveTime > 0,
		punching = State.punchTime > 0.1,
		slamming = State.slamming,
		turbo = State.turbo,
		jetBoost = State.jetBoost,
		dead = State.dead,
		clock = clock,
	})
	rig.headlight.Enabled = State.lights and not State.dead
	if stepped then
		FX.sound(CONFIG.SOUNDS.land, 0.4, 0.5 / Mech.scale)
		if State.piloting then
			FX.shake(0.12 * Mech.scale)
		end
		City.damageCity(State.rootCF.Position - Vector3.new(0, Game.hip() - 1, 0), 3.5 * Mech.scale, 40 * Mech.scale)
	end
	Rig.compute(rig, State.rootCF, aiming and State.aimPoint or nil)
	if not State.dead then
		Rig.apply(rig)
	end

	-- Mantém o piloto escondido dentro do peito do robô
	if State.piloting then
		local hrp = Pilot.parts()
		if hrp then
			hrp.CFrame = rig.world.torso * CFrame.new(0, 3.5 * Mech.scale, 0)
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		Pilot.setHidden(true)
	end

	Weapons.updateMissiles(dt)
	E.update(dt)
	E.updateProjectiles(dt)
	E.updatePickups(dt)
	City.update(dt)
	updateHUD()
end

---------------------------------------------------------------------------------------
-- INÍCIO
---------------------------------------------------------------------------------------
task.spawn(function()
	RunService:BindToRenderStep("RoboTitan", Enum.RenderPriority.Camera.Value + 1, mainLoop)
	City.generate()
	Game.showMenu()
end)
