--!nonstrict
--[[
	Menu: janela principal (tecla M). Abas: Loja, Meus Brinquedos, Habilidades, Cabo, Recordes,
	Ajustes e Ajuda.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Toys = require(Shared:WaitForChild("Toys"))
local AbilityDefs = require(Shared:WaitForChild("AbilityDefs"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local HUD = require(script.Parent:WaitForChild("HUD"))

local Menu = {}

local P = Theme.P
local player = Players.LocalPlayer

local gui, window, content, tabButtons, titleLabel, walletLabel
local currentTab = "shop"
local isOpen = false
local buildTab = {}

local TABS = {
	{ id = "shop", label = "🧸  Loja" },
	{ id = "toys", label = "🎒  Meus Brinquedos" },
	{ id = "skills", label = "⭐  Habilidades" },
	{ id = "tether", label = "🔗  Cabo & Rastro" },
	{ id = "board", label = "🏆  Recordes" },
	{ id = "settings", label = "⚙️  Ajustes" },
	{ id = "help", label = "❓  Ajuda" },
}

-- Ajudantes --------------------------------------------------------------------------------------------------------------------

local function clear()
	for _, c in content:GetChildren() do
		if not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function useGrid(cellW: number, cellH: number)
	Theme.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(cellW, cellH),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
end

local function useList(pad: number?)
	Theme.new("UIListLayout", {
		Padding = UDim.new(0, pad or 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
end

local function header(text: string, order: number)
	local h = Theme.text(content, { text = text, font = Theme.Title, size = 22, color = P.Accent, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(1, -10, 0, 30) })
	h.LayoutOrder = order
	return h
end

local function refreshWallet()
	if walletLabel then
		walletLabel.Text = string.format("🪙 %s     ⭐ %d pts", Util.formatNumber(Store.get("Coins") or 0), Store.get("SkillPoints") or 0)
	end
end

local function shopCall(action: string, id: string)
	local ok, res, msg = pcall(function()
		return Remotes.get("Shop"):InvokeServer(action, id)
	end)
	if not ok then
		HUD.toast("Erro na loja", "bad")
		return false
	end
	if res then
		Audio.ui("Coin", 0.5, 1.3)
	else
		Audio.ui("Error", 0.35)
	end
	HUD.toast(msg or (res and "Pronto!" or "Não foi possível"), res and "good" or "bad")
	return res
end

-- Aba: Loja ------------------------------------------------------------------------------------------------------------------------------

local function toyCard(toy, order: number, showBuy: boolean)
	local owned = Store.ownsToy(toy.id)
	local level = Store.get("Level") or 1
	local coins = Store.get("Coins") or 0
	local rarity = Toys.Rarity[toy.rarity] or Toys.Rarity["Comum"]
	local f = Theme.panel(content, { size = UDim2.fromOffset(206, 196), name = "Toy_" .. toy.id, strokeColor = rarity.color, strokeTransparency = 0.35 })
	f.LayoutOrder = order
	Theme.text(f, { text = toy.icon, size = 42, frame = UDim2.new(1, 0, 0, 52), position = UDim2.fromOffset(0, 6) })
	Theme.text(f, { text = toy.name, size = 16, font = Theme.Title, color = rarity.color, frame = UDim2.new(1, -12, 0, 20), position = UDim2.fromOffset(6, 58) })
	Theme.text(f, { text = toy.rarity .. "  ·  Nv " .. toy.level, size = 11, font = Theme.Bold, color = P.Muted, frame = UDim2.new(1, -12, 0, 14), position = UDim2.fromOffset(6, 78) })
	Theme.text(f, { text = toy.desc, size = 11, color = P.White, wrap = true, alignY = Enum.TextYAlignment.Top, frame = UDim2.new(1, -16, 0, 46), position = UDim2.fromOffset(8, 94) })

	local label, color, enabled, action
	if owned then
		label, color, enabled = "INVOCAR", P.Green, true
		action = function()
			Remotes.get("SpawnToy"):FireServer(toy.id)
			Audio.ui("Ui", 0.3)
		end
	elseif level < toy.level then
		label, color, enabled = "🔒 Nível " .. toy.level, P.PanelLight, false
	else
		label, color, enabled = "🪙 " .. Util.formatNumber(toy.price), (coins >= toy.price) and P.Accent or P.Muted, true
		action = function()
			if shopCall("buyToy", toy.id) then
				Menu.refresh()
			end
		end
	end
	local btn = Theme.button(f, { text = label, size = UDim2.new(1, -20, 0, 36), position = UDim2.new(0, 10, 1, -44), color = color, textSize = 16, onClick = enabled and action or nil })
	if not enabled then
		btn.TextColor3 = P.Muted
	end
	if not showBuy and not owned then
		f.Visible = false
	end
end

buildTab.shop = function()
	useGrid(206, 196)
	local list = {}
	for _, t in Toys.List do
		table.insert(list, t)
	end
	table.sort(list, function(a, b)
		return a.level < b.level
	end)
	for i, t in list do
		toyCard(t, i, true)
	end
end

buildTab.toys = function()
	useGrid(206, 196)
	local n = 0
	for i, t in Toys.List do
		if Store.ownsToy(t.id) then
			n += 1
			toyCard(t, i, false)
		end
	end
	local clearBtn = Theme.button(content, {
		text = "🧹 Guardar todos os meus brinquedos",
		size = UDim2.fromOffset(206, 196),
		color = P.Purple,
		textColor = P.White,
		textSize = 18,
		onClick = function()
			Remotes.get("DespawnToys"):FireServer()
			Audio.ui("Ui", 0.3)
		end,
	})
	clearBtn.LayoutOrder = 999
end

-- Aba: Habilidades ------------------------------------------------------------------------------------------------------------------------

buildTab.skills = function()
	useList(10)
	local sp = Store.get("SkillPoints") or 0
	header(string.format("Pontos de habilidade: %d ⭐  (1 por nível)", sp), 1)
	local order = 2
	for _, id in { "Power", "Range", "Strength", "Cooldown", "Escape", "DoubleTether" } do
		local def = Config.Upgrades[id]
		local cur = Store.upgrade(id)
		local cost = (id == "DoubleTether") and 5 or (1 + cur // 3)
		local row = Theme.panel(content, { size = UDim2.new(1, -12, 0, 64), name = "Up_" .. id })
		row.LayoutOrder = order
		order += 1
		Theme.text(row, { text = def.icon, size = 30, frame = UDim2.fromOffset(56, 64) })
		Theme.text(row, { text = def.name, font = Theme.Title, size = 18, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0.4, 0, 0, 24), position = UDim2.fromOffset(60, 6) })
		Theme.text(row, { text = def.desc, size = 12, color = P.Muted, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0.5, 0, 0, 18), position = UDim2.fromOffset(60, 34) })
		-- pontinhos de nivel
		for i = 1, def.max do
			local pip = Theme.new("Frame", {
				Size = UDim2.fromOffset(10, 10),
				Position = UDim2.new(0.55, (i - 1) * 14, 0.5, -5),
				BackgroundColor3 = (i <= cur) and P.Accent or P.Ink,
				Parent = row,
			})
			Theme.corner(pip, 5)
			Theme.stroke(pip, Color3.new(1, 1, 1), 1, 0.7)
		end
		local maxed = cur >= def.max
		Theme.button(row, {
			text = maxed and "MÁX" or string.format("+  (%d⭐)", cost),
			size = UDim2.fromOffset(100, 38),
			position = UDim2.new(1, -110, 0.5, -19),
			color = maxed and P.PanelLight or ((sp >= cost) and P.Green or P.Muted),
			textSize = 16,
			onClick = (not maxed) and function()
				Remotes.get("BuyUpgrade"):FireServer(id)
				Audio.ui("Ui", 0.4, 1.3)
			end or nil,
		})
	end

	header("Habilidades (teclas 1-7)", order)
	order += 1
	local level = Store.get("Level") or 1
	for _, def in AbilityDefs.List do
		local unlocked = level >= def.level
		local row = Theme.panel(content, { size = UDim2.new(1, -12, 0, 62), name = "Ab_" .. def.id })
		row.LayoutOrder = order
		order += 1
		Theme.text(row, { text = def.icon, size = 30, frame = UDim2.fromOffset(56, 62) })
		Theme.text(row, { text = string.format("%s  <font color='#ffc43d'>[%s]</font>", def.name, def.keyLabel), font = Theme.Title, size = 17, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0.6, 0, 0, 24), position = UDim2.fromOffset(60, 5) })
		Theme.text(row, { text = def.desc, size = 12, color = P.Muted, wrap = true, alignX = Enum.TextXAlignment.Left, alignY = Enum.TextYAlignment.Top, frame = UDim2.new(0.68, 0, 0, 30), position = UDim2.fromOffset(60, 30) })
		Theme.text(row, {
			text = unlocked and string.format("⏱ %ds", def.cooldown) or ("🔒 Nível " .. def.level),
			font = Theme.Title,
			size = 16,
			color = unlocked and P.Green or P.Muted,
			frame = UDim2.fromOffset(110, 30),
			position = UDim2.new(1, -120, 0.5, -15),
		})
		if not unlocked then
			row.BackgroundTransparency = 0.5
		end
	end
end

-- Aba: Cabo & Rastro ------------------------------------------------------------------------------------------------------------------------

local function swatch(item, order: number, kind: string)
	local owned = (kind == "tether" and Store.get("OwnedTethers")[item.id]) or (kind == "trail" and Store.get("OwnedTrails")[item.id]) or false
	local equipped = (kind == "tether" and Store.get("Tether") == item.id) or (kind == "trail" and Store.get("Trail") == item.id)
	local level = Store.get("Level") or 1
	local coins = Store.get("Coins") or 0
	local f = Theme.panel(content, { size = UDim2.fromOffset(150, 128), name = "Sw_" .. item.id, strokeColor = equipped and P.Accent or P.White, strokeTransparency = equipped and 0.1 or 0.82 })
	f.LayoutOrder = order
	local preview = Theme.new("Frame", { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = item.color or P.Accent2, Parent = f })
	Theme.corner(preview, 13)
	if item.rainbow then
		Theme.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 90, 255)),
			}),
			Parent = preview,
		})
	elseif kind == "trail" then
		preview.BackgroundColor3 = P.PanelLight
		Theme.text(preview, { text = item.id == "Nenhum" and "—" or "✨", size = 18 })
	end
	Theme.text(f, { text = item.name, font = Theme.Title, size = 14, frame = UDim2.new(1, -8, 0, 32), position = UDim2.fromOffset(4, 40), wrap = true })
	local label, color, enabled, action
	local buyAction = kind == "tether" and "buyTether" or "buyTrail"
	local equipAction = kind == "tether" and "equipTether" or "equipTrail"
	if equipped then
		label, color, enabled = "EQUIPADO ✔", P.Accent, false
	elseif owned then
		label, color, enabled = "EQUIPAR", P.Green, true
		action = function()
			if shopCall(equipAction, item.id) then
				Menu.refresh()
			end
		end
	elseif level < item.level then
		label, color, enabled = "🔒 Nv " .. item.level, P.PanelLight, false
	else
		label, color, enabled = "🪙 " .. Util.formatNumber(item.price), (coins >= item.price) and P.Accent or P.Muted, true
		action = function()
			if shopCall(buyAction, item.id) then
				Menu.refresh()
			end
		end
	end
	local b = Theme.button(f, { text = label, size = UDim2.new(1, -16, 0, 32), position = UDim2.new(0, 8, 1, -40), color = color, textSize = 14, onClick = enabled and action or nil })
	if not enabled and not equipped then
		b.TextColor3 = P.Muted
	end
