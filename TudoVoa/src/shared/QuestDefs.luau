--!nonstrict
--[[
	Missoes: 3 ativas por jogador. Ao completar, paga moedas + XP e sorteia outra.
	kind = o tipo de evento que conta progresso (os modulos do servidor chamam Quests.report).
]]

local QuestDefs = {}

QuestDefs.SlotCount = 3

QuestDefs.List = {
	{ id = "throws10", kind = "throw", goal = 10, text = "Arremesse 10 objetos longe (40+ studs)", coins = 70, xp = 90, icon = "🎯" },
	{ id = "far150", kind = "far", goal = 3, text = "Faça 3 arremessos acima de 150 studs", coins = 150, xp = 170, icon = "🚀", minLevel = 3 },
	{ id = "far300", kind = "far300", goal = 1, text = "Arremesse a mais de 300 studs", coins = 320, xp = 300, icon = "🌠", minLevel = 7 },
	{ id = "hits5", kind = "hit", goal = 5, text = "Acerte 5 pessoas ou robôs", coins = 110, xp = 130, icon = "💥", minLevel = 2 },
	{ id = "targets5", kind = "target", goal = 5, text = "Acerte 5 alvos no Tiro ao Alvo", coins = 120, xp = 130, icon = "🏹" },
	{ id = "hoops2", kind = "hoop", goal = 2, text = "Faça 2 cestas", coins = 140, xp = 150, icon = "🏀" },
	{ id = "bots8", kind = "bot", goal = 8, text = "Derrube 8 robôs da Arena", coins = 190, xp = 210, icon = "🤖", minLevel = 4 },
	{ id = "coins100", kind = "coin", goal = 100, text = "Pegue 100 moedas do chão", coins = 90, xp = 100, icon = "🪙" },
	{ id = "abil6", kind = "ability", goal = 6, text = "Use habilidades 6 vezes", coins = 100, xp = 110, icon = "⚡", minLevel = 2 },
	{ id = "strike", kind = "strike", goal = 1, text = "Faça um STRIKE no Boliche Gigante", coins = 170, xp = 180, icon = "🎳", minLevel = 3 },
	{ id = "boss300", kind = "boss", goal = 300, text = "Cause 300 de dano ao Golem", coins = 420, xp = 360, icon = "🗿", minLevel = 8 },
	{ id = "boom3", kind = "boomerang", goal = 3, text = "Pegue o Bumerangue 3 vezes", coins = 130, xp = 140, icon = "🪃", minLevel = 7 },
	{ id = "peak", kind = "summit", goal = 1, text = "Conquiste o Pico da Montanha", coins = 200, xp = 220, icon = "🏔️", minLevel = 5 },
}

QuestDefs.ById = {}
for _, q in QuestDefs.List do
	QuestDefs.ById[q.id] = q
end

return QuestDefs
