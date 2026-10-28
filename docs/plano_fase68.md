# Plano da Fase 68 — Atratividade e turistas

**Estado: feita em 28/10/2026, a pedido do dono** ("pode fazer toda e seguir para a próxima"; a atratividade e o
turismo do Anno, simplificados). Mexe na simulação, mas o turismo só paga com os eventos ligados (como o jornal): o
mundo novo da simulação, os testes, o robô e as assinaturas não mudam; nada novo vai no save.

## O que entrou

- **Atratividade** (`DerivedState.attractiveness`, refeita com o estado derivado): cada ilha com entreposto e casas
  soma a beleza que espalha — decorações e, desde a Fase 67, o zoológico e o museu com as peças
  (`beauty_strength`) — vezes `attractiveness_per_beauty` (100) e desconta a poluição dos prédios (`pollution_strength`)
  vezes `attractiveness_per_pollution` (60), nunca abaixo de zero.
- **Turistas** (`TourismSystem`, logo depois da economia): pagam por minuto a atratividade de cada ilha vezes
  `tourism_coins_per_point` (0,5), mais `tourism_festival_bonus` (50%) com a festa na ilha. A renda entra no dinheiro e
  na receita por minuto (como os acordos com as rivais) e fica em `WorldState.tourism_per_min`.
- **Detalhamento do dinheiro** (Fase 47): uma parcela "Turistas" (`Breakdown.Kind.TOURISM`); o imposto continua
  fechando a conta.
- **Painel do entreposto**: "Atratividade: N · turistas X/min", com a explicação na dica (some sem os eventos).

## Números

- Benchmark (alto, RTX 5060): neutro — tick médio 1,31 ms, construir com a ilha cheia 15,4 ms, GPU 21,8 ms com a
  máquina no estado lento (sem eventos no benchmark, o turismo não paga; `docs/benchmark.md`).

## Como testar

- `tests/sim/test_phase68_tourism.gd`: a atratividade é a beleza menos a poluição, sem entreposto não há, os turistas
  pagam com os eventos ligados e mais na festa, o detalhamento com a parcela deles fecha, o dinheiro do tick bate com
  a receita (com os turistas) menos a manutenção, e sem os eventos nada.
- `tests/ui/test_phase68_tourism_panel.gd`: a linha da atratividade no painel do entreposto (e sem ela sem eventos);
  o nome da parcela traduzido.

## Fica de fora (proposta à espera do dono)

- Turistas andando nas ruas e chegando de navio, gastos nos serviços (taverna, teatro), o hotel e a atratividade por
  paisagem (praia, mata). Os pesos e o preço por ponto são provisórios.
