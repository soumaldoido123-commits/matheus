# Regras para desenhos SVG

Velocidade e qualidade vêm antes da quantidade de detalhes.

- Escreva o SVG à mão, direto em um arquivo, numa chamada só. Nunca use script (Python ou outro) para gerar o desenho.
- Nunca use aleatório (`random`). Todas as posições são fixas e escolhidas de propósito.
- No máximo cerca de 30 formas. Se pedirem mais detalhe, melhore as formas que já existem; não empilhe centenas de formas novas.
- Espelhe as partes simétricas com `<use>` e `transform="matrix(-1 0 0 1 LARGURA 0)"`.
- Nada de loops, texturas de pelo ou partículas espalhadas: são elas que cobrem partes do desenho e criam erros.
- Uma rodada só: criar o arquivo, commit e push no mesmo comando Bash (heredoc).
- Resposta curta: só o arquivo e, no máximo, uma frase.
