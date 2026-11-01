# Plano da Fase 201 — Poço da vila

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_200_204.md` (gato, poço e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WellView.cells`): junto de uma casa dos camponeses a cada `WELL_EVERY` pelo id (resto `WELL_REST`; as casas da bomba
  d'água da Fase 132 ficam de fora), na célula livre encostada nela que dá para a rua e fica mais perto da porta, fora do que
  as outras peças já tomam e das bombas. A busca é a da bomba, separada em `WaterPumpView.taken_cells` (as células das outras
  peças) e `WaterPumpView.beside_street` (a célula da rua mais perto da porta); a bomba continua igual.
- **O poço** (`well_mesh`): o bocal redondo de pedra em fiadas de blocos desencontrados (`_ring`, `STONE_TONES`), a borda mais
  larga em cima, a água escura lá no fundo, os dois esteios com o telhadinho de duas águas e a cumeeira, o sarilho com a
  manivela, a corda e o balde; o sarilho de través para a rua. Um MultiMesh.
- O recheio deixa a célula limpa (`ScatterView.island_context`). Só a ilha com relevo, como a bomba.

## Como testar

- `tests/world/test_phase201_wells.gd`: o poço fica numa célula livre encostada numa casa dos camponeses do resto certo, com a
  rua ao lado e fora das bombas; o recheio deixa a célula; os operários e a ilha plana não têm; o poço assenta no chão e cabe
  na célula. O teste da bomba (Fase 132) segue passando depois da separação.
- Captura: `tools/capture_phase201.tscn` (uma rua de terra de casas de camponeses na ilha principal da semente 1840).