end

buildTab.tether = function()
	useGrid(150, 128)
	local order = 0
	for _, c in Config.TetherColors do
		order += 1
		swatch(c, order, "tether")
	end
	for _, t in Config.Trails do
		order += 1
		swatch(t, 100 + order, "trail")
	end
end

-- Aba: Recordes ----------------------------------------------------------------------------------------------------------------------------

buildTab.board = function()
	useList(6)
	header("🏆 Maiores arremessos do servidor", 1)
	local mine = Theme.panel(content, { size = UDim2.new(1, -12, 0, 60), color = Color3.fromRGB(60, 44, 110) })
	mine.LayoutOrder = 2
	Theme.text(mine, {
		text = string.format("Você:  <font color='#ffc43d'>%d studs</font>   ·   %d arremessos   ·   %d acertos   ·   Nível %d", Store.get("BestThrow") or 0, Store.get("TotalThrows") or 0, Store.get("TotalHits") or 0, Store.get("Level") or 1),
		size = 17,
		font = Theme.Bold,
	})
	local loading = Theme.text(content, { text = "Carregando placar...", size = 16, color = P.Muted, frame = UDim2.new(1, 0, 0, 30) })
	loading.LayoutOrder = 3
	task.spawn(function()
		local ok, list = pcall(function()
			return Remotes.get("GetBoard"):InvokeServer()
		end)
		if not content.Parent or currentTab ~= "board" or not loading.Parent then
			return
		end
		loading:Destroy()
		if not ok or type(list) ~= "table" or #list == 0 then
			local t = Theme.text(content, { text = "Ainda ninguém arremessou longe. Seja o primeiro!", size = 16, color = P.Muted, frame = UDim2.new(1, 0, 0, 30) })
			t.LayoutOrder = 4
			return
		end
		for i, e in list do
			local row = Theme.panel(content, { size = UDim2.new(1, -12, 0, 44) })
			row.LayoutOrder = 3 + i
			local medal = (i == 1 and "🥇") or (i == 2 and "🥈") or (i == 3 and "🥉") or tostring(i) .. "."
			Theme.text(row, { text = medal, font = Theme.Title, size = 22, frame = UDim2.fromOffset(60, 44) })
			Theme.text(row, { text = e.name, font = Theme.Bold, size = 18, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0.6, 0, 1, 0), position = UDim2.fromOffset(64, 0) })
			Theme.text(row, { text = e.value .. " studs", font = Theme.Title, size = 20, color = P.Accent, alignX = Enum.TextXAlignment.Right, frame = UDim2.new(0.3, 0, 1, 0), position = UDim2.new(0.7, -14, 0, 0) })
		end
	end)
