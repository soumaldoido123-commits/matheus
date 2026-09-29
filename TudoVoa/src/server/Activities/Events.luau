--!nonstrict
--[[
	Events: eventos do mundo que acontecem de tempos em tempos.
	  ☄️ Chuva de Meteoros    🌙 Gravidade Lunar    🪙 Chuva de Moedas
	  🌋 Erupção do Vulcão    ✨ Hora do Ouro (moedas em dobro)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Server = script.Parent.Parent
local Data = require(Server:WaitForChild("Data"))
local Blasts = require(Server:WaitForChild("Blasts"))
local Pickups = require(Server:WaitForChild("Pickups"))
local Zones = require(Server:WaitForChild("Zones"))
local Interactive = require(Server:WaitForChild("World"):WaitForChild("Interactive"))
local Volcano = require(Server:WaitForChild("World"):WaitForChild("Volcano"))
local Build = require(Server:WaitForChild("World"):WaitForChild("Build"))

local Events = {}

local P = Config.Palette
local M = Enum.Material
local GRAVITY_DEFAULT = 196.2

local active = nil -- { id, name, icon, endsAt }
local rng = Random.new()

local function livePlayers()
	local out = {}
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and hrp.Position.Y < Config.World.SkyY - 40 then
			table.insert(out, { player = p, hrp = hrp })
		end
	end
	return out
end

local function broadcast(on: boolean, ev, endsAt: number?)
	Remotes.get("EventState"):FireAllClients({
		active = on,
		id = ev.id,
		name = ev.name,
		icon = ev.icon,
		desc = ev.desc,
		endsAt = endsAt,
	})
end

-- Meteoros ------------------------------------------------------------------------------------------------------------------------------------------

local function meteor(target: Vector3)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = M.Neon
	ring.Color = P.Red
	ring.Transparency = 0.4
	ring.Size = Vector3.new(0.4, 22, 22)
	ring.CFrame = CFrame.new(target + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = workspace
	task.delay(1.8, function()
		ring:Destroy()
	end)

	local fall = 1.7
	local from = target + Vector3.new(rng:NextNumber(-70, 70), 280, rng:NextNumber(-70, 70))
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * 8
	ball.Material = M.Neon
	ball.Color = Color3.fromRGB(255, 130, 50)
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Position = from
	ball.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 1, 1)
	ball.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 60)
	light.Range = 60
	light.Brightness = 4
	light.Parent = ball
	local att = Instance.new("Attachment")
	att.Parent = ball
	local trail = Instance.new("ParticleEmitter")
	trail.Texture = "rbxasset://textures/particles/fire_main.dds"
	trail.Rate = 90
	trail.Lifetime = NumberRange.new(0.6, 1.2)
	trail.Speed = NumberRange.new(0, 4)
	trail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 0) })
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 70, 20))
	trail.Parent = att

	-- velocidade para chegar no alvo em "fall" segundos sob a gravidade atual
	local g = workspace.Gravity
	local off = target - from
	local vel = Vector3.new(off.X / fall, off.Y / fall + 0.5 * g * fall, off.Z / fall)
	ball.AssemblyLinearVelocity = vel
	pcall(function()
		ball:SetNetworkOwner(nil)
	end)
	ball.CanCollide = true
	local hit = false
	ball.Touched:Connect(function(other)
		if hit or other:IsDescendantOf(ball) then
			return
		end
		hit = true
		local pos = ball.Position
		ball:Destroy()
		Blasts.explode(pos, 24, 95, nil)
		Pickups.burst(pos + Vector3.new(0, 3, 0), 60, 6)
	end)
	task.delay(6, function()
		if ball.Parent then
			ball:Destroy()
		end
	end)
end

