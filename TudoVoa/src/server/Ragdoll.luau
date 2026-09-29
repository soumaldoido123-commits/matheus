--!nonstrict
--[[
	Ragdoll: transforma personagens (R6/R15, jogadores ou NPCs) em bonecos de trapo.
	- Constroi BallSocketConstraints no lugar dos Motor6D (o servidor faz a parte fisica).
	- Avisa o cliente dono do personagem para entrar em estado Physics.
	- Recupera sozinho: depois de parado (e nao segurado) ou quando o tempo maximo acaba.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Physics = require(script.Parent:WaitForChild("Physics"))

local Ragdoll = {}

local states = {} -- [character] = estado

-- limites por junta (graus). Padrao generoso: o objetivo e ficar engracado, nao realista.
local JOINT_LIMITS = {
	Neck = { upper = 50, twist = 40 },
	Waist = { upper = 25, twist = 20 },
	RightShoulder = { upper = 110, twist = 70 },
	LeftShoulder = { upper = 110, twist = 70 },
	["Right Shoulder"] = { upper = 110, twist = 70 },
	["Left Shoulder"] = { upper = 110, twist = 70 },
	RightElbow = { upper = 75, twist = 5 },
	LeftElbow = { upper = 75, twist = 5 },
	RightWrist = { upper = 40, twist = 20 },
	LeftWrist = { upper = 40, twist = 20 },
	RightHip = { upper = 80, twist = 20 },
	LeftHip = { upper = 80, twist = 20 },
	["Right Hip"] = { upper = 80, twist = 20 },
	["Left Hip"] = { upper = 80, twist = 20 },
	RightKnee = { upper = 70, twist = 5 },
	LeftKnee = { upper = 70, twist = 5 },
	RightAnkle = { upper = 30, twist = 10 },
	LeftAnkle = { upper = 30, twist = 10 },
}
local DEFAULT_LIMIT = { upper = 60, twist = 30 }

function Ragdoll.isRagdolled(character: Model): boolean
	return states[character] ~= nil
end

function Ragdoll.isHeld(character: Model): boolean
	local st = states[character]
	return st ~= nil and st.held == true
end

local function tellOwner(character: Model, on: boolean, duration: number?)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		Remotes.get("RagdollState"):FireClient(player, on, duration or 0)
	end
end

local function build(character: Model, st)
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and d.Name ~= "RootJoint" and d.Part0 and d.Part1 then
			local limit = JOINT_LIMITS[d.Name] or DEFAULT_LIMIT
			local a0 = Instance.new("Attachment")
			a0.Name = "TV_RagA0"
			a0.CFrame = d.C0
			a0.Parent = d.Part0
			local a1 = Instance.new("Attachment")
			a1.Name = "TV_RagA1"
			a1.CFrame = d.C1
			a1.Parent = d.Part1

			local ball = Instance.new("BallSocketConstraint")
			ball.Name = "TV_RagBall"
			ball.Attachment0 = a0
			ball.Attachment1 = a1
			ball.LimitsEnabled = true
			ball.UpperAngle = limit.upper
			ball.TwistLimitsEnabled = true
			ball.TwistLowerAngle = -limit.twist
			ball.TwistUpperAngle = limit.twist
			ball.Restitution = 0
			ball.Parent = d.Part0

			-- evita membros brigando com o tronco
			local nc = Instance.new("NoCollisionConstraint")
			nc.Name = "TV_RagNC"
			nc.Part0 = d.Part0
			nc.Part1 = d.Part1
			nc.Parent = d.Part0

			d.Enabled = false
			table.insert(st.motors, d)
			table.insert(st.objects, a0)
			table.insert(st.objects, a1)
			table.insert(st.objects, ball)
			table.insert(st.objects, nc)
		end
	end
end

local function restore(character: Model, st)
	for _, obj in st.objects do
		if obj.Parent then
			obj:Destroy()
		end
	end
	for _, m in st.motors do
		if m.Parent then
			m.Enabled = true
		end
	end
end

-- Liga o ragdoll. opts: { duration = s, held = bool }
function Ragdoll.enable(character: Model, opts: { duration: number?, held: boolean? }?)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	opts = opts or {}
	local duration = opts.duration or Config.Ragdoll.MinDuration
	local st = states[character]
	local now = os.clock()
	if st then
		st.minEnd = math.max(st.minEnd, now + duration)
		if opts.held then
			st.held = true
		end
		return true
	end

	st = {
		motors = {},
		objects = {},
		start = now,
		minEnd = now + duration,
		held = opts.held == true,
		rest = 0,
		prevAutoRotate = humanoid.AutoRotate,
	}
	states[character] = st
	character:SetAttribute("Ragdolled", true)
	build(character, st)

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end)
	tellOwner(character, true, duration)

	humanoid.Died:Once(function()
		if states[character] then
			-- morreu ragdollado: deixa os membros soltos e limpa o estado
			states[character] = nil
			character:SetAttribute("Ragdolled", nil)
		end
	end)
	return true
end

function Ragdoll.disable(character: Model)
	local st = states[character]
	if not st then
		return
	end
	states[character] = nil
	character:SetAttribute("Ragdolled", nil)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = Physics.rootOfCharacter(character)
	if humanoid and humanoid.Health > 0 and root then
		-- levanta na vertical, olhando na direcao atual
		local look = Util.flat(root.CFrame.LookVector)
		if look.Magnitude < 0.05 then
			look = Util.flat(root.CFrame.UpVector)
		end
		look = Util.safeUnit(look, Vector3.zAxis)
		local pos = root.Position + Vector3.new(0, 3, 0)
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") then
				d.AssemblyLinearVelocity = Vector3.zero
				d.AssemblyAngularVelocity = Vector3.zero
			end
		end
		restore(character, st)
		character:PivotTo(CFrame.lookAt(pos, pos + look))
		humanoid.PlatformStand = false
		humanoid.AutoRotate = st.prevAutoRotate ~= false
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	else
		restore(character, st)
	end
	tellOwner(character, false, 0)
end

-- Derruba por um tempo (nao segurado)
function Ragdoll.knock(character: Model, duration: number?)
	return Ragdoll.enable(character, { duration = duration or Config.Ragdoll.MinDuration })
end

function Ragdoll.setHeld(character: Model, held: boolean, extraTime: number?)
	local st = states[character]
	if not st then
		return
	end
	st.held = held
	if not held then
		st.minEnd = math.max(st.minEnd, os.clock() + (extraTime or Config.Ragdoll.MinDuration))
		st.rest = 0
	end
end

local function step(dt: number)
	local now = os.clock()
	for character, st in states do
		if not character.Parent then
			states[character] = nil
		elseif not st.held then
			local root = Physics.rootOfCharacter(character)
			local speed = 0
			if root then
				speed = root.AssemblyLinearVelocity.Magnitude
			end
			if speed < Config.Ragdoll.RestSpeed then
				st.rest += dt
			else
				st.rest = 0
			end
			local resting = st.rest > 0.8
			local age = now - st.start
			if now >= st.minEnd and (resting or age >= Config.Ragdoll.MaxDuration) then
				Ragdoll.disable(character)
			end
		end
	end
end

function Ragdoll.init()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.2 then
			step(acc)
			acc = 0
		end
	end)

	-- o proprio jogador pode pedir para levantar (espaco) depois de um tempo
	Remotes.get("RequestGetUp").OnServerEvent:Connect(function(player)
		local character = player.Character
		local st = character and states[character]
		if not st or st.held then
			return
		end
		if os.clock() - st.start >= Config.Ragdoll.GetUpAfter then
			Ragdoll.disable(character)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local c = player.Character
		if c then
			states[c] = nil
		end
	end)
end

return Ragdoll
