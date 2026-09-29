--!nonstrict
--[[
	Hoops: "Cestas" — aros de basquete em varias alturas/distancias perto da praca.
	Faca o objeto arremessado passar por dentro do aro (de cima para baixo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Server = script.Parent.Parent
local Build = require(Server:WaitForChild("World"):WaitForChild("Build"))
local Data = require(Server:WaitForChild("Data"))
local Quests = require(Server:WaitForChild("Quests"))

local Hoops = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local scored = {}

local function makeHoop(folder: Folder, x: number, z: number, height: number, points: number, color: Color3)
	local gy = Build.y(x, z)
	local m = Build.model(folder, "Hoop")
	Build.foundation(m, CFrame.new(x, gy, z), Vector3.new(6, 1, 6))
	Build.cyl(m, CFrame.new(x, gy + height / 2, z), height, 1.2, rgb(70, 74, 110), M.Metal)
	-- tabela virada para o leste (+X): jogadores arremessam do leste para o oeste
	local boardCF = CFrame.new(x - 0.8, gy + height + 4, z)
	local board = Build.block(m, boardCF, Vector3.new(0.6, 8, 12), rgb(245, 245, 250), M.SmoothPlastic)
	Build.block(m, boardCF * CFrame.new(0.32, -1, 0), Vector3.new(0.2, 3.4, 5.4), color, M.SmoothPlastic, { collide = false })
	-- aro: anel de bolinhas de neon (horizontal)
	local ringCenter = Vector3.new(x + 5.4, gy + height + 1.6, z)
	Build.block(m, CFrame.new(x + 2.4, gy + height + 1.6, z), Vector3.new(5.4, 0.5, 0.6), P.Red, M.Metal, { collide = false })
	local n = 14
	for i = 1, n do
		local a = i / n * math.pi * 2
		Build.ball(m, CFrame.new(ringCenter + Vector3.new(math.cos(a) * 4.4, 0, math.sin(a) * 4.4)), 1.1, color, M.Neon, { shadow = false })
	end
	-- rede (cones de cilindros translucidos)
	for i = 0, 3 do
		local d = 8.4 - i * 1.6
		local net = Build.cyl(m, CFrame.new(ringCenter - Vector3.new(0, 1 + i * 1.3, 0)), 1.2, d, Color3.new(1, 1, 1), M.Fabric, { collide = false, transparency = 0.5, shadow = false })
		net.CanQuery = false
	end
	-- sensor dentro do aro
	local sensor = Build.cyl(m, CFrame.new(ringCenter - Vector3.new(0, 0.6, 0)), 1.2, 7, P.Accent, M.Neon, { collide = false, transparency = 1, shadow = false })
	sensor.CanQuery = false
	sensor.CanTouch = true
	Build.billboard(board, string.format("🏀 %d pts", points), { color = P.Accent, offset = Vector3.new(0, 7, 0) })

	sensor.Touched:Connect(function(other)
		local thrower = other:GetAttribute("Thrower")
		if not thrower then
			return
		end
		local vel = other.AssemblyLinearVelocity
		if vel.Y > -4 then
			return -- precisa estar descendo
		end
		if scored[other] and os.clock() - scored[other] < 4 then
			return
		end
		local flat = Vector3.new(other.Position.X - ringCenter.X, 0, other.Position.Z - ringCenter.Z).Magnitude
		if flat > 4.8 then
			return
		end
		scored[other] = os.clock()
		local player = Players:GetPlayerByUserId(thrower)
		if not player or not Data.isLoaded(player) then
			return
		end
		local coins = points
		Quests.report(player, "hoop", 1)
		Data.addCoins(player, coins)
		Data.addXP(player, points * 2)
		Remotes.get("ScorePopup"):FireClient(player, ringCenter + Vector3.new(0, 4, 0), string.format("CESTA! +%d", coins), P.Accent)
		Remotes.get("Fx"):FireAllClients("confetti", ringCenter + Vector3.new(0, 3, 0), 0.7, nil)
		Remotes.get("Fx"):FireAllClients("bounce", ringCenter, 0.8, nil)
	end)
	return m
end

function Hoops.init()
	local folder = Build.folder("Hoops")
	local baseX, baseZ = -95, -85
	makeHoop(folder, baseX, baseZ, 14, 20, P.Green)
	makeHoop(folder, baseX - 12, baseZ - 34, 24, 45, P.Blue)
	makeHoop(folder, baseX - 22, baseZ - 74, 36, 90, P.Pink)
	makeHoop(folder, baseX - 8, baseZ + 38, 10, 12, P.Accent)
	local sy = Build.y(baseX + 40, baseZ)
	local board = Build.block(folder, CFrame.new(baseX + 40, sy + 6, baseZ), Vector3.new(0.6, 8, 20), rgb(36, 34, 90), M.SmoothPlastic)
	Build.label(board, "🏀 CESTAS\nQuanto mais alto, mais moedas!", { color = P.White, face = Enum.NormalId.Left, ppu = 28 })
	Build.foundation(folder, CFrame.new(baseX + 40, sy, baseZ), Vector3.new(2, 1, 2))
end

return Hoops
