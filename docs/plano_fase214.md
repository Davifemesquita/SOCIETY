# Plano da Fase 214 — Escada de mão

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_210_214.md` (pombo, mó e buxo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`LadderView.spot`, `_cell`, `cells`): numa casa a cada `LADDER_EVERY` pelo id (resto `LADDER_REST`), de telhado de duas
  águas sem a ala da Fase 96, encostada na parede de −X do corpo, na metade de trás (`BACK_M`): a de +X tem a lenha da Fase 171, e
  a casinha do cão da Fase 197 fica no mesmo lado, mas na frente. Só com a célula do lado livre (só pelo lote, para o recheio e as
  bombas a deixarem).
- **A escada** (`ladder_mesh`): os dois banzos de madeira inclinados contra a parede, o pé a `FOOT_OUT_M` dela, os degraus a cada
  `RUNG_STEP_M` e o balde de lata com a alça ao lado do pé; esticada em y até o beiral da casa. Um MultiMesh.

## Como testar

- `tests/world/test_phase214_ladders.gd`: só as casas do resto certo têm a escada, na parede de −X do corpo, na metade de trás, com
  o alto no beiral e encostado na parede e o pé para fora; o recheio e as bombas deixam a célula; com estrada na célula não há.
- Captura: `escada_de_mao.png` no `tools/capture_phase95.tscn` (câmera à mão).
