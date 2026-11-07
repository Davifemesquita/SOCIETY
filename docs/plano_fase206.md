# Plano da Fase 206 — Bebedouro de cavalos

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_205_209.md` (estandarte, bebedouro e lanterna, a partir
das capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`HorseTroughView.cells`): junto de cada taverna, na célula livre encostada nela pelo lado (sem os cantos) mais perto
  da porta, fora das células que as outras peças já tomam (`WaterPumpView.taken_cells`, com as mesas da Fase 116, que pegam as
  células da frente) e do carrinho de feira, quase plana; guardada na memória das buscas junto da rua da Fase 204.
- **O bebedouro** (`trough_mesh`): o cocho comprido de pedra (o fundo, as paredes e a borda mais escura), a água, a coluna da bica
  com o cano de ferro numa ponta e a argola de amarrar na outra, de comprido ao longo da parede da taverna e de frente para longe
  dela. Um MultiMesh.
- A bomba e o poço desviam dele, junto com o carrinho de feira (`WaterPumpView.street_pieces`), e o recheio deixa a célula.
- **O que ficou de fora**: o roteiro punha o bebedouro junto da rua. As mesas da taverna pegam as células da frente, e dar a
  vez ao bebedouro antes delas fazia as buscas chamarem umas às outras (as mesas consultariam o bebedouro, que consulta a lista
  das tomadas, que tem os silos e as medas, que consultam as mesas). Buscar a duas células passava por cima da rua.

## Como testar

- `tests/world/test_phase206_horse_troughs.gd` (num pedaço de terra da ilha: a obra ignora o terreno, e no mar a rua sairia igual):
  o bebedouro fica encostado na taverna pelo lado, fora das mesas, de costas para ela; a bomba, o poço e o recheio deixam a
  célula; sem taverna e na ilha plana não há; o cocho assenta no chão e cabe na célula.
- Captura: `tools/capture_phase206.tscn` (uma rua de terra com duas tavernas e casas na ilha principal da semente 1840).
