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
