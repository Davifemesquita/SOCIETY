# Plano da Fase 202 — Secadouro de peixe

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_200_204.md` (gato, poço e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`FishRackView.sites`, `cells`): ao lado de cada cabana de pesca das ilhas temperadas, na célula livre encostada nela
  mais perto da metade do lado da terra (o contrário das redes da Fase 139), de terra, sem prédio, estrada, trilho nem árvore,
  fora do largo, da alameda, das redes e do barco virado da Fase 183, e quase plana. Nas tropicais não há.
- **O secadouro** (`rack_mesh`): dois pares de varas cruzadas em X segurando a vara de cima e duas mais baixas, com os peixes
  abertos pendurados aos pares de um lado e do outro de cada vara (`_fish`: o corpo chato alargando e afinando até a cabeça,
  mais escura, e o rabo em V no alto, dos dois lados), a vara de través do mar. Um MultiMesh.
- O recheio e as bombas d'água deixam a célula (`ScatterView.island_context`, `WaterPumpView.taken_cells`).

## Como testar

- `tests/world/test_phase202_fish_racks.gd`: o secadouro fica de um lado da cabana, na fileira da terra, fora das redes; com a
  célula bloqueada, vai para outra; outros prédios e as ilhas tropicais não têm; o recheio deixa a célula; a peça cabe nela.
- Captura: `tools/capture_phase202.tscn` (uma cabana de pesca na costa da ilha principal da semente 1840, de longe e de perto).
