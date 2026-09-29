--!nonstrict
--[[
	HUD: interface principal — cartao do jogador (nivel/XP/moedas), mira com barra de carga,
	avisos de zona, toasts, anuncios, resultado do arremesso, agarrado/espernear.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))
local Theme = require(script.Parent:WaitForChild("Theme"))

local HUD = {}

local P = Theme.P
local player = Players.LocalPlayer

local gui: ScreenGui
local scaleObj: UIScale
local card, levelLabel, xpBar, xpLabel, coinLabel, coinScale, pointsLabel
local crosshair, crossDot, crossRing, chargeFrame, chargeBar, chargeLabel, hintLabel
local zoneFrame, zoneLabel
local toastList
local announceFrame, announceTitle, announceSub
local resultCard, resultDist, resultInfo, resultCombo
local struggleFrame, struggleBar, struggleTitle
local chipPeace, chipSafe

HUD.gui = nil
HUD.abilityBar = nil

local shownCoins = 0
local coinTween = nil

-- Toasts ------------------------------------------------------------------------------------------------------------------

local TOAST_COLORS = {
	coin = P.Accent,
	good = P.Green,
	bad = P.Red,
	info = P.Accent2,
}

function HUD.toast(text: string, kind: string?)
	if not toastList then
		return
	end
	local color = TOAST_COLORS[kind or "info"] or P.White
	-- limita a fila
	local children = {}
	for _, c in toastList:GetChildren() do
		if c:IsA("Frame") then
			table.insert(children, c)
		end
	end
	if #children >= 6 then
		children[1]:Destroy()
	end
	local f = Theme.new("Frame", {
		BackgroundColor3 = P.Ink,
		BackgroundTransparency = 0.15,
		Size = UDim2.fromOffset(300, 34),
		AutomaticSize = Enum.AutomaticSize.None,
		Name = "Toast",
		Parent = toastList,
	})
	Theme.corner(f, 10)
	Theme.stroke(f, color, 2, 0.35)
	local bar = Theme.new("Frame", { BackgroundColor3 = color, Size = UDim2.new(0, 5, 1, -10), Position = UDim2.new(0, 6, 0, 5), Parent = f })
	Theme.corner(bar, 3)
	Theme.text(f, {
		text = text,
		size = 16,
		font = Theme.Bold,
		color = P.White,
		alignX = Enum.TextXAlignment.Left,
		frame = UDim2.new(1, -24, 1, 0),
		position = UDim2.fromOffset(20, 0),
	})
	f.Position = UDim2.fromOffset(-40, 0)
	Theme.tween(f, 0.25, { BackgroundTransparency = 0.15 })
	task.delay(3.4, function()
		if f.Parent then
			Theme.tween(f, 0.4, { BackgroundTransparency = 1 })
			for _, d in f:GetDescendants() do
				if d:IsA("TextLabel") then
					Theme.tween(d, 0.4, { TextTransparency = 1 })
				elseif d:IsA("Frame") then
					Theme.tween(d, 0.4, { BackgroundTransparency = 1 })
				elseif d:IsA("UIStroke") then
					Theme.tween(d, 0.4, { Transparency = 1 })
				end
			end
			task.wait(0.45)
			f:Destroy()
		end
	end)
end

-- Anuncio grande ------------------------------------------------------------------------------------------------------------

local announceToken = 0
function HUD.announce(title: string, subtitle: string?, duration: number?, color: Color3?)
	announceToken += 1
	local token = announceToken
	announceTitle.Text = title
	announceTitle.TextColor3 = color or P.Accent
	announceSub.Text = subtitle or ""
	announceFrame.Visible = true
	announceFrame.Position = UDim2.new(0.5, 0, 0, 40)
	local sc = announceFrame:FindFirstChild("Scale")
	sc.Scale = 0.4
	announceTitle.TextTransparency = 0
	announceSub.TextTransparency = 0
	Theme.tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	Theme.tween(announceFrame, 0.35, { Position = UDim2.new(0.5, 0, 0, 120) }, Enum.EasingStyle.Back)
	Audio.ui("LevelUp", 0.35, 1.1)
	task.delay(duration or 2.5, function()
		if token == announceToken then
			Theme.tween(announceTitle, 0.4, { TextTransparency = 1 })
			Theme.tween(announceSub, 0.4, { TextTransparency = 1 })
			task.wait(0.45)
			if token == announceToken then
				announceFrame.Visible = false
			end
		end
	end)
