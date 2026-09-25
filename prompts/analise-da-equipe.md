# O que a equipe encontrou nos seus ~25 prompts

Resumo das análises dos 13 especialistas sobre `prompts/referencias/lote-01.txt`, `lote-02.txt` e `lote-03.txt`.

## O que há de melhor no acervo (e entrou no super prompt)

| Ideia | De onde veio | Como entrou no «DO NOT TOUCH» |
|---|---|---|
| Um toque minúsculo → meio segundo de silêncio → rachadura "喀→喀喀→rede" | BOSS de pedra | O toque de garfo no pudim derruba o museu |
| O corpo é mais honesto que o rosto; a cauda "mente" | Fast food voxel, lanterna ("Fear level? Zero") | A cauda aponta para o pudim enquanto ela diz que nem gosta de pudim |
| A gula maior que o instinto de sobrevivência | Avião (salvar o pudim contra o cinto) | Ela se joga para salvar o pudim no meio do desabamento |
| Jogar a culpa em outro de boca cheia | Fast food ("HE did it!") | "He did it." apontando o gato |
| Uma testemunha impassível | Ventilador, deserto, varredor | O gato, que desta vez produz a prova contra ela |
| Objeto com arco próprio | Chapéu de papel que escorrega | O quepe de vigia, que fica mais torto a cada plano |
| Uma cor guardada para um único momento | Pizzaria ("紅眼為全片唯一純紅"), PAYDAY | O vermelho puro aparece só no alarme, por cerca de 1s |
| Um único olhar para a câmera, guardado para o final | Fast food, avião | Ela descobre a câmera de segurança |
| Frases humanas: confiança que racha, justificativa absurda | Mina ("Please tell me I got this"), fast food ("Quality check") | "Quality... control." |
| Rack focus da comida para os olhos | Enderman, avião | A primeira imagem do vídeo |

## Problemas que se repetiam (e foram corrigidos)

1. **Ficha da personagem contraditória.** Metade dos prompts manda animar as orelhas, a outra metade diz 「嚴格禁止獸耳」. A cauda às vezes não tem tipo, às vezes é cauda de cobra, às vezes é branca. Os dentes variam entre uma fileira de tubarão, 虎牙 (presas caninas) e uma presa só de um lado. A bochecha de hamster aparece como obrigatória e também como proibida. → Criamos a **Bíblia da Cissia**, um bloco único.
2. **O mesmo final em cerca de 12 prompts:** impact frame, flash branco, corte seco para preto e congelamento "no quadro mais saturado". → O super prompt termina no olhar dela, com o som ambiente ainda tocando.
3. **Superlativos vazios** («院線級», «官方過場動畫級», «高級», «漂亮») e o pacote bloom + lens flare + aberração cromática colado em todo prompt. → Trocados por fontes de luz concretas.
4. **Beats demais para 15s.** O BOSS tem uns 20 beats e o Pac-Man tem uns 15 planos. → Agora são 3 planos e 3 falas.
5. **Contagem de frames** ("三幀半眨", "不少於8幀", "1幀閃白"). O gerador não controla frame. → Agora os tempos estão em segundos.
6. **Regras que se contradizem.** "Não olhe para a câmera" junto com "encare a câmera"; "não pode ter segundo mudo" junto com silêncio obrigatório; "não trema" junto com "handheld chaos".
7. **Marcas e propriedade intelectual.** FNAF ("官方聯動"), Pac-Man, Minecraft/Enderman, McDonald's, YouTube/X, Miyabi/ZZZ, Super Saiyan e o bordão "Did I do that?". → No super prompt, tudo é original.
8. **Restos de chatbot colados no prompt**, como "如果你要，我下一則可以…", "依據要求，已減少 50% 贅述" e trechos em português no meio do texto. O gerador lê tudo isso como instrução.
9. **Blocos duplicados.** O ventilador e o carro que cresce aparecem duas vezes no lote 1, e o Pac-Man duas vezes no lote 2.

## Decisões que ainda são suas

- **Orelhas.** Coloquei "耳朵完全照 @Video1，不另外加任何獸耳" (orelhas exatamente como no @Video1, sem acrescentar orelhas de animal). Se ela tiver orelhas de animal no vídeo de referência, apague a parte "不另外加任何獸耳".
- **Formato.** Escolhi 9:16 (TikTok/Reels). Para YouTube horizontal, troque por "橫式 16:9".
- **Ferramenta.** Se o gerador faz 15s de uma vez (Seedance, por exemplo), use a versão única. Se faz 5–6s por vez, use as 3 tomadas.
