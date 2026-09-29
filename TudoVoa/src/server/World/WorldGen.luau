--!nonstrict
--[[
	WorldGen: gera o terreno (Terrain:WriteVoxels) a partir de uma funcao de altura.
	  - Praca central plana, Fazenda (oeste), Montanha Gelada (norte),
	    Vulcao (leste), Praia + mar (sul)
	  - Estradas de pedra ligando a praca aos biomas, lagos, lago congelado, cratera com lava
	  - Ilhas flutuantes (rocha + grama) no ceu
	A funcao WorldGen.height(x, z) e deterministica e usada pelo resto do mundo para colocar coisas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local WorldGen = {}

local W = Config.World
local B = Config.Biomes
local SEED = W.Seed % 1000 * 0.137
local VOX = W.Voxel

local floor, sqrt, exp, abs, max = math.floor, math.sqrt, math.exp, math.abs, math.max
local smooth, saturate = Util.smoothstep, Util.saturate

-- Ruido -------------------------------------------------------------------------------------

local function fbm(x: number, z: number, freq: number, oct: number, off: number): number
	local amp, sum, norm = 1, 0, 0
	local f = freq
	for i = 1, oct do
		sum += amp * math.noise(x * f + off + 0.113 * i, z * f + off * 1.31 + 0.377 * i, SEED + 7.7 * i)
		norm += amp
		amp *= 0.5
		f *= 2
	end
	return (sum / norm) * 2 -- aproximadamente [-1, 1]
end

-- Lagos (x, z, raio, altura da agua, congelado?)
WorldGen.Lakes = {
	{ x = -560, z = -170, r = 70, water = 13, frozen = false, name = "Lagoa da Fazenda" },
	{ x = 150, z = -320, r = 55, water = 30, frozen = true, name = "Lago Congelado" },
	{ x = 390, z = -270, r = 45, water = 22, frozen = false, name = "Oásis" },
}

-- Estradas: do centro da praca ate cada bioma
local ROADS = {}
for key, b in B do
	if key ~= "Hub" then
		table.insert(ROADS, { a = Vector2.new(0, 0), b = b.center })
	end
end

local function distToSegment(px: number, pz: number, a: Vector2, b: Vector2): number
	local abx, abz = b.X - a.X, b.Y - a.Y
	local t = ((px - a.X) * abx + (pz - a.Y) * abz) / (abx * abx + abz * abz)
	t = saturate(t)
	local cx, cz = a.X + abx * t, a.Y + abz * t
	return sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

function WorldGen.roadDistance(x: number, z: number): number
	local best = 1e9
	for _, r in ROADS do
		local d = distToSegment(x, z, r.a, r.b)
		if d < best then
			best = d
		end
	end
	return best
end

-- Pesos dos biomas em (x, z)
local function weights(x: number, z: number)
	local ws = {}
	local total = 0
	for key, b in B do
		if key ~= "Hub" then
			local dx, dz = x - b.center.X, z - b.center.Y
			local d = sqrt(dx * dx + dz * dz)
			local w = exp(-((d / (b.radius * 1.05)) ^ 2))
			ws[key] = { w = w, d = d }
			total += w
		end
	end
	return ws, max(total, 1e-6)
end

-- Altura de cada bioma ---------------------------------------------------------------------------

local function hFarm(x, z)
	return 21 + 22 * fbm(x, z, 0.0042, 4, 1.0) + 5 * fbm(x, z, 0.02, 2, 2.0)
end

local function hSnow(x, z, d)
	local cone = max(0, 1 - d / 310)
	local ridge = 1 - abs(fbm(x, z, 0.009, 4, 3.0))
	return 26 + 250 * (cone ^ 1.35) * (0.5 + 0.5 * ridge) + 10 * fbm(x, z, 0.03, 3, 4.0) * (0.3 + cone)
end

local function hVolcano(x, z, d)
	local r = d / 270
	local cone = max(0, 1 - r)
	local h = 24 + 178 * (cone ^ 1.12) + 9 * fbm(x, z, 0.022, 3, 5.0)
	-- cratera: prato no topo (r < 0.2)
	local bowl = 1 - smooth(0.06, 0.22, r)
	h -= 74 * bowl
	return h
end

local function hBeach(x, z)
	-- terra firme ate z ~ 380, depois desce suavemente para o mar (linha da costa em z ~ 410)
	local t = saturate((z - 30) / 470)
	return 25 - 44 * smooth(0.55, 1.0, t) + 4 * fbm(x, z, 0.018, 3, 6.0) + 5 * smooth(0.0, 0.3, t) * fbm(x, z, 0.045, 2, 8.0)
end

-- Altura final do terreno em (x, z)
function WorldGen.height(x: number, z: number): number
	local d = sqrt(x * x + z * z)

	local ws, total = weights(x, z)
	local h = 0
	h += ws.Farm.w * hFarm(x, z)
	h += ws.Snow.w * hSnow(x, z, ws.Snow.d)
	h += ws.Volcano.w * hVolcano(x, z, ws.Volcano.d)
	h += ws.Beach.w * hBeach(x, z)
	h /= total

	-- praca central plana e suave
	local t = smooth(W.HubRadius, W.HubRadius + 130, d)
	h = Util.lerp(W.HubHeight, h, t)

	-- lagos
	for _, lake in WorldGen.Lakes do
		local dl = sqrt((x - lake.x) ^ 2 + (z - lake.z) ^ 2)
		local m = 1 - smooth(lake.r * 0.72, lake.r, dl)
		if m > 0 then
			local target = lake.frozen and lake.water or (lake.water - 9)
			h = Util.lerp(h, target, m)
		end
	end

	-- estradas: achatam um pouco e ficam mais lisas
	local rd = WorldGen.roadDistance(x, z)
	if rd < 12 and d > W.HubRadius - 20 then
		local rm = (1 - smooth(4, 12, rd)) * 0.55
		local smoothH = W.HubHeight + (h - W.HubHeight) * 0.6
		h = Util.lerp(h, smoothH, rm)
	end

	-- oceano ao redor da ilha
	local dw = d + 110 * fbm(x, z, 0.0032, 3, 9.0)
	local mask = 1 - smooth(W.IslandRadius - 210, W.IslandRadius + 20, dw)
	local seabed = -40 + 8 * fbm(x, z, 0.01, 2, 10.0)
	h = seabed + (h - seabed) * (mask ^ 0.85)

	return h
end

-- Material da superficie ----------------------------------------------------------------------------

local M = Enum.Material

local function surfaceMaterial(x: number, z: number, h: number, slope: number, ws, total: number)
	local sea = W.SeaLevel
	-- lagos
	for _, lake in WorldGen.Lakes do
		if lake.frozen then
			local dl = sqrt((x - lake.x) ^ 2 + (z - lake.z) ^ 2)
			if dl < lake.r * 0.82 then
				return M.Ice
			end
		end
	end

	-- pesos "crus" (gaussianas): as fronteiras ficam redondas em vez de em cunha
	local nz = fbm(x, z, 0.012, 3, 20.0) * 0.14
	local wSnow = ws.Snow.w + nz
	local wVol = ws.Volcano.w + nz
	local wFarm = ws.Farm.w + nz
	local wBeach = ws.Beach.w + nz
	local d = sqrt(x * x + z * z)

	-- fundo do mar e praia
	if h < sea - 30 then
		return M.Slate
	elseif h < sea + 4.5 + (wBeach > 0.3 and 6 or 0) then
		return M.Sand
	end

	-- estradas de pedra
	if d > W.HubRadius - 10 and WorldGen.roadDistance(x, z) < 4.6 and h > sea + 5 then
		return M.Cobblestone
	end

	-- vulcao
	if wVol > 0.42 then
		local r = ws.Volcano.d / 270
		if r < 0.13 then
			return M.CrackedLava
		end
		if r < 0.7 then
			return (slope > 1.2 or h > 110) and M.Basalt or (fbm(x, z, 0.06, 2, 11) > 0.1 and M.Slate or M.Basalt)
		end
		return fbm(x, z, 0.05, 2, 12) > -0.2 and M.Sand or M.Sandstone
	elseif wVol > 0.2 then
		return fbm(x, z, 0.05, 2, 12) > -0.2 and M.Sand or M.Sandstone
	end

	-- neve
	if wSnow > 0.36 then
		if h > 150 and slope > 1.3 then
			return M.Rock
		end
		if h > 95 then
			return M.Snow
		end
		if slope > 1.4 then
			return M.Rock
		end
		return (fbm(x, z, 0.04, 2, 13) > 0.5) and M.Glacier or M.Snow
	end

	if slope > 1.35 then
		return M.Rock
	end
	if wFarm > 0.3 then
		-- campos: faixas de terra e grama
		if math.sin(x * 0.045 + fbm(x, z, 0.01, 2, 14) * 3) > 0.82 and abs(z + 100) < 260 then
			return M.Ground
		end
		return (fbm(x, z, 0.08, 2, 15) > 0.15) and M.LeafyGrass or M.Grass
	end
	return M.Grass
end

-- Material + altura + inclinacao em (x, z) (usado por cenario e pelo simulador)
function WorldGen.materialAt(x: number, z: number)
	local h = WorldGen.height(x, z)
	local dx = (WorldGen.height(x + VOX, z) - WorldGen.height(x - VOX, z)) / (2 * VOX)
	local dz = (WorldGen.height(x, z + VOX) - WorldGen.height(x, z - VOX)) / (2 * VOX)
	local slope = sqrt(dx * dx + dz * dz) * 1.6
	local ws, total = weights(x, z)
	return surfaceMaterial(x, z, h, slope, ws, total), h, slope
end

-- Escrita do terreno ----------------------------------------------------------------------------------------

local CHUNK = 64 -- voxels por chunk (256 studs)

local function writeChunk(terrain: Terrain, cx: number, cz: number)
	local x0 = -W.Half + cx * CHUNK * VOX
	local z0 = -W.Half + cz * CHUNK * VOX
	local n = CHUNK

	-- grade de alturas com borda de 1 celula (para inclinacao)
	local hg = table.create(n + 2)
	local hmax = W.SeaLevel + 8
	for i = 0, n + 1 do
		local row = table.create(n + 2)
		local x = x0 + (i - 0.5) * VOX
		for k = 0, n + 1 do
			local z = z0 + (k - 0.5) * VOX
			local h = WorldGen.height(x, z)
			row[k] = h
			if h > hmax then
				hmax = h
			end
		end
		hg[i] = row
	end

	local yMin = W.BedrockY
	local yTop = math.ceil((hmax + 8) / VOX) * VOX
	local ny = (yTop - yMin) // VOX
	local mats = table.create(n)
	local occ = table.create(n)
	local sea = W.SeaLevel

	for i = 1, n do
		local mx = table.create(ny)
		local ox = table.create(ny)
		for y = 1, ny do
			mx[y] = table.create(n, M.Air)
			ox[y] = table.create(n, 0)
		end
		mats[i] = mx
		occ[i] = ox
	end

	for i = 1, n do
		local x = x0 + (i - 0.5) * VOX
		for k = 1, n do
			local z = z0 + (k - 0.5) * VOX
			local h = hg[i][k]
			local dx = (hg[i + 1][k] - hg[i - 1][k]) / (2 * VOX)
			local dz = (hg[i][k + 1] - hg[i][k - 1]) / (2 * VOX)
			local slope = sqrt(dx * dx + dz * dz) * 1.6 -- ~ 1 = 45 graus aproximado
			local ws, total = weights(x, z)
			local surf = surfaceMaterial(x, z, h, slope, ws, total)
			local deepMat = M.Rock
			if surf == M.Sand then
				deepMat = M.Sandstone
			elseif surf == M.Basalt or surf == M.CrackedLava then
				deepMat = M.Basalt
			elseif surf == M.Slate then
				deepMat = M.Slate
			end

			-- indice do voxel do topo
			local top = floor((h - yMin) / VOX) + 1
			top = math.clamp(top, 1, ny)
			for y = 1, top do
				local vb = yMin + (y - 1) * VOX
				local frac = 1
				if y == top then
					frac = math.clamp((h - vb) / VOX, 0.05, 1)
				end
				local depth = top - y
				local m = surf
				if depth > 2 then
					m = deepMat
				elseif depth > 0 and surf == M.Grass then
					m = M.Ground
				elseif depth > 0 and surf == M.LeafyGrass then
					m = M.Ground
				end
				mats[i][y][k] = m
				occ[i][y][k] = frac
			end

			-- agua do mar
			if h < sea then
				local wTop = math.min(ny, floor((sea - yMin) / VOX) + 1)
				for y = top + 1, wTop do
					local vb = yMin + (y - 1) * VOX
					mats[i][y][k] = M.Water
					occ[i][y][k] = math.clamp((sea - vb) / VOX, 0.05, 1)
				end
			end
			-- agua dos lagos
			for _, lake in WorldGen.Lakes do
				if not lake.frozen then
					local dl = sqrt((x - lake.x) ^ 2 + (z - lake.z) ^ 2)
					if dl < lake.r * 0.94 and h < lake.water then
						local wTop = math.min(ny, floor((lake.water - yMin) / VOX) + 1)
						for y = top + 1, wTop do
							local vb = yMin + (y - 1) * VOX
							mats[i][y][k] = M.Water
							occ[i][y][k] = math.clamp((lake.water - vb) / VOX, 0.05, 1)
						end
					end
				end
			end
		end
	end

	local region = Region3.new(Vector3.new(x0, yMin, z0), Vector3.new(x0 + n * VOX, yMin + ny * VOX, z0 + n * VOX))
	terrain:WriteVoxels(region, VOX, mats, occ)
end

local function paintTerrain(terrain: Terrain)
	local function c(mat, r, g, b)
		terrain:SetMaterialColor(mat, Color3.fromRGB(r, g, b))
	end
	c(M.Grass, 104, 212, 72)
	c(M.LeafyGrass, 70, 186, 88)
	c(M.Ground, 156, 108, 72)
	c(M.Mud, 122, 88, 62)
	c(M.Sand, 250, 226, 156)
	c(M.Sandstone, 232, 176, 110)
	c(M.Rock, 128, 122, 140)
	c(M.Slate, 88, 96, 118)
	c(M.Basalt, 66, 58, 76)
	c(M.CrackedLava, 255, 106, 24)
	c(M.Snow, 244, 250, 255)
	c(M.Glacier, 178, 226, 250)
	c(M.Ice, 168, 226, 255)
	c(M.Cobblestone, 176, 168, 190)
	c(M.Pavement, 190, 190, 200)
	pcall(function()
		terrain.WaterColor = Color3.fromRGB(58, 196, 236)
		terrain.WaterTransparency = 0.72
		terrain.WaterReflectance = 0.9
		terrain.WaterWaveSize = 0.32
		terrain.WaterWaveSpeed = 12
	end)
end

-- Ilhas flutuantes ---------------------------------------------------------------------------------------------------

WorldGen.SkyIslands = {
	{ id = "Arena", pos = Vector3.new(0, W.SkyY, -40), radius = 105, name = "Ilha da Arena" },
	{ id = "Crystal", pos = Vector3.new(310, W.SkyY + 45, 260), radius = 62, name = "Ilha dos Cristais" },
	{ id = "Boss", pos = Vector3.new(-340, W.SkyY + 10, -230), radius = 118, name = "Ilha do Golem" },
	{ id = "Treasure", pos = Vector3.new(-120, W.SkyY + 125, 320), radius = 46, name = "Ilha do Tesouro" },
	{ id = "Garden", pos = Vector3.new(360, W.SkyY - 30, -330), radius = 74, name = "Jardim Flutuante" },
}

local function buildSkyIslands(terrain: Terrain)
	for _, isl in WorldGen.SkyIslands do
		local p, r = isl.pos, isl.radius
		-- corpo de rocha: pilha de esferas cada vez menores para baixo
		local steps = 7
		for s = 0, steps do
			local t = s / steps
			local rr = r * (1 - t * 0.85) * 0.92
			terrain:FillBall(p - Vector3.new(0, 6 + t * r * 0.9, 0), math.max(rr, 6), M.Rock)
		end
		-- topo plano de grama (cilindro com eixo Y)
		terrain:FillCylinder(CFrame.new(p), 10, r, M.Ground)
		terrain:FillCylinder(CFrame.new(p + Vector3.new(0, 4.5, 0)), 3, r * 0.985, M.Grass)
		task.wait()
	end
end

WorldGen.islandTop = function(isl): number
	return isl.pos.Y + 6
end

function WorldGen.getIsland(id: string)
	for _, isl in WorldGen.SkyIslands do
		if isl.id == id then
			return isl
		end
	end
	return nil
end

-- Cavernas: tuneis escavados na montanha ------------------------------------------------------------------------------------

WorldGen.Cave = {
	entrance = Vector3.new(-200, 0, -470), -- y calculado
	direction = Vector3.new(1, 0, 0),
}

local function carveCave(terrain: Terrain)
	local e = WorldGen.Cave.entrance
	local y = WorldGen.height(e.X, e.Z) + 6
	local start = Vector3.new(e.X, y, e.Z)
	WorldGen.Cave.entranceWorld = start
	local dir = WorldGen.Cave.direction
	-- tunel inclinado para baixo e depois camara grande
	for i = 0, 22 do
		local pos = start + dir * (i * 7) + Vector3.new(0, -i * 1.6 + math.sin(i * 0.5) * 3, math.sin(i * 0.37) * 8)
		terrain:FillBall(pos, 11 + math.sin(i * 0.8) * 2, M.Air)
	end
	local chamber = start + dir * 190 + Vector3.new(0, -32, 0)
	terrain:FillBall(chamber, 52, M.Air)
	terrain:FillBall(chamber + Vector3.new(30, 8, 20), 30, M.Air)
	terrain:FillBall(chamber + Vector3.new(-25, 6, -30), 26, M.Air)
	WorldGen.Cave.chamber = chamber
end

-- API ---------------------------------------------------------------------------------------------------------------------------------------

function WorldGen.spawnPoint(): Vector3
	return Vector3.new(0, W.HubHeight + 4, 24)
end

function WorldGen.build(progress: ((number) -> ())?)
	local terrain = workspace.Terrain
	terrain:Clear()
	paintTerrain(terrain)

	local chunks = (2 * W.Half) // (CHUNK * VOX)
	local total = chunks * chunks
	local done = 0
	for cx = 0, chunks - 1 do
		for cz = 0, chunks - 1 do
			writeChunk(terrain, cx, cz)
			done += 1
			if progress then
				progress(done / total * 0.8)
			end
			task.wait()
		end
	end
	carveCave(terrain)
	if progress then
		progress(0.88)
	end
	task.wait()
	buildSkyIslands(terrain)
	if progress then
		progress(1)
	end
end

return WorldGen
