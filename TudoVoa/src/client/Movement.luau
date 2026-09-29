--!nonstrict
--[[
	Movement (cliente): tudo que mexe no proprio personagem.
	  - Lancamentos do servidor (canhoes, explosoes, cama elastica)
	  - Ragdoll: estado fisico, levantar (espaco) e ESPERNEAR quando alguem te agarra
	  - Tubos de vento (elevadores para as ilhas), jump pads (cogumelos, gêiseres)
	  - Correr (Shift) e impulso (dash)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Fx = require(script.Parent:WaitForChild("Fx"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local HUD = require(script.Parent:WaitForChild("UI"):WaitForChild("HUD"))
local GrabController = require(script.Parent:WaitForChild("GrabController"))

local Movement = {}

local player = Players.LocalPlayer

local heldBy: string? = nil
local ragdolled = false
local ragdollStart = 0
local lastStruggle = 0
local lastPad = 0
local winds = {}
local pads = {}
local sprinting = false
local inWind = false

local BASE_SPEED = 16
local SPRINT_SPEED = 27

local function character(): Model?
	return player.Character
end

local function hrpOf(): BasePart?
	local c = character()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function humanoid(): Humanoid?
	local c = character()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function setAllVelocity(v: Vector3)
	local c = character()
	if not c then
		return
	end
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			d.AssemblyLinearVelocity = v
		end
	end
end

-- Ragdoll -------------------------------------------------------------------------------------------------------------------------

local function setRagdoll(on: boolean)
	local hum = humanoid()
	if not hum then
		return
	end
	ragdolled = on
	if on then
		ragdollStart = os.clock()
		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		hum.PlatformStand = true
		hum:ChangeState(Enum.HumanoidStateType.Physics)
	else
		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function onJumpRequest()
	if heldBy then
		local now = os.clock()
		if now - lastStruggle > 0.055 then
			lastStruggle = now
			Remotes.get("Struggle"):FireServer()
			Fx.shake(0.12)
			Audio.ui("Soft", 0.15, 1.6 + math.random() * 0.4)
		end
	elseif ragdolled and os.clock() - ragdollStart > Config.Ragdoll.GetUpAfter then
		Remotes.get("RequestGetUp"):FireServer()
	end
end

-- Vento e jump pads -------------------------------------------------------------------------------------------------------------------

local function trackTag(tag: string, list)
	for _, p in CollectionService:GetTagged(tag) do
		if p:IsA("BasePart") then
			table.insert(list, p)
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(p)
		if p:IsA("BasePart") then
			table.insert(list, p)
		end
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(p)
		local i = table.find(list, p)
		if i then
			table.remove(list, i)
		end
	end)
end

local function stepWorld(dt: number)
	local hrp = hrpOf()
	local hum = humanoid()
	if not hrp or not hum or hum.Health <= 0 then
		return
	end
	local pos = hrp.Position

	-- vento
	local nowInWind = false
	for _, tube in winds do
		if tube.Parent then
			local rel = tube.CFrame:PointToObjectSpace(pos)
			local halfLen = tube.Size.X / 2
			local radius = tube.Size.Y / 2
			if math.abs(rel.X) < halfLen and math.sqrt(rel.Y * rel.Y + rel.Z * rel.Z) < radius then
				nowInWind = true
				local speed = tube:GetAttribute("Speed") or 78
				local v = hrp.AssemblyLinearVelocity
				local axisPoint = tube.CFrame * Vector3.new(rel.X, 0, 0)
				local toAxis = Vector3.new(axisPoint.X - pos.X, 0, axisPoint.Z - pos.Z)
				local horiz = Vector3.new(v.X, 0, v.Z) * math.max(0, 1 - dt * 2.5) + toAxis * dt * 5
				local top = tube:GetAttribute("Top") or (tube.Position.Y + halfLen)
				local px, pz = tube:GetAttribute("PullX"), tube:GetAttribute("PullZ")
				if px and pz then
					local frac = Util.saturate((pos.Y - (top - 55)) / 45)
					local toCenter = Vector3.new(px - pos.X, 0, pz - pos.Z)
					if toCenter.Magnitude > 1 then
						horiz = horiz:Lerp(toCenter.Unit * 34, frac * math.min(1, dt * 3.5))
					end
				end
				local vy = Util.lerp(v.Y, speed, math.min(1, dt * 5))
				local newVel = Vector3.new(horiz.X, vy, horiz.Z)
				for _, d in character():GetDescendants() do
					if d:IsA("BasePart") and d.AssemblyRootPart == d then
						d.AssemblyLinearVelocity = newVel
					end
				end
				if not ragdolled then
					hum:ChangeState(Enum.HumanoidStateType.Freefall)
				end
				break
			end
		end
	end
	if nowInWind and not inWind then
		Audio.ui("Charge", 0.4, 0.5)
		Fx.fovKick(0)
	end
	inWind = nowInWind

	-- jump pads
	local now = os.clock()
	if now - lastPad > 0.5 then
		for _, pad in pads do
			if pad.Parent then
				local dx, dz = pos.X - pad.Position.X, pos.Z - pad.Position.Z
				local dy = pos.Y - pad.Position.Y
				local r = pad.Size.Y / 2 + 1
				if dx * dx + dz * dz < r * r and dy > -1 and dy < 7 then
					local power = pad:GetAttribute("Power") or 110
					local dir = Vector3.new(pad:GetAttribute("DirX") or 0, pad:GetAttribute("DirY") or 1, pad:GetAttribute("DirZ") or 0)
					dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.yAxis
					lastPad = now
					local v = hrp.AssemblyLinearVelocity
					setAllVelocity(dir * power + Vector3.new(v.X * 0.3, 0, v.Z * 0.3))
					if not ragdolled then
						hum:ChangeState(Enum.HumanoidStateType.Freefall)
					end
					Fx.handlers.bounce(pad.Position, 1)
					Fx.fovKick(6)
					break
				end
			end
		end
	end

	-- correr
	if not ragdolled then
		local target = BASE_SPEED
		if sprinting and not GrabController.isHolding() then
			target = SPRINT_SPEED
		elseif GrabController.isHolding() then
			target = 14
		end
		hum.WalkSpeed = Util.lerp(hum.WalkSpeed, target, math.min(1, dt * 8))
	end
end

-- API --------------------------------------------------------------------------------------------------------------------------------------

function Movement.dash()
	local hrp = hrpOf()
	local hum = humanoid()
	if not hrp or not hum then
		return
	end
	local cam = workspace.CurrentCamera
	local look = cam.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.05 then
		flat = hrp.CFrame.LookVector
	end
	flat = flat.Unit
	local v = flat * 105 + Vector3.new(0, 46, 0)
	setAllVelocity(v)
	hum:ChangeState(Enum.HumanoidStateType.Freefall)
	Fx.fovKick(10)
	Audio.ui("Throw", 0.5, 1.4)
end

function Movement.isRagdolled(): boolean
	return ragdolled
end

function Movement.isHeld(): boolean
	return heldBy ~= nil
end

function Movement.init()
	trackTag("TV_Wind", winds)
	trackTag("TV_JumpPad", pads)

	Remotes.get("Launch").OnClientEvent:Connect(function(velocity)
		if typeof(velocity) == "Vector3" then
			setAllVelocity(velocity)
			local hum = humanoid()
			if hum and not ragdolled then
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end
	end)

	Remotes.get("RagdollState").OnClientEvent:Connect(function(on)
		setRagdoll(on == true)
	end)

	Remotes.get("HoldedBy").OnClientEvent:Connect(function(name, progress)
		heldBy = name
		HUD.setStruggle(name, progress)
	end)

	UserInputService.JumpRequest:Connect(onJumpRequest)

	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprinting = true
		end
		local _ = processed
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprinting = false
		end
	end)

	RunService.Heartbeat:Connect(stepWorld)

	player.CharacterAdded:Connect(function(char)
		ragdolled = false
		heldBy = nil
		HUD.setStruggle(nil)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.WalkSpeed = BASE_SPEED
		end
	end)
end

return Movement
