# Plano da Fase 195 — Cemitério da igreja

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_195_199.md` (cemitério, pato e rede, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`GraveyardView.layout`, `cells`): atrás de cada igreja, além do anel do largo calçado da Fase 109, `ROWS` fileiras
  de células da largura dela mais `SIDE_CELLS` de cada lado; só as livres (terra sem prédio, estrada, trilho nem árvore), quase
  planas (`MAX_RELIEF_M`) e fora da alameda e das mesas da taverna. O portão é a célula do meio da primeira fileira.
- **As covas** (`graves_of`, `stone_mesh`): `GRAVES_PER_CELL` por célula, lado a lado, com a lápide no fundo virada para a
  igreja: lápide de topo redondo com o limo na base, cruz sobre o soco ou obelisco com a moldura de pedra e o cascalho, pelo
  hash da cova; as outras com o montinho de grama. Parte delas tomba um pouco (`TILT_SHARE`, até `MAX_TILT_RAD`), e cada pedra
  tem o seu tom (`TONES`: nova, gasta, com limo, amarelada). Um MultiMesh por tipo de pedra.
- **O muro** (`walls`): um pedaço de pedra baixo por lado de célula que não dá para outra célula do cemitério, recuado
  `WALL_INSET_M`; no portão o lado da igreja fica aberto, com dois pilares. Na pedra das paredes do cais.
- O recheio (`ScatterView.island_context`) e as bombas d'água deixam as células limpas. Só a ilha com relevo, como o largo.

## Como testar

- `tests/world/test_phase195_graveyard.gd`: as covas ficam atrás da igreja, fora do largo, nas células livres e quase planas;
  as lápides olham para a igreja e assentam no chão; o muro fecha as bordas e abre o portão; o recheio fica fora; outros prédios
  e a ilha plana não têm.
- Captura: `tools/capture_phase195.tscn` (a igreja num descampado da semente 1840, vista por trás, de perto e pela rua).
