# Prompt-base definitivo para o Wan 3.0: cópia de animação desenhada à mão

**Resumo para ler primeiro:**

- **O cabeçalho W1 está inteiro.** Conferi com um script: as 149 palavras do W1 aparecem na mesma ordem no prompt-base e nas duas cenas. Tudo o que é novo foi só acrescentado.
- **O que está provado é que o modelo para porque resolve a cena.** Ele não para por falta de capacidade. As duas gerações boas chegaram a cerca de 17 desenhos/s sem nenhum trecho parado acima de 0,13 s. As ruins terminam num estado final (deitada, sentada, estátua ou fora do quadro) e ficam nele. O texto novo existe para nunca descrever um estado final.
- **O português é o padrão e o chinês é um braço de teste.** O motivo não é o tamanho, é que todos os prompts que funcionaram (W1 a W4) eram em português e o chinês nunca foi testado.
  - Em tokens do umT5, o codificador do Wan 2.x, as duas línguas empatam (cena 1: 397 em português e 389 em chinês).
  - Em caracteres, o chinês é cerca de 3,5 vezes menor (1.503 contra 421).
  - Não sei qual codificador o Wan 3.0 usa.
- **No Wan 3.0, o corte em 512 tokens provavelmente não existe.** A documentação pública do Wan 3.0 (vista só pelo resultado de busca) dá um limite de 20.000 caracteres para o prompt. O corte em 512 tokens é do Wan 2.x de código aberto. O teto de cerca de 285 palavras continua, mas agora pelo motivo certo: prompts longos falharam com você, e o W1, com 149 palavras, foi o melhor.
- **O travar.py original fabrica a parada.** Nas duas gerações boas, o trecho parado mais longo subiu de 0,10–0,13 s para 0,23 s.
- **A pós de grade também cria parada quando a geração já tem holds.** Medi:
  - o fps=12 aplicado a uma geração boa criou holds de 5 quadros;
  - o fps=15 criou holds de 4.

  Por isso a pós de cadência agora só entra quando a geração está mais lisa que a referência. O `aceite.py --ref` diz se é o caso.
- **O aceite é necessário, mas não basta.** Ele aprovou a fa5, que termina com o quadro vazio, e a 0ca, que termina em esteira. Agora há uma checagem visual obrigatória, e o script ganhou ajustes para referências com holds longos (a Aqua e a sala de aula reprovavam no padrão).

---

## 1. Por que o modelo para

| Medida (tela inteira, 160x90 em cinza) | 8 referências | Gerações boas (fa5, 0ca) | Gerações ruins (33f, 81d, a2c, 48e) |
|---|---|---|---|
| Maior trecho com a tela idêntica | Até 0,13 s. Exceções: o lilás segura 0,2–0,24 s nas pontas do loop; a Aqua tem uma pausa única de 1 s | 0,13 s e 0,10 s | No vídeo inteiro: 0,9 s, 1,03 s, 1,3 s e 1,8 s. Quase todos ficam no rabo morto. No trecho vivo, só a 33f (a estátua, 1,03 s); a 48e chega a 0,17 s |
| Desenhos por segundo, no trecho vivo (pelo `wan_tools/aceite.py`) | 6,3 (Aqua) a 17,8 (perseguição). A Miku dá 20,3 porque o fundo muda em todo quadro | 16,8 e 17,2 | 10,3 a 17,6. A a2c tem mais desenhos/s que a fa5. **Sozinha, esta medida não separa boa de ruim.** Na parte gerada inteira, com o rabo morto incluído, o metric.py dá de 6,6 a 13,5 |
| Piso de energia por meio segundo, em fração do pico | 0,42 a 0,73. Exceções: sala de aula 0,09 (o close parado do início) e Aqua 0,27 fora da pausa | 0,29 e 0,19 | No trecho vivo: 33f 0,04 e 48e 0,12. A a2c (0,30) e a 81d (0,20) só passam porque o aceite corta o rabo em 5,5 s e 5,0 s |
| Último segundo | A ação ainda está no meio | Ainda vivo, mas a fa5 termina com o quadro vazio e a 0ca em corrida de esteira | Sobram de 3% a 4% da energia (a2c, 81d, 33f); a 48e fica entre 0,10 e 0,14 |

**O que esses números dizem:**

1. **Animação limitada não quer dizer segurar muito tempo.** Quer dizer poucos desenhos por segundo com a tela nunca congelada: cada pose dura um instante e o desenho seguinte já é outro. A trava de 6 quadros do travar.py e o pedido "congela como estátua" partiam do entendimento contrário.
2. **O Wan consegue o ritmo certo.** A fa5 e a 0ca chegaram a cerca de 17 desenhos/s sem trecho parado acima de 0,13 s. Isso indica que a parada é principalmente semântica: **o modelo resolve a cena num estado final e fica nele.** São só duas gerações boas, então isso é forte indício, não prova.
   - 4 das 6 gerações terminam deitadas, sentadas ou encolhidas.
   - Nas 6, o menino sai de cena entre 0,3 e 0,9 s depois do corte.
   - "Congela como estátua" virou 31 quadros idênticos. Depois disso ela desaba, e vêm mais 54 quadros idênticos até o fim.
3. **"Segure as poses como o vídeo segura" não diz quanto tempo.** Sem medida, o modelo usa o hold padrão dele, de cerca de 1 s. A referência segura de 0,08 a 0,13 s.
4. **O movimento secundário sem verbo assenta.** O modelo só anima o substantivo que tem verbo. Sem verbo, ele aplica o amortecimento de vídeo real, e o cabelo para 0,3 a 0,5 s depois do corpo. É exatamente a sua observação: na referência o negócio fica balançando, na geração ele para.
5. **A pós-produção também fabricava parada.**
   - travar.py original: o trecho parado mais longo foi de 0,10–0,13 s para 0,23 s.
   - fps=12,fps=30 na 0ca: criou holds de 5 quadros, e a perseguição (a referência dela) nunca passa de 2.
   - fps=15,fps=30: criou holds de 4 quadros.

   Decimar um vídeo que já tem holds próprios faz quadros repetidos se somarem.
6. **O fim de prompts longos é ignorado, mas no Wan 3.0 a causa provável não é corte.**
   - No Wan 2.1/2.2 de código aberto, o texto é cortado em 512 tokens do umT5.
   - Para o Wan 3.0, o limite publicado é de 20.000 caracteres.
   - Hipóteses mais prováveis:
     - diluição: as últimas frases pesam menos;
     - reescrita automática do prompt por um LLM, se a sua plataforma tiver isso ligado. A API do Wan 2.7 tem o parâmetro `prompt_extend`; não confirmei se o 3.0 tem.
   - Os nomes dos seus arquivos gerados começam com `hf_`, o que sugere que você gera por uma plataforma intermediária. Veja se ela tem "melhorar prompt", "enhance" ou "智能改写", e desligue (teste T0).

**A conclusão:** o texto não pode ter nenhum estado final. Ele precisa:

- dar medida ao "segure";
- dar um verbo de ida e volta a cada elemento secundário;
- manter o elenco preso no quadro;
- terminar no meio de uma ação.

---

## 2. Prompt-base definitivo

**Teto prático:** cerca de 285 palavras em português (cerca de 400 tokens umT5) ou cerca de 430 caracteres em chinês.

- O teto vem da sua experiência (prompts longos param de copiar o vídeo) e do W1 (149 palavras, o melhor). Ele não vem de um corte técnico confirmado no Wan 3.0.
- O prompt-base com os slots vazios tem 232 palavras (362 tokens).
- As cenas prontas têm 278 e 285 palavras (397 e 399 tokens).

### Português (versão padrão, para gerar)

