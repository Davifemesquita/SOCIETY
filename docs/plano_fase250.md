# Plano da Fase 250 — Balança de carga no armazém

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_250_254.md` (balança, cabra e canoa, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScaleView.sites`): em cada armazém, nas duas células do meio de um lado pelo `SideYard` — o de −X do modelo, depois o de
  trás e por fim o de +X (a plataforma de carga da Fase 23 fica na frente) —, guardado pelo `SideYard.remember`. O recheio e as
  bombas deixam as células limpas.
- **A balança** (`scale_mesh`, `_sack`): a balança decimal de plataforma — o chassi pintado de verde com as quatro rodinhas, o
  estrado de tábuas, a coluna de trás com o travessão, o fiel de latão e o prato dos pesos pendurado com os pesos empilhados —, um
  saco deitado em cima dela, três sacos de pé, amarrados, esperando ao lado e os pesos soltos no chão. Um MultiMesh.

## Como testar

- `tests/world/test_phase250_scales.gd`: em cada rotação a balança fica num lado do armazém (nunca na frente), encostada nele; com
  uma célula bloqueada ela muda de lado; o vinhedo não tem; o recheio e as bombas deixam as células; a balança cabe nas duas
  células.
- Captura: `tools/capture_phase250.tscn` (a ilha plana; `balanca_de_perto.png`, `balanca_e_predio.png`, `balanca_de_longe.png`).
