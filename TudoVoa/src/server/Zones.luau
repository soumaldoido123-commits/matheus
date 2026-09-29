--!nonstrict
--[[
	Zones: em que regiao cada jogador esta (mostra "voce entrou em..."), zona segura
	da praca, e quedas do mundo (respawn, com credito para quem empurrou por ultimo).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Data = require(script.Parent:WaitForChild("Data"))
local Scoring = require(script.Parent:WaitForChild("Scoring"))

local Zones = {}

Zones.SafeRadius = 62 -- raio da zona segura no centro da praca
Zones.SafeExtra = {} -- outras zonas seguras: { { center = Vector3, radius = number } }

local SKY_NAMES = {}

function Zones.registerSkyName(center: Vector3, radius: number, name: string, icon: string?)
	table.insert(SKY_NAMES, { center = center, radius = radius, name = name, icon = icon or "☁️" })
end

function Zones.at(position: Vector3): (string, string)
	if position.Y > Config.World.SkyY - 60 then
		for _, s in SKY_NAMES do
			local flat = Vector3.new(position.X - s.center.X, 0, position.Z - s.center.Z)
			if flat.Magnitude <= s.radius + 20 then
				return s.name, s.icon
			end
		end
		return "Céu", "☁️"
	end
	local best, bestD = nil, math.huge
	for key, b in Config.Biomes do
		local d = (Vector2.new(position.X, position.Z) - b.center).Magnitude
		if d < b.radius and d < bestD then
			best, bestD = b, d
		end
	end
	if best then
		return best.name, best.icon
	end
	if position.Y < Config.World.SeaLevel - 3 then
		return "Mar Aberto", "🌊"
	end
	return "Ilha Principal", "🏝️"
end

local function isSafe(position: Vector3): boolean
	local flat = Vector3.new(position.X, 0, position.Z)
	if flat.Magnitude <= Zones.SafeRadius and position.Y < Config.World.SkyY - 60 then
		return true
	end
	for _, z in Zones.SafeExtra do
		if (position - z.center).Magnitude <= z.radius then
			return true
		end
	end
	return false
end

local function respawn(player: Player)
	task.wait(3)
	if player.Parent then
		local ok, err = pcall(function()
			player:LoadCharacter()
		end)
		if not ok then
			warn("[Zones] LoadCharacter falhou:", err)
		end
	end
end

function Zones.init()
	local last = {}
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local pos = hrp.Position
					local name, icon = Zones.at(pos)
					if last[player] ~= name then
						last[player] = name
						player:SetAttribute("Zone", name)
						Remotes.get("Zone"):FireClient(player, name, icon)
					end
					local safe = isSafe(pos)
					if player:GetAttribute("SafeZone") ~= safe then
						player:SetAttribute("SafeZone", safe)
					end
					-- caiu do mundo
					if pos.Y < Config.World.KillY then
						hum.Health = 0
					end
				end
			end
		end
	end)

	local function watch(player: Player)
		player.CharacterAdded:Connect(function(char)
			local hum = char:WaitForChild("Humanoid", 10)
			if not hum then
				return
			end
			hum.Died:Connect(function()
				-- credito para quem empurrou por ultimo (ate 12 s antes)
				local by = char:GetAttribute("LastHitBy")
				local t = char:GetAttribute("LastHitTime")
				if by and t and os.clock() - t < 12 then
					local killer = Players:GetPlayerByUserId(by)
					if killer and killer ~= player and Data.isLoaded(killer) then
						Data.addCoins(killer, 25, "derrubou " .. player.DisplayName)
						Data.addXP(killer, 20)
					end
				end
				respawn(player)
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		last[p] = nil
	end)
	_ = Scoring
end

return Zones
