--!nonstrict
--[[
	TUDO VOA! — Ilhas do Caos
	Configuracao central. Quase tudo que da pra "balancear" mora aqui.
	Unidades: studs, segundos. Gravidade do Roblox = 196.2 studs/s^2.
]]

local Config = {}

Config.GameName = "TUDO VOA!"
Config.Subtitle = "Ilhas do Caos"
Config.Version = "1.0"

-- Nomes de tags (CollectionService)
Config.Tags = {
	Grabbable = "TV_Grabbable", -- qualquer coisa que o cabo pode agarrar (raiz da montagem)
	Toy = "TV_Toy",
	Airborne = "TV_Airborne", -- brinquedo arremessado, sob controle do dono
	Spin = "TV_Spin", -- decoracao que gira (animada no cliente)
	Bob = "TV_Bob", -- decoracao que flutua (animada no cliente)
	Sway = "TV_Sway", -- balanca (arvores, bandeiras)
	Pulse = "TV_Pulse", -- brilho pulsante
	Conveyor = "TV_Conveyor",
	Target = "TV_Target",
}

-- Grupos de colisao
Config.Groups = {
	Players = "TV_Players",
	Held = "TV_Held",
	Default = "Default",
}

Config.World = {
	Seed = 20260929,
	SeaLevel = 0,
	HubHeight = 26,
	HubRadius = 105, -- praca central plana
	IslandRadius = 700, -- raio da ilha principal
	Half = 800, -- metade da area de terreno gerada (studs)
	BedrockY = -56,
	Voxel = 4,
	SkyY = 380, -- altura das ilhas flutuantes
	KillY = -140, -- abaixo disso o jogador "cai do mundo"
	SpawnOffset = Vector3.new(0, 0, 0),
	Village = Vector3.new(160, 0, 160), -- centro da Vila dos Jogadores (terreno plano, longe dos biomas)
}

-- Regioes nomeadas (usadas para mostrar "voce entrou em..." e distribuir brinquedos)
-- Centros em coordenadas do mundo (x, z). y e calculado pela altura do terreno.
Config.Biomes = {
	Hub = { name = "Praça Cósmica", icon = "🌀", center = Vector2.new(0, 0), radius = 150 },
	Farm = { name = "Fazenda Maluca", icon = "🐷", center = Vector2.new(-470, 20), radius = 240 },
	Snow = { name = "Montanha Gelada", icon = "🏔️", center = Vector2.new(-30, -480), radius = 260 },
	Volcano = { name = "Vulcão Furioso", icon = "🌋", center = Vector2.new(480, -40), radius = 250 },
	Beach = { name = "Praia dos Ventos", icon = "🏖️", center = Vector2.new(20, 390), radius = 250 },
}

Config.Palette = {
	Ink = Color3.fromRGB(20, 22, 44),
	Panel = Color3.fromRGB(28, 31, 62),
	PanelLight = Color3.fromRGB(44, 49, 92),
	Accent = Color3.fromRGB(255, 196, 61),
	Accent2 = Color3.fromRGB(94, 234, 212),
	Pink = Color3.fromRGB(255, 92, 168),
	Purple = Color3.fromRGB(150, 98, 255),
	Blue = Color3.fromRGB(70, 160, 255),
	Green = Color3.fromRGB(96, 226, 118),
	Red = Color3.fromRGB(255, 84, 84),
	White = Color3.fromRGB(245, 247, 255),
	Muted = Color3.fromRGB(150, 158, 200),
}

-- Cabo de energia -----------------------------------------------------------
Config.Grab = {
	BaseRange = 46, -- distancia maxima para agarrar (studs)
	RangePerLevel = 7, -- +alcance por nivel do upgrade "Alcance"
	HoldMin = 5,
	HoldDefault = 13,
	HoldMaxBase = 26,
	HoldMaxPerLevel = 4,
	ScrollStep = 2.5,
	MaxMassBase = 300, -- massa maxima agarravel
	MaxMassPerLevel = 350, -- por nivel do upgrade "Força"
	Responsiveness = 55,
	MaxVelocity = 190,
	OrientResponsiveness = 32,
	ServerLeash = 30, -- se o objeto ficar mais longe que HoldMax + isso, solta
	CharacterGrabCooldown = 0.6, -- depois de soltar alguem, quanto espera para agarrar de novo
	ReleaseGrace = 0.35, -- depois do arremesso, "Held" continua sem colidir com o lancador
	OwnerLinger = 3.5, -- tempo que o lancador segue dono da fisica depois de soltar
}

Config.Throw = {
	MinSpeed = 42,
	MaxSpeed = 235,
	ChargeTime = 1.15, -- segundos para carga total
	MinCharge = 0.12,
	RefMass = 14, -- massa "normal": objetos mais pesados saem mais devagar
	MassExponent = 0.34,
	PowerPerLevel = 0.08, -- +8% de forca por nivel do upgrade "Potência"
	MaxSpeedHard = 420, -- teto absoluto aceito pelo servidor
	Spin = 9, -- rotacao aleatoria aplicada no arremesso
	DistanceMin = 40, -- alcance minimo para contar recorde/recompensa
	LandSpeed = 4,
	LandTime = 0.7,
	TrackTimeout = 18,
}

