# Plano da Fase 148 — Cavalete do lenhador

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_145_149.md` (relógio, cais e cata-vento, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`LumberYardView.cell_of`, `cells`): na célula encostada no meio de um lado de cada lenhador — o de +X da frente,
  o oposto ou o de trás (nunca a frente, a porta e a rua) —, a primeira de terra, sem prédio, estrada nem trilho e com até
  `MAX_RELIEF_M` de desnível. A mata pode estar nela: a clareira da Fase 140 (`StumpView.cut_cells_of`) corta a célula
  inteira, e a `StumpView` não põe toco nem tora ali. O recheio deixa a célula limpa.
- **A mata acompanha** (`TreeView._recut`, `_recut_now`): o corte da ilha é refeito também quando uma estrada ou uma
  derrubada de árvores muda o lugar do terreiro (só nas ilhas com lenhador), não só quando um lenhador entra ou sai; o
  recálculo fica para o quadro seguinte, juntando os pedidos (a montagem de uma cidade manda centenas de estradas no mesmo
  quadro: refeito a cada uma, montar a cidade do benchmark subia 0,35 s). A `StumpView` também refaz a ilha na estrada.
- **O terreiro** (`yard_mesh`), virado para o lenhador: o cavalete de serrar em xis com uma tora atravessada, o cepo com o
  machado cravado, a pilha de lenha rachada em três fiadas e as lascas no chão. Uma malha só para o arquipélago
  (`GameScreen.lumber_yard_view`), refeita na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

## Como testar

- `tests/world/test_phase148_lumber_yard.gd`: cada lenhador ganha uma célula encostada, olhando para ele e nunca na frente,
  nas quatro rotações; uma estrada nela a muda de lugar; outros prédios não têm; com mata na célula, a clareira a corta e a
  `StumpView` não põe toco nela. O teste da clareira (Fase 140) desconta a célula do terreiro.
- Captura: `tools/capture_phase148.tscn` (semente 1840: um lenhador na beira da mata; `terreiro.png` e
  `terreiro_de_perto.png`).
