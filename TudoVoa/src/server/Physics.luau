--!nonstrict
--[[
	Physics: utilidades de fisica no servidor.
	- Grupos de colisao (objetos segurados nao colidem com jogadores)
	- Dono da fisica (network ownership) de objetos e personagens
	- Lancar alvos (objetos ou personagens)
]]

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Physics = {}

local GROUP_PLAYERS = Config.Groups.Players
local GROUP_HELD = Config.Groups.Held

local function registerGroup(name)
	local ok = pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
	return ok
end

function Physics.setGroup(inst: Instance, group: string)
	if inst:IsA("BasePart") then
		inst.CollisionGroup = group
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = group
		end
	end
end

-- Modelo do personagem de um jogador (ou NPC) a partir de qualquer parte dele
function Physics.characterOf(part: Instance): (Model?, Player?)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return model, Players:GetPlayerFromCharacter(model)
		end
		local parent = model.Parent
		model = parent and parent:FindFirstAncestorOfClass("Model") or nil
	end
	return nil, nil
end

function Physics.rootOfCharacter(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

-- parte "principal" para segurar: torso (mais estavel) ou HRP
function Physics.holdPartOfCharacter(model: Model): BasePart?
	return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or Physics.rootOfCharacter(model)
end

function Physics.characterMass(model: Model): number
	local total = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			total += d:GetMass()
		end
	end
	return total
end

-- Dono da fisica para todas as partes soltas de um modelo/parte.
-- player = nil devolve para o servidor.
function Physics.setOwner(target: Instance, player: Player?)
	local function apply(p: BasePart)
		if p.Anchored then
			return
		end
		pcall(function()
			p:SetNetworkOwner(player)
		end)
	end
	if target:IsA("BasePart") then
		if target.AssemblyRootPart == target then
			apply(target)
		end
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") and d.AssemblyRootPart == d then
			apply(d)
		end
	end
end

function Physics.setOwnerAuto(target: Instance)
	local function apply(p: BasePart)
		if p.Anchored then
			return
		end
		pcall(function()
			p:SetNetworkOwnershipAuto()
		end)
	end
	if target:IsA("BasePart") then
		apply(target)
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") and d.AssemblyRootPart == d then
			apply(d)
		end
	end
end

-- Lanca um alvo: parte solta, modelo ou personagem. Personagens de jogadores recebem
-- a velocidade no proprio cliente (ele e o dono da fisica).
function Physics.launch(target: Instance, velocity: Vector3, angular: Vector3?)
	local model, player = nil, nil
	if target:IsA("Model") then
		model = target
	else
		model, player = Physics.characterOf(target)
	end
	if model and model:FindFirstChildOfClass("Humanoid") then
		player = Players:GetPlayerFromCharacter(model)
		if player then
			Remotes.get("Launch"):FireClient(player, velocity)
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.AssemblyLinearVelocity = velocity
				if angular then
					d.AssemblyAngularVelocity = angular
				end
			end
		end
		return
	end
	local function apply(p: BasePart)
		if p.Anchored then
			return
		end
		p.AssemblyLinearVelocity = velocity
		if angular then
			p.AssemblyAngularVelocity = angular
		end
	end
	if target:IsA("BasePart") then
		apply(target.AssemblyRootPart or target)
	else
		for _, d in target:GetDescendants() do
			if d:IsA("BasePart") and d.AssemblyRootPart == d then
				apply(d)
			end
		end
	end
end

-- Impulso (massa * velocidade) num objeto solto: garante que o servidor e o dono.
function Physics.impulse(root: BasePart, impulse: Vector3)
	if root.Anchored then
		return
	end
	if root:GetAttribute("HeldBy") then
		return
	end
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	root:ApplyImpulse(impulse)
end

function Physics.isProtected(player: Player?): boolean
	if not player then
		return false
	end
	if player:GetAttribute("Peaceful") == true then
		return true
	end
	if player:GetAttribute("SafeZone") == true then
		return true
	end
	local shield = player:GetAttribute("ShieldUntil")
	if type(shield) == "number" and shield > workspace:GetServerTimeNow() then
		return true
	end
	local immune = player:GetAttribute("ImmuneUntil")
	if type(immune) == "number" and immune > workspace:GetServerTimeNow() then
		return true
	end
	return false
end

local function hookCharacter(player: Player, character: Model)
	Physics.setGroup(character, GROUP_PLAYERS)
	character.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and d.CollisionGroup == Config.Groups.Default then
			d.CollisionGroup = GROUP_PLAYERS
		end
	end)
end

-- Cria o personagem (LoadCharacter esta obsoleto; usa a versao nova quando existe)
function Physics.loadCharacter(player: Player)
	local ok = pcall(function()
		player:LoadCharacterAsync()
	end)
	if not ok then
		pcall(function()
			player:LoadCharacter()
		end)
	end
end

function Physics.init()
	registerGroup(GROUP_PLAYERS)
	registerGroup(GROUP_HELD)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(GROUP_HELD, GROUP_PLAYERS, false)
	end)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(char)
			hookCharacter(player, char)
		end)
		if player.Character then
			hookCharacter(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
end

-- Marca (ou remove) etiqueta de "agarravel" numa parte raiz
function Physics.markGrabbable(root: BasePart, on: boolean)
	if on then
		CollectionService:AddTag(root, Config.Tags.Grabbable)
	else
		CollectionService:RemoveTag(root, Config.Tags.Grabbable)
	end
end

return Physics
