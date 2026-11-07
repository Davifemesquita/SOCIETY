# Plano da Fase 162 — Cascalho nas encostas

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_160_164.md` (cunhal, deriva e horta, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView.Kind.SCREE`, no fim do enum e no fim das listas `OPEN`, `NEAR_FOREST` e `NEAR_SEA`, para o sorteio das
  peças de antes não mudar): na célula de encosta — desnível de `SCREE_MIN_RELIEF_M` ou mais entre os cantos dela
  (`cell_relief`, lido direto das alturas dos cantos) —, `SCREE_CHANCE`, nas temperadas e nas tropicais. O montinho deita no
  plano da encosta (`cell_normal`: a normal do plano que melhor passa pelos quatro cantos) e afunda um pouco.
- **O cascalho** (`scree_mesh`): `SCREE_STONES` pedrinhas angulosas e chatas num disco de `SCREE_RADIUS_M`, mais miúdas para a
  borda, em dois tons de pedra puxados para o castanho da rocha do terreno.

## Como testar

- `tests/world/test_phase162_scree.gd`: a peça entrou no fim das três listas e depois da madeira à deriva; o desnível e a
  normal saem dos cantos (célula plana e rampa de 1 m); o cascalho só aparece em encosta e deitado nela; o montinho é baixo e
  pequeno.
- Captura: `tools/capture_phase162.tscn` (o trecho da ilha principal com mais cascalho, de perto e a meia distância).
