--!nonstrict
--[[
	Plots: "Vila dos Jogadores" — casinhas que cada jogador pode reivindicar.
	Dentro de um lote ninguem consegue agarrar ninguem (zona segura). O dono pode pintar a casa.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Server = script.Parent.Parent
local Build = require(Server:WaitForChild("World"):WaitForChild("Build"))
local Zones = require(Server:WaitForChild("Zones"))

local Plots = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local PALETTE = {
	rgb(255, 214, 200), rgb(200, 232, 255), rgb(214, 255, 210), rgb(255, 240, 180),
	rgb(236, 210, 255), rgb(255, 196, 226), rgb(200, 255, 244), rgb(255, 224, 170),
}
local ROOFS = { rgb(220, 80, 90), rgb(70, 110, 200), rgb(90, 160, 90), rgb(230, 150, 50), rgb(140, 90, 200), rgb(220, 90, 160), rgb(60, 170, 170), rgb(200, 110, 60) }

local plots = {}

local function refresh(plot)
	local owner = plot.owner
	if owner then
		plot.pp.ActionText = "Visitar (dono: pintar)"
		plot.pp.ObjectText = "Casa de " .. owner.DisplayName
		plot.sign.Text = "🏠 " .. owner.DisplayName
	else
		plot.pp.ActionText = "Reivindicar casa"
		plot.pp.ObjectText = "Lote livre"
		plot.sign.Text = "LOTE LIVRE\n[E] reivindicar"
	end
end

local function release(player: Player)
	for _, plot in plots do
		if plot.owner == player then
			plot.owner = nil
			plot.colorIndex = plot.baseIndex
			plot.body.Color = PALETTE[plot.colorIndex]
			refresh(plot)
		end
	end
end

local function ownedBy(player: Player)
	for _, plot in plots do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

local function makePlot(folder: Folder, center: Vector3, faceTo: Vector3, index: number)
	local samples = {}
	for dx = -18, 18, 9 do
		for dz = -18, 18, 9 do
			table.insert(samples, Build.y(center.X + dx, center.Z + dz))
		end
	end
	local top, low = -1e9, 1e9
	for _, y in samples do
		top = math.max(top, y)
		low = math.min(low, y)
	end
	local floorY = top + 0.6
	local pos = Vector3.new(center.X, floorY, center.Z)
	-- o "fundo" (-Z) do lote aponta para longe do centro da vila; a frente (+Z, com portao/correio) olha para ele
	local cf = CFrame.lookAt(pos, Vector3.new(2 * pos.X - faceTo.X, floorY, 2 * pos.Z - faceTo.Z))
	local m = Build.model(folder, "Plot" .. index)

	-- gramado
	local depth = floorY - low + 6
	Build.block(m, cf * CFrame.new(0, -depth / 2, 0), Vector3.new(42, depth, 42), rgb(120, 96, 80), M.Ground)
	Build.block(m, cf * CFrame.new(0, 0.1, 0), Vector3.new(42, 0.4, 42), rgb(104, 212, 72), M.Grass)
	-- calçada
	Build.block(m, cf * CFrame.new(0, 0.35, 12), Vector3.new(6, 0.3, 24), rgb(200, 196, 210), M.Cobblestone, { collide = false })

	-- casa (fundos do lote)
	local house = Build.house(m, cf * CFrame.new(0, 0, -8), Vector3.new(18, 11, 14), PALETTE[index], ROOFS[index], "House")
	local body = house.PrimaryPart

	-- cerca em volta (com portao aberto na frente)
	local function fence(from: Vector3, to: Vector3)
		local mid = (from + to) / 2
		local len = (to - from).Magnitude
		local look = CFrame.lookAt(cf * mid, cf * to)
		Build.block(m, look * CFrame.new(0, 1.6, 0), Vector3.new(0.5, 0.5, len), rgb(240, 236, 226), M.Wood, { collide = false })
		Build.block(m, look * CFrame.new(0, 0.7, 0), Vector3.new(0.5, 0.5, len), rgb(240, 236, 226), M.Wood, { collide = false })
	end
	fence(Vector3.new(-20, 0, -20), Vector3.new(20, 0, -20))
	fence(Vector3.new(-20, 0, -20), Vector3.new(-20, 0, 20))
	fence(Vector3.new(20, 0, -20), Vector3.new(20, 0, 20))
	fence(Vector3.new(-20, 0, 20), Vector3.new(-6, 0, 20))
	fence(Vector3.new(6, 0, 20), Vector3.new(20, 0, 20))
	for _, c in { Vector3.new(-20, 0, -20), Vector3.new(20, 0, -20), Vector3.new(-20, 0, 20), Vector3.new(20, 0, 20), Vector3.new(-6, 0, 20), Vector3.new(6, 0, 20) } do
		Build.block(m, cf * CFrame.new(c.X, 1.2, c.Z), Vector3.new(0.9, 2.6, 0.9), rgb(210, 200, 190), M.Wood)
	end

	-- caixa de correio com placa
	local post = Build.block(m, cf * CFrame.new(9, 1.4, 17), Vector3.new(0.6, 2.8, 0.6), rgb(120, 84, 52), M.Wood)
	local board = Build.block(m, cf * CFrame.new(9, 4.2, 17), Vector3.new(7, 2.6, 0.4), rgb(40, 34, 90), M.SmoothPlastic)
	local label = Build.label(board, "", { color = P.White, face = Enum.NormalId.Front, ppu = 40 })
	local pp = Build.prompt(post, "Reivindicar casa", "Lote livre", "plot")
	pp.MaxActivationDistance = 12

	local plot = { owner = nil, body = body, sign = label, pp = pp, colorIndex = index, baseIndex = index, center = pos }
	table.insert(plots, plot)
	refresh(plot)
	table.insert(Zones.SafeExtra, { center = pos + Vector3.new(0, 6, 0), radius = 32 })

	pp.Triggered:Connect(function(player)
		if not plot.owner then
			if ownedBy(player) then
				Remotes.get("Notify"):FireClient(player, "Você já tem uma casa!", "bad")
				return
			end
			plot.owner = player
			refresh(plot)
			Remotes.get("Announce"):FireClient(player, "CASA SUA!", "Ninguém consegue agarrar você aqui dentro", 2.5, P.Green)
			Remotes.get("Fx"):FireAllClients("confetti", pos + Vector3.new(0, 8, 0), 0.8, nil)
		elseif plot.owner == player then
			plot.colorIndex = plot.colorIndex % #PALETTE + 1
			plot.body.Color = PALETTE[plot.colorIndex]
			Remotes.get("Fx"):FireAllClients("spawn", pos + Vector3.new(0, 6, -8), 1, nil)
		else
			Remotes.get("Notify"):FireClient(player, "Casa de " .. plot.owner.DisplayName, "info")
		end
	end)
end

function Plots.init()
	local folder = Build.folder("Plots")
	-- vila a sudeste da praca, em arco, todas viradas para o centro da vila
	local villageCenter = Config.World.Village
	local n = 8
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 1.5 + math.pi * 0.85
		local pos = villageCenter + Vector3.new(math.cos(a) * 78, 0, math.sin(a) * 78)
		makePlot(folder, pos, villageCenter, i)
	end
	-- praca da vila
	local y = Build.y(villageCenter.X, villageCenter.Z)
	Build.cyl(folder, CFrame.new(villageCenter.X, y + 0.2, villageCenter.Z), 1, 34, rgb(226, 218, 240), M.Marble)
	Build.lamp(folder, Vector3.new(villageCenter.X, y + 0.7, villageCenter.Z), 14, rgb(255, 226, 150))
	local sign = Build.block(folder, CFrame.new(villageCenter.X, y + 8, villageCenter.Z + 12), Vector3.new(16, 4, 0.5), rgb(40, 34, 90), M.SmoothPlastic)
	Build.label(sign, "🏘️ VILA DOS JOGADORES", { color = P.Accent, face = Enum.NormalId.Front })
	Build.foundation(folder, CFrame.new(villageCenter.X, y, villageCenter.Z + 12), Vector3.new(2, 1, 2))

	Players.PlayerRemoving:Connect(release)
end

return Plots