end

-- Aba: Ajustes ------------------------------------------------------------------------------------------------------------------------------

local function toggleRow(label: string, desc: string, key: string, order: number)
	local row = Theme.panel(content, { size = UDim2.new(1, -12, 0, 64) })
	row.LayoutOrder = order
	Theme.text(row, { text = label, font = Theme.Title, size = 18, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0.7, 0, 0, 26), position = UDim2.fromOffset(16, 8) })
	Theme.text(row, { text = desc, size = 12, color = P.Muted, alignX = Enum.TextXAlignment.Left, wrap = true, frame = UDim2.new(0.7, 0, 0, 22), position = UDim2.fromOffset(16, 34) })
	local on = Store.setting(key) == true
	local track = Theme.new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(64, 32), Position = UDim2.new(1, -80, 0.5, -16), BackgroundColor3 = on and P.Green or P.Ink, Parent = row })
	Theme.corner(track, 16)
	Theme.stroke(track, Color3.new(1, 1, 1), 2, 0.7)
	local knob = Theme.new("Frame", { Size = UDim2.fromOffset(24, 24), Position = on and UDim2.fromOffset(36, 4) or UDim2.fromOffset(4, 4), BackgroundColor3 = P.White, Parent = track })
	Theme.corner(knob, 12)
	track.Activated:Connect(function()
		local nowOn = not (Store.setting(key) == true)
		Remotes.get("SetSetting"):FireServer(key, nowOn)
		Store.get("Settings")[key] = nowOn
		Theme.tween(track, 0.15, { BackgroundColor3 = nowOn and P.Green or P.Ink })
		Theme.tween(knob, 0.15, { Position = nowOn and UDim2.fromOffset(36, 4) or UDim2.fromOffset(4, 4) })
		Audio.ui("Ui", 0.3)
	end)
