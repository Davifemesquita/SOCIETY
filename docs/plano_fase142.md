# Plano da Fase 142 — Botes no porto

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_140_144.md` (toco, bote e boia, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A roda** (`RowboatView.loop`): diante de cada entreposto, do lado do mar (`HarborView.seaward`), o meio de uma roda de
  água funda a `LOOP_OUT_M` da beira dele e o raio de `LOOP_RADIUS_M`, o primeiro par em que o meio e `LOOP_SAMPLES` pontos
  da roda boiam (`HarborView.afloat`); sem água funda para uma roda inteira, nada.
- **Os botes** (`pose`): `BOATS_PER_POST` botes por entreposto dando voltas devagar (`SPEED_M_S`), um em cada sentido, de
  proa para a frente, com o arranco de cada remada (`SURGE`), subindo e descendo nas ondas e balançando de lado. O casco é o
  bote do cais (`HarborView.boat_mesh`).
- **O remador e os remos** (`rower_pose`, `oar_pose`, `rower_mesh`, `oar_mesh`): o remador sentado de costas para a proa,
  na camisa da instância, inclinando a cada remada; os dois remos presos nos toletes varrendo da proa para a popa com a pá
  n'água e voltando erguidos. Três MultiMesh com a caixa fixa do arquipélago, no tempo de jogo (para na pausa); à noite os
  botes somem (`GameScreen.rowboat_view`); refeitos na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase142_rowboats.gd`: a roda do entreposto boia inteira; os botes ficam na roda, de proa para onde
  andam, um em cada sentido; os remos ficam fora do bote, com a pá abaixo do tolete, e varrem; só o entreposto tem botes.
- Captura: `tools/capture_phase142.tscn` (semente 1840: um entreposto na costa da ilha principal; `botes.png` e
  `bote_de_perto.png`).
