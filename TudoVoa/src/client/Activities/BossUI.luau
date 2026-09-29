--!nonstrict
--[[
	BossUI: barra de vida do chefao (Golem Sucata) + distancia ate ele.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Theme = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Theme"))
local HUD = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("HUD"))

local BossUI = {}

local P = Theme.P
local player = Players.LocalPlayer
local frame, hpBar, hpLabel, distLabel, phaseLabel
local lastState = nil
local lastUpdate = 0

function BossUI.init()
	frame = Theme.panel(HUD.gui, {
		size = UDim2.fromOffset(560, 92),
		position = UDim2.new(0.5, 0, 0, 86),
		anchor = Vector2.new(0.5, 0),
		visible = false,
		name = "BossBar",
		color = Color3.fromRGB(70, 28, 40),
		color2 = P.Ink,
		strokeColor = P.Red,
		strokeTransparency = 0.4,
	})
	Theme.text(frame, { text = "🗿 GOLEM SUCATA", font = Theme.Title, size = 24, color = P.Accent, frame = UDim2.new(1, -20, 0, 30), position = UDim2.fromOffset(10, 6), stroke = 0.4 })
	hpBar = Theme.bar(frame, { size = UDim2.new(1, -30, 0, 22), position = UDim2.fromOffset(15, 40), color = P.Red, gradient = P.Accent, radius = 11 })
	hpLabel = Theme.text(frame, { text = "", font = Theme.Bold, size = 13, color = P.White, frame = UDim2.new(1, -30, 0, 22), position = UDim2.fromOffset(15, 40), stroke = 0.4, z = 5 })
	distLabel = Theme.text(frame, { text = "", font = Theme.Bold, size = 13, color = P.Muted, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0.6, 0, 0, 18), position = UDim2.fromOffset(16, 67) })
	phaseLabel = Theme.text(frame, { text = "", font = Theme.Title, size = 14, color = P.Pink, alignX = Enum.TextXAlignment.Right, frame = UDim2.new(0.4, -16, 0, 18), position = UDim2.new(0.6, 0, 0, 67) })

	Remotes.get("BossState").OnClientEvent:Connect(function(state)
		lastState = state
		lastUpdate = os.clock()
		if state.active then
			frame.Visible = true
			hpBar.set(state.hp / math.max(state.maxHp, 1))
			hpLabel.Text = string.format("%s / %s", Util.formatNumber(state.hp), Util.formatNumber(state.maxHp))
			phaseLabel.Text = string.format("FASE %d/4", state.phase or 1)
		else
			frame.Visible = false
		end
	end)

	RunService.Heartbeat:Connect(function()
		if not frame.Visible or not lastState or not lastState.pos then
			return
		end
		if os.clock() - lastUpdate > 5 then
			frame.Visible = false
			return
		end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = (hrp.Position - lastState.pos).Magnitude
			distLabel.Text = string.format("📍 %d studs  ·  Ilha do Golem (tubo de vento laranja)", math.floor(d))
		end
	end)
end

return BossUI
