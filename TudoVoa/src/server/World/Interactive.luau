--!nonstrict
--[[
	Interactive: objetos interativos do mundo.
	  cannon   canhao que lanca o jogador em arco balistico ate um destino
	  portal   pad que teleporta
	  chest    bau de moedas com recarga por jogador
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Build = require(script.Parent:WaitForChild("Build"))
local Server = script.Parent.Parent
local Data = require(Server:WaitForChild("Data"))
local Physics = require(Server:WaitForChild("Physics"))
local Ragdoll = require(Server:WaitForChild("Ragdoll"))
local Pickups = require(Server:WaitForChild("Pickups"))

local Interactive = {}

local M = Enum.Material
local P = Config.Palette
local GRAVITY = 196.2

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Velocidade inicial para ir de "from" a "to" com angulo fixo (graus). Retorna Vector3 ou nil.
function Interactive.ballistic(from: Vector3, to: Vector3, angleDeg: number): Vector3?
	local off = to - from
	local flat = Vector3.new(off.X, 0, off.Z)
	local D = flat.Magnitude
	if D < 1 then
		return nil
	end
	local th = math.rad(angleDeg)
	local cos, tan = math.cos(th), math.tan(th)
	local denom = 2 * cos * cos * (D * tan - off.Y)
	if denom <= 0 then
		return nil
	end
	local v = math.sqrt(GRAVITY * D * D / denom)
	local dir = flat.Unit
	return dir * (v * cos) + Vector3.new(0, v * math.sin(th), 0)
end

-- Canhao. target: posicao de destino (Vector3). Retorna o modelo.
function Interactive.cannon(parent: Instance, pos: Vector3, target: Vector3, label: string, opts: { [string]: any }?)
	opts = opts or {}
	local angle = opts.angle or 52
	local y = Build.y(pos.X, pos.Z)
	local origin = Vector3.new(pos.X, y, pos.Z)
	local look = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
	local cf = CFrame.lookAt(origin, origin + look.Unit)
	local m = Build.model(parent, "Cannon")

	Build.foundation(m, cf, Vector3.new(12, 1, 12), rgb(90, 90, 110), M.Slate)
	-- base + rodas
	local base = Build.block(m, cf * CFrame.new(0, 2.6, 0), Vector3.new(7, 2.6, 8), rgb(120, 82, 54), M.Wood)
	for _, sx in { -3.7, 3.7 } do
		Build.cyl(m, cf * CFrame.new(sx, 3, 0) * CFrame.Angles(0, 0, math.pi / 2), 1.2, 6, rgb(90, 60, 40), M.Wood)
		Build.cyl(m, cf * CFrame.new(sx, 3, 0) * CFrame.Angles(0, 0, math.pi / 2), 1.4, 1.6, rgb(180, 180, 190), M.Metal)
	end
	-- cano inclinado
	local barrelCF = cf * CFrame.new(0, 5.4, -0.6) * CFrame.Angles(math.rad(angle), 0, 0)
	local tube = Build.cyl(m, barrelCF * CFrame.new(0, 0, -3.2) * CFrame.Angles(math.pi / 2, 0, 0), 9, 4.6, opts.color or rgb(70, 74, 100), M.Metal)
	Build.cyl(m, barrelCF * CFrame.new(0, 0, -7.6) * CFrame.Angles(math.pi / 2, 0, 0), 1.4, 5.6, rgb(230, 190, 60), M.Metal, { collide = false })
	Build.ball(m, barrelCF * CFrame.new(0, 0, 1.2), 4.8, opts.color or rgb(70, 74, 100), M.Metal, { collide = false })
	local sign = Build.block(m, cf * CFrame.new(0, 10.5, 4.6), Vector3.new(12, 2.4, 0.4), rgb(36, 34, 80), M.SmoothPlastic)
	Build.label(sign, label, { color = P.Accent })
	local light = Build.ball(m, cf * CFrame.new(0, 7.4, 4.3), 1.2, P.Accent2, M.Neon, { collide = false })
	Build.pulse(light, 0.6, 2.4, 1.1)
	Build.light(light, P.Accent2, 1.2, 16, false)

	local pp = Build.prompt(base, "Disparar!", "Canhão: " .. label, "cannon", 0.6)
	pp.MaxActivationDistance = 13
	local last = {}
	pp.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then
			return
		end
		local now = os.clock()
		if last[player] and now - last[player] < 3 then
			return
		end
		last[player] = now
		local from = origin + Vector3.new(0, 8, 0)
		local vel = Interactive.ballistic(from, target, angle)
		if not vel then
			return
		end
		char:PivotTo(CFrame.new(from + look.Unit * 2))
		Ragdoll.enable(char, { duration = 3.2 })
		Physics.launch(char, vel, Vector3.new(4, 2, 3))
		Remotes.get("Fx"):FireAllClients("cannon", from, 1, { dir = vel.Unit })
		Remotes.get("Struck"):FireClient(player, 0.6, vel.Unit)
	end)
	m.PrimaryPart = base
	_ = tube
	return m
end

-- Portal de retorno: quem pisa vai para a praca
function Interactive.portal(parent: Instance, pos: Vector3, destination: Vector3, label: string, color: Color3?)
	local c = color or P.Purple
	local m = Build.model(parent, "Portal")
	local base = Build.cyl(m, CFrame.new(pos), 1, 12, rgb(40, 40, 90), M.Metal)
	local disc = Build.cyl(m, CFrame.new(pos + Vector3.new(0, 0.7, 0)), 0.4, 10, c, M.Neon, { name = "PortalDisc" })
	Build.pulse(disc, 0.8, 2.4, 1.6)
	local pillar = Build.cyl(m, CFrame.new(pos + Vector3.new(0, 8, 0)), 16, 5, c, M.Neon, { collide = false, transparency = 0.8, shadow = false })
	pillar.CanQuery = false
	Build.billboard(disc, label, { color = c, offset = Vector3.new(0, 7, 0) })
	local att = Instance.new("Attachment")
	att.Parent = disc
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 20
	pe.Lifetime = NumberRange.new(2, 3)
	pe.Speed = NumberRange.new(6, 12)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.SpreadAngle = Vector2.new(6, 6)
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(c, Color3.new(1, 1, 1))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	pe.Parent = att
	local last = {}
	disc.Touched:Connect(function(other)
		local char = other:FindFirstAncestorOfClass("Model")
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player then
			return
		end
		local now = os.clock()
		if last[player] and now - last[player] < 2 then
			return
		end
		last[player] = now
		char:PivotTo(CFrame.new(destination))
		Remotes.get("Fx"):FireAllClients("teleport", destination, 1, nil)
	end)
	m.PrimaryPart = base
	return m
end

-- Bau de moedas (recarga por jogador em segundos)
function Interactive.chest(parent: Instance, pos: Vector3, name: string, coins: number, cooldown: number, color: Color3?)
	local c = color or P.Accent
	local m = Build.model(parent, "Chest")
	local cf = CFrame.new(pos)
	local body = Build.block(m, cf * CFrame.new(0, 2, 0), Vector3.new(6, 4, 4), rgb(150, 96, 56), M.Wood)
	Build.cyl(m, cf * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.pi / 2), 6, 4.2, rgb(170, 110, 64), M.Wood, { collide = false })
	Build.block(m, cf * CFrame.new(0, 2.6, 2.05), Vector3.new(1.2, 1.6, 0.3), c, M.Metal, { collide = false })
	local glow = Build.ball(m, cf * CFrame.new(0, 6.6, 0), 2, c, M.Neon, { collide = false })
	Build.bob(glow, 0.5, 2)
	Build.light(glow, c, 2, 26, false)
	Build.billboard(glow, "💰 " .. name, { color = c, offset = Vector3.new(0, 3, 0) })
	local pp = Build.prompt(body, "Abrir", name, "chest", 0.5)
	local last = {}
	pp.Triggered:Connect(function(player)
		if not Data.isLoaded(player) then
			return
		end
		local now = os.clock()
		if last[player] and now - last[player] < cooldown then
			Remotes.get("Notify"):FireClient(player, "O baú está vazio. Volte mais tarde!", "bad")
			return
		end
		last[player] = now
		Pickups.burst(pos + Vector3.new(0, 5, 0), coins, math.clamp(coins // 12, 6, 30))
		Data.addXP(player, math.floor(coins / 6))
		Remotes.get("Fx"):FireAllClients("confetti", pos + Vector3.new(0, 5, 0), 1.2, nil)
		Remotes.get("Announce"):FireClient(player, name, "+" .. coins .. " moedas!", 2, c)
	end)
	m.PrimaryPart = body
	return m
end

-- Placa de madeira com texto (em pe)
function Interactive.signpost(parent: Instance, pos: Vector3, text: string, facing: Vector3?)
	local y = Build.y(pos.X, pos.Z)
	local cf = CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(pos.X, y, pos.Z) + (facing or Vector3.zAxis))
	local m = Build.model(parent, "Signpost")
	Build.block(m, cf * CFrame.new(-4, 4, 0), Vector3.new(0.8, 8, 0.8), rgb(120, 84, 52), M.Wood)
	Build.block(m, cf * CFrame.new(4, 4, 0), Vector3.new(0.8, 8, 0.8), rgb(120, 84, 52), M.Wood)
	local board = Build.block(m, cf * CFrame.new(0, 8.4, 0), Vector3.new(11, 4.4, 0.6), rgb(44, 40, 96), M.SmoothPlastic)
	Build.label(board, text, { color = P.White })
	return m
end

_ = TweenService
return Interactive
