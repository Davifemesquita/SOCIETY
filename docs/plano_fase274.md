# Plano da Fase 274 — Girassóis

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_270_274.md`. O roteiro previa os nenúfares no rio; feitos e
fotografados, eles sumiam: os rios da semente 1840 são gargantas estreitas, e a água neles fica coberta da espuma da beira (a
espuma vai até `shore_foam_width_m` da terra). A fase virou os girassóis junto das casas, e o código dos nenúfares saiu.

## O que entrou

- **`ScatterView.Kind.SUNFLOWER`** (no fim do enum, no fim da lista `NEAR_HOUSE`, encostado na parede da casa como as outras peças
  dela, e entre as `PLANTS`, que balançam ao vento; sem sombra): com a chance `SUNFLOWER_CHANCE` (0,2) por célula junto de casa,
  só nas temperadas. `sunflower_mesh`: quatro hastes de 1,45 a 1,9 m com as folhas largas em pares e, no alto de cada uma, a flor
  virada para o mesmo lado e um pouco para baixo: o disco escuro redondo do miolo e catorze pétalas amarelas. A primeira versão,
  de miolo quadrado e pétalas finas, parecia um sol de desenho.

## Como testar

- `tests/world/test_phase274_sunflowers.gd`: a regra no fim da lista junto das casas e no fim do enum, entre as plantas; encostado
  numa casa das temperadas, de pé, nunca nas tropicais; a touceira alta com as pétalas amarelas só no alto.
- Captura: `tools/capture_phase274.tscn -- <pasta>` (a vila do ciclo da cor; os girassóis mais perto do meio dela).
