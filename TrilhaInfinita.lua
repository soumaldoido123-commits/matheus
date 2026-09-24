--[[
=====================================================================================
   TRILHA INFINITA 4x4
   Caminhonete off-road com física de suspensão realista num mapa infinito.
   Jogo completo em UM ÚNICO script (LocalScript).
=====================================================================================

  COMO INSTALAR
   1. Abra o Roblox Studio e crie um jogo novo do tipo "Baseplate".
   2. No Explorer: StarterPlayer > StarterPlayerScripts
   3. Clique no "+" ao lado de StarterPlayerScripts > LocalScript
   4. Apague o conteúdo do LocalScript e cole ESTE código inteiro.
   5. Aperte Play (F5).
   (Opcional) Som do motor: pegue um som de motor na Toolbox (aba Audio),
   copie o ID e cole em CONFIG.SOUNDS.engine, ex.: "rbxassetid://123456".

  O JOGO
   Siga a trilha. A cada trecho aparece um DESAFIO (troncos, pedras, lama,
   subida íngreme, ponte estreita sobre um cânion, travessia de rio, rampa,
   gangorra, encosta inclinada, toras soltas) e depois um POSTO.
   Nos postos há cargas: desça da caminhonete, pegue as cargas, coloque na
   CAÇAMBA e leve até o próximo posto sem deixar cair. Quanto mais longe,
   mais difícil fica. Os postos também reabastecem o combustível.

  CONTROLES NA CAMINHONETE
   W / S ........ Acelerar / frear e ré        A / D ........ Virar
   Espaço ....... Freio de mão                  F ............ Descer
   R ............ Desvirar / voltar para a trilha
   T ............ Tração 4x4 / 4x2              H ............ Faróis
   C ............ Câmera (perseguição, longe, capô)
   Botão direito do mouse + arrastar: olhar em volta
   V ............ Trocar cor da caminhonete     P ............ Pausar
   No ar: W/S inclinam para frente/trás e A/D giram.

  CONTROLES A PÉ
   WASD ......... Andar                         Espaço ...... Pular
   E ............ Pegar / soltar carga          Clique ...... Arremessar carga
   F ............ Entrar na caminhonete

  CONTROLE (GAMEPAD)
   Gatilho direito acelera, esquerdo freia, analógico vira,
   B freio de mão, Y entra/sai, X desvira.

  OBSERVAÇÃO
   Tudo é criado no cliente (LocalScript): é um jogo para 1 jogador.
   O script esconde a Baseplate e usa o terreno para gerar o mapa.
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
local terrain = workspace.Terrain

---------------------------------------------------------------------------------------
-- CONFIGURAÇÕES
---------------------------------------------------------------------------------------
local CONFIG = {
	-- Gravidade mais próxima da real (a padrão do Roblox, 196, é ~6x a real e deixa
	-- carros "pesados" demais para subir morros). Só vale para este jogador.
	GRAVITY = 70,

	-- Caminhonete
	CHASSIS_DENSITY = 1.6, -- massa da caminhonete (a carga soma por cima)
	ENGINE_FORCE = 0.8, -- força do motor na 1ª marcha, em "g"
	GEAR_TOP_SPEEDS = { 14, 26, 42, 60, 78, 95 }, -- velocidade máxima de cada marcha (studs/s)
	REVERSE_TOP_SPEED = 16,
	BRAKE_FORCE = 0.95, -- em "g"
	DRAG = 0.09,
	ROLLING_RESISTANCE = 0.015,

	SUSPENSION_REST = 2.4, -- curso da suspensão
	SUSPENSION_SAG = 0.35, -- quanto afunda parado (0.35 = 35% do curso): mais = mais mole
	DAMPING_BUMP = 0.25, -- amortecimento comprimindo (baixo = balança mais, estilo GTA 4)
	DAMPING_REBOUND = 0.42, -- amortecimento voltando
	ANTI_ROLL = 0.35, -- barra estabilizadora (0 = inclina muito nas curvas)
	WHEEL_RADIUS = 1.7,
	TIRE_GRIP = 1.15, -- aderência base dos pneus
	SLIP_SATURATION = 5, -- escorregamento lateral (studs/s) até a aderência máxima
	HANDBRAKE_GRIP = 0.15,
	FORCE_HEIGHT = 0.45, -- altura onde o pneu empurra (0 = no chão; maior = capota menos)

	STEER_MAX = 0.62, -- ângulo máximo das rodas parado (radianos)
	STEER_MIN = 0.18, -- ângulo máximo em alta velocidade
	STEER_SPEED = 2.6,
	STEER_RETURN = 3.6,
	AIR_CONTROL = 1.6,

	FUEL_ENABLED = true,
	FUEL_USE = 0.28, -- % por segundo acelerando no máximo

	-- Mundo
	SEGMENT = 320, -- distância entre postos
	TRAIL_HALF = 9, -- meia largura da trilha
	CHUNK = 128,
	VOXEL = 4,
	LOAD_RADIUS = 3, -- blocos de terreno carregados em volta (3 = 7x7)
	TREES_PER_CHUNK = 14,
	DAY_LENGTH = 600,

	SOUNDS = {
		engine = "", -- cole aqui o ID de um som de motor em loop (Toolbox > Audio)
		horn = "",
		impact = "rbxasset://sounds/collide.wav",
		pickup = "rbxasset://sounds/electronicpingshort.wav",
		deliver = "rbxasset://sounds/electronicpingshort.wav",
	},
}

local PAINTS = {
	{ name = "Vermelho", color = Color3.fromRGB(170, 30, 30) },
	{ name = "Laranja", color = Color3.fromRGB(220, 110, 20) },
	{ name = "Verde Militar", color = Color3.fromRGB(85, 100, 60) },
	{ name = "Azul", color = Color3.fromRGB(30, 70, 150) },
	{ name = "Preto", color = Color3.fromRGB(25, 25, 28) },
	{ name = "Branco", color = Color3.fromRGB(225, 225, 220) },
	{ name = "Amarelo", color = Color3.fromRGB(230, 180, 20) },
}

---------------------------------------------------------------------------------------
-- ESTADO
---------------------------------------------------------------------------------------
local State = {
	gameState = "loading", -- loading | menu | playing | paused
	seed = math.random(1, 50000) + 0.37,
	driving = false,
	paint = 1,
	camMode = 1,
	lights = false,
	fourWD = true,
	fuel = 100,
	score = 0,
	bestZ = 0,
	outpostsReached = 0,
	lastOutpost = 0,
	delivered = 0,
	challengesDone = {},
	outpostsDone = {},
	carrying = nil :: any,
	resetCooldown = 0,
	flipTimer = 0,
	shake = 0,
	camYawOffset = 0,
	camPitchOffset = 0,
	camLookTimer = 0,
	menuAngle = 0,
	showHelp = false,
	wasNight = false,
}

-- Funções compartilhadas entre as seções
local Game = {}
local UI = {}

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

local function part(props)
	local className = props.ClassName or "Part"
	local base = {
		Anchored = true,
		CanCollide = true,
		CanTouch = false,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}
	for k, v in pairs(props) do
		if k ~= "ClassName" then
			base[k] = v
		end
	end
	return new(className, base)
end

local function smoothstep(a, b, x)
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function isDown(key)
	return UserInputService:IsKeyDown(key)
end

local function yawOf(v)
	return math.atan2(-v.X, -v.Z)
end

local AXIS_Y = CFrame.Angles(0, 0, math.rad(90)) -- cilindro em pé
local AXIS_Z = CFrame.Angles(0, math.rad(90), 0) -- cilindro deitado no sentido Z

---------------------------------------------------------------------------------------
-- PASTAS E LIMPEZA
---------------------------------------------------------------------------------------
for _, name in ipairs({ "Trilha_Mundo", "Trilha_Carro", "Trilha_Cargas", "Trilha_Efeitos" }) do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local F = {
	world = new("Folder", { Name = "Trilha_Mundo", Parent = workspace }),
	truck = new("Folder", { Name = "Trilha_Carro", Parent = workspace }),
	cargo = new("Folder", { Name = "Trilha_Cargas", Parent = workspace }),
	effects = new("Folder", { Name = "Trilha_Efeitos", Parent = workspace }),
}

-- Esconde a Baseplate e o SpawnLocation (só para este jogador)
for _, d in ipairs(workspace:GetChildren()) do
	if d:IsA("BasePart") and (d.Name == "Baseplate" or d:IsA("SpawnLocation")) then
		d.Transparency = 1
		d.CanCollide = false
		d.CanQuery = false
		for _, t in ipairs(d:GetChildren()) do
			if t:IsA("Texture") or t:IsA("Decal") then
				t.Transparency = 1
			end
		end
	end
end
terrain:Clear()
workspace.Gravity = CONFIG.GRAVITY
pcall(function()
	terrain.Decoration = true
	terrain.WaterColor = Color3.fromRGB(60, 90, 70)
	terrain.WaterTransparency = 0.6
	terrain.WaterWaveSize = 0.1
	terrain.WaterReflectance = 0.4
end)

---------------------------------------------------------------------------------------
-- ILUMINAÇÃO
---------------------------------------------------------------------------------------
Lighting.ClockTime = 15
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(125, 125, 135)
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.6
Lighting.GlobalShadows = true
if not Lighting:FindFirstChildOfClass("Atmosphere") then
	new("Atmosphere", {
		Density = 0.32,
		Offset = 0.15,
		Haze = 1.4,
		Glare = 0.3,
		Color = Color3.fromRGB(205, 210, 215),
		Decay = Color3.fromRGB(120, 125, 120),
		Parent = Lighting,
	})
end
if not Lighting:FindFirstChild("TrilhaBloom") then
	new("BloomEffect", { Name = "TrilhaBloom", Intensity = 0.5, Size = 24, Threshold = 1.7, Parent = Lighting })
	new("SunRaysEffect", { Name = "TrilhaSol", Intensity = 0.07, Spread = 0.7, Parent = Lighting })
	new("ColorCorrectionEffect", { Name = "TrilhaCor", Brightness = 0.02, Contrast = 0.1, Saturation = 0.1, TintColor = Color3.fromRGB(255, 250, 240), Parent = Lighting })
end
if not terrain:FindFirstChildOfClass("Clouds") then
	new("Clouds", { Cover = 0.6, Density = 0.65, Color = Color3.fromRGB(245, 245, 250), Parent = terrain })
end

---------------------------------------------------------------------------------------
-- MUNDO: trilha, relevo, desafios
-- A trilha segue sempre para -Z (frente). O relevo é gerado por ruído e "achatado"
-- perto da trilha. Cada trecho entre dois postos tem um desafio.
---------------------------------------------------------------------------------------
local World = {}
do
	local noise = math.noise
	local SEG = CONFIG.SEGMENT
	local W = CONFIG.TRAIL_HALF

	local CHALLENGES = {
		troncos = "TRONCOS NO CAMINHO",
		pedras = "CAMPO DE PEDRAS",
		lama = "LAMAÇAL",
		subida = "SUBIDA ÍNGREME",
		ponte = "PONTE ESTREITA",
		rio = "TRAVESSIA DE RIO",
		rampa = "RAMPA DE SALTO",
		gangorra = "GANGORRA",
		lateral = "ENCOSTA INCLINADA",
		toras = "TORAS SOLTAS",
	}
	local ORDER = { "troncos", "pedras", "lama", "subida", "ponte", "rio", "rampa", "gangorra", "lateral", "toras" }
	World.CHALLENGES = CHALLENGES

	-- A distância percorrida é "d" (positiva para frente). Mundo: z = -d.
	function World.pathX(d)
		local s = State.seed
		return noise(d / 700 + 0.37, s, 0.1) * 260 + noise(d / 180 + 0.11, s, 3.3) * 35
	end

	function World.trailBase(d)
		local s = State.seed
		return noise(d / 900 + 0.21, s, 5.7) * 60 + noise(d / 260 + 0.53, s, 9.1) * 14
	end

	local segCache = {}
	function World.resetCache()
		segCache = {}
	end

	-- Desafio do trecho k (entre o posto k-1 e o posto k)
	function World.segment(k)
		if k < 1 then
			return nil
		end
		local info = segCache[k]
		if info then
			return info
		end
		local rng = Random.new(math.floor(State.seed * 1000) + k * 7919)
		local kind
		if k == 1 then
			kind = "troncos"
		elseif k == 2 then
			kind = "lama"
		elseif k == 3 then
			kind = "subida"
		else
			kind = ORDER[rng:NextInteger(1, #ORDER)]
		end
		info = {
			k = k,
			kind = kind,
			name = CHALLENGES[kind],
			d0 = (k - 1) * SEG + 70,
			d1 = k * SEG - 70,
			diff = math.min(1, (k - 1) / 12),
			rng = rng:NextNumber(),
		}
		segCache[k] = info
		return info
	end

	function World.segmentAt(d)
		return World.segment(math.floor(d / SEG) + 1)
	end

	-- Posição 0..1 dentro do desafio (nil fora)
	local function challengeT(info, d)
		local t = (d - info.d0) / (info.d1 - info.d0)
		if t < 0 or t > 1 then
			return nil
		end
		return t
	end

	-- Nível da água (só no desafio do rio)
	function World.waterLevel(d)
		local info = World.segmentAt(d)
		if info and info.kind == "rio" then
			local t = challengeT(info, d)
			if t and t > 0.25 and t < 0.75 then
				return World.trailBase(info.d0 + (info.d1 - info.d0) * 0.5) - 1.5
			end
		end
		return nil
	end

	-- Modificação do relevo feita pelo desafio
	local function challengeMod(d, dx)
		local info = World.segmentAt(d)
		if not info then
			return 0
		end
		local t = challengeT(info, d)
		if not t then
			return 0
		end
		local diff = info.diff
		local adx = math.abs(dx)
		local kind = info.kind
		if kind == "subida" then
			return (32 + 28 * diff) * (1 - math.cos(t * math.pi * 2)) / 2 * (1 - smoothstep(60, 160, adx) * 0.5)
		elseif kind == "ponte" then
			local canyon = smoothstep(0.3, 0.36, t) * (1 - smoothstep(0.64, 0.7, t))
			return -(35 + 20 * diff) * canyon * (1 - smoothstep(350, 450, adx))
		elseif kind == "rio" then
			local river = smoothstep(0.28, 0.4, t) * (1 - smoothstep(0.6, 0.72, t))
			return -(7 + 3 * diff) * river * (1 - smoothstep(350, 450, adx))
		elseif kind == "lama" then
			return -2 * math.sin(t * math.pi) * (1 - smoothstep(W, W + 10, adx))
		elseif kind == "lateral" then
			local window = smoothstep(0.05, 0.2, t) * (1 - smoothstep(0.8, 0.95, t))
			return dx * (0.35 + 0.3 * diff) * window * (1 - smoothstep(W + 4, W + 20, adx))
		elseif kind == "rampa" then
			local ditch = smoothstep(0.5, 0.53, t) * (1 - smoothstep(0.6, 0.63, t))
			return -(6 + 4 * diff) * ditch * (1 - smoothstep(40, 60, adx))
		end
		return 0
	end

	-- Altura do terreno no ponto (x, z)
	function World.height(x, z)
		local s = State.seed
		local d = -z
		local dx = x - World.pathX(d)
		local adx = math.abs(dx)
		local th = World.trailBase(d)
		local amp = 8 + math.min(adx, 260) * 0.32
		local hills = noise(x / 220 + 0.1, z / 220 + 0.2, s) + noise(x / 80 + 0.3, z / 80 + 0.7, s + 1) * 0.35 + noise(x / 25 + 0.5, z / 25 + 0.9, s + 2) * 0.08
		local base = th + hills * amp
		local blend = 1 - smoothstep(W, W + 28, adx)
		local h = base + (th - base) * blend
		h += noise(x / 7 + 0.3, z / 7 + 0.1, s + 3) * 0.5 * blend -- sulcos da trilha
		h += challengeMod(d, dx)
		-- Postos: área plana
		local k = math.floor(d / SEG + 0.5)
		if k >= 0 then
			local od = k * SEG
			local ox = World.pathX(od)
			local dist = math.sqrt((x - ox) ^ 2 + (d - od) ^ 2)
			if dist < 50 then
				h = lerp(h, World.trailBase(od), 1 - smoothstep(30, 50, dist))
			end
		end
		return h
	end

	-- Material do terreno
	function World.material(x, z, h, slope)
		local d = -z
		local dx = x - World.pathX(d)
		local adx = math.abs(dx)
		local info = World.segmentAt(d)
		local kind = info and challengeT(info, d) and info.kind
		if adx < W + 1.5 then
			if kind == "lama" then
				return Enum.Material.Mud
			elseif kind == "rio" and World.waterLevel(d) then
				return Enum.Material.Sand
			end
			return Enum.Material.Ground
		end
		if kind == "lama" and adx < W + 12 then
			return Enum.Material.Mud
		end
		if slope > 1.1 then
			return Enum.Material.Rock
		elseif slope > 0.7 then
			return Enum.Material.Slate
		end
		local wl = World.waterLevel(d)
		if wl and h < wl + 1.5 then
			return Enum.Material.Sand
		end
		if h > World.trailBase(d) + 75 then
			return Enum.Material.Rock
		end
		local n = noise(x / 50 + 0.2, z / 50 + 0.4, State.seed + 4)
		if n > 0.25 then
			return Enum.Material.LeafyGrass
		elseif n < -0.3 then
			return Enum.Material.Ground
		end
		return Enum.Material.Grass
	end

	-- Ponto da trilha (centro) na distância d
	function World.trailPoint(d)
		local z = -d
		local x = World.pathX(d)
		return Vector3.new(x, World.height(x, z), z)
	end

	-- Direção da trilha (para frente)
	function World.trailDir(d)
		local a = World.trailPoint(d - 4)
		local b = World.trailPoint(d + 4)
		local v = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		return v.Magnitude > 0 and v.Unit or Vector3.new(0, 0, -1)
	end
end

---------------------------------------------------------------------------------------
-- CARGAS (objetos com física que vão na caçamba)
---------------------------------------------------------------------------------------
local Cargo = { list = {}, byPart = {} }
do
	local TYPES = {
		{ name = "CAIXA", size = Vector3.new(3, 3, 3), color = Color3.fromRGB(160, 115, 65), material = Enum.Material.WoodPlanks, density = 0.6, value = 100 },
		{ name = "BARRIL", size = Vector3.new(3.4, 2.4, 2.4), shape = Enum.PartType.Cylinder, rot = AXIS_Y, color = Color3.fromRGB(170, 40, 30), material = Enum.Material.Metal, density = 0.9, value = 150 },
		{ name = "PNEU", size = Vector3.new(1.3, 3.6, 3.6), shape = Enum.PartType.Cylinder, color = Color3.fromRGB(28, 28, 30), material = Enum.Material.SmoothPlastic, density = 0.5, value = 80 },
		{ name = "TORA", size = Vector3.new(8, 1.8, 1.8), shape = Enum.PartType.Cylinder, color = Color3.fromRGB(110, 75, 45), material = Enum.Material.Wood, density = 0.7, value = 200 },
		{ name = "GALÃO", size = Vector3.new(1.6, 2.2, 1.1), color = Color3.fromRGB(200, 30, 30), material = Enum.Material.SmoothPlastic, density = 0.6, value = 60, fuel = 25 },
		{ name = "CAIXA DE FERRAMENTAS", size = Vector3.new(3.4, 2, 2), color = Color3.fromRGB(40, 90, 170), material = Enum.Material.DiamondPlate, density = 2.2, value = 250 },
		{ name = "BOTIJÃO", size = Vector3.new(2.6, 1.8, 1.8), shape = Enum.PartType.Cylinder, rot = AXIS_Y, color = Color3.fromRGB(230, 200, 40), material = Enum.Material.Metal, density = 1.4, value = 180 },
	}
	Cargo.TYPES = TYPES

	function Cargo.spawn(position, origin, typeIndex)
		local t = TYPES[typeIndex or math.random(1, #TYPES)]
		local p = part({
			Name = "Carga",
			Size = t.size,
			Shape = t.shape or Enum.PartType.Block,
			CFrame = CFrame.new(position) * (t.rot or CFrame.identity) * CFrame.Angles(0, math.random() * 3, 0),
			Color = t.color,
			Material = t.material,
			Anchored = false,
			CustomPhysicalProperties = PhysicalProperties.new(t.density, 0.8, 0.1, 1, 1),
			Parent = F.cargo,
		})
		local item = { part = p, def = t, origin = origin, value = t.value }
		table.insert(Cargo.list, item)
		Cargo.byPart[p] = item
		return item
	end

	function Cargo.remove(item)
		local i = table.find(Cargo.list, item)
		if i then
			table.remove(Cargo.list, i)
		end
		Cargo.byPart[item.part] = nil
		item.part:Destroy()
	end

	function Cargo.nearest(position, maxDist)
		local best, bestDist = nil, maxDist
		for _, item in ipairs(Cargo.list) do
			local d = (item.part.Position - position).Magnitude
			if d < bestDist then
				best, bestDist = item, d
			end
		end
		return best
	end

	function Cargo.clear()
		for i = #Cargo.list, 1, -1 do
			Cargo.remove(Cargo.list[i])
		end
	end
end

---------------------------------------------------------------------------------------
-- TERRENO INFINITO EM BLOCOS
---------------------------------------------------------------------------------------
local Chunks = { loaded = {} }
do
	local CH, RES = CONFIG.CHUNK, CONFIG.VOXEL
	local COLS = CH // RES
	local W = CONFIG.TRAIL_HALF
	local SEG = CONFIG.SEGMENT
	local AIR, WATER, ROCK, GROUND = Enum.Material.Air, Enum.Material.Water, Enum.Material.Rock, Enum.Material.Ground

	local function key(cx, cz)
		return cx .. "," .. cz
	end

	local function nearOutpost(d, x)
		local k = math.floor(d / SEG + 0.5)
		if k < 0 then
			return false
		end
		local od = k * SEG
		return math.sqrt((x - World.pathX(od)) ^ 2 + (d - od) ^ 2) < 60
	end

	local function makeTree(folder, pos, rng)
		local pine = rng:NextNumber() < 0.55
		local h = pine and rng:NextNumber() * 6 + 11 or rng:NextNumber() * 4 + 7
		local bark = Color3.fromRGB(95, 65, 40)
		part({
			Name = "Tronco",
			Size = Vector3.new(h, 1.3, 1.3),
			Shape = Enum.PartType.Cylinder,
			CFrame = CFrame.new(pos + Vector3.new(0, h / 2 - 0.5, 0)) * AXIS_Y,
			Color = bark,
			Material = Enum.Material.Wood,
			Parent = folder,
		})
		if pine then
			local green = Color3.fromRGB(40, 85 + rng:NextInteger(0, 30), 45)
			for i = 0, 3 do
				local dia = 9 - i * 2
				part({
					Name = "Folhas",
					Size = Vector3.new(1.8, dia, dia),
					Shape = Enum.PartType.Cylinder,
					CFrame = CFrame.new(pos + Vector3.new(0, h * 0.4 + i * 2.4, 0)) * AXIS_Y,
					Color = green,
					Material = Enum.Material.Grass,
					CanCollide = false,
					CanQuery = false,
					CastShadow = true,
					Parent = folder,
				})
			end
		else
			for i = 1, 3 do
				local s = rng:NextNumber() * 3 + 5
				part({
					Name = "Folhas",
					Shape = Enum.PartType.Ball,
					Size = Vector3.one * s,
					CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber() * 3 - 1.5, h + i * 1.3 - 1, rng:NextNumber() * 3 - 1.5)),
					Color = Color3.fromRGB(70 + rng:NextInteger(0, 30), 130 + rng:NextInteger(0, 30), 50),
					Material = Enum.Material.LeafyGrass,
					CanCollide = false,
					CanQuery = false,
					Parent = folder,
				})
			end
		end
	end

	function Chunks.generate(cx, cz)
		local x0, z0 = cx * CH, cz * CH
		local hs = {}
		local minH, maxH = math.huge, -math.huge
		for ix = 0, COLS + 1 do
			local row = {}
			hs[ix] = row
			for iz = 0, COLS + 1 do
				local h = World.height(x0 + (ix - 0.5) * RES, z0 + (iz - 0.5) * RES)
				row[iz] = h
				if ix >= 1 and ix <= COLS and iz >= 1 and iz <= COLS then
					minH = math.min(minH, h)
					maxH = math.max(maxH, h)
				end
			end
		end
		local water = {}
		local maxWater = -math.huge
		for iz = 1, COLS do
			local wl = World.waterLevel(-(z0 + (iz - 0.5) * RES))
			water[iz] = wl
			if wl then
				maxWater = math.max(maxWater, wl)
			end
		end
		local y0 = math.floor((minH - 14) / RES) * RES
		local y1 = math.ceil((math.max(maxH, maxWater) + 4) / RES) * RES
		local ny = (y1 - y0) // RES

		local mats, occ = {}, {}
		for ix = 1, COLS do
			local mx, ox = {}, {}
			mats[ix], occ[ix] = mx, ox
			for iy = 1, ny do
				mx[iy], ox[iy] = {}, {}
			end
			for iz = 1, COLS do
				local h = hs[ix][iz]
				local slope = math.max(math.abs(hs[ix + 1][iz] - hs[ix - 1][iz]), math.abs(hs[ix][iz + 1] - hs[ix][iz - 1])) / (2 * RES)
				local surf = World.material(x0 + (ix - 0.5) * RES, z0 + (iz - 0.5) * RES, h, slope)
				local deep = (surf == Enum.Material.Mud or surf == Enum.Material.Sand) and surf or GROUND
				local wl = water[iz]
				for iy = 1, ny do
					local yc = y0 + (iy - 0.5) * RES
					local o = math.clamp((h - (yc - RES / 2)) / RES, 0, 1)
					if o > 0 then
						local depth = h - yc
						mx[iy][iz] = depth < 5 and surf or (depth < 14 and deep or ROCK)
						ox[iy][iz] = o
					elseif wl and yc < wl then
						mx[iy][iz] = WATER
						ox[iy][iz] = 1
					else
						mx[iy][iz] = AIR
						ox[iy][iz] = 0
					end
				end
			end
		end
		terrain:WriteVoxels(Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x0 + CH, y1, z0 + CH)), RES, mats, occ)

		-- Árvores, pedras e cargas espalhadas
		local folder = new("Folder", { Name = "Bloco " .. key(cx, cz), Parent = F.world })
		local rng = Random.new((math.floor(State.seed * 100) + cx * 92821 + cz * 68917) % 2147483647)
		for _ = 1, CONFIG.TREES_PER_CHUNK do
			local x = x0 + rng:NextNumber() * CH
			local z = z0 + rng:NextNumber() * CH
			local d = -z
			local adx = math.abs(x - World.pathX(d))
			if adx > W + 12 and not nearOutpost(d, x) then
				local h = World.height(x, z)
				local slope = math.abs(World.height(x + 3, z) - World.height(x - 3, z)) / 6
				local wl = World.waterLevel(d)
				if slope < 0.7 and not (wl and h < wl + 1) then
					makeTree(folder, Vector3.new(x, h, z), rng)
				end
			end
		end
		for _ = 1, 3 do
			local x = x0 + rng:NextNumber() * CH
			local z = z0 + rng:NextNumber() * CH
			if math.abs(x - World.pathX(-z)) > W + 10 then
				local r = rng:NextNumber() * 4 + 3
				terrain:FillBall(Vector3.new(x, World.height(x, z) + r * 0.2, z), r, ROCK)
			end
		end
		if rng:NextNumber() < 0.22 then
			local d = -(z0 + rng:NextNumber() * CH)
			local side = rng:NextNumber() < 0.5 and -1 or 1
			local x = World.pathX(d) + side * (W + 5)
			if x >= x0 and x < x0 + CH and not nearOutpost(d, x) then
				Cargo.spawn(Vector3.new(x, World.height(x, -d) + 3, -d), -1)
			end
		end

		Chunks.loaded[key(cx, cz)] = { cx = cx, cz = cz, y0 = y0 - 8, y1 = y1 + 16, folder = folder }
	end

	local function unload(k, rec)
		local x0, z0 = rec.cx * CH, rec.cz * CH
		terrain:FillBlock(CFrame.new(x0 + CH / 2, (rec.y0 + rec.y1) / 2, z0 + CH / 2), Vector3.new(CH, rec.y1 - rec.y0, CH), AIR)
		rec.folder:Destroy()
		Chunks.loaded[k] = nil
	end

	function Chunks.isLoaded(pos)
		return Chunks.loaded[key(math.floor(pos.X / CH), math.floor(pos.Z / CH))] ~= nil
	end

	-- Carrega os blocos mais perto primeiro; descarrega os distantes
	function Chunks.update(focus, budget)
		local fcx, fcz = math.floor(focus.X / CH), math.floor(focus.Z / CH)
		local R = CONFIG.LOAD_RADIUS
		for k, rec in pairs(Chunks.loaded) do
			if math.max(math.abs(rec.cx - fcx), math.abs(rec.cz - fcz)) > R + 1 then
				unload(k, rec)
			end
		end
		local missing = {}
		for dx = -R, R do
			for dz = -R, R do
				if not Chunks.loaded[key(fcx + dx, fcz + dz)] then
					table.insert(missing, { fcx + dx, fcz + dz, dx * dx + dz * dz })
				end
			end
		end
		table.sort(missing, function(a, b)
			return a[3] < b[3]
		end)
		for i = 1, math.min(budget, #missing) do
			Chunks.generate(missing[i][1], missing[i][2])
		end
		return #missing - math.min(budget, #missing)
	end

	function Chunks.clearAll()
		for k, rec in pairs(Chunks.loaded) do
			unload(k, rec)
		end
		terrain:Clear()
	end
end

---------------------------------------------------------------------------------------
-- TRECHOS: postos, obstáculos dos desafios e marcações da trilha
---------------------------------------------------------------------------------------
local Segments = { loaded = {}, outposts = {} }
do
	local SEG = CONFIG.SEGMENT
	local W = CONFIG.TRAIL_HALF
	local WOOD = Color3.fromRGB(120, 85, 50)

	local function frameAt(d, dx)
		local p = World.trailPoint(d)
		local dir = World.trailDir(d)
		local right = Vector3.new(-dir.Z, 0, dir.X)
		local pos = p + right * (dx or 0)
		pos = Vector3.new(pos.X, World.height(pos.X, pos.Z), pos.Z)
		return CFrame.lookAt(pos, pos + dir)
	end
	Segments.frameAt = frameAt

	local function sign(folder, cf, text, color)
		for _, x in ipairs({ -3.2, 3.2 }) do
			part({ Size = Vector3.new(0.5, 6, 0.5), CFrame = cf * CFrame.new(x, 3, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = folder })
		end
		local board = part({ Size = Vector3.new(8, 3.2, 0.3), CFrame = cf * CFrame.new(0, 5.4, 0), Color = Color3.fromRGB(35, 35, 38), Material = Enum.Material.WoodPlanks, Parent = folder })
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = new("SurfaceGui", { Face = face, LightInfluence = 0.3, PixelsPerStud = 40, Parent = board })
			new("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = text,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
				TextColor3 = color or Color3.fromRGB(255, 200, 40),
				Parent = gui,
			})
		end
	end

	local function buildOutpost(k, folder)
		local d = k * SEG
		local cf = frameAt(d, 0)
		local post = Color3.fromRGB(90, 60, 35)
		for _, x in ipairs({ -12, 12 }) do
			part({ Size = Vector3.new(1.2, 13, 1.2), CFrame = cf * CFrame.new(x, 6.5, 0), Color = post, Material = Enum.Material.Wood, Parent = folder })
		end
		local beam = part({ Size = Vector3.new(26, 2.4, 1.2), CFrame = cf * CFrame.new(0, 13, 0), Color = Color3.fromRGB(40, 40, 42), Material = Enum.Material.WoodPlanks, Parent = folder })
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = new("SurfaceGui", { Face = face, LightInfluence = 0.2, PixelsPerStud = 30, Parent = beam })
			new("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = k == 0 and "BASE — INÍCIO DA TRILHA" or ("POSTO " .. k),
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
				TextColor3 = Color3.fromRGB(255, 210, 60),
				Parent = gui,
			})
		end
		-- Área de entrega
		local pad = part({
			Size = Vector3.new(22, 0.3, 22),
			CFrame = cf * CFrame.new(0, 0.3, -18),
			Color = Color3.fromRGB(255, 200, 40),
			Material = Enum.Material.Neon,
			Transparency = 0.75,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
			Parent = folder,
		})
		local padGui = new("SurfaceGui", { Face = Enum.NormalId.Top, LightInfluence = 0, PixelsPerStud = 10, Parent = pad })
		new("TextLabel", {
			Size = UDim2.fromScale(1, 0.3),
			Position = UDim2.fromScale(0, 0.35),
			BackgroundTransparency = 1,
			Text = "ENTREGA",
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
			TextColor3 = Color3.new(1, 1, 1),
			Parent = padGui,
		})
		-- Bomba de combustível, cabana e bandeira
		part({ Size = Vector3.new(2.2, 5, 2.2), CFrame = cf * CFrame.new(16, 2.5, -16), Color = Color3.fromRGB(190, 30, 30), Material = Enum.Material.Metal, Parent = folder })
		local lamp = part({ Size = Vector3.new(2.3, 0.6, 2.3), CFrame = cf * CFrame.new(16, 4.4, -16), Color = Color3.fromRGB(255, 240, 200), Material = Enum.Material.Neon, Parent = folder })
		new("PointLight", { Range = 24, Brightness = 1.2, Color = Color3.fromRGB(255, 230, 180), Parent = lamp })
		part({ Size = Vector3.new(10, 7, 8), CFrame = cf * CFrame.new(-22, 3.5, -16), Color = Color3.fromRGB(140, 100, 65), Material = Enum.Material.WoodPlanks, Parent = folder })
		part({ Size = Vector3.new(11, 1, 9.5), CFrame = cf * CFrame.new(-22, 7.4, -16), Color = Color3.fromRGB(70, 45, 35), Material = Enum.Material.Slate, Parent = folder })
		part({ Size = Vector3.new(0.4, 16, 0.4), CFrame = cf * CFrame.new(13, 8, 4), Color = Color3.fromRGB(200, 200, 200), Material = Enum.Material.Metal, Parent = folder })
		part({ Size = Vector3.new(0.1, 2.6, 4.2), CFrame = cf * CFrame.new(13, 14.6, 6.2), Color = Color3.fromRGB(230, 120, 20), Material = Enum.Material.Fabric, CanCollide = false, Parent = folder })

		-- Cargas para o próximo trecho
		local count = k == 0 and 2 or 2 + math.min(4, math.floor(k / 3))
		for i = 1, count do
			local p = (cf * CFrame.new(-15 + (i % 3) * 4.5, 0, -28 - math.floor((i - 1) / 3) * 5)).Position
			Cargo.spawn(Vector3.new(p.X, World.height(p.X, p.Z) + 3, p.Z), k)
		end
		Segments.outposts[k] = { pos = cf.Position, pad = pad.Position, cf = cf }
	end

	local function buildChallenge(info, folder)
		local rng = Random.new(math.floor(info.rng * 1e6) + info.k)
		local diff = info.diff
		local d0, d1 = info.d0, info.d1
		local len = d1 - d0
		local kind = info.kind

		sign(folder, frameAt(d0 - 14, W + 5), ("DESAFIO %d\n%s"):format(info.k, info.name))

		if kind == "troncos" then
			local n = 3 + math.floor(4 * diff)
			for i = 1, n do
				local dia = 1.4 + 2.2 * diff + rng:NextNumber() * 0.6
				local cf = frameAt(d0 + len * i / (n + 1), 0)
				part({ Name = "Tronco", Size = Vector3.new(26, dia, dia), Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(0, dia / 2 - 0.4, 0) * CFrame.Angles(0, rng:NextNumber() * 0.4 - 0.2, 0), Color = Color3.fromRGB(105, 72, 45), Material = Enum.Material.Wood, Parent = folder })
			end
		elseif kind == "pedras" or kind == "rio" then
			local n = kind == "rio" and 8 or math.floor(14 + 24 * diff)
			for _ = 1, n do
				local r = 1.5 + rng:NextNumber() * (2 + 4 * diff)
				local t = kind == "rio" and 0.35 + rng:NextNumber() * 0.3 or rng:NextNumber()
				local cf = frameAt(d0 + len * t, (rng:NextNumber() * 2 - 1) * (W + 2))
				part({ Name = "Pedra", Shape = Enum.PartType.Ball, Size = Vector3.one * r * 2, CFrame = cf * CFrame.new(0, r * 0.35, 0), Color = Color3.fromRGB(120 + rng:NextInteger(-15, 15), 118, 112), Material = Enum.Material.Rock, Parent = folder })
			end
		elseif kind == "ponte" then
			local dA, dB = d0 + len * 0.27, d0 + len * 0.73
			local pA, pB = World.trailPoint(dA), World.trailPoint(dB)
			local dir = Vector3.new(pB.X - pA.X, 0, pB.Z - pA.Z).Unit
			local right = Vector3.new(-dir.Z, 0, dir.X)
			local width = math.max(2.6, 4 - 1.3 * diff)
			for _, off in ipairs({ -3.4, 3.4 }) do
				local a = pA + right * off + Vector3.new(0, 0.4, 0)
				local b = pB + right * off + Vector3.new(0, 0.4, 0)
				local length = (b - a).Magnitude
				part({ Name = "Ponte", Size = Vector3.new(width, 0.8, length), CFrame = CFrame.lookAt((a + b) / 2, b), Color = Color3.fromRGB(125, 90, 55), Material = Enum.Material.WoodPlanks, Parent = folder })
			end
			local steps = math.floor((pB - pA).Magnitude / 16)
			for i = 1, steps - 1 do
				local p = pA:Lerp(pB, i / steps)
				for _, off in ipairs({ -5.5, 5.5 }) do
					part({ Name = "Pilar", Size = Vector3.new(0.9, 60, 0.9), CFrame = CFrame.new(p + right * off - Vector3.new(0, 30, 0)), Color = Color3.fromRGB(90, 65, 40), Material = Enum.Material.Wood, Parent = folder })
				end
			end
		elseif kind == "rampa" then
			local h = 4 + 3 * diff
			local cf = frameAt(d0 + len * 0.515 - 8, 0)
			part({ ClassName = "WedgePart", Name = "Rampa", Size = Vector3.new(11, h, 16), CFrame = cf * CFrame.new(0, h / 2 - 0.3, 0) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(130, 95, 60), Material = Enum.Material.WoodPlanks, Parent = folder })
		elseif kind == "gangorra" then
			local cf = frameAt(d0 + len * 0.5, 0)
			local pivotH = 3
			local base = part({ Name = "Base", Size = Vector3.new(11, pivotH, 3), CFrame = cf * CFrame.new(0, pivotH / 2 - 0.2, 0), Color = Color3.fromRGB(80, 80, 85), Material = Enum.Material.Metal, Parent = folder })
			local angle = math.asin(math.clamp((pivotH - 0.2) / 18, -1, 1))
			local plank = part({
				Name = "Gangorra",
				Size = Vector3.new(11, 1, 38),
				CFrame = cf * CFrame.new(0, pivotH, 0) * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0.5, 0),
				Color = Color3.fromRGB(140, 100, 60),
				Material = Enum.Material.WoodPlanks,
				Anchored = false,
				CustomPhysicalProperties = PhysicalProperties.new(0.9, 0.9, 0.05, 1, 1),
				Parent = folder,
			})
			local a0 = new("Attachment", { Position = Vector3.new(0, pivotH / 2 + 0.2, 0), Parent = base })
			local a1 = new("Attachment", { Parent = plank })
			a1.WorldCFrame = a0.WorldCFrame
			new("HingeConstraint", { Attachment0 = a0, Attachment1 = a1, LimitsEnabled = true, LowerAngle = -18, UpperAngle = 18, Parent = plank })
		elseif kind == "toras" then
			local n = math.floor(8 + 6 * diff)
			for i = 1, n do
				local cf = frameAt(d0 + len * (0.2 + 0.6 * i / n), rng:NextNumber() * 6 - 3)
				part({
					Name = "ToraSolta",
					Size = Vector3.new(13, 1.6, 1.6),
					Shape = Enum.PartType.Cylinder,
					CFrame = cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, rng:NextNumber() * 0.6 - 0.3, 0),
					Color = Color3.fromRGB(110, 75, 45),
					Material = Enum.Material.Wood,
					Anchored = false,
					CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.7, 0.1, 1, 1),
					Parent = folder,
				})
			end
		end
	end

	-- Estacas de sinalização nas bordas da trilha
	local function buildMarkers(k, folder)
		local info = World.segment(k)
		for d = (k - 1) * SEG + 20, k * SEG - 20, 40 do
			local skip = false
			if info then
				local t = (d - info.d0) / (info.d1 - info.d0)
				if (info.kind == "ponte" or info.kind == "rio") and t > 0.2 and t < 0.8 then
					skip = true
				end
			end
			if not skip then
				for _, side in ipairs({ -1, 1 }) do
					local cf = frameAt(d, side * (W + 2.5))
					part({ Size = Vector3.new(0.4, 3.2, 0.4), CFrame = cf * CFrame.new(0, 1.4, 0), Color = Color3.fromRGB(235, 235, 235), Material = Enum.Material.SmoothPlastic, Parent = folder })
					part({ Size = Vector3.new(0.45, 0.6, 0.45), CFrame = cf * CFrame.new(0, 2.8, 0), Color = Color3.fromRGB(255, 120, 20), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
				end
			end
		end
	end

	function Segments.build(k)
		local folder = new("Folder", { Name = "Trecho " .. k, Parent = F.world })
		buildOutpost(k, folder)
		local info = World.segment(k)
		if info then
			buildChallenge(info, folder)
			buildMarkers(k, folder)
		end
		Segments.loaded[k] = folder
	end

	function Segments.update(d)
		local current = math.floor(d / SEG)
		for k, folder in pairs(Segments.loaded) do
			if k < current - 1 or k > current + 2 then
				folder:Destroy()
				Segments.loaded[k] = nil
				Segments.outposts[k] = nil
			end
		end
		for k = math.max(0, current - 1), current + 2 do
			if not Segments.loaded[k] then
				Segments.build(k)
				return -- um por quadro
			end
		end
	end

	function Segments.clearAll()
		for k, folder in pairs(Segments.loaded) do
			folder:Destroy()
			Segments.loaded[k] = nil
		end
		Segments.outposts = {}
	end
end

---------------------------------------------------------------------------------------
-- CAMINHONETE
-- Física de "raycast vehicle": o chassi é uma peça com física de verdade; cada roda
-- lança um raio para baixo e aplica força de mola + amortecedor (suspensão) e as
-- forças do pneu (aderência lateral, tração, freio) no ponto de contato.
---------------------------------------------------------------------------------------
local Truck = {}
do
	local R = CONFIG.WHEEL_RADIUS
	local REST = CONFIG.SUSPENSION_REST

	-- Aderência e resistência de cada material do chão
	local SURFACES = {
		[Enum.Material.Ground] = { grip = 1.0, roll = 1.0, dust = Color3.fromRGB(140, 110, 80) },
		[Enum.Material.Grass] = { grip = 0.85, roll = 1.2, dust = Color3.fromRGB(110, 120, 70) },
		[Enum.Material.LeafyGrass] = { grip = 0.85, roll = 1.2, dust = Color3.fromRGB(110, 120, 70) },
		[Enum.Material.Mud] = { grip = 0.55, roll = 4.5, dust = Color3.fromRGB(80, 60, 40) },
		[Enum.Material.Sand] = { grip = 0.7, roll = 3, dust = Color3.fromRGB(210, 190, 140) },
		[Enum.Material.Rock] = { grip = 1.05, roll = 0.8, dust = Color3.fromRGB(150, 150, 150) },
		[Enum.Material.Slate] = { grip = 0.95, roll = 0.8, dust = Color3.fromRGB(130, 130, 130) },
		[Enum.Material.Snow] = { grip = 0.5, roll = 2, dust = Color3.fromRGB(240, 240, 250) },
		[Enum.Material.Wood] = { grip = 0.95, roll = 0.8, dust = Color3.fromRGB(150, 120, 90) },
		[Enum.Material.WoodPlanks] = { grip = 0.95, roll = 0.8, dust = Color3.fromRGB(150, 120, 90) },
	}
	local DEFAULT_SURFACE = { grip = 1.0, roll = 1.0, dust = Color3.fromRGB(150, 140, 130) }

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	Truck.rayParams = rayParams

	function Truck.refreshFilter()
		local list = { F.truck, F.effects }
		if player.Character then
			table.insert(list, player.Character)
		end
		if State.carrying then
			table.insert(list, State.carrying.part)
		end
		rayParams.FilterDescendantsInstances = list
	end

	-------------------------------------------------------------------------------
	-- Construção
	-------------------------------------------------------------------------------
	function Truck.build(cf)
		if Truck.model then
			Truck.model:Destroy()
		end
		local model = new("Model", { Name = "Caminhonete", Parent = F.truck })
		Truck.model = model
		Truck.paintParts = {}
		local chassis = part({
			Name = "Chassi",
			Size = Vector3.new(6.2, 1.2, 17.4),
			CFrame = cf,
			Color = Color3.fromRGB(35, 35, 38),
			Material = Enum.Material.Metal,
			Anchored = false,
			CustomPhysicalProperties = PhysicalProperties.new(CONFIG.CHASSIS_DENSITY, 0.5, 0.1, 1, 1),
			Parent = model,
		})
		model.PrimaryPart = chassis
		Truck.chassis = chassis

		-- Peças da carroceria (sem massa, soldadas no chassi)
		local function body(name, size, localCF, color, material, extra)
			local p = part({
				Name = name,
				Size = size,
				CFrame = cf * localCF,
				Color = color,
				Material = material or Enum.Material.SmoothPlastic,
				Anchored = false,
				Massless = true,
				Parent = model,
			})
			if extra then
				for k, v in pairs(extra) do
					p[k] = v
				end
			end
			new("WeldConstraint", { Part0 = chassis, Part1 = p, Parent = p })
			return p
		end
		local function paint(name, size, localCF)
			local p = body(name, size, localCF, PAINTS[State.paint].color, Enum.Material.SmoothPlastic)
			table.insert(Truck.paintParts, p)
			return p
		end
		local dark = Color3.fromRGB(30, 30, 32)
		local glass = Color3.fromRGB(40, 55, 70)
		local metal = Color3.fromRGB(150, 150, 155)

		paint("Capo", Vector3.new(6.6, 2.2, 4.2), CFrame.new(0, 1.7, -6.7))
		body("Grade", Vector3.new(5, 1.4, 0.2), CFrame.new(0, 1.6, -8.85), dark, Enum.Material.DiamondPlate)
		paint("CabineBaixa", Vector3.new(6.6, 2.2, 5.2), CFrame.new(0, 1.7, -2))
		paint("CabineAlta", Vector3.new(6.2, 2.6, 4.2), CFrame.new(0, 4.1, -1.6))
		body("Parabrisa", Vector3.new(6, 2.4, 0.2), CFrame.new(0, 4.05, -3.72) * CFrame.Angles(0.3, 0, 0), glass, Enum.Material.Glass, { Transparency = 0.3 })
		body("JanelaL", Vector3.new(0.2, 1.8, 3.4), CFrame.new(-3.12, 4.2, -1.6), glass, Enum.Material.Glass, { Transparency = 0.3 })
		body("JanelaR", Vector3.new(0.2, 1.8, 3.4), CFrame.new(3.12, 4.2, -1.6), glass, Enum.Material.Glass, { Transparency = 0.3 })
		body("VidroTraseiro", Vector3.new(5.4, 1.6, 0.2), CFrame.new(0, 4.3, 0.52), glass, Enum.Material.Glass, { Transparency = 0.3 })

		-- Caçamba (paredes com colisão para segurar a carga)
		body("CacambaChao", Vector3.new(6.4, 0.4, 7.6), CFrame.new(0, 1.0, 4.5), Color3.fromRGB(60, 60, 62), Enum.Material.DiamondPlate)
		paint("CacambaL", Vector3.new(0.4, 2.2, 7.6), CFrame.new(-3.0, 2.3, 4.5))
		paint("CacambaR", Vector3.new(0.4, 2.2, 7.6), CFrame.new(3.0, 2.3, 4.5))
		paint("CacambaFrente", Vector3.new(6.4, 2.2, 0.4), CFrame.new(0, 2.3, 0.9))
		paint("Tampa", Vector3.new(6.4, 2.2, 0.4), CFrame.new(0, 2.3, 8.1))
		Truck.bed = { center = Vector3.new(0, 1.2, 4.5), half = Vector3.new(2.8, 4, 3.6) }

		-- Para-choques, quebra-mato, paralamas, estribos
		body("ParachoqueT", Vector3.new(6.8, 0.8, 0.6), CFrame.new(0, 0.6, 8.9), dark, Enum.Material.Metal)
		body("ParachoqueD", Vector3.new(7, 1, 0.8), CFrame.new(0, 0.9, -9.2), dark, Enum.Material.Metal)
		for _, x in ipairs({ -2.2, 2.2 }) do
			body("QuebraMato", Vector3.new(0.4, 2.4, 0.4), CFrame.new(x, 2.2, -9.5), dark, Enum.Material.Metal)
		end
		body("QuebraMatoTopo", Vector3.new(4.8, 0.4, 0.4), CFrame.new(0, 3.3, -9.5), dark, Enum.Material.Metal)
		for _, x in ipairs({ -3.55, 3.55 }) do
			for _, z in ipairs({ -5.8, 5.6 }) do
				paint("Paralama", Vector3.new(1.3, 0.5, 4.6), CFrame.new(x, 2.9, z))
			end
			body("Estribo", Vector3.new(0.7, 0.3, 4.6), CFrame.new(x, 0.3, -2), dark, Enum.Material.DiamondPlate)
			body("Retrovisor", Vector3.new(0.9, 0.6, 0.3), CFrame.new(x * 1.02, 4, -3.4), dark, Enum.Material.SmoothPlastic)
		end
		body("Snorkel", Vector3.new(0.5, 3.2, 0.5), CFrame.new(3.35, 4.2, -4.1), dark, Enum.Material.SmoothPlastic)

		-- Luzes
		Truck.headlights = {}
		for _, x in ipairs({ -2.4, 2.4 }) do
			local lamp = body("Farol", Vector3.new(1.2, 0.8, 0.2), CFrame.new(x, 2.1, -8.87), Color3.fromRGB(255, 250, 225), Enum.Material.Neon)
			table.insert(Truck.headlights, new("SpotLight", { Face = Enum.NormalId.Front, Range = 70, Angle = 55, Brightness = 5, Color = Color3.fromRGB(255, 245, 220), Enabled = false, Parent = lamp }))
		end
		local bar = body("BarraDeLuz", Vector3.new(4.4, 0.5, 0.6), CFrame.new(0, 5.65, -3.2), Color3.fromRGB(255, 250, 230), Enum.Material.Neon)
		table.insert(Truck.headlights, new("SpotLight", { Face = Enum.NormalId.Front, Range = 90, Angle = 70, Brightness = 4, Color = Color3.fromRGB(255, 250, 235), Enabled = false, Parent = bar }))
		Truck.brakeLights = {}
		for _, x in ipairs({ -2.9, 2.9 }) do
			table.insert(Truck.brakeLights, body("Lanterna", Vector3.new(0.8, 1, 0.2), CFrame.new(x, 2.3, 8.37), Color3.fromRGB(120, 10, 10), Enum.Material.Neon))
		end

		-- Rodas (só visuais; a física é feita pelos raios)
		Truck.wheels = {}
		local wheelModel = new("Model", { Name = "Rodas", Parent = F.truck })
		Truck.wheelModel = wheelModel
		for _, spec in ipairs({
			{ x = -3.4, z = -5.8, front = true },
			{ x = 3.4, z = -5.8, front = true },
			{ x = -3.4, z = 5.6, front = false },
			{ x = 3.4, z = 5.6, front = false },
		}) do
			local tire = part({ Name = "Pneu", Size = Vector3.new(1.5, R * 2, R * 2), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(25, 25, 27), Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, Parent = wheelModel })
			local rim = part({ Name = "Aro", Size = Vector3.new(1.55, R * 1.1, R * 1.1), Shape = Enum.PartType.Cylinder, Color = metal, Material = Enum.Material.Metal, CanCollide = false, CanQuery = false, Parent = wheelModel })
			local hub = part({ Name = "Cubo", Size = Vector3.new(1.6, 0.5, R * 1.2), Color = dark, Material = Enum.Material.Metal, CanCollide = false, CanQuery = false, Parent = wheelModel })
			local dustPart = part({ Name = "Poeira", Size = Vector3.one * 0.2, Transparency = 1, CanCollide = false, CanQuery = false, Parent = F.effects })
			local dust = new("ParticleEmitter", {
				Texture = "rbxasset://textures/particles/smoke_main.dds",
				Size = NumberSequence.new(1.2, 4.5),
				Transparency = NumberSequence.new(0.35, 1),
				Lifetime = NumberRange.new(0.8, 1.6),
				Speed = NumberRange.new(2, 6),
				SpreadAngle = Vector2.new(40, 40),
				Acceleration = Vector3.new(0, 3, 0),
				Rate = 0,
				Parent = dustPart,
			})
			table.insert(Truck.wheels, {
				mount = Vector3.new(spec.x, 0, spec.z),
				front = spec.front,
				left = spec.x < 0,
				compression = 0.3,
				lastCompression = 0.3,
				spin = 0,
				grounded = false,
				load = 0,
				slip = 0,
				tire = tire,
				rim = rim,
				hub = hub,
				dustPart = dustPart,
				dust = dust,
			})
		end

		Truck.steer = 0
		Truck.gear = 1
		Truck.rpm = 0
		Truck.throttle = 0
		Truck.brake = 0
		Truck.handbrake = false
		Truck.lastVelocity = Vector3.zero
		Truck.submerged = 0
		Truck.refreshFilter()
		Truck.updateVisuals(0)
		return model
	end

	function Truck.setPaint(index)
		State.paint = index
		for _, p in ipairs(Truck.paintParts or {}) do
			p.Color = PAINTS[index].color
		end
	end

	function Truck.setLights(on)
		State.lights = on
		for _, l in ipairs(Truck.headlights or {}) do
			l.Enabled = on
		end
	end

	-- Coloca a caminhonete em pé num ponto, parada
	function Truck.place(position, lookDir)
		local cf = CFrame.lookAt(position, position + lookDir)
		local chassis = Truck.chassis
		chassis.AssemblyLinearVelocity = Vector3.zero
		chassis.AssemblyAngularVelocity = Vector3.zero
		Truck.model:PivotTo(cf)
		for _, w in ipairs(Truck.wheels) do
			w.compression = 0.3
			w.lastCompression = 0.3
		end
	end

	-------------------------------------------------------------------------------
	-- Motor e câmbio
	-------------------------------------------------------------------------------
	local GEARS = CONFIG.GEAR_TOP_SPEEDS

	local function torqueCurve(x)
		-- x = rotação normalizada 0..1: pico no meio, cai perto do limite
		return 0.88 + 0.12 * math.sin(math.clamp(x, 0, 1) * math.pi * 0.9)
	end

	-- Força total do motor para a marcha atual
	local function engineForce(speed, mass, g)
		local top = Truck.gear == -1 and CONFIG.REVERSE_TOP_SPEED or GEARS[Truck.gear]
		local rpmNorm = math.clamp(speed / top, 0, 1.05)
		Truck.rpm = rpmNorm
		if rpmNorm >= 1 then
			return 0 -- limitador de giro
		end
		local gearFactor = (GEARS[1] / top) ^ 1.2
		return mass * g * CONFIG.ENGINE_FORCE * gearFactor * torqueCurve(rpmNorm)
	end

	local function autoShift(forwardSpeed)
		if Truck.gear == -1 then
			return
		end
		local top = GEARS[Truck.gear]
		local rpmNorm = forwardSpeed / top
		if rpmNorm > 0.93 and Truck.gear < #GEARS and Truck.throttle > 0.1 then
			Truck.gear += 1
			Truck.shiftTimer = 0.25
		elseif Truck.gear > 1 and forwardSpeed < GEARS[Truck.gear - 1] * 0.55 then
			Truck.gear -= 1
			Truck.shiftTimer = 0.15
		end
	end

	-------------------------------------------------------------------------------
	-- Física (roda antes de cada passo da simulação)
	-------------------------------------------------------------------------------
	function Truck.physicsStep(dt, input)
		local chassis = Truck.chassis
		if not chassis or not chassis.Parent or chassis.Anchored then
			return
		end
		dt = math.min(dt, 1 / 30)
		local cf = chassis.CFrame
		local up = cf.UpVector
		local mass = chassis.AssemblyMass
		local g = workspace.Gravity
		local massPerWheel = mass / 4
		local velocity = chassis.AssemblyLinearVelocity
		local forward = cf.LookVector
		local forwardSpeed = velocity:Dot(forward)
		local speed = velocity.Magnitude

		-- Suspensão: rigidez calculada para afundar SUSPENSION_SAG parado
		local k = (mass * g / 4) / (REST * CONFIG.SUSPENSION_SAG)
		local critical = 2 * math.sqrt(k * massPerWheel)

		-- Entrada: marcha à ré automática
		local throttle, brake = 0, 0
		local wantForward, wantBack = input.throttle, input.brake
		if Truck.gear == -1 then
			if wantForward > 0 and forwardSpeed > -2 then
				Truck.gear = 1
			elseif wantBack > 0 then
				throttle = wantBack
			end
			if wantForward > 0 then
				brake = wantForward
			end
		else
			if wantBack > 0 and forwardSpeed < 2 then
				Truck.gear = -1
				throttle = wantBack
			else
				throttle = wantForward
				brake = wantBack
			end
		end
		if CONFIG.FUEL_ENABLED and State.fuel <= 0 then
			throttle = 0
		end
		Truck.throttle = throttle
		Truck.brake = brake
		Truck.handbrake = input.handbrake
		Truck.shiftTimer = math.max(0, (Truck.shiftTimer or 0) - dt)
		autoShift(math.abs(forwardSpeed))
		local driveTotal = engineForce(math.abs(forwardSpeed), mass, g) * throttle * (Truck.shiftTimer > 0 and 0.3 or 1)
		local driveDir = Truck.gear == -1 and -1 or 1
		local drivenCount = State.fourWD and 4 or 2

		-- Direção sensível à velocidade
		local maxSteer = lerp(CONFIG.STEER_MAX, CONFIG.STEER_MIN, math.clamp(math.abs(forwardSpeed) / 70, 0, 1))
		local targetSteer = input.steer * maxSteer
		local rate = (math.abs(targetSteer) < math.abs(Truck.steer) or math.sign(targetSteer) ~= math.sign(Truck.steer)) and CONFIG.STEER_RETURN or CONFIG.STEER_SPEED
		Truck.steer += math.clamp(targetSteer - Truck.steer, -rate * dt, rate * dt)

		local grounded = 0
		for _, w in ipairs(Truck.wheels) do
			local mountWorld = cf * w.mount
			local result = workspace:Raycast(mountWorld, -up * (REST + R), rayParams)
			w.grounded = result ~= nil
			if result then
				grounded += 1
				local dist = (result.Position - mountWorld).Magnitude
				local compression = math.clamp(REST + R - dist, 0, REST)
				w.lastCompression = w.compression
				w.compression = compression
				w.contact = result.Position
				w.normal = result.Normal
				w.surface = SURFACES[result.Material] or DEFAULT_SURFACE
				w.hitPart = result.Instance
			else
				w.lastCompression = w.compression
				w.compression = math.max(0, w.compression - dt * 4)
				w.load = 0
			end
		end

		-- Barra estabilizadora: transfere carga entre os lados de cada eixo
		local antiRoll = {}
		for axle = 0, 1 do
			local a, b = Truck.wheels[axle * 2 + 1], Truck.wheels[axle * 2 + 2]
			local diff = (a.compression - b.compression) * k * CONFIG.ANTI_ROLL
			antiRoll[axle * 2 + 1] = a.grounded and diff or 0
			antiRoll[axle * 2 + 2] = b.grounded and -diff or 0
		end

		Truck.submerged = 0
		local wl = World.waterLevel(-cf.Position.Z)
		if wl and cf.Position.Y < wl + 1 then
			Truck.submerged = math.clamp((wl + 1 - cf.Position.Y) / 4, 0, 1)
		end

		for i, w in ipairs(Truck.wheels) do
			if w.grounded then
				local mountWorld = cf * w.mount
				-- Mola + amortecedor (mais amortecido na volta)
				local compVel = (w.compression - w.lastCompression) / dt
				local zeta = compVel > 0 and CONFIG.DAMPING_BUMP or CONFIG.DAMPING_REBOUND
				local springForce = k * w.compression + critical * zeta * compVel + antiRoll[i]
				-- Batente: fim de curso
				if w.compression > REST * 0.92 then
					springForce += k * 6 * (w.compression - REST * 0.92)
				end
				springForce = math.max(0, springForce)
				w.load = springForce
				local suspensionImpulse = up * springForce * dt
				chassis:ApplyImpulseAtPosition(suspensionImpulse, mountWorld)

				-- Pneu: eixos da roda no plano do chão
				local contact = w.contact
				local normal = w.normal
				local wheelForward = forward
				if w.front then
					wheelForward = CFrame.fromAxisAngle(up, Truck.steer):VectorToWorldSpace(forward)
				end
				wheelForward = (wheelForward - normal * wheelForward:Dot(normal))
				if wheelForward.Magnitude < 1e-3 then
					continue
				end
				wheelForward = wheelForward.Unit
				local wheelRight = wheelForward:Cross(normal).Unit

				local pointVel = chassis:GetVelocityAtPosition(contact)
				if w.hitPart and not w.hitPart.Anchored then
					pointVel -= w.hitPart:GetVelocityAtPosition(contact)
				end
				local vLong = pointVel:Dot(wheelForward)
				local vLat = pointVel:Dot(wheelRight)

				local surface = w.surface
				local mu = CONFIG.TIRE_GRIP * surface.grip
				local maxFriction = mu * springForce

				-- Lateral: curva de escorregamento suave, sem passar do necessário
				local lateralGrip = 1
				if not w.front and Truck.handbrake then
					lateralGrip = CONFIG.HANDBRAKE_GRIP
				end
				local latForce = -math.clamp(vLat / CONFIG.SLIP_SATURATION, -1, 1) * maxFriction * lateralGrip
				local latCap = math.abs(vLat) * massPerWheel / dt * 0.9
				latForce = math.clamp(latForce, -latCap, latCap)

				-- Longitudinal: tração, freio, resistência ao rolamento
				local longForce = 0
				local driven = State.fourWD or not w.front
				if driven then
					longForce += driveTotal / drivenCount * driveDir
				end
				local brakeForce = brake * CONFIG.BRAKE_FORCE * massPerWheel * g
				if Truck.handbrake and not w.front then
					brakeForce += CONFIG.BRAKE_FORCE * massPerWheel * g * 1.5
				end
				if throttle == 0 and brake == 0 and not Truck.handbrake and (not State.driving or math.abs(forwardSpeed) < 1.5) then
					brakeForce += CONFIG.BRAKE_FORCE * massPerWheel * g -- segura-rampa / freio de estacionamento
				end
				local rolling = CONFIG.ROLLING_RESISTANCE * surface.roll * springForce
				local resist = brakeForce + rolling
				local stopCap = math.abs(vLong) * massPerWheel / dt
				longForce -= math.sign(vLong) * math.min(resist, stopCap)

				-- Círculo de atrito: se passar do limite, o pneu escorrega
				local total = math.sqrt(longForce * longForce + latForce * latForce)
				w.slip = 0
				if total > maxFriction and total > 0 then
					local scale = maxFriction / total
					w.slip = 1 - scale
					longForce *= scale
					latForce *= scale * 0.92 -- atrito dinâmico um pouco menor
				end
				if driven and throttle > 0.5 and driveTotal / drivenCount > maxFriction * 0.95 then
					w.slip = math.max(w.slip, 0.6) -- patinando
				end

				local tireImpulse = (wheelForward * longForce + wheelRight * latForce) * dt
				chassis:ApplyImpulseAtPosition(tireImpulse, contact:Lerp(mountWorld, CONFIG.FORCE_HEIGHT))

				-- Ação e reação em objetos soltos (gangorra, toras, cargas)
				if w.hitPart and not w.hitPart.Anchored then
					w.hitPart:ApplyImpulseAtPosition(-(suspensionImpulse + tireImpulse) * 0.5, contact)
				end

				-- Rotação visual da roda
				local spinSpeed = vLong / R
				if w.slip > 0.5 and driven and throttle > 0 then
					spinSpeed = (Truck.gear == -1 and -1 or 1) * 25
				elseif Truck.handbrake and not w.front then
					spinSpeed = 0
				end
				w.spin += spinSpeed * dt
			else
				w.spin += (w.front and 0 or throttle * 20) * dt
			end
		end

		-- Arrasto do ar e da água
		local drag = -velocity * speed * CONFIG.DRAG * mass / 243
		if Truck.submerged > 0 then
			drag += -velocity * Truck.submerged * mass * 0.8
			chassis:ApplyImpulse(Vector3.new(0, mass * g * 0.35 * Truck.submerged, 0) * dt)
		end
		chassis:ApplyImpulse(drag * dt)

		-- Controle no ar (inclinar e girar) e amortecimento de giro
		Truck.airborne = grounded == 0
		if Truck.airborne then
			local inertia = mass * 25
			local pitch = (input.throttle - input.brake)
			local torque = cf.RightVector * -pitch * CONFIG.AIR_CONTROL + up * input.steer * CONFIG.AIR_CONTROL * 0.8
			chassis:ApplyAngularImpulse(torque * inertia * dt)
			chassis:ApplyAngularImpulse(-chassis.AssemblyAngularVelocity * inertia * 0.3 * dt)
		end

		-- Combustível
		if CONFIG.FUEL_ENABLED and State.driving then
			State.fuel = math.max(0, State.fuel - (0.02 + throttle * CONFIG.FUEL_USE) * dt)
		end
		Truck.grounded = grounded
	end

	-------------------------------------------------------------------------------
	-- Visual: rodas, luzes de freio, poeira
	-------------------------------------------------------------------------------
	function Truck.updateVisuals(_dt)
		local chassis = Truck.chassis
		if not chassis then
			return
		end
		local cf = chassis.CFrame
		local speed = chassis.AssemblyLinearVelocity.Magnitude
		local parts, cfs = {}, {}
		for _, w in ipairs(Truck.wheels) do
			local suspensionLength = REST - w.compression
			local center = cf * (w.mount - Vector3.new(0, suspensionLength, 0))
			local steer = w.front and Truck.steer or 0
			local wheelCF = CFrame.new(center) * cf.Rotation * CFrame.Angles(0, steer, 0) * CFrame.Angles(-w.spin, 0, 0)
			local outward = w.left and -1 or 1
			table.insert(parts, w.tire)
			table.insert(cfs, wheelCF)
			table.insert(parts, w.rim)
			table.insert(cfs, wheelCF * CFrame.new(outward * 0.05, 0, 0))
			table.insert(parts, w.hub)
			table.insert(cfs, wheelCF * CFrame.new(outward * 0.08, 0, 0))

			-- Poeira / lama
			if w.grounded and w.contact then
				w.dustPart.Position = w.contact + Vector3.new(0, 0.5, 0)
				w.dust.Color = ColorSequence.new(w.surface.dust)
				w.dust.Rate = math.clamp(speed * 0.35 + w.slip * 60, 0, 70) * (speed > 3 and 1 or w.slip)
			else
				w.dust.Rate = 0
			end
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)

		local braking = Truck.brake > 0 or Truck.handbrake
		local reversing = Truck.gear == -1 and Truck.throttle > 0
		for _, l in ipairs(Truck.brakeLights) do
			l.Color = reversing and Color3.fromRGB(240, 240, 240) or (braking and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(120, 10, 10))
		end
	end

	-- Cargas que estão dentro da caçamba
	function Truck.cargoInBed()
		local list = {}
		local chassis = Truck.chassis
		if not chassis then
			return list
		end
		local bed = Truck.bed
		for _, item in ipairs(Cargo.list) do
			if item ~= State.carrying then
				local p = chassis.CFrame:PointToObjectSpace(item.part.Position) - bed.center
				if math.abs(p.X) < bed.half.X + 0.6 and p.Y > -1 and p.Y < bed.half.Y + 2 and math.abs(p.Z) < bed.half.Z + 0.6 then
					table.insert(list, item)
				end
			end
		end
		return list
	end

	function Truck.isUpsideDown()
		return Truck.chassis and Truck.chassis.CFrame.UpVector.Y < 0.3
	end

	-- Desvira / volta para a trilha
	function Truck.reset()
		local pos = Truck.chassis.Position
		local d = -pos.Z
		local onTrail = math.abs(pos.X - World.pathX(d)) < CONFIG.TRAIL_HALF + 20
		local target
		if onTrail and not Truck.isUpsideDown() then
			target = pos
		end
		local p = World.trailPoint(d)
		if not onTrail then
			target = p
		end
		target = target or pos
		local groundY = World.height(target.X, target.Z)
		local wl = World.waterLevel(-target.Z)
		local y = math.max(groundY, wl or -math.huge) + 6
		local look = World.trailDir(d)
		Truck.place(Vector3.new(target.X, y, target.Z), look)
	end
end

---------------------------------------------------------------------------------------
-- INTERFACE
---------------------------------------------------------------------------------------
do
	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("TrilhaHUD")
	if old then
		old:Destroy()
	end
	local ACCENT = Color3.fromRGB(255, 170, 40)
	UI.ACCENT = ACCENT

	local function corner(r)
		return new("UICorner", { CornerRadius = UDim.new(0, r or 8) })
	end
	local function stroke()
		return new("UIStroke", { Color = ACCENT, Thickness = 2, Transparency = 0.2 })
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
	local function button(parent, text, position, callback)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(300, 50),
			Position = position,
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(22, 22, 26),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 19,
			Font = Enum.Font.GothamBlack,
			Parent = parent,
		}, { corner(10), stroke() })
		b.MouseButton1Click:Connect(callback)
		return b
	end
	local function panel(props)
		local base = { BackgroundColor3 = Color3.fromRGB(12, 12, 15), BackgroundTransparency = 0.25 }
		for k, v in pairs(props) do
			base[k] = v
		end
		return new("Frame", base, { corner(12), stroke() })
	end
	UI.label = label

	local gui = new("ScreenGui", { Name = "TrilhaHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
	UI.hud = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })

	-- Velocímetro
	local speedo = panel({ Size = UDim2.fromOffset(280, 170), Position = UDim2.new(1, -20, 1, -20), AnchorPoint = Vector2.new(1, 1), Parent = UI.hud })
	UI.speedo = speedo
	UI.speed = label({ Size = UDim2.fromOffset(170, 70), Position = UDim2.fromOffset(16, 8), Text = "0", TextSize = 64, Font = Enum.Font.GothamBlack, Parent = speedo })
	label({ Size = UDim2.fromOffset(80, 20), Position = UDim2.fromOffset(18, 72), Text = "KM/H", TextSize = 14, TextColor3 = Color3.fromRGB(180, 180, 190), Parent = speedo })
	UI.gear = label({ Size = UDim2.fromOffset(80, 70), Position = UDim2.new(1, -16, 0, 8), AnchorPoint = Vector2.new(1, 0), Text = "1", TextSize = 56, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = ACCENT, Parent = speedo })
	UI.drive = label({ Size = UDim2.fromOffset(80, 20), Position = UDim2.new(1, -16, 0, 74), AnchorPoint = Vector2.new(1, 0), Text = "4x4", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, Parent = speedo })
	local function bar(y, title)
		label({ Size = UDim2.fromOffset(120, 16), Position = UDim2.fromOffset(16, y), Text = title, TextSize = 12, TextColor3 = Color3.fromRGB(180, 180, 190), Parent = speedo })
		local bg = new("Frame", { Size = UDim2.new(1, -32, 0, 10), Position = UDim2.fromOffset(16, y + 18), BackgroundColor3 = Color3.fromRGB(40, 40, 45), Parent = speedo }, { corner(5) })
		return new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ACCENT, Parent = bg }, { corner(5) })
	end
	UI.rpm = bar(98, "ROTAÇÃO")
	UI.fuel = bar(132, "COMBUSTÍVEL")

	-- Painel de informações
	local info = panel({ Size = UDim2.fromOffset(270, 150), Position = UDim2.fromOffset(16, 56), Parent = UI.hud })
	UI.infoLines = {}
	for i = 1, 6 do
		UI.infoLines[i] = label({ Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 8 + (i - 1) * 22), TextSize = i == 1 and 18 or 14, Font = i == 1 and Enum.Font.GothamBlack or Enum.Font.GothamMedium, TextColor3 = i == 1 and ACCENT or Color3.new(1, 1, 1), Parent = info })
	end

	-- Topo: desafio atual e bússola para o próximo posto
	UI.banner = label({ Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 12), Text = "", TextSize = 24, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, TextColor3 = ACCENT, Parent = UI.hud })
	UI.arrow = label({ Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, 0, 0, 46), AnchorPoint = Vector2.new(0.5, 0), Text = "▲", TextSize = 34, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = UI.hud })
	UI.target = label({ Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 86), Text = "", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, Parent = UI.hud })

	UI.prompt = label({ Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, -70), Text = "", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3, Parent = UI.hud })
	UI.notify = label({ Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0.3, 0), Text = "", TextSize = 30, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 5, Parent = gui })

	-- Ajuda
	UI.help = panel({ Size = UDim2.fromOffset(460, 440), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0.05, Visible = false, ZIndex = 30, Parent = gui })
	label({
		Size = UDim2.new(1, -40, 1, -30),
		Position = UDim2.fromOffset(20, 16),
		RichText = true,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 15,
		Font = Enum.Font.Gotham,
		ZIndex = 30,
		Text = table.concat({
			"<b><font size=\"20\">CONTROLES</font></b>",
			"",
			"<b>NA CAMINHONETE</b>",
			"W / S  acelerar / frear e ré      A / D  virar",
			"Espaço  freio de mão      F  descer",
			"R  desvirar / voltar à trilha      T  4x4 / 4x2",
			"H  faróis      C  câmera      V  cor",
			"Botão direito + mouse  olhar em volta",
			"No ar: W/S inclina, A/D gira",
			"",
			"<b>A PÉ</b>",
			"E  pegar / soltar carga      Clique  arremessar",
			"F  entrar na caminhonete",
			"",
			"<b>OBJETIVO</b>",
			"Pegue as cargas nos postos, coloque na caçamba e leve",
			"até o próximo posto. Pare na área amarela de ENTREGA.",
			"",
			"P  pausar      H (no menu)  esta ajuda",
		}, "\n"),
		Parent = UI.help,
	})

	-- Carregando
	UI.loading = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 10, 12), ZIndex = 40, Parent = gui })
	label({ Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0.5, -80), Text = "TRILHA INFINITA 4x4", TextSize = 48, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = ACCENT, ZIndex = 41, Parent = UI.loading })
	UI.loadingText = label({ Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0.5, 0), Text = "GERANDO O MUNDO...", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(180, 180, 190), ZIndex = 41, Parent = UI.loading })

	-- Menu
	UI.menu = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 15, Parent = gui })
	local left = new("Frame", { Size = UDim2.new(0, 470, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = UI.menu }, {
		new("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
	})
	label({ Size = UDim2.new(1, -60, 0, 60), Position = UDim2.new(0, 40, 0.5, -250), Text = "TRILHA", TextSize = 64, Font = Enum.Font.GothamBlack, TextColor3 = ACCENT, TextStrokeTransparency = 0.5, Parent = left })
	label({ Size = UDim2.new(1, -60, 0, 50), Position = UDim2.new(0, 40, 0.5, -190), Text = "INFINITA 4x4", TextSize = 44, Font = Enum.Font.GothamBlack, TextStrokeTransparency = 0.5, Parent = left })
	button(left, "▶  JOGAR", UDim2.new(0, 190, 0.5, -110), function()
		Game.play()
	end)
	UI.paintButton = button(left, "COR: " .. PAINTS[State.paint].name, UDim2.new(0, 190, 0.5, -50), function()
		Truck.setPaint(State.paint % #PAINTS + 1)
		UI.paintButton.Text = "COR: " .. PAINTS[State.paint].name
	end)
	button(left, "🗺  NOVO MAPA", UDim2.new(0, 190, 0.5, 10), function()
		task.spawn(Game.newMap)
	end)
	button(left, "?  CONTROLES", UDim2.new(0, 190, 0.5, 70), function()
		State.showHelp = not State.showHelp
	end)
	UI.menuStats = label({ Size = UDim2.new(1, -60, 0, 60), Position = UDim2.new(0, 44, 0.5, 136), Text = "", TextSize = 15, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(210, 210, 220), TextYAlignment = Enum.TextYAlignment.Top, Parent = left })

	-- Pausa
	UI.pause = panel({ Size = UDim2.fromOffset(360, 300), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0.1, Visible = false, ZIndex = 15, Parent = gui })
	label({ Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 14), Text = "PAUSADO", TextSize = 32, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, Parent = UI.pause })
	button(UI.pause, "CONTINUAR", UDim2.new(0.5, 0, 0, 80), function()
		Game.resume()
	end)
	button(UI.pause, "CONTROLES", UDim2.new(0.5, 0, 0, 144), function()
		State.showHelp = not State.showHelp
	end)
	button(UI.pause, "MENU PRINCIPAL", UDim2.new(0, 180, 0, 208), function()
		Game.toMenu()
	end)
end

local notifyToken = 0
function Game.notify(text, color)
	notifyToken += 1
	local token = notifyToken
	UI.notify.Text = text
	UI.notify.TextColor3 = color or UI.ACCENT
	UI.notify.TextTransparency = 0
	UI.notify.TextStrokeTransparency = 0.3
	task.delay(2.5, function()
		if token == notifyToken then
			TweenService:Create(UI.notify, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function playSound(id, volume, pitch, parent)
	if not id or id == "" then
		return
	end
	local s = new("Sound", { SoundId = id, Volume = volume or 0.6, PlaybackSpeed = pitch or 1, Parent = parent or workspace })
	pcall(function()
		s:Play()
	end)
	Debris:AddItem(s, 5)
end

---------------------------------------------------------------------------------------
-- MOTORISTA E PERSONAGEM A PÉ
---------------------------------------------------------------------------------------
local Driver = {}
do
	local controls
	task.spawn(function()
		pcall(function()
			local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: any)
			controls = module:GetControls()
			if not (State.gameState == "playing" and not State.driving) then
				controls:Disable()
			end
		end)
	end)

	function Driver.setControls(enabled)
		if controls then
			if enabled then
				controls:Enable()
			else
				controls:Disable()
			end
		end
	end

	function Driver.parts(): (BasePart?, Humanoid?)
		local char = player.Character
		if not char then
			return nil, nil
		end
		return char:FindFirstChild("HumanoidRootPart") :: BasePart?, char:FindFirstChildOfClass("Humanoid")
	end

	function Driver.setHidden(hidden)
		local char = player.Character
		if char then
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("Decal") then
					d.LocalTransparencyModifier = hidden and 1 or 0
				end
			end
		end
	end

	function Driver.enter()
		local hrp = Driver.parts()
		if not hrp then
			return
		end
		if State.carrying then
			Driver.drop(false)
		end
		State.driving = true
		hrp.Anchored = true
		Driver.setControls(false)
		camera.CameraType = Enum.CameraType.Scriptable
		Game.resetCamera()
	end

	function Driver.exit()
		local hrp, humanoid = Driver.parts()
		State.driving = false
		if not hrp then
			return
		end
		local cf = Truck.chassis.CFrame
		local side = (cf * CFrame.new(-6, 0, -2)).Position
		local hit = workspace:Raycast(side + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), Truck.rayParams)
		local y = hit and hit.Position.Y + 3 or side.Y + 3
		hrp.Anchored = false
		hrp.CFrame = CFrame.lookAt(Vector3.new(side.X, y, side.Z), Vector3.new(side.X, y, side.Z) + Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z))
		hrp.AssemblyLinearVelocity = Vector3.zero
		Driver.setHidden(false)
		Driver.setControls(State.gameState == "playing")
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then
			camera.CameraSubject = humanoid
		end
		camera.FieldOfView = 70
	end

	-- Pegar / soltar / arremessar cargas
	function Driver.pickUp(item)
		local p = item.part
		local att = new("Attachment", { Name = "Pega", Parent = p })
		item.attachment = att
		item.align = new("AlignPosition", {
			Mode = Enum.PositionAlignmentMode.OneAttachment,
			Attachment0 = att,
			MaxForce = p.AssemblyMass * workspace.Gravity * 8 + 5000,
			Responsiveness = 30,
			MaxVelocity = 60,
			Parent = p,
		})
		item.orient = new("AlignOrientation", {
			Mode = Enum.OrientationAlignmentMode.OneAttachment,
			Attachment0 = att,
			MaxTorque = 1e7,
			Responsiveness = 20,
			Parent = p,
		})
		p.CanCollide = false
		State.carrying = item
		Truck.refreshFilter()
		local _, humanoid = Driver.parts()
		if humanoid then
			humanoid.WalkSpeed = math.max(8, 16 - p.AssemblyMass / 8)
		end
		playSound(CONFIG.SOUNDS.pickup, 0.5, 1.2)
	end

	function Driver.drop(throw)
		local item = State.carrying
		if not item then
			return
		end
		State.carrying = nil
		for _, key in ipairs({ "align", "orient", "attachment" }) do
			if item[key] then
				item[key]:Destroy()
				item[key] = nil
			end
		end
		local p = item.part
		p.CanCollide = true
		local hrp, humanoid = Driver.parts()
		if humanoid then
			humanoid.WalkSpeed = 16
		end
		if throw and hrp then
			local m = p.AssemblyMass
			p:ApplyImpulse((hrp.CFrame.LookVector * 55 + Vector3.new(0, 30, 0)) * m)
		end
		Truck.refreshFilter()
	end

	function Driver.updateCarry()
		local item = State.carrying
		if not item then
			return
		end
		local hrp = Driver.parts()
		if not hrp or not item.part.Parent then
			Driver.drop(false)
			return
		end
		local size = item.part.Size
		local hold = hrp.CFrame * CFrame.new(0, 4.5 + size.Y / 2, -(2.5 + math.max(size.X, size.Z) / 2))
		item.align.Position = hold.Position
		item.orient.CFrame = hrp.CFrame.Rotation * (item.def.rot or CFrame.identity)
		if (item.part.Position - hold.Position).Magnitude > 25 then
			Driver.drop(false) -- ficou preso em algum lugar
		end
	end

	local function hookCharacter(char)
		Truck.refreshFilter()
		local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.UseJumpPower = false
			humanoid.JumpHeight = 7.2
		end
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if State.gameState ~= "loading" and Truck.chassis and hrp and hrp:IsA("BasePart") then
			-- Renasceu: volta para perto da caminhonete
			task.wait()
			if State.driving then
				hrp.Anchored = true
			else
				local pos = (Truck.chassis.CFrame * CFrame.new(-6, 4, 0)).Position
				hrp.CFrame = CFrame.new(pos)
			end
		end
		if State.gameState ~= "playing" or State.driving then
			Driver.setControls(false)
		end
	end
	player.CharacterAdded:Connect(hookCharacter)
	if player.Character then
		task.spawn(hookCharacter, player.Character)
	end
end

---------------------------------------------------------------------------------------
-- CÂMERA
---------------------------------------------------------------------------------------
local Cam = { yaw = 0, pos = nil :: Vector3?, zoom = 1 }
local CAMERA_MODES = {
	{ name = "PERSEGUIÇÃO", dist = 22, height = 7.5 },
	{ name = "LONGE", dist = 36, height = 13 },
	{ name = "CAPÔ", hood = true },
}

function Game.resetCamera()
	if Truck.chassis then
		Cam.yaw = yawOf(Truck.chassis.CFrame.LookVector)
	end
	Cam.pos = nil
end

local function updateDriveCamera(dt)
	local chassis = Truck.chassis
	local cf = chassis.CFrame
	local vel = chassis.AssemblyLinearVelocity
	local speed = vel.Magnitude
	local mode = CAMERA_MODES[State.camMode]
	camera.CameraType = Enum.CameraType.Scriptable

	State.shake = math.max(0, State.shake - dt * 2.5)
	local s = State.shake * 0.03
	local shakeCF = CFrame.Angles((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0)
	camera.FieldOfView = lerp(camera.FieldOfView, 70 + math.clamp(speed / 90, 0, 1) * 14, math.min(1, dt * 3))

	-- Volta a olhar para frente depois de soltar o mouse
	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		State.camLookTimer -= dt
		if State.camLookTimer <= 0 then
			local a = 1 - math.exp(-dt * 3)
			State.camYawOffset = lerp(State.camYawOffset, 0, a)
			State.camPitchOffset = lerp(State.camPitchOffset, 0, a)
		end
	end

	if mode.hood then
		camera.CFrame = cf * CFrame.new(-1.4, 5.3, -2.6) * CFrame.Angles(0, State.camYawOffset, 0) * CFrame.Angles(State.camPitchOffset - 0.05, 0, 0) * shakeCF
		return
	end

	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	local targetYaw = yawOf(look.Magnitude > 0.01 and look or Vector3.new(0, 0, -1))
	local flatVel = Vector3.new(vel.X, 0, vel.Z)
	if flatVel.Magnitude > 10 and flatVel:Dot(look) > 0 then
		-- em derrapagem a câmera acompanha um pouco a direção do movimento
		local vYaw = yawOf(flatVel)
		targetYaw += math.clamp((((vYaw - targetYaw) + math.pi) % (2 * math.pi)) - math.pi, -0.6, 0.6) * 0.4
	end
	local diff = ((targetYaw - Cam.yaw + math.pi) % (2 * math.pi)) - math.pi
	Cam.yaw += diff * (1 - math.exp(-dt * 3.5))

	local dist = mode.dist * Cam.zoom
	local pitch = math.atan2(mode.height, mode.dist) + State.camPitchOffset
	local rot = CFrame.Angles(0, Cam.yaw + State.camYawOffset, 0) * CFrame.Angles(-pitch, 0, 0)
	local focus = cf.Position + Vector3.new(0, 4, 0)
	local desired = focus + rot:VectorToWorldSpace(Vector3.new(0, 0, dist))
	local dir = desired - focus
	local hit = workspace:Raycast(focus, dir, Truck.rayParams)
	if hit then
		desired = hit.Position - dir.Unit * 1.5
	end
	if not Cam.pos then
		Cam.pos = desired
	end
	Cam.pos = Cam.pos:Lerp(desired, 1 - math.exp(-dt * 10))
	camera.CFrame = CFrame.lookAt(Cam.pos, focus + vel * 0.04) * shakeCF
end

local function updateMenuCamera(dt)
	State.menuAngle += dt * 0.15
	camera.CameraType = Enum.CameraType.Scriptable
	if not Truck.chassis then
		return
	end
	local focus = Truck.chassis.Position + Vector3.new(0, 2, 0)
	local a = State.menuAngle
	local pos = focus + Vector3.new(math.cos(a) * 26, 8, math.sin(a) * 26)
	local base = CFrame.lookAt(pos, focus)
	camera.CFrame = CFrame.lookAt(pos, focus - base.RightVector * 7)
	camera.FieldOfView = 60
end

---------------------------------------------------------------------------------------
-- REGRAS DO JOGO: pontos, postos, entregas, combustível
---------------------------------------------------------------------------------------
local Rules = { timer = 0 }
do
	local SEG = CONFIG.SEGMENT

	function Rules.update(dt)
		Rules.timer += dt
		if Rules.timer < 0.25 then
			return
		end
		Rules.timer = 0
		local chassis = Truck.chassis
		local pos = chassis.Position
		local d = -pos.Z

		-- Distância nova percorrida
		if d > State.bestZ then
			State.score += math.floor((d - State.bestZ) * 0.25)
			State.bestZ = d
		end

		-- Desafio superado
		local k = math.floor(d / SEG) + 1
		local prev = World.segment(k - 1)
		if prev and d > prev.d1 + 5 and not State.challengesDone[prev.k] and not Truck.isUpsideDown() then
			State.challengesDone[prev.k] = true
			local bonus = math.floor(200 * (1 + prev.diff * 2))
			State.score += bonus
			Game.notify(("DESAFIO SUPERADO!  +%d"):format(bonus), Color3.fromRGB(120, 255, 120))
		end

		-- Postos: chegada, reabastecimento e entregas
		for index, outpost in pairs(Segments.outposts) do
			local nearPad = (pos - outpost.pad).Magnitude < 20
			local nearPost = (pos - outpost.pos).Magnitude < 40
			if nearPost and index > 0 and not State.outpostsDone[index] then
				State.outpostsDone[index] = true
				State.outpostsReached += 1
				State.lastOutpost = math.max(State.lastOutpost, index)
				State.score += 300
				Game.notify(("POSTO %d ALCANÇADO!  +300"):format(index))
			end
			if nearPad then
				if CONFIG.FUEL_ENABLED and State.fuel < 99 then
					State.fuel = 100
					Game.notify("TANQUE CHEIO", Color3.fromRGB(120, 200, 255))
				end
				if chassis.AssemblyLinearVelocity.Magnitude < 12 then
					local total, count = 0, 0
					for _, item in ipairs(Truck.cargoInBed()) do
						if item.origin ~= index then
							local value = math.floor(item.value * (1 + 0.15 * index))
							total += value
							count += 1
							if item.def.fuel then
								State.fuel = math.min(100, State.fuel + item.def.fuel)
							end
							Cargo.remove(item)
						end
					end
					if count > 0 then
						State.score += total
						State.delivered += count
						playSound(CONFIG.SOUNDS.deliver, 0.7, 0.8)
						Game.notify(("ENTREGA: %d CARGA(S)  +%d"):format(count, total), Color3.fromRGB(255, 220, 80))
					end
				end
			end
		end

		-- Limpa cargas muito longe
		for i = #Cargo.list, 1, -1 do
			local item = Cargo.list[i]
			if item ~= State.carrying and (item.part.Position - pos).Magnitude > 900 then
				Cargo.remove(item)
			elseif item.part.Position.Y < -400 then
				Cargo.remove(item)
			end
		end
	end
end

---------------------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------------------
local function updateHUD()
	local playing = State.gameState == "playing" or State.gameState == "paused"
	UI.hud.Visible = playing
	UI.help.Visible = State.showHelp
	if not playing or not Truck.chassis then
		return
	end
	local chassis = Truck.chassis
	local vel = chassis.AssemblyLinearVelocity
	local kmh = vel.Magnitude * 1.008
	UI.speedo.Visible = State.driving
	UI.speed.Text = tostring(math.floor(kmh))
	UI.gear.Text = Truck.gear == -1 and "R" or (Truck.throttle == 0 and vel.Magnitude < 1 and "N" or tostring(Truck.gear))
	UI.drive.Text = State.fourWD and "4x4" or "4x2"
	UI.drive.TextColor3 = State.fourWD and UI.ACCENT or Color3.fromRGB(180, 180, 190)
	local rpm = math.clamp(0.12 + Truck.rpm * 0.88 * math.max(Truck.throttle, 0.4), 0, 1)
	UI.rpm.Size = UDim2.fromScale(rpm, 1)
	UI.rpm.BackgroundColor3 = rpm > 0.9 and Color3.fromRGB(255, 60, 40) or UI.ACCENT
	UI.fuel.Size = UDim2.fromScale(State.fuel / 100, 1)
	UI.fuel.BackgroundColor3 = State.fuel < 20 and Color3.fromRGB(255, 60, 40) or Color3.fromRGB(90, 200, 255)

	local d = -chassis.Position.Z
	local bed = Truck.cargoInBed()
	UI.infoLines[1].Text = ("PONTOS: %d"):format(State.score)
	UI.infoLines[2].Text = ("DISTÂNCIA: %d m"):format(math.floor(State.bestZ * 0.28))
	UI.infoLines[3].Text = ("POSTOS: %d"):format(State.outpostsReached)
	UI.infoLines[4].Text = ("CARGA NA CAÇAMBA: %d"):format(#bed)
	UI.infoLines[5].Text = ("ENTREGAS: %d"):format(State.delivered)
	UI.infoLines[6].Text = CONFIG.FUEL_ENABLED and ("COMBUSTÍVEL: %d%%"):format(math.floor(State.fuel)) or ""

	-- Desafio atual
	local info = World.segmentAt(d)
	if info and d > info.d0 - 40 and d < info.d1 then
		UI.banner.Text = ("DESAFIO %d: %s"):format(info.k, info.name)
	else
		UI.banner.Text = ""
	end

	-- Bússola para o próximo posto
	local nextK = math.floor(d / CONFIG.SEGMENT) + 1
	local target = World.trailPoint(nextK * CONFIG.SEGMENT)
	local toTarget = Vector3.new(target.X - chassis.Position.X, 0, target.Z - chassis.Position.Z)
	local look = camera.CFrame.LookVector
	local rel = yawOf(Vector3.new(look.X, 0, look.Z)) - yawOf(toTarget)
	UI.arrow.Rotation = math.deg(rel)
	UI.target.Text = ("POSTO %d  •  %d m"):format(nextK, math.floor(toTarget.Magnitude * 0.28))

	-- Dicas na tela
	local hrp = Driver.parts()
	if State.driving then
		if CONFIG.FUEL_ENABLED and State.fuel <= 0 then
			UI.prompt.Text = "SEM COMBUSTÍVEL — aperte R para chamar o reboque (-300)"
		elseif Truck.isUpsideDown() then
			UI.prompt.Text = "Aperte R para desvirar"
		else
			UI.prompt.Text = ""
		end
	elseif hrp then
		if State.carrying then
			UI.prompt.Text = ("Carregando %s  —  E soltar  •  Clique arremessar"):format(State.carrying.def.name)
		else
			local item = Cargo.nearest(hrp.Position, 9)
			local nearTruck = (hrp.Position - chassis.Position).Magnitude < 13
			if item then
				UI.prompt.Text = ("E  pegar %s"):format(item.def.name) .. (nearTruck and "     F  entrar" or "")
			elseif nearTruck then
				UI.prompt.Text = "F  entrar na caminhonete"
			else
				UI.prompt.Text = "Volte para a caminhonete"
			end
		end
	end
end

---------------------------------------------------------------------------------------
-- FLUXO: carregar, menu, jogar, pausar, novo mapa
---------------------------------------------------------------------------------------
local Sound = { engine = nil :: Sound? }

local function startPosition()
	local d = 25
	local p = World.trailPoint(d)
	return p + Vector3.new(0, 6, 0), World.trailDir(d)
end

local function loadWorld()
	State.gameState = "loading"
	UI.loading.Visible = true
	UI.menu.Visible = false
	local pos, dir = startPosition()
	for i = 1, 400 do
		local left = Chunks.update(pos, 2)
		Segments.update(0)
		UI.loadingText.Text = ("GERANDO O MUNDO... %d blocos restantes"):format(left)
		task.wait()
		if left == 0 and i > 5 then
			break
		end
	end
	Truck.build(CFrame.lookAt(pos, pos + dir))
	Truck.chassis.Anchored = true
	Truck.setLights(false)
	if Sound.engine then
		Sound.engine:Destroy()
		Sound.engine = nil
	end
	if CONFIG.SOUNDS.engine ~= "" then
		Sound.engine = new("Sound", { SoundId = CONFIG.SOUNDS.engine, Looped = true, Volume = 0.4, Parent = Truck.chassis })
		pcall(function()
			(Sound.engine :: Sound):Play()
		end)
	end
	UI.loading.Visible = false
end

local function resetProgress()
	State.fuel = 100
	State.score = 0
	State.bestZ = 0
	State.outpostsReached = 0
	State.lastOutpost = 0
	State.delivered = 0
	State.challengesDone = {}
	State.outpostsDone = {}
end

function Game.toMenu()
	if State.driving then
		Driver.exit()
	end
	if State.carrying then
		Driver.drop(false)
	end
	State.gameState = "menu"
	UI.pause.Visible = false
	UI.menu.Visible = true
	State.showHelp = false
	Driver.setControls(false)
	if Truck.chassis then
		Truck.chassis.Anchored = true
	end
	UI.menuStats.Text = ("PONTOS: %d\nDISTÂNCIA: %d m   ENTREGAS: %d"):format(State.score, math.floor(State.bestZ * 0.28), State.delivered)
end

function Game.play()
	if State.gameState ~= "menu" then
		return
	end
	UI.menu.Visible = false
	State.showHelp = false
	State.gameState = "playing"
	Truck.chassis.Anchored = false
	Driver.enter()
	Game.notify("SIGA A TRILHA ATÉ O PRÓXIMO POSTO!")
end

function Game.resume()
	if State.gameState ~= "paused" then
		return
	end
	State.gameState = "playing"
	UI.pause.Visible = false
	State.showHelp = false
	Truck.chassis.Anchored = false
	Driver.setControls(not State.driving)
end

local function pause()
	if State.gameState ~= "playing" then
		return
	end
	State.gameState = "paused"
	UI.pause.Visible = true
	Truck.chassis.Anchored = true
	Driver.setControls(false)
end

function Game.newMap()
	if State.gameState ~= "menu" then
		return
	end
	State.seed = math.random(1, 50000) + 0.37
	World.resetCache()
	Cargo.clear()
	Segments.clearAll()
	Chunks.clearAll()
	resetProgress()
	loadWorld()
	Game.toMenu()
end

---------------------------------------------------------------------------------------
-- ENTRADA
---------------------------------------------------------------------------------------
local function readInput()
	local input = { throttle = 0, brake = 0, steer = 0, handbrake = false }
	if not (State.driving and State.gameState == "playing") then
		return input
	end
	if isDown(Enum.KeyCode.W) or isDown(Enum.KeyCode.Up) then
		input.throttle = 1
	end
	if isDown(Enum.KeyCode.S) or isDown(Enum.KeyCode.Down) then
		input.brake = 1
	end
	if isDown(Enum.KeyCode.A) or isDown(Enum.KeyCode.Left) then
		input.steer += 1
	end
	if isDown(Enum.KeyCode.D) or isDown(Enum.KeyCode.Right) then
		input.steer -= 1
	end
	input.handbrake = isDown(Enum.KeyCode.Space)
	if UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		for _, s in ipairs(UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)) do
			if s.KeyCode == Enum.KeyCode.ButtonR2 then
				input.throttle = math.max(input.throttle, s.Position.Z)
			elseif s.KeyCode == Enum.KeyCode.ButtonL2 then
				input.brake = math.max(input.brake, s.Position.Z)
			elseif s.KeyCode == Enum.KeyCode.Thumbstick1 and math.abs(s.Position.X) > 0.12 then
				input.steer = -s.Position.X
			end
		end
		if UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonB) then
			input.handbrake = true
		end
	end
	return input
end

local function tryReset()
	if State.resetCooldown > 0 or not Truck.chassis then
		return
	end
	State.resetCooldown = 2
	if CONFIG.FUEL_ENABLED and State.fuel <= 0 then
		-- Reboque até o último posto
		local d = State.lastOutpost * CONFIG.SEGMENT
		local p = World.trailPoint(d + 25)
		Truck.place(p + Vector3.new(0, 6, 0), World.trailDir(d + 25))
		State.fuel = 100
		State.score = math.max(0, State.score - 300)
		Game.notify("REBOCADO ATÉ O POSTO " .. State.lastOutpost .. "  (-300)", Color3.fromRGB(255, 120, 80))
	else
		Truck.reset()
	end
	Game.resetCamera()
end

local function toggleVehicle()
	if State.driving then
		if Truck.chassis.AssemblyLinearVelocity.Magnitude > 15 then
			Game.notify("PARE A CAMINHONETE PARA DESCER", Color3.fromRGB(255, 120, 80))
			return
		end
		Driver.exit()
	else
		local hrp = Driver.parts()
		if hrp and (hrp.Position - Truck.chassis.Position).Magnitude < 13 then
			Driver.enter()
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.P or key == Enum.KeyCode.ButtonStart then
		if State.gameState == "playing" then
			pause()
		elseif State.gameState == "paused" then
			Game.resume()
		end
		return
	end
	if State.gameState ~= "playing" then
		return
	end
	if key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonY then
		toggleVehicle()
	elseif State.driving then
		if key == Enum.KeyCode.R or key == Enum.KeyCode.ButtonX then
			tryReset()
		elseif key == Enum.KeyCode.T then
			State.fourWD = not State.fourWD
			Game.notify(State.fourWD and "TRAÇÃO 4x4" or "TRAÇÃO 4x2")
		elseif key == Enum.KeyCode.H then
			Truck.setLights(not State.lights)
		elseif key == Enum.KeyCode.C then
			State.camMode = State.camMode % #CAMERA_MODES + 1
			Game.notify("CÂMERA: " .. CAMERA_MODES[State.camMode].name)
			Cam.pos = nil
		elseif key == Enum.KeyCode.V then
			Truck.setPaint(State.paint % #PAINTS + 1)
			UI.paintButton.Text = "COR: " .. PAINTS[State.paint].name
		elseif key == Enum.KeyCode.G then
			playSound(CONFIG.SOUNDS.horn, 0.8, 1, Truck.chassis)
		end
	else
		if key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonX then
			if State.carrying then
				Driver.drop(false)
			else
				local hrp = Driver.parts()
				local item = hrp and Cargo.nearest(hrp.Position, 9)
				if item then
					Driver.pickUp(item)
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and State.carrying then
			Driver.drop(true)
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not State.driving or State.gameState ~= "playing" then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		State.camYawOffset -= input.Delta.X * 0.006
		State.camPitchOffset = math.clamp(State.camPitchOffset - input.Delta.Y * 0.004, -0.4, 0.8)
		State.camLookTimer = 1.5
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		Cam.zoom = math.clamp(Cam.zoom - input.Position.Z * 0.1, 0.6, 2)
	end
end)

---------------------------------------------------------------------------------------
-- LOOPS PRINCIPAIS
---------------------------------------------------------------------------------------
local physicsEvent = RunService.PreSimulation or RunService.Stepped
physicsEvent:Connect(function(a, b)
	local dt = typeof(b) == "number" and b or a
	if State.gameState == "playing" and Truck.chassis and not Truck.chassis.Anchored then
		Truck.physicsStep(dt, readInput())
	end
end)

local lastVelocity = Vector3.zero
local holdTimer = 0
local function render(dt)
	dt = math.min(dt, 0.1)
	local gs = State.gameState
	if gs == "loading" then
		return
	end
	local chassis = Truck.chassis
	if not chassis then
		return
	end

	-- Mundo em volta de quem está jogando
	local hrp = Driver.parts()
	local focus = (State.driving or not hrp) and chassis.Position or hrp.Position
	Chunks.update(focus, 1)
	Segments.update(-focus.Z)

	-- Segura a caminhonete se o chão ainda não foi gerado
	if gs == "playing" then
		local loaded = Chunks.isLoaded(chassis.Position)
		if not loaded and not chassis.Anchored then
			chassis.Anchored = true
			holdTimer = 1
		elseif loaded and chassis.Anchored and holdTimer > 0 then
			holdTimer = 0
			chassis.Anchored = false
		end
	end

	Truck.updateVisuals(dt)
	State.resetCooldown = math.max(0, State.resetCooldown - dt)

	if gs == "menu" then
		updateMenuCamera(dt)
	elseif gs == "playing" then
		if State.driving then
			if hrp then
				hrp.CFrame = chassis.CFrame * CFrame.new(-1.4, 2.8, -1.6)
				hrp.AssemblyLinearVelocity = Vector3.zero
				Driver.setHidden(true)
			end
			updateDriveCamera(dt)
			UserInputService.MouseBehavior = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
		end
		Driver.updateCarry()
		Rules.update(dt)

		-- Impactos fortes: som e tremor
		local vel = chassis.AssemblyLinearVelocity
		local jolt = (vel - lastVelocity).Magnitude
		lastVelocity = vel
		if jolt > 45 and State.driving then
			State.shake = math.min(3, State.shake + jolt / 60)
			playSound(CONFIG.SOUNDS.impact, math.clamp(jolt / 120, 0.3, 1), 0.6, chassis)
		end
		-- Suspensão trabalhando também balança a câmera
		for _, w in ipairs(Truck.wheels) do
			local v = math.abs(w.compression - w.lastCompression)
			if v > 0.15 then
				State.shake = math.min(3, State.shake + v * 0.3)
			end
		end
	end

	-- Motor
	if Sound.engine then
		Sound.engine.PlaybackSpeed = 0.7 + Truck.rpm * 1.3 * math.max(Truck.throttle, 0.35)
		Sound.engine.Volume = State.gameState == "playing" and (0.25 + Truck.throttle * 0.35) or 0.1
	end

	-- Dia e noite
	Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / CONFIG.DAY_LENGTH) % 24
	local night = Lighting.ClockTime > 18.3 or Lighting.ClockTime < 6
	if night ~= State.wasNight then
		State.wasNight = night
		if night and State.driving then
			Truck.setLights(true)
		end
	end

	updateHUD()
end

---------------------------------------------------------------------------------------
-- INÍCIO
---------------------------------------------------------------------------------------
task.spawn(function()
	RunService:BindToRenderStep("TrilhaInfinita", Enum.RenderPriority.Camera.Value + 1, render)
	camera.CameraType = Enum.CameraType.Scriptable
	loadWorld()
	Game.toMenu()
end)
