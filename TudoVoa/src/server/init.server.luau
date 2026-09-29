--!nonstrict
--[[
	TUDO VOA! — Ilhas do Caos
	Script principal do servidor: inicia os sistemas, gera o mundo e coloca os jogadores.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

Players.CharacterAutoLoads = false
Players.RespawnTime = 3

workspace.Gravity = 196.2
workspace.StreamingEnabled = false
workspace.FallenPartsDestroyHeight = Config.World.KillY - 200
workspace:SetAttribute("TV_WorldReady", false)
workspace:SetAttribute("TV_Progress", 0)
workspace:SetAttribute("TV_LoadText", "Iniciando...")

-- 1) remotes primeiro (todo o resto usa)
Remotes.init()

-- 2) sistemas base (cada um carregado/iniciado de forma protegida: um erro nao derruba o jogo todo)
local function load(name: string): any
	local ok, mod = xpcall(function()
		return require(script:WaitForChild(name, 20))
	end, debug.traceback)
	if not ok then
		warn("[Servidor] falha ao carregar '" .. name .. "':\n" .. tostring(mod))
		return nil
	end
	return mod
end

local function start(name: string, mod: any)
	if mod and type(mod.init) == "function" then
		local ok, err = xpcall(mod.init, debug.traceback)
		if not ok then
			warn("[Servidor] falha ao iniciar '" .. name .. "':\n" .. tostring(err))
		end
	end
end

local Data = load("Data")
local Physics = load("Physics")
local Ragdoll = load("Ragdoll")
local Scoring = load("Scoring")
local Board = load("Board")
local Blasts = load("Blasts")
local Pickups = load("Pickups")
local ToyPassive = load("ToyPassive")
local ToySpawner = load("ToySpawner")
local Grab = load("Grab")
local AbilityService = load("AbilityService")
local Shop = load("Shop")
local Zones = load("Zones")
local Quests = load("Quests")
local Atmosphere = load("Atmosphere")

start("Atmosphere", Atmosphere)
start("Data", Data)
start("Physics", Physics)
start("Ragdoll", Ragdoll)
start("Scoring", Scoring)
start("Board", Board)
start("Blasts", Blasts)
start("Pickups", Pickups)
start("ToyPassive", ToyPassive)
start("ToySpawner", ToySpawner)
start("Grab", Grab)
start("AbilityService", AbilityService)
start("Shop", Shop)
start("Zones", Zones)
start("Quests", Quests)

-- 3) jogadores: espera o mundo + dados e so entao cria o personagem
local function spawnPlayer(player: Player)
	local t0 = os.clock()
	while not workspace:GetAttribute("TV_WorldReady") and player.Parent do
		task.wait(0.25)
	end
	while Data and not Data.isLoaded(player) and os.clock() - t0 < 30 and player.Parent do
		task.wait(0.2)
	end
	if player.Parent then
		Physics.loadCharacter(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(spawnPlayer, player)
end)
for _, p in Players:GetPlayers() do
	task.spawn(spawnPlayer, p)
end

-- 4) mundo (demora alguns segundos)
task.spawn(function()
	local ok, err = xpcall(function()
		local Scenery = require(script:WaitForChild("World"):WaitForChild("Scenery"))
		Scenery.build()
		ToySpawner.fillAll()

		-- atividades e eventos (modulos opcionais: se um falhar, o resto do jogo segue)
		local Activities = script:FindFirstChild("Activities")
		if Activities then
			for _, mod in Activities:GetChildren() do
				if mod:IsA("ModuleScript") then
					local okMod, res = pcall(require, mod)
					if okMod and type(res) == "table" and res.init then
						local okInit, e = pcall(res.init)
						if not okInit then
							warn("[Atividade] falhou ao iniciar", mod.Name, e)
						end
					elseif not okMod then
						warn("[Atividade] falhou ao carregar", mod.Name, res)
					end
				end
			end
		end
	end, debug.traceback)
	if not ok then
		warn("[TudoVoa] erro ao gerar o mundo:\n" .. tostring(err))
		workspace:SetAttribute("TV_LoadText", "Erro ao gerar o mundo (veja o Output)")
	end
	workspace:SetAttribute("TV_WorldReady", true)
	Remotes.get("WorldReady"):FireAllClients()
end)