Config.Ragdoll = {
	StruggleNeeded = 22, -- toques de espernear para escapar (base)
	StrugglePerLevel = 5, -- menos toques por nivel do upgrade "Escapar"
	StruggleDecay = 3.2, -- por segundo
	StruggleMax = 1.0,
	MinDuration = 1.6,
	ImpactSpeed = 55, -- velocidade de impacto minima para derrubar alguem
	ImpactCooldown = 0.5,
	GetUpAfter = 1.4, -- pode levantar apos isso (pressione espaco)
	MaxDuration = 12,
	RestSpeed = 6, -- abaixo disso e considerado parado
}

Config.Progression = {
	XPBase = 90,
	XPExponent = 1.32,
	MaxLevel = 60,
	SkillPointEvery = 1,
	SaveInterval = 60,
	StoreName = "TudoVoa_v1",
	BoardStoreName = "TudoVoa_BestThrow_v1",
}

-- Upgrades comprados com pontos de habilidade
Config.Upgrades = {
	Power = { name = "Potência", icon = "💪", max = 10, desc = "+8% de força nos arremessos" },
	Range = { name = "Alcance", icon = "📡", max = 8, desc = "Agarre de mais longe" },
	Strength = { name = "Força", icon = "🦍", max = 8, desc = "Agarre objetos mais pesados" },
	Cooldown = { name = "Recarga", icon = "⏱️", max = 8, desc = "-6% na recarga das habilidades" },
	Escape = { name = "Escapar", icon = "🕊️", max = 6, desc = "Escape mais rápido quando te agarram" },
	DoubleTether = { name = "Cabo Duplo", icon = "🔗", max = 1, desc = "Segure dois objetos ao mesmo tempo" },
}

-- Cores de cabo (nome -> cor). "Arco-íris" e especial.
Config.TetherColors = {
	{ id = "Roxo", name = "Roxo Cósmico", color = Color3.fromRGB(170, 90, 255), price = 0, level = 1 },
	{ id = "Ciano", name = "Ciano Elétrico", color = Color3.fromRGB(60, 230, 255), price = 0, level = 1 },
	{ id = "Rosa", name = "Rosa Choque", color = Color3.fromRGB(255, 80, 170), price = 0, level = 1 },
	{ id = "Verde", name = "Verde Radioativo", color = Color3.fromRGB(110, 255, 90), price = 150, level = 3 },
	{ id = "Ouro", name = "Ouro Sólido", color = Color3.fromRGB(255, 205, 60), price = 400, level = 6 },
	{ id = "Fogo", name = "Fogo Vivo", color = Color3.fromRGB(255, 110, 40), price = 600, level = 9 },
	{ id = "Gelo", name = "Gelo Ártico", color = Color3.fromRGB(170, 230, 255), price = 800, level = 12 },
	{ id = "Vazio", name = "Vazio Negro", color = Color3.fromRGB(90, 40, 140), price = 1500, level = 18 },
	{ id = "Arco", name = "Arco-íris", color = Color3.fromRGB(255, 255, 255), price = 3000, level = 25, rainbow = true },
}

Config.Trails = {
	{ id = "Nenhum", name = "Sem rastro", price = 0, level = 1 },
	{ id = "Estrelas", name = "Estrelas", price = 250, level = 4 },
	{ id = "Fumaca", name = "Fumaça Colorida", price = 500, level = 8 },
	{ id = "Faiscas", name = "Faíscas", price = 900, level = 14 },
	{ id = "Cometa", name = "Cometa", price = 2000, level = 22 },
}

Config.Economy = {
	StartCoins = 60,
	DistanceCoinFactor = 0.13,
	DistanceCoinExponent = 0.92,
	HitCoins = 6,
	HitCooldownPerVictim = 4,
	ComboWindow = 6,
	ComboMax = 8,
	SlotCooldown = 900, -- maquina de moedas: 15 minutos
	SlotMin = 40,
	SlotMax = 260,
	MaxPlayerToys = 4,
	SpawnToyCooldown = 1.2,
}

-- Sons: usa os sons que ja vem no cliente do Roblox (rbxasset://). Se algum nao
-- existir na sua versao, simplesmente fica mudo. Troque por "rbxassetid://ID" se quiser.
Config.Sounds = {
	Grab = "rbxasset://sounds/switch.wav",
	Release = "rbxasset://sounds/button.wav",
	Charge = "rbxasset://sounds/electronicpingshort.wav",
	Throw = "rbxasset://sounds/swordslash.wav",
	Impact = "rbxasset://sounds/impact_explosion_03.mp3",
	Soft = "rbxasset://sounds/clickfast.wav",
	Coin = "rbxasset://sounds/electronicpingshort.wav",
	LevelUp = "rbxasset://sounds/victory.wav",
	Oof = "rbxasset://sounds/uuhhh.mp3",
	Splash = "rbxasset://sounds/impact_water.mp3",
	Explosion = "rbxasset://sounds/impact_explosion_03.mp3",
	Rocket = "rbxasset://sounds/Rocket whoosh 01.wav",
	Ui = "rbxasset://sounds/button.wav",
	Error = "rbxasset://sounds/snap.wav",
	Bounce = "rbxasset://sounds/action_jump_land.mp3",
	Jump = "rbxasset://sounds/action_jump.mp3",
}

return Config
