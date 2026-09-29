--!nonstrict
--[[
	EventBanner: faixa com o evento do mundo em andamento + contagem regressiva.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Theme = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Theme"))
local HUD = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("HUD"))

local EventBanner = {}

local P = Theme.P
local frame, label
local current = nil

function EventBanner.init()
	frame = Theme.panel(HUD.gui, {
		size = UDim2.fromOffset(380, 42),
		position = UDim2.new(0.5, 0, 0, 200),
		anchor = Vector2.new(0.5, 0),
		visible = false,
		name = "EventBanner",
		color = Color3.fromRGB(40, 60, 100),
		color2 = P.Ink,
		strokeColor = P.Accent2,
		strokeTransparency = 0.35,
		radius = 21,
	})
	label = Theme.text(frame, { text = "", font = Theme.Title, size = 19, color = P.White, stroke = 0.4 })

	Remotes.get("EventState").OnClientEvent:Connect(function(state)
		if state.active then
			current = state
			frame.Visible = true
			frame.Position = UDim2.new(0.5, 0, 0, 170)
			Theme.tween(frame, 0.4, { Position = UDim2.new(0.5, 0, 0, 200) }, Enum.EasingStyle.Back)
		else
			current = nil
			frame.Visible = false
		end
	end)

	RunService.Heartbeat:Connect(function()
		if current then
			local remain = math.max(0, (current.endsAt or 0) - workspace:GetServerTimeNow())
			label.Text = string.format("%s  %s   ·   %s", current.icon, string.upper(current.name), Util.formatTime(remain))
			if remain <= 0 then
				current = nil
				frame.Visible = false
			end
		end
	end)
end

return EventBanner
