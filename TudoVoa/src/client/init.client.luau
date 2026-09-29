--!nonstrict
--[[
	TUDO VOA! — Ilhas do Caos
	Script principal do cliente: inicia a interface e todos os sistemas locais.
	Cada modulo e carregado/iniciado de forma protegida: se um falhar, o resto do jogo continua.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

-- espera o servidor criar os remotes
Remotes.get("ClientReady")

-- esconde a mochila padrao (nao usamos ferramentas); mantem a lista de jogadores
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local function load(parent: Instance, name: string): any
	local ok, mod = xpcall(function()
		return require(parent:WaitForChild(name, 20))
	end, debug.traceback)
	if not ok then
		warn("[Cliente] falha ao carregar '" .. name .. "':\n" .. tostring(mod))
		return nil
	end
	return mod
end

local function start(name: string, mod: any)
	if mod and type(mod.init) == "function" then
		local ok, err = xpcall(mod.init, debug.traceback)
		if not ok then
			warn("[Cliente] falha ao iniciar '" .. name .. "':\n" .. tostring(err))
		end
	end
end

local UI = script:WaitForChild("UI")
local Store = load(script, "Store")
local Loading = load(UI, "Loading")
local HUD = load(UI, "HUD")
local Menu = load(UI, "Menu")
local Mobile = load(UI, "Mobile")
local Tutorial = load(UI, "Tutorial")
local QuestPanel = load(UI, "QuestPanel")
local Fx = load(script, "Fx")
local GrabController = load(script, "GrabController")
local Tether = load(script, "Tether")
local Pose = load(script, "Pose")
local ToyPhysics = load(script, "ToyPhysics")
local Movement = load(script, "Movement")
local DecorAnim = load(script, "DecorAnim")
local AbilityBar = load(script, "AbilityBar")
local Ambient = load(script, "Ambient")

-- ordem importa: carregamento e dados primeiro
start("Loading", Loading)
start("Store", Store)
start("Fx", Fx)
start("HUD", HUD)
start("Menu", Menu)
start("QuestPanel", QuestPanel)
start("Tether", Tether)
start("GrabController", GrabController)
start("Pose", Pose)
start("ToyPhysics", ToyPhysics)
start("Movement", Movement)
start("DecorAnim", DecorAnim)
start("AbilityBar", AbilityBar)
start("Ambient", Ambient)
start("Mobile", Mobile)

-- modulos de atividades do cliente (chefao, arena, eventos...)
local Activities = script:FindFirstChild("Activities")
if Activities then
	for _, mod in Activities:GetChildren() do
		if mod:IsA("ModuleScript") then
			start(mod.Name, load(Activities, mod.Name))
		end
	end
end

-- interacoes por tecla E (ProximityPrompt)
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local id = prompt:GetAttribute("Id")
	if id == "shop" and Menu then
		Menu.open("shop")
	end
end)

-- tira a tela de carregamento quando o mundo, os dados e o personagem estiverem prontos
task.spawn(function()
	local t0 = os.clock()
	while os.clock() - t0 < 120 do
		local worldReady = workspace:GetAttribute("TV_WorldReady") == true
		local char = player.Character
		local hasChar = char and char:FindFirstChild("HumanoidRootPart") ~= nil
		if worldReady and hasChar and ((Store and Store.loaded) or os.clock() - t0 > 20) then
			break
		end
		task.wait(0.2)
	end
	if Loading then
		Loading.finish()
	end
	start("Tutorial", Tutorial)
end)
