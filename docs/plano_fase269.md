# Plano da Fase 269 — Cruzeiro no morro

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_265_269.md` (garça, ruína e cruzeiro).

## O que entrou

- **`SummitCrossView`** (`GameScreen.summit_cross_view`): em cada ilha temperada com relevo, a célula de terra livre (sem árvore,
  prédio, estrada nem trilho) e quase plana (`MAX_RELIEF_M`) mais alta, procurada a cada `SEARCH_STEP` células, acima de
  `MIN_HEIGHT_M` (ilha sem morro fica sem) (`summit`); o cruzeiro no chão mais baixo da célula, virado para o meio da ilha
  (`place_of`). `cross_mesh`: o degrau largo, o pedestal em dois socos, o fuste afinando e a cruz de braços com as pontas
  alargadas, em pedra clara, e o musgo no pé. Um por ilha; na semente 1840 são 4.

## Como testar

- `tests/world/test_phase269_summit_crosses.gd`: o cruzeiro na célula livre e quase plana mais alta da ilha, acima da altura mínima,
  virado para o meio; nada nas tropicais nem na ilha plana; a cruz de pé no degrau.
- Captura: `tools/capture_phase269.tscn -- <pasta>` (cada cruzeiro de frente, de lado e de longe).
