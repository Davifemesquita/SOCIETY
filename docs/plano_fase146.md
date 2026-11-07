# Plano da Fase 146 — Grade e lampiões no cais

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_145_149.md` (relógio, cais e cata-vento, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A grade** (`QuayRailView.rails`, `_rail`): ao longo da beira de cada lanço do cais de pedra da Fase 106
  (`HarborView.stone_quay`), `RAIL_IN_M` para dentro, no alto do capeamento: os balaústres de ferro a cada `POST_STEP_M`, o
  corrimão a `RAIL_M` e a travessa embaixo. Fica aberta nos lanços dos cabeços (o resto 1 de
  `HarborView.SEA_WALL_BOLLARD_EVERY`, por onde se amarra) e nos da frente do entreposto (o cais de tábuas, onde os barcos
  encostam: `_in_front`). Uma malha só para o arquipélago.
- **Os lampiões** (`lamps`): num lanço a cada `LAMP_EVERY` (no resto `LAMP_REST`, nunca o dos cabeços), fora da frente do
  prédio, `LAMP_IN_M` para dentro da beira, o poste de ferro fundido dos postes da rua (`LampView.post_mesh`) com o vidro
  aceso à noite (`LampView.glass_mesh`). Dois MultiMesh com a caixa fixa do arquipélago (`GameScreen.quay_rail_view`);
  tudo refeito na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase146_quay_rails.gd`: cada trecho da grade casa com um lanço que não é de cabeço, para dentro da
  beira e no alto do capeamento, do comprimento do lanço; os lampiões ficam nos lanços do resto certo, fora dos cabeços; a
  ilha plana não tem.
- Captura: `tools/capture_phase146.tscn` (semente 1840: um entreposto na costa da ilha principal; `cais_grade.png` de dia
  e `cais_de_noite.png`).
