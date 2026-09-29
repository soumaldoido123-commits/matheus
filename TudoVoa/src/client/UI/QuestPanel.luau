--!nonstrict
--[[
	QuestPanel: lista compacta das missoes ativas (canto esquerdo, abaixo do cartao do jogador).
	Tecla J recolhe/expande.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefs = require(Shared:WaitForChild("QuestDefs"))
local Util = require(Shared:WaitForChild("Util"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local HUD = require(script.Parent:WaitForChild("HUD"))

local QuestPanel = {}

local P = Theme.P
local panel, list, header
local collapsed = false
local lastProgress = {}

local ROW_H = 46

local function render()
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local q = Store.get("Quests")
	local slots = q and q.slots or {}
	header.Text = string.format("📋 MISSÕES  <font color='#96a0c8' size='12'>[J]  ·  %d feitas</font>", (q and q.completed) or 0)
	for i, s in slots do
		local def = QuestDefs.ById[s.id]
		if def then
			local row = Theme.new("Frame", { Size = UDim2.new(1, 0, 0, ROW_H), BackgroundTransparency = 1, LayoutOrder = i, Parent = list, Name = "Q" .. i })
			Theme.text(row, { text = def.icon .. " " .. def.text, size = 13, font = Theme.Bold, alignX = Enum.TextXAlignment.Left, wrap = true, alignY = Enum.TextYAlignment.Top, frame = UDim2.new(1, -6, 0, 26), position = UDim2.fromOffset(2, 0) })
			local bar = Theme.bar(row, { size = UDim2.new(1, -62, 0, 10), position = UDim2.fromOffset(2, 30), color = P.Green, gradient = P.Accent2, radius = 5 })
			local frac = s.progress / math.max(def.goal, 1)
			bar.set(frac, true)
			Theme.text(row, { text = string.format("%s/%s", Util.formatNumber(s.progress), Util.formatNumber(def.goal)), size = 12, font = Theme.Bold, color = P.Accent, alignX = Enum.TextXAlignment.Right, frame = UDim2.fromOffset(56, 14), position = UDim2.new(1, -56, 0, 26) })
			local last = lastProgress[s.id]
			if last and s.progress > last then
				Theme.tween(row, 0.001, {})
				local pulse = Theme.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.Accent, BackgroundTransparency = 0.6, Parent = row, ZIndex = 0 })
				Theme.corner(pulse, 6)
				Theme.tween(pulse, 0.8, { BackgroundTransparency = 1 })
				task.delay(0.9, function()
					pulse:Destroy()
				end)
			end
			lastProgress[s.id] = s.progress
		end
	end
	local n = #slots
	panel.Size = UDim2.fromOffset(300, collapsed and 34 or (44 + n * (ROW_H + 4)))
	list.Visible = not collapsed
end

function QuestPanel.init()
	panel = Theme.panel(HUD.gui, {
		size = UDim2.fromOffset(300, 160),
		position = UDim2.fromOffset(16, 158),
		name = "Quests",
		transparency = 0.25,
		radius = 12,
	})
	header = Theme.text(panel, { text = "📋 MISSÕES", font = Theme.Title, size = 16, color = P.Accent, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(1, -16, 0, 26), position = UDim2.fromOffset(10, 4) })
	list = Theme.new("Frame", { Size = UDim2.new(1, -20, 1, -38), Position = UDim2.fromOffset(10, 34), BackgroundTransparency = 1, Parent = panel })
	Theme.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local btn = Theme.new("TextButton", { Size = UDim2.fromScale(1, 0), Text = "", BackgroundTransparency = 1, Parent = panel })
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.Activated:Connect(function()
		collapsed = not collapsed
		render()
	end)

	Store.Changed:Connect(function(key)
		if key == "Quests" then
			render()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.J then
			collapsed = not collapsed
			render()
		end
	end)
	render()
end

return QuestPanel
