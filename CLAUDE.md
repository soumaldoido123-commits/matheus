# Contexto do projeto (passagem de sessão)

Projeto principal: **TudoVoa/** — "TUDO VOA! — Ilhas do Caos", jogo de física multiplayer para Roblox
(agarrar/carregar/arremessar objetos e pessoas com um cabo de energia). Não é clone de "Fling Things and People":
mecânicas próprias (arremesso carregado com trajetória prevista, esperneio para escapar, habilidades, Golem co-op etc.).
O usuário fala **português** — responda em português. Objetivo dele: continuar melhorando o jogo até ele mandar parar.

Branch de trabalho: `claude/zealous-cerf-xvhqag`. Não criar PR sem o usuário pedir.
Commits terminam com as linhas `Co-Authored-By` / `Claude-Session` que a sessão indicar.

## Estado atual
Jogo completo e commitado: cabo de energia + ragdoll, 24 brinquedos, 7 habilidades, XP/níveis/upgrades/loja/missões,
mundo procedural (5 biomas, ilhas flutuantes, caverna), Tiro ao Alvo, Cestas, Boliche, Arena de robôs, Golem chefão,
eventos do mundo, Vila dos Jogadores (8 casas), emotes (H/B/N), UI, animações procedurais (Motor6D).
**Nunca foi rodado no Roblox Studio de verdade** — só validado por analisador + simulador (sem física/gráficos).
Todo o feedback real (bugs, "sensação" da física, balanceamento) ainda está pendente: peça ao usuário o Output do Studio.

## Como abrir / rodar
- Pronto: abrir `TudoVoa/build/TudoVoa.rbxlx` no Studio e dar Play.
- Rebuild: `cd TudoVoa && rojo build default.project.json -o build/TudoVoa.rbxlx` (Rojo 7.7.0)
- Ao vivo: `rojo serve` + plugin do Rojo no Studio.
- Para o Claude enxergar o Studio: rodar o Claude Code **local** + servidor MCP do Roblox Studio
  (`Roblox/studio-rust-mcp-server`). Na nuvem não há acesso ao Studio.

## Validação (sem Studio) — rodar depois de qualquer edição
```
cd TudoVoa/tools && npm install
node check.mjs            # analisador Luau (esperado: 0 erros, 1 aviso de LoadCharacter deprecated — fallback proposital)
node api-check.mjs        # nomes de API (5 "desconhecidos" são chaves de tabelas, falsos positivos: clip, hook, lightInfluence, rich, scaled)
node enum-check.mjs       # todo Enum.X.Y existe
node sim/smoke.mjs        # servidor inteiro num mock (esperado: falhas 0)
node sim/smoke-client.mjs # cliente inteiro num mock (esperado: falhas 0)
node sim/heightmap.mjs mapa.png   # imagem do mapa
```

## Arquitetura (TudoVoa/src)
- `shared/`: Config (balanceamento — quase tudo se ajusta aqui), Toys, AbilityDefs, QuestDefs, Remotes, Util.
- `server/`: Grab (validação/ownership/leash/esperneio), Ragdoll, Physics, Impact, Blasts, ToyFactory/ToyPassive/ToySpawner,
  AbilityService, Data (DataStore), Shop, Quests, Scoring, Board, Zones, Atmosphere; `World/*` (WorldGen voxel, biomas, Scenery);
  `Activities/*` (Targets, Hoops, Bowling, Arena, Boss, Events, Extras, Plots) — carregados automaticamente da pasta.
- `client/`: GrabController (AlignPosition/AlignOrientation locais), Tether (beams), Pose (braços/emotes), Movement,
  ToyPhysics, Fx, Audio, DecorAnim, Ambient, AbilityBar, `UI/*`, `Activities/*`.

## Decisões / armadilhas já resolvidas (não desfazer sem motivo)
- Ao agarrar personagem: `Ragdoll.enable` primeiro, `task.wait(0.06)`, **só depois** trocar network owner (senão o assembly divide depois do setOwner).
- `HeldBy` é reservado antes do yield para evitar agarrão duplo.
- Rotação do objeto: teclas **Z/X** (giro) e **C/V** (inclinação); **E** é dos ProximityPrompts.
- `AbilityDefs` (shared) e `AbilityService` (server) têm nomes diferentes de propósito: nomes de módulo duplicados colidem no simulador.
- UIGradient multiplica BackgroundColor3: usar fundo branco + cor no gradiente.
- `NumberRange * number` não existe no Roblox: usar `NumberRange.new(a*k, b*k)`.
- Inicialização tolerante a falhas: `Scenery.build` em estágios com pcall; server/client carregam módulos com xpcall.
- Vila dos Jogadores em `Config.World.Village` (160,160), escolhida por ser plana; a área é reservada no `Nature` antes de espalhar árvores.
- Data: em Studio sem acesso à API, a persistência é desligada na hora (senão o spawn atrasa ~6s).

## Próximos passos sugeridos
1. Abrir no Studio, dar Play, corrigir qualquer erro vermelho do Output.
2. Ajustar "sensação": `Config.Grab` (Responsiveness, MaxVelocity), `Config.Throw` (MinSpeed/MaxSpeed/MassExponent), `Config.Ragdoll`.
3. Trocar sons `rbxasset://` por `rbxassetid://` (Config.Sounds) e, se quiser, animações reais no lugar das procedurais.
4. Playtest multiplayer (2+ jogadores): agarrar pessoas, escapar, Arena, Golem.
5. Polimento visual do mapa e mais brinquedos/habilidades.
