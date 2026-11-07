# Plano da Fase 186 — Estacas na água

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_185_189.md` (hera, estaca e arco-íris, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`MooringPileView.spots`): diante de cada entreposto, dos dois lados de onde o navio encosta e um mais para fora
  (`POST_SPOTS`), e na ponta de cada píer (`PIER_SPOTS`), pelo mesmo rumo do mar das boias da Fase 144 (`HarborView.seaward`),
  só onde a água é funda o bastante (`HarborView.afloat`); cada feixe girado pelo lugar.
- **O feixe** (`cluster_mesh`): cinco estacas de alturas diferentes, as de fora puxadas para o meio no alto, cravadas da água
  funda (`FOOT_M`) até acima dela, com o limo escuro até um pouco acima da água e duas voltas de cabo amarrando o feixe. Um
  MultiMesh (`GameScreen.mooring_pile_view`), refeito na obra, na demolição e ao trocar de mundo.

## Riscos

- Com o pé a 2,5 m dentro da água, a espuma por profundidade do shader da água desenhava a parte submersa como uma coluna
  branca: o pé ficou a meio metro (sobra uma espuminha em volta, como a de verdade).

## Como testar

- `tests/world/test_phase186_mooring_piles.gd`: os feixes na água, do lado do mar do entreposto; nada nos outros prédios; o
  feixe sai da água e tem o pé dentro dela.
- Captura: `tools/capture_phase186.tscn` (o entreposto da ilha principal da semente 1840).
