--!nonstrict
--[[
	ToyPassive: comportamentos que funcionam o tempo todo (nao so quando arremessado):
	  trampoline  joga para cima quem/o que cair em cima
	  flop        o peixe pula sozinho no chao
	  magnet      o ima puxa objetos de metal por perto
]]

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Physics = require(script.Parent:WaitForChild("Physics"))

local ToyPassive = {}

local flops = {} -- [body] = proximo pulo
local magnets = {} -- [body] = true

local METAL_TOYS = { barril = true, bigorna = true, foguete = true, dinamite = false, ima = false }

local function attachTrampoline(model: Model)
	local body = model.PrimaryPart
	local pad = model:FindFirstChild("Pad")
	if not body or not pad then
		return
	end
	local last = {}
	pad.Touched:Connect(function(other)
		if not other.Parent then
			return
		end
		local normal = body.CFrame.RightVector -- eixo X do corpo = "para cima" do trampolim
		local rel = other.Position - pad.Position
		if rel:Dot(normal) < 0 then
			return
		end
		local now = os.clock()
		local charModel, player = Physics.characterOf(other)
		if charModel then
			if last[charModel] and now - last[charModel] < 0.45 then
				return
			end
			last[charModel] = now
			local root = Physics.rootOfCharacter(charModel)
			if not root then
				return
			end
			local v = root.AssemblyLinearVelocity
			local vy = 105 + math.max(0, -v.Y) * 0.5
			Physics.launch(charModel, Vector3.new(v.X * 0.5, vy, v.Z * 0.5))
			Remotes.get("Fx"):FireAllClients("bounce", pad.Position, 1, nil)
			if player then
				Remotes.get("Struck"):FireClient(player, 0.25, Vector3.yAxis)
			end
		else
			local root = other.AssemblyRootPart or other
			if root.Anchored or root:GetAttribute("HeldBy") or root == body or root:IsDescendantOf(model) then
				return
			end
			if last[root] and now - last[root] < 0.3 then
				return
			end
			last[root] = now
			local v = root.AssemblyLinearVelocity
			if v.Y < 25 then
				pcall(function()
					root:SetNetworkOwner(nil)
				end)
				root.AssemblyLinearVelocity = Vector3.new(v.X * 0.6, 88, v.Z * 0.6)
				Remotes.get("Fx"):FireAllClients("bounce", pad.Position, 0.7, nil)
			end
		end
	end)
end

function ToyPassive.attach(model: Model)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local behavior = body:GetAttribute("Behavior")
	if behavior == "trampoline" then
		attachTrampoline(model)
	elseif behavior == "flop" then
		flops[body] = os.clock() + 2 + math.random() * 3
		body.Destroying:Once(function()
			flops[body] = nil
		end)
	elseif behavior == "magnet" then
		magnets[body] = true
		body.Destroying:Once(function()
			magnets[body] = nil
		end)
	end
end

local function step()
	local now = os.clock()
	for body, at in flops do
		if not body.Parent then
			flops[body] = nil
		elseif now >= at then
			flops[body] = now + 1.5 + math.random() * 3
			if not body:GetAttribute("HeldBy") and not CollectionService:HasTag(body, Config.Tags.Airborne) then
				-- so pula se estiver mais ou menos no chao (parado)
				if body.AssemblyLinearVelocity.Magnitude < 8 then
					local dir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
					dir = Util.safeUnit(dir, Vector3.xAxis)
					Physics.impulse(body, (dir * 22 + Vector3.new(0, 44, 0)) * body.AssemblyMass)
					body.AssemblyAngularVelocity = Util.randomUnit() * 6
				end
			end
		end
	end

	for body in magnets do
		if not body.Parent then
			magnets[body] = nil
		elseif not body:GetAttribute("HeldBy") and body.AssemblyLinearVelocity.Magnitude < 6 then
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { body.Parent }
			for _, part in workspace:GetPartBoundsInRadius(body.Position, 34, params) do
				if not part.Anchored and part.Name == "Body" and part.AssemblyRootPart == part then
					local id = part:GetAttribute("ToyId")
					if id and METAL_TOYS[id] and not part:GetAttribute("HeldBy") then
						local off = body.Position - part.Position
						local d = off.Magnitude
						if d > 5 then
							local pull = Util.saturate(1 - d / 34)
							Physics.impulse(part, off.Unit * part.AssemblyMass * (18 + 40 * pull))
						end
					end
				end
			end
		end
	end
end

function ToyPassive.init()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.2 then
			acc = 0
			step()
		end
	end)
end

return ToyPassive
