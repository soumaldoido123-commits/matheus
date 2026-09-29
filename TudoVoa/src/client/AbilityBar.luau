--!nonstrict
--[[
	AbilityBar: barra de habilidades (teclas 1-7 ou toque), recargas, mira das habilidades,
	corda do gancho e bolha do escudo (visiveis para todos).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local AbilityDefs = require(Shared:WaitForChild("AbilityDefs"))

local Store = require(script.Parent:WaitForChild("Store"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Fx = require(script.Parent:WaitForChild("Fx"))
local Movement = require(script.Parent:WaitForChild("Movement"))
local GrabController = require(script.Parent:WaitForChild("GrabController"))
local HUD = require(script.Parent:WaitForChild("UI"):WaitForChild("HUD"))
local Theme = require(script.Parent:WaitForChild("UI"):WaitForChild("Theme"))

local AbilityBar = {}

local player = Players.LocalPlayer
local P = Theme.P

local slots = {} -- [id] = { def, frame, cdFill, cdText, lock, keyLabel }
local cooldownEnd = {} -- [id] = os.clock()
local cooldownTotal = {}

local function unlocked(def): boolean
	return (Store.get("Level") or 1) >= def.level
end

-- Construcao da barra -----------------------------------------------------------------------------------------------------------------

local function buildSlot(def, order: number)
	local f = Theme.new("TextButton", {
		Name = "Slot_" .. def.id,
		Size = UDim2.fromOffset(68, 68),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		ClipsDescendants = true,
		Parent = HUD.abilityBar,
	})
	Theme.corner(f, 14)
	Theme.stroke(f, P.White, 2, 0.7)
	Theme.gradient(f, P.PanelLight, P.Ink, 90)
	local icon = Theme.text(f, { text = def.icon, size = 34, frame = UDim2.new(1, 0, 0, 44), position = UDim2.fromOffset(0, 6) })
	local key = Theme.text(f, { text = def.keyLabel, size = 13, font = Theme.Title, color = P.Accent, alignX = Enum.TextXAlignment.Left, frame = UDim2.fromOffset(20, 16), position = UDim2.fromOffset(6, 3), stroke = 0.4 })
	local name = Theme.text(f, { text = def.name, size = 9, font = Theme.Bold, color = P.Muted, frame = UDim2.new(1, -4, 0, 12), position = UDim2.new(0, 2, 1, -14), wrap = false })
	local cdFill = Theme.new("Frame", { Name = "Cooldown", Size = UDim2.fromScale(1, 0), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 5, Parent = f })
	local cdText = Theme.text(f, { text = "", size = 22, font = Theme.Title, z = 6, stroke = 0.3 })
	local lock = Theme.new("Frame", { Name = "Lock", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 10, 24), BackgroundTransparency = 0.25, ZIndex = 7, Parent = f })
	Theme.text(lock, { text = "🔒\nNv " .. def.level, size = 15, font = Theme.Title, z = 8 })
	f.Activated:Connect(function()
		AbilityBar.activate(def)
	end)
	f.MouseEnter:Connect(function()
		Theme.tween(f, 0.1, { Size = UDim2.fromOffset(72, 72) })
	end)
	f.MouseLeave:Connect(function()
		Theme.tween(f, 0.1, { Size = UDim2.fromOffset(68, 68) })
	end)
	slots[def.id] = { def = def, frame = f, cdFill = cdFill, cdText = cdText, lock = lock, icon = icon, key = key, name = name }
end

local function refreshLocks()
	for _, s in slots do
		s.lock.Visible = not unlocked(s.def)
	end
end

-- Ativacao ---------------------------------------------------------------------------------------------------------------------------------

local function startCooldown(def)
	local total = def.cooldown * Store.cooldownScale()
	cooldownEnd[def.id] = os.clock() + total
	cooldownTotal[def.id] = total
end

function AbilityBar.activate(def)
	local slot = slots[def.id]
	if not unlocked(def) then
		HUD.toast(def.name .. " libera no nível " .. def.level, "bad")
		Audio.ui("Error", 0.3)
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	if Movement.isRagdolled() then
		return
	end
	if cooldownEnd[def.id] and os.clock() < cooldownEnd[def.id] - 0.1 then
		Audio.ui("Error", 0.2, 1.4)
		if slot then
			Theme.tween(slot.frame, 0.08, { Rotation = 6 })
			task.delay(0.08, function()
				Theme.tween(slot.frame, 0.1, { Rotation = 0 })
			end)
		end
		return
	end

	local arg = nil
	if def.id == "pull" then
		local _, key = GrabController.aimTarget(def.range)
		if not key or (key.Parent and key.Parent:FindFirstChildOfClass("Humanoid")) then
			HUD.toast("Mire em um objeto para puxar", "bad")
			return
		end
		arg = key
	elseif def.id == "stasis" then
		local holds = GrabController.getHolds()
		if holds[1] and holds[1].kind == "object" then
			arg = holds[1].key
			GrabController.dropAll()
		else
			local _, key = GrabController.aimTarget(def.range)
			if not key then
				HUD.toast("Mire em um objeto (ou segure um) para congelar", "bad")
				return
			end
			arg = key
		end
	elseif def.id == "bubble" then
		local pt = GrabController.aimWorldPoint(def.range)
		if not pt then
			local cam = workspace.CurrentCamera
			pt = cam.CFrame.Position + cam.CFrame.LookVector * 40
		end
		arg = pt
	elseif def.id == "hook" then
		local pt = GrabController.aimWorldPoint(def.range)
		if not pt then
			HUD.toast("Mire em uma superfície para usar o gancho", "bad")
			return
		end
		arg = pt
	elseif def.id == "dash" then
		Movement.dash()
	elseif def.id == "shock" then
		Fx.shake(0.4)
	end

	Remotes.get("UseAbility"):FireServer(def.id, arg)
	startCooldown(def)
	Audio.ui("Charge", 0.35, 1.2 + (slot and slot.def.index or 1) * 0.06)
end

-- Efeitos remotos (todos veem) -------------------------------------------------------------------------------------------------------------

local ropes = {} -- [player] = { part, beam, a0 }
local shields = {} -- [player] = part

local function handOf(char: Model): BasePart?
	return char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
end

local function updateRope(p: Player)
	local point = p:GetAttribute("HookPoint")
	local rec = ropes[p]
	if typeof(point) == "Vector3" then
		local char = p.Character
		local hand = char and handOf(char)
		if not hand then
			return
		end
		if not rec then
			local anchor = Instance.new("Part")
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanQuery = false
			anchor.CanTouch = false
			anchor.Transparency = 1
			anchor.Size = Vector3.one
			anchor.Position = point
			anchor.Parent = workspace
			local a1 = Instance.new("Attachment")
			a1.Parent = anchor
			local a0 = Instance.new("Attachment")
			a0.Name = "TV_HookA0"
			a0.Parent = hand
			local beam = Instance.new("Beam")
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Width0 = 0.3
			beam.Width1 = 0.3
			beam.Segments = 1
			beam.FaceCamera = true
			beam.Color = ColorSequence.new(Color3.fromRGB(230, 230, 240))
			beam.LightEmission = 0.4
			beam.Parent = anchor
			-- gancho na ponta
			local tip = Instance.new("Part")
			tip.Shape = Enum.PartType.Ball
			tip.Size = Vector3.one * 1.4
			tip.Color = P.Accent
			tip.Material = Enum.Material.Neon
			tip.Anchored = true
			tip.CanCollide = false
			tip.CanQuery = false
			tip.Position = point
			tip.Parent = anchor
			rec = { part = anchor, a0 = a0 }
			ropes[p] = rec
			if p == player then
				Audio.ui("Throw", 0.4, 1.7)
				Fx.fovKick(5)
			end
		end
	elseif rec then
		rec.part:Destroy()
		if rec.a0.Parent then
			rec.a0:Destroy()
		end
		ropes[p] = nil
	end
end

local function updateShield(p: Player)
	local untilT = p:GetAttribute("ShieldUntil")
	local active = type(untilT) == "number" and untilT > workspace:GetServerTimeNow()
	local part = shields[p]
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if active and hrp then
		if not part then
			part = Instance.new("Part")
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.one * 9
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Material = Enum.Material.ForceField
			part.Color = P.Accent2
			part.Transparency = 0.35
			part.Parent = workspace
			shields[p] = part
		end
		part.CFrame = CFrame.new(hrp.Position)
		-- pisca perto do fim
		local remaining = untilT - workspace:GetServerTimeNow()
		part.Transparency = remaining < 1.5 and (0.35 + 0.4 * math.abs(math.sin(os.clock() * 14))) or 0.35
	elseif part then
		part:Destroy()
		shields[p] = nil
	end
end

local AFX = {}
function AFX.pull(_, pos)
	Fx.handlers.freeze(pos, 1)
end
function AFX.dash(userId, pos)
	Fx.handlers.bounce(pos, 1)
	Fx.handlers.shock(pos, 0.3)
	local _ = userId
end
function AFX.shield(_, pos)
	Fx.handlers.sparkle(pos)
end

function AbilityBar.init()
	for i, def in AbilityDefs.List do
		buildSlot(def, i)
	end
	refreshLocks()
	Store.Changed:Connect(function(key)
		if key == "Level" then
			refreshLocks()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		for _, def in AbilityDefs.List do
			if input.KeyCode == Enum.KeyCode[def.key] then
				AbilityBar.activate(def)
				return
			end
		end
	end)

	Remotes.get("AbilityFx").OnClientEvent:Connect(function(kind, userId, pos, extra)
		if kind == "fail" then
			-- o servidor recusou: libera a recarga local
			if type(extra) == "string" then
				cooldownEnd[extra] = nil
			end
			return
		end
		local h = AFX[kind]
		if h and typeof(pos) == "Vector3" then
			h(userId, pos, extra)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for id, s in slots do
			local endT = cooldownEnd[id]
			if endT and now < endT then
				local total = cooldownTotal[id] or 1
				local remain = endT - now
				s.cdFill.Size = UDim2.fromScale(1, math.clamp(remain / total, 0, 1))
				s.cdText.Text = remain >= 1 and tostring(math.ceil(remain)) or string.format("%.1f", remain)
			elseif s.cdFill.Size.Y.Scale > 0 then
				s.cdFill.Size = UDim2.fromScale(1, 0)
				s.cdText.Text = ""
				local st = s.frame:FindFirstChildOfClass("UIStroke")
				if st then
					st.Transparency = 0
					Theme.tween(st, 0.4, { Transparency = 0.7 })
				end
			end
		end
		for _, p in Players:GetPlayers() do
			updateRope(p)
			updateShield(p)
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		local r = ropes[p]
		if r then
			r.part:Destroy()
			ropes[p] = nil
		end
		local s = shields[p]
		if s then
			s:Destroy()
			shields[p] = nil
		end
	end)
	local _ = Config
end

return AbilityBar
