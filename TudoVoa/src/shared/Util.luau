--!nonstrict
--[[
	Utilitarios compartilhados entre servidor e cliente.
]]

local TweenService = game:GetService("TweenService")

local Util = {}

-- Matematica ----------------------------------------------------------------

function Util.clamp(x: number, a: number, b: number): number
	if x < a then
		return a
	elseif x > b then
		return b
	end
	return x
end

function Util.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function Util.map(x: number, a: number, b: number, c: number, d: number): number
	if a == b then
		return c
	end
	return c + (d - c) * ((x - a) / (b - a))
end

function Util.saturate(x: number): number
	return Util.clamp(x, 0, 1)
end

function Util.smoothstep(a: number, b: number, x: number): number
	if a == b then
		return x < a and 0 or 1
	end
	local t = Util.saturate((x - a) / (b - a))
	return t * t * (3 - 2 * t)
end

function Util.round(x: number, step: number?): number
	local s = step or 1
	return math.floor(x / s + 0.5) * s
end

function Util.formatNumber(n: number): string
	n = math.floor(n)
	local abs = math.abs(n)
	if abs >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif abs >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif abs >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	-- separador de milhar com ponto
	local s = tostring(abs)
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if out:sub(1, 1) == "." then
		out = out:sub(2)
	end
	return (n < 0 and "-" or "") .. out
end

function Util.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local m = seconds // 60
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

function Util.lerpColor(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end

-- Sorteio ponderado: items = lista, weightFn(item) -> peso
function Util.weightedPick(items: { any }, weightFn: (any) -> number, rng: Random?): any
	local total = 0
	for _, it in items do
		total += math.max(0, weightFn(it))
	end
	if total <= 0 then
		return items[1]
	end
	local r = (rng and rng:NextNumber() or math.random()) * total
	for _, it in items do
		r -= math.max(0, weightFn(it))
		if r <= 0 then
			return it
		end
	end
	return items[#items]
end

-- Instancias ----------------------------------------------------------------

-- Util.New("Part", { Size = ..., Parent = ... }, { filhos })
function Util.New(className: string, props: { [string]: any }?, children: { Instance }?): Instance
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Util.getRoot(part: BasePart): BasePart
	local root = part.AssemblyRootPart
	return root or part
end

-- massa total de uma montagem ou de um modelo inteiro
function Util.modelMass(inst: Instance): number
	local total = 0
	if inst:IsA("BasePart") then
		total += inst:GetMass()
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			total += d:GetMass()
		end
	end
	return total
end

function Util.weld(a: BasePart, b: BasePart, parent: Instance?): WeldConstraint
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = parent or a
	return w
end

function Util.setAll(inst: Instance, prop: string, value: any)
	if inst:IsA("BasePart") then
		inst[prop] = value
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			d[prop] = value
		end
	end
end

function Util.tween(inst: Instance, info: TweenInfo | number, goal: { [string]: any }, play: boolean?): Tween
	local ti = info
	if typeof(info) == "number" then
		ti = TweenInfo.new(info, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
	local t = TweenService:Create(inst, ti, goal)
	if play ~= false then
		t:Play()
	end
	return t
end

-- Maid: agrupa conexoes/instancias para limpar de uma vez ----------------------

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(item: any): any
	table.insert(self._tasks, item)
	return item
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for _, item in tasks do
		local t = typeof(item)
		if t == "RBXScriptConnection" then
			item:Disconnect()
		elseif t == "Instance" then
			item:Destroy()
		elseif t == "function" then
			task.spawn(item)
		elseif t == "table" then
			if item.Destroy then
				item:Destroy()
			elseif item.Disconnect then
				item:Disconnect()
			end
		end
	end
end

Maid.Destroy = Maid.Clean
Util.Maid = Maid

-- Signal simples (sem BindableEvent) ---------------------------------------------

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {}, _n = 0 }, Signal)
end

function Signal:Connect(fn: (...any) -> ())
	self._n += 1
	local id = self._n
	self._handlers[id] = fn
	local conn = { Connected = true }
	function conn:Disconnect()
		if self.Connected then
			self.Connected = false
			self._signal._handlers[id] = nil
		end
	end
	conn._signal = self
	return conn
end

function Signal:Fire(...)
	for _, fn in self._handlers do
		task.spawn(fn, ...)
	end
end

function Signal:Once(fn: (...any) -> ())
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end

function Signal:Destroy()
	self._handlers = {}
end

Util.Signal = Signal

-- Mola critica amortecida (suaviza valores numericos ou Vector3) ---------------------

local Spring = {}
Spring.__index = Spring

-- freq: rad/s aproximado, damping: 1 = critico, <1 = quica
function Spring.new(initial: any, freq: number, damping: number)
	local zero = initial
	if typeof(initial) == "number" then
		zero = 0
	elseif typeof(initial) == "Vector3" then
		zero = Vector3.zero
	elseif typeof(initial) == "Vector2" then
		zero = Vector2.zero
	end
	return setmetatable({
		Position = initial,
		Velocity = zero,
		Target = initial,
		Frequency = freq,
		Damping = damping,
		_zero = zero,
	}, Spring)
end

function Spring:Step(dt: number): any
	-- integracao semi-implicita estavel (subpassos para dt grande)
	local steps = math.max(1, math.ceil(dt / (1 / 120)))
	local h = dt / steps
	local w = self.Frequency
	local z = self.Damping
	for _ = 1, steps do
		local accel = (self.Target - self.Position) * (w * w) - self.Velocity * (2 * z * w)
		self.Velocity = self.Velocity + accel * h
		self.Position = self.Position + self.Velocity * h
	end
	return self.Position
end

function Spring:Impulse(v: any)
	self.Velocity = self.Velocity + v
end

function Spring:Reset(v: any)
	self.Position = v
	self.Target = v
	self.Velocity = self._zero
end

Util.Spring = Spring

-- Diversos -----------------------------------------------------------------------------

function Util.randomUnit(rng: Random?): Vector3
	local r = rng or Random.new()
	local v = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-1, 1), r:NextNumber(-1, 1))
	if v.Magnitude < 1e-3 then
		return Vector3.yAxis
	end
	return v.Unit
end

function Util.flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Util.safeUnit(v: Vector3, fallback: Vector3?): Vector3
	if v.Magnitude < 1e-4 then
		return fallback or Vector3.zAxis
	end
	return v.Unit
end

-- Cor a partir de HSV com saturacao/valor fixos
function Util.hue(h: number, s: number?, v: number?): Color3
	return Color3.fromHSV(h % 1, s or 0.8, v or 1)
end

return Util
