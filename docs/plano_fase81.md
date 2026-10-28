# Plano da Fase 81 — Festa cheia

**Estado: feita em 28/10/2026, a pedido do dono** ("pode seguir"; proposta deixada de fora na Fase 80: "mais turistas na
festa"). Só visual: a simulação, o save e as assinaturas não mudam (a renda da festa já subia desde a Fase 68).

## O que entrou

- **Na festa, mais turistas na rua** (`Crowd._rebalance_tourists`): com a festa na ilha, a quantidade de turistas e o
  teto por ilha são multiplicados por `1 + tourism_festival_bonus` (1,5), a mesma proporção em que sobe a renda do
  turismo. Acabada a festa, os que sobram vão embora quando chegam ao entreposto.
- `TourismSystem.has_festival(world, island_id)`: a checagem da festa saiu de dentro de `island_income` (o resultado
  é o mesmo) para os turistas da rua usarem a mesma regra.

## Números

- Benchmark: o mundo do benchmark não tem atratividade nem festa; neutra (`docs/benchmark.md`).
- Na captura: 7 turistas sem a festa (Fase 80), 11 com ela.

## Como testar

- `tests/presentation/test_phase81_festival_tourists.gd`: a festa traz `1 + tourism_festival_bonus` vezes os turistas e,
  acabada, voltam ao normal; o teto sobe junto. `tests/sim/test_phase68_tourism.gd` segue verde (a renda igual).
- Capturas: `tools/capture_phase81.tscn -- <pasta>` (o bairro da Fase 80 com a festa: bandeirolas e mais turistas; em
  `F:\ferramentas\capturas\fase81`).

## Fica de fora (proposta à espera do dono)

- Turistas indo ver os fogos à noite, juntando-se em volta dos mastros da festa.
