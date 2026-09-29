--!nonstrict
--[[
	Pose: animacao procedural do corpo (sem assets de animacao).
	  - Quem esta segurando algo estica os bracos em direcao ao objeto (todos veem)
	  - Ao carregar a forca o braco vai para tras e o tronco gira (jogador local)
	  - Ao arremessar o braco "chicoteia" para frente com mola (todos veem, via atributo ThrowT)
	Tudo e feito mexendo em Motor6D.C0 (o Animator so mexe em Transform).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Util = require(Shared:WaitForChild("Util"))

local Tether = require(script.Parent:WaitForChild("Tether"))
local GrabController = require(script.Parent:WaitForChild("GrabController"))

local Pose = {}

local player = Players.LocalPlayer
local states = {} -- [character] = state

local UP = Vector3.yAxis

local function motorInfo(m: Motor6D?)
	if not m or not m:IsA("Motor6D") or not m.Part0 then
		return nil
	end
	return { m = m, c0 = m.C0, c1 = m.C1, part0 = m.Part0 }
end

local function buildRig(char: Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil
	end
	local rig = {}
	if hum.RigType == Enum.HumanoidRigType.R15 then
		local rua = char:FindFirstChild("RightUpperArm")
		local lua = char:FindFirstChild("LeftUpperArm")
		local ut = char:FindFirstChild("UpperTorso")
		rig.right = motorInfo(rua and rua:FindFirstChild("RightShoulder"))
		rig.left = motorInfo(lua and lua:FindFirstChild("LeftShoulder"))
		rig.waist = motorInfo(ut and ut:FindFirstChild("Waist"))
	else
		local torso = char:FindFirstChild("Torso")
		rig.right = motorInfo(torso and torso:FindFirstChild("Right Shoulder"))
		rig.left = motorInfo(torso and torso:FindFirstChild("Left Shoulder"))
	end
	if not rig.right and not rig.left then
		return nil
	end
	return rig
end

local function getState(char: Model)
	local st = states[char]
	if st then
		return st
	end
	local rig = buildRig(char)
	if not rig then
		return nil
	end
	st = {
		rig = rig,
		weight = Util.Spring.new(0, 16, 0.9),
		kick = Util.Spring.new(0, 22, 0.32), -- subamortecida: chicote com retorno
		lastTarget = nil,
		char = char,
	}
	states[char] = st
	char.Destroying:Once(function()
		states[char] = nil
	end)
	char:GetAttributeChangedSignal("ThrowT"):Connect(function()
		st.kick.Position = 1
		st.kick.Velocity = 6
	end)
	return st
end

local function restore(info)
	if info and info.m.Parent then
		info.m.C0 = info.c0
	end
end

-- Aponta o membro (o "para baixo" natural do braco) para uma direcao no mundo
local function pointArm(info, worldDir: Vector3, weight: number)
	if not info or not info.m.Parent or not info.part0.Parent then
		return
	end
	local restDir = (info.c0 * info.c1:Inverse()):VectorToWorldSpace(Vector3.new(0, -1, 0))
	local desired = info.part0.CFrame:VectorToObjectSpace(worldDir)
	local axis = restDir:Cross(desired)
	local dot = math.clamp(restDir:Dot(desired), -1, 1)
	local angle = math.acos(dot)
	local rot = CFrame.identity
	if axis.Magnitude > 1e-4 then
		rot = CFrame.fromAxisAngle(axis.Unit, angle * weight)
	end
	info.m.C0 = CFrame.new(info.c0.Position) * rot * info.c0.Rotation
	if weight > 0.6 then
		info.m.Transform = CFrame.identity
	end
end

local function shoulderWorld(info): Vector3
	return (info.part0.CFrame * info.c0).Position
end

local function stepChar(char: Model, st, dt: number)
	local holdList = Tether.active[char]
	local isLocal = char == player.Character
	local chargeAmt = isLocal and GrabController.charge or 0

	if char:GetAttribute("Ragdolled") then
		st.weight.Target = 0
		st.weight.Position = 0
		return
	end

	-- alvo do braco: primeiro objeto segurado
	local targetPos: Vector3? = nil
	if holdList and holdList[1] and holdList[1].key.Parent then
		targetPos = holdList[1].key.Position
		st.lastTarget = targetPos
	end

	local holding = targetPos ~= nil
	st.weight.Target = (holding or st.kick.Position > 0.02) and 1 or 0
	local w = st.weight:Step(dt)
	st.kick:Step(dt)
	w = math.clamp(w, 0, 1)

	if w < 0.01 and st.kick.Position < 0.01 then
		restore(st.rig.right)
		restore(st.rig.left)
		restore(st.rig.waist)
		return
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local look = hrp and hrp.CFrame.LookVector or Vector3.zAxis
	look = Vector3.new(look.X, 0, look.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.zAxis

	local kick = math.clamp(st.kick.Position, -1.2, 1.4)

	for side, info in { right = st.rig.right, left = st.rig.left } do
		if info then
			local from = shoulderWorld(info)
			local to = targetPos or st.lastTarget or (from + look * 8)
			local dir = (to - from)
			dir = dir.Magnitude > 0.1 and dir.Unit or look
			-- carregando: braco vai para tras e um pouco para cima (so o braco direito e o esquerdo levemente)
			if chargeAmt > 0 then
				local back = (-look * 0.85 + UP * 0.55).Unit
				dir = dir:Lerp(back, math.clamp(chargeAmt * (side == "right" and 1 or 0.55), 0, 1)).Unit
			end
			-- chicote: vai para frente e levemente para cima
			if kick > 0.01 then
				local whip = (look * 1 + UP * 0.25).Unit
				dir = dir:Lerp(whip, math.clamp(kick, 0, 1)).Unit
			end
			pointArm(info, dir, w)
		end
	end

	-- tronco: gira para tras ao carregar e "chicoteia" no arremesso
	local wa = st.rig.waist
	if wa and wa.m.Parent then
		local yaw = -chargeAmt * 0.55 + kick * 0.6
		local lean = holding and 0.08 or 0
		wa.m.C0 = wa.c0 * CFrame.Angles(-lean - chargeAmt * 0.12, yaw, 0)
	end
end

function Pose.init()
	GrabController.Changed:Connect(function(event)
		if event == "throw" then
			local char = player.Character
			local st = char and getState(char)
			if st then
				st.kick.Position = 1
				st.kick.Velocity = 6
			end
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		-- cria estado para quem esta segurando algo
		for char in Tether.active do
			if char.Parent and not states[char] then
				getState(char)
			end
		end
		local lp = player.Character
		if lp and not states[lp] then
			getState(lp)
		end
		for char, st in states do
			if not char.Parent then
				states[char] = nil
			else
				local ok, err = pcall(stepChar, char, st, math.min(dt, 0.05))
				if not ok then
					warn("[Pose] erro:", err)
					states[char] = nil
				end
			end
		end
	end)
end

return Pose
