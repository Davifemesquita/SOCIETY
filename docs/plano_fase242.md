# Plano da Fase 242 — Tabaco secando

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_240_244.md` (lagar, terreiro e estacas, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`TobaccoRackView.sites`): em cada plantação de tabaco, nas duas células do meio de um lado pelo `SideYard` — o de −X do
  modelo, depois o de trás e por fim o de +X —, guardado pelo `SideYard.remember`. O recheio e as bombas deixam as células limpas.
- **O varal** (`rack_mesh`): dois cavaletes de dois esteios com a travessa e a escora nas pontas e três varas compridas por cima,
  com as réstias de folhas de tabaco penduradas (`STRINGS` por vara, `LEAVES` folhas por réstia, cada folha uma lâmina fina girada
  um pouco) — a vara da frente ainda verde-amarela, a do meio dourada e a de trás já curada, castanha —, e o cesto de folhas no
  chão. Um MultiMesh, as folhas vistas dos dois lados.

## Como testar

- `tests/world/test_phase242_tobacco_racks.gd`: em cada rotação o varal fica num lado da plantação (nunca na frente), encostado
  nela; com uma célula bloqueada ele muda de lado; o vinhedo não tem; o recheio e as bombas deixam as células; o varal cabe nas
  duas células.
- Captura: `tools/capture_phase242.tscn` (a ilha plana; `tabaco_de_perto.png`, `tabaco_e_predio.png`, `tabaco_de_longe.png`).