end

-- Zona -------------------------------------------------------------------------------------------------------------------------

local zoneToken = 0
function HUD.setZone(name: string, icon: string?)
	zoneToken += 1
	local token = zoneToken
	zoneLabel.Text = (icon or "📍") .. "  " .. string.upper(name)
	zoneFrame.Visible = true
	zoneFrame.BackgroundTransparency = 1
	zoneLabel.TextTransparency = 1
	Theme.tween(zoneFrame, 0.4, { BackgroundTransparency = 0.25 })
	Theme.tween(zoneLabel, 0.4, { TextTransparency = 0 })
	task.delay(3.2, function()
		if token == zoneToken then
			Theme.tween(zoneFrame, 0.6, { BackgroundTransparency = 1 })
			Theme.tween(zoneLabel, 0.6, { TextTransparency = 1 })
		end
	end)
end

-- Mira -----------------------------------------------------------------------------------------------------------------------------

function HUD.setCharge(fraction: number?)
	if not fraction then
		chargeFrame.Visible = false
		crossRing.Size = UDim2.fromOffset(28, 28)
		return
	end
	chargeFrame.Visible = true
	chargeBar.Size = UDim2.fromScale(fraction, 1)
	local color = P.Green:Lerp(P.Accent, math.clamp(fraction * 2, 0, 1)):Lerp(P.Red, math.clamp(fraction * 2 - 1, 0, 1))
	chargeBar.BackgroundColor3 = color
	chargeLabel.Text = string.format("FORÇA %d%%", math.floor(fraction * 100))
	crossRing.Size = UDim2.fromOffset(28 + fraction * 26, 28 + fraction * 26)
	crossRing.UIStroke.Color = color
end

function HUD.setHint(text: string?, hovering: boolean?)
	if text then
		hintLabel.Text = text .. (hovering and "  <font color='#ffc43d'>[clique]</font>" or "")
		hintLabel.Visible = true
	else
		hintLabel.Visible = false
	end
	if hovering then
		crossDot.BackgroundColor3 = P.Accent
		crossRing.UIStroke.Color = P.Accent
	else
		crossDot.BackgroundColor3 = P.White
		if not chargeFrame.Visible then
			crossRing.UIStroke.Color = P.White
		end
	end
end

function HUD.setCrosshairVisible(visible: boolean)
	crosshair.Visible = visible
end

-- Resultado do arremesso ----------------------------------------------------------------------------------------------------------

local resultToken = 0
function HUD.showThrowResult(distance: number, coins: number, xp: number, record: boolean, combo: number, label: string?)
	resultToken += 1
	local token = resultToken
	resultDist.Text = string.format("%d <font size='22'>studs</font>", distance)
	resultDist.TextColor3 = record and P.Pink or P.Accent
	local extra = ""
	if label then
		extra = "  ·  " .. label
	end
	resultInfo.Text = string.format("+%d 🪙   +%d XP%s", coins, xp, extra)
	resultCombo.Text = combo > 1 and string.format("COMBO ×%d 🔥", combo) or (record and "NOVO RECORDE! 🏆" or "")
	resultCard.Visible = true
	resultCard.Position = UDim2.new(1, 320, 0.4, 0)
	Theme.tween(resultCard, 0.35, { Position = UDim2.new(1, -18, 0.4, 0) }, Enum.EasingStyle.Back)
	task.delay(3.6, function()
		if token == resultToken then
			Theme.tween(resultCard, 0.4, { Position = UDim2.new(1, 320, 0.4, 0) })
		end
	end)
end

-- Espernear ------------------------------------------------------------------------------------------------------------------------------

function HUD.setStruggle(holderName: string?, progress: number?)
	if not holderName then
		struggleFrame.Visible = false
		return
	end
	struggleFrame.Visible = true
	struggleTitle.Text = string.format("🕸️ %s te agarrou!  Aperte <b>ESPAÇO</b> sem parar!", holderName)
	struggleBar.set(progress or 0, true)
