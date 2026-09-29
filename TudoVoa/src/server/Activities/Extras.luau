--!nonstrict
--[[
	Extras: acoes do cliente que precisam de validacao no servidor (Remotes.ActivityAction).
	  boomerang/catch  pegar o bumerangue de volta rende moedas
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Server = script.Parent.Parent
local Data = require(Server:WaitForChild("Data"))
local Quests = require(Server:WaitForChild("Quests"))

local Extras = {}

local handlers = {}

function handlers.boomerang(player, action, part)
	if action ~= "catch" or typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end
	if part:GetAttribute("Behavior") ~= "boomerang" or part:GetAttribute("Thrower") ~= player.UserId then
		return
	end
	if part:GetAttribute("Caught") then
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - part.Position).Magnitude > 18 then
		return
	end
	part:SetAttribute("Caught", true)
	task.delay(20, function()
		if part.Parent then
			part:SetAttribute("Caught", nil)
		end
	end)
	if Data.isLoaded(player) then
		Quests.report(player, "boomerang", 1)
		Data.addCoins(player, 15, "pegou o bumerangue")
		Data.addXP(player, 10)
		Remotes.get("ScorePopup"):FireClient(player, part.Position + Vector3.new(0, 3, 0), "PEGOU! +15", Config.Palette.Accent)
		Remotes.get("Fx"):FireAllClients("sparkle", part.Position, 1, nil)
	end
end

local lastEmote = {}
local EMOTES = { wave = true, cheer = true, dance = true }

function handlers.emote(player, action)
	if type(action) ~= "string" or not EMOTES[action] then
		return
	end
	local now = os.clock()
	if lastEmote[player] and now - lastEmote[player] < 0.8 then
		return
	end
	lastEmote[player] = now
	local char = player.Character
	if char then
		char:SetAttribute("Emote", action)
		char:SetAttribute("EmoteT", workspace:GetServerTimeNow())
	end
end

function Extras.init()
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		lastEmote[p] = nil
	end)
	Remotes.get("ActivityAction").OnServerEvent:Connect(function(player, activity, action, arg)
		if type(activity) ~= "string" or type(action) ~= "string" then
			return
		end
		local h = handlers[activity]
		if h then
			local ok, err = pcall(h, player, action, arg)
			if not ok then
				warn("[Extras] erro:", err)
			end
		end
	end)
end

return Extras
