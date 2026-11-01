# Plano da Fase 231 — Cormorões nas estacas

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_230_234.md` (sinal, cormorão e castanha, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`CormorantView.perches`): no alto da estaca do meio (a mais alta, `MooringPileView.TOPS_M[0]`) de um a cada
  `PERCH_EVERY` feixes de atracação da Fase 186, na ordem deles (o primeiro sempre: pelo hash do lugar, o cais da semente 1840
  ficava sem nenhum), assentado `SIT_M`, virado pelo lugar.
- **O cormorão** (`cormorant_mesh`): de pé com as asas abertas secando ao sol — o corpo escuro inclinado, a cauda dura apoiada para
  trás, o pescoço em S até a cabeça com a garganta clara e o bico de gancho, e as duas asas largas abertas para os lados com a borda
  de trás em dentes —, desenhado `SCALE` vezes maior, num material sem descarte de face. Um MultiMesh sem sombra; some à
  noite.

## Como testar

- `tests/world/test_phase231_cormorants.gd`: na semente 1840, o entreposto com feixes tem pelo menos um cormorão e nunca mais
  cormorões que feixes, cada um no alto de um feixe; outros prédios não têm; as asas abertas fazem o cormorão mais largo que alto.
- Captura: `tools/capture_phase231.tscn` (o entreposto da semente 1840; `cormorao_0_de_um_lado.png`, `cormorao_0_do_outro.png`,
  `cormoroes_longe.png`).