```
OBEDEÇA O VÍDEO. Ele é a lei. Mesmo traço, mesma cor, mesma câmera, mesmo cenário, mesma personagem, mesmo timing, mesma sujeira no desenho. Proibido suavizar. Proibido limpar. Proibido animar em 60 quadros. Proibido movimento linear. Proibido acalmar. Segure as poses como o vídeo segura. Quebre as poses como o vídeo quebra. Cada pose dura só um instante; o desenho seguinte já é outra pose. Enquanto o corpo segura, [SEC1], [SEC2] e [SEC3] vão e voltam um passo atrás do corpo, passam do ponto e já vão de novo[, e [PARTÍCULA] [VERBO] o tempo todo]. [ELENCO] Agora [MOTOR], ela fica cada vez mais [EMOÇÃO] e faz uma corrente de gestos novos com as mãos[, OBJETO] e o rosto, no mesmo jeito do vídeo, e cada gesto nasce de dentro do anterior: a mão que termina um gesto é a que começa o próximo, uma mão sempre chega antes da outra, as mãos nunca param entre uma pose e outra, e o rosto muda de expressão no exato momento em que a mão chega. [ÂNCORA 1]. [ÂNCORA 2]. Cada vez mais louco, e o último segundo, o mais louco de todos: no último quadro [QUEM] ainda está no meio de [AÇÃO RÁPIDA], com [SEC1] [VERBO NO GERÚNDIO]. Tudo copiado do jeito de desenhar do vídeo, com a mesma intensidade do vídeo, tudo mais forte, mais rápido e mais louco. Continue até o último quadro sem parar.
```

### Chinês tradicional (braço de teste, não testado)

```
服從影片。影片就是法律。同一線條、同一顏色、同一鏡頭、同一場景、同一角色、同一動作節奏、同一作畫髒感。禁止平滑。禁止修乾淨。禁止做成每秒60格。禁止線性等速運動。禁止平靜下來。像影片那樣保持姿勢。像影片那樣打破姿勢。每個姿勢只保持一瞬間，下一張已是新姿勢。身體保持姿勢時，[SEC1]、[SEC2]和[SEC3]照樣來回，總比身體晚一步，衝過頭、彈回來，馬上又甩出去[，[PARTÍCULA]一直[VERBO]]。[ELENCO]現在[MOTOR]，她越來越[EMOÇÃO]，用手[、OBJETO]和臉做出一連串新手勢，照影片的方式，每個手勢都從上一個裡長出來：結束上一個手勢的手就是開始下一個的手，一隻手總比另一隻先到，雙手在姿勢之間從不停下，手到的那一瞬間表情就變。[ÂNCORA 1]。[ÂNCORA 2]。一輪比一輪瘋，最後一秒最瘋：最後一格[QUEM]正[AÇÃO RÁPIDA]到一半，[SEC1]還在甩。全部照影片的畫法，和影片一樣強烈，全部更強、更快、更瘋。一直持續到最後一格，不要停。
```

**Escolhas de tradução já resolvidas no chinês:**

- **保持** em vez de 定住/定格, porque 定住 quer dizer imobilizar e traz a estátua de volta.
- **禁止平滑** em vez de 柔化, porque 柔化 quer dizer desfocar.
- **作畫髒感** em vez de 髒污, que pode virar mancha literal. **修乾淨** é mais claro que 清理.
- **張** conta desenhos e **格** conta quadros.
- **到一半** em vez de 途中 para ações que não são um trajeto.
- **同一角色** não tem número gramatical. Mesmo assim, quem segura os dois personagens em cena é o [ELENCO].
- **線性等速** é o "movimento linear" no sentido de animação (velocidade constante).
- **Respingos são 水花 (濺開)**, nunca 雨點炸開: 炸開 pode virar explosão.
- **Protagonista masculino:** troque 她 por 他 (em português, "ela" por "ele"; ver a seção 3).
- **Diferenças intencionais em relação ao português:**
  - no B6 o verbo do SEC1 é fixo (甩, chicotear), enquanto em português ele é um slot;
  - 一輪比一輪瘋 ("rodada a rodada mais louco") não tem o duplo sentido de "volta" (giro) que levou à troca do português para "Cada vez mais louco".

### Mapa dos blocos

| Bloco | Texto | Origem |
|---|---|---|
| B1 | "OBEDEÇA O VÍDEO … Quebre as poses como o vídeo quebra." | W1, literal |
| B2 | "Cada pose dura só um instante…" + [SEC] "vão e voltam um passo atrás do corpo, passam do ponto e já vão de novo" + [PARTÍCULA] | Novo: medida do "segure" (P2), hold em camadas (P3) e atraso (P5). Só forma positiva |
| B3 | [ELENCO] | Prende todo o elenco no quadro (P6) |
| B4 | "Agora [MOTOR], ela fica cada vez mais [EMOÇÃO] e faz uma corrente … no exato momento em que a mão chega." | **Corrente do W1 inteira.** Os acréscimos são o motor, a emoção e o objeto |
| B5 | [ÂNCORA 1]. [ÂNCORA 2]. | W3 (mapeamento) e W6 (ciclo com quebra) |
| B6 | "Cada vez mais louco, e o último segundo, o mais louco de todos: no último quadro … no meio de …" | Crescendo e sentinela de leitura do fim (P7). Se o último quadro bater com o B6, o texto foi lido até ali |
| B7 | "Tudo copiado … Continue até o último quadro sem parar." | W1, literal e por último |

### Como "segure" e "nunca para" convivem

O prompt pede as duas coisas, e elas não se contradizem porque falam de camadas e tempos diferentes. É o que todas as referências fazem:

1. **Duração.** O corpo segura, mas só por um instante: de 0,08 a 0,13 s, ou até 0,27 s na Aqua. É a primeira frase do B2, colada no "Segure" do W1, que funciona como a medida dele.
2. **Camadas.** Enquanto o corpo segura, os secundários (SEC) e as partículas continuam: vão, chegam atrasados, passam do ponto e voltam. É o resto do B2. Na sala de aula, o rosto varia de 0,0 a 0,2 enquanto as mechas variam de 2 a 4,8. Na Miku, o fundo muda em 71 de 71 holds.
3. **Redesenho.** Quando o que se segura é uma expressão longa (o espanto e o riso do guarda-chuva, de 16 a 18 desenhos), segura-se a expressão e nunca o desenho. Isso é o módulo "Redesenho do hold" (seção 5), que só entra se o aceite acusar um hold longo.

Nunca se pede "parar" para obter um hold. O hold vem do próprio vídeo, pelo "Segure como o vídeo segura", e da pós de cadência quando ela é necessária.

---

## 3. Como preencher

| Slot | O que pôr | Forma em PT | Forma em ZH | Nunca pôr |
|---|---|---|---|---|
| **[SEC1–3]** | 2 ou 3 **substantivos que existem e se mexem bastante no vídeo**: cabelo, roupa solta, acessório pendurado, língua ou orelhas de um animal, o objeto na mão. O SEC1 é o que mais se mexe e volta no B6. Se houver um só SEC, conjugue no singular ("vai e volta"). | Só o substantivo: "as marias-chiquinhas", "o cabelo dela" (o verbo já está no bloco fixo). Se sobrar orçamento, dê ao SEC1 o verbo que ele faz no vídeo, como no W4: "a franja atravessa os olhos e volta" | 雙馬尾、呆毛、她的頭髮 | Adjetivo de forma ("cabelo em pé", "esticado"); algo que o vídeo não tem; peça pequena e presa (gravatinha) |
| **[PARTÍCULA] [VERBO]** | Elemento que se move sozinho e existe no vídeo: chuva, respingos, poeira, pétalas, letras do balão, bolhinhas, discos do fundo | "e os respingos estouram o tempo todo" | 水花一直濺開 | "sem parar" (é uma negação); 炸開 |
| **[ELENCO]** | Obrigatório quando o vídeo tem 2 ou mais personagens, ou um objeto que gera movimento (rede, guarda-chuva) | "[A] e [B] ficam colados [onde], dentro do quadro, o vídeo inteiro." Se o objeto não estiver no motor, acrescente ", ela sempre com [a rede] [estalando] na mão" | [她和小狗]全程貼在[傘下]、留在畫面裡 | Escrever só "ela" quando há dois personagens; 她 para um animal (use 小狗/牠); 緊握 ("agarra firme", que fixa a mão) |
| **"ela" do B4** | O pronome da protagonista | "ela"; com protagonista masculino (socos), "ele". Trocar o pronome é adaptação, não remoção, mas avise o usuário | 她 / 他 | Nunca deixar "ela" para um menino |
| **[MOTOR]** | A sua ideia como algo que **nunca se resolve**, em uma de três formas:<br>**A.** objetivo que nunca se cumpre ("tenta pegar, e ele escapa de novo");<br>**B.** gatilho que se repete ("uma barata passa de novo e de novo");<br>**C.** troca entre dois ("joga água nele, ele devolve") | Uma frase, com "sempre erra", "de novo e de novo" ou "escapa de novo" | 每次都咬空、一次又一次、你來我往 | Evento com resultado ("foge", "vence", "se acalma") |
| **[EMOÇÃO]** | Um estado que só sobe | "fica cada vez mais [eufórica / em pânico]" | 越來越[慌]、越玩越瘋 | Arco de história (birra que murcha) |
| **[OBJETO]** na corrente | O objeto que a mão segura no vídeo | "com as mãos, o guarda-chuva e o rosto" | 用手、傘和臉 | Nunca tirar "mãos" nem "rosto" |
| **[ÂNCORA 1–2]** | De 0 a 2 âncoras; **com [ELENCO], no máximo 1**. Cada uma com cerca de 15 palavras. Dois formatos:<br>**mapeamento W3:** "[peça do vídeo pela pose visível], do vídeo, vira [peça nova]", podendo fechar com "[verbo], recua e [verbo] mais longe";<br>**ciclo W6:** "No terceiro [FASE], [quebra que já continua]".<br>Queda ou susto só como ÂNCORA 1: sem palavras de tempo, a ordem no texto é a única forma de pôr algo cedo, e o modelo consome as âncoras cedo | "Os braços esticados, do vídeo, viram ela empurrando o ar: empurra, recua e empurra mais longe." | 影片裡雙臂伸直，變成她往前推空氣 | "depois / então / por fim"; números de quadros; queda como ÂNCORA 2; efeito que o vídeo não tem; objeto novo dentro do quadro |
| **[QUEM] [AÇÃO RÁPIDA]** (B6) | O último quadro no meio de um verbo **rápido do corpo**: giro, empurrão, passada, soco, sacudida | "ainda está no meio de um empurrão" | 正推到一半、正轉到一半 | "grito" (vira boca aberta parada); "no ar", "flutuando", "pose final", "parado", "caído" |
| **[SEC1] [VERBO NO GERÚNDIO]** (B6) | O SEC1 ainda em movimento | "com as marias-chiquinhas chicoteando" | 雙馬尾還在甩 | Pode sair se o B6 já tiver dois sujeitos em movimento |

