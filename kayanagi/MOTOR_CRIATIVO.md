# MOTOR CRIATIVO — o que o outro chat fazia de certo (e como eu uso na Kaya)

> **MODELO-MESTRE: `prompts/02_aquario.md`.** Toda cena nova usa o esqueleto e o jeito de escrever do aquário:
> núcleo "核心不是劇情邏輯，而是超高能量 acting"; corpo solto; mãos em moinho que somem em linhas várias vezes;
> câmera viva que persegue ELA (nunca plano aberto que a diminui); ≤3 objetos que participam; a ação mais difícil
> (entrar/sair de algo) com mais texto; quase sem fala; final seco. Da cena do dragão vem só o acabamento
> (luz, cor, materiais). Muda a cada cena: cenário, entrada, ação central, ângulos únicos e final.
> Referência aplicada: `prompts/15_lavanderia.md`. Regras do guia-mestre que freiam energia
> ("linhas só no pico", "só 3 vezes", "sem tremor constante") NÃO valem por cima do aquário.

> **Lições do vídeo de terror (`16` v1 × aquário), 26/09:**
> - **Linhas de movimento NÃO são "mão girando como moinho".** São o braço fazendo um movimento real e grande
>   (correr jogando os braços para a frente, arremessar, cavar, puxar), e, no trecho mais rápido, o braço vira
>   várias linhas brancas finas e afiladas **ao longo do arco que ele realmente percorre**, com a mão ainda visível
>   na ponta. Quanto mais rápido, mais linhas. Correndo, os braços puxam o corpo para a frente. No v1 viraram anéis
>   simétricos girando em volta de um corpo parado: errado.
> - **Câmera de corrida:** colada nela, na mesma velocidade, na frente e de lado, na altura da cintura, de baixo para
>   cima, inclinada ~20°, ela ocupando mais da metade do quadro, fundo esticado em listras. Nunca plano fixo distante
>   com ela pequena no centro (o v1 fez isso no relógio e na fuga).
> - **O primeiro quadro já tem ela em velocidade máxima.** O v1 começou com 1 s de porta vazia.
> - **Nunca escrever ações lentas** ("vira a cabeça devagar, quadro a quadro", "silêncio", "prende a respiração") em
>   cenas de gênero (terror, suspense): o modelo transforma em planos parados. O medo deixa ela mais rápida.
> - **Luz forte e legível.** Terror escuro = imagem apagada. Luar forte, relâmpagos frequentes, feixes claros.
> - **Som (medido nos vídeos):** o aquário original NÃO descreve som nenhum, e o gerador colocou sozinho efeitos de
>   desenho animado colados em cada movimento ("vush" dos braços, chiado da freada) e silêncios de contraste. Parcela de
>   som agudo tipo "vush": aquário 13,5%, congelador 11,3%, peixaria v2 10,7%, sushi 9,8%, sofá 7,4%, terror 5,6%.
>   O terror (chuva, trovão e música descritos) virou uma parede grave e constante. Regra: **não escrever ambiente
>   sonoro nem trilha contínua**; escrever só o som de cada movimento dentro da própria ação (cada volta do braço/linha
>   de movimento = um "咻" agudo; freada = "吱——"; arremesso = "咻—砰"); ambiente, se existir, "muito longe e baixo";
>   um momento de silêncio de contraste antes da explosão. É correlação em 6 vídeos, não prova, mas bate com o que o usuário sentiu.
> - **Não sobre-especificar** (listas de materiais, parágrafos de som, regras longas de monstro): o aquário não tem
>   nada disso e dá mais liberdade de movimento ao modelo. Ver `prompts/16_casa_assombrada_v2.md`.


Fonte: chat do usuário com outro modelo sobre a Cissia (≈170 pedidos, set/2026). O usuário considera esse chat
"ouro": o modelo errava muito, mas **toda ideia virava uma cena legal de assistir**. Este arquivo explica por quê.

Ordem de uso: 1) este arquivo gera a IDEIA e a composição; 2) `GUIA_MESTRE.md` garante a EXECUÇÃO (física, mãos,
continuidade, falas); 3) `GUIA_DE_ESTILO.md` guarda identidade e histórico. Criatividade do chat + rigor do guia.

