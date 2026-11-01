# Plano da Fase 235 — Cervos na beira da mata

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_235_239.md` (cervo, âncora e marco, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`DeerView.herds`, `_meadow`): numa rede de pontos de `HERD_STEP` células das ilhas temperadas com relevo, a célula de
  capim livre (sem árvore, prédio, estrada nem trilho, quase plana, acima da praia) mais perto do ponto que tenha mata a até
  `EDGE_CELLS` e nenhum prédio perto, pelos blocos de `SealView.WILD_CELLS` das focas da Fase 189 (longe das vilas), com a chance
  `HERD_CHANCE`.
- **Os cervos** (`deer`, `body_mesh`, `head_mesh`, `stag_mesh`): de dois a quatro por grupo em volta da célula, cada um virado pelo
  hash, o primeiro um veado de galhada; o corpo de pé com a anca clara, o rabo curto e as pernas finas com os cascos, e a cabeça
  com o pescoço comprido, as orelhas e o focinho escuro. A cabeça pasta baixada (`GRAZE_RAD`) quase sempre e se ergue de tempos em
  tempos, cada um no seu ritmo (`head_pitch`), no tempo de jogo. Três MultiMesh; refeito também na derrubada de árvores.

## Como testar

- `tests/world/test_phase235_deer.gd`: na semente 1840, os grupos ficam em capim livre na beira da mata, com dois a quatro cervos e
  um veado cada; uma casa perto tira o grupo dali; as tropicais e a ilha plana não têm; a cabeça pasta baixada na maior parte do
  tempo.
- Captura: `tools/capture_phase235.tscn` (a semente 1840; `cervos_N.png`, `cervos_N_alerta.png`, `cervos_N_longe.png`).