### Filtro de vocabulário

Regra do assistente, nunca escrita no prompt. **Vale para slots e módulos.** O W1 e os blocos fixos ficam como estão, mesmo tendo "segura", "nunca param" e "sem parar".

| Ideia sua | Português | Chinês |
|---|---|---|
| congelar / estátua / travar | "o corpo encolhe num susto por um instante enquanto o cabelo voa, e já dispara". No máximo 1 vez, só como ÂNCORA 1 | 嚇得全身一縮，頭髮照樣飛，馬上又衝出去 |
| cair | "bate no chão e no mesmo instante já quica girando". Só como ÂNCORA 1 | 撞上地面，同一瞬間就彈起來打轉 |
| sentar / deitar | "agacha como uma mola e já dispara" | 像彈簧一樣蹲下，立刻彈出去 |
| murchar / cansar / acalmar | "recua encolhida e volta mais forte" / "chora cada vez mais alto" | 縮回去，再更猛地衝回來／哭得一次比一次大聲 |
| sair correndo | "corre colada nele, avançando e recuando dentro do quadro" | 黏著他跑，在畫面裡忽前忽後 |
| pose final | "no último quadro ainda está no meio de um giro" | 最後一格正轉到一半 |
| esticada / cabelo em pé | "estica por um instante e volta" / "o cabelo arrepia e cai no mesmo instante" | 拉長一瞬間又彈回／頭髮炸開，同一瞬間又落下 |
| objeto que a referência não tem | **Fora do quadro por padrão, sem citar parte do corpo que o enquadramento não mostra:** "uma barata passa lá embaixo, fora do quadro" | 畫面外的下方有蟑螂爬過 |

**Palavras proibidas em português:**

- **Parada:** parar, estátua, congela, trava, assenta, pousa, acalma, amortece, desacelera, cansa.
- **Suavidade:** suave, fluido e fluidez (puxam para a interpolação de 60 fps), câmera lenta, flutua, "no ar" ligado ao corpo, "aos pouquinhos" (vira rastejar contínuo).
- **Leitura literal:** piscar (vira piscar de olhos), treme, tremor, ferve. A única exceção é "as pontas vibram", que vem do W4 e funcionou.
- **Sequência:** depois, então, por fim.
- **Números:** contagem de quadros. Segundos também ficam fora, salvo no teste T8.
- **Estilo:** serrilhado, sombra, realista, esboço. Física, peso e gravidade também ficam de fora; é hipótese, mas "realista" já injetou o conceito antes.
- **Texto:** "sem legenda".
- **Efeitos:** smear e linhas de velocidade quando a referência não os tem.
- **"Volta"** no sentido de rodada, porque pode virar giro: use "cada vez", "cada tentativa" ou "cada troca".
- **"Mola" e "onda":** só como comparação ("como uma mola"), e "onda" nunca numa cena com água.

**Palavras proibidas em chinês:**

- **Parada e estado congelado:** 定住, 定格, 靜止, 僵住, 凝固, 停住, 不動, 坐下, 躺下, 倒下, 冷靜, 愣住, 目瞪口呆, 呆若木雞, 一動不動, 面無表情, 精疲力盡.
- **Suavidade:** 流暢, 順滑, 絲滑, 柔和, 柔化, 細膩, 行雲流水, 栩栩如生, 一點一點.
- **Tremor e piscar:** 發抖, 顫抖, 抖動, 一抖, 眨眼.
- **Flutuar e lento:** 飄, 浮, 懸空, 慢動作, 緩緩, 慢慢, 慢一拍.
- **Sequência:** 然後, 接著, 終於, 之後.
- **Números e técnica:** 第N格, N幀, 一拍二.
- **Estilo e texto:** 鋸齒, 陰影, 寫實, 手繪感, 草圖感, 字幕, 髒污.
- **Saída de quadro e explosão:** 跑出畫面, 離開, 消失, 炸開 (para água).
- **途中:** só com trajeto (旋轉途中). No resto, use 到一半.

**Ordem de corte se passar do teto:**

1. ÂNCORA 2;
2. SEC3;
3. "com [SEC1] [verbo]" no B6;
4. PARTÍCULA (só se a cena não for de água).

**Nunca cortar:** B1, a primeira frase do B2, a corrente do W1, o B6 com "no meio de" e o B7.

---

## 4. Receita: da sua ideia à cena

Os comandos abaixo rodam a partir da pasta do projeto (`/home/user/matheus`).

0. **Conferir a interface uma vez.**
   - Se ela tiver reescrita ou melhoria automática do prompt ("enhance", `prompt_extend`, 智能改写), desligue.
   - Anote se existe campo negativo e se a semente pode ser fixada.
   - Anote se a referência entra como continuação do vídeo ou como referência com etiqueta ("vídeo 1"). Se a interface exigir etiqueta, acrescentar "1" a "OBEDEÇA O VÍDEO" é adaptação, não remoção; confirme com o usuário.
1. **Identificar a referência e o tipo** na tabela da seção 6. Se for nova, rodar `python3 wan_tools/metric.py ref.mp4` e `python3 wan_tools/aceite.py ref.mp4`. Anotar desenhos/s, distribuição dos holds, maior trecho idêntico e piso, e classificar como A, B, C ou D.
   - Se a própria referência reprovar no aceite, como a Aqua (pausa) e a sala de aula (close parado), anote os valores de `--hold-max` e `--piso-min` que ela exige (seção 6).
2. **Limpar a referência.** Se houver legenda ou texto fixo, cobrir no arquivo, nunca escrever "sem legenda":
   `ffmpeg -i ref.mp4 -vf "drawbox=x=0:y=0:w=iw:h=ih*0.12:color=white:t=fill" ref_limpa.mp4`
   Ajuste a faixa ao lugar do texto.
3. **Fazer o inventário da referência:**
   - (a) personagens e objetos que precisam ficar em cena, e o sexo da protagonista (para o pronome);
   - (b) as 2 ou 3 partes que mais balançam (SEC) e as partículas;
   - (c) as peças mapeáveis, descritas pela pose visível;
   - (d) os efeitos que ela tem;
   - (e) a parte plantada, se houver (pés da Aqua, braços cruzados da Miku);
   - (f) o enquadramento (corpo inteiro ou cintura para cima), para não citar parte do corpo fora do quadro.
