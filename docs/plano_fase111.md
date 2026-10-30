# Plano da Fase 111 — Terreiro tropical

**Estado: feita em 30/10/2026**, segunda do roteiro `docs/plano_fases_110_114.md` (sol, trópico e avenida, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **O terreiro** (`RoadMask.yards`, `_stamp_yard`): nas ilhas tropicais, cada casa ganha no canal b da máscara das
  estradas (o do chão batido das portas, Fase 38) o lote dela crescido de `YARD_REACH_M`, cheio por dentro e somindo em
  `YARD_SOFT_M` na borda. O terreno já pinta o canal b como terra batida, então nenhuma linha do shader mudou.
- **Refeito com a obra**: o `refresh` compara os terreiros como compara as trilhas dos pastos e redesenha só o retângulo
  das casas que entraram, saíram ou mudaram (a `TerrainView` já chama o `refresh` a cada obra e demolição).
- As ilhas temperadas ficam como antes.

## Como testar

- `tests/world/test_phase111_tropical_yards.gd`: a casa tropical tem terreiro (chão batido no canto do lote, nada bem longe
  dele); a temperada não; uma casa nova faz o `refresh` redesenhar o lote dela.
- Captura: `tools/capture_phase111.tscn` (semente 1840: uma rua de casas num descampado da primeira ilha tropical;
  `terreiro_de_cima.png`, `terreiro_rua.png`, `terreiro_fundos.png`).
