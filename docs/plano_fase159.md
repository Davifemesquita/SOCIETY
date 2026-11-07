# Plano da Fase 159 — Tijolos secando

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_155_159.md` (carneirinho, papoula e colheita, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BrickYardView.sites`, `cells`): três células em fila ao longo da parede, encostadas no meio de um lado de cada
  olaria — o de −X da frente, o de trás ou, por último, o de +X, que é o da boca do forno da Fase 137 —, o primeiro em que as
  três são de terra, livres (sem prédio, estrada, trilho nem árvore, fora do largo e da alameda) e quase planas. O recheio, os
  silos e as bombas d'água deixam as células limpas.
- **O pátio** (`yard_mesh`): duas fileiras de tijolos crus secando, em grade (as fiadas alternando de través, com o vão entre
  os tijolos, e ao comprido nas duas beiras), a de dentro mais seca e mais clara, com duas tábuas estreitas em telhado na
  cumeeira; na ponta, o monte de barro escavado em anéis, baixo e torto. Uma malha só para o arquipélago, refeita na obra, na
  demolição, na estrada, no trilho e ao trocar de mundo.

## No caminho

- A primeira versão punha o pátio no mesmo lado da boca do forno, bem na frente dela: o lado de +X ficou por último.
- As fileiras baixas com tábuas largas pareciam tábuas no chão de longe: ficaram mais altas, com as tábuas estreitas e o
  tijolo à mostra. O monte em cone virou cúpula em anéis.

## Como testar

- `tests/world/test_phase159_brick_yards.gd`: o pátio fica em três células livres encostadas na olaria; com o lado ocupado
  por uma estrada, vai para outro; nas quatro rotações, nunca no lado da boca do forno quando os outros estão livres; o recheio
  deixa as células limpas; o pátio cabe nas três células e é baixo; uma vista desenha um pátio por olaria.
- Captura: `tools/capture_phase159.tscn` (uma olaria na ilha principal, achada pelo `SiteFinder`, vista do lado do pátio).