4. **Traduzir a ideia em MOTOR** (forma A, B ou C) **e EMOÇÃO que sobe.**
   - **Teste do penúltimo segundo:** "o que está acontecendo no segundo 14?" (ou no 29, para 30 s). Se a resposta for um estado ("está sentada", "foi embora", "se acalmou", "a barata morreu"), refazer o motor.
   - Se a ideia traz algo que a referência não tem, deixar esse elemento fora do quadro e só no motor, nunca nas âncoras.
5. **Escolher as âncoras:** até 2 (só 1 se houver ELENCO), em mapeamento W3 ou ciclo W6, mais o B6.
   - Toda âncora termina num verbo em andamento.
   - Queda ou susto só como ÂNCORA 1.
6. **Passar o filtro de vocabulário** da seção 3, só nos slots.
7. **Montar** de B1 a B7, num bloco único, e **medir:** até cerca de 285 palavras em português.
   Acima disso, cortar na ordem da seção 3. Rodar também o conferidor do W1 (ver "Arquivos").
8. **Fazer o chinês, se você quiser,** escrevendo direto em chinês com as formas da tabela, sem traduzir palavra por palavra.
9. **Entregar** o bloco em português (e o chinês, se pedido), o comando de aceite e a regra de pós do tipo.
10. **Depois da geração:**
    - gerar com cerca de 2 s a mais, se a ferramenta deixar escolher a duração. Para 30 s, prefira duas gerações de cerca de 15 s, a segunda partindo de um quadro em pleno movimento da primeira (recomendação, não testada);
    - rodar no arquivo **bruto**: `python3 wan_tools/aceite.py gerado.mp4 --precisa 15 --ref ref_limpa.mp4` (mais `--desde S` se a geração começar pelo trecho da referência, e os ajustes do passo 1);
    - **olhar o vídeo** e reprovar se:
      - alguém do elenco sumiu;
      - o quadro termina vazio;
      - virou esteira (o mesmo ciclo de corrida no lugar);
      - ela largou o objeto;
      - a legenda foi copiada.

      O aceite não vê nada disso: ele aprovou a fa5 e a 0ca, que têm esses defeitos;
    - se aceito: cortar o fim no tempo que o script indicar e aplicar a pós **só se** a sugestão do `--ref` disser "mais lisa". Depois da pós, rodar o metric.py de novo. Se a pós criou um hold maior que o maior da referência mais 1 quadro, fique com o bruto cortado;
    - se reprovado: regerar com **uma** mudança da escada abaixo.
11. **Para estender** a cena, usar como condicionamento um quadro em pleno movimento, nunca o trecho assentado do fim.

### Escada de correção (uma mudança por vez)

| Sintoma | Mudança |
|---|---|
| Congelou no meio (hold acima do `--hold-max`, com o corpo numa pose) | Acrescentar o módulo "redesenho do hold" e tirar a ÂNCORA 2 para pagar as palavras |
| Secundário parou junto com o corpo | Trocar os SEC por partes que se mexem mais na referência, ou dar ao SEC1 o verbo próprio dele (W4). Se continuar, módulo "pontas" |
| Morreu no fim (o aceite manda cortar cedo) | B6 com um verbo mais rápido e uma âncora a menos |
| O último quadro não bate com o B6 (sentinela) | O fim do texto pesou pouco: confira a reescrita automática (passo 0) e corte na ordem da seção 3 |
| Alguém saiu de cena ou o quadro terminou vazio | Reforçar o motor com interação entre os corpos ("tenta pegar o menino") e garantir "dentro do quadro" no ELENCO |
| Os dois param juntos | Módulo "revezamento" |
| Copiou menos o vídeo | Tirar uma âncora (o W1 com mais liberdade copia melhor) |
| Objeto ou efeito novo saiu fora do estilo, ou a câmera mudou para mostrar algo | Tirar o elemento das âncoras, deixá-lo só no motor e fora do quadro, sem citar parte do corpo fora do enquadramento |
| Corrida em esteira ou ciclo mecânico | Módulo "tentativa encadeada" + interação |
| Copiou a legenda | Cobrir melhor a faixa no drawbox (nunca escrever "sem legenda") |
| Ondulação digital na imagem | Tirar o módulo "pontas" |
| Aparece uma mola ou uma onda desenhada | Trocar por "encolhe e dispara" |
| A pós deixou a imagem mais parada que o bruto | Ficar com o bruto cortado; ver a regra da seção 6 |
| Referência com parte fixa (braços cruzados da Miku) e as mãos se soltaram | Conflito conhecido com a corrente do W1 (ver as notas da revisão). Aceite o resultado ou peça autorização para testar uma variante |

---

## 5. Módulos opcionais

Cada módulo entra no lugar indicado, um de cada vez, e conta para o teto.

| Módulo | Português | Chinês | Quando usar | Risco |
|---|---|---|---|---|
| Redesenho do hold (P4) | "Quando ela segura uma expressão, cada desenho muda e o cabelo muda de forma a cada instante." | 保持表情時每張都在變，頭髮的形狀每一瞬間都在變。 | O aceite reprova por hold longo no meio, ou a referência sustenta expressões longas (guarda-chuva) | Cabelo deformando como morph. Nunca acrescentar "a boca abre e fecha" (vira boca genérica) |
| Pontas (W4) | ", e as pontas vibram depois de cada mudança de direção" (no fim do B2) | ，每次轉向之後末梢還會再甩幾下 | O secundário assenta no fim de cada movimento | Ondulação na imagem inteira. O português usa a palavra do W4 (testada); o chinês usa 甩 para fugir de 顫/抖 |
| Tentativa encadeada | "Cada [tentativa / troca / passagem] começa de onde a anterior terminou, cada uma num ritmo diferente." | 每一次都接著上一次的結尾開始，節奏次次不同。 | Motor cíclico (corrida, perseguição, troca) | Sozinho não basta contra a esteira; precisa de interação. Não use "volta" (pode virar giro) |
| Revezamento (P8) | "Ela e [X] se revezam: quando um chega, o outro ainda está indo." | 她和[X]此起彼落：一個到了，另一個還在動。 | Dois personagens param juntos | É o mais abstrato e o primeiro a cortar |
| Parte plantada (P3) | "Os pés ficam plantados e tudo acima da cintura muda o tempo todo." | 雙腳留在原地，腰部以上一直在變。 | A referência tem uma âncora fixa nas pernas (Aqua) | Corpo rígido se a referência não tiver isso. Braços fixos (Miku) conflitam com a corrente do W1 |
| Duas marchas (P23) | "A preparação é picada, em poucos desenhos; a explosão vem numa rajada e entra numa pose forte." | 預備時一頓一頓地往回收，爆發時一連串衝進強烈姿勢。 | Só referências A e D (perseguição, sala, Aqua, lilás) | A cadência exata vem da pós, não daqui |
| Susto (no lugar de congelar) | "o corpo encolhe num susto por um instante enquanto o cabelo e a roupa voam, e já dispara de novo" | 嚇得全身一縮，頭髮和衣服照樣飛，馬上又衝出去 | A ideia exige um susto | Verbo de parada: no máximo 1 vez, só como ÂNCORA 1, nunca como última ação |
| Queda | "bate no chão e no mesmo instante já quica girando" | 撞上地面，同一瞬間就彈起來打轉 | A ideia tem queda | Fora da ÂNCORA 1, ela fica deitada até o fim |
| Intensidade presa ao vídeo (W2) | "ri tão alto quanto ela chora no vídeo" | 笑得和影片裡她哭得一樣大聲 | Emoção oposta à da referência | Baixo |
| Verbos curtos (W2) | "Pule, gire, soque o ar, bata os pés." | 跳、轉、朝空中揮拳、跺腳。 | Sobra orçamento e o corpo inteiro aparece | Nunca com "depois/então". Plano de cintura para cima não tem pés |
| Ciclo nomeado (W6, como âncora) | "Ela corre em ciclo CONTACT, DOWN, PASSING, UP; no terceiro CONTACT o pé engancha e ela já quica para frente." | 她以CONTACT、DOWN、PASSING、UP循環奔跑；第三次CONTACT時腳一絆，同一瞬間就彈向前。 | Corrida ou caminhada | Só a proporção lento/rápido é obedecida, não a contagem |
| Efeito da referência (P13) | "o braço vira uma faixa reta da cor da manga atravessando a tela, como no vídeo" | 手臂變成一條和袖子同色的直帶，橫過畫面，和影片一樣 | Só se a referência tem o efeito: socos (faixa, silhueta chapada), sala (tira rasgada, fitas em Z), Aqua (braços em leque), perseguição (cabo de borracha) | Sem o efeito na referência, falhou 5 de 5 vezes |
| Campo negativo | 靜止不動的畫面，畫面定格，慢動作，飄浮，補幀般的平滑動作，乾淨的線條，字幕，角色走出畫面，倒著動 ("imagem parada, quadro congelado, câmera lenta, flutuação, movimento liso de interpolação, linhas limpas, legenda, personagem saindo do quadro, movimento para trás") | idem | Só se a sua interface do Wan 3.0 tiver esse campo (não confirmado) | Não testado. O negativo padrão do Wan 2.1 também tem 风格, 作品 e 画作, que puxam contra o visual desenhado; tire esses se aparecerem |

