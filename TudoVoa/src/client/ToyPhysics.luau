--!nonstrict
--[[
	ToyPhysics (cliente): comportamentos em voo dos brinquedos arremessados.
	  - Quem arremessou e dono da fisica: so ele aplica as forcas (planar, foguete, bumerangue)
	  - TODOS os clientes: chama do foguete, rastro do jogador (estrelas, fumaca, cometa...)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Audio = require(script.Parent:WaitForChild("Audio"))

local ToyPhysics = {}

local player = Players.LocalPlayer
local GRAVITY = 196.2
local airborne = {} -- [part] = { t0, visuals = {...}, caught = false }

local TRAIL_COLORS = {}
for _, c in Config.TetherColors do
	TRAIL_COLORS[c.id] = c
end

-- Rastro cosmetico ------------------------------------------------------------------------------------------------------------

local function makeTrailVisual(part: BasePart, trailId: string, colorId: string)
	local color = (TRAIL_COLORS[colorId] or TRAIL_COLORS.Roxo).color
	local visuals = {}
	local att = Instance.new("Attachment")
	att.Name = "TV_TrailAtt"
	att.Parent = part
	table.insert(visuals, att)

	if trailId == "Estrelas" or trailId == "Faiscas" or trailId == "Cometa" then
		local e = Instance.new("ParticleEmitter")
		e.Rate = trailId == "Cometa" and 80 or 40
		e.Lifetime = NumberRange.new(0.5, trailId == "Cometa" and 1.6 or 1.0)
		e.Speed = NumberRange.new(2, trailId == "Faiscas" and 22 or 8)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, trailId == "Cometa" and 2.2 or 1.2), NumberSequenceKeypoint.new(1, 0) })
		e.LightEmission = 1
		e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		e.Parent = att
		table.insert(visuals, e)
	end
	if trailId == "Fumaca" then
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Rate = 30
		e.Lifetime = NumberRange.new(0.8, 1.6)
		e.Speed = NumberRange.new(0, 3)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(color)
		e.Parent = att
		table.insert(visuals, e)
	end
	if trailId == "Cometa" or trailId == "Estrelas" then
		local a2 = Instance.new("Attachment")
		a2.Position = Vector3.new(0, 0, 0)
		a2.Parent = part
		local tr = Instance.new("Trail")
		tr.Attachment0 = att
		tr.Attachment1 = a2
		att.Position = Vector3.new(0, part.Size.Y / 2, 0)
		a2.Position = Vector3.new(0, -part.Size.Y / 2, 0)
		tr.Lifetime = trailId == "Cometa" and 0.9 or 0.5
		tr.LightEmission = 1
		tr.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.6))
		tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		tr.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		tr.Parent = part
		table.insert(visuals, a2)
		table.insert(visuals, tr)
	end
	return visuals
end

local function onAirborne(part: BasePart)
	if not part:IsA("BasePart") or airborne[part] then
		return
	end
	local rec = { t0 = os.clock(), visuals = {}, caught = false, throwerId = part:GetAttribute("Thrower") }
	airborne[part] = rec

	-- rastro do jogador que arremessou
	local thrower = rec.throwerId and Players:GetPlayerByUserId(rec.throwerId)
	if thrower then
		local trail = thrower:GetAttribute("TetherTrail")
		if trail and trail ~= "Nenhum" then
			rec.visuals = makeTrailVisual(part, trail, thrower:GetAttribute("TetherColor") or "Roxo")
		end
	end

	local behavior = part:GetAttribute("Behavior")
	if behavior == "rocket" then
		local flame = part:FindFirstChild("Flame", true)
		if flame then
			flame.Enabled = true
			rec.flame = flame
		end
		rec.sound = Audio.loop("Rocket", part, 0.5, 1)
		table.insert(rec.visuals, rec.sound)
	elseif behavior == "explosive" then
		-- o pavio acende quando o servidor liga o emissor Spark
	end
end

