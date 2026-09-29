--!nonstrict
--[[
	Blasts: explosoes, ondas de choque e bolhas de gravidade zero.
]]

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Physics = require(script.Parent:WaitForChild("Physics"))
local Ragdoll = require(script.Parent:WaitForChild("Ragdoll"))
local Scoring = require(script.Parent:WaitForChild("Scoring"))

local Blasts = {}

local GRAVITY = 196.2

local function overlapParams(): OverlapParams
	local p = OverlapParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	local pickups = workspace:FindFirstChild("TV_Pickups")
	if pickups then
		table.insert(ignore, pickups)
	end
	p.FilterDescendantsInstances = ignore
	return p
end

-- Empurra tudo em volta de um ponto.
-- power: velocidade final (studs/s) no centro; falloff linear ate o raio.
-- opts: { credit = Player?, knock = seg?, skip = Model?, fx = "explosion"|"shock"|false, lift = number?, noCharacters = bool? }
function Blasts.push(position: Vector3, radius: number, power: number, opts: { [string]: any }?)
	opts = opts or {}
	local credit: Player? = opts.credit
	local lift = opts.lift or 0.55
	if opts.fx ~= false then
		Remotes.get("Fx"):FireAllClients(opts.fx or "explosion", position, radius / 26, nil)
	end

	local parts = workspace:GetPartBoundsInRadius(position, radius, overlapParams())
	local seen = {}
	for _, part in parts do
		if part.Anchored then
			continue
		end
		local model, player = Physics.characterOf(part)
		if model and opts.noCharacters then
			continue
		end
		if model then
			if seen[model] or model == opts.skip then
				continue
			end
			seen[model] = true
			local root = Physics.rootOfCharacter(model)
			if not root then
				continue
			end
			if player and Physics.isProtected(player) then
				continue
			end
			local off = root.Position - position
			local dist = off.Magnitude
			local fall = Util.saturate(1 - dist / radius)
			local dir = Util.safeUnit(off + Vector3.new(0, radius * lift, 0), Vector3.yAxis)
			Ragdoll.knock(model, opts.knock or (1.6 + 2.2 * fall))
			Physics.launch(model, dir * (power * (0.35 + 0.65 * fall)))
			if player then
				Remotes.get("Struck"):FireClient(player, fall, dir)
			end
			if credit then
				Scoring.hit(credit, model, player, power)
			end
		else
			local root = part.AssemblyRootPart or part
			if seen[root] then
				continue
			end
			seen[root] = true
			if root:GetAttribute("HeldBy") or root.Anchored then
				continue
			end
			local mass = root.AssemblyMass
			local off = root.Position - position
			local dist = off.Magnitude
			local fall = Util.saturate(1 - dist / radius)
			local dir = Util.safeUnit(off + Vector3.new(0, radius * lift, 0), Vector3.yAxis)
			Physics.impulse(root, dir * (mass * power * (0.3 + 0.7 * fall)))
			root.AssemblyAngularVelocity = Util.randomUnit() * 8 * fall
		end
	end
end

-- Explosao "de verdade": empurra + quebra brinquedos explosivos proximos em cadeia
function Blasts.explode(position: Vector3, radius: number, power: number, credit: Player?)
	Blasts.push(position, radius, power, { credit = credit, fx = "explosion" })
end

-- Onda de choque de habilidade (sem "boom" grande, mais anel de energia)
function Blasts.shock(player: Player, position: Vector3, radius: number, power: number)
	local model = player.Character
	Blasts.push(position, radius, power, { credit = player, skip = model, fx = "shock", knock = 2.2 })
end

-- Bolha anti-gravidade ------------------------------------------------------------------------------

local bubbles = {} -- lista de { part, center, radius, expire, forces = { [part] = VectorForce } }

function Blasts.bubble(position: Vector3, radius: number, duration: number, owner: Player?)
	local shell = Instance.new("Part")
	shell.Name = "TV_Bubble"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.one * radius * 2
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanTouch = false
	shell.CanQuery = false
	shell.CastShadow = false
	shell.Material = Enum.Material.ForceField
	shell.Color = Color3.fromRGB(160, 120, 255)
	shell.Transparency = 0.35
	shell.CFrame = CFrame.new(position)
	shell.Parent = workspace
	shell:SetAttribute("Owner", owner and owner.UserId or 0)
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(170, 130, 255)
	pl.Range = radius * 1.4
	pl.Brightness = 1.2
	pl.Shadows = false
	pl.Parent = shell

	shell.Size = Vector3.one * 2
	Util.tween(shell, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.one * radius * 2 })
	Remotes.get("Fx"):FireAllClients("bubble", position, radius / 26, nil)

	table.insert(bubbles, {
		part = shell,
		center = position,
		radius = radius,
		expire = os.clock() + duration,
		forces = {},
	})
end

local function clearForce(rec, part)
	local f = rec.forces[part]
	if f then
		if f.force.Parent then
			f.force:Destroy()
		end
		if f.att.Parent then
			f.att:Destroy()
		end
		rec.forces[part] = nil
	end
end

local function bubbleStep()
	local now = os.clock()
	local i = 1
	while i <= #bubbles do
		local rec = bubbles[i]
		if now >= rec.expire or not rec.part.Parent then
			for part in rec.forces do
				clearForce(rec, part)
			end
			if rec.part.Parent then
				rec.part.Anchored = true
				Util.tween(rec.part, 0.4, { Size = Vector3.one * 1, Transparency = 1 })
				Debris:AddItem(rec.part, 0.5)
			end
			table.remove(bubbles, i)
		else
			local inside = {}
			for _, part in workspace:GetPartBoundsInRadius(rec.center, rec.radius, overlapParams()) do
				if not part.Anchored and part.AssemblyRootPart == part and part.Name ~= "TV_Bubble" then
					inside[part] = true
					if not rec.forces[part] then
						local att = Instance.new("Attachment")
						att.Name = "TV_BubbleAtt"
						att.Parent = part
						local vf = Instance.new("VectorForce")
						vf.Name = "TV_BubbleForce"
						vf.Attachment0 = att
						vf.RelativeTo = Enum.ActuatorRelativeTo.World
						vf.ApplyAtCenterOfMass = true
						vf.Force = Vector3.new(0, part.AssemblyMass * GRAVITY * 0.94, 0)
						vf.Parent = part
						rec.forces[part] = { force = vf, att = att }
					else
						rec.forces[part].force.Force = Vector3.new(0, part.AssemblyMass * GRAVITY * 0.94, 0)
					end
					-- personagens dentro da bolha: o cliente reduz a gravidade
					local model, player = Physics.characterOf(part)
					if model and player then
						player:SetAttribute("LowGravUntil", workspace:GetServerTimeNow() + 0.6)
					end
				end
			end
			for part in rec.forces do
				if not inside[part] then
					clearForce(rec, part)
				end
			end
			i += 1
		end
	end
end

function Blasts.init()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.2 then
			acc = 0
			bubbleStep()
		end
	end)
end

return Blasts
