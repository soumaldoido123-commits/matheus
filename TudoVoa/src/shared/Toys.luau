--!nonstrict
--[[
	Catalogo de brinquedos. Compartilhado: o servidor constroi (ToyFactory) e o cliente
	usa os dados na loja/inventario.

	behavior (o que ele faz de especial):
	  none        nada de especial
	  bouncy      quica muito
	  splat       explode em respingos quando bate forte
	  float       flutua / cai devagar (gravidade reduzida)
	  balloon     sobe sozinho
	  glide       plana: ganha sustentacao ao ser arremessado
	  heavy       pesadao; amassa o que acertar
	  rocket      propulsor: acelera para frente e explode no impacto
	  boomerang   volta para quem arremessou
	  explosive   explode apos o impacto/pavio
	  sticky      gruda no que acertar
	  pinata      solta moedas ao levar pancada
	  slippery    sem atrito
	  flop        pula sozinho quando esta no chao
	  trampoline  joga para cima quem (ou o que) cair em cima
	  gravity     cria uma bolha de baixa gravidade ao bater
	  magnet      puxa metais/objetos leves por perto
	  crystal     raro: brilha e paga moedas extra ao ser arremessado longe
	  squeak      apita ao bater e boia na agua
]]

local Toys = {}

Toys.Rarity = {
	["Comum"] = { color = Color3.fromRGB(190, 198, 220), order = 1 },
	["Incomum"] = { color = Color3.fromRGB(110, 230, 130), order = 2 },
	["Raro"] = { color = Color3.fromRGB(80, 170, 255), order = 3 },
	["Épico"] = { color = Color3.fromRGB(190, 110, 255), order = 4 },
	["Lendário"] = { color = Color3.fromRGB(255, 190, 60), order = 5 },
}

local function v3(x, y, z)
	return Vector3.new(x, y, z)
end

