--!nonstrict
--[[
	Farm: a Fazenda Maluca (oeste). Celeiro, moinho, silo, cercas, animais, plantacoes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Build = require(script.Parent:WaitForChild("Build"))
local Nature = require(script.Parent:WaitForChild("Nature"))

local Farm = {}

local M = Enum.Material
local P = Config.Palette
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function siteCF(x: number, z: number, faceTo: Vector3?): CFrame
	local y = Build.y(x, z)
	local pos = Vector3.new(x, y, z)
	local target = faceTo or Vector3.new(0, y, 0)
	return CFrame.lookAt(pos, Vector3.new(target.X, y, target.Z))
end

local function barn(folder: Folder, x: number, z: number)
	local cf = siteCF(x, z)
	local m = Build.model(folder, "Barn")
	Build.foundation(m, cf, Vector3.new(28, 1, 24), rgb(150, 130, 120), M.Concrete)
	local red = rgb(200, 52, 52)
	local body = Build.block(m, cf * CFrame.new(0, 8.5, 0), Vector3.new(26, 16, 22), red, M.WoodPlanks)
	-- telhado gambrel (dois planos duplos)
	for _, sgn in { -1, 1 } do
		Build.block(m, cf * CFrame.new(sgn * 8.2, 17.2, 0) * CFrame.Angles(0, 0, -sgn * math.rad(30)), Vector3.new(11, 1.2, 24), rgb(70, 60, 90), M.Slate)
		Build.block(m, cf * CFrame.new(sgn * 3.2, 20.6, 0) * CFrame.Angles(0, 0, -sgn * math.rad(52)), Vector3.new(7, 1.2, 24), rgb(70, 60, 90), M.Slate)
	end
	Build.block(m, cf * CFrame.new(0, 22.2, 0), Vector3.new(2.4, 1.4, 24.4), rgb(50, 44, 70), M.Slate)
	-- porta grande com X branco
	local door = Build.block(m, cf * CFrame.new(0, 6.2, 11.05), Vector3.new(10, 12, 0.4), rgb(240, 236, 230), M.WoodPlanks)
	Build.block(m, cf * CFrame.new(0, 6.2, 11.3), Vector3.new(10, 12, 0.4), red, M.WoodPlanks)
	for _, sgn in { -1, 1 } do
		Build.block(m, cf * CFrame.new(0, 6.2, 11.55) * CFrame.Angles(0, 0, sgn * math.rad(50)), Vector3.new(1, 15, 0.3), rgb(240, 236, 230), M.WoodPlanks)
	end
	Build.block(m, cf * CFrame.new(0, 16.8, 11.1), Vector3.new(6, 5, 0.4), rgb(70, 40, 30), M.Wood)
	local sign = Build.block(m, cf * CFrame.new(0, 23.4, 11.4), Vector3.new(19, 3.4, 0.5), rgb(255, 236, 200), M.SmoothPlastic)
	Build.label(sign, "FAZENDA MALUCA", { color = rgb(190, 48, 48), stroke = false })
	m.PrimaryPart = body
	_ = door
	Nature.reserve(x, z, 24)
end

local function silo(folder: Folder, x: number, z: number)
	local cf = siteCF(x, z)
	local m = Build.model(folder, "Silo")
	Build.foundation(m, cf, Vector3.new(14, 1, 14))
	Build.cyl(m, cf * CFrame.new(0, 13, 0), 26, 12, rgb(196, 200, 214), M.Metal)
	for i = 0, 3 do
		Build.cyl(m, cf * CFrame.new(0, 4 + i * 6, 0), 0.5, 12.4, rgb(120, 126, 150), M.Metal)
	end
	local dome = Build.ball(m, cf * CFrame.new(0, 26, 0), 12, rgb(196, 200, 214), M.Metal, { collide = false })
	dome.Size = Vector3.new(12, 8, 12)
	Nature.reserve(x, z, 10)
end

local function windmill(folder: Folder, x: number, z: number)
	local cf = siteCF(x, z, Vector3.new(0, 0, 0))
	local m = Build.model(folder, "Windmill")
	Build.foundation(m, cf, Vector3.new(16, 1, 16))
	-- torre em degraus
	local heights = { { 14, 5 }, { 12, 5 }, { 10, 5 }, { 8, 5 } }
	local y = 0.5
	for _, t in heights do
		Build.cyl(m, cf * CFrame.new(0, y + t[2] / 2, 0), t[2], t[1], rgb(250, 244, 230), M.SmoothPlastic)
		y += t[2]
	end
	Build.cyl(m, cf * CFrame.new(0, y + 1.5, 0), 3, 9, rgb(190, 60, 60), M.SmoothPlastic)
	Build.cyl(m, cf * CFrame.new(0, y + 4, 0), 2, 4, rgb(190, 60, 60), M.SmoothPlastic)
	-- eixo + pas (giram no cliente ao redor de Z)
	local blades = Build.model(m, "Blades")
	local hubCF = cf * CFrame.new(0, y + 1.5, 5.4)
	local hub = Build.ball(blades, hubCF, 3.2, rgb(90, 60, 50), M.Wood, { collide = false })
	blades.PrimaryPart = hub
	for i = 0, 3 do
		local a = i * math.pi / 2
		local arm = hubCF * CFrame.Angles(0, 0, a) * CFrame.new(0, 8.5, 0.4)
		Build.block(blades, arm, Vector3.new(1, 15, 0.6), rgb(150, 100, 70), M.Wood, { collide = false })
		Build.block(blades, arm * CFrame.new(1.8, 2.2, 0.35), Vector3.new(3, 9, 0.3), rgb(255, 250, 240), M.Fabric, { collide = false })
	end
	Build.spin(blades, "Z", 22)
	Nature.reserve(x, z, 12)
end

local function fenceLine(folder: Folder, a: Vector3, b: Vector3)
	local dir = b - a
	local len = dir.Magnitude
	local n = math.max(2, math.floor(len / 6))
	for i = 0, n do
		local p = a + dir * (i / n)
		local y = Build.y(p.X, p.Z)
		Build.block(folder, CFrame.new(p.X, y + 2, p.Z), Vector3.new(0.8, 4.4, 0.8), rgb(176, 130, 90), M.Wood)
	end
	for _, h in { 1.6, 3.2 } do
		local mid = (a + b) / 2
		local y = Build.y(mid.X, mid.Z)
		Build.block(folder, CFrame.lookAt(Vector3.new(mid.X, y + h, mid.Z), Vector3.new(b.X, y + h, b.Z)), Vector3.new(0.5, 0.5, len), rgb(196, 150, 104), M.Wood)
	end
end

local function pen(folder: Folder, cx: number, cz: number, w: number, d: number)
	local corners = {
		Vector3.new(cx - w / 2, 0, cz - d / 2),
		Vector3.new(cx + w / 2, 0, cz - d / 2),
		Vector3.new(cx + w / 2, 0, cz + d / 2),
		Vector3.new(cx - w / 2, 0, cz + d / 2),
	}
	for i = 1, 4 do
		if i ~= 3 then -- deixa um lado aberto
			fenceLine(folder, corners[i], corners[i % 4 + 1])
		end
	end
	Nature.reserve(cx, cz, math.max(w, d) * 0.7)
end

local function animal(folder: Folder, pos: Vector3, kind: string, rng: Random)
	local m = Build.model(folder, "Animal_" .. kind)
	local yaw = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	local body, head, spot, legs
	if kind == "pig" then
		body, head, spot, legs = rgb(255, 170, 196), rgb(255, 150, 184), rgb(255, 120, 160), rgb(255, 150, 184)
	else
		body, head, spot, legs = rgb(250, 250, 250), rgb(250, 250, 250), rgb(40, 40, 46), rgb(230, 230, 230)
	end
	local torso = Build.block(m, yaw * CFrame.new(0, 3.4, 0), Vector3.new(3.6, 3, 5.6), body, M.SmoothPlastic)
	Build.block(m, yaw * CFrame.new(0, 4.1, -3.6), Vector3.new(2.8, 2.8, 2.8), head, M.SmoothPlastic, { collide = false })
	Build.block(m, yaw * CFrame.new(0, 3.7, -5.2), Vector3.new(1.6, 1.2, 0.6), kind == "pig" and rgb(255, 120, 150) or rgb(255, 190, 190), M.SmoothPlastic, { collide = false })
	Build.ball(m, yaw * CFrame.new(-0.8, 4.9, -4.9), 0.45, rgb(20, 20, 20), M.SmoothPlastic, { collide = false })
	Build.ball(m, yaw * CFrame.new(0.8, 4.9, -4.9), 0.45, rgb(20, 20, 20), M.SmoothPlastic, { collide = false })
	for _, sx in { -1, 1 } do
		Build.block(m, yaw * CFrame.new(sx * 1.6, 5.9, -3.3), Vector3.new(0.9, 1.3, 0.5), spot, M.SmoothPlastic, { collide = false })
		for _, sz in { -1.9, 1.9 } do
			Build.block(m, yaw * CFrame.new(sx * 1.2, 1.1, sz), Vector3.new(1, 2.2, 1), legs, M.SmoothPlastic)
		end
	end
	if kind == "cow" then
		Build.block(m, yaw * CFrame.new(0.9, 4.2, 0.6), Vector3.new(1.6, 1.4, 1.8), spot, M.SmoothPlastic, { collide = false })
		Build.block(m, yaw * CFrame.new(-1.0, 3.2, 1.6), Vector3.new(1.4, 1.5, 1.4), spot, M.SmoothPlastic, { collide = false })
	end
	m.PrimaryPart = torso
	Build.bob(torso, 0.15, 2 + rng:NextNumber(0, 1.5))
end

local function tractor(folder: Folder, x: number, z: number)
	local cf = siteCF(x, z)
	local m = Build.model(folder, "Tractor")
	local body = Build.block(m, cf * CFrame.new(0, 3.6, 0), Vector3.new(5, 3, 8), rgb(64, 170, 80), M.SmoothPlastic)
	Build.block(m, cf * CFrame.new(0, 6.4, 1.6), Vector3.new(4.4, 3.6, 4), rgb(48, 140, 62), M.SmoothPlastic)
	local glass = Build.block(m, cf * CFrame.new(0, 6.6, 1.65), Vector3.new(4.5, 2.4, 3.2), rgb(190, 235, 255), M.Glass)
	glass.Transparency = 0.4
	for _, sx in { -1, 1 } do
		Build.cyl(m, cf * CFrame.new(sx * 3, 2.6, 2.6) * CFrame.Angles(0, 0, math.pi / 2), 1.6, 5.2, rgb(30, 30, 36), M.Rubber)
		Build.cyl(m, cf * CFrame.new(sx * 2.7, 1.9, -2.6) * CFrame.Angles(0, 0, math.pi / 2), 1.2, 3.6, rgb(30, 30, 36), M.Rubber)
	end
	Build.cyl(m, cf * CFrame.new(0, 5.6, -3.8), 3, 0.5, rgb(90, 90, 100), M.Metal)
	m.PrimaryPart = body
end

local function scarecrow(folder: Folder, pos: Vector3, rng: Random)
	local m = Build.model(folder, "Scarecrow")
	local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	local post = Build.block(m, cf * CFrame.new(0, 5, 0), Vector3.new(0.7, 10, 0.7), rgb(150, 110, 70), M.Wood)
	Build.block(m, cf * CFrame.new(0, 7, 0), Vector3.new(7, 0.7, 0.7), rgb(150, 110, 70), M.Wood)
	Build.block(m, cf * CFrame.new(0, 6, 0), Vector3.new(2.6, 3.4, 1.4), rgb(70, 110, 200), M.Fabric, { collide = false })
	Build.ball(m, cf * CFrame.new(0, 9.2, 0), 2.6, rgb(245, 200, 120), M.Fabric, { collide = false })
	Build.cyl(m, cf * CFrame.new(0, 10.4, 0), 0.3, 4.2, rgb(90, 60, 40), M.Fabric, { collide = false })
	Build.cyl(m, cf * CFrame.new(0, 11.2, 0), 1.6, 2.4, rgb(90, 60, 40), M.Fabric, { collide = false })
	m.PrimaryPart = post
	Build.sway(post, 3, 3.5)
end

local function hay(folder: Folder, pos: Vector3, rng: Random)
	local cf = CFrame.new(pos + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	local b = Build.cyl(folder, cf * CFrame.Angles(0, 0, math.pi / 2), 5, 4.4, rgb(232, 196, 90), M.Fabric)
	Build.cyl(folder, cf * CFrame.Angles(0, 0, math.pi / 2), 5.1, 1.4, rgb(200, 160, 60), M.Fabric, { collide = false })
	return b
end

local function pumpkinPatch(folder: Folder, cx: number, cz: number, rng: Random)
	local placed = 0
	for _ = 1, 90 do
		local x = cx + rng:NextNumber(-40, 40)
		local z = cz + rng:NextNumber(-40, 40)
		local pos, normal, mat = Build.ground(x, z)
		if pos and normal.Y > 0.9 and (mat == M.Grass or mat == M.LeafyGrass or mat == M.Ground) then
			local s = rng:NextNumber(2.4, 4.2)
			local p = Build.ball(folder, CFrame.new(pos + Vector3.new(0, s * 0.35, 0)), s, rgb(255, rng:NextInteger(110, 150), 30), M.SmoothPlastic, { collide = false })
			p.Size = Vector3.new(s, s * 0.8, s)
			Build.block(folder, CFrame.new(pos + Vector3.new(0, s * 0.85, 0)), Vector3.new(0.4, 0.8, 0.4), rgb(70, 130, 60), M.Wood, { collide = false })
			placed += 1
		end
	end
	Nature.reserve(cx, cz, 44)
end

local function dock(folder: Folder)
	-- pequeno deque sobre a lagoa
	local lx, lz = -560, -170
	local y = Config.World.SeaLevel + 13.4
	for i = 0, 8 do
		Build.block(folder, CFrame.new(lx + 46 - i * 5, y, lz), Vector3.new(5, 0.6, 7), rgb(170, 122, 84), M.WoodPlanks)
	end
	for i = 0, 4 do
		for _, sz in { -3.4, 3.4 } do
			Build.cyl(folder, CFrame.new(lx + 46 - i * 10, y - 3, lz + sz), 7, 0.8, rgb(120, 84, 56), M.Wood)
		end
	end
end

function Farm.build(rng: Random, addSlot)
	local folder = Build.folder("Farm")
	local c = Config.Biomes.Farm.center

	barn(folder, c.X - 10, c.Y + 34)
	silo(folder, c.X + 22, c.Y + 34)
	windmill(folder, c.X + 60, c.Y - 40)
	tractor(folder, c.X + 40, c.Y + 62)
	pen(folder, c.X - 70, c.Y + 10, 44, 34)
	pen(folder, c.X - 60, c.Y - 60, 38, 30)
	for i = 1, 6 do
		animal(folder, Vector3.new(c.X - 70 + rng:NextNumber(-14, 14), Build.y(c.X - 70, c.Y + 10), c.Y + 10 + rng:NextNumber(-10, 10)), i % 2 == 0 and "pig" or "cow", rng)
	end
	for i = 1, 5 do
		animal(folder, Vector3.new(c.X - 60 + rng:NextNumber(-11, 11), Build.y(c.X - 60, c.Y - 60), c.Y - 60 + rng:NextNumber(-9, 9)), "pig", rng)
	end
	pumpkinPatch(folder, c.X + 20, c.Y - 110, rng)
	pumpkinPatch(folder, c.X - 100, c.Y + 90, rng)
	dock(folder)

	for i = 1, 8 do
		local x, z = c.X + rng:NextNumber(-150, 150), c.Y + rng:NextNumber(-150, 150)
		local pos = Build.ground(x, z)
		if pos then
			scarecrow(folder, pos, rng)
		end
	end
	-- pilha de feno (torre)
	local hx, hz = c.X + 90, c.Y + 30
	local hy = Build.y(hx, hz)
	for row = 0, 3 do
		for col = 0, 3 - row do
			hay(folder, Vector3.new(hx + col * 5.2 + row * 2.6, hy + row * 4.2, hz), rng)
		end
	end
	Nature.reserve(hx + 8, hz, 16)

	-- arvores e pedras
	Nature.scatter(folder, rng, 120, {
		center = c,
		radius = 230,
		materials = Nature.GRASS,
		kinds = { { "oak", 5 }, { "round", 3 } },
		scale = { 0.9, 1.7 },
		clearance = 4,
	})
	Nature.rocks(folder, rng, 24, { center = c, radius = 230, materials = Nature.GRASS, clearance = 3 })

	-- brinquedos espalhados
	for _ = 1, 26 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * 210
		local x, z = c.X + math.cos(a) * r, c.Y + math.sin(a) * r
		local pos = Build.ground(x, z)
		if pos and pos.Y > 4 then
			addSlot(pos, "Farm")
		end
	end
	_ = P
end

return Farm
