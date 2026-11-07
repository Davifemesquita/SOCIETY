# Plano da Fase 106 — Cais de pedra

**Estado: feita em 29/10/2026**, segunda do roteiro `docs/plano_fases_105_109.md` (cidade e porto, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save; os navios encostam onde já encostavam.

## O que entrou

- **O cais** (`HarborView.stone_quay`, `_quay_segment`): dos dois lados do entreposto, ao longo da costa, lanços retos de
  `STONE_QUAY_STEP_M` até `STONE_QUAY_REACH_M` além do prédio. Cada lanço é uma plataforma de cantaria da beira (a mesma
  linha do cais de tábuas, `QUAY_DEPTH_M` para o mar) até `STONE_QUAY_BACK_M` para dentro, do fundo (`SEA_WALL_BOTTOM_M`)
  até `STONE_QUAY_BELOW_DECK_M` abaixo das tábuas; a parte enterrada some no chão. Capeamento na beira e um cabeço a cada
  `SEA_WALL_BOLLARD_EVERY` lanços. Um lado para no primeiro lanço em que a terra atrás sobe mais que `STONE_QUAY_RISE_M`
  acima do cais (falésia ou morro). A pedra é a das paredes (`BuildingMaterials`, camada de pedra, projetada pelo mundo).
- Só no entreposto e só na ilha com relevo (na plana a costa é a borda da grade).

## No caminho

- A primeira versão punha um bloco em cada divisa de célula de terra com o mar. Como a linha d'água desenhada é curva
  (Fases 54 e 55) e a das células é em escada, o muro saía em zigue-zague, meio na água e meio na areia. O cais passou a
  seguir a frente do entreposto, em linha reta.
- A base dos lanços estava espelhada (determinante negativo) e as faces saíam invertidas, como lâminas ocas.

## Como testar

- `tests/world/test_phase106_stone_quay.gd`: todos os lanços na mesma linha da frente do cais de tábuas, virados para o mar
  e um pouco abaixo das tábuas, nunca com terra alta atrás; o número de lanços tem teto; nada na ilha plana.
- Captura: `CAPTURA_SO=porto` no `tools/capture_phase5.tscn` (`12_porto.png`, `14_cais.png`).