local function runMeteors(ev, endsAt)
	while os.clock() < endsAt do
		local list = livePlayers()
		if #list > 0 then
			local pick = list[rng:NextInteger(1, #list)]
			local base = pick.hrp.Position
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(4, 45)
			local x, z = base.X + math.cos(a) * r, base.Z + math.sin(a) * r
			-- longe da zona segura
			if Vector3.new(x, 0, z).Magnitude < Zones.SafeRadius + 10 and base.Y < Config.World.SkyY - 60 then
				local push = Vector3.new(x, 0, z)
				push = push.Magnitude > 1 and push.Unit or Vector3.xAxis
				x, z = push.X * (Zones.SafeRadius + 14), push.Z * (Zones.SafeRadius + 14)
			end
			local y = Build.y(x, z)
			meteor(Vector3.new(x, y, z))
		end
		task.wait(rng:NextNumber(1.1, 2.0))
	end
end

-- Erupcao ---------------------------------------------------------------------------------------------------------------------------------------------

local function runEruption(ev, endsAt)
	local crater = Volcano.craterPos
	if not crater then
		return
	end
	local n = 0
	while os.clock() < endsAt and n < 14 do
		n += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(70, 330)
		local tx = crater.X + math.cos(a) * r
		local tz = crater.Z + math.sin(a) * r
		local ty = Build.y(tx, tz)
		local from = crater + Vector3.new(0, 16, 0)
		local vel = Interactive.ballistic(from, Vector3.new(tx, ty, tz), 62)
		if vel then
			local fb = Instance.new("Part")
			fb.Shape = Enum.PartType.Ball
			fb.Size = Vector3.one * 9
			fb.Material = M.Neon
			fb.Color = Color3.fromRGB(255, 110, 30)
			fb.Position = from
			fb.Parent = workspace
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(255, 120, 40)
			l.Range = 70
			l.Brightness = 4
			l.Parent = fb
			local att = Instance.new("Attachment")
			att.Parent = fb
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/fire_main.dds"
			pe.Rate = 80
			pe.Lifetime = NumberRange.new(0.6, 1.2)
			pe.Speed = NumberRange.new(0, 4)
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 9), NumberSequenceKeypoint.new(1, 0) })
			pe.LightEmission = 1
			pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 110), Color3.fromRGB(255, 60, 20))
			pe.Parent = att
			fb.AssemblyLinearVelocity = vel
			pcall(function()
				fb:SetNetworkOwner(nil)
			end)
			Remotes.get("Fx"):FireAllClients("explosion", from, 1.4, nil)
			local hit = false
			task.delay(0.5, function()
				fb.Touched:Connect(function(other)
					if hit or other:IsDescendantOf(fb) then
						return
					end
					hit = true
					local pos = fb.Position
					fb:Destroy()
					Blasts.explode(pos, 28, 105, nil)
					Pickups.burst(pos + Vector3.new(0, 3, 0), 90, 8)
				end)
			end)
			task.delay(12, function()
				if fb.Parent then
					fb:Destroy()
				end
			end)
		end
		task.wait(rng:NextNumber(1.6, 2.6))
	end
end

-- Chuva de moedas ------------------------------------------------------------------------------------------------------------------------------------------

local function runCoinRain(ev, endsAt)
	while os.clock() < endsAt do
		for _, e in livePlayers() do
			local base = e.hrp.Position
			for _ = 1, 2 do
				local x = base.X + rng:NextNumber(-45, 45)
				local z = base.Z + rng:NextNumber(-45, 45)
				Pickups.burst(Vector3.new(x, base.Y + 70, z), 8, 1)
			end
		end
		task.wait(0.6)
	end
end

-- Gravidade lunar --------------------------------------------------------------------------------------------------------------------------------------------

local function runLowGravity(ev, endsAt)
	workspace.Gravity = 62
	while os.clock() < endsAt do
		task.wait(0.5)
	end
	workspace.Gravity = GRAVITY_DEFAULT
end

local function runGoldHour(ev, endsAt)
	Data.multiplier = 2
	while os.clock() < endsAt do
		task.wait(0.5)
	end
	Data.multiplier = 1
end

local LIST = {
	{ id = "meteors", name = "Chuva de Meteoros", icon = "☄️", duration = 48, weight = 3, run = runMeteors, desc = "Fique de olho no chão: círculos vermelhos mostram onde eles caem!" },
	{ id = "lowgrav", name = "Gravidade Lunar", icon = "🌙", duration = 65, weight = 3, run = runLowGravity, desc = "Tudo flutua! Seus arremessos vão MUITO mais longe." },
	{ id = "coinrain", name = "Chuva de Moedas", icon = "🪙", duration = 38, weight = 3, run = runCoinRain, desc = "Moedas caem do céu. Corra e pegue!" },
	{ id = "eruption", name = "Erupção do Vulcão", icon = "🌋", duration = 40, weight = 2, run = runEruption, desc = "Bolas de fogo do Vulcão Furioso! Elas dão moedas ao explodir." },
	{ id = "goldhour", name = "Hora do Ouro", icon = "✨", duration = 80, weight = 2, run = runGoldHour, desc = "Todas as moedas valem o DOBRO!" },
}

local function pickEvent()
	local total = 0
	for _, e in LIST do
		total += e.weight
	end
	local r = rng:NextNumber(0, total)
	for _, e in LIST do
		r -= e.weight
		if r <= 0 then
			return e
		end
	end
	return LIST[1]
end

function Events.trigger(id: string?)
	if active then
		return
	end
	local ev = nil
	if id then
		for _, e in LIST do
			if e.id == id then
				ev = e
			end
		end
	end
	ev = ev or pickEvent()
	local endsAt = os.clock() + ev.duration
	local serverEnd = workspace:GetServerTimeNow() + ev.duration
	active = { id = ev.id, name = ev.name, icon = ev.icon, endsAt = endsAt }
	broadcast(true, ev, serverEnd)
	for _, p in Players:GetPlayers() do
		Remotes.get("Announce"):FireClient(p, ev.icon .. " " .. string.upper(ev.name), ev.desc, 4, P.Accent2)
	end
	task.spawn(function()
		local ok, err = pcall(ev.run, ev, endsAt)
		if not ok then
			warn("[Eventos] erro em", ev.id, err)
		end
		workspace.Gravity = GRAVITY_DEFAULT
		Data.multiplier = 1
		active = nil
		broadcast(false, ev, nil)
	end)
end

function Events.init()
	task.spawn(function()
		task.wait(110)
		while true do
			if #Players:GetPlayers() > 0 and not active then
				Events.trigger()
			end
			task.wait(rng:NextNumber(230, 340))
		end
	end)
end

return Events
