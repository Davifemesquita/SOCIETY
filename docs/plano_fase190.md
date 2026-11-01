# Plano da Fase 190 — Colmeias de palha

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_190_194.md` (colmeia, pombal e varal, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BeehiveView.cells`): ao lado de cada fazenda de `FARMS` (lúpulo, vinhedo e batata), na célula livre e quase plana
  encostada nela mais perto do meio da face de −X da frente — o lado oposto ao das medas da Fase 166 —, fora das outras peças de
  célula (largo, alameda, mesas, silos, medas, hortas, barris e as demais). Só nas ilhas com relevo. O recheio deixa a célula
  limpa (`ScatterView.island_context`).
- **As colmeias** (`hive_mesh`): o banco de tábua sobre quatro pés e três colmeias de palha trançada em sino, em fiadas de dois
  tons, cada uma com a boca escura.
- **As abelhas** (`shaders/bee.gdshader`): `BEES_PER_HIVE` pontinhos escuros por banco, cada um em volta da boca de uma colmeia,
  rodando depressa e sem rumo, saindo e voltando, no tempo visual (param na pausa); escondidas à noite, somem de longe.
- Dois MultiMesh (`GameScreen.beehive_view`), refeitos na obra, na demolição, na estrada e ao trocar de mundo.

## Como testar

- `tests/world/test_phase190_beehives.gd`: as colmeias ao lado da fazenda certa, numa célula livre encostada no lote; nada nas
  outras fazendas nem na ilha plana; o recheio deixa a célula; o banco com as três colmeias.
- Captura: `tools/capture_phase190.tscn` (fazendas na ilha principal da semente 1840, com a câmera posta à mão).
