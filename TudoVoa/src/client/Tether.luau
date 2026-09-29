--!nonstrict
--[[
	Tether: desenha o cabo de energia de TODOS os jogadores (o servidor cria um ObjectValue
	"Hold" na pasta TV_Holds do personagem; aqui cada cliente monta o visual localmente).
	Cores/rastros vem dos atributos TetherColor/TetherTrail do jogador.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local Tether = {}

Tether.active = {} -- [character] = { { key = part, ... } }

local COLORS = {}
for _, c in Config.TetherColors do
	COLORS[c.id] = c
end

local beams = {} -- { beam, core, a0, a1, char, player, rainbow, key, emitter }

local function colorFor(player: Player?): (Color3, boolean)
	local id = player and player:GetAttribute("TetherColor") or "Roxo"
	local def = COLORS[id] or COLORS.Roxo
	return def.color, def.rainbow == true
end

local function handOf(char: Model): BasePart?
	return char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
end

local function makeBeam(char: Model, ov: ObjectValue)
	local key: BasePart? = ov.Value
	if not key or not key.Parent then
		return
	end
	local player = Players:GetPlayerFromCharacter(char)
	local hand = handOf(char)
	if not hand then
		return
	end
	local color, rainbow = colorFor(player)

	local a0 = hand:FindFirstChild("RightGripAttachment")
	local own0 = false
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name = "TV_TetherA0"
		a0.Parent = hand
		own0 = true
	end
	local a1 = Instance.new("Attachment")
	a1.Name = "TV_TetherA1"
	a1.Parent = key

	local beam = Instance.new("Beam")
	beam.Name = "TV_TetherBeam"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.55))
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 26
	beam.CurveSize0 = 2.5
	beam.CurveSize1 = -2.5
	beam.Width0 = 0.5
	beam.Width1 = 0.9
	beam.Transparency = NumberSequence.new(0.05)
	beam.Parent = hand

	local core = Instance.new("Beam")
	core.Name = "TV_TetherCore"
	core.Attachment0 = a0
	core.Attachment1 = a1
	core.Color = ColorSequence.new(Color3.new(1, 1, 1))
	core.LightEmission = 1
	core.LightInfluence = 0
	core.FaceCamera = true
	core.Segments = 26
	core.CurveSize0 = 2.5
	core.CurveSize1 = -2.5
	core.Width0 = 0.16
	core.Width1 = 0.3
	core.Transparency = NumberSequence.new(0.1)
	core.Parent = hand

	-- fagulhas no objeto
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "TV_TetherSparks"
	sparks.Rate = 14
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Speed = NumberRange.new(2, 8)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	sparks.LightEmission = 1
	sparks.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	sparks.Parent = a1

	-- contorno colorido no objeto/pessoa segurado
	local hl = Instance.new("Highlight")
	hl.Name = "TV_HeldOutline"
	hl.Adornee = (key.Parent and key.Parent:IsA("Model") and key.Parent) or key
	hl.FillTransparency = 1
	hl.OutlineColor = color
	hl.OutlineTransparency = 0.15
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = key

	local rec = { beam = beam, core = core, a0 = a0, own0 = own0, a1 = a1, sparks = sparks, hl = hl, char = char, player = player, rainbow = rainbow, key = key, ov = ov, t0 = os.clock() }
	table.insert(beams, rec)
	local list = Tether.active[char]
	if not list then
		list = {}
		Tether.active[char] = list
	end
	table.insert(list, rec)
	return rec
end

local function destroyBeam(rec)
	local i = table.find(beams, rec)
	if i then
		table.remove(beams, i)
	end
	local list = Tether.active[rec.char]
	if list then
		local j = table.find(list, rec)
		if j then
			table.remove(list, j)
		end
		if #list == 0 then
			Tether.active[rec.char] = nil
		end
	end
	for _, o in { rec.beam, rec.core, rec.a1, rec.sparks, rec.hl } do
		if o and o.Parent then
			o:Destroy()
		end
	end
	if rec.own0 and rec.a0 and rec.a0.Parent then
		rec.a0:Destroy()
	end
end

local function watchCharacter(char: Model)
	local function hookFolder(folder: Instance)
		for _, ov in folder:GetChildren() do
			if ov:IsA("ObjectValue") then
				makeBeam(char, ov)
			end
		end
		folder.ChildAdded:Connect(function(ov)
			if ov:IsA("ObjectValue") then
				task.defer(makeBeam, char, ov)
			end
		end)
		folder.ChildRemoved:Connect(function(ov)
			for _, rec in table.clone(beams) do
				if rec.ov == ov then
					destroyBeam(rec)
				end
			end
		end)
	end
	local existing = char:FindFirstChild("TV_Holds")
	if existing then
		hookFolder(existing)
	end
	char.ChildAdded:Connect(function(c)
		if c.Name == "TV_Holds" then
			hookFolder(c)
		end
	end)
end

local function watchPlayer(player: Player)
	if player.Character then
		watchCharacter(player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
end

function Tether.isHolding(char: Model): boolean
	return Tether.active[char] ~= nil
end

function Tether.init()
	for _, p in Players:GetPlayers() do
		watchPlayer(p)
	end
	Players.PlayerAdded:Connect(watchPlayer)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for i = #beams, 1, -1 do
			local rec = beams[i]
			if not rec.key.Parent or not rec.beam.Parent then
				destroyBeam(rec)
			else
				local age = t - rec.t0
				local pulse = 0.5 + math.sin(t * 9) * 0.08
				local grow = math.min(1, age * 6)
				rec.beam.Width0 = pulse * grow
				rec.beam.Width1 = (pulse + 0.35) * grow
				rec.beam.CurveSize0 = math.sin(t * 5) * 2.4
				rec.beam.CurveSize1 = math.cos(t * 4.3) * 2.4
				rec.core.CurveSize0 = rec.beam.CurveSize0
				rec.core.CurveSize1 = rec.beam.CurveSize1
				if rec.rainbow then
					local c0 = Util.hue(t * 0.4, 0.75, 1)
					local c1 = Util.hue(t * 0.4 + 0.3, 0.75, 1)
					rec.beam.Color = ColorSequence.new(c0, c1)
					rec.sparks.Color = ColorSequence.new(c0, c1)
					rec.hl.OutlineColor = c0
				end
			end
		end
	end)
end

return Tether
