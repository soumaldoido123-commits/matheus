--!nonstrict
--[[
	Board: placar de recordes de arremesso (maior distancia).
	Usa OrderedDataStore quando disponivel; sempre mantem uma copia em memoria do servidor.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Board = {}

Board.Changed = Util.Signal.new()

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(Config.Progression.BoardStoreName)
	end)
	if ok then
		store = result
	end
end

local local_best = {} -- [userId] = { name, value } (so desta sessao do servidor)
local global_cache = {} -- ultima leitura global
local last_fetch = 0

function Board.submit(player: Player, distance: number)
	local value = math.floor(distance)
	local rec = local_best[player.UserId]
	if rec and rec.value >= value then
		return
	end
	local_best[player.UserId] = { name = player.DisplayName, userId = player.UserId, value = value }
	Board.Changed:Fire()
	if store then
		task.spawn(function()
			pcall(function()
				store:UpdateAsync("U_" .. player.UserId, function(old)
					if old and old >= value then
						return old
					end
					return value
				end)
			end)
		end)
	end
end

local function fetchGlobal()
	if not store or os.clock() - last_fetch < 30 then
		return
	end
	last_fetch = os.clock()
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 10)
	end)
	if not ok or not pages then
		return
	end
	local ok2, top = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not ok2 then
		return
	end
	local list = {}
	for _, entry in top do
		local userId = tonumber(string.match(entry.key, "U_(%d+)"))
		local name = "Jogador"
		if userId then
			local okName, n = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if okName then
				name = n
			end
		end
		table.insert(list, { name = name, userId = userId, value = entry.value })
	end
	global_cache = list
end

-- Lista combinada (global + sessao), top 10
function Board.top(): { { name: string, value: number } }
	task.spawn(fetchGlobal)
	local merged = {}
	local seen = {}
	for _, r in global_cache do
		seen[r.userId or r.name] = r
	end
	for _, r in local_best do
		local key = r.userId or r.name
		local cur = seen[key]
		if not cur or cur.value < r.value then
			seen[key] = r
		end
	end
	for _, r in seen do
		table.insert(merged, r)
	end
	table.sort(merged, function(a, b)
		return a.value > b.value
	end)
	local out = {}
	for i = 1, math.min(10, #merged) do
		out[i] = { name = merged[i].name, value = merged[i].value }
	end
	return out
end

function Board.init()
	Remotes.get("GetBoard").OnServerInvoke = function()
		return Board.top()
	end
end

return Board
