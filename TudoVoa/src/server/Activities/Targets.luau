--!nonstrict
--[[
	Targets: "Tiro ao Alvo" — alvos parados e moveis num campo perto da praca.
	Acerte com qualquer objeto arremessado: mais longe e mais no centro = mais pontos.
]]

local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Server = script.Parent.Parent
local Build = require(Server:WaitForChild("World"):WaitForChild("Build"))
local Data = require(Server:WaitForChild("Data"))

local Targets = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local RINGS = {
	{ d = 12, color = rgb(250, 250, 250), value = 10 },
	{ d = 9.4, color = rgb(230, 50, 60), value = 20 },
	{ d = 6.6, color = rgb(250, 250, 250), value = 30 },
	{ d = 4.2, color = rgb(230, 50, 60), value = 40 },
	{ d = 1.8, color = rgb(255, 210, 60), value = 60 },
}

local hitCooldown = {}

local function award(player: Player, value: number, dist: number, pos: Vector3, label: string)
	if not Data.isLoaded(player) then
		return
	end
	local mult = 1 + math.min(dist, 260) / 90
	local points = math.floor(value * mult)
	local coins = math.max(2, math.floor(points * 0.45))
	Data.addCoins(player, coins)
	Data.addXP(player, math.floor(points * 0.6))
	Data.addStat(player, "TotalHits", 1)
	Remotes.get("ScorePopup"):FireClient(player, pos + Vector3.new(0, 3, 0), string.format("%s +%d", label, coins), value >= 60 and P.Accent or P.Green)
end

-- Cria um alvo. cf: posicao/orientacao (eixo do disco = lookVector do cf), moving: { axis, dist, time }
local function makeTarget(folder: Folder, center: Vector3, moving)
	local m = Build.model(folder, "Target")
	local faceCF = CFrame.new(center) * CFrame.Angles(0, 0, -math.pi / 2) -- eixo do cilindro = +X (voltado para a praca)
	local anchored = moving == nil
	local opts = function(extra)
		extra = extra or {}
		extra.anchored = anchored
		return extra
	end

	-- poste
	local groundY = Build.y(center.X, center.Z)
	local h = center.Y - groundY
	local pole = Build.cyl(m, CFrame.new(center.X - 0.5, groundY + h / 2, center.Z), h, 1.2, rgb(130, 96, 66), M.Wood, opts())
	local discParts = {}
	for i, r in RINGS do
		local p = Build.cyl(m, faceCF * CFrame.new(0, i * 0.12, 0), 0.3, r.d, r.color, i == #RINGS and M.Neon or M.SmoothPlastic, opts({ collide = false }))
		p.CanTouch = true
		p:SetAttribute("Ring", r.value)
		table.insert(discParts, p)
		if not anchored then
			local w = Instance.new("WeldConstraint")
			w.Part0 = pole
			w.Part1 = p
			w.Parent = p
		end
	end
	if not anchored then
		pole.Anchored = true
		-- cada peca do modelo precisa estar soldada ao "carrier"
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d ~= pole and not d:FindFirstChildOfClass("WeldConstraint") then
				local w = Instance.new("WeldConstraint")
				w.Part0 = pole
				w.Part1 = d
				w.Parent = d
			end
		end
	end
	m.PrimaryPart = pole

	-- placa com a distancia
	local sign = Build.block(m, CFrame.new(center.X - 0.6, groundY + 2.2, center.Z), Vector3.new(0.4, 2.2, 5), rgb(40, 40, 90), M.SmoothPlastic, opts({ collide = false }))
	local dist = (Vector3.new(center.X, 0, center.Z) - Vector3.new(-75, 0, center.Z)).Magnitude
	Build.label(sign, string.format("%dm", math.floor(dist)), { color = P.White, face = Enum.NormalId.Right, ppu = 30 })

	local function onTouch(other: BasePart)
		local thrower = other:GetAttribute("Thrower")
		if not thrower or not other.Parent then
			return
		end
		local now = os.clock()
		if hitCooldown[other] and now - hitCooldown[other] < 1 then
			return
		end
		if other.AssemblyLinearVelocity.Magnitude < 28 then
			return
		end
		local player = Players:GetPlayerByUserId(thrower)
		if not player then
			return
		end
		hitCooldown[other] = now
		-- anel atingido: distancia do impacto ao centro no plano do alvo
		local rel = faceCF:PointToObjectSpace(other.Position)
		local rr = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
		local value = 5
		local label = "ACERTOU"
		for i = #RINGS, 1, -1 do
			if rr <= RINGS[i].d / 2 + 0.6 then
				value = RINGS[i].value
				label = (i == #RINGS) and "NA MOSCA!" or "ACERTOU"
				break
			end
		end
		local throwerPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local dist2 = throwerPos and (throwerPos.Position - center).Magnitude or 60
		award(player, value, dist2, center, label)
		Remotes.get("Fx"):FireAllClients(value >= 60 and "confetti" or "sparkle", center, 0.6, nil)
	end
	for _, p in discParts do
		p.Touched:Connect(onTouch)
	end

	if moving then
		local from = center
		local to = center + moving.axis * moving.dist
		local yOff = 0
		local tinfo = TweenInfo.new(moving.time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		-- move o carrier (o resto vai junto, soldado)
		TweenService:Create(pole, tinfo, { CFrame = pole.CFrame + (to - from) + Vector3.new(0, yOff, 0) }):Play()
	end
	return m
end

function Targets.init()
	local folder = Build.folder("Targets")
	-- campo a oeste da praca; alvos voltados para +X (para quem arremessa da linha de partida)
	local baseX = -75
	local lane = { z = 58 }
	local specs = {
		{ dx = -40, dz = -18, h = 8 },
		{ dx = -55, dz = 12, h = 10 },
		{ dx = -75, dz = -8, h = 14 },
		{ dx = -95, dz = 20, h = 12 },
		{ dx = -115, dz = -24, h = 16 },
		{ dx = -140, dz = 4, h = 18 },
		{ dx = -170, dz = -14, h = 22 },
		{ dx = -200, dz = 18, h = 26 },
	}
	for i, s in specs do
		local x, z = baseX + s.dx, lane.z + s.dz
		local y = Build.y(x, z) + s.h
		local moving = nil
		if i % 3 == 0 then
			moving = { axis = Vector3.new(0, 0, 1), dist = 22, time = 2.4 + i * 0.25 }
		end
		makeTarget(folder, Vector3.new(x, y, z), moving)
	end

	-- linha de partida
	local sy = Build.y(baseX + 6, lane.z)
	local line = Build.block(folder, CFrame.new(baseX + 6, sy + 0.2, lane.z), Vector3.new(2, 0.4, 70), P.Accent, M.Neon, { collide = false })
	local board = Build.block(folder, CFrame.new(baseX - 6, sy + 6, lane.z + 42), Vector3.new(0.6, 7, 16), rgb(36, 34, 90), M.SmoothPlastic)
	Build.label(board, "🎯 TIRO AO ALVO\nArremesse nos alvos!", { color = P.White, face = Enum.NormalId.Right, ppu = 30 })
	Build.foundation(folder, CFrame.new(baseX - 6, sy, lane.z + 42), Vector3.new(2, 1, 2))
	_ = line
	_ = CollectionService
end

return Targets
