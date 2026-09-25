# Kayanagi — Guia de estilo para prompts de vídeo

Referência para criar cenas novas da Kayanagi no mesmo nível dos prompts em `prompts/`.
Os prompts são escritos em **chinês tradicional**; só as falas (entre aspas) são em **inglês**.

- `prompts/02_aquario.md` é o **original**: dele vem a energia (a ação física exagerada, o jeito dela se mexer).
- `prompts/03_minecraft.md` é a referência de **história** (arco, virada, final), mas o texto deve seguir a prosa do aquário.
- `prompts/04_sushi.md` é um **exemplo do que não fazer** (ver "Lições dos vídeos gerados").
- `prompts/05_congelador.md` aplica as lições: forma nova, mesma energia.

## Por que o Minecraft é superior (a receita)

O aquário tem energia, mas é uma sequência de ações. O Minecraft tem energia **e** uma história de 30 segundos:

1. **Motivação clara:** a ganância dela move cada ação.
2. **Um mundo com regras próprias** e um contraste visual com ela (voxel × render 3D de alta qualidade).
3. **Uma regra quebrada:** ela toca no que não devia e o mundo muda (congela).
4. **Um antagonista silencioso** que não precisa falar (Herobrine).
5. **Consequência física e absurda:** erguida pela mochila, o chão apagado, a queda para fora do mundo.
6. **Arco de luz:** quente → frio e invasivo → neutro. A luz conta a história junto com ela.
7. **Arco emocional:** ganância → curiosidade → medo (no corpo antes da boca) → blefe → pânico → alívio → teimosia.
8. **Plantar e pagar:** a esmeralda escondida no bolso volta no final.
9. **Ficha técnica por plano:** tempo em segundos, lente (24mm, 85mm, 100mm), ângulo, ação quadro a quadro, fala com instrução de como ela é cortada.
10. **Som como ação:** vozes esticadas e cortadas, estática, o mundo ficando distante.

## Lições dos vídeos gerados (o que funciona de verdade)

O sushi (`04_sushi.md`) ficou ruim e o aquário ficou bom. Olhando os quadros:

- **Toda ideia do usuário tem essa energia, mesmo as que parecem calmas** (andar de carro, esperar, sentar).
  Não recusar nem trocar a ideia: se ela precisa ficar sentada, o corpo dela continua em movimento
  (pernas tremendo em borrão, cauda batendo no teto, cor do rosto mudando, reação física a cada solavanco).
- **Ela sentada e quieta = cena morta.** No sushi ela passa a maior parte sentada no balcão comendo, depois sentada no prato.
  O aquário não tem nenhum momento sentado.
- **Ela tem que fazer a ação, não sofrer a ação.** No sushi quem age é o chef e a esteira; ela é carregada.
  No aquário ela corre, mergulha, enfia a cabeça, puxa. O mundo só reage.
- **Poucas ações grandes > muitas piadas pequenas.** O sushi tinha umas 25 mini piadas (chá, molho, pilha de pratos, placa...)
  e virou 27 cortes curtos sem nenhuma ação completa. O aquário tem ~6 ações físicas grandes, cada uma com tempo.
- **Plano aberto mata a energia.** No sushi ela aparece pequena, longe. No aquário a câmera está colada nela.
- **Linhas de velocidade nos braços são a assinatura.** Precisam estar lá, em mais de um momento.
- **Rosto de anime exagerado funciona:** bochecha estufada, boca maior que o rosto, olhos de estrela.
- **O prompt em prosa (estilo aquário) gerou resultado melhor** que o formato em lista com minutagem.
- **Não repetir a forma.** O sofá funcionou mas é o aquário com outros objetos. Cada cena nova precisa de:
  entrada diferente, jeito diferente de se locomover, ação central diferente e final diferente.
  O que se mantém são os princípios (energia, física, câmera colada, linhas de velocidade), não a sequência.

## Como usar a referência (vídeo ou imagem)

Pedir para copiar **a personagem** e **a qualidade de produção**, nunca o cenário, o enquadramento ou a história da referência.
Este parágrafo abre toda cena nova:

```
參考素材的使用方式：提供的角色圖是角色外觀的唯一來源，角色必須完整複製。提供的參考影片只用來複製「製作品質」：渲染精度、材質與紋理細節、布料與頭髮的物理、光影層次、景深、粒子與特效的精緻度、動畫流暢度與表演強度。不要複製參考影片的場景、構圖、鏡頭順序或劇情；本片的場景、鏡頭與動作全部依照以下描述重新創作，但必須達到與參考相同或更高的製作品質。
```

## Quem ela é

- **Nome:** Kayanagi (渦耶凪, "redemoinho e calmaria"). Apelido **Kaya**, codinome **Nagi** na Shark Unit.
- **Personalidade nas cenas:** energia explosiva, gananciosa e curiosa, nunca para. Quando é pega,
  o medo aparece primeiro no corpo (ombros sobem, cauda trava, olhos arregalam) e depois na boca,
  com um blefe nervoso e sarcástico.
- **Assinatura:** mordida de tubarão na câmera, cartunesca e sem sangue.

## As regras da energia (o que torna os prompts "insanos")

1. **Ela nunca está parada.** Mesmo quando congela, respira, treme, a ponta da cauda e a antena da touca se mexem.
2. **Todo movimento tem 4 tempos:** preparação → ação exagerada → overshoot (passa do ponto) → rebote.
3. **O corpo inteiro atua**, não só o rosto: cabeça, pescoço, ombros, cotovelos, pulsos, dedos, coluna,
   quadril, joelhos, tornozelos, antena, fones, cabelo, lenço vermelho, equipamento e cauda.
4. **Ordem de transmissão de força:** quadril → coluna → ombros → cabeça → mãos; raiz da cauda → meio → barbatana.
   Antena, fones, cabelo e lenço vermelho sempre chegam **meio tempo atrasados**.
5. **Proibido teletransporte:** ações-chave (entrar e sair de um lugar apertado, frear, pular) aparecem inteiras,
   com peso, resistência e explosão. Nunca resolver com um corte de câmera.
6. **Braços em alta velocidade** podem virar só linhas de velocidade e rastros.
7. **Frenagem completa:** o pé trava → derrapa → joelhos dobram → quadril continua → ombros e cabeça vão
   meio tempo depois → braços dão mais uma volta → o corpo volta ao centro → a cauda compensa.
8. **A cauda tem peso e volume:** nem tábua rígida nem fita sem peso. Em superfície macia ela deforma (squash).
9. **Câmera agressiva e sempre mudando:** muito baixa rente ao chão, de cima, contra-plongée, de **dentro do objeto**
   (de dentro do sofá, de trás do vidro do aquário, pelo ponto de vista do controle). Nunca frontal parado.
10. **Coadjuvantes reagem, não roubam a cena:** peixe, controle remoto, aldeões são alvo da comédia.
11. **Continuidade de objetos:** se ela tira a touca, é um movimento visível, a touca fica onde caiu e não volta sozinha.
12. **Final seco e abrupto:** um punchline (mordida na câmera, algo tapando a lente) e corte. Sem explicação.
13. **A comédia vem do exagero dela**, não do cenário: ela destrói tudo por um motivo minúsculo.
14. **A luz serve a ela:** rosto, olhos, cabelo, touca e cauda sempre legíveis; o cenário nunca é mais importante.
15. **Plantar e pagar:** se algo vai importar no final (ex.: a esmeralda escondida no bolso), mostre claramente antes.

## Estrutura que funciona

| Tempo | O que acontece |
|---|---|
| 0–3 s | Entrada explodindo: ela já está na velocidade máxima no 1º quadro, câmera rente ao chão |
| 3–4 s | Frenagem com física completa, visto de um ângulo estranho |
| meio | Busca/caos com o corpo todo, closes de mãos e olhos, detritos voando no primeiro plano |
| virada | Ela trava, algo chama a atenção (cabeça "estala" para cima com follow-through) |
| clímax | Ação absurda e física (enfiar a cabeça, ser erguida, cair do mundo), entrar E sair por completo |
| final | Nova ideia a acende → dispara em direção à câmera → punchline → corte seco |

