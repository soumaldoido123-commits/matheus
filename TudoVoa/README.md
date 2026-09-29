# TUDO VOA! — Ilhas do Caos

Jogo de física do Roblox onde você **agarra, carrega e arremessa** objetos e pessoas com um cabo de energia,
explora uma ilha com biomas, sobe para ilhas flutuantes, enfrenta um chefão e sobe de nível.

Inspirado no gênero "arremessar coisas e pessoas", mas com mecânicas próprias: arremesso **carregado com trajetória
prevista**, **espernear** para escapar de quem te agarra, **habilidades**, **brinquedos com comportamentos únicos**,
**Arena com robôs**, **Golem chefão** e **eventos do mundo**.

## Como jogar (2 jeitos)

### 1) Abrir o arquivo pronto (mais fácil)
1. Abra o **Roblox Studio**.
2. `Arquivo → Abrir do arquivo` → escolha `TudoVoa/build/TudoVoa.rbxlx`.
3. Aperte **Play** (F5). O mundo é gerado em alguns segundos (tem tela de carregamento).
4. Para salvar dados de verdade (moedas, nível) no Studio: `Home → Game Settings → Security → Enable Studio Access to API Services`.
   Sem isso o jogo funciona normalmente, só não salva.

### 2) Com Rojo (para editar o código)
```bash
rojo build default.project.json -o build/TudoVoa.rbxlx   # gera o arquivo
rojo serve                                                # ou sincroniza ao vivo com o Studio
```

## Controles

| Tecla / botão | O que faz |
|---|---|
| **Clique esquerdo** | Agarra o objeto/pessoa sob a mira. Clique de novo para soltar |
| **Botão direito (segurar)** | Carrega a força do arremesso. **Solte** para arremessar. Uma linha mostra onde vai cair |
| **Scroll** | Aproxima/afasta o objeto |
| **Z / X**, **C / V** | Giram / inclinam o objeto |
| **1 – 7** | Habilidades (liberam por nível) |
| **Shift** | Correr |
| **Espaço** | Pular · levantar do chão · **escapar quando te agarram (aperte várias vezes)** |
| **G** | Solta tudo |
| **M** | Menu (loja, habilidades, cabo, recordes, ajustes, ajuda) |
| **E** | Interagir (loja, caça-moedas, canhões, baús, reivindicar casa) |
| **H / B / N** | Emotes: acenar, comemorar, dançar (todos veem) |
| Controle | R1 agarra · R2 carrega/arremessa · D-pad distância |
| Celular | Toque no objeto; botões ARREMESSAR (segure), AGARRAR/SOLTAR e ± distância |

## O que tem no jogo

- **Cabo de energia**: física real (AlignPosition/AlignOrientation), 2 cabos com upgrade, cores e rastros.
- **Pessoas viram ragdoll** quando agarradas/atingidas; quem é agarrado **espernea** para escapar.
- **24 brinquedos** com comportamento próprio: bola quicante, melancia que espirra, aviãozinho e pizza que **planam**,
  **foguete** que voa e explode, **bumerangue** que volta (pegue para ganhar moedas), **dinamite**, gosma que gruda,
  piñata que solta moedas, ímã, orbe de gravidade, cama elástica, cristal raro...
- **7 habilidades**: Puxão Magnético, Impulso, **Estase** (congela objetos no ar — construa escadas), Onda de Choque,
  Bolha Anti-Gravidade, **Gancho**, Escudo.
- **Progressão**: XP, níveis, pontos de habilidade (Potência, Alcance, Força, Recarga, Escapar, Cabo Duplo), moedas, loja.
- **Mundo procedural** de 1600×1600 studs: Praça Cósmica (zona segura), Fazenda Maluca, Montanha Gelada,
  Vulcão Furioso + deserto, Praia dos Ventos, Caverna de Cristal, 5 ilhas flutuantes, lagos, estradas, mar.
- **Atividades**: Tiro ao Alvo, Cestas, Boliche Gigante, **Arena do Caos** (ondas de robôs rolantes),
  **Golem Sucata** (chefão co-op), **eventos**: chuva de meteoros, gravidade lunar, chuva de moedas, erupção, hora do ouro.
- **Missões**: 3 missões ativas por vez (arremessar longe, acertar pessoas, arena, chefão...), com XP e moedas — aba Missões no menu (M) e painel na tela.
- **Vila dos Jogadores**: 8 casinhas para reivindicar e pintar; dentro do lote ninguém consegue te agarrar.
- **Emotes** procedurais (acenar, comemorar, dançar) feitos com Motor6D, sem assets de animação.
- **Canhões expressos**, tubos de vento até as ilhas, jump pads, gêiseres, caça-moedas, baús, picos para conquistar.
- **Ciclo dia/noite**, iluminação Future, animações procedurais de braços/tronco e do cenário.
- **Multiplayer**: tudo validado no servidor (distância, massa, velocidade máxima, recargas).

## Estrutura

```
TudoVoa/
├─ default.project.json        # projeto Rojo
├─ build/TudoVoa.rbxlx         # jogo pronto para abrir no Studio
├─ src/
│  ├─ shared/                  # Config, Toys, AbilityDefs, Remotes, Util
│  ├─ server/                  # Grab, Ragdoll, Impact, Abilities, Data, World/*, Activities/*
│  └─ client/                  # GrabController, Tether, Pose, Fx, UI/*, Activities/*
└─ tools/                      # validacao (veja abaixo)
```

## Ferramentas de desenvolvimento (`tools/`)

Não tenho como abrir o Studio na máquina de desenvolvimento, então o projeto traz sua própria verificação:

```bash
cd tools && npm install
node check.mjs          # analisador oficial do Luau (WASM) + definições reais da API do Roblox
node api-check.mjs      # confere se todo método/propriedade usado existe na API do Roblox
node enum-check.mjs     # confere se todo Enum.Tipo.Valor usado existe de verdade
node sim/smoke.mjs      # roda o servidor inteiro num mock do Roblox (mundo, agarrar, loja, arena, chefão...)
node sim/smoke-client.mjs   # roda o cliente inteiro (HUD, menu, efeitos, agarrar/arremessar)
node sim/heightmap.mjs mapa.png   # desenha o mapa do mundo
```

> O simulador **não** simula física nem renderização — ele pega erros de lógica e de API, não "sensação de jogo".
> Ajustes finos de balanceamento (forças, velocidades) ficam em `src/shared/Config.luau`.
