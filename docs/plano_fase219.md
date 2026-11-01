# Plano da Fase 219 — Balanço e gangorra na escola

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_215_219.md` (tábua, cortina e andorinha, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **`SideYard`** (`presentation/side_yard.gd`): a busca das duas células encostadas no meio de um lado de um prédio, que as Fases
  215 (tábuas) e 216 (carvão) repetiam, virou uma classe só: `pick` (os prédios dos tipos pedidos, pela ordem dos ids, e o
  primeiro lado livre na ordem pedida no referencial do modelo), `pair`, `is_free`, `cells_of` e `place` (o meio das duas células
  no chão, com o +z para fora da parede). As tábuas e o carvão passaram a usá-la, sem mudar onde ficam.
- **Onde** (`PlaygroundView.sites`, `cells`): em cada escola, as duas células do meio do lado de −X do modelo, depois o de +X e
  por fim o de trás (a frente é a da estrada), fora das tábuas e do carvão de um vizinho encostado. O recheio e as bombas as
  deixam limpas.
- **O pátio** (`playground_mesh`): o balanço de madeira em dois cavaletes em A com a trave por cima e dois assentos de tábua nas
  cordas (um levado um pouco para fora, como se alguém tivesse acabado de descer), e a gangorra pintada de verde sobre o pé de
  cavalete, com o eixo de ferro, inclinada com a ponta baixa no chão, e as alças. Um MultiMesh, no meio das duas células.

## Como testar

- `tests/world/test_phase219_playgrounds.gd`: nas quatro rotações o pátio fica de lado, encostado na escola, nunca na frente; com
  uma das células bloqueada, vai para o outro lado; outros prédios não têm; o recheio e as bombas deixam as células; o balanço e a
  gangorra cabem nas duas células e a ponta baixa da gangorra encosta no chão. Os testes das Fases 215 e 216 seguem passando com
  o `SideYard`.
- Captura: `tools/capture_phase219.tscn` (duas escolas na ilha plana; `balanco_de_perto.png`, `balanco_e_escola.png`,
  `balanco_de_longe.png`).
