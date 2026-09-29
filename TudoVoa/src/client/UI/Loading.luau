--!nonstrict
--[[
	Loading: tela de carregamento enquanto o servidor gera o mundo e o personagem nasce.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Theme = require(script.Parent:WaitForChild("Theme"))

local Loading = {}

local P = Theme.P
local player = Players.LocalPlayer

local TIPS = {
	"Clique em um objeto para agarrar. Clique com o botão direito e segure para carregar a força!",
	"Role o mouse enquanto segura algo para aproximar ou afastar.",
	"Pessoas também podem ser agarradas... e elas esperneiam! (Espaço repetido para escapar)",
	"Q/E giram o objeto, Z/X inclinam. Mire com cuidado!",
	"Suba de nível para desbloquear habilidades: Puxão, Impulso, Estase, Onda de Choque...",
	"Estase congela objetos no ar: empilhe e construa escadas!",
	"O Caça-Moedas na praça dá um prêmio a cada 15 minutos.",
	"Os tubos de vento levam às ilhas flutuantes. Lá em cima tem arena, chefão e tesouros.",
	"Arremessos longos dão moedas, XP e entram no placar de recordes.",
	"Combos: arremesse de novo em até 6 segundos para multiplicar as moedas.",
	"O Foguete voa sozinho, o Bumerangue volta, a Dinamite espera... escolha seu estilo!",
	"Modo Pacífico no Menu impede que te agarrem (e você não agarra ninguém).",
}

local gui: ScreenGui
local bar
local textLabel
local tipLabel
local done = false

function Loading.init()
	gui = Theme.new("ScreenGui", {
		Name = "TV_Loading",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local bg = Theme.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = gui, Name = "Bg" })
	Theme.gradient(bg, Color3.fromRGB(38, 28, 90), Color3.fromRGB(10, 12, 32), 90)

	-- estrelas
	local rng = Random.new(7)
	for _ = 1, 60 do
		local s = Theme.new("Frame", {
			Size = UDim2.fromOffset(rng:NextInteger(2, 5), rng:NextInteger(2, 5)),
			Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber()),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = rng:NextNumber(0.2, 0.8),
			BorderSizePixel = 0,
			Parent = bg,
		})
		Theme.corner(s, 3)
	end

	Theme.text(bg, {
		text = Config.GameName,
		font = Theme.Title,
		size = 96,
		color = P.Accent,
		frame = UDim2.new(1, 0, 0, 110),
		position = UDim2.new(0, 0, 0.26, 0),
		stroke = 0.1,
	})
	Theme.text(bg, {
		text = string.upper(Config.Subtitle),
		font = Theme.Title,
		size = 30,
		color = P.Accent2,
		frame = UDim2.new(1, 0, 0, 40),
		position = UDim2.new(0, 0, 0.26, 108),
		stroke = 0.3,
	})

	local barBox = Theme.new("Frame", { Size = UDim2.fromOffset(520, 22), Position = UDim2.fromScale(0.5, 0.62), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = P.Panel, Parent = bg })
	Theme.corner(barBox, 11)
	Theme.stroke(barBox, P.White, 2, 0.7)
	bar = Theme.bar(barBox, { size = UDim2.new(1, -8, 1, -8), position = UDim2.fromOffset(4, 4), color = P.Accent, gradient = P.Pink, radius = 8 })
	textLabel = Theme.text(bg, {
		text = "Conectando...",
		size = 20,
		font = Theme.Bold,
		color = P.White,
		frame = UDim2.fromOffset(520, 28),
		position = UDim2.fromScale(0.5, 0.62),
		anchor = Vector2.new(0.5, 0),
	})
	textLabel.Position = UDim2.new(0.5, 0, 0.62, 22)
	tipLabel = Theme.text(bg, {
		text = TIPS[1],
		size = 19,
		font = Theme.Body,
		color = P.Muted,
		wrap = true,
		frame = UDim2.fromOffset(640, 60),
		position = UDim2.new(0.5, 0, 0.8, 0),
		anchor = Vector2.new(0.5, 0),
	})

	task.spawn(function()
		local i = 1
		while gui.Parent and not done do
			tipLabel.Text = "💡 " .. TIPS[i]
			i = i % #TIPS + 1
			task.wait(4.5)
		end
	end)

	RunService.RenderStepped:Connect(function()
		if done then
			return
		end
		local p = workspace:GetAttribute("TV_Progress") or 0
		bar.set(p, false)
		textLabel.Text = workspace:GetAttribute("TV_LoadText") or "Carregando..."
	end)
end

function Loading.finish()
	if done then
		return
	end
	done = true
	local bg = gui:FindFirstChild("Bg")
	if bg then
		Theme.tween(bg, 0.8, { BackgroundTransparency = 1 })
		for _, d in bg:GetDescendants() do
			if d:IsA("TextLabel") then
				Theme.tween(d, 0.7, { TextTransparency = 1, TextStrokeTransparency = 1 })
			elseif d:IsA("Frame") then
				Theme.tween(d, 0.7, { BackgroundTransparency = 1 })
			elseif d:IsA("UIStroke") then
				Theme.tween(d, 0.7, { Transparency = 1 })
			end
		end
	end
	task.delay(1, function()
		gui:Destroy()
	end)
end

return Loading