-- world: peso de aparicao por bioma (Hub, Farm, Snow, Volcano, Beach, Sky, Cave, Factory)
Toys.List = {
	{
		id = "caixa", name = "Caixote", icon = "📦", price = 0, level = 1, rarity = "Comum",
		behavior = "none", desc = "Clássico. Simples. Voa bem.",
		shape = "Block", size = v3(3, 3, 3), color = Color3.fromRGB(176, 128, 78), material = "WoodPlanks",
		density = 0.7, friction = 0.6, elasticity = 0.18,
		world = { Hub = 3, Farm = 5, Snow = 2, Volcano = 2, Beach = 3, Factory = 5 },
	},
	{
		id = "barril", name = "Barril", icon = "🛢️", price = 0, level = 1, rarity = "Comum",
		behavior = "none", desc = "Rola pra todo lado e faz um barulho ótimo.",
		shape = "Cylinder", size = v3(4, 3.2, 3.2), color = Color3.fromRGB(196, 78, 60), material = "Metal",
		density = 0.9, friction = 0.45, elasticity = 0.2,
		world = { Hub = 2, Farm = 3, Volcano = 3, Beach = 3, Factory = 4 },
	},
	{
		id = "bola", name = "Bola Maluca", icon = "⚽", price = 0, level = 1, rarity = "Comum",
		behavior = "bouncy", desc = "Quica muito. MUITO. Ninguém sabe onde ela vai parar.",
		shape = "Ball", size = v3(3.2, 3.2, 3.2), color = Color3.fromRGB(255, 96, 150), material = "SmoothPlastic",
		density = 0.25, friction = 0.4, elasticity = 0.95,
		world = { Hub = 4, Farm = 2, Snow = 2, Beach = 5, Sky = 4 },
	},
	{
		id = "melancia", name = "Melancia", icon = "🍉", price = 0, level = 1, rarity = "Comum",
		behavior = "splat", desc = "Se bater forte demais, vira sopa. Deliciosa e perigosa.",
		shape = "Ball", size = v3(3.8, 3.8, 3.8), color = Color3.fromRGB(70, 170, 80), material = "SmoothPlastic",
		density = 0.55, friction = 0.6, elasticity = 0.1,
		world = { Farm = 6, Beach = 4, Hub = 1 },
	},
	{
		id = "boliche", name = "Bola de Boliche", icon = "🎳", price = 130, level = 4, rarity = "Incomum",
		behavior = "heavy", desc = "Pesada, veloz e sem piedade. Faz strike em gente também.",
		shape = "Ball", size = v3(3, 3, 3), color = Color3.fromRGB(46, 60, 170), material = "SmoothPlastic",
		density = 4.5, friction = 0.25, elasticity = 0.08,
		world = { Hub = 2 },
	},
	{
		id = "pena", name = "Pena Gigante", icon = "🪶", price = 60, level = 2, rarity = "Comum",
		behavior = "float", desc = "Cai devagarzinho. Perfeita para provocar quem está embaixo.",
		shape = "Block", size = v3(0.5, 7, 2.6), color = Color3.fromRGB(255, 240, 210), material = "Fabric",
		density = 0.12, friction = 0.9, elasticity = 0.05,
		world = { Farm = 3, Sky = 6, Beach = 1 },
	},
	{
		id = "patinho", name = "Patinho de Borracha", icon = "🦆", price = 100, level = 2, rarity = "Comum",
		behavior = "squeak", desc = "Apita quando bate e boia na água. Nunca ri do pato.",
		build = "duck", shape = "Block", size = v3(3.2, 3, 4), color = Color3.fromRGB(255, 214, 40), material = "SmoothPlastic",
		density = 0.16, friction = 0.35, elasticity = 0.55,
		world = { Beach = 7, Hub = 1 },
	},
	{
		id = "balao", name = "Balão Gigante", icon = "🎈", price = 90, level = 3, rarity = "Comum",
		behavior = "balloon", desc = "Sobe sozinho. Prenda-se a ele (com o cabo) e voe.",
		build = "balloon", shape = "Ball", size = v3(5, 5.8, 5), color = Color3.fromRGB(255, 70, 90), material = "SmoothPlastic",
		density = 0.03, friction = 0.4, elasticity = 0.7,
		world = { Beach = 3, Sky = 4, Hub = 2 },
	},
	{
		id = "aviao", name = "Aviãozinho", icon = "✈️", price = 80, level = 3, rarity = "Incomum",
		behavior = "glide", desc = "Plana por uma eternidade. Arremesse com o vento a favor.",
		build = "plane", shape = "Block", size = v3(6, 0.6, 5), color = Color3.fromRGB(245, 248, 255), material = "SmoothPlastic",
		density = 0.2, friction = 0.4, elasticity = 0.1,
		world = { Snow = 3, Sky = 6, Hub = 1 },
	},
	{
		id = "peixe", name = "Peixe Escorregadio", icon = "🐟", price = 180, level = 4, rarity = "Incomum",
		behavior = "flop", desc = "Pula sozinho no chão. Quase impossível de segurar (ele reclama).",
		build = "fish", shape = "Block", size = v3(1.6, 2.4, 5), color = Color3.fromRGB(80, 170, 230), material = "SmoothPlastic",
		density = 0.5, friction = 0.05, elasticity = 0.45,
		world = { Beach = 6 },
	},
	{
		id = "pizza", name = "Pizza Voadora", icon = "🍕", price = 120, level = 4, rarity = "Incomum",
		behavior = "glide", desc = "Um disco de queijo. Gira, plana e voa mais longe que tudo.",
		build = "pizza", shape = "Cylinder", size = v3(0.5, 5, 5), color = Color3.fromRGB(255, 190, 70), material = "SmoothPlastic",
		density = 0.25, friction = 0.3, elasticity = 0.15,
		world = { Hub = 3, Factory = 3 },
	},
	{
		id = "gelo", name = "Bloco de Gelo", icon = "🧊", price = 200, level = 5, rarity = "Incomum",
		behavior = "slippery", desc = "Sem atrito nenhum. Desliza infinitamente.",
		shape = "Block", size = v3(3.4, 3.4, 3.4), color = Color3.fromRGB(170, 225, 255), material = "Ice",
		density = 0.9, friction = 0.0, elasticity = 0.1, transparency = 0.25,
		world = { Snow = 9 },
	},
	{
		id = "bigorna", name = "Bigorna", icon = "⚓", price = 150, level = 5, rarity = "Incomum",
		behavior = "heavy", desc = "Muito pesada. Voa curto, cai forte. Cuidado com a cabeça.",
		build = "anvil", shape = "Block", size = v3(3, 2.6, 5), color = Color3.fromRGB(58, 60, 70), material = "Metal",
		density = 8, friction = 0.5, elasticity = 0.03,
		world = { Volcano = 4, Factory = 5, Farm = 1 },
	},
	{
		id = "sofa", name = "Sofá Voador", icon = "🛋️", price = 220, level = 6, rarity = "Raro",
		behavior = "heavy", desc = "Confortável até ser arremessado em alguém.",
		build = "sofa", shape = "Block", size = v3(7, 3, 3), color = Color3.fromRGB(150, 60, 190), material = "Fabric",
		density = 1.8, friction = 0.7, elasticity = 0.08,
		world = { Hub = 1, Farm = 2 },
	},
	{
		id = "foguete", name = "Foguete", icon = "🚀", price = 300, level = 6, rarity = "Raro",
		behavior = "rocket", desc = "Liga o propulsor ao ser arremessado e explode no impacto.",
		build = "rocket", shape = "Cylinder", size = v3(6, 2, 2), color = Color3.fromRGB(240, 244, 255), material = "Metal",
		density = 0.6, friction = 0.4, elasticity = 0.05,
		world = { Volcano = 3, Sky = 2 },
	},
	{
		id = "bumerangue", name = "Bumerangue", icon = "🪃", price = 250, level = 7, rarity = "Raro",
		behavior = "boomerang", desc = "Curva e VOLTA pra você. Pegue-o para ganhar moedas.",
		build = "boomerang", shape = "Block", size = v3(6, 0.6, 6), color = Color3.fromRGB(255, 160, 40), material = "WoodPlanks",
		density = 0.35, friction = 0.4, elasticity = 0.2,
		world = { Beach = 2, Farm = 1 },
	},
	{
		id = "dinamite", name = "Dinamite", icon = "🧨", price = 400, level = 8, rarity = "Raro",
		behavior = "explosive", desc = "Explode 2 segundos depois de um impacto forte. Devagar!",
		build = "dynamite", shape = "Cylinder", size = v3(4, 1.4, 1.4), color = Color3.fromRGB(210, 40, 40), material = "SmoothPlastic",
		density = 0.7, friction = 0.5, elasticity = 0.1,
		world = { Volcano = 5, Factory = 2 },
	},
	{
		id = "trampolim", name = "Cama Elástica", icon = "🤸", price = 450, level = 8, rarity = "Raro",
		behavior = "trampoline", desc = "Quem cair em cima é lançado pro alto. Empilhe vários!",
		build = "trampoline", shape = "Cylinder", size = v3(1.2, 9, 9), color = Color3.fromRGB(50, 130, 255), material = "SmoothPlastic",
		density = 0.6, friction = 0.7, elasticity = 0.9,
		world = { Hub = 1, Farm = 1 },
	},
	{
		id = "gosma", name = "Gosma Grudenta", icon = "🦠", price = 350, level = 9, rarity = "Épico",
		behavior = "sticky", desc = "Gruda em tudo que acertar. Inclusive amigos.",
		shape = "Ball", size = v3(3.2, 3.2, 3.2), color = Color3.fromRGB(120, 255, 90), material = "Neon",
		density = 0.4, friction = 1, elasticity = 0.05, transparency = 0.15,
		world = { Volcano = 1 },
	},
	{
		id = "pinata", name = "Piñata", icon = "🪅", price = 500, level = 10, rarity = "Épico",
		behavior = "pinata", desc = "Cada pancada solta moedas. Bata com força!",
		build = "pinata", shape = "Block", size = v3(4, 4, 3), color = Color3.fromRGB(255, 90, 190), material = "Fabric",
		density = 0.3, friction = 0.6, elasticity = 0.3,
		world = { Hub = 1, Sky = 2 },
	},
	{
		id = "ima", name = "Ímã Gigante", icon = "🧲", price = 500, level = 11, rarity = "Épico",
		behavior = "magnet", desc = "Puxa caixotes, barris e bigornas quando fica parado.",
		build = "magnet", shape = "Block", size = v3(5, 5, 1.8), color = Color3.fromRGB(230, 40, 60), material = "Metal",
		density = 2.2, friction = 0.5, elasticity = 0.05,
		world = { Factory = 3 },
	},
	{
		id = "orbe", name = "Orbe Gravitacional", icon = "🔮", price = 550, level = 12, rarity = "Épico",
		behavior = "gravity", desc = "Ao bater, cria uma bolha onde tudo flutua por 8 segundos.",
		shape = "Ball", size = v3(3, 3, 3), color = Color3.fromRGB(160, 90, 255), material = "Neon",
		density = 0.3, friction = 0.3, elasticity = 0.6,
		world = { Sky = 3 },
	},
	{
		id = "piano", name = "Piano de Cauda", icon = "🎹", price = 650, level = 13, rarity = "Épico",
		behavior = "heavy", desc = "Enorme. Precisa de muita Força. Cai com classe.",
		build = "piano", shape = "Block", size = v3(6, 4, 7), color = Color3.fromRGB(30, 30, 38), material = "SmoothPlastic",
		density = 1.4, friction = 0.5, elasticity = 0.05,
		world = { Hub = 1 },
	},
	{
		id = "cristal", name = "Cristal Raro", icon = "💎", price = 800, level = 15, rarity = "Lendário",
		behavior = "crystal", desc = "Brilha no escuro e paga moedas extras nos arremessos longos.",
		build = "crystal", shape = "Block", size = v3(2.6, 5, 2.6), color = Color3.fromRGB(90, 235, 255), material = "Neon",
		density = 0.8, friction = 0.3, elasticity = 0.3, transparency = 0.2,
		world = { Cave = 8, Sky = 2 },
	},
}

Toys.ById = {}
for _, t in Toys.List do
	Toys.ById[t.id] = t
end

-- Lista dos que aparecem espalhados pelo mundo (world[bioma] > 0)
function Toys.worldPool(biome: string): { any }
	local out = {}
	for _, t in Toys.List do
		local w = t.world and t.world[biome]
		if w and w > 0 then
			table.insert(out, t)
		end
	end
	return out
end

return Toys