### O que comprovadamente não funciona por prompt

| Técnica | Por que falha | O que fazer |
|---|---|---|
| Contagem exata de quadros | Só a proporção é obedecida | Proporção no prompt, cadência na pós |
| Smear, mão em linhas ou borrão sem existir na referência | 5 fracassos seguidos; o "obedeça o vídeo" vence | Trocar para uma referência que tenha o efeito |
| Catálogo de técnicas (o prompt da Aqua) | Prompt longo, o fim é ignorado | No máximo 2 âncoras + B6 |
| Adjetivos de estilo, mesmo com "não" | Injetam o conceito | "mesmo X do vídeo" |
| "Sem legenda" | Injeta o conceito, e a fa5 e a 0ca copiaram a legenda | drawbox na referência |
| Tremor, linha fervendo, câmera tremendo | Viram tremor de frio ou ondulação digital; nas referências a câmera é travada | Descrever partes que mudam; "mesma câmera" |
| Estátua ou pausa dramática | O modelo nunca destrava | Fazer na edição (seção 6) |
| Holds em 2 e 3 | Não se controla por texto | Pós de grade ou travar.py, só se a geração vier lisa |
| Fim morto | O modelo morre de 1,5 a 2 s antes do fim | Gerar 2 s a mais e cortar com o aceite |
| Prompt longo como lista de eventos | O fim é ignorado na prática. No Wan 2.x há corte em 512 tokens; no Wan 3.0 o limite publicado é de 20.000 caracteres, então a causa provável é diluição ou reescrita | Teto de cerca de 285 palavras; desligar a reescrita automática |

---

## 6. Pós-produção

**Regras:**

- A pós só reamostra e remove quadros; ela não cria movimento. **Passe a geração no aceite primeiro, no arquivo bruto.**
- **Só aplique pós de cadência se a geração estiver mais lisa que a referência.** É a sugestão "mais lisa" do `aceite.py --ref`, que significa mais de 1,3 vezes os desenhos/s da referência. Se a cadência já for parecida, a grade e o travar só somam quadros repetidos aos holds que o vídeo já tem. Medido: fps=12 criou holds de 5 quadros, fps=15 de 4, e travar `--trava 3` de 4. Se a geração tiver bem menos desenhos que a referência, a pós não resolve: regere.
- Depois de qualquer pós, rode o metric.py de novo. Se o maior hold passou do maior hold da referência mais 1 quadro, fique com o bruto cortado.
- Nunca empilhe o travar com fps=N.
- Não use o `travar.py` original (trava fixa de 6 na linha 20) nos tipos A, B e C.
- O travar e a grade congelam a **tela inteira**. Referências que seguram em camadas (sala de aula, Miku) perdem o fundo e o cabelo em movimento: compare sempre com o bruto.

### Ferramentas

**`aceite.py`** (calibrado nas 6 gerações; agora com ajustes por referência):

`python3 wan_tools/aceite.py gerado.mp4 [--desde S] [--precisa S] [--hold-max S] [--piso-min X] [--ref ref.mp4]`

- `--desde` pula o trecho da referência quando a geração é uma extensão do vídeo.
- `--precisa` é a duração viva de que você precisa.
- `--hold-max` é o maior trecho idêntico aceito (padrão 0,2 s).
- `--piso-min` é o piso de energia exigido (padrão 0,15).
- `--ref`, só informativo, mede a referência e imprime:
  - os desenhos/s, o maior hold e o piso dela;
  - a razão de desenhos/s e de energia entre geração e referência;
  - a sugestão de pós: nenhuma, grade ou regerar.

O que ele faz:

1. corta o fim morto na primeira de duas janelas seguidas de 0,5 s abaixo de 0,10;
2. no que sobra, exige trecho idêntico ≤ `--hold-max`, piso (só janelas completas) ≥ `--piso-min` e duração viva ≥ `--precisa`;
3. mostra os desenhos/s só como informação.

**Resultado nas 6 gerações** (com `--desde 2.2`):

| Geração | Resultado |
|---|---|
| fa5 | Aceita, piso 0,29 |
| 0ca | Aceita, piso 0,19 |
| 33f | Reprovada: hold de 1,03 s e piso de 0,04 |
| 48e | Reprovada: piso de 0,12 |
| a2c | Corte em 5,5 s, sobram 3,3 s vivos. Reprovada com `--precisa 4.5` |
| 81d | Corte em 5,0 s, sobram 2,8 s vivos. Reprovada com `--precisa 4.5` |

**Limites do aceite:**

- Ele não vê quem saiu de cena, o quadro vazio, a esteira, o objeto largado nem a legenda copiada (a fa5 e a 0ca passaram com esses defeitos). Por isso existe a checagem visual do passo 10.
- A energia é relativa ao pico do próprio vídeo. Uma geração lenta do começo ao fim, sem o trecho da referência no início, pode passar. Olhe a razão de energia do `--ref`: nas boas foi 0,56 a 0,67, nas ruins 0,39 a 0,47. Isso é só um indício, porque a a2c deu 0,67.

**Calibração nas próprias referências:**

| Referência | Resultado com o padrão | O que usar |
|---|---|---|
| perseguição, lilás, Miku, corredor, socos, guarda-chuva | Passam no padrão | Padrão |
| sala de aula | Piso 0,09 no close parado | `--piso-min 0.08` |
| Aqua | Pausa de 1 s; piso 0,27 fora dela | `--hold-max 0.3 --piso-min 0.2`. A pausa entra só na edição |

**`travar.py`** (cópia do seu travar.py com parâmetros; sem eles, faz o mesmo que o original):

`python3 travar.py in.mp4 out.mp4 --trava N --lento N`

- `--trava` é a trava do fim de movimento, **em quadros do vídeo gerado**: maior hold da referência em segundos × fps da geração. As gerações medidas eram a 30 fps.
- `--lento` é quantos quadros dura cada desenho no movimento lento: 3 é o padrão; use 2 no tipo A.

### Tipo de cada referência

Medido com o metric.py e o aceite.py. A pós vale **só se a sugestão do `--ref` for "mais lisa"**.

| Referência | fps | Desenhos/s | Holds medidos | Tipo | Pós, se a geração vier lisa | Aceite |
|---|---|---|---|---|---|---|
| perseguição | 24 | 17,5 | 1 e 2 quadros (máx. 0,08 s), 45% em 1 | A | `travar.py --trava 3 --lento 2`. Nunca fps=12 | Padrão |
| corredor | 30 | 14,3 | Quase tudo em 2 | B | `fps=15,fps=30` | Padrão |
| socos | 30 | 12,3 | Em 2, com 4 nos impactos | B | `fps=15,fps=30` | Padrão |
| guarda-chuva | 30 | 12,5 | 2 e 3 | C | `fps=12.5,fps=30` | Padrão |
| Miku | 25 | 20,3 na tela, ~10,5 na personagem | Personagem em 2-3; o fundo anda durante os holds | C | De preferência nenhuma: `fps=10,fps=30` congela o fundo junto, e o fundo andando é a vida desta referência | Padrão |
| sala de aula | 30 | 13,8 | 1, 2, 3 e 4 | D | `travar.py --trava 4 --lento 3`. Compare com o bruto: a sala segura em camadas | `--piso-min 0.08` |
| rascunho lilás | 25 | 8,8 | Em 2-3 no meio do gesto (máx. 3 quadros a 25 fps = 0,12 s); 6 só nas pontas do loop | D | `travar.py --trava 4 --lento 3`. Não 6: a trava de 6 só existe nas pontas do loop, que numa corrente de 15 s não aparecem | Padrão |
| Aqua | 30 | 6,3 | 2 a 8, mais uma pausa de 30 | D | `travar.py --trava 8 --lento 3`, mais a pausa na edição | `--hold-max 0.3 --piso-min 0.2` |

