--!nonstrict
--[[
	ToySpawner: mantem brinquedos espalhados pelo mundo (com reaparecimento) e permite
	que jogadores invoquem os brinquedos que compraram.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Toys = require(Shared:WaitForChild("Toys"))
local Util = require(Shared:WaitForChild("Util"))

local Data = require(script.Parent:WaitForChild("Data"))
local ToyFactory = require(script.Parent:WaitForChild("ToyFactory"))
local ToyPassive = require(script.Parent:WaitForChild("ToyPassive"))

local ToySpawner = {}

local folder
local slots = {} -- { pos, biome, model, nextSpawn }
local playerToys = {} -- [player] = { model, ... }
local lastSpawn = {} -- [player] = t
local rng = Random.new(Config.World.Seed)

local function placeToy(toyId: string, position: Vector3, ownerUserId: number?): Model?
	local toy = Toys.ById[toyId]
	if not toy then
		return nil
	end
	local lift = math.max(toy.size.X, toy.size.Y, toy.size.Z) * 0.6 + 1
	local cf = CFrame.new(position + Vector3.new(0, lift, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local model = ToyFactory.spawn(toyId, cf, folder, ownerUserId)
	if model then
		ToyPassive.attach(model)
	end
	return model
end

function ToySpawner.addSlot(position: Vector3, biome: string)
	table.insert(slots, { pos = position, biome = biome, model = nil, nextSpawn = 0, idleSince = nil })
end

local function fillSlot(slot)
	local pool = Toys.worldPool(slot.biome)
	if #pool == 0 then
		return
	end
	local toy = Util.weightedPick(pool, function(t)
		return t.world[slot.biome] or 0
	end, rng)
	slot.model = placeToy(toy.id, slot.pos, nil)
	slot.idleSince = nil
end

local function busy(body: BasePart): boolean
	return body:GetAttribute("HeldBy") ~= nil or CollectionService:HasTag(body, Config.Tags.Airborne)
end

local function step()
	local now = os.clock()
	for _, slot in slots do
		local model = slot.model
		if not model or not model.Parent then
			slot.model = nil
			if slot.nextSpawn == 0 then
				slot.nextSpawn = now + 6
			elseif now >= slot.nextSpawn then
				slot.nextSpawn = 0
				fillSlot(slot)
			end
		else
			local body = model.PrimaryPart
			if not body then
				model:Destroy()
			elseif body.Position.Y < Config.World.KillY or body.Position.Y > Config.World.SkyY + 500 then
				model:Destroy()
			elseif body:GetAttribute("Rises") and body.Position.Y > Config.World.SkyY + 220 then
				model:Destroy()
			elseif not busy(body) then
				local far = (body.Position - slot.pos).Magnitude > 140
				if far then
					slot.idleSince = slot.idleSince or now
					if now - slot.idleSince > 50 then
						model:Destroy()
					end
				else
					slot.idleSince = nil
				end
			else
				slot.idleSince = nil
			end
		end
	end

	-- brinquedos de jogadores que sairam do mundo
	for player, list in playerToys do
		for i = #list, 1, -1 do
			local m = list[i]
			if not m.Parent then
				table.remove(list, i)
			elseif m.PrimaryPart and m.PrimaryPart.Position.Y < Config.World.KillY then
				m:Destroy()
				table.remove(list, i)
			end
		end
	end
end

function ToySpawner.spawnForPlayer(player: Player, toyId: string): (boolean, string)
	if not Data.isLoaded(player) then
		return false, "Carregando..."
	end
	if not Data.ownsToy(player, toyId) then
		return false, "Você ainda não tem esse brinquedo"
	end
	local toy = Toys.ById[toyId]
	if not toy then
		return false, "Brinquedo inválido"
	end
	if toy.level > Data.get(player).Level then
		return false, "Nível " .. toy.level .. " necessário"
	end
	local now = os.clock()
	if lastSpawn[player] and now - lastSpawn[player] < Config.Economy.SpawnToyCooldown then
		return false, "Calma!"
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false, "Sem personagem"
	end
	lastSpawn[player] = now

	local list = playerToys[player]
	if not list then
		list = {}
		playerToys[player] = list
	end
	while #list >= Config.Economy.MaxPlayerToys do
		local old = table.remove(list, 1)
		if old and old.Parent then
			old:Destroy()
		end
	end
	local pos = hrp.Position + hrp.CFrame.LookVector * 9 + Vector3.new(0, 3, 0)
	local model = placeToy(toyId, pos, player.UserId)
	if not model then
		return false, "Erro ao criar"
	end
	table.insert(list, model)
	Remotes.get("Fx"):FireAllClients("spawn", pos, 1, nil)
	return true, toy.name
end

function ToySpawner.despawnFor(player: Player)
	local list = playerToys[player]
	if list then
		for _, m in list do
			if m.Parent then
				m:Destroy()
			end
		end
	end
	playerToys[player] = nil
end

function ToySpawner.spawnAt(toyId: string, position: Vector3): Model?
	return placeToy(toyId, position, nil)
end

function ToySpawner.init()
	folder = workspace:FindFirstChild("TV_Toys")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TV_Toys"
		folder.Parent = workspace
	end

	Remotes.get("SpawnToy").OnServerEvent:Connect(function(player, toyId)
		if type(toyId) ~= "string" then
			return
		end
		local ok, msg = ToySpawner.spawnForPlayer(player, toyId)
		if not ok then
			Remotes.get("Notify"):FireClient(player, msg, "bad")
		end
	end)
	Remotes.get("DespawnToys").OnServerEvent:Connect(function(player)
		ToySpawner.despawnFor(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		ToySpawner.despawnFor(player)
		lastSpawn[player] = nil
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 2 then
			acc = 0
			step()
		end
	end)
end

function ToySpawner.slotCount(): number
	return #slots
end

return ToySpawner
