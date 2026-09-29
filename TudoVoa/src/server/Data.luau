--!nonstrict
--[[
	Data: dados do jogador (moedas, XP, nivel, upgrades, brinquedos comprados, cosmeticos).
	- Salva em DataStore (com pcall: no Studio sem "Enable Studio Access to API Services"
	  o jogo funciona normalmente, so nao salva).
	- Replica para o cliente via Remotes.DataSync / DataChanged.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Toys = require(Shared:WaitForChild("Toys"))

local Data = {}

Data.Loaded = Util.Signal.new() -- (player)
Data.LevelUp = Util.Signal.new() -- (player, novoNivel)
Data.Changed = Util.Signal.new() -- (player, chave, valor)
Data.multiplier = 1 -- multiplicador global de moedas (evento "Hora do Ouro")

local DEFAULT = {
	Version = 1,
	Coins = Config.Economy.StartCoins,
	XP = 0,
	Level = 1,
	SkillPoints = 0,
	BestThrow = 0,
	TotalThrows = 0,
	TotalHits = 0,
	BossDamage = 0,
	PlayTime = 0,
	Upgrades = {},
	Toys = {}, -- id -> true (comprados)
	OwnedTethers = { Roxo = true, Ciano = true, Rosa = true },
	OwnedTrails = { Nenhum = true },
	Tether = "Roxo",
	Trail = "Nenhum",
	Settings = { Peaceful = false, Music = true, Sfx = true, Shake = true, Tutorial = false },
	LastSlot = 0,
	Wins = 0,
	Quests = { slots = {}, completed = 0 },
}

local profiles = {} -- [player] = { data, loaded, dirty, lastSave }
local store = nil
local canPersist = false

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Progression.StoreName)
	end)
	if ok then
		store = result
		canPersist = true
	end
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = deepCopy(v)
	end
	return out
end

local function reconcile(target, template)
	for k, v in template do
		if target[k] == nil then
			target[k] = deepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" then
			reconcile(target[k], v)
		end
	end
end

function Data.xpForLevel(level: number): number
	return math.floor(Config.Progression.XPBase * (level ^ Config.Progression.XPExponent))
end

local PUBLIC_KEYS = {
	"Coins", "XP", "Level", "SkillPoints", "BestThrow", "TotalThrows", "TotalHits", "BossDamage",
	"Upgrades", "Toys", "OwnedTethers", "OwnedTrails", "Tether", "Trail", "Settings", "Wins", "Quests",
}

function Data.snapshot(player: Player)
	local prof = profiles[player]
	if not prof then
		return nil
	end
	local snap = {}
	for _, k in PUBLIC_KEYS do
		snap[k] = deepCopy(prof.data[k])
	end
	snap.XPNeeded = Data.xpForLevel(prof.data.Level)
	return snap
end

function Data.get(player: Player)
	local prof = profiles[player]
	return prof and prof.data or nil
end

function Data.isLoaded(player: Player): boolean
	local prof = profiles[player]
	return prof ~= nil and prof.loaded
end

local function updateLeaderstats(player: Player)
	local prof = profiles[player]
	if not prof then
		return
	end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		return
	end
	local lvl = ls:FindFirstChild("Nível")
	if lvl then
		lvl.Value = prof.data.Level
	end
	local coins = ls:FindFirstChild("Moedas")
	if coins then
		coins.Value = math.floor(prof.data.Coins)
	end
	local best = ls:FindFirstChild("Recorde")
	if best then
		best.Value = math.floor(prof.data.BestThrow)
	end
end

local function push(player: Player, key: string)
	local prof = profiles[player]
	if not prof then
		return
	end
	prof.dirty = true
	local value = deepCopy(prof.data[key])
	Remotes.get("DataChanged"):FireClient(player, key, value)
	if key == "XP" or key == "Level" then
		Remotes.get("DataChanged"):FireClient(player, "XPNeeded", Data.xpForLevel(prof.data.Level))
	end
	if key == "Settings" then
		player:SetAttribute("Peaceful", prof.data.Settings.Peaceful == true)
	elseif key == "Tether" then
		player:SetAttribute("TetherColor", prof.data.Tether)
	elseif key == "Trail" then
		player:SetAttribute("TetherTrail", prof.data.Trail)
	elseif key == "Level" then
		player:SetAttribute("Level", prof.data.Level)
	end
	updateLeaderstats(player)
	Data.Changed:Fire(player, key, value)
