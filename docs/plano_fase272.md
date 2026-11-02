# Plano da Fase 272 — Anel de cogumelos

**Estado: feita em 02/11/2026**, terceira do roteiro `docs/plano_fases_270_274.md` (corvo, dedaleira e girassol).

## O que entrou

- **`ScatterView.Kind.FAIRY_RING`** (no fim do enum e no fim da lista `OPEN`; sem sombra, parado): com a chance
  `FAIRY_RING_CHANCE` (0,006) por célula de campo aberto, só nas temperadas e no chão de pouco desnível, no meio da célula e deitado no
  plano dela (`cell_normal`). `fairy_ring_mesh`: uma roda de `FAIRY_RING_M` (0,8 m) de raio de dezesseis cogumelos claros de chapéu
  redondo, de tamanhos e tons diferentes, uns em pares, e o disco de capim mais verde por dentro, rente ao chão.

## Como testar

- `tests/world/test_phase272_fairy_rings.gd`: a regra no fim da lista do campo aberto e no fim do enum; só nas temperadas, no chão
  pouco inclinado, deitado no plano da célula; a malha é uma roda baixa. Na semente 1840 de teste, 3 (o capim alto e as papoulas
  tomam muitas células antes).
- Captura: `tools/capture_phase272.tscn -- <pasta>`.
