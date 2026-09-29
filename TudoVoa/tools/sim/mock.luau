--[[
	Mock leve da API do Roblox, so para rodar a logica pura (mundo, dados, pontuacao)
	fora do Studio. NAO simula fisica. Usado por tools/sim/*.mjs.
]]

-- typeof que entende os tipos mock ------------------------------------------------------
local realTypeof = typeof
function typeof(v)
	local t = type(v)
	if t == "table" then
		local mt = getmetatable(v)
		if mt and mt.__type then
			return mt.__type
		end
		if rawget(v, "__isInstance") then
			return "Instance"
		end
	end
	return t
end

-- Perlin noise (Ken Perlin, improved) -------------------------------------------------------
local perm = {}
do
	local p = {}
	for i = 0, 255 do
		p[i] = i
	end
	local seed = 1234567
	local function rnd()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	for i = 255, 1, -1 do
		local j = math.floor(rnd() * (i + 1))
		p[i], p[j] = p[j], p[i]
	end
	for i = 0, 511 do
		perm[i] = p[i % 256]
	end
end
local function fade(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end
local function lerp(t, a, b)
	return a + t * (b - a)
end
local function grad(hash, x, y, z)
	local h = hash % 16
	local u = h < 8 and x or y
	local v = h < 4 and y or ((h == 12 or h == 14) and x or z)
	return ((h % 2 == 0) and u or -u) + (((h // 2) % 2 == 0) and v or -v)
end
function math.noise(x, y, z)
	y = y or 0
	z = z or 0
	local X = math.floor(x) % 256
	local Y = math.floor(y) % 256
	local Z = math.floor(z) % 256
	x -= math.floor(x)
	y -= math.floor(y)
	z -= math.floor(z)
	local u, v, w = fade(x), fade(y), fade(z)
	local A = perm[X] + Y
	local AA = perm[A] + Z
	local AB = perm[A + 1] + Z
	local B = perm[X + 1] + Y
	local BA = perm[B] + Z
	local BB = perm[B + 1] + Z
	return lerp(
		w,
		lerp(v, lerp(u, grad(perm[AA], x, y, z), grad(perm[BA], x - 1, y, z)), lerp(u, grad(perm[AB], x, y - 1, z), grad(perm[BB], x - 1, y - 1, z))),
		lerp(
			v,
			lerp(u, grad(perm[AA + 1], x, y, z - 1), grad(perm[BA + 1], x - 1, y, z - 1)),
			lerp(u, grad(perm[AB + 1], x, y - 1, z - 1), grad(perm[BB + 1], x - 1, y - 1, z - 1))
		)
	)
end

-- Vector3 / Vector2 -----------------------------------------------------------------------------
local V3 = { __type = "Vector3" }
V3.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	elseif k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then
			return Vector3.new(0, 0, 0)
		end
		return Vector3.new(t.X / m, t.Y / m, t.Z / m)
	elseif k == "Dot" then
		return function(_, o)
			return t.X * o.X + t.Y * o.Y + t.Z * o.Z
		end
	elseif k == "Cross" then
		return function(_, o)
			return Vector3.new(t.Y * o.Z - t.Z * o.Y, t.Z * o.X - t.X * o.Z, t.X * o.Y - t.Y * o.X)
		end
	elseif k == "Lerp" then
		return function(_, o, a)
			return Vector3.new(t.X + (o.X - t.X) * a, t.Y + (o.Y - t.Y) * a, t.Z + (o.Z - t.Z) * a)
		end
	end
	return rawget(V3, k)
end
V3.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return Vector3.new(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return Vector3.new(a.X * b, a.Y * b, a.Z * b)
	end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return Vector3.new(a.X / b, a.Y / b, a.Z / b)
	end
	return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a)
	return Vector3.new(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3.__tostring = function(a)
	return a.X .. ", " .. a.Y .. ", " .. a.Z
end
Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector3.xAxis = Vector3.new(1, 0, 0)
Vector3.yAxis = Vector3.new(0, 1, 0)
Vector3.zAxis = Vector3.new(0, 0, 1)

local V2 = { __type = "Vector2" }
V2.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y)
	end
	return rawget(V2, k)
end
V2.__add = function(a, b)
	return Vector2.new(a.X + b.X, a.Y + b.Y)
end
V2.__sub = function(a, b)
	return Vector2.new(a.X - b.X, a.Y - b.Y)
end
V2.__mul = function(a, b)
	if type(b) == "number" then
		return Vector2.new(a.X * b, a.Y * b)
	elseif type(a) == "number" then
		return Vector2.new(a * b.X, a * b.Y)
	end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
Vector2 = {}
function Vector2.new(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, V2)
end
Vector2.zero = Vector2.new(0, 0)

-- Color3 ---------------------------------------------------------------------------------------------
local C3 = { __type = "Color3" }
C3.__index = function(t, k)
	if k == "ToHSV" then
		return function()
			local r, g, b = t.R, t.G, t.B
			local mx, mn = math.max(r, g, b), math.min(r, g, b)
			local d = mx - mn
			local h = 0
			if d > 0 then
				if mx == r then
					h = ((g - b) / d) % 6
				elseif mx == g then
					h = (b - r) / d + 2
				else
					h = (r - g) / d + 4
				end
				h /= 6
			end
			return h, mx == 0 and 0 or d / mx, mx
		end
	elseif k == "Lerp" then
		return function(_, o, a)
			return Color3.new(t.R + (o.R - t.R) * a, t.G + (o.G - t.G) * a, t.B + (o.B - t.B) * a)
		end
	end
	return rawget(C3, k)
end
Color3 = {}
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end
function Color3.fromRGB(r, g, b)
	return Color3.new(r / 255, g / 255, b / 255)
end
function Color3.fromHSV(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	local r, g, b
	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end
	return Color3.new(r, g, b)
end

-- Enum: qualquer Enum.X.Y vira uma tabela { Name = "Y", EnumType = "X" } -----------------------------------------
local enumCache = {}
Enum = setmetatable({}, {
	__index = function(_, enumName)
		local e = enumCache[enumName]
		if not e then
			e = setmetatable({}, {
				__index = function(t, itemName)
					local item = setmetatable({ Name = itemName, EnumType = enumName }, { __type = "EnumItem", __tostring = function() return "Enum." .. enumName .. "." .. itemName end })
					rawset(t, itemName, item)
					return item
				end,
			})
			enumCache[enumName] = e
		end
		return e
	end,
})

-- Region3, Random, TweenInfo, etc. ---------------------------------------------------------------------------------------------
Region3 = { new = function(a, b) return { Min = a, Max = b } end }
Random = { new = function(seed)
	local r = {}
	local s = seed or 1
	local function nxt()
		s = (s * 1664525 + 1013904223) % 4294967296
		return s / 4294967296
	end
	function r:NextNumber(a, b)
		if a then
			return a + (b - a) * nxt()
		end
		return nxt()
	end
	function r:NextInteger(a, b)
		return a + math.floor(nxt() * (b - a + 1))
	end
	return r
end }
TweenInfo = { new = function(...) return { ... } end }
NumberRange = { new = function(a, b) return { Min = a, Max = b or a } end }
NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
NumberSequence = { new = function(a) return a end }
ColorSequence = { new = function(a, b) return { a, b } end }
UDim2 = { new = function(...) return { ... } end, fromScale = function(...) return { ... } end, fromOffset = function(...) return { ... } end }
UDim = { new = function(...) return { ... } end }
PhysicalProperties = { new = function(...) return { ... } end }
RaycastParams = { new = function() return { FilterDescendantsInstances = {} } end }
OverlapParams = { new = function() return { FilterDescendantsInstances = {} } end }
NumberSequenceKeypoint = NumberSequenceKeypoint
ColorSequenceKeypoint = { new = function(t, c) return { Time = t, Value = c } end }
Rect = { new = function() return {} end }
Font = { fromEnum = function(e) return e end }

-- CFrame minimo (so posicao + identidade de rotacao) --------------------------------------------------------------------------------
local CF = { __type = "CFrame" }
CF.__index = function(t, k)
	if k == "Position" then
		return Vector3.new(t.X, t.Y, t.Z)
	elseif k == "LookVector" then
		return Vector3.new(0, 0, -1)
	elseif k == "RightVector" then
		return Vector3.new(1, 0, 0)
	elseif k == "UpVector" then
		return Vector3.new(0, 1, 0)
	elseif k == "Rotation" then
		return CFrame.new(0, 0, 0)
	end
	return rawget(CF, k)
end
CF.__mul = function(a, b)
	if typeof(b) == "Vector3" then
		return a.Position + b
	end
	return CFrame.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
CFrame = {}
function CFrame.new(x, y, z)
	if typeof(x) == "Vector3" then
		return setmetatable({ X = x.X, Y = x.Y, Z = x.Z }, CF)
	end
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, CF)
end
function CFrame.Angles()
	return CFrame.new(0, 0, 0)
end
function CFrame.lookAt(a)
	return CFrame.new(a)
end
CFrame.identity = CFrame.new(0, 0, 0)

-- Signals / Instances -------------------------------------------------------------------------------------------------------------------
local function newSignal()
	local s = { _h = {} }
	function s:Connect(fn)
		table.insert(self._h, fn)
		return { Disconnect = function() end, Connected = true }
	end
	function s:Once(fn)
		table.insert(self._h, fn)
		return { Disconnect = function() end, Connected = true }
	end
	function s:Fire(...)
		for _, fn in self._h do
			fn(...)
		end
	end
	function s:Wait() end
	return s
end

local Inst = {}
local instMt = { __type = "Instance" }
local instMethods = {}
instMt.__index = function(t, k)
	local props = rawget(t, "_props")
	local v = props[k]
	if v ~= nil then
		return v
	end
	local m = instMethods[k]
	if m then
		return m
	end
	-- sinais (Touched, Changed...) sob demanda
	if type(k) == "string" and k:match("^[A-Z]") then
		local ch = rawget(t, "_children")
		for _, c in ch do
			if c.Name == k then
				return c
			end
		end
		local sig = newSignal()
		props[k] = sig
		return sig
	end
	return nil
end
instMt.__newindex = function(t, k, v)
	if k == "Parent" then
		local old = rawget(t, "_props").Parent
		if old then
			local ch = rawget(old, "_children")
			local i = table.find(ch, t)
			if i then
				table.remove(ch, i)
			end
		end
		rawget(t, "_props").Parent = v
		if v then
			table.insert(rawget(v, "_children"), t)
		end
	else
		local props = rawget(t, "_props")
		props[k] = v
		if k == "CFrame" and v then
			props.Position = v.Position
		end
	end
end
local CLASS_PARENT = {
	Part = "BasePart", WedgePart = "BasePart", MeshPart = "BasePart", SpawnLocation = "Part", TrussPart = "BasePart",
	BasePart = "PVInstance", Model = "PVInstance", PVInstance = "Instance", Folder = "Instance", Attachment = "Instance",
	ProximityPrompt = "Instance", ModuleScript = "Instance", Script = "Instance",
	TextLabel = "GuiObject", Frame = "GuiObject", TextButton = "GuiObject", ImageLabel = "GuiObject", GuiObject = "GuiBase2d",
	PointLight = "Light", SpotLight = "Light", Light = "Instance",
}
local function isA(cn, target)
	while cn do
		if cn == target then
			return true
		end
		cn = CLASS_PARENT[cn]
	end
	return target == "Instance"
end
local function mk(className, name)
	local o = setmetatable({ __isInstance = true, _props = { ClassName = className, Name = name or className }, _children = {} }, instMt)
	if isA(className, "BasePart") then
		local props = rawget(o, "_props")
		props.CFrame = CFrame.new(0, 0, 0)
		props.Position = Vector3.new(0, 0, 0)
		props.Size = Vector3.new(4, 1, 2)
		props.Anchored = false
		props.CanCollide = true
		props.Massless = false
		props.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		props.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		props.AssemblyMass = 10
		props.Color = Color3.new(1, 1, 1)
		props.Transparency = 0
		props.PivotOffset = CFrame.new(0, 0, 0)
		props.CollisionGroup = "Default"
		props.AssemblyRootPart = o
	end
	return o
end
function instMethods.WaitForChild(self, name)
	for _, c in rawget(self, "_children") do
		if c.Name == name then
			return c
		end
	end
	local c = mk("ModuleScript", name)
	c.Parent = self
	return c
end
function instMethods.FindFirstChild(self, name, recursive)
	for _, c in rawget(self, "_children") do
		if c.Name == name then
			return c
		end
	end
	if recursive then
		for _, c in rawget(self, "_children") do
			local r = instMethods.FindFirstChild(c, name, true)
			if r then
				return r
			end
		end
	end
	return nil
end
function instMethods.FindFirstChildOfClass(self, cn)
	for _, c in rawget(self, "_children") do
		if isA(c.ClassName, cn) then
			return c
		end
	end
	return nil
end
function instMethods.GetChildren(self)
	return table.clone(rawget(self, "_children"))
end
function instMethods.GetDescendants(self)
	local out = {}
	local function walk(n)
		for _, c in rawget(n, "_children") do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function instMethods.IsA(self, cn)
	return isA(self.ClassName, cn)
end
function instMethods.GetMass() return 10 end
function instMethods.SetNetworkOwner() end
function instMethods.SetNetworkOwnershipAuto() end
function instMethods.ApplyImpulse() end
function instMethods.ClearAllChildren(self)
	for _, c in table.clone(rawget(self, "_children")) do
		c.Parent = nil
	end
end
function instMethods.RemoveTag(self, tag)
	services.CollectionService:RemoveTag(self, tag)
end
function instMethods.GetTags() return {} end
function instMethods.GetAttributeChangedSignal() return newSignal() end
function instMethods.FindFirstAncestor() return nil end
function instMethods.GetFullName(self) return self.Name end
function instMethods.GetPivot() return CFrame.new(0, 0, 0) end
function instMethods.TweenPosition() end
function instMethods.Destroy(self)
	self.Parent = nil
end
function instMethods.SetAttribute(self, k, v)
	rawget(self, "_props")["@" .. k] = v
end
function instMethods.GetAttribute(self, k)
	return rawget(self, "_props")["@" .. k]
end
function instMethods.GetPropertyChangedSignal()
	return newSignal()
end
function instMethods.AddTag(self, tag)
	services.CollectionService:AddTag(self, tag)
end
function instMethods.HasTag(self, tag)
	return services.CollectionService:HasTag(self, tag)
end
function instMethods.Clone(self)
	return mk(self.ClassName, self.Name)
end
function instMethods.PivotTo() end
function instMethods.IsDescendantOf(self, other)
	local p = rawget(self, "_props").Parent
	while p do
		if p == other then
			return true
		end
		p = rawget(p, "_props").Parent
	end
	return false
end
function instMethods.FindFirstAncestorOfClass()
	return nil
end
function instMethods.FireClient() end
function instMethods.FireAllClients() end
function instMethods.FireServer() end

Instance = {
	new = function(cn, parent)
		local o = mk(cn)
		if parent then
			o.Parent = parent
		end
		return o
	end,
}

-- Terrain de mentira: guarda so contagem de escritas
local terrain = mk("Terrain", "Terrain")
terrain.__writes = 0
function terrain.WriteVoxels(self, region, res, mats, occ)
	rawset(self, "writes", (rawget(self, "writes") or 0) + 1)
end
terrain.FillBall = function() end
terrain.FillBlock = function() end
terrain.FillCylinder = function() end
terrain.FillWedge = function() end
terrain.Clear = function() end
terrain.SetMaterialColor = function() end

workspace = mk("Workspace", "Workspace")
workspace.Terrain = terrain
workspace.CurrentCamera = mk("Camera")
workspace.Gravity = 196.2
function workspace.GetServerTimeNow()
	return os.clock()
end
function workspace.Raycast()
	return nil
end
function workspace.GetPartBoundsInRadius()
	return {}
end

services = {}
game = mk("DataModel", "Game")
function game.GetService(_, name)
	local s = services[name]
	if not s then
		s = mk(name, name)
		services[name] = s
		if name == "Workspace" then
			return workspace
		end
	end
	return s
end
game.Workspace = workspace
function game.BindToClose() end
services.RunService = mk("RunService", "RunService")
services.RunService.Heartbeat = newSignal()
services.RunService.RenderStepped = newSignal()
services.RunService.Stepped = newSignal()
function services.RunService.IsServer() return true end
function services.RunService.IsClient() return false end
function services.RunService.IsStudio() return true end
services.Players = mk("Players", "Players")
services.Players.PlayerAdded = newSignal()
services.Players.PlayerRemoving = newSignal()
function services.Players.GetPlayers() return {} end
function services.Players.GetPlayerFromCharacter() return nil end
services.CollectionService = mk("CollectionService", "CollectionService")
local tagged = {}
function services.CollectionService.AddTag(_, inst, tag)
	tagged[tag] = tagged[tag] or {}
	tagged[tag][inst] = true
end
function services.CollectionService.RemoveTag(_, inst, tag)
	if tagged[tag] then
		tagged[tag][inst] = nil
	end
end
function services.CollectionService.HasTag(_, inst, tag)
	return tagged[tag] ~= nil and tagged[tag][inst] == true
end
function services.CollectionService.GetTagged(_, tag)
	local out = {}
	for inst in tagged[tag] or {} do
		table.insert(out, inst)
	end
	return out
end
function services.CollectionService.GetInstanceAddedSignal() return newSignal() end
function services.CollectionService.GetInstanceRemovedSignal() return newSignal() end
services.DataStoreService = mk("DataStoreService", "DataStoreService")
function services.DataStoreService.GetDataStore()
	local store = { _d = {} }
	function store:GetAsync(k) return self._d[k] end
	function store:SetAsync(k, v) self._d[k] = v end
	function store:UpdateAsync(k, fn) self._d[k] = fn(self._d[k]) end
	return store
end
function services.DataStoreService.GetOrderedDataStore()
	local store = { _d = {} }
	function store:GetAsync(k) return self._d[k] end
	function store:SetAsync(k, v) self._d[k] = v end
	function store:UpdateAsync(k, fn) self._d[k] = fn(self._d[k]) end
	function store:GetSortedAsync() return { GetCurrentPage = function() return {} end } end
	return store
end

-- task -----------------------------------------------------------------------------------------------------------------------------------------
__DELAYED = {}
task = {
	wait = function(t)
		if coroutine.isyieldable() then
			coroutine.yield()
		end
		return t or 0
	end,
	spawn = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			warn("task.spawn erro:", err)
		end
		return co
	end,
	defer = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			warn("task.defer erro:", err)
		end
		return co
	end,
	delay = function(t, fn, ...)
		table.insert(__DELAYED, { t = t, fn = fn, args = { ... } })
	end,
	cancel = function() end,
}
function wait() return 0 end
function warn(...) print("WARN:", ...) end
function tick() return os.clock() end
function time() return os.clock() end
os.date = os.date or function() return "" end

-- require por nome ----------------------------------------------------------------------------------------------------------------------------------
__MODULES = {}
__LOADED = {}
function __define(name, fn)
	__MODULES[name] = fn
end
local realRequire = require
function require(inst)
	local name = type(inst) == "table" and inst.Name or tostring(inst)
	if __LOADED[name] ~= nil then
		return __LOADED[name]
	end
	local fn = __MODULES[name]
	if not fn then
		error("mock require: modulo nao definido: " .. tostring(name))
	end
	local scriptStub = mk("ModuleScript", name)
	local parentStub = mk("Folder", "Parent")
	parentStub.Parent = mk("Folder", "Root")
	scriptStub.Parent = parentStub
	local res = fn(scriptStub)
	__LOADED[name] = res == nil and true or res
	return res
end