end

Data.push = push

function Data.set(player: Player, key: string, value: any)
	local prof = profiles[player]
	if not prof then
		return
	end
	prof.data[key] = value
	push(player, key)
end

function Data.addCoins(player: Player, amount: number, reason: string?): number
	local prof = profiles[player]
	if not prof or amount == 0 then
		return 0
	end
	amount = math.floor(amount)
	if amount > 0 and Data.multiplier ~= 1 then
		amount = math.floor(amount * Data.multiplier)
	end
	prof.data.Coins = math.max(0, prof.data.Coins + amount)
	push(player, "Coins")
	if amount > 0 then
		Remotes.get("Notify"):FireClient(player, "+" .. Util.formatNumber(amount) .. " 🪙" .. (reason and (" · " .. reason) or ""), "coin")
	end
	return amount
end

function Data.spendCoins(player: Player, amount: number): boolean
	local prof = profiles[player]
	if not prof or prof.data.Coins < amount then
		return false
	end
	prof.data.Coins -= amount
	push(player, "Coins")
	return true
end

function Data.addXP(player: Player, amount: number)
	local prof = profiles[player]
	if not prof or amount <= 0 then
		return
	end
	local d = prof.data
	if d.Level >= Config.Progression.MaxLevel then
		return
	end
	d.XP += math.floor(amount)
	local leveled = false
	while d.XP >= Data.xpForLevel(d.Level) and d.Level < Config.Progression.MaxLevel do
		d.XP -= Data.xpForLevel(d.Level)
		d.Level += 1
		d.SkillPoints += Config.Progression.SkillPointEvery
		leveled = true
		Data.LevelUp:Fire(player, d.Level)
	end
	push(player, "XP")
	if leveled then
		push(player, "Level")
		push(player, "SkillPoints")
		Remotes.get("Announce"):FireClient(
			player,
			"NÍVEL " .. d.Level .. "!",
			"+1 ponto de habilidade  ·  novas coisas foram liberadas",
			3.5,
			Config.Palette.Accent
		)
	end
end

function Data.addStat(player: Player, key: string, amount: number)
	local prof = profiles[player]
	if not prof then
		return
	end
	prof.data[key] = (prof.data[key] or 0) + amount
	push(player, key)
end

function Data.getUpgrade(player: Player, id: string): number
	local prof = profiles[player]
	if not prof then
		return 0
	end
	return prof.data.Upgrades[id] or 0
end

function Data.upgradeCost(player: Player, id: string): number
	local cur = Data.getUpgrade(player, id)
	if id == "DoubleTether" then
		return 5
	end
	return 1 + cur // 3
end

function Data.buyUpgrade(player: Player, id: string): (boolean, string)
	local prof = profiles[player]
	local def = Config.Upgrades[id]
	if not prof or not def then
		return false, "Upgrade inválido"
	end
	local cur = prof.data.Upgrades[id] or 0
	if cur >= def.max then
		return false, "Já está no máximo"
	end
	local cost = Data.upgradeCost(player, id)
	if prof.data.SkillPoints < cost then
		return false, "Faltam pontos de habilidade (" .. cost .. ")"
	end
	prof.data.SkillPoints -= cost
	prof.data.Upgrades[id] = cur + 1
	push(player, "SkillPoints")
	push(player, "Upgrades")
	return true, def.name .. " nível " .. (cur + 1)
end

function Data.ownsToy(player: Player, id: string): boolean
	local prof = profiles[player]
	local toy = Toys.ById[id]
	if not prof or not toy then
		return false
	end
	if toy.price == 0 then
		return true
	end
	return prof.data.Toys[id] == true
