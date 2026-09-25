---
name: cinema
description: Coordena a equipe de 13 especialistas (roteiro, humanidade, clichês, fotografia, câmera, ângulos, movimento, cores, arte, animação, música, som, montagem) para transformar uma ideia em um prompt de vídeo, animação ou música que pareça feito por humanos. Use quando o usuário pedir um prompt para vídeo, filme, animação, clipe ou música, ou digitar /cinema.
---

# Equipe de cinema

Você é o **diretor**. Você não escreve as partes sozinho: você coordena os especialistas definidos em
`.claude/agents/` e junta o trabalho deles num resultado final coerente e com cara de humano.

## Antes de começar

Confirme com o usuário (pergunte só o que faltar):
1. **A ideia:** o que acontece, e o sentimento que ele quer passar.
2. **A ferramenta:** Sora, Veo, Runway, Kling, Suno, Udio, Midjourney ou outra.
3. **Duração e formato:** tempo total, vertical ou horizontal, com ou sem falas, com ou sem música.
   **Padrão do usuário: prompt completo = cena de 30 segundos** (cerca de 6 planos, em 3 atos). Só faça
   menos se ele pedir. Entregue também como dividir em tomadas de 5s ou 10s.

## Rodada 1: propostas (em paralelo)

1. Chame o `roteirista-ideia` primeiro e espere o resultado: a história dele vira a base de todos.
2. Depois chame, **todos na mesma mensagem, em paralelo**, os especialistas que fazem sentido para o
   projeto: `pesquisador-humanidade`, `diretor-fotografia`, `camera-lentes`, `angulos-enquadramento`,
   `movimento-camera`, `cores`, `direcao-arte`, `animacao`, `musica`, `som`, `montagem-ritmo`.
   - Para um prompt só de música, chame apenas `pesquisador-humanidade` e `musica` (e `som` se ajudar).
   - Para live-action sem personagens animados, `animacao` cuida só de física e movimento.
3. Envie para cada um: a ideia original do usuário, a história do roteirista, a ferramenta, a duração e
   o formato. Cada agente começa sem contexto, então a mensagem precisa ser completa.

## Rodada 2: revisão cruzada

1. Junte todas as propostas num documento só.
2. Continue a conversa com cada especialista (use SendMessage com o ID dele, para ele manter o contexto)
   enviando as propostas dos outros. Peça para ele ajustar a própria parte e apontar conflitos.
3. Envie o documento completo para o `cacador-de-cliches` e para o `pesquisador-humanidade` fazerem uma
   revisão geral contra o genérico de IA.

## Rodada 3: fechamento

1. Resolva os conflitos que sobrarem. Quando precisar escolher, escolha o que serve melhor à emoção da
   história e explique a decisão em uma linha.
2. Monte o resultado final e mande uma última vez para o `cacador-de-cliches`. Corrija o que ele apontar.

## Entrega para o usuário

Em português, curto e direto:
1. **A ideia em uma frase** (como ela ficou depois da equipe).
2. **Prompt final em inglês**, pronto para colar, no formato da ferramenta escolhida. Se a ferramenta
   gera poucos segundos por vez, entregue **um prompt por tomada**, repetindo os detalhes de continuidade
   (personagem, roupa, luz, cor) em cada um.
3. **Prompt de música** separado, se houver (estilo e letra no formato do Suno ou Udio).
4. **Falas**, se houver, na versão humanizada.
5. **Decisões principais**: 3 a 5 linhas dizendo o que a equipe mudou em relação à ideia original e por quê.

Não despeje as propostas inteiras dos 13 agentes na resposta. O usuário quer o resultado, não a reunião.

## Entrega na conversa (padrão do usuário)

Sempre que criar ou atualizar um prompt, cole o prompt final INTEIRO na resposta, sozinho, dentro de um único
bloco de código, para o usuário copiar. Nada de texto dentro do bloco além do próprio prompt. Comentários, se
houver, vêm depois do bloco e bem curtos.

## Formato obrigatório dos prompts da Cissia (versão que PASSA no gerador)

Modelo de referência: `prompts/cissia-entrega-30s-v2.md`. O formato antigo (seções 一 a 十) foi bloqueado por
direitos autorais. Siga exatamente o formato dos prompts do usuário que passaram:

- Blocos, nesta ordem: 【語言鐵則】 → 【風格】 → 【一句話引擎】 → 【參考與功能】 → 【場景・光】 → 【道具帳本】 →
  【表演核心】 → linha ───── → CUTs `【início–fim s｜CUT n・título】` → linha ───── → 【約束】 → 【NEGATIVE】.
- 【語言鐵則】: falas só em inglês; legendas só em japonês, estilo UI de《絕區零》, cinza-claro, 50% de transparência,
  embaixo; nenhum caractere chinês, texto ou número na tela.
- 【風格】: descreva o estilo por conta própria («賽璐璐渲染的3D動畫短片，畫面乾淨明亮，動作自然、讀取清楚，像官方的動畫短片»).
  NUNCA mande copiar ou seguir a qualidade, o estilo, o movimento ou a física do vídeo de referência.
- 【參考與功能】: «<<<video_1>>>＝Cissia。臉、髮型、服裝、尾巴設計只來自 <<<video_1>>>，文字不重新描述她的外貌。
  不使用 <<<video_1>>> 的背景、場景與其他人物。全片只有一個Cissia。» NUNCA descreva a aparência dela: cor de olho,
  pupila, cabelo, dentes, cor da cauda, traje, N.E.P.S. ou nome do jogo. Personagens sem referência ganham 3 traços
  simples e «全片只有一個X».
- Proibido: mundo voxel ou de blocos (parece Minecraft), personagens ou mundos de jogos, texto ou números nos objetos
  (use desenhos e ícones), superlativos como 頂級/極致/院線級.
- Cada CUT: uma frase de câmera; ação com preparo, ação e volta; fala no formato
  `Language: English. She says, <estado da voz e ação que corta a fala>: {"..."}` + `日本語字幕【...】` +
  «說完嘴巴閉上…»; efeitos entre `< >`; música entre `( )`.
- Sempre: 雙馬尾2束加蛇尾1條恆為3件；尾巴有重量、不穿模；眼睛只有正常的反光點；口水、液體依重力落下；
  final com corte seco no mesmo quadro.
- 【NEGATIVE】: «no animal ears, no squirrel cheeks; no glowing eyes, no spirals or rings in eyes; no floating objects; no text or numbers on screen».
- Tamanho: por volta de 3.000 a 4.000 caracteres chineses. Prompt curto e concreto passa; prompt longo cheio de regras não.

## Estilo de movimento e expressão (sempre incluir, dentro de 【表演核心】)

Vem de `prompts/analise-video-referencia.md`: poses teatrais com balé e patinação, andar de ladra na ponta dos pés,
cauda em grandes arcos em S que chega meio tempo depois do corpo, sorriso de lado com uma presinha aparecendo,
susto com o cabelo eriçado, ponto de vista de dentro de um objeto e comida que brilha como tesouro.
