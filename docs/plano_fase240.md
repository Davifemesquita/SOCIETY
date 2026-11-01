# Plano da Fase 240 — Lagar no vinhedo

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_240_244.md` (lagar, terreiro e estacas, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WinePressView.sites`): em cada vinhedo, nas duas células do meio de um lado pelo `SideYard` — o de +X do modelo,
  depois o de trás e por fim o de −X (as colmeias da Fase 190 preferem o −X e o silo da Fase 117 fica atrás) —, fora das células
  das colmeias e do silo; guardado pelo `SideYard.remember`. O recheio e as bombas deixam as células limpas.
- **O lagar** (`press_mesh`): a tina larga de pisar uvas, de aduelas com os dois arcos de ferro, cheia de mosto roxo com uns
  cachos boiando; a prensa de fuso — o estrado, o cesto de ripas com o mosto, o bloco de apertar, os dois esteios com a trave, o
  fuso de ferro e a barra de girar —; e dois cestos de vime com as uvas na frente. Um MultiMesh.

## Como testar

- `tests/world/test_phase240_wine_press.gd`: em cada rotação o lagar fica num lado do vinhedo (nunca na frente), encostado nele e
  fora das colmeias e do silo; com uma célula bloqueada ele muda de lado; a fazenda de lúpulo não tem; o recheio e as bombas deixam
  as células; o lagar cabe nas duas células.
- Captura: `tools/capture_phase240.tscn` (a ilha plana; `lagar_de_perto.png`, `lagar_e_vinhedo.png`, `lagar_de_longe.png`).
