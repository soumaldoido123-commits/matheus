--!nonstrict
--[[
	Mobile: botoes na tela para celular/tablet (agarrar, arremessar com carga, soltar, distancia).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent:WaitForChild("Theme"))
local HUD = require(script.Parent:WaitForChild("HUD"))
local GrabController = require(script.Parent.Parent:WaitForChild("GrabController"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))

local Mobile = {}

local P = Theme.P
local player = Players.LocalPlayer

local function pressButton(props: { [string]: any })
	local b = Theme.new("TextButton", {
		Name = props.name,
		Size = props.size,
		Position = props.position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = props.color,
		BackgroundTransparency = 0.15,
		Text = props.text,
		TextColor3 = props.textColor or P.White,
		Font = Theme.Title,
		TextSize = props.textSize or 20,
		AutoButtonColor = false,
		Parent = props.parent,
	})
	Theme.corner(b, 40)
	Theme.stroke(b, Color3.new(1, 1, 1), 3, 0.4)
	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
	end
	b.InputBegan:Connect(function(input)
		if isPress(input) then
			Theme.tween(b, 0.06, { BackgroundTransparency = 0.45 })
			Audio.ui("Ui", 0.2, 1.2)
			if props.onDown then
				props.onDown()
			end
		end
	end)
	b.InputEnded:Connect(function(input)
		if isPress(input) then
			Theme.tween(b, 0.1, { BackgroundTransparency = 0.15 })
			if props.onUp then
				props.onUp()
			end
		end
	end)
	return b
end

function Mobile.init()
	if not UserInputService.TouchEnabled then
		return
	end
	local gui = Theme.new("ScreenGui", { Name = "TV_Mobile", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
	Theme.new("UIScale", { Scale = 0.9, Parent = gui })
	pressButton({ parent = gui, name = "Throw", text = "ARREMESSAR\n(segure)", size = UDim2.fromOffset(118, 118), position = UDim2.new(1, -90, 1, -260), color = P.Pink, textSize = 15, onDown = GrabController.mobileChargeBegin, onUp = GrabController.mobileChargeEnd })
	pressButton({ parent = gui, name = "Grab", text = "AGARRAR\nSOLTAR", size = UDim2.fromOffset(96, 96), position = UDim2.new(1, -210, 1, -190), color = P.Purple, textSize = 14, onDown = GrabController.mobileGrab })
	pressButton({ parent = gui, name = "Near", text = "−", size = UDim2.fromOffset(60, 60), position = UDim2.new(1, -60, 1, -390), color = P.Blue, textSize = 30, onDown = function()
		GrabController.adjustDistance(-1)
	end })
	pressButton({ parent = gui, name = "Far", text = "+", size = UDim2.fromOffset(60, 60), position = UDim2.new(1, -130, 1, -390), color = P.Blue, textSize = 30, onDown = function()
		GrabController.adjustDistance(1)
	end })
	HUD.setCrosshairVisible(true)
end

return Mobile
