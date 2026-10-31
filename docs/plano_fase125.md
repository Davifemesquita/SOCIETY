# Plano da Fase 125 — Recife de coral

**Estado: feita em 30/10/2026**, primeira do roteiro `docs/plano_fases_125_129.md` (recife, alpendre e nuvens, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **O recife** (`shaders/water.gdshader`, grupo `Reef`, `reef_at`): no mar raso das ilhas tropicais, entre `reef_from_m` e
  `reef_to_m` da costa (o mesmo campo de costa da Fase 35), manchas escuras e irregulares de um ruído de valor de duas
  oitavas (`reef_cell_m`, a fração `reef_share`), misturadas à cor do fundo raso em `reef_color`.
- **Só no trópico** (`WaterView.reef_min_x`): o recife vale a leste da borda oeste das regiões das ilhas tropicais (as
  temperadas ficam todas a oeste dela); sem ilha tropical, desligado.

## No caminho

- O hash do ruído com `fract(sin(...))` perdia precisão na GPU com as coordenadas do arquipélago e as manchas saíam com a
  borda em escada; o hash passou a ser sem seno.

## Como testar

- `tests/world/test_phase125_reef.gd`: a borda do recife fica entre as temperadas e as tropicais; sem tropical não há; com
  tela, o shader compila com os uniformes novos.
- Captura: `tools/capture_phase125.tscn` (semente 1840: a costa sul da maior ilha tropical e a da principal para comparar;
  `recife.png`, `recife_de_perto.png`, `sem_recife.png`, `sem_recife_de_perto.png`).