end

-- Cartao do jogador -----------------------------------------------------------------------------------------------------------------------

local function formatCoins(n: number): string
	return Util.formatNumber(math.floor(n))
end

local function refreshCard()
	levelLabel.Text = tostring(Store.get("Level") or 1)
	local xp, need = Store.get("XP") or 0, Store.get("XPNeeded") or 100
	xpBar.set(xp / math.max(need, 1))
	xpLabel.Text = string.format("XP %s / %s", Util.formatNumber(xp), Util.formatNumber(need))
	local sp = Store.get("SkillPoints") or 0
	pointsLabel.Visible = sp > 0
	pointsLabel.Text = string.format("⭐ %d ponto%s de habilidade — abra o Menu [M]", sp, sp == 1 and "" or "s")
end

local function setCoins(target: number)
	if coinTween then
		coinTween:Disconnect()
	end
	local from = shownCoins
	local t0 = os.clock()
	local dur = 0.6
	coinTween = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		shownCoins = Util.lerp(from, target, 1 - (1 - a) ^ 3)
		coinLabel.Text = "🪙 " .. formatCoins(shownCoins)
		if a >= 1 then
			coinTween:Disconnect()
			coinTween = nil
		end
	end)
	if target > from then
		coinScale.Scale = 1.25
		Theme.tween(coinScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

-- Construcao ---------------------------------------------------------------------------------------------------------------------------------

local function build()
	gui = Theme.new("ScreenGui", {
		Name = "TV_HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HUD.gui = gui
	scaleObj = Theme.new("UIScale", { Parent = gui })
	local function rescale()
		local vs = workspace.CurrentCamera.ViewportSize
		scaleObj.Scale = math.clamp(vs.Y / 820, 0.62, 1.25)
	end
	rescale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

	-- cartao do jogador
	card = Theme.panel(gui, { size = UDim2.fromOffset(330, 104), position = UDim2.fromOffset(16, 16), name = "PlayerCard" })
	local badge = Theme.new("Frame", { Size = UDim2.fromOffset(74, 74), Position = UDim2.fromOffset(14, 15), BackgroundColor3 = Color3.new(1, 1, 1), Parent = card, Name = "Badge" })
	Theme.corner(badge, 37)
	Theme.gradient(badge, Color3.fromRGB(255, 226, 120), Color3.fromRGB(255, 150, 40), 90)
	Theme.stroke(badge, Color3.new(1, 1, 1), 3, 0.3)
	levelLabel = Theme.text(badge, { text = "1", font = Theme.Title, size = 38, color = P.Ink, stroke = 1 })
	Theme.text(card, { text = "NÍVEL", size = 10, font = Theme.Bold, color = P.Muted, frame = UDim2.fromOffset(74, 12), position = UDim2.fromOffset(14, 91) }).ZIndex = 2
	Theme.text(card, {
		text = player.DisplayName,
		font = Theme.Title,
		size = 18,
		alignX = Enum.TextXAlignment.Left,
		frame = UDim2.new(1, -110, 0, 22),
		position = UDim2.fromOffset(100, 10),
	})
	xpBar = Theme.bar(card, { size = UDim2.new(1, -116, 0, 14), position = UDim2.fromOffset(100, 36), color = P.Accent2, gradient = P.Blue })
	xpLabel = Theme.text(card, { text = "XP", size = 11, font = Theme.Bold, color = P.Muted, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(1, -116, 0, 12), position = UDim2.fromOffset(100, 52) })
	coinLabel = Theme.text(card, {
		text = "🪙 0",
		font = Theme.Title,
		size = 26,
		color = P.Accent,
		alignX = Enum.TextXAlignment.Left,
		frame = UDim2.new(1, -110, 0, 30),
		position = UDim2.fromOffset(100, 64),
		stroke = 0.6,
	})
	coinScale = Theme.new("UIScale", { Parent = coinLabel })
	pointsLabel = Theme.text(gui, {
		text = "",
		size = 14,
		font = Theme.Bold,
		color = P.Accent,
		alignX = Enum.TextXAlignment.Left,
		frame = UDim2.fromOffset(340, 20),
		position = UDim2.fromOffset(20, 126),
		stroke = 0.5,
	})
	pointsLabel.Visible = false

	-- mira
	crosshair = Theme.new("Frame", { Size = UDim2.fromOffset(60, 60), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Name = "Crosshair", Parent = gui })
	crossDot = Theme.new("Frame", { Size = UDim2.fromOffset(6, 6), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.White, Parent = crosshair })
	Theme.corner(crossDot, 3)
	Theme.stroke(crossDot, P.Ink, 1, 0.3)
	crossRing = Theme.new("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = crosshair, Name = "Ring" })
	Theme.corner(crossRing, 20)
	Theme.stroke(crossRing, P.White, 2, 0.35)

	chargeFrame = Theme.new("Frame", { Size = UDim2.fromOffset(200, 16), Position = UDim2.new(0.5, 0, 0.5, 60), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = P.Ink, BackgroundTransparency = 0.3, Visible = false, Parent = gui, Name = "Charge" })
	Theme.corner(chargeFrame, 8)
	Theme.stroke(chargeFrame, P.White, 2, 0.6)
	chargeBar = Theme.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = P.Green, Parent = chargeFrame })
	Theme.corner(chargeBar, 8)
	chargeLabel = Theme.text(chargeFrame, { text = "FORÇA", size = 12, font = Theme.Title, color = P.White, stroke = 0.4, z = 3 })

	hintLabel = Theme.text(gui, {
		text = "",
		font = Theme.Bold,
		size = 17,
		frame = UDim2.fromOffset(340, 24),
		position = UDim2.new(0.5, 0, 0.5, 32),
		anchor = Vector2.new(0.5, 0),
		stroke = 0.4,
	})
	hintLabel.Visible = false

	-- zona
	zoneFrame = Theme.new("Frame", { Size = UDim2.fromOffset(420, 50), Position = UDim2.new(0.5, 0, 0, 22), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = P.Ink, BackgroundTransparency = 1, Visible = false, Parent = gui, Name = "Zone" })
	Theme.corner(zoneFrame, 25)
	zoneLabel = Theme.text(zoneFrame, { text = "", font = Theme.Title, size = 24, color = P.White, stroke = 0.4 })

	-- toasts
	toastList = Theme.new("Frame", { Size = UDim2.fromOffset(310, 260), Position = UDim2.new(0, 16, 1, -190), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, Parent = gui, Name = "Toasts" })
	Theme.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), Parent = toastList })

	-- anuncio
	announceFrame = Theme.new("Frame", { Size = UDim2.fromOffset(700, 120), Position = UDim2.new(0.5, 0, 0, 120), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Visible = false, Parent = gui, Name = "Announce" })
	Theme.new("UIScale", { Name = "Scale", Parent = announceFrame })
	announceTitle = Theme.text(announceFrame, { text = "", font = Theme.Title, size = 58, color = P.Accent, frame = UDim2.new(1, 0, 0, 70), stroke = 0.15 })
	announceSub = Theme.text(announceFrame, { text = "", font = Theme.Bold, size = 22, color = P.White, frame = UDim2.new(1, 0, 0, 30), position = UDim2.fromOffset(0, 74), stroke = 0.3 })

	-- resultado
	resultCard = Theme.panel(gui, { size = UDim2.fromOffset(280, 118), position = UDim2.new(1, 320, 0.4, 0), anchor = Vector2.new(1, 0.5), visible = false, name = "ThrowResult" })
	Theme.text(resultCard, { text = "ARREMESSO", size = 12, font = Theme.Bold, color = P.Muted, frame = UDim2.new(1, 0, 0, 16), position = UDim2.fromOffset(0, 8) })
	resultDist = Theme.text(resultCard, { text = "0", font = Theme.Title, size = 46, color = P.Accent, frame = UDim2.new(1, 0, 0, 50), position = UDim2.fromOffset(0, 22), stroke = 0.4 })
	resultInfo = Theme.text(resultCard, { text = "", size = 16, font = Theme.Bold, color = P.White, frame = UDim2.new(1, 0, 0, 20), position = UDim2.fromOffset(0, 74) })
	resultCombo = Theme.text(resultCard, { text = "", size = 15, font = Theme.Title, color = P.Pink, frame = UDim2.new(1, 0, 0, 18), position = UDim2.fromOffset(0, 94) })

	-- espernear
	struggleFrame = Theme.panel(gui, { size = UDim2.fromOffset(460, 70), position = UDim2.new(0.5, 0, 0.72, 0), anchor = Vector2.new(0.5, 0.5), visible = false, name = "Struggle", color = Color3.fromRGB(80, 30, 50), color2 = P.Ink })
	struggleTitle = Theme.text(struggleFrame, { text = "", size = 18, font = Theme.Bold, frame = UDim2.new(1, -20, 0, 26), position = UDim2.fromOffset(10, 8) })
	struggleBar = Theme.bar(struggleFrame, { size = UDim2.new(1, -30, 0, 16), position = UDim2.fromOffset(15, 40), color = P.Red, gradient = P.Accent })

	-- barra de habilidades
	local ab = Theme.new("Frame", { Size = UDim2.fromOffset(560, 84), Position = UDim2.new(0.5, 0, 1, -14), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Parent = gui, Name = "AbilityBar" })
	Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ab })
	HUD.abilityBar = ab

	-- status (canto superior direito)
	local chips = Theme.new("Frame", { Size = UDim2.fromOffset(300, 34), Position = UDim2.new(1, -16, 0, 16), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Parent = gui, Name = "Chips" })
	Theme.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), Parent = chips })
	local function chip(text: string, color: Color3)
		local c = Theme.new("Frame", { Size = UDim2.fromOffset(130, 30), BackgroundColor3 = color, BackgroundTransparency = 0.25, Visible = false, Parent = chips })
		Theme.corner(c, 15)
		Theme.stroke(c, Color3.new(1, 1, 1), 2, 0.6)
		Theme.text(c, { text = text, size = 14, font = Theme.Bold })
		return c
	end
	chipPeace = chip("🕊️ Modo Pacífico", P.Green)
	chipSafe = chip("🛡️ Zona Segura", P.Blue)

	-- botao de menu
	Theme.button(gui, {
		text = "☰  MENU  [M]",
		size = UDim2.fromOffset(150, 40),
		position = UDim2.new(1, -16, 1, -16),
		anchor = Vector2.new(1, 1),
		color = P.Purple,
		textColor = P.White,
		textSize = 16,
		onClick = function()
			if HUD.onMenu then
				HUD.onMenu()
			end
		end,
	})
