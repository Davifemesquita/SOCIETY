# Plano da Fase 237 — Marco de légua

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_235_239.md` (cervo, âncora e marco, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`MilestoneView.stones`, `_straight_axis`): nas estradas de terra das ilhas com relevo, na célula do desenho da grade
  `posmod(7x + 13y, STONE_EVERY)` = 0 (numa estrada reta, um marco a cada `STONE_EVERY` células), só no meio de um trecho reto de
  `RUN_CELLS` células para cada lado (a estrada comprida, nunca no cruzamento nem na curva), fora das vilas (sem casa a até
  `SignpostView.TOWN_CELLS`, a regra das placas da Fase 187) e fora das células dos postes de fio (Fase 120); na beira da célula,
  `OFFSET_M` para o lado em que a vizinha é terra livre (um lado ou o outro pelo hash), com a face para a estrada e uma pontinha
  de inclinação pelo hash.
- **O marco** (`stone_mesh`): a laje de pedra clara de topo redondo, enterrada no pé, com o painel rebaixado e os três riscos da
  inscrição (sem texto) e a faixa de musgo no pé. Um MultiMesh; refeito quando as estradas mudam, na obra e na demolição.

## Como testar

- `tests/world/test_phase237_milestones.gd`: na estrada reta e comprida, os marcos ficam nas células do desenho, na beira, com a
  face para a estrada, no máximo um a cada `STONE_EVERY` células; nada no paralelepípedo, perto de casa, no cruzamento nem na ilha
  plana; o marco é mais alto que largo, de topo redondo e enterrado no pé.
- Captura: `tools/capture_phase237.tscn` (a semente 1840, com estradas retas onde o relevo deixa; `marco_N.png` e
  `marco_N_longe.png`).