## Bloco fixo de aparência (copiar em toda cena nova)

```
角色名稱：Kayanagi（暱稱 Kaya，鯊魚小隊代號 Nagi）。把提供的角色圖作為唯一主參考與母體屬性來源，完整複製並沿用圖中已經成立的所有角色屬性、視覺屬性、動畫屬性、表演屬性、材質屬性、動作語言屬性與鏡頭語言屬性。整個 prompt 使用繁體中文書寫，只有角色實際說出口的對白使用英文；所有放在引號內的台詞一律寫成英文。

角色必須始終保持與提供角色圖完全相同的外觀：相同的女性臉型、相同的亮青綠偏湖水色大眼睛（眼下帶淡淡黑眼圈）、相同的深黑偏墨青色長髮，髮型略帶凌亂，有長側瀏海與自然垂落的後髮輪廓；頸部戴深色細頸圈。頭上戴著圖中相同的白色軟質針織帽，帽身有青色橫條，兩側為圓形藍色耳機，帽頂有一根細長彎曲的呆毛狀觸角。嘴部維持角色圖中相同的造型，張嘴時可清楚看見細小尖銳的鯊魚式牙齒。

服裝完全依照角色圖鎖定，不重新設計：白色露肩長袖制服襯衫、袖子上的青色條紋與菱形臂章、胸前垂直的青色領帶、左肩的紅色披巾／飾帶、深色內層背心、橄欖綠戰術背帶與背後的橄欖綠戰術背包、深棕色多袋工具腰帶與大型金屬環、白色百褶短裙、黑色半指戰術手套、大腿上的深色固定帶、深棕黑色長筒襪（上緣白色帶）、黑色戰術短靴（紅色鞋底）。所有位置與比例必須保持一致。材質是高品質三維動畫角色材質。

她只有一條清楚可見的大型鯊魚尾。尾巴從腰後自然延伸，根部厚實，往末端逐漸收細：背側為深海藍青色並帶一排鋸齒狀背鰭，腹側為淺灰白色，中後段保留明顯鰭片，末端為垂直大型新月形尾鰭，所有鰭尖帶紅色。尾巴的配色、體積、長度、曲率、鰭的位置與輪廓全程不能改變。
```

## Bloco fixo de regras (fechar toda cena nova)

```
【強化規則】
角色全程幾乎不能進入真正靜止。
每一個動作都要有預備、主動作、overshoot、回彈。
手臂高速動作時，可以誇張到只剩速度線和殘影。
關鍵動作（進入與離開狹窄空間、急煞、跳躍）必須完整演出，絕對不能像 teleport。
鏡頭角度必須一直變，要怪、要近、要有侵略性，不要老是正面平視。
角色能量要像快爆掉，讓觀眾一直覺得她下一秒還會做更誇張的事。
角色外觀從第一幀到最後一幀必須鎖定提供角色圖：亮青綠色眼睛、深黑墨青長髮、相同臉型、鯊魚式小尖牙、白色針織帽與藍色耳機及帽頂觸角、白色露肩襯衫、青色領帶、左肩紅色飾帶、橄欖綠戰術背帶與背包、多袋工具腰帶、白色百褶短裙、黑色半指手套、腿部固定帶、深色長筒襪與黑色短靴，以及唯一一條背藍腹白、鰭尖紅色的大型鯊魚尾。
禁止把鯊魚尾生成成全白色、蛇形、毛絨尾、細尾、惡魔尾或多尾。禁止生成獸耳。禁止改變髮色、眼睛顏色、制服輪廓或角色身材比例。
針織帽只能由角色以可見連續動作取下；取下後留在原處，不能消失，也不能突然重新出現在頭上。
```

## Cuidados

- Usar só caracteres **tradicionais** (ex.: 擠壓 e não 挤压, 誇張 e não 夸张, 裡 e não 里, 介質 e não 介质).
- Nunca voltar para a aparência antiga (quepe militar escuro, uniforme azul-marinho, gravata vermelha): isso é de outra personagem.
