# Plano da Fase 254 — Canoas na margem do rio

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_250_254.md` (balança, cabra e canoa, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`CanoeView.banks`, `_river_side`): numa rede de pontos de `CANOE_STEP` células das ilhas com relevo, a célula de terra
  livre (sem árvore, prédio, estrada nem trilho), baixa (até `MAX_HEIGHT_M`) e encostada pelo lado num rio mais perto do ponto, sem
  prédio perto, pelos blocos de `SealView.WILD_CELLS` das focas da Fase 189 (longe das vilas), com a chance `CANOE_CHANCE`.
- **A canoa** (`place_of`, `canoe_mesh`): puxada para a margem, `TOWARD_RIVER` da célula para o lado do rio, de comprido ao longo
  dela e deitada com a inclinação do chão; o casco escavado em seções de través (as pontas finas e altas), o banco de través e o
  remo deitado no fundo. Um MultiMesh sem descarte de face (o casco é aberto); refeito também na derrubada de árvores.

## Como testar

- `tests/world/test_phase254_canoes.gd`: na semente 1840, as canoas ficam em terra livre e baixa com o rio do lado, de comprido ao
  longo da margem; uma casa perto tira a canoa dali; a ilha plana não tem; a canoa é comprida e baixa.
- Captura: `tools/capture_phase254.tscn` (a semente 1840; `canoa_N.png`, `canoa_N_de_lado.png`, `canoa_N_longe.png`).
