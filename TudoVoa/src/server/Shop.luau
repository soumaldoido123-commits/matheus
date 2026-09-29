--!nonstrict
--[[
	Shop: compra de brinquedos, cores de cabo e rastros. Tudo com moedas + nivel minimo.
	Chamado pelo cliente via RemoteFunction "Shop": (acao, id) -> ok, mensagem
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Toys = require(Shared:WaitForChild("Toys"))

local Data = require(script.Parent:WaitForChild("Data"))

local Shop = {}

local function findById(list, id)
	for _, item in list do
		if item.id == id then
			return item
		end
	end
	return nil
end

local actions = {}

function actions.buyToy(player, id)
	local toy = Toys.ById[id]
	if not toy then
		return false, "Brinquedo inexistente"
	end
	local d = Data.get(player)
	if toy.price == 0 or d.Toys[id] then
		return false, "Você já tem esse"
	end
	if d.Level < toy.level then
		return false, "Precisa do nível " .. toy.level
	end
	if not Data.spendCoins(player, toy.price) then
		return false, "Moedas insuficientes"
	end
	d.Toys[id] = true
	Data.push(player, "Toys")
	return true, toy.name .. " desbloqueado!"
end

function actions.buyTether(player, id)
	local item = findById(Config.TetherColors, id)
	if not item then
		return false, "Cor inexistente"
	end
	local d = Data.get(player)
	if d.OwnedTethers[id] then
		return false, "Você já tem essa cor"
	end
	if d.Level < item.level then
		return false, "Precisa do nível " .. item.level
	end
	if not Data.spendCoins(player, item.price) then
		return false, "Moedas insuficientes"
	end
	d.OwnedTethers[id] = true
	Data.push(player, "OwnedTethers")
	Data.set(player, "Tether", id)
	return true, item.name .. " equipado!"
end

function actions.equipTether(player, id)
	local d = Data.get(player)
	if not findById(Config.TetherColors, id) or not d.OwnedTethers[id] then
		return false, "Você não tem essa cor"
	end
	Data.set(player, "Tether", id)
	return true, "Cabo trocado"
end

function actions.buyTrail(player, id)
	local item = findById(Config.Trails, id)
	if not item then
		return false, "Rastro inexistente"
	end
	local d = Data.get(player)
	if d.OwnedTrails[id] then
		return false, "Você já tem esse rastro"
	end
	if d.Level < item.level then
		return false, "Precisa do nível " .. item.level
	end
	if not Data.spendCoins(player, item.price) then
		return false, "Moedas insuficientes"
	end
	d.OwnedTrails[id] = true
	Data.push(player, "OwnedTrails")
	Data.set(player, "Trail", id)
	return true, item.name .. " equipado!"
end

function actions.equipTrail(player, id)
	local d = Data.get(player)
	if not findById(Config.Trails, id) or not d.OwnedTrails[id] then
		return false, "Você não tem esse rastro"
	end
	Data.set(player, "Trail", id)
	return true, "Rastro trocado"
end

function Shop.init()
	Remotes.get("Shop").OnServerInvoke = function(player, action, id)
		if type(action) ~= "string" or type(id) ~= "string" then
			return false, "Pedido inválido"
		end
		if not Data.isLoaded(player) then
			return false, "Carregando..."
		end
		local fn = actions[action]
		if not fn then
			return false, "Ação inválida"
		end
		local ok, a, b = pcall(fn, player, id)
		if not ok then
			warn("[Shop] erro:", a)
			return false, "Erro"
		end
		return a, b
	end
end

return Shop