local function onGrounded(part: Instance)
	local rec = airborne[part]
	if not rec then
		return
	end
	airborne[part] = nil
	if rec.flame and rec.flame.Parent then
		rec.flame.Enabled = false
	end
	for _, v in rec.visuals do
		if typeof(v) == "Instance" and v.Parent then
			if v:IsA("ParticleEmitter") then
				v.Enabled = false
				task.delay(2, function()
					if v.Parent then
						v:Destroy()
					end
				end)
			elseif v:IsA("Sound") then
				v:Destroy()
			else
				task.delay(1.5, function()
					if v.Parent then
						v:Destroy()
					end
				end)
			end
		end
	end
end

-- Forcas (so o dono) -----------------------------------------------------------------------------------------------------------------

local function steer(part: BasePart, rec, dt: number)
	local behavior = part:GetAttribute("Behavior")
	local age = os.clock() - rec.t0
	local mass = part.AssemblyMass
	local vel = part.AssemblyLinearVelocity
	local speed = vel.Magnitude

	if behavior == "glide" then
		-- sustentacao proporcional a velocidade + um pouco de arrasto
		local lift = GRAVITY * math.clamp(speed / 75, 0, 0.94)
		part:ApplyImpulse(Vector3.new(0, mass * lift * dt, 0))
		if speed > 30 then
			part:ApplyImpulse(-vel.Unit * mass * speed * 0.05 * dt)
		end
		-- aviao alinha o nariz com a velocidade
		if part:GetAttribute("AlignMode") == "look" and speed > 25 then
			local cf = CFrame.lookAt(part.Position, part.Position + vel)
			part.AssemblyAngularVelocity = Vector3.zero
			part.CFrame = part.CFrame:Lerp(cf, math.min(1, dt * 5))
		end
	elseif behavior == "rocket" then
		local yaw = part:GetAttribute("AlignYaw") or 0
		-- a frente do foguete e o eixo definido por AlignYaw (X local com 90 graus)
		local forward = (part.CFrame * CFrame.Angles(0, -math.rad(yaw), 0)).LookVector
		if age < 1.7 then
			part:ApplyImpulse(forward * mass * 330 * dt)
			part:ApplyImpulse(Vector3.new(0, mass * GRAVITY * 0.9 * dt, 0))
			-- nariz segue a velocidade
			if speed > 20 then
				local cf = CFrame.lookAt(part.Position, part.Position + vel) * CFrame.Angles(0, math.rad(yaw), 0)
				part.CFrame = part.CFrame:Lerp(cf, math.min(1, dt * 8))
				part.AssemblyAngularVelocity = Vector3.zero
			end
		elseif rec.flame then
			rec.flame.Enabled = false
		end
	elseif behavior == "boomerang" then
		local thrower = rec.throwerId and Players:GetPlayerByUserId(rec.throwerId)
		local hrp = thrower and thrower.Character and thrower.Character:FindFirstChild("HumanoidRootPart")
		part.AssemblyAngularVelocity = Vector3.new(0, 24, 0)
		part:ApplyImpulse(Vector3.new(0, mass * GRAVITY * 0.93 * dt, 0))
		if hrp and age > 0.8 then
			local to = (hrp.Position + Vector3.new(0, 2, 0)) - part.Position
			local dist = to.Magnitude
			local pull = math.clamp((age - 0.8) * 1.6, 0, 2.6)
			part:ApplyImpulse(to.Unit * mass * 160 * pull * dt)
			-- freia perto do jogador para poder "pegar"
			if dist < 16 then
				part.AssemblyLinearVelocity = vel * (1 - math.min(1, dt * 4))
			end
			if dist < 7 and not rec.caught and age > 1.6 then
				rec.caught = true
				Remotes.get("ActivityAction"):FireServer("boomerang", "catch", part)
			end
		end
	end
end

function ToyPhysics.init()
	local tag = Config.Tags.Airborne
	for _, part in CollectionService:GetTagged(tag) do
		onAirborne(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(onAirborne)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(onGrounded)

	RunService.Heartbeat:Connect(function(dt)
		for part, rec in airborne do
			if not part.Parent then
				onGrounded(part)
			elseif rec.throwerId == player.UserId and part.ReceiveAge == 0 then
				steer(part, rec, dt)
			end
		end
	end)
	local _ = Util
end

return ToyPhysics
