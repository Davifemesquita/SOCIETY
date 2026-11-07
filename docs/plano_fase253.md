# Plano da Fase 253 — Cestos de batata

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_250_254.md` (balança, cabra e canoa, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`PotatoBasketView.sites`): em cada fazenda de batata, nas duas células do meio de um lado pelo `SideYard` — o de +X do
  modelo, depois o de trás e por fim o de −X (as colmeias da Fase 190 preferem o −X e o silo da Fase 117 fica atrás) —, fora das
  células das colmeias e do silo; guardado pelo `SideYard.remember`. O recheio e as bombas deixam as células limpas.
- **Os cestos** (`basket_mesh`, `_basket`, `_potato`): três cestos de vime afunilados encostados na parede, cada um com o monte baixo
  e as batatas soltas por cima, um quarto tombado com as batatas rolando para o chão, dois sacos cheios e o forcado de três dentes
  encostado. Um MultiMesh. (Com o monte liso por cima e o vime escuro, os cestos pareciam bolinhos.)

## Como testar

- `tests/world/test_phase253_potato_baskets.gd`: em cada rotação os cestos ficam num lado da fazenda (nunca na frente), encostados
  nela e fora das colmeias e do silo; com uma célula bloqueada eles mudam de lado; o vinhedo não tem; o recheio e as bombas deixam
  as células; os cestos cabem nas duas células.
- Captura: `tools/capture_phase253.tscn` (a ilha plana; `batata_de_perto.png`, `batata_e_predio.png`, `batata_de_longe.png`).
