--!nonstrict
--[[
	Impact: o que acontece quando um objeto/pessoa arremessado bate em alguma coisa.
	Cada arremesso tem um "registro" (rec) criado pelo modulo Grab:
	  rec = { key, parts, model, thrower, kind, mass, behavior, t0, conns, ... }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Physics = require(script.Parent:WaitForChild("Physics"))
local Ragdoll = require(script.Parent:WaitForChild("Ragdoll"))
local Scoring = require(script.Parent:WaitForChild("Scoring"))
local Blasts = require(script.Parent:WaitForChild("Blasts"))
local Pickups = require(script.Parent:WaitForChild("Pickups"))

local Impact = {}

local function destroyToy(rec)
	rec.done = true
	if rec.model and rec.model.Parent then
		rec.model:Destroy()
	end
end

local Behaviors = {}

function Behaviors.splat(rec, other, speed, pos)
	if speed > 70 and rec.kind == "object" then
		Remotes.get("Fx"):FireAllClients("splat", pos, math.min(speed / 140, 1), { color = rec.key.Color })
		destroyToy(rec)
	end
end

function Behaviors.explosive(rec, other, speed, pos)
	if rec.kind ~= "object" or rec.fuse then
		return
	end
	if speed > 110 then
		rec.fuse = true
		Blasts.explode(pos, 30, 160, rec.thrower)
		destroyToy(rec)
		return
	end
	if speed > 35 then
		rec.fuse = true
		local spark = rec.key:FindFirstChild("Spark", true)
		if spark then
			spark.Enabled = true
		end
		Remotes.get("Fx"):FireAllClients("fuse", pos, 1, nil)
		task.delay(2.0, function()
			if rec.model and rec.model.Parent then
				Blasts.explode(rec.key.Position, 30, 160, rec.thrower)
				destroyToy(rec)
			end
		end)
	end
end

function Behaviors.rocket(rec, other, speed, pos)
	if rec.kind == "object" and speed > 30 and not rec.done then
		Blasts.explode(pos, 26, 145, rec.thrower)
		destroyToy(rec)
	end
end

function Behaviors.sticky(rec, other, speed, pos)
	if rec.kind ~= "object" or rec.stuck or speed < 28 then
		return
	end
	rec.stuck = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = rec.key
	w.Part1 = other
	w.Parent = rec.key
	rec.key.AssemblyLinearVelocity = Vector3.zero
	Remotes.get("Fx"):FireAllClients("splat", pos, 0.5, { color = rec.key.Color })
	task.delay(10, function()
		if w.Parent then
			w:Destroy()
		end
	end)
end

function Behaviors.pinata(rec, other, speed, pos)
	if rec.kind ~= "object" or speed < 26 then
		return
	end
	rec.pinHits = (rec.pinHits or 0) + 1
	local value = 10 + math.floor(speed / 10)
	if rec.pinHits >= 8 then
		Pickups.burst(pos + Vector3.new(0, 2, 0), value * 8, 26)
		Remotes.get("Fx"):FireAllClients("confetti", pos, 1.6, nil)
		destroyToy(rec)
	else
		Pickups.burst(pos + Vector3.new(0, 2, 0), value, 3)
		Remotes.get("Fx"):FireAllClients("confetti", pos, 0.6, nil)
	end
end

function Behaviors.gravity(rec, other, speed, pos)
	if rec.kind ~= "object" or rec.popped or speed < 26 then
		return
	end
	rec.popped = true
	Blasts.bubble(pos + Vector3.new(0, 6, 0), 24, 8.5, rec.thrower)
	destroyToy(rec)
end

function Behaviors.crystal(rec, other, speed, pos)
	if speed > 50 then
		Remotes.get("Fx"):FireAllClients("sparkle", pos, 1, nil)
	end
end

function Behaviors.squeak(rec, other, speed, pos)
	if speed > 24 then
		Remotes.get("Fx"):FireAllClients("squeak", pos, math.min(speed / 100, 1), nil)
	end
end

function Behaviors.bouncy(rec, other, speed, pos)
	if speed > 30 then
		Remotes.get("Fx"):FireAllClients("bounce", pos, math.min(speed / 120, 1), nil)
	end
end

function Behaviors.heavy(rec, other, speed, pos)
	if speed > 65 then
		Remotes.get("Fx"):FireAllClients("thud", pos, math.min(speed / 150, 1), nil)
	end
end

local function onTouch(rec, mine: BasePart, other: BasePart)
	if rec.done or not other.Parent then
		return
	end
	local now = os.clock()
	if now - rec.t0 < 0.08 then
		return
	end
	if rec.model and other:IsDescendantOf(rec.model) then
		return
	end
	if now - rec.lastTouch < 0.08 then
		return
	end
	if other.CollisionGroup == Config.Groups.Held then
		return
	end
	if other:IsDescendantOf(workspace:FindFirstChild("TV_Pickups") or workspace) and other.Name == "Coin" then
		return
	end

	local otherModel, otherPlayer = Physics.characterOf(other)
	-- nao se acerta logo apos arremessar
	if otherModel and rec.thrower and otherPlayer == rec.thrower and now - rec.t0 < 1.4 then
		return
	end

	local otherVel = other.AssemblyLinearVelocity
	local speed = (rec.key.AssemblyLinearVelocity - otherVel).Magnitude
	if speed < 16 then
		return
	end
	rec.lastTouch = now
	local pos = mine.Position

	if speed > 24 and now - rec.lastFx > 0.15 then
		rec.lastFx = now
		Remotes.get("Fx"):FireAllClients("impact", pos, math.min(speed / 150, 1), { mat = other.Material.Name, color = other.Color })
	end

	-- pessoas atingidas
	if otherModel and otherModel ~= rec.model then
		local momentum = rec.mass * speed
		if momentum >= 150 or speed >= 85 then
			if not (otherPlayer and Physics.isProtected(otherPlayer)) then
				local dir = Util.safeUnit(rec.key.AssemblyLinearVelocity, Vector3.yAxis)
				Ragdoll.knock(otherModel, math.clamp(momentum / 180, 1.4, 5))
				Physics.launch(otherModel, dir * math.min(speed * 0.6, 150) + Vector3.new(0, 26, 0))
				if otherPlayer then
					Remotes.get("Struck"):FireClient(otherPlayer, math.min(momentum / 500, 1), dir)
					Remotes.get("Fx"):FireAllClients("oof", pos, 1, nil)
				end
				Scoring.hit(rec.thrower, otherModel, otherPlayer, momentum)
			end
		end
	end

	local fn = Behaviors[rec.behavior]
	if fn then
		fn(rec, other, speed, pos, otherModel)
	end
end

function Impact.begin(rec)
	rec.conns = {}
	rec.lastTouch = 0
	rec.lastFx = 0
	for _, part in rec.parts do
		table.insert(
			rec.conns,
			part.Touched:Connect(function(other)
				onTouch(rec, part, other)
			end)
		)
	end
end

function Impact.finish(rec)
	rec.done = true
	if rec.conns then
		for _, c in rec.conns do
			c:Disconnect()
		end
		rec.conns = nil
	end
end

return Impact
