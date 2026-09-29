--!nonstrict
--[[
	DecorAnim: anima o cenario no CLIENTE (o servidor so marca com tags):
	  TV_Spin (gira), TV_Bob (flutua), TV_Sway (balanca), TV_Pulse (luz pulsante)
	Somente o que esta perto da camera e animado (economia de CPU).
]]

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local DecorAnim = {}

local T = Config.Tags
local recs = {} -- [inst] = rec
local active = {} -- lista de recs perto da camera
local NEAR = 300

local function pivotOf(inst: Instance): CFrame
	if inst:IsA("Model") then
		return inst:GetPivot()
	end
	return inst.CFrame
end

local function setPivot(inst: Instance, cf: CFrame)
	if inst:IsA("Model") then
		inst:PivotTo(cf)
	else
		inst.CFrame = cf
	end
end

local function approx(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 0.03 and a.LookVector:Dot(b.LookVector) > 0.9995 and a.UpVector:Dot(b.UpVector) > 0.9995
end

local function ensureRec(inst: Instance)
	local r = recs[inst]
	if not r then
		if not (inst:IsA("BasePart") or inst:IsA("Model")) then
			return nil
		end
		local base = pivotOf(inst)
		r = { inst = inst, base = base, last = base, angle = 0 }
		recs[inst] = r
	end
	return r
end

local function readAttrs(r)
	local inst = r.inst
	r.spin = CollectionService:HasTag(inst, T.Spin)
	r.bob = CollectionService:HasTag(inst, T.Bob)
	r.sway = CollectionService:HasTag(inst, T.Sway)
	r.pulse = CollectionService:HasTag(inst, T.Pulse)
	if r.spin then
		r.axis = inst:GetAttribute("SpinAxis") or "Y"
		r.speed = math.rad(inst:GetAttribute("SpinSpeed") or 30)
	end
	if r.bob then
		r.bobAmp = inst:GetAttribute("BobAmp") or 1
		r.bobPeriod = inst:GetAttribute("BobPeriod") or 3
		r.bobPhase = inst:GetAttribute("BobPhase") or 0
	end
	if r.sway then
		r.swayDeg = math.rad(inst:GetAttribute("SwayDeg") or 3)
		r.swayPeriod = inst:GetAttribute("SwayPeriod") or 4
		r.swayPhase = inst:GetAttribute("SwayPhase") or 0
	end
	if r.pulse then
		r.pMin = inst:GetAttribute("PulseMin") or 0.5
		r.pMax = inst:GetAttribute("PulseMax") or 2
		r.pPeriod = inst:GetAttribute("PulsePeriod") or 2
		r.light = inst:IsA("BasePart") and inst:FindFirstChildWhichIsA("PointLight") or inst:FindFirstChildWhichIsA("PointLight", true)
	end
end

local function onTagged(inst: Instance)
	local r = ensureRec(inst)
	if r then
		r.dirty = true
	end
end

local function onUntagged(inst: Instance)
	local r = recs[inst]
	if r then
		if not (CollectionService:HasTag(inst, T.Spin) or CollectionService:HasTag(inst, T.Bob) or CollectionService:HasTag(inst, T.Sway) or CollectionService:HasTag(inst, T.Pulse)) then
			recs[inst] = nil
		else
			r.dirty = true
		end
	end
end

local function refreshActive()
	local cam = workspace.CurrentCamera
	local cpos = cam.CFrame.Position
	table.clear(active)
	for inst, r in recs do
		if not inst.Parent then
			recs[inst] = nil
		else
			if r.dirty then
				readAttrs(r)
				r.dirty = false
			end
			if (r.base.Position - cpos).Magnitude < NEAR then
				table.insert(active, r)
			end
		end
	end
end

function DecorAnim.init()
	for _, tag in { T.Spin, T.Bob, T.Sway, T.Pulse } do
		for _, inst in CollectionService:GetTagged(tag) do
			onTagged(inst)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(onTagged)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(onUntagged)
	end

	-- luzes dos postes: acendem a noite
	local Lighting = game:GetService("Lighting")
	local lamps = {}
	local function trackLamp(p)
		if p:IsA("BasePart") then
			table.insert(lamps, p)
		end
	end
	for _, p in CollectionService:GetTagged("TV_Lamp") do
		trackLamp(p)
	end
	CollectionService:GetInstanceAddedSignal("TV_Lamp"):Connect(trackLamp)
	local lastNight = nil
	local function updateLamps()
		local t = Lighting.ClockTime
		local night = t < 5.8 or t > 18.2
		if night == lastNight then
			return
		end
		lastNight = night
		for i = #lamps, 1, -1 do
			local p = lamps[i]
			if not p.Parent then
				table.remove(lamps, i)
			else
				p.Material = night and Enum.Material.Neon or Enum.Material.SmoothPlastic
				local l = p:FindFirstChildWhichIsA("PointLight")
				if l then
					l.Enabled = night
				end
			end
		end
	end

	local acc = 0
	local accLamps = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		accLamps += dt
		if accLamps > 2 then
			accLamps = 0
			updateLamps()
		end
		if acc > 0.4 then
			acc = 0
			refreshActive()
		end
		local t = os.clock()
		for _, r in active do
			local inst = r.inst
			if inst.Parent then
				-- se o servidor mexeu no objeto (ex.: moedas), o novo pivo vira a base
				local cur = pivotOf(inst)
				if not approx(cur, r.last) then
					r.base = cur
				end
				local cf = r.base
				if r.bob then
					local off = math.sin(t * (math.pi * 2 / r.bobPeriod) + r.bobPhase) * r.bobAmp
					cf = cf + Vector3.new(0, off, 0)
				end
				if r.spin then
					r.angle += r.speed * dt
					if r.axis == "X" then
						cf = cf * CFrame.Angles(r.angle, 0, 0)
					elseif r.axis == "Z" then
						cf = cf * CFrame.Angles(0, 0, r.angle)
					else
						cf = cf * CFrame.Angles(0, r.angle, 0)
					end
				end
				if r.sway then
					local a = t * (math.pi * 2 / r.swayPeriod) + r.swayPhase
					cf = cf * CFrame.Angles(math.sin(a) * r.swayDeg, 0, math.cos(a * 0.8) * r.swayDeg * 0.7)
				end
				if r.bob or r.spin or r.sway then
					setPivot(inst, cf)
					r.last = cf
				end
				if r.pulse and r.light and r.light.Parent then
					local k = (math.sin(t * (math.pi * 2 / r.pPeriod)) + 1) / 2
					r.light.Brightness = r.pMin + (r.pMax - r.pMin) * k
				end
			end
		end
	end)
end

return DecorAnim
