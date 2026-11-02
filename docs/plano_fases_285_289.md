# Roteiro das Fases 285 a 289 — Prado

**02/11/2026.** Terceiro ciclo da ideação de 02/11/2026 (ver `docs/plano_fases_275_279.md`). A referência é o Anno aberto nesse
dia: o prado de perto (`c10_05`), o capim entre as árvores (`c10_07`) e o da beira da cidade (`c10_02`), em
`F:\ferramentas\capturas\anno\`. Como sempre, **só a ideia**: tudo é gerado no código.

## O diagnóstico

- **Chão liso.** De perto, o capim do Society é a textura chapada do terreno com umas touceiras soltas (o recheio da Fase 41). No
  Anno, o prado é um tapete de capim: touceiras mais escuras, flores miúdas e as lâminas à mostra perto da câmera.
- **Verde de uma nota só.** Todo o capim tem o mesmo verde-amarelado das Fases 257 e 262. No Anno, há manchas de capim alto, mais
  escuras, e de capim baixo e seco, mais claras.
- **Papoulas em grade.** Os canteiros de papoulas (Fase 156) saem como pontos vermelhos em linhas regulares, porque cada célula
  leva a mesma touceira no mesmo lugar.
- **Borda seca.** Onde o capim encontra o barranco ou a margem, o Society corta a cor de uma vez. No Anno, o capim pende sobre uma
  faixa de terra, pedras e raízes.

## As fases

| Fase | O quê |
|---|---|
| 285 — Manchas do prado | no `shaders/terrain.gdshader`, manchas de capim alto mais escuro e de capim baixo mais claro, de 3 a 12 m, de borda recortada e com um pouco de relevo no mapa de normais; só no capim (fora da estrada, do campo, da areia e da rocha) |
| 286 — Tapete de capim | perto da câmera (até ~60 m do ponto que ela olha), um MultiMesh de tufos de lâminas que segue a câmera em blocos, posto na altura do terreno e só no capim livre (sem prédio, estrada, campo nem água), balançando com o vento pelo `shaders/foliage.gdshader` e sumindo aos poucos com a distância. É a fase mais cara do ciclo: o tamanho do raio sai do benchmark |
| 287 — Flores miúdas | pontinhos brancos e amarelos no capim: nos tufos do tapete de perto e, de longe, no shader do terreno, mais nos prados abertos e menos perto das casas |
| 288 — Papoulas soltas | os canteiros de papoulas perdem a grade: várias touceiras por célula em lugares sorteados, de tamanhos diferentes, com a densidade caindo para a borda da mancha |
| 289 — Beira do barranco | na borda de cima dos barrancos e das margens, uma faixa estreita de terra e pedras com raízes à mostra onde o capim acaba (shader do terreno, pela inclinação logo adiante, e umas raízes do recheio) |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

O tapete de capim (Fase 286) é a primeira vista que segue a câmera em vez de seguir o mundo:

- refaz só os blocos que entram no raio, sem nada a cada quadro;
- não entra no save;
- respeita o "reduzir movimento" (Fase 43) no balanço.

## Estado

A fazer.
