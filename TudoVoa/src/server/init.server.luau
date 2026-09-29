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

-- 2) sistemas base
local Data = require(script:WaitForChild("Data"))
local Physics = require(script:WaitForChild("Physics"))
local Ragdoll = require(script:WaitForChild("Ragdoll"))
local Scoring = require(script:WaitForChild("Scoring"))
local Board = require(script:WaitForChild("Board"))
local Blasts = require(script:WaitForChild("Blasts"))
local Pickups = require(script:WaitForChild("Pickups"))
local ToyPassive = require(script:WaitForChild("ToyPassive"))
local ToySpawner = require(script:WaitForChild("ToySpawner"))
local Grab = require(script:WaitForChild("Grab"))
local AbilityService = require(script:WaitForChild("AbilityService"))
local Shop = require(script:WaitForChild("Shop"))
local Zones = require(script:WaitForChild("Zones"))
local Atmosphere = require(script:WaitForChild("Atmosphere"))

Atmosphere.init()
Data.init()
Physics.init()
Ragdoll.init()
Scoring.init()
Board.init()
Blasts.init()
Pickups.init()
ToyPassive.init()
ToySpawner.init()
Grab.init()
AbilityService.init()
Shop.init()
Zones.init()

-- 3) jogadores: espera o mundo + dados e so entao cria o personagem
local function spawnPlayer(player: Player)
	local t0 = os.clock()
	while not workspace:GetAttribute("TV_WorldReady") and player.Parent do
		task.wait(0.25)
	end
	while not Data.isLoaded(player) and os.clock() - t0 < 30 and player.Parent do
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
