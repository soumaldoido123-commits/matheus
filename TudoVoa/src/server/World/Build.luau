--!nonstrict
--[[
	Build: ferramentas para montar o cenario com pecas (estilo "mundo de brinquedo":
	formas grossas, cores fortes). Tudo ancorado e dentro de workspace.TV_World.
	Animacoes de cenario sao feitas no CLIENTE por tags (Spin, Bob, Sway, Pulse).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local WorldGen = require(script.Parent:WaitForChild("WorldGen"))

local Build = {}

local Tags = Config.Tags
local rootFolder: Folder
local subFolders = {}
local groundParams: RaycastParams

function Build.init()
	rootFolder = workspace:FindFirstChild("TV_World")
	if rootFolder then
		rootFolder:Destroy()
	end
	rootFolder = Instance.new("Folder")
	rootFolder.Name = "TV_World"
	rootFolder.Parent = workspace

	groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances = { workspace.Terrain }
	groundParams.IgnoreWater = false
end

function Build.folder(name: string): Folder
	local f = subFolders[name]
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = rootFolder
		subFolders[name] = f
	end
	return f
end

-- Chao ---------------------------------------------------------------------------------------------------

-- Retorna posicao, normal e material do terreno em (x, z). nil se nao acha (ou e agua).
function Build.ground(x: number, z: number, allowWater: boolean?)
	local hit = workspace:Raycast(Vector3.new(x, 700, z), Vector3.new(0, -900, 0), groundParams)
	if not hit then
		return nil
	end
	if hit.Material == Enum.Material.Water and not allowWater then
		return nil
	end
	return hit.Position, hit.Normal, hit.Material
end

-- Raycast para baixo a partir de qualquer ponto (util dentro de cavernas)
function Build.groundFrom(origin: Vector3, dist: number)
	local hit = workspace:Raycast(origin, Vector3.new(0, -dist, 0), groundParams)
	if hit then
		return hit.Position, hit.Normal, hit.Material
	end
	return nil
end

-- Altura do chao (raycast; se falhar usa a funcao de altura)
function Build.y(x: number, z: number): number
	local p = Build.ground(x, z, true)
	if p then
		return p.Y
	end
	return WorldGen.height(x, z)
end

-- Pecas -------------------------------------------------------------------------------------------------------

export type Opts = {
	name: string?,
	transparency: number?,
	reflectance: number?,
	collide: boolean?,
	shadow: boolean?,
	anchored: boolean?,
	query: boolean?,
}

local function finish(p: BasePart, parent: Instance, opts: Opts?)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts then
		if opts.name then
			p.Name = opts.name
		end
		if opts.transparency then
			p.Transparency = opts.transparency
		end
		if opts.reflectance then
			p.Reflectance = opts.reflectance
		end
		if opts.collide == false then
			p.CanCollide = false
		end
		if opts.shadow == false then
			p.CastShadow = false
		end
		if opts.anchored == false then
			p.Anchored = false
		end
		if opts.query == false then
			p.CanQuery = false
		end
	end
	p.Parent = parent
	return p
end

function Build.block(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: any, opts: Opts?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	return finish(p, parent, opts)
end

-- cilindro com o eixo ao longo do Y local de cf
function Build.cyl(parent: Instance, cf: CFrame, height: number, diameter: number, color: Color3, material: any, opts: Opts?): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	return finish(p, parent, opts)
end

function Build.ball(parent: Instance, cf: CFrame, diameter: number, color: Color3, material: any, opts: Opts?): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * diameter
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	return finish(p, parent, opts)
end

function Build.wedge(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: any, opts: Opts?): WedgePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	return finish(p, parent, opts)
end

function Build.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Build.tag(inst: Instance, tag: string, attrs: { [string]: any }?)
	CollectionService:AddTag(inst, tag)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, v)
		end
	end
end

-- gira ao redor do eixo local ("X"|"Y"|"Z") em graus/s (animado no cliente)
function Build.spin(inst: Instance, axis: string, degPerSec: number)
	Build.tag(inst, Tags.Spin, { SpinAxis = axis, SpinSpeed = degPerSec })
end

-- flutua para cima e para baixo (amplitude em studs, periodo em s)
function Build.bob(inst: Instance, amp: number, period: number, phase: number?)
	Build.tag(inst, Tags.Bob, { BobAmp = amp, BobPeriod = period, BobPhase = phase or math.random() * 6.28 })
end

function Build.sway(inst: Instance, deg: number, period: number)
	Build.tag(inst, Tags.Sway, { SwayDeg = deg, SwayPeriod = period, SwayPhase = math.random() * 6.28 })
end

function Build.pulse(inst: Instance, minB: number, maxB: number, period: number)
	Build.tag(inst, Tags.Pulse, { PulseMin = minB, PulseMax = maxB, PulsePeriod = period })
end

function Build.light(parent: Instance, color: Color3, brightness: number, range: number, shadows: boolean?): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = shadows == true
	l.Parent = parent
	return l
end

-- Texto num painel (SurfaceGui). face padrao: Front
function Build.label(part: BasePart, text: string, opts: { [string]: any }?)
	opts = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Name = opts.name or "Label"
	gui.Face = opts.face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.ppu or 50
	gui.LightInfluence = opts.lightInfluence or 0
	gui.Brightness = opts.brightness or 1.2
	gui.AlwaysOnTop = false
	gui.Parent = part
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = opts.font or Enum.Font.FredokaOne
	t.Text = text
	t.TextColor3 = opts.color or Color3.new(1, 1, 1)
	t.TextScaled = true
	t.RichText = true
	if opts.stroke ~= false then
		t.TextStrokeTransparency = 0.35
		t.TextStrokeColor3 = opts.strokeColor or Color3.fromRGB(20, 20, 40)
	end
	t.Parent = gui
	return t
end

-- Balao de texto flutuante (BillboardGui)
function Build.billboard(part: BasePart, text: string, opts: { [string]: any }?)
	opts = opts or {}
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = opts.size or UDim2.fromOffset(240, 60)
	gui.StudsOffset = opts.offset or Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = opts.maxDistance or 220
	gui.LightInfluence = 0
	gui.Parent = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.Text = text
	t.TextColor3 = opts.color or Color3.new(1, 1, 1)
	t.TextScaled = true
	t.TextStrokeTransparency = 0.3
	t.TextStrokeColor3 = Color3.fromRGB(20, 20, 40)
	t.Parent = gui
	return t
end

-- Base enterrada: evita que construcoes fiquem "voando" em terreno irregular
function Build.foundation(parent: Instance, cf: CFrame, size: Vector3, color: Color3?, material: any)
	local depth = 14
	return Build.block(
		parent,
		cf * CFrame.new(0, -depth / 2 + 0.5, 0),
		Vector3.new(size.X, depth + size.Y, size.Z),
		color or Color3.fromRGB(150, 140, 150),
		material or Enum.Material.Concrete
	)
end

-- Prompt de interacao (tecla E). action: nome lido pelo cliente/servidor
function Build.prompt(part: BasePart, actionText: string, objectText: string, id: string, holdTime: number?): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = actionText
	pp.ObjectText = objectText
	pp.HoldDuration = holdTime or 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.E
	pp.Style = Enum.ProximityPromptStyle.Default
	pp:SetAttribute("Id", id)
	pp.Parent = part
	CollectionService:AddTag(pp, "TV_Prompt")
	return pp
end

-- Natureza ------------------------------------------------------------------------------------------------------------

local function jitter(c: Color3, rng: Random, amt: number): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV((h + rng:NextNumber(-amt, amt) * 0.15) % 1, s, math.clamp(v + rng:NextNumber(-amt, amt), 0, 1))
end

-- kind: "oak" | "round" | "pine" | "snowpine" | "palm" | "cactus" | "mushroom"
function Build.tree(parent: Instance, pos: Vector3, kind: string, scale: number, rng: Random, tilt: Vector3?)
	local m = Build.model(parent, "Tree_" .. kind)
	local s = scale
	local yaw = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local trunkColor = Color3.fromRGB(122, 84, 52)
	local rootPart

	if kind == "oak" or kind == "round" then
		local h = 9 * s
		rootPart = Build.cyl(m, yaw * CFrame.new(0, h / 2 - 1, 0), h, 2.2 * s, trunkColor, Enum.Material.Wood)
		local leaf = jitter(Color3.fromRGB(70, 200, 90), rng, 0.1)
		local top = yaw * CFrame.new(0, h + 2.2 * s, 0)
		local b = Build.ball(m, top, 10 * s, leaf, Enum.Material.Grass, { collide = false })
		Build.ball(m, top * CFrame.new(3.2 * s, -1.6 * s, 1 * s), 6.5 * s, jitter(leaf, rng, 0.06), Enum.Material.Grass, { collide = false })
		Build.ball(m, top * CFrame.new(-3 * s, -1.2 * s, -1.6 * s), 6 * s, jitter(leaf, rng, 0.06), Enum.Material.Grass, { collide = false })
		Build.sway(b, 1.6, 4 + rng:NextNumber(0, 2))
	elseif kind == "pine" or kind == "snowpine" then
		local h = 6 * s
		rootPart = Build.cyl(m, yaw * CFrame.new(0, h / 2 - 1, 0), h, 1.8 * s, trunkColor, Enum.Material.Wood)
		local leaf = kind == "snowpine" and Color3.fromRGB(56, 128, 96) or jitter(Color3.fromRGB(46, 150, 84), rng, 0.08)
		local tiers = { { 13, 4 }, { 10, 4 }, { 7, 3.5 }, { 4, 3 } }
		local y = h - 1
		for i, t in tiers do
			local c = leaf
			if kind == "snowpine" and i % 2 == 0 then
				c = Color3.fromRGB(240, 248, 255)
			end
			Build.cyl(m, yaw * CFrame.new(0, y + t[2] / 2, 0), t[2] * s, t[1] * s, c, kind == "snowpine" and (i % 2 == 0 and Enum.Material.Snow or Enum.Material.Grass) or Enum.Material.Grass, { collide = false })
			y += t[2] * 0.72 * s
		end
		Build.ball(m, yaw * CFrame.new(0, y + 1.2 * s, 0), 2.4 * s, kind == "snowpine" and Color3.fromRGB(240, 248, 255) or leaf, Enum.Material.SmoothPlastic, { collide = false })
	elseif kind == "palm" then
		local segs = 5
		local cf = yaw
		local lean = tilt or Vector3.new(0.12, 0, 0.05)
		rootPart = nil
		for i = 1, segs do
			local seg = Build.cyl(m, cf * CFrame.new(0, 1.9 * s, 0), 3.8 * s, (2.0 - i * 0.12) * s, Color3.fromRGB(176, 128, 82), Enum.Material.Wood)
			if not rootPart then
				rootPart = seg
			end
			cf = cf * CFrame.new(0, 3.6 * s, 0) * CFrame.Angles(lean.X, lean.Y, lean.Z)
		end
		local crown = cf * CFrame.new(0, 1 * s, 0)
		for i = 0, 6 do
			local a = i / 7 * math.pi * 2
			local frond = Build.wedge(
				m,
				crown * CFrame.Angles(0, a, math.rad(-28)) * CFrame.new(0, 0, -5 * s),
				Vector3.new(1.2 * s, 0.35, 8 * s),
				Color3.fromRGB(60, 190, 90),
				Enum.Material.Grass,
				{ collide = false }
			)
			if i == 0 then
				Build.sway(frond, 2, 3.4)
			end
		end
		Build.ball(m, crown, 2 * s, Color3.fromRGB(120, 84, 50), Enum.Material.Wood, { collide = false })
		Build.ball(m, crown * CFrame.new(1.1 * s, -0.8 * s, 0), 1.3 * s, Color3.fromRGB(110, 76, 44), Enum.Material.Wood, { collide = false })
	elseif kind == "cactus" then
		local h = 8 * s
		rootPart = Build.cyl(m, yaw * CFrame.new(0, h / 2 - 0.5, 0), h, 2.6 * s, Color3.fromRGB(86, 176, 96), Enum.Material.SmoothPlastic)
		Build.ball(m, yaw * CFrame.new(0, h - 0.5, 0), 2.6 * s, Color3.fromRGB(86, 176, 96), Enum.Material.SmoothPlastic)
		Build.cyl(m, yaw * CFrame.new(2.2 * s, h * 0.55, 0), 3.6 * s, 1.7 * s, Color3.fromRGB(86, 176, 96), Enum.Material.SmoothPlastic, { collide = false })
		Build.cyl(m, yaw * CFrame.new(1.2 * s, h * 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), 2.4 * s, 1.7 * s, Color3.fromRGB(86, 176, 96), Enum.Material.SmoothPlastic, { collide = false })
		Build.ball(m, yaw * CFrame.new(-0.4 * s, h * 0.9, 1.4 * s), 0.9 * s, Color3.fromRGB(255, 120, 190), Enum.Material.Neon, { collide = false })
	elseif kind == "mushroom" then
		local h = 5 * s
		rootPart = Build.cyl(m, yaw * CFrame.new(0, h / 2 - 0.5, 0), h, 2.4 * s, Color3.fromRGB(245, 240, 225), Enum.Material.SmoothPlastic)
		local cap = Build.ball(m, yaw * CFrame.new(0, h + 0.4 * s, 0), 9 * s, Color3.fromRGB(255, 70, 110), Enum.Material.SmoothPlastic, { collide = false })
		cap.Size = Vector3.new(9 * s, 5.5 * s, 9 * s)
		for i = 1, 5 do
			local a = i * 1.2566
			Build.ball(m, yaw * CFrame.new(math.cos(a) * 2.6 * s, h + 2.4 * s, math.sin(a) * 2.6 * s), 1.3 * s, Color3.fromRGB(255, 250, 240), Enum.Material.SmoothPlastic, { collide = false })
		end
	end
	if rootPart then
		m.PrimaryPart = rootPart
	end
	return m
end

function Build.rock(parent: Instance, pos: Vector3, size: number, color: Color3?, rng: Random)
	local c = color or Color3.fromRGB(128, 122, 140)
	local m = Build.model(parent, "Rock")
	local main = Build.block(m, CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3)), Vector3.new(size, size * 0.75, size * 0.9), jitter(c, rng, 0.05), Enum.Material.Slate)
	Build.block(m, main.CFrame * CFrame.new(size * 0.35, -size * 0.1, size * 0.15) * CFrame.Angles(0.3, 0.7, 0.2), Vector3.new(size * 0.6, size * 0.5, size * 0.55), jitter(c, rng, 0.05), Enum.Material.Slate)
	m.PrimaryPart = main
	return m
