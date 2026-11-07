# Plano da Fase 251 — Cabras nas encostas

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_250_254.md` (balança, cabra e canoa, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`GoatView.herds`, `_slope`): numa rede de pontos de `HERD_STEP` células das ilhas temperadas com relevo, a célula de
  encosta livre (terra sem árvore, prédio, estrada nem trilho, com desnível de `MIN_RELIEF_M` ou mais entre os cantos, pelo
  `ScatterView.cell_relief`) mais perto do ponto e sem prédio perto, pelos blocos de `SealView.WILD_CELLS` das focas da Fase 189
  (longe das vilas), com a chance `HERD_CHANCE`.
- **As cabras** (`goats`, `body_mesh`, `head_mesh`, `rock_mesh`, `head_pitch`): de duas a quatro por grupo, cada uma virada pelo
  hash, a primeira de pé numa pedra de `ROCK_M` de alto; o corpo claro com as manchas castanhas, as pernas com os cascos e o rabo
  curto, e a cabeça com os chifres para trás, as orelhas e a barbicha, que pasta baixada quase sempre e se ergue de tempos em
  tempos, cada uma no seu ritmo, no tempo de jogo. Três MultiMesh; refeito também na derrubada de árvores.

## Como testar

- `tests/world/test_phase251_goats.gd`: na semente 1840, os grupos ficam em encosta livre, com duas a quatro cabras e uma na pedra
  (na altura dela) cada; uma casa perto tira o grupo dali; as tropicais e a ilha plana não têm; a cabeça pasta baixada na maior parte
  do tempo; o alto da pedra é onde a cabra fica.
- Captura: `tools/capture_phase251.tscn` (a semente 1840; `cabras_N.png`, `cabras_N_alerta.png`, `cabras_N_longe.png`).