end

function HUD.init()
	build()

	Store.Changed:Connect(function(key, value)
		if key == "Coins" then
			setCoins(value)
		elseif key == "XP" or key == "Level" or key == "XPNeeded" or key == "SkillPoints" then
			refreshCard()
		end
	end)
	shownCoins = Store.get("Coins") or 0
	coinLabel.Text = "🪙 " .. formatCoins(shownCoins)
	refreshCard()

	local function refreshChips()
		chipPeace.Visible = player:GetAttribute("Peaceful") == true
		chipSafe.Visible = player:GetAttribute("SafeZone") == true
	end
	player:GetAttributeChangedSignal("Peaceful"):Connect(refreshChips)
	player:GetAttributeChangedSignal("SafeZone"):Connect(refreshChips)
	refreshChips()

	Remotes.get("Notify").OnClientEvent:Connect(function(text, kind)
		HUD.toast(text, kind)
		if kind == "coin" then
			Audio.ui("Coin", 0.25, 1.4)
		elseif kind == "bad" then
			Audio.ui("Error", 0.25)
		end
	end)
	Remotes.get("Announce").OnClientEvent:Connect(function(title, sub, dur, color)
		HUD.announce(title, sub, dur, color)
	end)
	Remotes.get("Zone").OnClientEvent:Connect(function(name, icon)
		HUD.setZone(name, icon)
	end)
	Remotes.get("ThrowResult").OnClientEvent:Connect(function(distance, coins, xp, record, combo, label)
		HUD.showThrowResult(distance, coins, xp, record, combo, label)
	end)

	-- esconde a mira em tela de menu aberta etc. (controlado por outros modulos)
	HUD.setCrosshairVisible(UserInputService.MouseEnabled == false or UserInputService.TouchEnabled)
end

return HUD
