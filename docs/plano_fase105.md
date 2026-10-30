# Plano da Fase 105 — Árvores de quintal

**Estado: feita em 29/10/2026**, primeira do roteiro `docs/plano_fases_105_109.md` (cidade e porto, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A macieira de quintal** (`ScatterView.Kind.YARD_TREE`, no fim do enum): tronco de `YARD_TRUNK_M`, copa em cinco massas
  (raio `YARD_CROWN_M`) e meia dúzia de frutas vermelhas por fora, cor no vértice, no material das plantas (balança com o
  vento) e com sombra.
- **Onde**: nas células livres encostadas numa casa, com a chance `YARD_TREE_CHANCE`, **no fim** da lista `NEAR_HOUSE` (o
  sorteio de cada célula anda pela lista em ordem: as peças de antes saem iguais). No meio da célula, sem encostar na
  parede (a copa fica a menos de 0,8 m do meio; a parede da casa vizinha, a 1,15 m: a divisa a 1 m e a folga da parede), e nunca maior que o tamanho de modelo. Na
  ilha tropical, a árvore de quintal vira bananeira.

## Como testar

- `tests/world/test_phase105_yard_trees.gd`: com uma fileira de casas, aparecem macieiras, todas no meio de uma célula
  livre encostada numa casa e sem passar do tamanho; a copa cabe na célula sem chegar à parede; nas tropicais, nenhuma.
- Captura: `tools/capture_phase105.tscn` (semente 1840: procura um descampado na ilha principal, ergue uma rua de casas e
  tira `quintais_rua.png`, `quintais_fundos.png` e `macieira_de_perto.png`).
