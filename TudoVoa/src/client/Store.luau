--!nonstrict
--[[
	Store (cliente): copia dos dados do jogador enviados pelo servidor.
	Store.get("Coins"), Store.Changed:Connect(function(chave, valor) ... end)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Toys = require(Shared:WaitForChild("Toys"))

local Store = {}

Store.Changed = Util.Signal.new() -- (chave, valor)
Store.Ready = Util.Signal.new()
Store.loaded = false

local data = {
	Coins = 0,
	XP = 0,
	XPNeeded = 100,
	Level = 1,
	SkillPoints = 0,
	BestThrow = 0,
	TotalThrows = 0,
	TotalHits = 0,
	BossDamage = 0,
	Upgrades = {},
	Toys = {},
	OwnedTethers = { Roxo = true, Ciano = true, Rosa = true },
	OwnedTrails = { Nenhum = true },
	Tether = "Roxo",
	Trail = "Nenhum",
	Settings = { Peaceful = false, Music = true, Sfx = true, Shake = true, Tutorial = false },
	Wins = 0,
	Quests = { slots = {}, completed = 0 },
}

function Store.get(key: string): any
	return data[key]
end

function Store.all()
	return data
end

function Store.upgrade(id: string): number
	return (data.Upgrades and data.Upgrades[id]) or 0
end

function Store.setting(key: string): any
	local s = data.Settings
	if s and s[key] ~= nil then
		return s[key]
	end
	return true
end

function Store.ownsToy(id: string): boolean
	local toy = Toys.ById[id]
	if not toy then
		return false
	end
	return toy.price == 0 or (data.Toys and data.Toys[id] == true)
end

-- multiplicador das recargas das habilidades (Recarga)
function Store.cooldownScale(): number
	return math.max(0.4, 1 - 0.06 * Store.upgrade("Cooldown"))
end

function Store.grabRange(): number
	return Config.Grab.BaseRange + Config.Grab.RangePerLevel * Store.upgrade("Range")
end

function Store.holdMax(): number
	return Config.Grab.HoldMaxBase + Config.Grab.HoldMaxPerLevel * Store.upgrade("Range")
end

function Store.maxHolds(): number
	return 1 + Store.upgrade("DoubleTether")
end

function Store.throwSpeed(mass: number, charge: number): number
	local T = Config.Throw
	local factor = math.clamp((T.RefMass / math.max(mass, 0.5)) ^ T.MassExponent, 0.2, 1.6)
	local power = 1 + T.PowerPerLevel * Store.upgrade("Power")
	local speed = Util.lerp(T.MinSpeed, T.MaxSpeed, charge ^ 0.85) * factor * power
	return math.min(speed, T.MaxSpeedHard)
end

function Store.init()
	Remotes.get("DataSync").OnClientEvent:Connect(function(snapshot)
		for k, v in snapshot do
			data[k] = v
		end
		if not Store.loaded then
			Store.loaded = true
			Store.Ready:Fire()
		end
		for k, v in snapshot do
			Store.Changed:Fire(k, v)
		end
	end)
	Remotes.get("DataChanged").OnClientEvent:Connect(function(key, value)
		data[key] = value
		Store.Changed:Fire(key, value)
	end)
	Remotes.get("ClientReady"):FireServer()
end

return Store
