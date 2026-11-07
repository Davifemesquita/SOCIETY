# Plano da Fase 82 — Ver os fogos

**Estado: feita em 28/10/2026, a pedido do dono** ("pode continuar"; proposta deixada de fora na Fase 81: "turistas indo
ver os fogos à noite, juntando-se em volta dos mastros da festa"). Só visual: a simulação, o save e as assinaturas não
mudam.

## O que entrou

- **Na hora dos fogos, os turistas vão à festa** (`Crowd._pick_attraction`): com a festa na ilha e a noite acima de
  `FestivalView.NIGHT_FIREWORKS` (a mesma em que os fogos estouram; `Crowd.fireworks_now`), o turista escolhe uma das
  praças da festa (`FestivalView.squares`, na rede de estrada do entreposto e com mastro na rua) em vez das atrações.
- **Em volta do mastro** (`Crowd._watch_spot`): em vez da porta, o turista fica na rua, ao longo de uma das cordas de
  bandeirolas, de `WATCH_NEAR_M` (1,2 m) até `WATCH_FAR_M` (7 m) do mastro e até `WATCH_SIDE_SHARE` (35%) da célula para
  o lado, de frente para o mastro (com até 0,4 rad de folga).
- **Sem saltos**: da porta da praça ele anda até o lugar (`Agent.to_spot`), e ao sair a perna começa no lugar dele (a
  rota em cache é copiada antes, para não levar o lugar de um turista para o próximo).
- De dia, ou sem festa, os turistas seguem como na Fase 80.

## Números

- Constantes de apresentação (`WATCH_*`), não de jogo.
- Benchmark: o mundo do benchmark não tem atratividade nem festa; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase82_fireworks_tourists.gd`: à noite na festa os turistas parados estão na praça, em volta
  do mastro e de frente para ele; ao sair, andam do lugar; de dia seguem visitando a estátua.
- Capturas: `tools/capture_phase82.tscn -- <pasta>` (o bairro da Fase 81 às 22 h, com turistas em volta do mastro e os
  fogos; em `F:\ferramentas\capturas\fase82`).

## Fica de fora (proposta à espera do dono)

- Os moradores também irem ver os fogos.
- Os turistas olharem para o céu (o boneco só gira em volta do eixo vertical) e baterem palmas a cada estouro.
