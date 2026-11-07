# Plano da Fase 72 — Desfazer o trilho

**Estado: feita em 28/10/2026, a pedido do dono** ("pode ir para a próxima"; proposta deixada de fora nas Fases 70 e
71). Mexe só no histórico de desfazer (fora do save): o save, o determinismo e as assinaturas não mudam.

## O que entrou

- **O trilho no histórico** (`UndoHistory`): o `BuildRailCommand` entra no histórico como a estrada (o retângulo do
  traçado) e cada ação guarda a camada de trilho do retângulo dela antes e depois, como já guardava as estradas.
- **O desfazer** (`UndoCommand`): o Ctrl+Z tira o trilho posto e devolve as moedas e as tábuas (no mesmo tick, os valores
  exatos); o trilho demolido volta; o refazer põe o trilho de novo e cobra outra vez. Recusado ("o lugar mudou") se o
  trilho do retângulo foi mexido fora do histórico depois da ação. O trilho que volta avisa a simulação
  (`rails_changed`): as ligações, o desenho e o trem são refeitos.

## Números

- Benchmark: o histórico não roda no benchmark; neutra (`docs/benchmark.md`).

## Como testar

- `tests/sim/test_phase72_rail_undo.gd`: desfazer e refazer o trilho posto (com o dinheiro e as tábuas), o trilho
  demolido voltando com o desfazer, e a recusa quando o trilho mudou.

## Fica de fora (proposta à espera do dono)

- Nada novo; seguem as propostas da Fase 71 (fumaça, o trem levando a carga de verdade, mais trens, desvios).
