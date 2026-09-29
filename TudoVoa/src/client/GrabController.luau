--!nonstrict
--[[
	GrabController: o "cabo de energia" no cliente.
	  - Mira (mouse livre; ao segurar algo a mira trava no centro, estilo terceira pessoa)
	  - Agarra objetos e pessoas (o servidor valida e entrega a fisica ao jogador)
	  - Segura com AlignPosition/AlignOrientation locais (o cliente e dono da fisica)
	  - Roda o mouse (scroll) muda a distancia; Z/X giram e C/V inclinam o objeto
	  - Botao direito: carrega a forca (com trajetoria prevista) e solta = arremessa
	  - Dois cabos (upgrade), controle (gamepad) e botoes de celular
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Store = require(script.Parent:WaitForChild("Store"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Fx = require(script.Parent:WaitForChild("Fx"))
local HUD = require(script.Parent:WaitForChild("UI"):WaitForChild("HUD"))
local Trajectory = require(script.Parent:WaitForChild("Trajectory"))

local GrabController = {}

GrabController.Changed = Util.Signal.new() -- (evento, ...)  "grab" | "drop" | "throw" | "chargeStart" | "chargeEnd"
GrabController.charge = 0
GrabController.charging = false
GrabController.holdCount = 0
GrabController.primary = nil -- primeira hold (para pose/HUD)

local player = Players.LocalPlayer
local GRAVITY = 196.2
local TAG = Config.Tags

local holds = {} -- { key, kind, model, mass, part, att, align, orient, rel (CFrame), parts = {BasePart} }
local pending = false
local holdDist = Config.Grab.HoldDefault
local hoverKey = nil
local hoverHit = nil
local lastGrabAttempt = 0
local usingCenterAim = false
local wheelBound = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local clientFolder = Instance.new("Folder")
clientFolder.Name = "TV_ClientFx"
clientFolder.Parent = workspace

local hoverHL = Instance.new("Highlight")
hoverHL.Name = "TV_Hover"
hoverHL.FillTransparency = 1
hoverHL.OutlineColor = Color3.new(1, 1, 1)
hoverHL.OutlineTransparency = 0.15
hoverHL.DepthMode = Enum.HighlightDepthMode.Occluded
hoverHL.Parent = clientFolder

-- Utilitarios --------------------------------------------------------------------------------------------------------

local function character(): Model?
	return player.Character
end

local function rootPart(): BasePart?
	local c = character()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function humanoid(): Humanoid?
	local c = character()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function updateFilter()
	local list = { clientFolder }
	local c = character()
	if c then
		table.insert(list, c)
	end
	for _, h in holds do
		table.insert(list, h.model or h.part)
	end
	local pk = workspace:FindFirstChild("TV_Pickups")
	if pk then
		table.insert(list, pk)
	end
	rayParams.FilterDescendantsInstances = list
end

local function isTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function usesCenter(): boolean
	return usingCenterAim or #holds > 0 or isTouch() or UserInputService.GamepadEnabled and not UserInputService.MouseEnabled
end

local function aimRay(): (Vector3, Vector3)
	local cam = workspace.CurrentCamera
	if usesCenter() then
		local vs = cam.ViewportSize
		local r = cam:ViewportPointToRay(vs.X / 2, vs.Y / 2)
		return r.Origin, r.Direction
	end
	local m = UserInputService:GetMouseLocation()
	local r = cam:ViewportPointToRay(m.X, m.Y)
	return r.Origin, r.Direction
end

-- Raio com "gordura" (ajuda a acertar objetos pequenos)
local function castAim(distance: number)
	updateFilter()
	local origin, dir = aimRay()
	local ok, result = pcall(function()
		return workspace:Spherecast(origin, 1.4, dir * distance, rayParams)
	end)
	if ok and result then
		return result, origin, dir
	end
	return workspace:Raycast(origin, dir * distance, rayParams), origin, dir
end

-- Descobre o "alvo agarravel" a partir de uma parte atingida: retorna key, modelo, ehPessoa
local function resolveTarget(part: BasePart)
	if not part or not part:IsA("BasePart") then
		return nil
	end
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			if model == character() then
				return nil
			end
			local p = Players:GetPlayerFromCharacter(model)
			if p or CollectionService:HasTag(model, TAG.Grabbable) then
				return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart"), model, true
			end
			return nil
		end
		local parent = model.Parent
		model = parent and parent:FindFirstAncestorOfClass("Model") or nil
	end
	local root = part.AssemblyRootPart or part
	if root.Anchored or not CollectionService:HasTag(root, TAG.Grabbable) then
		return nil
	end
	local m = root:FindFirstAncestorOfClass("Model")
	if m and m.PrimaryPart ~= root then
		m = nil
	end
	return root, m, false
end

-- Constraints de segurar ----------------------------------------------------------------------------------------------------

local function massOf(target: Instance): number
	local total = 0
	if target:IsA("BasePart") then
		return target.AssemblyMass
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") then
			total += d:GetMass()
		end
	end
	return total
end

local function buildHold(info)
	local key: BasePart = info.key
	if not key or not key.Parent then
		return nil
	end
	-- espera o servidor entregar a fisica
	local t0 = os.clock()
	while os.clock() - t0 < 0.7 and key.Parent do
		if key.ReceiveAge == 0 then
			break
		end
		task.wait()
	end
	if not key.Parent then
		return nil
	end

	local mass = info.mass or massOf(info.model or key)
	local att = Instance.new("Attachment")
	att.Name = "TV_HoldAtt"
	att.Parent = key

	local ap = Instance.new("AlignPosition")
	ap.Name = "TV_HoldPos"
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.RigidityEnabled = false
	ap.ApplyAtCenterOfMass = true
	ap.MaxForce = math.max(mass, 5) * GRAVITY * 16
	ap.MaxVelocity = Config.Grab.MaxVelocity
	ap.Responsiveness = Config.Grab.Responsiveness
	ap.Position = key.Position
	ap.Parent = key

	local ao = Instance.new("AlignOrientation")
	ao.Name = "TV_HoldRot"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.RigidityEnabled = false
	ao.MaxTorque = math.max(mass, 5) * 9000
	ao.MaxAngularVelocity = 26
	ao.Responsiveness = Config.Grab.OrientResponsiveness
	ao.CFrame = key.CFrame.Rotation
	ao.Parent = key

	-- rotacao relativa ao "yaw" da camera
	local cam = workspace.CurrentCamera
	local look = cam.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local yawCF = CFrame.Angles(0, yaw, 0)
	local rel = yawCF:Inverse() * key.CFrame.Rotation

	local parts = {}
	if info.kind == "character" and info.model then
		for _, d in info.model:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	else
		table.insert(parts, key)
		if info.model then
			for _, d in info.model:GetDescendants() do
				if d:IsA("BasePart") and d.AssemblyRootPart == key then
					table.insert(parts, d)
				end
			end
		end
	end

	return {
		key = key,
		part = key,
		kind = info.kind,
		model = info.model,
		mass = mass,
		att = att,
		align = ap,
		orient = ao,
		rel = rel,
		parts = parts,
		behavior = key:GetAttribute("Behavior"),
	}
end

local function destroyConstraints(h)
	for _, o in { h.align, h.orient, h.att } do
		if o and o.Parent then
			o:Destroy()
		end
	end
end

local function refreshState()
	GrabController.holdCount = #holds
	GrabController.primary = holds[1]
end

local function bindWheel()
	if wheelBound then
		return
	end
	wheelBound = true
	ContextActionService:BindActionAtPriority("TV_HoldWheel", function(_, state, input)
		if state == Enum.UserInputState.Change and #holds > 0 then
			holdDist = math.clamp(holdDist + input.Position.Z * Config.Grab.ScrollStep, Config.Grab.HoldMin, Store.holdMax())
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.UserInputType.MouseWheel)
end

local function unbindWheel()
	if not wheelBound then
		return
	end
	wheelBound = false
	ContextActionService:UnbindAction("TV_HoldWheel")
end

local function releaseHold(h, silent: boolean?)
	local idx = table.find(holds, h)
	if idx then
		table.remove(holds, idx)
	end
	destroyConstraints(h)
	refreshState()
	if #holds == 0 then
		GrabController.charging = false
		GrabController.charge = 0
		HUD.setCharge(nil)
		Trajectory.hide()
		unbindWheel()
		local hum = humanoid()
		if hum then
			hum.AutoRotate = true
		end
	end
	if not silent then
		GrabController.Changed:Fire("drop", h)
	end
end

-- Agarrar ----------------------------------------------------------------------------------------------------------------------

local function tryGrab()
	if pending or os.clock() - lastGrabAttempt < 0.15 then
		return
	end
	lastGrabAttempt = os.clock()
	local hum = humanoid()
	local hrp = rootPart()
	if not hum or not hrp or hum.Health <= 0 or character():GetAttribute("Ragdolled") then
		return
	end
	if #holds >= Store.maxHolds() then
		return
	end
	local result = castAim(Store.grabRange() + 10)
	local key, model, isPerson
	if result then
		key, model, isPerson = resolveTarget(result.Instance)
	end
	if not key then
		return false
	end
	if (key.Position - hrp.Position).Magnitude > Store.grabRange() + 14 then
		HUD.toast("Longe demais", "bad")
		return false
	end
	pending = true
	local ok, res, info = pcall(function()
		return Remotes.get("Grab"):InvokeServer(key, result and result.Position or key.Position)
	end)
	pending = false
	if not ok or not res then
		Audio.ui("Error", 0.4)
		if ok and type(info) == "string" then
			HUD.toast(info, "bad")
		end
		return false
	end
	local hold = buildHold(info)
	if not hold then
		Remotes.get("Release"):FireServer(key)
		return false
	end
	table.insert(holds, hold)
	refreshState()
	holdDist = math.clamp((key.Position - workspace.CurrentCamera.CFrame.Position).Magnitude, Config.Grab.HoldMin, Store.holdMax())
	bindWheel()
	Audio.ui("Grab", 0.5, 1 + math.random() * 0.15)
	GrabController.Changed:Fire("grab", hold)
	local _ = isPerson or model
	return true
end

local function dropAll(reason: string?)
	for i = #holds, 1, -1 do
		local h = holds[i]
		Remotes.get("Release"):FireServer(h.key)
		releaseHold(h)
	end
	if reason then
		Audio.ui("Release", 0.4)
	end
end

-- Arremesso -----------------------------------------------------------------------------------------------------------------------

local function aimPoint(): (Vector3, Vector3)
	local result, origin, dir = castAim(300)
	if result then
		return result.Position, dir
	end
	return origin + dir * 300, dir
end

local function throwAll()
	if #holds == 0 then
		return
	end
	local charge = math.max(GrabController.charge, Config.Throw.MinCharge)
	local point, camDir = aimPoint()
	local count = #holds
	local list = table.clone(holds)
	local hrp = rootPart()
	for i, h in list do
		local pos = h.part.Position
		local dir = point - pos
		if dir.Magnitude < 8 then
			dir = camDir
		end
		dir = dir.Unit
		-- dois cabos: abre um pouco os arremessos
		if count > 1 then
			local spread = math.rad((i - (count + 1) / 2) * 5)
			dir = (CFrame.Angles(0, spread, 0) * dir)
		end
		local speed = Store.throwSpeed(h.mass, charge)

		-- solta o cabo local ANTES de aplicar a velocidade
		destroyConstraints(h)
		table.remove(holds, table.find(holds, h))

		local mode = h.part:GetAttribute("AlignMode")
		local alignYaw = h.part:GetAttribute("AlignYaw") or 0
		local angular = Util.randomUnit() * Config.Throw.Spin
		if h.kind == "object" then
			if mode == "look" or h.behavior == "rocket" or h.behavior == "glide" and mode ~= "flat" then
				h.part.CFrame = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(alignYaw), 0)
				angular = dir * 0
				if h.behavior == "rocket" then
					angular = Vector3.zero
				end
			elseif mode == "flat" then
				h.part.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), math.pi / 2)
				angular = Vector3.new(0, 26, 0)
			elseif mode == "flatY" then
				h.part.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
				angular = Vector3.new(0, 22, 0)
			end
		end
		for _, p in h.parts do
			p.AssemblyLinearVelocity = dir * speed
			p.AssemblyAngularVelocity = angular
		end
		Remotes.get("Throw"):FireServer(h.key, dir, charge)
		GrabController.Changed:Fire("throw", h, speed, charge)
	end
	holds = {}
	refreshState()
	GrabController.charging = false
	GrabController.charge = 0
	HUD.setCharge(nil)
	Trajectory.hide()
	unbindWheel()
	local hum = humanoid()
	if hum then
		hum.AutoRotate = true
	end
	Audio.ui("Throw", 0.5 + charge * 0.4, 0.8 + charge * 0.5)
	Fx.fovKick(2 + charge * 7)
	Fx.shake(0.15 + charge * 0.3)
	local _ = hrp
end

local function beginCharge()
	if #holds == 0 or GrabController.charging or HUD.menuOpen then
		return
	end
	GrabController.charging = true
	GrabController.charge = 0
	GrabController.Changed:Fire("chargeStart")
end

local function endCharge()
	if not GrabController.charging then
		return
	end
	throwAll()
	GrabController.Changed:Fire("chargeEnd")
end

-- Atualizacao por quadro ---------------------------------------------------------------------------------------------------------------

local function setHover(key: BasePart?, model: Instance?)
	if key == hoverKey then
		return
	end
	hoverKey = key
	hoverHL.Adornee = key and (model or key) or nil
end

local function update(dt: number)
	local cam = workspace.CurrentCamera
	local hum = humanoid()
	local hrp = rootPart()
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	local c = character()

	-- caiu no ragdoll (ou abriu o menu) com coisas na mao: solta
	if (c:GetAttribute("Ragdolled") or HUD.menuOpen) and #holds > 0 then
		dropAll()
	end

	-- limpa holds cujo objeto sumiu
	for i = #holds, 1, -1 do
		local h = holds[i]
		if not h.part.Parent or not h.part:IsDescendantOf(workspace) then
			releaseHold(h)
		end
	end

	if #holds > 0 then
		-- travar mouse no centro e esconder o cursor
		if UserInputService.MouseEnabled then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		end
		hum.AutoRotate = false
		usingCenterAim = true

		local look = cam.CFrame.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		local yawCF = CFrame.Angles(0, yaw, 0)

		-- personagem olha para onde a camera olha
		if not c:GetAttribute("Ragdolled") then
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.01 then
				local target = CFrame.lookAt(hrp.Position, hrp.Position + flat)
				hrp.CFrame = hrp.CFrame:Lerp(target, math.min(1, dt * 14))
			end
		end

		-- rotacao do objeto pelo teclado
		local ry = (UserInputService:IsKeyDown(Enum.KeyCode.X) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.Z) and 1 or 0)
		local rx = (UserInputService:IsKeyDown(Enum.KeyCode.V) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.C) and 1 or 0)

		local origin = cam.CFrame.Position
		updateFilter()
		holdDist = math.clamp(holdDist, Config.Grab.HoldMin, Store.holdMax())
		local aimO, aimD = aimRay()
		for idx, h in holds do
			if ry ~= 0 or rx ~= 0 then
				h.rel = CFrame.Angles(rx * dt * 2.6, ry * dt * 2.6, 0) * h.rel
			end
			-- com dois cabos, o segundo fica ao lado
			local side = 0
			if #holds > 1 then
				side = (idx == 1) and -1.8 or 1.8
			end
			local wanted = aimD * holdDist + cam.CFrame.RightVector * side
			-- nao atravessar paredes/terreno
			local radius = h.part.Size.Magnitude * 0.5
			local hit = workspace:Raycast(aimO, wanted, rayParams)
			local target
			if hit then
				target = hit.Position + hit.Normal * math.min(radius + 0.4, 6)
			else
				target = aimO + wanted
			end
			h.align.Position = target
			h.orient.CFrame = yawCF * h.rel
		end

		-- carga do arremesso
		if GrabController.charging then
			GrabController.charge = math.min(1, GrabController.charge + dt / Config.Throw.ChargeTime)
			HUD.setCharge(GrabController.charge)
			local h = holds[1]
			if h then
				local point = aimPoint()
				local dir = (point - h.part.Position)
				if dir.Magnitude < 8 then
					dir = aimD
				end
				Trajectory.update(h.part.Position, dir.Unit, Store.throwSpeed(h.mass, math.max(GrabController.charge, Config.Throw.MinCharge)), rayParams)
			end
		end
		-- camera por cima do ombro
		hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.new(2, 0.4, 0), math.min(1, dt * 8))
		setHover(nil)
		HUD.setHint(nil)
		local _ = origin
	else
		usingCenterAim = false
		hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.zero, math.min(1, dt * 8))
		if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and not UserInputService.MouseIconEnabled then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		if UserInputService.MouseEnabled then
			UserInputService.MouseIconEnabled = true
		end
		-- destaca o que pode ser agarrado
		if not c:GetAttribute("Ragdolled") then
			local result = castAim(Store.grabRange() + 6)
			if result then
				local key, model, isPerson = resolveTarget(result.Instance)
				if key and (key.Position - hrp.Position).Magnitude <= Store.grabRange() + 8 then
					setHover(key, model)
					local label = isPerson and "Agarrar pessoa" or "Agarrar"
					if not isPerson and key:GetAttribute("ToyId") then
						local toy = require(Shared:WaitForChild("Toys")).ById[key:GetAttribute("ToyId")]
						if toy then
							label = toy.icon .. " " .. toy.name
						end
					end
					HUD.setHint(label, true)
					hoverHit = key
					return
				end
			end
		end
		setHover(nil)
		hoverHit = nil
		HUD.setHint(nil)
	end
