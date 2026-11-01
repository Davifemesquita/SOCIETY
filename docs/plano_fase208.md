# Plano da Fase 208 — Rama de tecido

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_205_209.md` (estandarte, bebedouro e lanterna, a partir
das capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`TenterView.sites`, `cells`): em três células em fila encostadas no meio de um lado de cada tecelagem (o de trás
  primeiro, depois o de −X e o de +X da frente; o primeiro em que as três são de terra, livres, fora do largo e da alameda, e
  quase planas), como o pátio de tijolos da olaria da Fase 159.
- **As ramas** (`tenter_mesh`): duas ramas de madeira paralelas, de comprido ao longo da parede, com os esteios, a travessa de
  cima e a de baixo, o pano tingido esticado entre elas (vermelho de garança e azul de anil), a ourela mais escura, as emendas
  entre as peças de pano, uma faixa mais clara no meio de cada uma e os ganchos no alto. Um MultiMesh, sem descarte de face.
- O recheio e as bombas d'água deixam as células (`ScatterView.island_context`, `WaterPumpView.taken_cells`).

## Como testar

- `tests/world/test_phase208_tenters.gd`: as três células ficam encostadas no lado de trás da tecelagem; com uma bloqueada, a fila
  vai para outro lado; outros prédios não têm; o recheio deixa as células; a rama cabe na fila.
- Captura: `ramas_de_tecido.png` e `ramas_de_longe.png` no `tools/capture_phase95.tscn` (a tecelagem na rua dos prédios grandes).
