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

**Concluído em 02/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase285.md` a `docs/plano_fase289.md`),
testes, captura e benchmark. As três pastas da suíte passaram no fim (world 681, presentation 389, ui 167).

- O FPS do trajeto do benchmark desceu devagar ao longo do ciclo (75,9 na Fase 284, 73,8 na 289), com a GPU de 12,1 a 12,3 ms.
- Com a câmera em cima do prado, o tapete de capim com as flores custa +0,32 a 0,43 ms de GPU (`tools/grass_cost.tscn`).

Diferenças do roteiro:

- o raio do tapete ficou em 90 m, com os tufos encolhendo de 55 a 95 m (na primeira medida, de 30 a 55 m, ele não aparecia na
  distância normal da câmera);
- as flores ficaram sem a regra de "menos perto das casas" (o terreno não sabe das casas; o tapete e as manchas já ficam fora
  dos lotes);
- a beira do barranco ficou só no shader, sem as raízes do recheio.

O antes e depois do ciclo está em `F:\ferramentas\capturas\fase289\ciclo_antes_depois.png`. A vista do barranco de "antes" é a
do começo da Fase 289: a busca do barranco da captura mudou nela.