### Comandos

- **Corte + grade (tipos B e C, só se a geração vier lisa):**
  `ffmpeg -i gerado.mp4 -t T -vf "fps=15,fps=30" -c:v libx264 -crf 16 -pix_fmt yuv420p final.mp4`
  - T é o corte que o `aceite.py` imprime; se ele não imprimir corte, tire o `-t T`.
  - Troque o 15 pelo N do tipo.
- **Só o corte (quando não há pós de cadência):**
  `ffmpeg -i gerado.mp4 -t T -c:v libx264 -crf 16 -pix_fmt yuv420p final.mp4`
- **Pausa dramática** (só no estilo da Aqua, uma vez, numa pose forte ou com o rosto escondido): repete o quadro F por 1 s e sai com corte seco.
  `ffmpeg -i in.mp4 -vf "loop=loop=29:size=1:start=F,setpts=N/FRAME_RATE/TB" -an -c:v libx264 -crf 16 -pix_fmt yuv420p out.mp4`
  O vídeo fica 1 s mais longo; se tiver áudio, refaça o áudio na edição. Faça a pausa depois do aceite, nunca antes.
- **Ferver a linha na pós** continua só como hipótese. Teste apenas depois de fixar todo o resto.

---

## 7. Cenas prontas

### Cena 1: "ela vê uma barata e entra em pânico" (referência: corredor com as mãos)

**Inventário da referência:**

- **Personagem:** marias-chiquinhas laranja com mechas verde-água, mecha antena (topete em laço) no alto da cabeça, laço rosa, mangas bufantes brancas e xuxinha rosa no pulso.
- **Enquadramento e cenário:** da cintura para cima, num corredor com portas de metal.
- **Partícula:** fileira de bolhinhas sobre a cabeça, que troca de lugar em todo desenho.
- **Peças do vídeo:**
  - os braços esticados para a câmera com os dedos abertos;
  - as mãos nas bochechas olhando para cima;
  - a mão no rosto de olhos fechados;
  - o antebraço sobre os olhos.
- **Escolhas:**
  - a barata fica fora do quadro, "lá embaixo", porque a referência não tem barata nem mostra os pés. Por isso a versão anterior ("passa pelo pé dela") foi trocada;
  - motor de forma B (a barata passa de novo e de novo);
  - as bolhinhas entram como partícula;
  - 2 âncoras de mapeamento;
  - o último quadro no meio de um empurrão.

**Tamanho:** 278 palavras, 397 tokens umT5.

**Português:**

```
OBEDEÇA O VÍDEO. Ele é a lei. Mesmo traço, mesma cor, mesma câmera, mesmo cenário, mesma personagem, mesmo timing, mesma sujeira no desenho. Proibido suavizar. Proibido limpar. Proibido animar em 60 quadros. Proibido movimento linear. Proibido acalmar. Segure as poses como o vídeo segura. Quebre as poses como o vídeo quebra. Cada pose dura só um instante; o desenho seguinte já é outra pose. Enquanto o corpo segura, as marias-chiquinhas e a mecha antena vão e voltam um passo atrás do corpo, passam do ponto e já vão de novo, e as bolhinhas sobre a cabeça trocam de lugar o tempo todo. Agora uma barata passa lá embaixo, fora do quadro, de novo e de novo, ela fica cada vez mais em pânico e faz uma corrente de gestos novos com as mãos e o rosto, no mesmo jeito do vídeo, e cada gesto nasce de dentro do anterior: a mão que termina um gesto é a que começa o próximo, uma mão sempre chega antes da outra, as mãos nunca param entre uma pose e outra, e o rosto muda de expressão no exato momento em que a mão chega. As mãos nas bochechas, do vídeo, viram o susto a cada passagem da barata. Os braços esticados, do vídeo, viram ela empurrando o ar: empurra, recua e empurra mais longe. Cada vez mais louco, e o último segundo, o mais louco de todos: no último quadro ela ainda está no meio de um empurrão, com as marias-chiquinhas chicoteando. Tudo copiado do jeito de desenhar do vídeo, com a mesma intensidade do vídeo, tudo mais forte, mais rápido e mais louco. Continue até o último quadro sem parar.
```

**Chinês** (389 tokens umT5, 421 caracteres):

```
服從影片。影片就是法律。同一線條、同一顏色、同一鏡頭、同一場景、同一角色、同一動作節奏、同一作畫髒感。禁止平滑。禁止修乾淨。禁止做成每秒60格。禁止線性等速運動。禁止平靜下來。像影片那樣保持姿勢。像影片那樣打破姿勢。每個姿勢只保持一瞬間，下一張已是新姿勢。身體保持姿勢時，雙馬尾和呆毛照樣來回，總比身體晚一步，衝過頭、彈回來，馬上又甩出去，頭上的小泡泡一直換位置。現在畫面外的下方一次又一次有蟑螂爬過，她越來越慌，用手和臉做出一連串新手勢，照影片的方式，每個手勢都從上一個裡長出來：結束上一個手勢的手就是開始下一個的手，一隻手總比另一隻先到，雙手在姿勢之間從不停下，手到的那一瞬間表情就變。影片裡雙手捧臉，變成每次蟑螂爬過時的驚嚇。影片裡雙臂伸直，變成她往前推空氣：推出去，收回來，再推得更遠。一輪比一輪瘋，最後一秒最瘋：最後一格她正推到一半，雙馬尾還在甩。全部照影片的畫法，和影片一樣強烈，全部更強、更快、更瘋。一直持續到最後一格，不要停。
```

**Se a barata aparecer desenhada ou a câmera descer:** troque "uma barata passa lá embaixo, fora do quadro" por "ela sente uma coisa passando lá embaixo" (em chinês: 她感覺下面有東西爬過).

**Depois de gerar:**

- Aceite: `python3 wan_tools/aceite.py gerado.mp4 --precisa 15 --ref ref_limpa.mp4`. Acrescente `--desde` se a geração começar pelo trecho da referência.
- Olhe se o quadro fica cheio e se nenhuma barata aparece desenhada.
- Pós, tipo B, só se a sugestão disser "mais lisa":
  `ffmpeg -i gerado.mp4 -t T -vf "fps=15,fps=30" -c:v libx264 -crf 16 -pix_fmt yuv420p barata_final.mp4`
  Senão, só o corte.
- Sem travar e sem pausa.

### Cena 2: "a menina e o cachorro brincando na chuva" (referência: guarda-chuva)

**Inventário da referência:**

- **Cena:** câmera de cima, através de um guarda-chuva transparente com varetas.
- **Personagens:** menina de cabelo longo verde-água, que é o maior movimento secundário, com cachecol rosa; cachorro claro com laço laranja e língua de fora.
- **Chuva:** respingos brancos chapados.
- **O que já acontece no vídeo:** o cachorro se sacode e o guarda-chuva gira.
- **Escolhas:**
  - ELENCO presente, então só 1 âncora: a sacudida do vídeo vira o cachorro molhando a cara dela;
  - motor de forma C (troca entre os dois) com emoção que sobe;
  - o guarda-chuva entra na corrente para ela não largá-lo;
  - o último quadro tem dois motores em andamento.

**Tamanho:** 285 palavras, 399 tokens umT5. Está no teto; o próximo corte seria "e o cachorro, no meio de uma sacudida".

**Português:**

