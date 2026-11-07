# Plano da Fase 239 — Algas na praia

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_235_239.md` (cervo, âncora e marco, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView`, `Kind.SEAWEED`): a peça nova do recheio vem no fim do enum e no fim da lista `NEAR_SEA` (o sorteio das
  peças de antes não muda), com a chance `SEAWEED_CHANCE`, só nas células baixas e planas da costa (até `SEAWEED_MAX_HEIGHT_M` de
  altura e `SEAWEED_MAX_RELIEF_M` de desnível: a areia da praia onde a maré chega), nas temperadas e nas tropicais, deitada no plano
  da célula e um pouco afundada na areia.
- **As algas** (`seaweed_mesh`): o monte chato de sargaço molhado em três bolos (o escuro, o marrom e o verde) e cinco fitas
  espalhadas em volta, cada uma em dois lances tortos rente ao chão; o tom de cada monte pela instância. Sem sombra (é rente ao
  chão) e sem balanço (não é planta em pé).

## Como testar

- `tests/world/test_phase239_seaweed.gd`: a peça é a última da lista da costa e do enum, fora das plantas e das sombras; aparece
  nas ilhas da semente 1840, só nas células baixas e planas junto do mar, deitada; a malha é chata e larga.
- Captura: `tools/capture_phase239.tscn` (a semente 1840; `algas_de_perto.png`, `algas.png`, `algas_do_outro_lado.png`).