end

buildTab.settings = function()
	useList(10)
	toggleRow("🕊️ Modo Pacífico", "Ninguém consegue te agarrar, e você não agarra pessoas. Objetos continuam liberados.", "Peaceful", 1)
	toggleRow("🔊 Efeitos sonoros", "Liga ou desliga os sons do jogo.", "Sfx", 2)
	toggleRow("📳 Tremor de câmera", "Impactos e explosões balançam a tela. Desligue se sentir enjoo.", "Shake", 3)
	local reset = Theme.button(content, {
		text = "🔄  Reaparecer na praça",
		size = UDim2.fromOffset(300, 46),
		color = P.Red,
		textColor = P.White,
		textSize = 18,
		onClick = function()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Health = 0
			end
			Menu.close()
		end,
	})
	reset.LayoutOrder = 10
end

-- Aba: Ajuda -----------------------------------------------------------------------------------------------------------------------------------

buildTab.help = function()
	useList(8)
	local lines = {
		{ "🖱️ Clique esquerdo", "Agarra o objeto ou a pessoa sob a mira. Clique de novo para soltar." },
		{ "🖱️ Botão direito (segurar)", "Carrega a força do arremesso. Solte para arremessar. Uma linha mostra onde vai cair." },
		{ "🖲️ Scroll", "Aproxima ou afasta o objeto que você está segurando." },
		{ "⌨️ Q / E   Z / X", "Gira e inclina o objeto (só enquanto segura)." },
		{ "⌨️ 1 a 7", "Usa as habilidades (liberadas por nível)." },
		{ "⌨️ Shift", "Correr.   Espaço: pular / levantar do chão / escapar quando te agarram (aperte várias vezes)." },
		{ "⌨️ G", "Solta tudo que está segurando." },
		{ "⌨️ M", "Abre e fecha este menu." },
		{ "🎮 Controle", "R1 agarra/solta · R2 carrega e arremessa · D-pad ajusta a distância." },
		{ "📱 Celular", "Toque num objeto para agarrar. Use os botões ARREMESSAR (segure), SOLTAR e ± distância." },
		{ "💡 Dica", "Arremessos longos dão moedas, XP e recordes. Combos multiplicam os ganhos. Explore os tubos de vento para chegar às ilhas!" },
	}
	for i, l in lines do
		local row = Theme.panel(content, { size = UDim2.new(1, -12, 0, 52) })
		row.LayoutOrder = i
		Theme.text(row, { text = l[1], font = Theme.Title, size = 16, color = P.Accent, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0.32, 0, 1, 0), position = UDim2.fromOffset(14, 0) })
		Theme.text(row, { text = l[2], size = 14, alignX = Enum.TextXAlignment.Left, wrap = true, frame = UDim2.new(0.66, -20, 1, 0), position = UDim2.new(0.33, 0, 0, 0) })
	end
