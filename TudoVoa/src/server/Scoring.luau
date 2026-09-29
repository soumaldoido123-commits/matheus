--!nonstrict
--[[
	Scoring: recompensas por arremessos longos, acertos em jogadores e combos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Data = require(script.Parent:WaitForChild("Data"))
local Board = require(script.Parent:WaitForChild("Board"))

local Scoring = {}

local combos = {} -- [player] = { count, last }
local hitCooldowns = {} -- [attacker] = { [victimKey] = t }

local function combo(player: Player): number
	local now = os.clock()
	local c = combos[player]
	if c and now - c.last <= Config.Economy.ComboWindow then
		c.count = math.min(Config.Economy.ComboMax, c.count + 1)
		c.last = now
	else
		c = { count = 1, last = now }
		combos[player] = c
	end
	return c.count
end

function Scoring.comboOf(player: Player): number
	local c = combos[player]
	if c and os.clock() - c.last <= Config.Economy.ComboWindow then
		return c.count
	end
	return 0
end

-- Arremesso terminou (objeto parou). bonus: multiplicador (cristal, pessoa...)
function Scoring.throwLanded(player: Player, distance: number, bonus: number?, position: Vector3?, label: string?)
	if not Data.isLoaded(player) then
		return
	end
	local d = Data.get(player)
	local count = combo(player)
	local mult = (1 + 0.15 * (count - 1)) * (bonus or 1)
	local coins = math.floor((distance ^ Config.Economy.DistanceCoinExponent) * Config.Economy.DistanceCoinFactor * mult)
	local xp = math.floor(distance * 0.28 * mult) + 4
	local record = distance > (d.BestThrow or 0)
	Data.addStat(player, "TotalThrows", 1)
	if record then
		Data.set(player, "BestThrow", math.floor(distance))
		Board.submit(player, distance)
		Remotes.get("Announce"):FireClient(
			player,
			"NOVO RECORDE!",
			string.format("%d studs", math.floor(distance)),
			2.6,
			Config.Palette.Pink
		)
	else
		Board.submit(player, distance)
	end
	if coins > 0 then
		Data.addCoins(player, coins)
	end
	Data.addXP(player, xp)
	Remotes.get("ThrowResult"):FireClient(player, math.floor(distance), coins, xp, record, count, label)
	if position then
		Remotes.get("ScorePopup"):FireClient(
			player,
			position + Vector3.new(0, 4, 0),
			string.format("%d studs%s", math.floor(distance), count > 1 and (" ×" .. count) or ""),
			Config.Palette.Accent
		)
	end
end

-- Acertou um jogador/NPC. Retorna true se pontuou (respeita o cooldown por vitima).
function Scoring.hit(attacker: Player?, victimModel: Model, victimPlayer: Player?, magnitude: number?): boolean
	if not attacker or attacker == victimPlayer then
		return false
	end
	-- marca quem acertou por ultimo (usado por "cair do mundo" e arenas)
	victimModel:SetAttribute("LastHitBy", attacker.UserId)
	victimModel:SetAttribute("LastHitTime", os.clock())

	local now = os.clock()
	local cds = hitCooldowns[attacker]
	if not cds then
		cds = {}
		hitCooldowns[attacker] = cds
	end
	local key = victimPlayer and victimPlayer.UserId or victimModel
	local last = cds[key]
	if last and now - last < Config.Economy.HitCooldownPerVictim then
		return false
	end
	cds[key] = now

	if Data.isLoaded(attacker) then
		local count = combo(attacker)
		local coins = math.floor(Config.Economy.HitCoins * (1 + 0.15 * (count - 1)))
		Data.addStat(attacker, "TotalHits", 1)
		Data.addCoins(attacker, coins)
		Data.addXP(attacker, 8)
		local root = victimModel:FindFirstChild("HumanoidRootPart")
		if root then
			Remotes.get("ScorePopup"):FireClient(attacker, root.Position + Vector3.new(0, 4, 0), "ACERTOU! +" .. coins, Config.Palette.Green)
		end
	end
	return true
end

function Scoring.init()
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		combos[p] = nil
		hitCooldowns[p] = nil
	end)
end

return Scoring
