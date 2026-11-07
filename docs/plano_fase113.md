# Plano da Fase 113 — Alameda

**Estado: feita em 30/10/2026**, quarta do roteiro `docs/plano_fases_110_114.md` (sol, trópico e avenida, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save; as células da alameda continuam livres.

## O que entrou

- **Onde** (`AvenueView.cells`): para cada célula de paralelepípedo da vez (`posmod(x + y, AVENUE_EVERY) = 0`, pelo desenho
  da grade, sem sorteio), as células livres dos quatro lados dela (terra sem prédio, estrada, trilho nem árvore, e quase
  plana no relevo). As pontas da avenida também ganham, na linha da rua. A busca só anda nas células calçadas (o `find` do
  array), não na ilha inteira, porque roda a cada obra.
- **A árvore**: a faia da Fase 22 reduzida a `TREE_SCALE`, no meio da célula, girada pelo hash, com o material da folhagem
  (balança com o vento) e sombra; um MultiMesh só, com a caixa do arquipélago.
- **O recheio** deixa essas células limpas (`ScatterView.island_context`, como o largo da Fase 109).

## No caminho

- Com a caixa do arquipélago no MultiMesh, o alcance de visibilidade é contado do meio do arquipélago e as árvores sumiam
  (a mesma armadilha das leiras da Fase 19); o alcance saiu.
- Na ilha plana as camadas de chão, trilho e árvores vêm vazias: a leitura passou a tolerar isso.

## Como testar

- `tests/world/test_phase113_avenue.gd`: a rua calçada ganha árvores dos dois lados, todas encostadas numa célula calçada
  da vez e fora da rua; a de terra não; uma casa toma o lugar das árvores; a vista acompanha a estrada.
- Captura: `tools/capture_phase113.tscn` (semente 1840: uma avenida calçada num descampado, com casas de um lado;
  `alameda.png`, `alameda_de_perto.png`, `alameda_de_cima.png`).
