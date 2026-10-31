# Plano da Fase 141 — Árvore seca

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_140_144.md` (toco, bote e boia, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView.Kind.SNAG`, no fim do enum): no recheio, uma peça nova no fim das listas `NEAR_FOREST` (a beira da
  mata, `SNAG_FOREST_CHANCE`) e `NEAR_SEA` (a costa, `SNAG_COAST_CHANCE`). Vir por último mantém o sorteio das peças de
  antes de cada célula. Só nas ilhas temperadas: na tropical o sorteio acontece e a peça é pulada.
- **A malha** (`snag_mesh`): o tronco nu em três lanços tortos, afinando de `SNAG_HEIGHT_M` até a ponta quebrada, e cinco
  galhos subindo abertos para os lados, cada um com um ramo; madeira velha, cinzenta (`SNAG_WOOD`), mais escura no pé
  (`SNAG_DARK`). No meio da célula, com sombra, sem balançar (não é planta).

## Como testar

- `tests/world/test_phase141_snags.gd`: a árvore seca é a última regra da beira da mata e da costa e o último tipo; aparece
  nas ilhas temperadas e nunca nas tropicais; a malha é alta, assenta no chão e só tem as cores da madeira.
- Captura: `tools/capture_phase141.tscn` (semente 1840: as árvores secas mais perto do meio da ilha principal, na beira da
  mata e na costa; `arvore_seca_<n>.png`).
