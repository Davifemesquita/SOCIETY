# Plano da Fase 244 — Estacas de lúpulo

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_240_244.md` (lagar, terreiro e estacas, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`HopPoleView.sites`): em cada fazenda de lúpulo, nas duas células do meio de um lado pelo `SideYard` — o de +X do modelo,
  depois o de trás e por fim o de −X (as colmeias da Fase 190 preferem o −X e o silo da Fase 117 fica atrás) —, fora das células
  das colmeias e do silo; guardado pelo `SideYard.remember`. O recheio e as bombas deixam as células limpas.
- **Os feixes** (`pole_mesh`): dois cavaletes em X com as estacas compridas (`POLE_M`) deitadas por cima em duas camadas, umas mais
  finas, outras mais grossas, cada uma num tom, e um feixe amarrado com duas voltas de barbante de pé, encostado na parede no canto.
  Um MultiMesh.

## Como testar

- `tests/world/test_phase244_hop_poles.gd`: em cada rotação os feixes ficam num lado da fazenda (nunca na frente), encostados nela
  e fora das colmeias e do silo; com uma célula bloqueada eles mudam de lado; a fazenda de batata não tem; o recheio e as bombas
  deixam as células; os feixes cabem nas duas células (o de pé passa da altura dos outros pátios, abaixo do comprimento da
  estaca).
- Captura: `tools/capture_phase244.tscn` (a ilha plana; `estacas_de_perto.png`, `estacas_e_predio.png`, `estacas_de_longe.png`).
