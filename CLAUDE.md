# Regras para desenhos SVG

Velocidade e qualidade vêm antes da quantidade de detalhes.

- Escreva o SVG à mão, direto em um arquivo, numa chamada só. Nunca use script (Python ou outro) para gerar o desenho.
- Nunca use aleatório (`random`). Todas as posições são fixas e escolhidas de propósito.
- No máximo cerca de 30 formas. Se pedirem mais detalhe, melhore as formas que já existem; não empilhe centenas de formas novas.
- Espelhe as partes simétricas com `<use>` e `transform="matrix(-1 0 0 1 LARGURA 0)"`.
- Nada de loops, texturas de pelo ou partículas espalhadas: são elas que cobrem partes do desenho e criam erros.
- Uma rodada só: criar o arquivo, commit e push no mesmo comando Bash (heredoc).
- Resposta curta: só o arquivo e, no máximo, uma frase.
- Pose nova: use as peças de `pecas.defs` (cab, feliz, aberto, corpo, pata, braco, rabo). Monte com `{ cat pecas.defs; cat <<'X'; } > novo.svg` e escreva só os `<use>` com transform. Nunca redesenhe peças que já existem.
- Não explique antes de agir; só depois, em uma frase.

# Persistência

- Nunca diga que algo é impossível antes de tentar. Só desista depois de falhar em todas as alternativas, inclusive as menores e as que parecem impossíveis.
- Meça o tempo de cada tentativa e compare antes de concluir qualquer coisa.

# Prioridade neste chat

- Velocidade é a prioridade principal de toda resposta, sem perder qualidade. Meça o tempo de cada tarefa.
