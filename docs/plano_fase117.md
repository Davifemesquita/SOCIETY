# Plano da Fase 117 — Silos das fazendas

**Estado: feita em 30/10/2026**, terceira do roteiro `docs/plano_fases_115_119.md` (fazenda, taverna e estaleiro, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save; a célula do silo continua livre.

## O que entrou

- **Onde** (`FarmSiloView.cells`): ao lado de cada fazenda de `FARMS` (trigo, batata, lúpulo, ovelha, porco e vinhedo), a
  célula livre e quase plana encostada nela mais perto do meio da face de trás (longe da porta), fora do largo, da alameda e
  das mesas da taverna. Sem célula assim, sem silo.
- **As peças** (`silo_mesh`, `tank_mesh`), geradas no código com a cor no vértice: o silo de aduelas em tons alternados
  sobre um soco de pedra, com `HOOPS` arcos de ferro, a portinhola de cima e o telhado cônico com o remate; ou a caixa
  d'água de madeira sobre quatro pés com escoras em xis, estrado, dois arcos, tampa cônica e a escada de mão. Dois silos
  para cada caixa, pelo resto do id da fazenda (`kind_of`).
- **O recheio** deixa a célula limpa (`ScatterView.island_context`).

## No caminho

- O sorteio pelo `hash([id, 17])` dava caixa d'água nas três fazendas da captura: com ids pequenos e seguidos ele puxa
  demais para um resto. Passou a ser o resto do próprio id, que alterna entre fazendas vizinhas.

## Como testar

- `tests/world/test_phase117_farm_silos.gd`: um silo por fazenda, numa célula livre encostada nela e do lado de trás; o
  recheio deixa a célula limpa e uma estrada a tira; a vista desenha silos e caixas; as aduelas têm as faces para fora.
- Captura: `tools/capture_phase117.tscn` (semente 1840: três fazendas na ilha principal, vistas pelos fundos;
  `fazenda_0.png` a `fazenda_2.png` e `fazenda_de_perto.png`).