end

function Data.getSetting(player: Player, key: string): any
	local prof = profiles[player]
	if not prof then
		return nil
	end
	return prof.data.Settings[key]
end

function Data.setSetting(player: Player, key: string, value: any)
	local prof = profiles[player]
	if not prof then
		return
	end
	if prof.data.Settings[key] == nil then
		return
	end
	if typeof(value) ~= typeof(prof.data.Settings[key]) then
		return
	end
	prof.data.Settings[key] = value
	push(player, "Settings")
end

-- Persistencia ----------------------------------------------------------------

local function load(player: Player)
	local key = "P_" .. player.UserId
	local data = nil
	if canPersist then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(key)
			end)
			if ok then
				data = result
				break
			end
			if RunService:IsStudio() then
				-- Studio sem "Enable Studio Access to API Services": nao adianta tentar de novo
				canPersist = false
				warn("[Data] DataStore indisponivel no Studio; jogando sem salvar. (" .. tostring(result) .. ")")
				break
			end
			task.wait(attempt)
		end
	end
	if type(data) ~= "table" then
		data = deepCopy(DEFAULT)
	else
		reconcile(data, DEFAULT)
	end
	return data
end

local function save(player: Player, force: boolean?)
	local prof = profiles[player]
	if not prof or not prof.loaded or not canPersist then
		return
	end
	if not prof.dirty and not force then
		return
	end
	prof.dirty = false
	local key = "P_" .. player.UserId
	local snapshot = deepCopy(prof.data)
	for attempt = 1, 3 do
		local ok = pcall(function()
			store:SetAsync(key, snapshot)
		end)
		if ok then
			return
		end
		task.wait(attempt * 1.5)
	end
	prof.dirty = true
end

Data.save = save

local function onPlayerAdded(player: Player)
	local prof = { data = nil, loaded = false, dirty = false, joined = os.clock() }
	profiles[player] = prof

	-- leaderstats (aparece na lista de jogadores)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Nível", "Moedas", "Recorde" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Value = 0
		v.Parent = ls
	end
	ls.Parent = player

	local data = load(player)
	if not player.Parent then
		profiles[player] = nil
		return
	end
	prof.data = data
	prof.loaded = true

	player:SetAttribute("Peaceful", data.Settings.Peaceful == true)
	player:SetAttribute("TetherColor", data.Tether)
	player:SetAttribute("TetherTrail", data.Trail)
	player:SetAttribute("Level", data.Level)
	updateLeaderstats(player)
	Data.Loaded:Fire(player)
end

local function onPlayerRemoving(player: Player)
	local prof = profiles[player]
	if prof and prof.loaded then
		prof.data.PlayTime += os.clock() - prof.joined
		save(player, true)
	end
	profiles[player] = nil
end

function Data.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end

	-- o cliente pede o snapshot quando estiver pronto
	Remotes.get("ClientReady").OnServerEvent:Connect(function(player)
		task.spawn(function()
			local t0 = os.clock()
			while not Data.isLoaded(player) and os.clock() - t0 < 30 do
				task.wait(0.1)
			end
			local snap = Data.snapshot(player)
			if snap then
				Remotes.get("DataSync"):FireClient(player, snap)
			end
		end)
	end)

	Remotes.get("SetSetting").OnServerEvent:Connect(function(player, key, value)
		if type(key) ~= "string" then
			return
		end
		Data.setSetting(player, key, value)
	end)

	Remotes.get("BuyUpgrade").OnServerEvent:Connect(function(player, id)
		if type(id) ~= "string" then
			return
		end
		local ok, msg = Data.buyUpgrade(player, id)
		Remotes.get("Notify"):FireClient(player, msg, ok and "good" or "bad")
	end)

	-- autosave
	task.spawn(function()
		while true do
			task.wait(Config.Progression.SaveInterval)
			for player in profiles do
				task.spawn(save, player)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.2)
		end
	end)
end

return Data