end

-- Abrir / fechar --------------------------------------------------------------------------------------------------------------------------------

function Menu.refresh()
	if not isOpen then
		return
	end
	clear()
	refreshWallet()
	local fn = buildTab[currentTab]
	if fn then
		fn()
	end
	for id, b in tabButtons do
		local active = id == currentTab
		Theme.tween(b, 0.12, { BackgroundColor3 = active and P.Accent or P.PanelLight, TextColor3 = active and P.Ink or P.White })
	end
end

function Menu.setTab(id: string)
	currentTab = id
	content.CanvasPosition = Vector2.zero
	Menu.refresh()
	Audio.ui("Ui", 0.25, 1.1)
end

function Menu.open(tab: string?)
	if tab then
		currentTab = tab
	end
	isOpen = true
	gui.Enabled = true
	window.Position = UDim2.fromScale(0.5, 0.56)
	Theme.tween(window, 0.22, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
	Menu.refresh()
	Audio.ui("Ui", 0.3)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function Menu.close()
	if not isOpen then
		return
	end
	isOpen = false
	gui.Enabled = false
end

function Menu.toggle()
	if isOpen then
		Menu.close()
	else
		Menu.open()
	end
end

function Menu.isOpen(): boolean
	return isOpen
end

function Menu.init()
	gui = Theme.new("ScreenGui", { Name = "TV_Menu", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	local dim = Theme.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false, Parent = gui, Name = "Dim" })
	dim.Activated:Connect(Menu.close)

	window = Theme.panel(gui, { size = UDim2.fromOffset(980, 600), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), name = "Window", radius = 20 })
	Theme.new("UISizeConstraint", { MaxSize = Vector2.new(980, 600), Parent = window })
	local sc = Theme.new("UIScale", { Parent = window })
	local function rescale()
		local vs = workspace.CurrentCamera.ViewportSize
		sc.Scale = math.clamp(math.min(vs.X / 1040, vs.Y / 660), 0.5, 1.15)
	end
	rescale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

	titleLabel = Theme.text(window, { text = Config.GameName .. "  —  MENU", font = Theme.Title, size = 28, color = P.Accent, alignX = Enum.TextXAlignment.Left, frame = UDim2.new(0, 400, 0, 44), position = UDim2.fromOffset(24, 10) })
	walletLabel = Theme.text(window, { text = "", font = Theme.Title, size = 22, color = P.White, alignX = Enum.TextXAlignment.Right, frame = UDim2.new(0, 360, 0, 44), position = UDim2.new(1, -90, 0, 10) })
	Theme.button(window, { text = "✕", size = UDim2.fromOffset(42, 42), position = UDim2.new(1, -18, 0, 12), anchor = Vector2.new(1, 0), color = P.Red, textColor = P.White, textSize = 22, onClick = Menu.close })

	-- abas
	local tabs = Theme.new("Frame", { Size = UDim2.fromOffset(220, 520), Position = UDim2.fromOffset(16, 66), BackgroundTransparency = 1, Parent = window })
	Theme.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabs })
	tabButtons = {}
	for i, t in TABS do
		local b = Theme.button(tabs, {
			text = t.label,
			size = UDim2.new(1, 0, 0, 50),
			color = P.PanelLight,
			textColor = P.White,
			textSize = 17,
			onClick = function()
				Menu.setTab(t.id)
			end,
		})
		b.LayoutOrder = i
		b.TextXAlignment = Enum.TextXAlignment.Left
		Theme.padding(b, 10)
		tabButtons[t.id] = b
	end

	-- conteudo
	content = Theme.new("ScrollingFrame", {
		Size = UDim2.fromOffset(700, 520),
		Position = UDim2.fromOffset(250, 66),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = P.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = window,
		Name = "Content",
	})
	Theme.padding(content, 4)

	Store.Changed:Connect(function(key)
		if isOpen and (key == "Coins" or key == "Toys" or key == "Level" or key == "SkillPoints" or key == "Upgrades" or key == "Tether" or key == "Trail" or key == "OwnedTethers" or key == "OwnedTrails") then
			Menu.refresh()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.M and not processed then
			Menu.toggle()
		elseif input.KeyCode == Enum.KeyCode.Escape and isOpen then
			Menu.close()
		end
	end)
	HUD.onMenu = Menu.toggle
end

return Menu
