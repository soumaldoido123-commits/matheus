--!nonstrict
--[[
	Tutorial: dicas curtas no comeco (some depois que o jogador aprende o basico).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local GrabController = require(script.Parent.Parent:WaitForChild("GrabController"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local HUD = require(script.Parent:WaitForChild("HUD"))

local Tutorial = {}

local P = Theme.P
local player = Players.LocalPlayer
local panel, label
local step = 0
local finished = false

local STEPS = {
	"👋 Chegue perto de um objeto e <font color='#ffc43d'>clique</font> nele para agarrar!",
	"💪 Agora segure o <font color='#ffc43d'>botão direito</font> para carregar a força e solte para <font color='#ffc43d'>arremessar</font>!",
	"🌟 Arremessos longos dão moedas e XP. Aperte <font color='#ffc43d'>M</font> para abrir o menu (loja, habilidades, cabos)!",
}

local function show(text: string)
	label.Text = text
	panel.Visible = true
	panel.Position = UDim2.new(0.5, 0, 0, 90)
	Theme.tween(panel, 0.35, { Position = UDim2.new(0.5, 0, 0, 96) }, Enum.EasingStyle.Back)
end

local function advance(to: number)
	if finished or to <= step then
		return
	end
	step = to
	if step > #STEPS then
		finished = true
		Theme.tween(panel, 0.4, { Position = UDim2.new(0.5, 0, 0, -80) })
		task.delay(0.5, function()
			panel.Visible = false
		end)
		Remotes.get("SetSetting"):FireServer("Tutorial", true)
		return
	end
	show(STEPS[step])
end

function Tutorial.init()
	if Store.setting("Tutorial") == true then
		return
	end
	local gui = Theme.new("ScreenGui", { Name = "TV_Tutorial", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 7, Parent = player:WaitForChild("PlayerGui") })
	panel = Theme.panel(gui, { size = UDim2.fromOffset(640, 54), position = UDim2.new(0.5, 0, 0, 96), anchor = Vector2.new(0.5, 0), visible = false, name = "Tip", radius = 27 })
	label = Theme.text(panel, { text = "", size = 18, font = Theme.Bold, wrap = true })
	HUD.tutorialPanel = panel

	GrabController.Changed:Connect(function(event)
		if event == "grab" then
			advance(2)
		elseif event == "throw" then
			advance(3)
			task.delay(9, function()
				advance(4)
			end)
		end
	end)

	task.delay(5, function()
		advance(1)
	end)
end

return Tutorial