---

## 1. O que o usuário gosta de ver (tipos de cena)

- **Fome como motor de tudo.** Comida viva, textura (queijo esticando, pudim balançando, gotas), mordida por mordida.
- **Comédia de falha física.** Ela se acha boa, erra, a física trai: é arremessada, cai de cara, bunda para cima,
  chora lágrimas de anime voando em câmera lenta. Apanhar/errar com peso é engraçado; ela nunca é "robô".
- **Gigante de verdade.** Muito maior que prédios (até 50×), **peso**: o corpo parece lento *por causa* da massa,
  cada passo afunda e treme, cair tem que ser sentido, nada para de repente. Nuvens, vento, pássaros, respiração que
  puxa nuvem, espiar dentro das casas pelos buracos com gente fugindo, destruição em cadeia. Ponto de vista humano.
- **Beleza pura.** Cada corte parece ilustração: vento forte com fios de poste mexendo, lua, poças, luz rebatendo.
- **Luta sakuga.** Golpes variados (nunca socos retos), esquivas por um fio, contra-ataque, impacto em câmera lenta
  com a pele do rosto ondulando, baba e lágrimas voando, corpo girando no ar e caindo com peso.
- **Atuação viva de mãos e rosto** (análise do vídeo "Miku/Teto"): a mão tem foco próprio, dedos se mexem ao apontar,
  aponta para si mesma ao falar de si, pisca para pensar. Muitos cortes curtos quando a atuação pede.
- **Câmera viva:** operador imperfeito (atrasa na arrancada, passa do ponto na freada e corrige, perde o foco num
  objeto do primeiro plano e reencontra), som que acompanha para onde a câmera olha.
- **Toda personagem tem o seu momento** quando há mais de uma. Coadjuvante parado = cena morta.

## 2. O motor do outro modelo (por que ele era criativo)

1. **Um fenômeno físico central, com nome.** Ele nunca entregava "uma lista de ações": cada cena girava em torno de
   UMA imagem física memorável que o gerador de vídeo consegue renderizar bem:
   - pudim do tamanho de uma cidade que balança; ela o ergue através das nuvens e **gotas de condensação se formam na pele**;
     ao sair das nuvens o sol explode; a mordida **afunda o pudim antes de cortar** e mostra o miolo;
   - a cauda que **se enrola na perna da mesa** para ela não cair;
   - no boxe, ela bate de costas nas cordas e **a própria corda a arremessa para dentro do soco**;
   - duas personagens **empilhadas** que perdem o equilíbrio juntas (física do Ponyo);
   - a gigante **abrindo o telhado com a unha como tampa de garrafa**; **o olho dela enchendo o buraco visto de dentro do quarto**;
   - a gigante caindo de cara e **deslizando, empurrando prédios como um trator**.
   Pergunta-chave: *qual é a imagem que alguém tiraria print?* A cena é construída ao redor dela.
2. **A comédia vem da física traindo a personagem**, não de uma piada falada: inércia, rebote, desequilíbrio,
   material inesperado (duro, mole, grudento). Causa e efeito legíveis.
3. **Um bloco "softness" em câmera ultralenta** perto do clímax: é onde a textura aparece (gotas refratando a luz,
   baba e lágrimas em trajetória 3D, pele deformando no impacto, cabelo em onda). O usuário ama esses momentos.
4. **Texturas sensoriais escritas como material deformando:** "Q彈", "黏稠", "拉絲", "凝結水珠", "多孔剖面".
5. **Cada corte tem uma ideia de composição própria**, com um objeto de primeiro plano que conta algo
   (lata suada de refrigerante, garfo virando linha, xícara quebrando) e uma posição de câmera incomum
   (de dentro do quarto, da altura da mesa, de baixo do pé gigante, drone).
6. **Formato estável que o Seedance 2.5 segue bem:** identidade → espaço/câmera/ambiente sonoro → 5–6 cortes, cada um com
   *composição em 3 camadas + ação + fala + som* → regras de física no fim. Texto curto por corte, ideias fortes.
