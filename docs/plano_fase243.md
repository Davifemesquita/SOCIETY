# Plano da Fase 243 — Vigas de aço empilhadas

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_240_244.md` (lagar, terreiro e estacas, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SteelBeamView.sites`): em cada fábrica de vigas de aço, nas duas células do meio de um lado pelo `SideYard` — o de −X do
  modelo, depois o de trás e por fim o de +X (a boca do forno da Fase 137 fica no +X) —, fora da célula do carrinho de mão da Fase
  172; guardado pelo `SideYard.remember`. O recheio e as bombas deixam as células limpas.
- **A pilha** (`pile_mesh`, `_beam`): as vigas de ferro em I (a aba de baixo, a alma e a aba de cima) ao longo da parede, em três
  camadas sobre os dormentes de madeira atravessados, a de cima mais curta, umas enferrujadas, e uma viga solta deitada no chão na
  frente. Um MultiMesh.

## Como testar

- `tests/world/test_phase243_steel_beams.gd`: em cada rotação a pilha fica num lado da fábrica (nunca na frente), encostada nela;
  com uma célula bloqueada ela muda de lado; o vinhedo não tem; o recheio e as bombas deixam as células; a pilha cabe nas duas
  células.
- Captura: `tools/capture_phase243.tscn` (a ilha plana; `vigas_de_perto.png`, `vigas_e_predio.png`, `vigas_de_longe.png`).
