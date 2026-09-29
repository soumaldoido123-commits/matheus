--!nonstrict
--[[
	ArenaUI: painel da Arena do Caos (onda atual, robos restantes e contagem regressiva).
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Theme"))
local HUD = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("HUD"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))

local ArenaUI = {}

local P = Theme.P
local frame, sub, big
local lastUpdate = 0
local lastCount = -1

function ArenaUI.init()
	frame = Theme.panel(HUD.gui, {
		size = UDim2.fromOffset(300, 80),
		position = UDim2.new(1, -16, 0, 60),
		anchor = Vector2.new(1, 0),
		visible = false,
		name = "ArenaPanel",
		color = Color3.fromRGB(80, 34, 100),
		color2 = P.Ink,
		strokeColor = P.Pink,
		strokeTransparency = 0.35,
	})
	Theme.text(frame, { text = "⚔️ ARENA DO CAOS", font = Theme.Title, size = 19, color = P.Pink, frame = UDim2.new(1, 0, 0, 26), position = UDim2.fromOffset(0, 6), stroke = 0.4 })
	sub = Theme.text(frame, { text = "", font = Theme.Bold, size = 15, color = P.White, frame = UDim2.new(1, 0, 0, 22), position = UDim2.fromOffset(0, 34) })
	big = Theme.text(HUD.gui, { text = "", font = Theme.Title, size = 90, color = P.Accent, frame = UDim2.fromOffset(300, 100), position = UDim2.fromScale(0.5, 0.34), anchor = Vector2.new(0.5, 0.5), stroke = 0.1 })
	big.Visible = false

	Remotes.get("ArenaState").OnClientEvent:Connect(function(state)
		lastUpdate = os.clock()
		frame.Visible = true
		if state.state == "idle" then
			sub.Text = "Derrube os robôs da plataforma!"
			big.Visible = false
		elseif state.state == "countdown" then
			sub.Text = string.format("Próxima onda: %d/%d", math.min(state.wave + 1, state.maxWave), state.maxWave)
			big.Visible = state.countdown > 0
			big.Text = tostring(state.countdown)
			if state.countdown ~= lastCount then
				lastCount = state.countdown
				Audio.ui("Charge", 0.3, 1 + (5 - state.countdown) * 0.1)
			end
		else
			sub.Text = string.format("Onda <b>%d</b>/%d   ·   Robôs: <b>%d</b>", state.wave, state.maxWave, state.bots)
			big.Visible = false
		end
	end)

	RunService.Heartbeat:Connect(function()
		if frame.Visible and os.clock() - lastUpdate > 2.5 then
			frame.Visible = false
			big.Visible = false
		end
	end)
end

return ArenaUI
