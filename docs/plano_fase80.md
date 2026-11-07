# Plano da Fase 80 — Turistas na rua

**Estado: feita em 28/10/2026, a pedido do dono** ("pode seguir"; proposta deixada de fora na Fase 68: "turistas
visíveis"). Só visual, como os pedestres: a simulação, o save e as assinaturas não mudam; o turismo continua pagando
como na Fase 68.

## O que entrou

- **Turistas na multidão** (`Crowd`, a mesma dos pedestres): com os eventos ligados (como o turismo da Fase 68), cada
  ilha com atratividade (`DerivedState.attractiveness`) e entreposto ganha `tourists_per_point` turistas por ponto
  (0,05: um a cada 20 pontos), até `max_tourists_per_island` (30), vezes a fração de pedestres do nível gráfico
  (`_rebalance_tourists`, a cada `REBALANCE_SECONDS`). Sem os eventos ou sem atratividade, os que estão na rua vão
  embora quando chegam.
- **A rotina do turista**: a "casa" dele é o entreposto da ilha; ele não trabalha. Sai do entreposto, visita uma das
  `TOURIST_CHOICES` (4) atrações de mais beleza da ilha na mesma rede de estrada (os prédios com beleza e raio:
  zoológico, museu, praças, coreto, estátua, canteiros), fica parado olhando para o prédio (de frente para ele, quase
  sempre parado, `_wait_at_service`) e volta ao entreposto (`_pick_attraction`, `_pick_work` devolve 0).
- **A roupa**: clara (linho, branco, azul-claro, palha, rosa; `TOURIST_COLORS`) com a calça da classe mais rica (o grupo
  de MultiMesh dela): dá para ver na rua quem é turista.
- Config nova: `tourists_per_point` e `max_tourists_per_island` (números provisórios, à espera do dono).

## Números

- Benchmark: o mundo do benchmark tem os eventos ligados, mas nenhum prédio com beleza (atratividade zero): nenhum
  turista, 2000 pedestres como antes; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase80_tourists.gd`: a quantidade pela atratividade, a classe, o entreposto e a roupa; o teto
  por ilha; o turista só visita atração (nunca trabalho), fica olhando e volta; sem os eventos, nenhum; sem as atrações,
  vão embora.
- Capturas: `tools/capture_phase80.tscn -- <pasta>` (no mundo plano, um bairro com o zoológico, a praça e a estátua
  ligados ao entreposto, com os eventos ligados; o jogo anda até haver turistas olhando uma atração; em
  `F:\ferramentas\capturas\fase80`).

## Fica de fora (proposta à espera do dono)

- Turistas chegando de navio (descendo no cais), com chapéu, guarda-sol ou máquina fotográfica; mais turistas na festa
  (a renda já sobe); o painel do entreposto mostrando quantos turistas há na ilha.