```
OBEDEÇA O VÍDEO. Ele é a lei. Mesmo traço, mesma cor, mesma câmera, mesmo cenário, mesma personagem, mesmo timing, mesma sujeira no desenho. Proibido suavizar. Proibido limpar. Proibido animar em 60 quadros. Proibido movimento linear. Proibido acalmar. Segure as poses como o vídeo segura. Quebre as poses como o vídeo quebra. Cada pose dura só um instante; o desenho seguinte já é outra pose. Enquanto o corpo segura, o cabelo dela e a língua do cachorro vão e voltam um passo atrás do corpo, passam do ponto e já vão de novo, e os respingos estouram o tempo todo. Ela e o cachorro ficam colados debaixo do guarda-chuva, dentro do quadro, o vídeo inteiro. Agora ela gira o guarda-chuva jogando água no cachorro, que abocanha os respingos e sempre erra, ela fica cada vez mais eufórica e faz uma corrente de gestos novos com as mãos, o guarda-chuva e o rosto, no mesmo jeito do vídeo, e cada gesto nasce de dentro do anterior: a mão que termina um gesto é a que começa o próximo, uma mão sempre chega antes da outra, as mãos nunca param entre uma pose e outra, e o rosto muda de expressão no exato momento em que a mão chega. A sacudida do cachorro, do vídeo, vira ele molhando a cara dela, e ela gargalha mais alto. Cada vez mais louco, e o último segundo, o mais louco de todos: no último quadro o guarda-chuva ainda está no meio de um giro e o cachorro, no meio de uma sacudida. Tudo copiado do jeito de desenhar do vídeo, com a mesma intensidade do vídeo, tudo mais forte, mais rápido e mais louco. Continue até o último quadro sem parar.
```

**Chinês** (394 tokens umT5, 422 caracteres):

```
服從影片。影片就是法律。同一線條、同一顏色、同一鏡頭、同一場景、同一角色、同一動作節奏、同一作畫髒感。禁止平滑。禁止修乾淨。禁止做成每秒60格。禁止線性等速運動。禁止平靜下來。像影片那樣保持姿勢。像影片那樣打破姿勢。每個姿勢只保持一瞬間，下一張已是新姿勢。身體保持姿勢時，她的頭髮和小狗的舌頭照樣來回，總比身體晚一步，衝過頭、彈回來，馬上又甩出去，水花一直濺開。她和小狗全程貼在傘下、留在畫面裡。現在她轉傘把雨水甩向小狗，小狗張嘴咬水花，每次都咬空，她越玩越瘋，用手、傘和臉做出一連串新手勢，照影片的方式，每個手勢都從上一個裡長出來：結束上一個手勢的手就是開始下一個的手，一隻手總比另一隻先到，雙手在姿勢之間從不停下，手到的那一瞬間表情就變。影片裡小狗甩水，變成牠把水甩到她臉上，她笑得更大聲。一輪比一輪瘋，最後一秒最瘋：最後一格傘正轉到一半，小狗正甩到一半。全部照影片的畫法，和影片一樣強烈，全部更強、更快、更瘋。一直持續到最後一格，不要停。
```

**Depois de gerar:**

- Aceite: `python3 wan_tools/aceite.py gerado.mp4 --precisa 15 --ref ref_limpa.mp4`.
- Olhe se a menina e o cachorro ficam no quadro e se nunca param ao mesmo tempo. Se pararem juntos, acrescente o módulo "revezamento".
- Pós, tipo C, só se a sugestão disser "mais lisa":
  `ffmpeg -i gerado.mp4 -t T -vf "fps=12.5,fps=30" -c:v libx264 -crf 16 -pix_fmt yuv420p chuva_final.mp4`
  Senão, só o corte.
- Sem travar, porque a grade 2-3 já é o hold e empilhar daria até 9 quadros parados. Sem pausa.

---

## 8. Como testar

**Regras do A/B:**

- Mude **uma variável por vez**.
- Mantenha a mesma referência (já limpa), a mesma duração e as mesmas configurações.
- Se a sua interface deixar fixar a semente, fixe. Se não deixar, gere **2 vídeos por braço**, porque a variação entre gerações é grande (a fa5 e a 0ca vieram do mesmo prompt e terminaram de jeitos diferentes).
- Meça sempre o arquivo bruto.

**O que anotar em cada geração:**

| Braço | Geração | hold_identico_max_s | piso | segundos_vivos | energia das 2 últimas janelas | razão de desenhos/s com a ref | elenco inteiro até o fim? | quadro vazio, esteira ou legenda? | sentinela (o último quadro bate com o B6?) | cópia do vídeo (1–5) | fez o que eu pensei (1–5) |
|---|---|---|---|---|---|---|---|---|---|---|---|

- Os números saem do `aceite.py --ref`; as duas últimas janelas estão em `energia_por_meio_segundo`.
- As colunas de elenco, quadro vazio, esteira, legenda, sentinela e as notas são o seu olho.

**Ordem dos testes:**

0. **T0:** reescrita automática do prompt ligada contra desligada, se a interface tiver essa opção. Se ela existir e estiver ligada, todos os outros testes medem o texto reescrito, não o seu.
1. **T1, a hipótese central:** W1 puro contra W1 + B2 (só o bloco de vida). Mede se a medida do "segure" e o secundário com verbo seguram o movimento.
2. **T2:** base completa contra base sem o B6 (crescendo + último quadro). Mede o fim morto e a sentinela.
3. **T3:** a mesma cena em português e em chinês. Mede o idioma. Em tokens umT5 o tamanho é igual; em caracteres o chinês é 3,5 vezes menor.
4. **T4:** com e sem o módulo "pontas".
5. **T5** (só cenas com objeto): corrente com e sem o [OBJETO]. Mede se ela larga o objeto.
6. **T6, só se você autorizar,** porque mexe no W1:
   - "mesma personagem" contra "mesmos personagens", em referências com dois personagens;
   - "sem parar" mantido contra retirado.
7. **T7, pós:** bruto cortado contra a pós do tipo contra o travar.py original. Compare o `hold_hist` do metric.py de cada resultado com o da referência.
8. **T8, experimental:** as âncoras com faixas de tempo ("de 0 a 5 s …, de 5 a 10 s …") contra sem tempo. Guias de terceiros recomendam timestamps por plano no Wan 3.0, e o veto que temos é a contagem de quadros, não a de segundos. Só depois de T1 e T2.

**Como decidir:**

- Um braço que passa no aceite **e** na checagem visual ganha de um que não passa.
- Entre os que passam, ganha o de maior piso e maior energia nas duas últimas janelas.
- Se a sentinela falhar em mais da metade das gerações de um braço, ele está longo demais, ou a reescrita está ligada: corte na ordem da seção 3.
- Em caso de empate, decide o seu olho na cópia do vídeo.
- Só depois que o T1 e o T2 tiverem vencedor vale testar módulos.

---

**Arquivos** (no repositório, branch `claude/zen-mccarthy-3oo5ig`):

- `wan_tools/prompts/base_pt.txt`, `base_zh.txt`, `c1_pt.txt`, `c1_zh.txt`, `c2_pt.txt`, `c2_zh.txt`: os prompts deste documento, prontos para colar.
- `wan_tools/prompts/w1.txt`: o W1 literal, para conferir se um prompt montado contém todas as palavras dele na ordem.
- `wan_tools/aceite.py`: controle de aceite com `--desde`, `--precisa`, `--hold-max`, `--piso-min` e `--ref`.
- `wan_tools/metric.py`: medição de uma referência nova.
- `travar.py`: agora aceita `--trava N` e `--lento N`. Sem esses parâmetros, faz exatamente o mesmo que antes.

---

## Notas da revisão

**Afirmações corrigidas ou rebaixadas a hipótese**

1. **O corte em 512 tokens deixou de ser a explicação.** O documento tratava o corte em 512 tokens do umT5 como provável causa de o fim do texto ser ignorado. Pela busca, a documentação do Wan 3.0 dá um limite de prompt de 20.000 caracteres; não consegui abrir as páginas, porque o proxy bloqueia, e vi só o resumo da busca.
   - O corte de 512 tokens ficou como fato só do Wan 2.x.
   - O teto de tamanho ficou como regra empírica (cerca de 285 palavras), justificada pelo W1 e pelos seus fracassos com prompts longos.
   - Entraram como causas mais prováveis a diluição e a reescrita automática do prompt.
2. **"O chinês não é mais curto para o Wan" estava exagerado.** Isso só vale para o umT5. Em caracteres o chinês é cerca de 3,5 vezes menor. O português continua como padrão, agora pelo motivo certo: W1 a W4 eram em português e o chinês não foi testado.
3. **A linha de desenhos/s da tabela da seção 1 contradizia o diagnóstico.** O documento dizia 11 a 16 nas gerações ruins; o diagnóstico dava 6,6 a 13,5. Rodei o aceite nas 6 gerações: no trecho vivo dá 10,3 a 17,6, e pelo metric.py na parte gerada inteira dá 6,6 a 13,5. Agora a tabela diz qual método dá cada número. A conclusão "não separa" vale para o trecho vivo: a a2c tem 17,6, mais que a fa5.
4. **A linha dos holds escondia que eles ficam quase todos no rabo morto.** No trecho vivo, antes do corte, só a 33f (a estátua) tem hold longo. A linha agora diz isso, e o piso aparece como o critério que de fato separa.
5. **"A parada não é um limite técnico" virou "principalmente semântica".** São só duas gerações boas.
6. **Saíram as referências a "juízes" e a "propostas" internas** que você nunca viu.

