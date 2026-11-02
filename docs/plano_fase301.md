# Plano da Fase 301 — Chão de vila

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_300_304.md`. No Society, as casas das temperadas assentavam
direto no gramado. No Anno, o chão entre as casas é terra pisada.

## O que entrou

- **`RoadMask.yards`**: devolve também as casas das ilhas temperadas, com o lote crescido de `TOWN_YARD_REACH_M` (2,2 m). Antes
  devolvia só as das tropicais (o terreiro da Fase 111).
- **No desenho da máscara**: na ilha temperada (`_town`), o carimbo é o do pátio das fábricas da Fase 165, com a borda recortada
  por `TOWN_YARD_RAGGED_M` de ruído e a força em `TOWN_YARD_STRENGTH` (0,85) da do terreiro tropical. `_stamp_yard` ganhou o
  parâmetro da força.
- **`GrassCarpetView.grows_at`**: o tapete de capim da Fase 286 não cresce mais em célula colada num prédio. Os tufos
  escondiam o chão batido e o pátio das fábricas; com a primeira versão (1,3 m) e o tapete, nada mudava na captura.
- **Mudança registrada**: o teste da Fase 111 dizia "as ilhas temperadas não têm terreiro". Agora confere o chão de vila delas.

## Medida

GPU 12,5 ms (300: 12,6). Neutra.

## Como testar

- `tests/world/test_phase301_town_ground.gd`:
  - o chão batido no meio do lote, mais fraco que o tropical;
  - a borda recortada;
  - nada longe da casa.
- `tests/world/test_phase111_tropical_yards.gd`: o chão de vila nas temperadas, com `TOWN_YARD_REACH_M`.
- Captura: `tools/capture_phase300.tscn -- <pasta>`; o recorte das casas está em
  `F:\ferramentas\capturas\fase301\antes_depois_casas.png`.
