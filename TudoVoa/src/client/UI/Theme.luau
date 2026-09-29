--!nonstrict
--[[
	Theme: visual da interface (cores, fontes e construtores de componentes).
	Estilo "arcade cosmico": paineis azul-noite arredondados, brilho dourado, fonte FredokaOne.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Theme = {}

Theme.P = Config.Palette
Theme.Title = Enum.Font.FredokaOne
Theme.Body = Enum.Font.GothamMedium
Theme.Bold = Enum.Font.GothamBold

local P = Theme.P

function Theme.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Theme.corner(parent: Instance, radius: number?)
	return Theme.new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?)
	return Theme.new("UIStroke", {
		Color = color or Color3.new(1, 1, 1),
		Thickness = thickness or 2,
		Transparency = transparency or 0.75,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Theme.gradient(parent: Instance, c0: Color3, c1: Color3, rotation: number?)
	return Theme.new("UIGradient", {
		Color = ColorSequence.new(c0, c1),
		Rotation = rotation or 90,
		Parent = parent,
	})
end

function Theme.padding(parent: Instance, all: number)
	return Theme.new("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
		Parent = parent,
	})
end

-- Painel padrao (fundo azul-noite com gradiente e borda suave)
function Theme.panel(parent: Instance, props: { [string]: any }?): Frame
	props = props or {}
	local useGradient = props.gradient ~= false
	local f = Theme.new("Frame", {
		BackgroundColor3 = useGradient and Color3.new(1, 1, 1) or (props.color or P.Panel),
		BackgroundTransparency = props.transparency or 0.08,
		Size = props.size or UDim2.fromOffset(200, 100),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		ClipsDescendants = props.clip or false,
		Name = props.name or "Panel",
		Visible = props.visible ~= false,
		ZIndex = props.z or 1,
		Parent = parent,
	})
	Theme.corner(f, props.radius or 14)
	Theme.stroke(f, props.strokeColor or P.White, 2, props.strokeTransparency or 0.82)
	if useGradient then
		-- o UIGradient multiplica a cor de fundo: por isso o fundo e branco e o gradiente da a cor
		Theme.gradient(f, props.color and props.color:Lerp(Color3.new(1, 1, 1), 0.06) or P.PanelLight, props.color2 or P.Ink, 90)
	end
	return f
end

function Theme.text(parent: Instance, props: { [string]: any }): TextLabel
	return Theme.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.font or Theme.Body,
		Text = props.text or "",
		TextColor3 = props.color or P.White,
		TextSize = props.size or 18,
		TextXAlignment = props.alignX or Enum.TextXAlignment.Center,
		TextYAlignment = props.alignY or Enum.TextYAlignment.Center,
		TextScaled = props.scaled or false,
		TextWrapped = props.wrap or false,
		RichText = props.rich ~= false,
		Size = props.frame or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		TextStrokeTransparency = props.stroke or 1,
		TextStrokeColor3 = props.strokeColor or P.Ink,
		Name = props.name or "Text",
		ZIndex = props.z or 1,
		Parent = parent,
	})
end

-- Botao com efeito de hover/clique. Retorna o TextButton.
function Theme.button(parent: Instance, props: { [string]: any }): TextButton
	local base = props.color or P.Accent
	local b = Theme.new("TextButton", {
		BackgroundColor3 = base,
		AutoButtonColor = false,
		Font = props.font or Theme.Title,
		Text = props.text or "",
		TextColor3 = props.textColor or P.Ink,
		TextSize = props.textSize or 18,
		TextWrapped = true,
		Size = props.size or UDim2.fromOffset(140, 42),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		Name = props.name or "Button",
		ZIndex = props.z or 1,
		Parent = parent,
	})
	Theme.corner(b, props.radius or 10)
	Theme.stroke(b, Color3.new(1, 1, 1), 2, 0.7)
	local scale = Theme.new("UIScale", { Scale = 1, Parent = b })
	b.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.2) }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.94 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1.04 }):Play()
	end)
	if props.onClick then
		b.Activated:Connect(props.onClick)
	end
	return b
end

function Theme.tween(inst: Instance, time: number, goal: { [string]: any }, style: any?, dir: any?): Tween
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

-- Barra de progresso simples. Retorna { frame, fill, set(fraction) }
function Theme.bar(parent: Instance, props: { [string]: any }): any
	local frame = Theme.new("Frame", {
		BackgroundColor3 = P.Ink,
		BackgroundTransparency = 0.25,
		Size = props.size or UDim2.new(1, 0, 0, 14),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		ClipsDescendants = true,
		Name = props.name or "Bar",
		Parent = parent,
	})
	Theme.corner(frame, props.radius or 8)
	local fill = Theme.new("Frame", {
		BackgroundColor3 = props.gradient and Color3.new(1, 1, 1) or (props.color or P.Accent),
		Size = UDim2.fromScale(0, 1),
		Name = "Fill",
		Parent = frame,
	})
	Theme.corner(fill, props.radius or 8)
	if props.gradient then
		Theme.gradient(fill, props.color or P.Accent, props.gradient, 0)
	end
	local bar = { frame = frame, fill = fill }
	function bar.set(fraction: number, instant: boolean?)
		fraction = math.clamp(fraction, 0, 1)
		if instant then
			fill.Size = UDim2.fromScale(fraction, 1)
		else
			Theme.tween(fill, 0.25, { Size = UDim2.fromScale(fraction, 1) })
		end
	end
	return bar
end

return Theme
