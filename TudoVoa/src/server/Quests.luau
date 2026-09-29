--!nonstrict
--[[
	Quests (servidor): mantem 3 missoes ativas por jogador, conta progresso e paga recompensas.
	Outros modulos chamam Quests.report(jogador, tipo, quantidade).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local QuestDefs = require(Shared:WaitForChild("QuestDefs"))

local Data = require(script.Parent:WaitForChild("Data"))

local Quests = {}

local rng = Random.new()

local function pickNew(data, level: number)
	local slots = data.Quests.slots
	local taken = {}
	for _, s in slots do
		taken[s.id] = true
	end
	local pool = {}
	for _, q in QuestDefs.List do
		if not taken[q.id] and (q.minLevel or 1) <= level then
			table.insert(pool, q)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

local function ensure(player: Player)
	local d = Data.get(player)
	if not d then
		return
	end
	if type(d.Quests) ~= "table" then
		d.Quests = { slots = {}, completed = 0 }
	end
	d.Quests.slots = d.Quests.slots or {}
	d.Quests.completed = d.Quests.completed or 0
	-- remove missoes que nao existem mais
	for i = #d.Quests.slots, 1, -1 do
		if not QuestDefs.ById[d.Quests.slots[i].id] then
			table.remove(d.Quests.slots, i)
		end
	end
	while #d.Quests.slots < QuestDefs.SlotCount do
		local q = pickNew(d, d.Level)
		if not q then
			break
		end
		table.insert(d.Quests.slots, { id = q.id, progress = 0 })
	end
	Data.push(player, "Quests")
end

function Quests.report(player: Player, kind: string, amount: number?)
	local d = Data.get(player)
	if not d or type(d.Quests) ~= "table" then
		return
	end
	amount = amount or 1
	local changed = false
	for i = #d.Quests.slots, 1, -1 do
		local s = d.Quests.slots[i]
		local def = QuestDefs.ById[s.id]
		if def and def.kind == kind then
			s.progress = math.min(def.goal, s.progress + amount)
			changed = true
			if s.progress >= def.goal then
				-- concluida!
				d.Quests.completed += 1
				table.remove(d.Quests.slots, i)
				Data.addCoins(player, def.coins, "missão")
				Data.addXP(player, def.xp)
				Remotes.get("Announce"):FireClient(player, "MISSÃO CUMPRIDA!", def.icon .. " " .. def.text, 3, Config.Palette.Green)
				local nq = pickNew(d, d.Level)
				if nq then
					table.insert(d.Quests.slots, { id = nq.id, progress = 0 })
				end
			end
		end
	end
	if changed then
		Data.push(player, "Quests")
	end
end

function Quests.init()
	Data.Loaded:Connect(function(player)
		ensure(player)
	end)
	for _, p in Players:GetPlayers() do
		if Data.isLoaded(p) then
			ensure(p)
		end
	end
	-- missoes de nivel mais alto passam a entrar ao subir de nivel (nas vagas livres)
	Data.LevelUp:Connect(function(player)
		ensure(player)
	end)
end

return Quests
