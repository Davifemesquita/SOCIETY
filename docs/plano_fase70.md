# Plano da Fase 70 — Ferrovia e petróleo

**Estado: feita em 28/10/2026, a pedido do dono** ("pode fazer toda e seguir para a próxima"; a proposta da
eletricidade a petróleo do Anno, que depende do trem, simplificada). Mexe na simulação (bem, prédios, camada de
trilho no save); a assinatura do terreno não muda (os campos de petróleo saem depois dela) e nada antigo muda de
comportamento.

## O que entrou

- **Campos de petróleo** (`OilFields`, `IslandGrid.oil_spots`): dois por ilha temperada, sorteados pela semente da ilha
  num bloco de terra plano de 3 × 3, longe um do outro, depois da assinatura do terreno (`ArchipelagoGenerator`):
  saves antigos e a assinatura continuam iguais. Mancha escura e brilhante no chão enquanto o campo está livre; ao
  escolher o poço, o destaque de terreno mostra os blocos.
- **Petróleo** (`GoodDef.rail_only`): só anda por trilho — carroça não leva, não vai ao estoque.
- **Poço de petróleo** (`oil_well`, 3 × 3, engenheiros, `Terrain.OIL`: o lote cobre um campo) e **usina a petróleo**
  (`oil_power_station`, 5 × 5, queima petróleo e eletrifica até 32 células, mais que a de carvão).
- **Trilho** (`IslandGrid.rails`, `BuildRailCommand`): em terra da ilha sem prédio nem estrada, fora do mar e do rio e
  sem barranco; 15 moedas e meia tábua por célula; prédio e estrada não vão em cima do trilho e o trilho não vai em
  cima deles; demolir tira; no save (o save antigo carrega sem trilho).
- **Regra** (`RailNetwork`, `DerivedState._link_rails`, `RailSystem`): os trilhos de cada ilha em grupos ligados (vizinho
  de lado); o poço e a usina que encostam no mesmo grupo (trilho num lado do lote) ficam ligados, e a cada tick o
  trilho leva o petróleo do poço até a usina guardar `rail_input_buffer_t` (6 t). Sem trilho, o poço enche e para.
- **Tela**: o cartão "Trilho" na aba da infraestrutura (o mesmo arrasto da estrada, sempre em L, com a prévia e o
  custo), a dica do modo, os trilhos desenhados (lastro, dormentes e barras, sobre o chão com o detalhe), o recheio
  fora das células de trilho, os ícones (a bomba, a torre e o trilho do Delapouite, baixados do game-icons.net,
  CC BY 3.0; o barril para o petróleo) e as fotos do poço e da usina.

## Números

- Benchmark (alto, RTX 5060): a primeira rodada travou 2,1 s na primeira vez que as manchas de petróleo apareceram (o
  material compilava no meio da partida); com o trilho e um campo no rascunho do `WarmUp`, o pior quadro voltou a
  426 ms, o dia inteiro a 35,6 FPS e a GPU a 22,5 ms com a máquina lenta, tick médio 1,37 ms (`docs/benchmark.md`).

## Como testar

- `tests/sim/test_phase70_rail_oil.gd`: os campos pela semente nas ilhas temperadas (nenhum nas tropicais, sempre em
  terra), o poço só no campo, trilho bloqueando prédio e estrada (e a estrada bloqueando trilho), o custo do trilho e a
  demolição, o petróleo só por trilho (sem trilho o poço enche e para; com trilho a usina produz; o estoque nunca tem
  petróleo), o trilho cortado cortando o abastecimento, e o save (e o antigo).
- `tests/ui/test_phase70_rail_tool.gd`: o arrasto do trilho (sempre em L) e o desenho, as recusas cruzadas da prévia, o
  poço e a usina no menu com ícone e foto.
- Capturas: `tools/capture_phase70.tscn -- <pasta>` (um campo livre, o poço com trilho até a usina e o trilho de perto;
  em `F:\ferramentas\capturas\fase70`; o roteiro traça o L ignorando o terreno, então o trilho pode descer barranco).

## Fica de fora (proposta à espera do dono)

- O trem andando no trilho (hoje o transporte é instantâneo), o desfazer do trilho no histórico (Ctrl+Z não devolve
  trilho demolido), trilho em diagonal e ponte de trilho, um modelo próprio do poço (cavalo-de-pau) e da usina, e
  outros bens que andem de trem. Os números são provisórios.