**Prompts**

7. **B6: "Cada volta mais louca que a anterior" virou "Cada vez mais louco".** "Volta" pode ser lido como giro e empurrar todas as cenas para rodopios. "Repetição" foi descartada porque reforça o ciclo mecânico (esteira). O módulo "Volta encadeada" virou "Tentativa encadeada". O W1 continua 149/149 nas três versões (conferido com script).
8. **Cena 1: "uma barata passa pelo pé dela" virou "uma barata passa lá embaixo, fora do quadro".** A referência é da cintura para cima, e citar o pé convida a câmera a descer e a barata a ser desenhada; o próprio documento já listava isso como risco. Na mesma cena, as bolhinhas sobre a cabeça, que existem na referência e mudam em todo desenho, entraram como partícula. A cena foi de 376 para 397 tokens, dentro do teto.
9. **Pronome masculino.** O B4 fixa "ela" e 她. Com protagonista masculino (referência dos socos) isso está errado. Entrou como slot de adaptação, que precisa da confirmação do usuário porque toca o texto do W1.
10. **Slots mais precisos:**
    - [SEC] no singular pede "vai e volta";
    - o verbo do B6 vai no gerúndio;
    - verbo próprio opcional para o SEC1, como no W4.
11. **Queda e susto "só no primeiro terço" era impossível de escrever,** porque palavras de tempo são proibidas. Virou "só como ÂNCORA 1": a ordem no texto é a única alavanca, e o modelo consome as âncoras cedo.
12. **Módulo "Duas marchas":** "recolhe aos pouquinhos" e 一點一點 (descrevem o rastejar contínuo, o vício da IA) viraram "a preparação é picada, em poucos desenhos" e 一頓一頓.
13. **A lista de palavras proibidas agora vale só para slots e módulos.** O W1 e os blocos fixos contêm "segura", "nunca param" e "sem parar"; antes a lista parecia contradizê-los.
14. **Nova seção "Como 'segure' e 'nunca para' convivem":** duração, camadas e redesenho. Faltava explicar por que pedir pose segurada e movimento perpétuo não é contraditório.
15. **"Teste do segundo 14" virou "teste do penúltimo segundo",** que também serve para cenas de 30 s.

**Chinês**

16. Cena 2: 雨點一直炸開 virou 水花一直濺開, porque 炸開 pode virar explosão e 水花 é o mesmo termo usado depois no motor.
17. Documentadas como intencionais duas diferenças:
    - o verbo fixo 甩 no B6;
    - 甩幾下 no módulo "pontas", contra "vibram" em português (palavra do W4, que funcionou; em chinês, 顫/抖 estão na lista proibida).
18. 炸開 (para água) e 一點一點 entraram na lista proibida em chinês.

**Receita**

19. **Novo passo 0:** desligar a reescrita automática, ver se existem campo negativo e semente, e ver como a interface nomeia a referência. Os nomes `hf_…` dos arquivos sugerem uma plataforma intermediária.
20. **Passo 1:** rodar o aceite na própria referência para calibrar `--hold-max` e `--piso-min`.
21. **Passo 3:** o inventário ganhou o sexo da protagonista e o enquadramento.
22. **Passo 10:**
    - checagem visual obrigatória (elenco, quadro vazio, esteira, objeto largado, legenda), porque o aceite aprovou a fa5 (termina vazia) e a 0ca (termina em esteira);
    - decisão de pós pelo `--ref`;
    - nova medição depois da pós;
    - para 30 s, duas gerações encadeadas (recomendação não testada).
23. **Ferramentas movidas para o repositório** (`wan_tools/` e `travar.py`), com os comandos apontando para elas.
24. **Escada de correção:** novas linhas para quadro vazio, câmera mudando por objeto novo, legenda copiada, pós piorando e o conflito da Miku.

**Pós-produção**

25. **Pós de cadência condicionada à geração vir lisa.** Medido nos arquivos de teste:
    - fps=15 criou holds de 4 quadros;
    - fps=12 criou holds de 5;
    - travar `--trava 3 --lento 2` criou holds de 4 (0,13 s, contra 0,08 s na perseguição).

    A regra "nenhuma pós se já tem cerca de 16 desenhos/s", que só existia no tipo A, virou regra geral.
26. **Rascunho lilás: `--trava 6` virou `--trava 4`.** O documento contradizia o princípio de que o 6 só ocorre nas pontas do loop, e o 6 estava em quadros a 25 fps, não a 30. No meio do gesto, o hold máximo é de 3 quadros a 25 fps, ou seja, 0,12 s, cerca de 4 quadros a 30 fps.
27. **A unidade do `--trava`** era "quadros a 30 fps"; o correto é quadros do vídeo gerado (segundos × fps da geração).
28. **Miku:** a pós padrão passou para nenhuma, porque a grade de tela inteira congela o fundo, que é o motor perpétuo dessa referência.
29. **Sala de aula:** entrou o aviso de que o travar congela a tela inteira e ela segura em camadas.
30. **Corte sem grade:** comando próprio e instrução de tirar o `-t` quando o aceite não indicar corte.

**Ferramentas alteradas**

31. **`pos/aceite.py` ganhou `--hold-max`, `--piso-min` e `--ref`.** Sem esses parâmetros, faz o mesmo que antes; o original está em `aceite_v1_backup.py`.
    - **Por quê:** com o padrão, ele reprovava 2 das 8 referências (Aqua: pausa de 1 s e piso de 0,07; sala de aula: piso de 0,09), então não servia para esses tipos sem ajuste. Com `--piso-min 0.08`, a sala passa.
    - **O que o `--ref` resolve:** a energia é relativa ao próprio pico, e uma geração lenta do começo ao fim, sem a referência no início, passaria. O `--ref` mostra a razão de desenhos/s e de energia contra a referência e sugere a pós. Nas 6 gerações, a sugestão "nenhuma pós" saiu para a fa5, a 0ca, a a2c e a 48e, e "regerar" para a 81d e a 33f.

**Conflitos que ficam em aberto** (precisam da sua decisão, porque mexem no W1)

32. **Braços cruzados contra a corrente do W1.** A corrente pede que "as mãos nunca param". Em referências cuja parte fixa são os braços cruzados (Miku), isso vai descruzar os braços.
33. **"mesma personagem" com dois personagens.** Continua em aberto (T6).
34. **Segundos nas âncoras.** O veto vinha da contagem de quadros, que falhou. Segundos nunca foram testados, e um guia de terceiros para o Wan 3.0 recomenda timestamps por plano. Isso virou o teste T8, não regra.

**Fontes sobre o Wan 3.0** (vistas só pelos resultados de busca; o proxy bloqueou a abertura das páginas):

- [Alibaba Model Studio: referência da API de vídeo do Wan 3.0](https://help.aliyun.com/zh/model-studio/wan3-video-generation-api-reference): prompt de até 20.000 caracteres, com corte automático acima disso.
- [Referência antiga da API de texto para vídeo do Wan](https://help.aliyun.com/zh/model-studio/legacy-wan-text-to-video-api-reference) e [Wan 2.7 texto para vídeo](https://evolink.ai/docs/cn/api-manual/video-series/wan2.7/wan2.7-text-to-video): limite de 5.000 caracteres e `prompt_extend` (reescrita por LLM) no 2.7.
- [Vercel AI Gateway: Wan v3.0 Video](https://vercel.com/ai-gateway/models/wan-v3.0-video/api): modos de texto, imagem e referência para vídeo, de 2 a 30 s.
- [Atlas Cloud: como escrever prompts para o Wan 3.0](https://www.atlascloud.ai/blog/guides/how-to-write-wan-3-0-prompt): recomenda timestamps por plano.
- [Eachlabs: parâmetros da API do Wan entre versões](https://www.eachlabs.ai/blog/wan-video-api-parameters-prompts-version-changes): o esquema de parâmetros muda entre as versões 2.5, 2.6, 2.7 e 3.0.