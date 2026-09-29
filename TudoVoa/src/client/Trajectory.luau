--!nonstrict
--[[
	Trajectory: previsao do arco do arremesso (bolinhas neon + anel onde vai cair).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Trajectory = {}

local GRAVITY = 196.2
local COUNT = 30
local STEP = 0.06

local pool = {}
local marker
local visible = false
local folder

local function ensure()
	if folder then
		return
	end
	folder = workspace:FindFirstChild("TV_ClientFx")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TV_ClientFx"
		folder.Parent = workspace
	end
	for i = 1, COUNT do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * (0.9 - i * 0.012)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Config.Palette.Accent
		p.Transparency = 1
		p.Parent = folder
		pool[i] = p
	end
	marker = Instance.new("Part")
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(0.3, 7, 7)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	marker.Material = Enum.Material.Neon
	marker.Color = Config.Palette.Pink
	marker.Transparency = 1
	marker.Parent = folder
end

function Trajectory.hide()
	if not visible then
		return
	end
	visible = false
	for _, p in pool do
		p.Transparency = 1
	end
	if marker then
		marker.Transparency = 1
	end
end

-- pos: posicao inicial, dir: direcao unitaria, speed: velocidade inicial
function Trajectory.update(pos: Vector3, dir: Vector3, speed: number, params: RaycastParams)
	ensure()
	visible = true
	local v = dir * speed
	local p = pos
	local landed = false
	for i = 1, COUNT do
		local dot = pool[i]
		if landed then
			dot.Transparency = 1
		else
			local nextV = v + Vector3.new(0, -GRAVITY * STEP, 0)
			local nextP = p + v * STEP
			local hit = workspace:Raycast(p, nextP - p, params)
			if hit then
				landed = true
				dot.Transparency = 1
				-- o cilindro tem o eixo no X: alinhar o eixo com a normal da superficie
				local n = hit.Normal
				local tangent = n:Cross(Vector3.xAxis)
				if tangent.Magnitude < 0.1 then
					tangent = n:Cross(Vector3.zAxis)
				end
				marker.CFrame = CFrame.fromMatrix(hit.Position + n * 0.15, n, tangent.Unit)
				marker.Transparency = 0.25
			else
				dot.CFrame = CFrame.new(nextP)
				dot.Transparency = 0.15 + i / COUNT * 0.6
				p = nextP
				v = nextV
			end
		end
	end
	if not landed then
		marker.Transparency = 1
	end
end

return Trajectory
