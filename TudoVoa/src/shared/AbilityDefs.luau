--!nonstrict
--[[
	Habilidades do jogador. Dados compartilhados (servidor valida, cliente mostra).
	kind = "instant": ativa na hora | "aim": usa a mira (ponto no mundo)
]]

local Abilities = {}

Abilities.List = {
	{
		id = "pull", name = "Puxão Magnético", icon = "🧲", key = "One", keyLabel = "1",
		cooldown = 5, level = 1, kind = "aim", range = 90,
		desc = "Puxa o objeto que você está mirando direto para as suas mãos.",
	},
	{
		id = "dash", name = "Impulso", icon = "⚡", key = "Two", keyLabel = "2",
		cooldown = 4.5, level = 2, kind = "instant",
		desc = "Um pulo turbinado para frente. Ótimo para atravessar o mapa.",
	},
	{
		id = "stasis", name = "Estase", icon = "❄️", key = "Three", keyLabel = "3",
		cooldown = 1.5, level = 4, kind = "aim", range = 120,
		desc = "Congela o objeto agarrado no ar (ou solta um congelado). Construa escadas!",
	},
	{
		id = "shock", name = "Onda de Choque", icon = "💥", key = "Four", keyLabel = "4",
		cooldown = 9, level = 6, kind = "instant", radius = 34,
		desc = "Explosão em volta de você: arremessa objetos e jogadores para longe.",
	},
	{
		id = "bubble", name = "Bolha Anti-Gravidade", icon = "🫧", key = "Five", keyLabel = "5",
		cooldown = 14, level = 9, kind = "aim", range = 110, radius = 26, duration = 9,
		desc = "Cria uma bolha onde tudo flutua. Arremessos ficam absurdos.",
	},
	{
		id = "hook", name = "Gancho", icon = "🪝", key = "Six", keyLabel = "6",
		cooldown = 3.5, level = 12, kind = "aim", range = 150,
		desc = "Lança um gancho e te puxa até o ponto mirado. Balance!",
	},
	{
		id = "shield", name = "Escudo Cósmico", icon = "🛡️", key = "Seven", keyLabel = "7",
		cooldown = 26, level = 16, kind = "instant", duration = 8,
		desc = "Ninguém consegue te agarrar ou te empurrar por 8 segundos.",
	},
}

Abilities.ById = {}
for i, a in Abilities.List do
	a.index = i
	Abilities.ById[a.id] = a
end

return Abilities
