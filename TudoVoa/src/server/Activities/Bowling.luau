--!nonstrict
--[[
	Bowling: "Boliche Gigante" — pista com 10 pinos fisicos. Derrube todos com qualquer objeto.
	Depois do primeiro impacto, espera os pinos assentarem, paga por pino e arruma tudo de novo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Server = script.Parent.Parent
local Build = require(Server:WaitForChild("World"):WaitForChild("Build"))
local Data = require(Server:WaitForChild("Data"))
local Pickups = require(Server:WaitForChild("Pickups"))

local Bowling = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local pinFolder
local pins = {} -- { part, home }
local origin -- CFrame do inicio da pista (x cresce para os pinos)
local roundThrower, roundStart, resetting = nil, nil, false
local rec_time = nil

local PIN_SIZE = Vector3.new(5, 2.4, 2.4) -- cilindro com eixo em X; deitado em CFrame para ficar de pe

local function makePin(home: Vector3): Part
	local p = Instance.new("Part")
	p.Name = "Pin"
	p.Shape = Enum.PartType.Cylinder
	p.Size = PIN_SIZE
	p.CFrame = CFrame.new(home) * CFrame.Angles(0, 0, math.pi / 2)
	p.Color = rgb(250, 250, 250)
	p.Material = M.SmoothPlastic
	p.CustomPhysicalProperties = PhysicalProperties.new(0.9, 0.5, 0.25, 1, 1)
	p.Anchored = false
	p.Parent = pinFolder
	-- faixa vermelha
	local band = Instance.new("Part")
	band.Shape = Enum.PartType.Cylinder
	band.Size = Vector3.new(0.7, 2.5, 2.5)
	band.CFrame = p.CFrame * CFrame.new(1.2, 0, 0)
	band.Color = rgb(230, 50, 60)
	band.Material = M.SmoothPlastic
	band.CanCollide = false
	band.Massless = true
	band.CanTouch = false
	band.Parent = pinFolder
	local w = Instance.new("WeldConstraint")
	w.Part0 = p
	w.Part1 = band
	w.Parent = band
	band.Parent = p
	pcall(function()
		p:SetNetworkOwner(nil)
	end)
	p.Touched:Connect(function(other)
		local thrower = other:GetAttribute("Thrower")
		if thrower and not roundThrower and not resetting then
			roundThrower = thrower
			roundStart = os.clock()
		end
	end)
	return p
end

local function rackPins()
	for _, rec in pins do
		if rec.part and rec.part.Parent then
			rec.part:Destroy()
		end
	end
	table.clear(pins)
	local idx = 0
	for row = 0, 3 do
		for k = 0, row do
			idx += 1
			local local_ = Vector3.new(row * 3.4, PIN_SIZE.Y / 2 + 0.4, (k - row / 2) * 3.4)
			local home = (origin * CFrame.new(local_)).Position
			table.insert(pins, { part = makePin(home), home = home })
		end
	end
end

local function knockedCount(): number
	local n = 0
	for _, rec in pins do
		local p = rec.part
		if not p.Parent then
			n += 1
		else
			-- de pe = eixo X do cilindro apontando para cima
			local up = math.abs(p.CFrame.RightVector.Y)
			if up < 0.72 or (p.Position - rec.home).Magnitude > 3.5 then
				n += 1
			end
		end
	end
	return n
end

local function settle()
	local player = roundThrower and Players:GetPlayerByUserId(roundThrower)
	local knocked = knockedCount()
	local center = (origin * CFrame.new(5, 4, 0)).Position
	if player and Data.isLoaded(player) and knocked > 0 then
		local coins = knocked * 10 + (knocked == #pins and 120 or 0)
		Data.addCoins(player, coins)
		Data.addXP(player, coins)
		local label = knocked == #pins and "STRIKE!" or string.format("%d pinos", knocked)
		Remotes.get("ScorePopup"):FireClient(player, center + Vector3.new(0, 6, 0), string.format("%s +%d", label, coins), knocked == #pins and P.Accent or P.Green)
		if knocked == #pins then
			Remotes.get("Announce"):FireClient(player, "STRIKE!", "Derrubou todos os pinos", 2, P.Accent)
			Remotes.get("Fx"):FireAllClients("confetti", center, 1.3, nil)
		end
	end
	roundThrower, roundStart = nil, nil
	resetting = true
	task.wait(2.5)
	rackPins()
	resetting = false
end

function Bowling.init()
	local folder = Build.folder("Bowling")
	pinFolder = Build.folder("BowlingPins")

	-- pista a leste da praca, ao longo de +X
	local sx, sz = 112, 70
	local samples = {}
	for i = 0, 6 do
		table.insert(samples, Build.y(sx + i * 16, sz))
		table.insert(samples, Build.y(sx + i * 16, sz + 10))
		table.insert(samples, Build.y(sx + i * 16, sz - 10))
	end
	local top, low = -1e9, 1e9
	for _, y in samples do
		top = math.max(top, y)
		low = math.min(low, y)
	end
	local floorY = top + 0.8
	local len = 118
	local center = Vector3.new(sx + len / 2, floorY, sz)
	origin = CFrame.new(sx + len - 24, floorY, sz)

	-- plataforma + pista
	local depth = floorY - low + 6
	Build.block(folder, CFrame.new(center.X, floorY - depth / 2, center.Z), Vector3.new(len + 8, depth, 26), rgb(120, 110, 130), M.Concrete)
	Build.block(folder, CFrame.new(center.X, floorY + 0.1, center.Z), Vector3.new(len, 0.4, 14), rgb(214, 160, 100), M.WoodPlanks)
	for _, sgn in { -1, 1 } do
		Build.block(folder, CFrame.new(center.X, floorY + 0.25, center.Z + sgn * 7.6), Vector3.new(len, 0.5, 1.6), rgb(50, 54, 100), M.SmoothPlastic)
		Build.block(folder, CFrame.new(center.X, floorY + 0.5, center.Z + sgn * 8.6), Vector3.new(len, 0.6, 0.3), P.Pink, M.Neon, { collide = false, shadow = false })
	end
	-- setas na pista
	for i = 1, 6 do
		local wedge = Build.wedge(folder, CFrame.new(sx + 28 + i * 4, floorY + 0.35, sz + (i - 3.5) * 1.1) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(0.4, 0.2, 1.6), rgb(90, 50, 30), M.SmoothPlastic, { collide = false })
		_ = wedge
	end
	-- paredao dos pinos
	local wall = Build.block(folder, CFrame.new(sx + len + 1, floorY + 8, sz), Vector3.new(2, 16, 26), rgb(44, 40, 100), M.SmoothPlastic)
	Build.label(wall, "🎳 BOLICHE GIGANTE", { color = P.Accent, face = Enum.NormalId.Left })
	Build.block(folder, CFrame.new(sx + len - 4, floorY + 16.4, sz), Vector3.new(0.4, 0.6, 26), P.Pink, M.Neon, { collide = false })
	local sign = Build.block(folder, CFrame.new(sx - 4, floorY + 6, sz - 12), Vector3.new(0.6, 6, 14), rgb(36, 34, 90), M.SmoothPlastic)
	Build.label(sign, "Jogue qualquer objeto\nnos pinos. Strike = +120!", { color = P.White, face = Enum.NormalId.Right, ppu = 32 })
	-- linha de arremesso
	Build.block(folder, CFrame.new(sx + 6, floorY + 0.4, sz), Vector3.new(1, 0.2, 14), P.Accent, M.Neon, { collide = false })

	rackPins()

	task.spawn(function()
		while true do
			task.wait(0.5)
			if roundThrower and not resetting and roundStart and os.clock() - roundStart > 6 then
				settle()
			elseif not roundThrower and not resetting then
				-- arruma sozinho se alguem bagunçou os pinos
				local disturbed = 0
				for _, rec in pins do
					if not rec.part.Parent or (rec.part.Position - rec.home).Magnitude > 3.5 then
						disturbed += 1
					end
				end
				if disturbed > 0 then
					rec_time = rec_time or os.clock()
					if os.clock() - rec_time > 20 then
						rec_time = nil
						rackPins()
					end
				else
					rec_time = nil
				end
			end
		end
	end)
	_ = Pickups
end

return Bowling
