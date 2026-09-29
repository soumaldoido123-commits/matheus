--!nonstrict
--[[
	Pickups: moedas no mundo. Podem ser jogadas (piñata, alvos) ou fixas (respawn).
	Coletadas por proximidade (um laco a 10 Hz, sem Touched).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Data = require(script.Parent:WaitForChild("Data"))
local Quests = require(script.Parent:WaitForChild("Quests"))

local Pickups = {}

local folder
local coins = {} -- lista de { part, value, born, static, home, respawn }

local GOLD = Color3.fromRGB(255, 205, 50)
local COLLECT_RADIUS = 5.5
local MAGNET_RADIUS = 16

local function makeCoin(position: Vector3, value: number)
	local p = Instance.new("Part")
	p.Name = "Coin"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.35, 2.2, 2.2)
	p.Color = GOLD
	p.Material = Enum.Material.Neon
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Anchored = true
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	p.Massless = true
	p:SetAttribute("Value", value)
	CollectionService:AddTag(p, Config.Tags.Spin)
	CollectionService:AddTag(p, Config.Tags.Bob)
	local pl = Instance.new("PointLight")
	pl.Color = GOLD
	pl.Range = 8
	pl.Brightness = 0.8
	pl.Shadows = false
	pl.Parent = p
	p.Parent = folder
	return p
end

-- Moedas que "explodem" para os lados e caem (efeito de recompensa)
function Pickups.burst(position: Vector3, totalValue: number, count: number)
	count = math.clamp(count, 1, 40)
	local each = math.max(1, math.floor(totalValue / count))
	for i = 1, count do
		local p = makeCoin(position, each)
		local angle = (i / count) * math.pi * 2 + math.random() * 0.6
		local speed = 14 + math.random() * 16
		local vel = Vector3.new(math.cos(angle) * speed, 30 + math.random() * 24, math.sin(angle) * speed)
		-- movimento balistico simples no proprio servidor (moeda e leve e curta)
		local rec = { part = p, value = each, born = os.clock(), static = false, vel = vel, pos = position }
		table.insert(coins, rec)
	end
end

-- Moeda fixa no mapa, reaparece depois de coletada
function Pickups.placeStatic(position: Vector3, value: number, respawn: number?)
	local p = makeCoin(position, value)
	p:SetAttribute("Home", position)
	table.insert(coins, {
		part = p,
		value = value,
		born = os.clock(),
		static = true,
		home = position,
		respawn = respawn or 60,
		vel = nil,
	})
end

local function collect(rec, player: Player)
	Data.addCoins(player, rec.value)
	Data.addXP(player, math.max(1, math.floor(rec.value / 3)))
	Quests.report(player, "coin", rec.value)
	Remotes.get("Fx"):FireClient(player, "coin", rec.part.Position, 1, nil)
	if rec.static then
		rec.part.Parent = nil
		rec.hiddenUntil = os.clock() + rec.respawn
	else
		rec.dead = true
		rec.part:Destroy()
	end
end

local GRAV = Vector3.new(0, -196.2 * 0.45, 0) -- moedas caem "leves"

local function step(dt: number)
	local now = os.clock()
	local players = {}
	for _, pl in Players:GetPlayers() do
		local char = pl.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			table.insert(players, { player = pl, pos = hrp.Position })
		end
	end

	local i = 1
	while i <= #coins do
		local rec = coins[i]
		if rec.dead then
			table.remove(coins, i)
		else
			if rec.static and rec.hiddenUntil then
				if now >= rec.hiddenUntil then
					rec.hiddenUntil = nil
					rec.part.Parent = folder
				end
			else
				local part = rec.part
				if not part.Parent then
					table.remove(coins, i)
					continue
				end
				-- voo balistico
				if rec.vel then
					rec.vel += GRAV * dt
					rec.pos += rec.vel * dt
					part.CFrame = CFrame.new(rec.pos) * CFrame.Angles(0, 0, math.pi / 2)
					if rec.vel.Y < 0 then
						local hit = workspace:Raycast(rec.pos + Vector3.new(0, 2, 0), Vector3.new(0, -4, 0))
						if hit then
							rec.pos = hit.Position + Vector3.new(0, 1.4, 0)
							part.CFrame = CFrame.new(rec.pos) * CFrame.Angles(0, 0, math.pi / 2)
							rec.vel = nil
							rec.settled = now
						end
					end
				end
				-- coleta / imã
				local age = now - rec.born
				for _, pp in players do
					local d = (pp.pos - part.Position).Magnitude
					if d < COLLECT_RADIUS and age > 0.5 then
						collect(rec, pp.player)
						break
					elseif d < MAGNET_RADIUS and age > 1.0 and not rec.vel then
						local dir = (pp.pos - part.Position)
						local move = dir.Unit * math.min(dir.Magnitude, 46 * dt)
						part.CFrame = part.CFrame + move
						if rec.pos then
							rec.pos += move
						end
					end
				end
				-- some sozinha depois de um tempo (nao as fixas)
				if not rec.static and age > 60 then
					rec.dead = true
					part:Destroy()
				end
			end
			i += 1
		end
	end
end

function Pickups.init()
	folder = workspace:FindFirstChild("TV_Pickups")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TV_Pickups"
		folder.Parent = workspace
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.06 then
			step(acc)
			acc = 0
		end
	end)
end

return Pickups