end

function Build.lamp(parent: Instance, pos: Vector3, height: number?, color: Color3?)
	local h = height or 12
	local m = Build.model(parent, "Lamp")
	local c = color or Color3.fromRGB(255, 226, 150)
	Build.cyl(m, CFrame.new(pos + Vector3.new(0, h / 2, 0)), h, 0.7, Color3.fromRGB(50, 54, 78), Enum.Material.Metal)
	Build.block(m, CFrame.new(pos + Vector3.new(0, h + 0.4, 0)), Vector3.new(1.6, 0.6, 1.6), Color3.fromRGB(50, 54, 78), Enum.Material.Metal)
	local bulb = Build.ball(m, CFrame.new(pos + Vector3.new(0, h + 1.5, 0)), 2.2, c, Enum.Material.Neon, { collide = false })
	Build.light(bulb, c, 1.4, 26, false)
	CollectionService:AddTag(bulb, "TV_Lamp")
	return m
end

-- Casa simples: paredes + telhado de dois planos + porta + janelas
function Build.house(parent: Instance, cf: CFrame, size: Vector3, wall: Color3, roof: Color3, name: string?)
	local m = Build.model(parent, name or "House")
	Build.foundation(m, cf, Vector3.new(size.X + 1, 1, size.Z + 1))
	local body = Build.block(m, cf * CFrame.new(0, size.Y / 2 + 0.5, 0), size, wall, Enum.Material.SmoothPlastic)
	local roofH = size.X * 0.32
	local roofLen = size.Z + 2
	for _, sgn in { -1, 1 } do
		Build.block(
			m,
			cf * CFrame.new(sgn * size.X * 0.27, size.Y + 0.5 + roofH * 0.5, 0) * CFrame.Angles(0, 0, -sgn * math.rad(32)),
			Vector3.new(size.X * 0.66, 1, roofLen),
			roof,
			Enum.Material.SmoothPlastic
		)
	end
	Build.block(m, cf * CFrame.new(0, size.Y * 0.4 + 0.5, size.Z / 2 + 0.05), Vector3.new(size.X * 0.22, size.Y * 0.7, 0.3), Color3.fromRGB(100, 66, 44), Enum.Material.Wood)
	for _, sx in { -1, 1 } do
		local w = Build.block(m, cf * CFrame.new(sx * size.X * 0.3, size.Y * 0.6 + 0.5, size.Z / 2 + 0.05), Vector3.new(size.X * 0.16, size.Y * 0.28, 0.3), Color3.fromRGB(180, 230, 255), Enum.Material.Glass)
		w.Reflectance = 0.2
	end
	m.PrimaryPart = body
	return m
end

return Build
