# Plano da Fase 221 — Barris na cervejaria

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_220_224.md` (bomba, barril e lençol, a partir das capturas do Anno
do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BarrelRackView.sites`, `cells`): na cervejaria, nas destilarias de aguardente e de rum e na adega (`KINDS`, os prédios
  dos tonéis da Fase 98), as duas células do meio do lado de −X do modelo, depois o de +X e por fim o de trás, pelo `SideYard`,
  fora dos pátios de lado de antes. O recheio e as bombas as deixam limpas.
- **Os barris** (`rack_mesh`, `_barrel`): a pirâmide de barris deitados (`ROWS`: quatro, três e dois, cada fileira nos vãos da de
  baixo) sobre dois calços, com o fundo para fora da parede, e dois barris de pé ao lado, um com o funil de lata. O barril é
  torneado com o bojo (`BULGE`), os dois fundos, os arcos de ferro das pontas e dois saltados no meio; um tom de madeira por
  barril. Um MultiMesh, no meio das duas células.

## Como testar

- `tests/world/test_phase221_barrel_racks.gd`: nas quatro rotações a pilha fica de lado, encostada na cervejaria, nunca na frente;
  com uma das células bloqueada, vai para o outro lado; outros prédios não têm; os quatro prédios dos tonéis ganham a sua; o
  recheio e as bombas deixam as células; a malha cabe nas duas células e cada fileira tem um barril a menos que a de baixo.
- Captura: `tools/capture_phase221.tscn` (uma cervejaria e uma destilaria na ilha plana; `barris_de_perto.png`,
  `barris_e_cervejaria.png`, `barris_de_longe.png`).

## Desempenho

- **As buscas de lado guardadas** (`SideYard.remember`): cada pátio de lado pede as células dos de antes, e cada pedido refazia a
  busca deles com o largo e a alameda; com a cidade cheia do benchmark o carregar subiu de 6,3 para 6,5 s (com a memória, 6,1). As buscas das tábuas,
  do carvão, da escola, do quartel e dos barris ficam na memória das buscas junto da rua da Fase 204 (`WaterPumpView.remembered`,
  esquecida a cada obra, estrada, trilho, árvore e troca de mundo), e quem chama recebe uma cópia.
