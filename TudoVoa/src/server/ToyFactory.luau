--!nonstrict
--[[
	ToyFactory: constroi os modelos dos brinquedos a partir do catalogo (shared/Toys).
	Cada brinquedo e um Model com uma parte "Body" (raiz da montagem, PrimaryPart).
	As demais partes sao decoracao soldada (sem colisao e sem massa, exceto brinquedos pesados).

	Convencao de frente: para brinquedos que voam "para frente" (aviao, peixe, bumerangue)
	a frente e -Z (LookVector). Foguete e dinamite tem eixo X: atributo AlignYaw = 90.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Toys = require(Shared:WaitForChild("Toys"))

local ToyFactory = {}

local GRAVITY = 196.2

local function v3(x, y, z)
	return Vector3.new(x, y, z)
end

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function newPart(name: string, size: Vector3, color: Color3, material: any, shape: any?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.Shape = shape or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	return p
end

-- Decoracao soldada ao corpo. keepMass = conta na massa/colisao (brinquedos pesados).
local function decor(model: Model, body: BasePart, offset: CFrame, p: BasePart, keepMass: boolean?)
	p.CFrame = body.CFrame * offset
	if keepMass then
		p.CanCollide = true
		p.Massless = false
		p.CustomPhysicalProperties = body.CustomPhysicalProperties
	else
		p.CanCollide = false
		p.Massless = true
	end
	p.CanTouch = false
	p.Anchored = false
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = body
	w.Part1 = p
	w.Parent = p
	return p
end

local function ball(model, body, offset, diameter, color, material, keepMass)
	local p = newPart("Deco", v3(diameter, diameter, diameter), color, material or Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	return decor(model, body, offset, p, keepMass)
end

local function block(model, body, offset, size, color, material, keepMass)
	local p = newPart("Deco", size, color, material or Enum.Material.SmoothPlastic)
	return decor(model, body, offset, p, keepMass)
end

local function cyl(model, body, offset, size, color, material, keepMass)
	local p = newPart("Deco", size, color, material or Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	return decor(model, body, offset, p, keepMass)
end

local function light(parent: Instance, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
	return l
end

-- Construtores especificos ----------------------------------------------------------------

local Builders = {}

function Builders.duck(model, body, toy)
	body.Shape = Enum.PartType.Ball
	body.Size = v3(3.2, 3.2, 3.2)
	ball(model, body, CFrame.new(0, 2.0, -0.9), 2.1, toy.color)
	block(model, body, CFrame.new(0, 1.85, -2.05), v3(1.1, 0.4, 1.0), rgb(255, 130, 30))
	ball(model, body, CFrame.new(-0.55, 2.5, -1.75), 0.38, rgb(20, 20, 20))
	ball(model, body, CFrame.new(0.55, 2.5, -1.75), 0.38, rgb(20, 20, 20))
	block(model, body, CFrame.new(0, 0.6, 1.65) * CFrame.Angles(math.rad(-30), 0, 0), v3(1.4, 0.5, 1.2), toy.color)
end

function Builders.balloon(model, body, toy)
	body.Shape = Enum.PartType.Ball
	body.Size = v3(5, 5, 5)
	body.Reflectance = 0.2
	ball(model, body, CFrame.new(0, -2.7, 0), 0.7, toy.color)
	block(model, body, CFrame.new(0, -5.1, 0), v3(0.12, 4.4, 0.12), rgb(240, 240, 240), Enum.Material.Fabric)
	local shine = ball(model, body, CFrame.new(-1.1, 1.3, -1.4), 0.9, rgb(255, 255, 255), Enum.Material.Neon)
	shine.Transparency = 0.6
end

function Builders.plane(model, body, toy)
	body.Size = v3(0.6, 0.6, 4.6)
	block(model, body, CFrame.new(0, 0, 0.4), v3(7, 0.12, 1.9), rgb(120, 190, 255))
	block(model, body, CFrame.new(0, 0.8, 2.0), v3(0.12, 1.3, 1.1), rgb(255, 90, 90))
	block(model, body, CFrame.new(0, 0.1, 2.1), v3(2.6, 0.1, 0.8), rgb(120, 190, 255))
	ball(model, body, CFrame.new(0, 0, -2.4), 0.75, rgb(255, 90, 90))
end

function Builders.fish(model, body, toy)
	body.Size = v3(1.6, 2.4, 5)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	block(model, body, CFrame.new(0, 0, 3.0), v3(0.25, 2.6, 1.6), rgb(255, 140, 60))
	block(model, body, CFrame.new(0, 1.6, 0.2), v3(0.2, 1.1, 1.8), rgb(255, 140, 60))
	ball(model, body, CFrame.new(-0.7, 0.45, -1.7), 0.5, rgb(255, 255, 255))
	ball(model, body, CFrame.new(0.7, 0.45, -1.7), 0.5, rgb(255, 255, 255))
	ball(model, body, CFrame.new(-0.85, 0.45, -1.85), 0.25, rgb(10, 10, 10))
	ball(model, body, CFrame.new(0.85, 0.45, -1.85), 0.25, rgb(10, 10, 10))
end

function Builders.pizza(model, body, toy)
	-- eixo X = para cima (PivotOffset). Coberturas na face +X.
	local spots = {
		v3(0.3, 0.0, 0.0), v3(0.3, 1.3, 0.6), v3(0.3, -1.2, 0.9), v3(0.3, 0.5, -1.4), v3(0.3, -0.9, -1.1), v3(0.3, 1.5, -0.9),
	}
	for _, s in spots do
		cyl(model, body, CFrame.new(s), v3(0.14, 0.95, 0.95), rgb(200, 50, 50))
	end
	cyl(model, body, CFrame.new(0.26, 0, 0), v3(0.1, 4.2, 4.2), rgb(255, 120, 60))
end

function Builders.anvil(model, body, toy)
	body.Size = v3(1.6, 1.4, 3)
	block(model, body, CFrame.new(0, -1.1, 0), v3(3, 0.8, 4.6), toy.color, Enum.Material.Metal, true)
	block(model, body, CFrame.new(0, 1.2, 0), v3(2.6, 1.0, 5), rgb(75, 78, 92), Enum.Material.Metal, true)
	block(model, body, CFrame.new(0, 1.2, -3.0), v3(1.6, 0.9, 1.3), rgb(75, 78, 92), Enum.Material.Metal, true)
end

function Builders.sofa(model, body, toy)
	body.Size = v3(7, 1.4, 3)
	block(model, body, CFrame.new(0, 1.8, -1.1), v3(7, 2.2, 0.8), toy.color, Enum.Material.Fabric, true)
	block(model, body, CFrame.new(-3.05, 0.9, 0), v3(0.9, 2, 3), toy.color, Enum.Material.Fabric, true)
	block(model, body, CFrame.new(3.05, 0.9, 0), v3(0.9, 2, 3), toy.color, Enum.Material.Fabric, true)
	block(model, body, CFrame.new(-1.6, 1.0, 0.2), v3(3.0, 0.6, 2.5), rgb(190, 110, 230), Enum.Material.Fabric)
	block(model, body, CFrame.new(1.6, 1.0, 0.2), v3(3.0, 0.6, 2.5), rgb(190, 110, 230), Enum.Material.Fabric)
	for _, x in { -3.0, 3.0 } do
		for _, z in { -1.1, 1.1 } do
			block(model, body, CFrame.new(x, -1.0, z), v3(0.5, 0.7, 0.5), rgb(70, 45, 30), Enum.Material.WoodPlanks)
		end
	end
end

function Builders.rocket(model, body, toy)
	body.Size = v3(5.6, 2, 2)
	ball(model, body, CFrame.new(2.8, 0, 0), 2, rgb(235, 60, 60), Enum.Material.SmoothPlastic)
	for i = 0, 2 do
		local ang = i * (2 * math.pi / 3)
		block(model, body, CFrame.Angles(ang, 0, 0) * CFrame.new(-2.2, 1.45, 0), v3(1.3, 1.9, 0.18), rgb(235, 60, 60))
	end
	local window = ball(model, body, CFrame.new(0.9, 0.95, 0), 0.9, rgb(90, 225, 255), Enum.Material.Neon)
	window.Transparency = 0.15
	local att = Instance.new("Attachment")
	att.Name = "Exhaust"
	att.CFrame = CFrame.new(-3.0, 0, 0)
	att.Parent = body
	local flame = Instance.new("ParticleEmitter")
	flame.Name = "Flame"
	flame.Enabled = false
	flame.Rate = 90
	flame.Lifetime = NumberRange.new(0.25, 0.5)
	flame.Speed = NumberRange.new(10, 18)
	flame.EmissionDirection = Enum.NormalId.Left
	flame.SpreadAngle = Vector2.new(8, 8)
	flame.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0.1) })
	flame.Color = ColorSequence.new(rgb(255, 230, 120), rgb(255, 80, 20))
	flame.LightEmission = 1
	flame.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	flame.Parent = att
	body:SetAttribute("AlignYaw", 90)
end

function Builders.boomerang(model, body, toy)
	body.Size = v3(1.2, 0.4, 1.2)
	local phi = math.rad(40)
	for _, sgn in { -1, 1 } do
		local dir = v3(sgn * math.sin(phi), 0, math.cos(phi))
		local center = dir * 2.3
		local off = CFrame.lookAt(center, center + dir) * CFrame.Angles(0, math.pi / 2, 0)
		block(model, body, off, v3(4.8, 0.4, 1.1), toy.color, Enum.Material.WoodPlanks, true)
		local stripe = block(model, body, off * CFrame.new(0.4, 0.21, 0), v3(1.0, 0.05, 1.12), rgb(255, 255, 255))
		stripe.Material = Enum.Material.SmoothPlastic
	end
end

function Builders.dynamite(model, body, toy)
	body.Size = v3(4, 1.4, 1.4)
	cyl(model, body, CFrame.new(0, -1.25, 0.72), v3(4, 1.4, 1.4), toy.color)
	cyl(model, body, CFrame.new(0, -1.25, -0.72), v3(4, 1.4, 1.4), toy.color)
	cyl(model, body, CFrame.new(0, -0.5, 0), v3(1.0, 3.3, 3.3), rgb(30, 30, 30), Enum.Material.Fabric)
	cyl(model, body, CFrame.new(2.6, 0.3, 0) * CFrame.Angles(0, 0, math.rad(15)), v3(1.2, 0.2, 0.2), rgb(40, 40, 40))
	local att = Instance.new("Attachment")
	att.Name = "FuseTip"
	att.CFrame = CFrame.new(3.3, 0.6, 0)
	att.Parent = body
	local spark = Instance.new("ParticleEmitter")
	spark.Name = "Spark"
	spark.Enabled = false
	spark.Rate = 60
	spark.Lifetime = NumberRange.new(0.3, 0.6)
	spark.Speed = NumberRange.new(4, 10)
	spark.SpreadAngle = Vector2.new(90, 90)
	spark.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	spark.Color = ColorSequence.new(rgb(255, 240, 150), rgb(255, 120, 30))
	spark.LightEmission = 1
	spark.Parent = att
	body:SetAttribute("AlignYaw", 90)
end

function Builders.trampoline(model, body, toy)
	body.Size = v3(1.2, 9, 9)
	body.Color = rgb(35, 38, 50)
	local pad = cyl(model, body, CFrame.new(0.8, 0, 0), v3(0.35, 8.4, 8.4), toy.color)
	pad.Name = "Pad"
	pad.CanCollide = true
	pad.CanTouch = true
	pad.Material = Enum.Material.Fabric
	cyl(model, body, CFrame.new(0.5, 0, 0), v3(0.5, 9.3, 9.3), rgb(255, 120, 60))
	for _, s in { v3(-1.1, 3.6, 0), v3(-1.1, -3.6, 0), v3(-1.1, 0, 3.6), v3(-1.1, 0, -3.6) } do
		block(model, body, CFrame.new(s), v3(1.0, 0.6, 0.6), rgb(35, 38, 50))
	end
end

function Builders.pinata(model, body, toy)
	body.Size = v3(4, 3.4, 5)
	for i, x in { -1.4, 0, 1.4 } do
		local c = (i % 2 == 1) and rgb(255, 220, 60) or rgb(70, 220, 255)
		block(model, body, CFrame.new(x, 0, 0), v3(0.55, 3.5, 5.1), c, Enum.Material.Fabric)
	end
	block(model, body, CFrame.new(0, 1.6, -3.2), v3(2, 2.2, 2.4), toy.color, Enum.Material.Fabric)
	block(model, body, CFrame.new(-0.95, 3.1, -2.6), v3(0.6, 1.3, 0.6), toy.color, Enum.Material.Fabric)
	block(model, body, CFrame.new(0.95, 3.1, -2.6), v3(0.6, 1.3, 0.6), toy.color, Enum.Material.Fabric)
	ball(model, body, CFrame.new(-0.6, 2.2, -4.35), 0.5, rgb(15, 15, 15))
	ball(model, body, CFrame.new(0.6, 2.2, -4.35), 0.5, rgb(15, 15, 15))
	for _, x in { -1.3, 1.3 } do
		for _, z in { -1.7, 1.7 } do
			block(model, body, CFrame.new(x, -2.4, z), v3(0.8, 1.5, 0.8), toy.color, Enum.Material.Fabric)
		end
	end
end

function Builders.magnet(model, body, toy)
	body.Size = v3(5, 1.4, 1.8)
	for _, sgn in { -1, 1 } do
		block(model, body, CFrame.new(sgn * 1.8, -2.4, 0), v3(1.4, 3.4, 1.8), toy.color, Enum.Material.Metal, true)
		block(model, body, CFrame.new(sgn * 1.8, -4.6, 0), v3(1.4, 1.0, 1.8), rgb(215, 220, 230), Enum.Material.Metal, true)
	end
end

function Builders.piano(model, body, toy)
	body.Size = v3(6, 2.2, 7)
	block(model, body, CFrame.new(0, 1.25, -1), v3(6, 0.3, 4.6), rgb(20, 20, 26), nil, true)
	block(model, body, CFrame.new(0, 0.6, 4.1), v3(5.4, 0.25, 1.6), rgb(245, 245, 245), nil, true)
	block(model, body, CFrame.new(0, 0.78, 4.35), v3(5.4, 0.1, 0.8), rgb(20, 20, 20))
	block(model, body, CFrame.new(0, 1.9, 2.4) * CFrame.Angles(math.rad(-20), 0, 0), v3(3, 1.4, 0.15), rgb(30, 30, 38))
	for _, p in { v3(-2.6, -2.3, 3.0), v3(2.6, -2.3, 3.0), v3(0, -2.3, -3.0) } do
		block(model, body, CFrame.new(p), v3(0.6, 2.4, 0.6), rgb(30, 30, 38), nil, true)
	end
end

function Builders.crystal(model, body, toy)
	body.Size = v3(1.6, 4.4, 1.6)
	body.Transparency = 0.2
	local b = block(model, body, CFrame.new(1.0, -0.8, 0.3) * CFrame.Angles(math.rad(10), math.rad(20), math.rad(-28)), v3(1.1, 3.2, 1.1), toy.color, Enum.Material.Neon)
	b.Transparency = 0.25
	local c = block(model, body, CFrame.new(-0.9, -1.0, -0.2) * CFrame.Angles(math.rad(-12), math.rad(60), math.rad(24)), v3(0.9, 2.6, 0.9), toy.color, Enum.Material.Neon)
	c.Transparency = 0.25
	light(body, toy.color, 1.6, 14)
end

function Builders.orb(model, body, toy)
	local shell = ball(model, body, CFrame.new(), 4.2, toy.color, Enum.Material.Glass)
	shell.Transparency = 0.7
	light(body, toy.color, 2, 16)
end

function Builders.barrel(model, body, toy)
	for _, x in { -1.2, 1.2 } do
		cyl(model, body, CFrame.new(x, 0, 0), v3(0.4, 3.35, 3.35), rgb(60, 60, 70), Enum.Material.Metal)
	end
	cyl(model, body, CFrame.new(2.02, 0, 0), v3(0.06, 2.6, 2.6), rgb(150, 55, 40), Enum.Material.Metal)
end

function Builders.crate(model, body, toy)
	for _, y in { -1.35, 1.35 } do
		block(model, body, CFrame.new(0, y, 0), v3(3.1, 0.3, 3.1), rgb(120, 82, 48), Enum.Material.WoodPlanks)
	end
	for _, x in { -1.35, 1.35 } do
		for _, z in { -1.35, 1.35 } do
			block(model, body, CFrame.new(x, 0, z), v3(0.32, 3.1, 0.32), rgb(120, 82, 48), Enum.Material.WoodPlanks)
		end
	end
end

function Builders.ballbands(model, body, toy)
	local d = body.Size.X + 0.06
	for i = 0, 1 do
		local band = cyl(model, body, CFrame.Angles(0, i * math.pi / 2, 0), v3(0.35, d, d), rgb(255, 255, 255))
		band.Material = Enum.Material.SmoothPlastic
	end
end

function Builders.bowling(model, body, toy)
	ball(model, body, CFrame.new(-0.35, 1.3, 0.3), 0.5, rgb(10, 10, 10))
	ball(model, body, CFrame.new(0.35, 1.3, 0.3), 0.5, rgb(10, 10, 10))
	ball(model, body, CFrame.new(0, 1.2, -0.4), 0.5, rgb(10, 10, 10))
end

function Builders.feather(model, body, toy)
	block(model, body, CFrame.new(0, 0, 0), v3(0.12, 7.2, 0.28), rgb(230, 215, 190))
	for i = -3, 3 do
		if i ~= 0 then
			local side = (i % 2 == 0) and 1 or -1
			block(model, body, CFrame.new(side * 0.9, i * 0.85, 0) * CFrame.Angles(0, 0, side * math.rad(-30)), v3(1.8, 0.35, 0.12), toy.color, Enum.Material.Fabric)
		end
	end
end

-- Mapeia id do brinquedo -> construtor extra (quando nao usa toy.build)
local EXTRA = {
	caixa = Builders.crate,
	barril = Builders.barrel,
	bola = Builders.ballbands,
	melancia = Builders.ballbands,
	boliche = Builders.bowling,
	pena = Builders.feather,
	orbe = Builders.orb,
}

-- Constroi o modelo (nao coloca no mundo) ------------------------------------------------

function ToyFactory.build(toyId: string): Model?
	local toy = Toys.ById[toyId]
	if not toy then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = "Toy_" .. toy.id

	local shape = Enum.PartType.Block
	if toy.shape == "Ball" then
		shape = Enum.PartType.Ball
	elseif toy.shape == "Cylinder" then
		shape = Enum.PartType.Cylinder
	end
	local material = Enum.Material[toy.material] or Enum.Material.SmoothPlastic
	local body = newPart("Body", toy.size, toy.color, material, shape)
	body.CustomPhysicalProperties = PhysicalProperties.new(
		toy.density,
		toy.friction,
		toy.elasticity,
		toy.friction < 0.1 and 100 or 1,
		toy.elasticity > 0.6 and 60 or 1
	)
	if toy.transparency then
		body.Transparency = toy.transparency
	end
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body

	if toy.shape == "Cylinder" then
		-- eixo do cilindro (X) fica na vertical quando o modelo e posicionado
		body.PivotOffset = CFrame.Angles(0, 0, -math.pi / 2)
	end

	local builder = toy.build and Builders[toy.build] or EXTRA[toy.id]
	if builder then
		builder(model, body, toy)
	end

	body:SetAttribute("ToyId", toy.id)
	body:SetAttribute("Behavior", toy.behavior)
	return model
end

-- Forcas continuas (flutuar / subir) dependem da massa real -> depois de estar no mundo
local function setupForces(model: Model, toy)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local mass = body.AssemblyMass
	body:SetAttribute("Mass", mass)
	local k = nil
	if toy.behavior == "float" then
		k = 0.86
	elseif toy.behavior == "balloon" then
		k = 1.22
	elseif toy.behavior == "squeak" then
		k = 0 -- so boia na agua (flutuabilidade nativa do terreno); sem forca extra
	end
	if k and k > 0 then
		local att = Instance.new("Attachment")
		att.Name = "LiftAtt"
		att.Parent = body
		local vf = Instance.new("VectorForce")
		vf.Name = "Lift"
		vf.Attachment0 = att
		vf.RelativeTo = Enum.ActuatorRelativeTo.World
		vf.ApplyAtCenterOfMass = true
		vf.Force = v3(0, mass * GRAVITY * k, 0)
		vf.Parent = body
		if toy.behavior == "balloon" then
			-- balao tambem sofre arrasto do ar: sem isso acelera para sempre
			local lv = Instance.new("LinearVelocity")
			lv.Name = "AirCap"
			lv.Attachment0 = att
			lv.RelativeTo = Enum.ActuatorRelativeTo.World
			lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			lv.VectorVelocity = v3(0, 0, 0)
			lv.MaxAxesForce = v3(mass * 6, 0, mass * 6)
			lv.Parent = body
			body:SetAttribute("Rises", true)
		end
	end
end

-- Cria e coloca no mundo -------------------------------------------------------------------

function ToyFactory.spawn(toyId: string, cf: CFrame, parent: Instance?, ownerUserId: number?): Model?
	local toy = Toys.ById[toyId]
	local model = ToyFactory.build(toyId)
	if not toy or not model then
		return nil
	end
	local body = model.PrimaryPart
	model:PivotTo(cf)
	model.Parent = parent or workspace
	setupForces(model, toy)
	CollectionService:AddTag(body, Config.Tags.Grabbable)
	CollectionService:AddTag(body, Config.Tags.Toy)
	if ownerUserId then
		body:SetAttribute("OwnerUserId", ownerUserId)
	end
	-- o servidor simula os brinquedos soltos (comportamentos consistentes para todos)
	pcall(function()
		body:SetNetworkOwner(nil)
	end)
	return model
end

function ToyFactory.getBody(inst: Instance): BasePart?
	if inst:IsA("Model") then
		return inst.PrimaryPart
	elseif inst:IsA("BasePart") then
		return inst
	end
	return nil
end

return ToyFactory