end

-- Entrada ----------------------------------------------------------------------------------------------------------------------------------

local tryGrabSecond

local function onInputBegan(input: InputObject, processed: boolean)
	if processed or HUD.menuOpen then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if #holds < Store.maxHolds() and hoverHit then
			task.spawn(tryGrab)
		elseif #holds > 0 then
			if not tryGrabSecond() then
				dropAll("click")
			end
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		beginCharge()
	elseif input.KeyCode == Enum.KeyCode.G then
		dropAll("key")
	end
end

-- com dois cabos, clicar em outro objeto pega o segundo
tryGrabSecond = function(): boolean
	if #holds >= Store.maxHolds() then
		return false
	end
	local result = castAim(Store.grabRange() + 10)
	if result then
		local key = resolveTarget(result.Instance)
		if key then
			task.spawn(tryGrab)
			return true
		end
	end
	return false
end

local function onInputEnded(input: InputObject, _processed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		endCharge()
	end
end

-- API publica (botoes de celular / controle) ---------------------------------------------------------------------------------------------

function GrabController.mobileGrab()
	if #holds > 0 then
		dropAll("tap")
	else
		usingCenterAim = true
		task.spawn(tryGrab)
	end
end

function GrabController.mobileChargeBegin()
	beginCharge()
end

function GrabController.mobileChargeEnd()
	endCharge()
end

function GrabController.adjustDistance(direction: number)
	holdDist = math.clamp(holdDist + direction * Config.Grab.ScrollStep * 1.5, Config.Grab.HoldMin, Store.holdMax())
end

function GrabController.isHolding(): boolean
	return #holds > 0
end

function GrabController.getHolds()
	return holds
end

function GrabController.dropAll()
	dropAll()
end

-- alvo sob a mira (habilidades usam para saber o que puxar/congelar)
function GrabController.aimTarget(distance: number)
	local result, _, dir = castAim(distance)
	if result then
		local key = resolveTarget(result.Instance)
		return result.Position, key, result.Normal, dir
	end
	return nil, nil, nil, dir
end

function GrabController.aimWorldPoint(distance: number): Vector3?
	local result = castAim(distance)
	return result and result.Position or nil
end

function GrabController.init()
	RunService:BindToRenderStep("TV_Grab", Enum.RenderPriority.Camera.Value + 1, update)
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)

	-- toque na tela: pega o que estiver no ponto tocado
	UserInputService.TouchTapInWorld:Connect(function(position, processed)
		if processed or #holds > 0 then
			return
		end
		local cam = workspace.CurrentCamera
		local r = cam:ViewportPointToRay(position.X, position.Y)
		updateFilter()
		local result = workspace:Raycast(r.Origin, r.Direction * (Store.grabRange() + 10), rayParams)
		if result then
			local key = resolveTarget(result.Instance)
			if key then
				usingCenterAim = true
				hoverHit = key
				task.spawn(tryGrab)
			end
		end
	end)

	-- controle: R1 pega/solta, R2 carrega/arremessa, D-pad ajusta distancia
	ContextActionService:BindActionAtPriority("TV_PadGrab", function(_, state)
		if state == Enum.UserInputState.Begin then
			GrabController.mobileGrab()
		end
		return Enum.ContextActionResult.Pass
	end, false, 2500, Enum.KeyCode.ButtonR1)
	ContextActionService:BindActionAtPriority("TV_PadThrow", function(_, state)
		if state == Enum.UserInputState.Begin then
			beginCharge()
		elseif state == Enum.UserInputState.End then
			endCharge()
		end
		return Enum.ContextActionResult.Pass
	end, false, 2500, Enum.KeyCode.ButtonR2)
	ContextActionService:BindActionAtPriority("TV_PadDist", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			GrabController.adjustDistance(input.KeyCode == Enum.KeyCode.DPadUp and 1 or -1)
		end
		return Enum.ContextActionResult.Pass
	end, false, 2500, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown)

	Remotes.get("ForceRelease").OnClientEvent:Connect(function(key, reason)
		for _, h in holds do
			if h.key == key then
				releaseHold(h)
				if reason == "leash" then
					HUD.toast("O cabo esticou demais!", "bad")
				elseif reason == "escaped" then
					Audio.ui("Error", 0.3)
				end
				break
			end
		end
	end)

	player.CharacterAdded:Connect(function()
		for i = #holds, 1, -1 do
			releaseHold(holds[i], true)
		end
		holds = {}
		refreshState()
		GrabController.charging = false
		GrabController.charge = 0
	end)
end

return GrabController
