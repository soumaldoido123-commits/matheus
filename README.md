# Jogos de Roblox em um único script

Cada arquivo é um jogo completo. Para jogar: no Roblox Studio, crie um jogo **Baseplate**,
adicione um **LocalScript** em **StarterPlayer → StarterPlayerScripts**, cole o código e aperte **Play**.

## TrilhaInfinita.lua — Trilha Infinita 4x4
Caminhonete off-road com física de suspensão realista (mola e amortecedor por roda,
escorregamento de pneu, transferência de peso, câmbio automático de 6 marchas, 4x4,
freio de mão) num mapa infinito gerado com terreno. A cada trecho aparece um desafio
(troncos, pedras, lama, subida, ponte estreita, rio, rampa, gangorra, encosta, toras soltas).
Desça da caminhonete, pegue cargas com física, coloque na caçamba e entregue no próximo posto.

## RoboTitan.lua — TITAN X-9: Cidade em Ruínas
Robôs gigantes numa cidade destrutível, com inimigos, ondas e chefão.

Os controles estão no começo de cada script.

## Equipe de cinema (Claude Code)
Em `.claude/agents/` estão 13 agentes especialistas (roteiro, pesquisa de humanidade, caçador de clichês,
fotografia, câmera, ângulos, movimento, cores, direção de arte, animação, música, som e montagem).
A skill `/cinema` (`.claude/skills/cinema/SKILL.md`) coordena a equipe em 3 rodadas (proposta, revisão
cruzada e fechamento) e entrega um prompt de vídeo, animação ou música com cara de feito por humanos.
