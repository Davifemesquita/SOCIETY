# Plano da Fase 112 — Coqueiros na rua tropical

**Estado: feita em 30/10/2026**, terceira do roteiro `docs/plano_fases_110_114.md` (sol, trópico e avenida, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **O coqueiro de rua** (`ScatterView.Kind.STREET_PALM`, no fim do enum): o coqueiro da Fase 58 (`TreeModel`, com o material
  da folhagem, que balança com o vento) reduzido a `STREET_PALM_SCALE`, no meio da célula, com sombra.
- **Onde**: nas células livres da beira das ruas (`NEAR_ROAD`), com a chance `STREET_PALM_CHANCE`, no fim da lista (as peças
  de antes da célula não mudam); só nas ilhas tropicais (nas temperadas o sorteio é feito e a peça é pulada).

## Como testar

- `tests/world/test_phase112_street_palms.gd`: com uma rua na ilha tropical aparecem coqueiros, todos em célula livre
  encostada na rua e no tamanho reduzido; na temperada nenhum, e o capim da beira da rua continua.
- Captura: `tools/capture_phase111.tscn` (a rua tropical da Fase 111; `terreiro_rua.png`).
