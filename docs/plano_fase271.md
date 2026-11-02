# Plano da Fase 271 — Dedaleiras

**Estado: feita em 02/11/2026**, segunda do roteiro `docs/plano_fases_270_274.md` (corvo, dedaleira e nenúfar).

## O que entrou

- **`ScatterView.Kind.FOXGLOVE`** (no fim do enum, no fim da lista `NEAR_FOREST` e entre as `PLANTS`, que balançam ao vento; sem
  sombra): com a chance `FOXGLOVE_CHANCE` (0,06) por célula da beira da mata, só nas temperadas. `foxglove_mesh`: a roseta de folhas
  largas, cinco hastes de 1 a 1,6 m um pouco tortas e, do meio para cima de cada uma, os sinos pendentes roxos (uns rosados), maiores
  embaixo. A primeira versão, de três hastes de 1,2 m, sumia na mata.

## Como testar

- `tests/world/test_phase271_foxgloves.gd`: a regra no fim da lista da beira da mata e no fim do enum, entre as plantas; só nas
  temperadas, de pé; a touceira alta com os sinos roxos só do meio para cima. Na semente 1840 de teste, 29.
- Captura: `tools/capture_phase271.tscn -- <pasta>`.
