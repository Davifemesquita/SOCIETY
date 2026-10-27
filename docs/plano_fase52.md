# Plano da Fase 52 — Ilhas no jeito do Anno (enseadas, falésias e rochedos)

**Estado: feita em 26/10/2026, a pedido do dono** ("abra o Anno 1800 e entenda como quero que fique, principalmente a
parte gráfica e a formação e o formato das ilhas"). O Anno foi aberto no PC do dono, no save dele, e só olhado (capturas
de tela em `F:\ferramentas\capturas\anno`, fora do repositório). Engenharia reversa e arquivos do jogo, não: a regra do
projeto (nada do Anno além de ideias) e os termos da Ubisoft proíbem; o link que o dono mandou é uma página de tópico do
GitHub, não um repositório.

## O que o Anno mostra (comparado com as nossas ilhas v1/v2)

| | Anno 1800 | Society antes |
|---|---|---|
| Formato | ilhas compridas e irregulares, com penínsulas e enseadas fundas em arco | manchas redondas (v1 quase quadradas) |
| Costa | praia clara e larga dentro das enseadas; falésia de rocha escura nos cabos | praia ou falésia por ruído, sem relação com a forma |
| Em volta | rochedos soltos e ilhotas de pedra junto aos cabos | quase nada (o v2 tem ilhotas baixas) |
| Água | rasa e turquesa junto à costa e nas enseadas, funda e azul longe | faixa clara em volta de um quadrado de cantos redondos |
| Interior | quase todo plano, morros só em parte | patamares em anéis subindo para o meio |
| Rios | serpenteiam pelo interior até uma enseada | braço de mar curto que entra pela planície |
| Cor | grama verde saturada, mata com copas variadas, areia clara | grama amarelada, mata em blocos escuros, névoa forte de longe |

## O que entrou nesta fase (formato; a cor e a água ficam para a Fase 53)

- **Gerador v3** (`terrain_version = 3`, `ArchipelagoGenerator.shape_v3`/`height_at_v3`, parâmetros em
  `TerrainV3Params`, que herda o warp, a costa fractal, os patamares e a ondulação do v2):
  - a ilha é uma **espinha curva** de 3 a 5 elipses (as das pontas menores) com até 3 **penínsulas**, esticada para a
    borda mais longe tocar `shore`;
  - **enseadas** (2 a 3): elipses largas cortadas da terra por união suave ao contrário, em ângulos espaçados, medidas a
    partir de um ponto da espinha (o meio da grade pode cair no mar); numa ilha estreita a enseada encolhe (até 40% da
    distância até a costa) para não partir a ilha;
  - perto da enseada a costa fica lisa (praia em arco), a água rasa (`bay_shallow_m`) e a praia larga;
  - no resto, a costa vira **falésia** pelo ruído, e a planície de cima dela sobe ao segundo patamar (3,6 m): a terra
    sai do mar de uma vez; o degrau entre a planície da falésia e a da praia é curto (a rampa larga tirava terra de
    construir);
  - **rochedos**: um ou dois grupos junto a cabos longe das enseadas, de paredes íngremes e topo quase plano, com pelo
    menos três células de raio e o lado de dentro sempre fora da terra (soltos, não morros na costa);
  - a descida para o mar é medida em **células** (praia 1,5, enseada 2,5, falésia 0,8), não em fração da ilha: na ilha
    grande a praia do v2 virava uma rampa de 15 m e não deixava construir na beira;
  - interior quase plano: quatro patamares (1,2 / 3,6 / 6,6 / 9,6 m) e degraus curtos.
- **Plataforma desenhada pela costa de verdade** (só no v3): o fundo do mar desenhado (`region_corners`) desce pela
  distância até a terra (chanfro 3-4), não pelo quadrado do v1; a água rasa turquesa acompanha enseadas e rochedos.
- **Jogo novo**: o v3 é o padrão (`GameConfig.new_game_terrain_version = 3`, pedido do dono) e aparece no jogo novo como
  "Enseadas e falésias"; o v1 e o v2 seguem para os saves e para quem escolher.
- Saves: a versão 3 entra em `ArchipelagoGenerator.VERSIONS`; save de versão desconhecida segue recusado.

## Números (sementes de referência, principal de 120 células nos testes)

- Alongamento (raiz da razão dos eixos da terra): v3 1,16–1,76 (69% das ilhas acima de 1,3); v2 1,04–1,26.
- Enseadas: 2 ou 3 em toda ilha; rochedos soltos em 11 das 16 ilhas.
- Costa alta (falésia) na principal: 26–49%.
- Lotes de casa na principal: 205 / 287 / 321 / 122 contra 432 / 497 / 457 / 445 do v1 (51% somados): **menos terra**
  que o v1 e o v2; enseadas e falésias comem a borda. Faixa provisória no teste: um quarto por ilha, 45% somado.
- Entreposto: acha costa em toda principal das sementes de referência.
- Geração: o arquipélago da semente 1840 passou de 787 ms (v1) para 2.637 ms em série e 1.247 ms em threads (pior
  quadro 17 ms, atrás da cortina); a ilha principal sozinha: v1 345, v2 869, v3 996 ms. Quadro igual (`docs/benchmark.md`).
- Rios: no v3 o rio também corre pela planície de cima da falésia, e numa ilha pequena aceita ser mais curto (1/6 da
  ilha, até 20 células).

## Como testar

- `tests/sim/test_phase52_terrain_v3.gd`: determinístico e independente da ordem; alongado, com enseadas e rochedos;
  praia e falésia na costa; lotes, jazidas e entreposto; save e load na versão 3; plataforma desenhada rasa junto à
  costa e funda na borda; custo de geração; a opção no jogo novo.
- `tests/sim/test_terrain_golden.gd`: assinaturas do v3 gravadas (o v1 e o v2 não mudaram).
- Capturas: `tools/capture_phase52.tscn` (cartas de seis sementes, o arquipélago, a principal, uma enseada e uma
  falésia de perto).

## Fica de fora (proposta à espera do dono)

- **Fase 53, a parte gráfica**: grama verde saturada e mata variada, areia clara de praia, rocha escura nas falésias e
  rochedos (hoje a falésia mostra a escada da grade de 2 m), água turquesa mais viva com espuma na arrebentação, menos
  névoa de longe.
- Rios compridos serpenteando até uma enseada; a disposição das ilhas em grupos com canais (hoje uma por região).
- A faixa de terra construível (o v3 tem cerca de metade dos lotes do v1) e se o v3 fica como padrão.
