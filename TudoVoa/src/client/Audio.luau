--!nonstrict
--[[
	Audio (cliente): efeitos sonoros simples. Usa os sons do Roblox (Config.Sounds).
]]

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Store = require(script.Parent:WaitForChild("Store"))

local Audio = {}

local function enabled(): boolean
	return Store.setting("Sfx") ~= false
end

local function idOf(name: string): string?
	return Config.Sounds[name]
end

-- Som nao-posicional (interface / eventos do proprio jogador)
function Audio.ui(name: string, volume: number?, pitch: number?)
	if not enabled() then
		return
	end
	local id = idOf(name)
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 5)
end

-- Som no mundo (3D)
function Audio.at(name: string, position: Vector3, volume: number?, pitch: number?, maxDist: number?)
	if not enabled() then
		return
	end
	local id = idOf(name)
	if not id then
		return
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = workspace
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.7
	s.PlaybackSpeed = pitch or 1
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = maxDist or 220
	s.Parent = p
	s:Play()
	Debris:AddItem(p, 6)
end

-- Sons em loop presos a uma parte (vento, propulsor...). Retorna o Sound.
function Audio.loop(name: string, parent: Instance, volume: number?, pitch: number?): Sound?
	local id = idOf(name)
	if not id then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = true
	s.Volume = enabled() and (volume or 0.4) or 0
	s.PlaybackSpeed = pitch or 1
	s.RollOffMaxDistance = 160
	s.Parent = parent
	s:Play()
	return s
end

return Audio