7. **Final como consequência física** (desabar, deslizar, chorar no chão), nunca pose.

## 3. Os erros dele (não repetir)

- Inventar fatos (chamou a Cissia de "Caesar King"), trocar idioma (prompt em português, falas em chinês por engano).
- **Bugs de espaço:** personagens de costas para o mar com o vento vindo "da frente", inimigo surgindo atrás de quem
  estava de frente para a porta, personagem que some e reaparece em outro lugar (teletransporte).
- **Atuação estática** e emoções genéricas ("fica com raiva"). Coadjuvantes mortos.
- **Coreografia travada:** socos retos, nenhuma esquiva, golpe que acerta o ar.
- **Final robótico** (sinal de V e frase de efeito). Falas-slogan ("This cheese looks absolutely heavenly! I'm diving in!").
- Mascarar um bug mudando a cena inteira. O usuário quer que se **isole o problema e se conserte só ele**.
- Perder a roupa/figurino no meio da cena.

## 4. Regras que o usuário criou naquele chat (continuam valendo para a Kaya)

- **Não-omissão física:** toda ação difícil tem 4 fases desenhadas — preparação → atrito/compressão → ápice →
  overshoot e acomodação. Nada de pular quadros. É o que prende o espectador e faz o tempo passar rápido.
- **Entendimento da cena / causalidade:** sempre dizer de onde vem a força, o golpe, o vento, e o que causou cada reação.
- **Falas naturais:** respondem umas às outras em cadeia, contrações ("gonna", "'kay"), cortadas pela respiração;
  boca cheia = voz abafada; nunca descrever o que a imagem já mostra; sem vácuo de voz (gemidos, respiração, risinho).
- **Som físico:** material + distância + espaço; ruído de ambiente contínuo; nada de bip eletrônico.
- **Anti-atuação estática:** pupila com micro-movimento e micro-zoom (contrai no susto, dilata ao se recuperar);
  **piscar como antecipação** antes de mudar de estado; rosto descrito por músculos (sobrancelha esquerda desce em
  diagonal, canto do lábio sobe mostrando o dente), dedos com movimento independente, força viajando
  ombro → cotovelo → pulso → palma → dedo.
- **Câmera viva** (ver seção 1).
- (Opcional daquele chat, só se o usuário pedir para a Kaya: legendas pequenas em japonês, estilo ZZZ, 50% de opacidade.)

## 5. Como eu gero uma cena da Kaya a partir de agora

1. **Ler o pedido ao pé da letra** e listar o que o usuário quer VER (ex.: "Kaya gigante saindo da água como um kaiju"
   = ela é o kaiju). Moldar a ideia sem trocar a ideia principal.
2. **Achar o fenômeno físico central** (a imagem de print). Testar 3 candidatos, escolher o mais visual e mais "Kaya"
   (tubarão, fome, corpo elástico, cauda pesada).
3. **Fazer a física trair a Kaya** para gerar a comédia (inércia, rebote, material inesperado).
4. **5–6 cortes**, cada um com: posição de câmera incomum + objeto de primeiro plano que conta algo + UMA ação completa
   em 4 fases + som com material e distância. Pelo menos um corte de **dentro de algo** ou **do ponto de vista humano**.
5. **Um bloco em câmera ultralenta** com textura (gotas, baba, lágrimas, pele, cabelo, comida).
6. **Mãos em linhas de velocidade** nos picos (3 usos com sentidos diferentes), voltando a ser mão antes de tocar.
   Corrida sempre em curva.
7. **Gigante:** a massa é lenta e pesada (passos que afundam, água/poeira/nuvem que demoram a assentar, quedas
   sentidas), mas a **intenção dela continua ansiosa e rápida** (olhos, rosto, mãos gulosas). Atmosfera participa:
   nuvens, vento, pássaros, respiração.
8. **Final:** consequência física ou escolha dela. Nunca pose, V ou frase de efeito.
9. **Auditoria anti-bug:** direção de cada personagem, lado do vento, posições que não mudam entre cortes, nada de
   teletransporte, figurino inteiro até o fim, cada coadjuvante com um momento.
