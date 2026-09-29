--!nonstrict
--[[
	TUDO VOA! — Ilhas do Caos
	Script principal do cliente: inicia a interface e todos os sistemas locais.
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

local Store = require(script:WaitForChild("Store"))
local Loading = require(script:WaitForChild("UI"):WaitForChild("Loading"))
local HUD = require(script:WaitForChild("UI"):WaitForChild("HUD"))
local Menu = require(script:WaitForChild("UI"):WaitForChild("Menu"))
local Mobile = require(script:WaitForChild("UI"):WaitForChild("Mobile"))
local Tutorial = require(script:WaitForChild("UI"):WaitForChild("Tutorial"))
local Fx = require(script:WaitForChild("Fx"))
local GrabController = require(script:WaitForChild("GrabController"))
local Tether = require(script:WaitForChild("Tether"))
local Pose = require(script:WaitForChild("Pose"))
local ToyPhysics = require(script:WaitForChild("ToyPhysics"))
local Movement = require(script:WaitForChild("Movement"))
local DecorAnim = require(script:WaitForChild("DecorAnim"))
local AbilityBar = require(script:WaitForChild("AbilityBar"))

Loading.init()
Store.init()
Fx.init()
HUD.init()
Menu.init()
Tether.init()
GrabController.init()
Pose.init()
ToyPhysics.init()
Movement.init()
DecorAnim.init()
AbilityBar.init()
Mobile.init()

-- modulos de atividades do cliente (chefao, arena, eventos...) sao opcionais
local Activities = script:FindFirstChild("Activities")
if Activities then
	for _, mod in Activities:GetChildren() do
		if mod:IsA("ModuleScript") then
			local ok, res = pcall(require, mod)
			if ok and type(res) == "table" and res.init then
				local okInit, err = pcall(res.init)
				if not okInit then
					warn("[Cliente] atividade falhou ao iniciar", mod.Name, err)
				end
			elseif not ok then
				warn("[Cliente] atividade falhou ao carregar", mod.Name, res)
			end
		end
	end
end

-- interacoes por tecla E (ProximityPrompt)
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local id = prompt:GetAttribute("Id")
	if id == "shop" then
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
		if worldReady and hasChar and (Store.loaded or os.clock() - t0 > 20) then
			break
		end
		task.wait(0.2)
	end
	Loading.finish()
	Tutorial.init()
end)
