# Plano da Fase 95 — Telhado de telhas

**Estado: feita em 29/10/2026**, a primeira do roteiro `docs/plano_fases_95_99.md` (formas mais redondas, a pedido do
dono, olhando o Anno 1800 dele: só a ideia, nada do jogo). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Telhas nas águas** (`shaders/building_kit.gdshader`, `roof_tile_shade`; `tile_row_m`, `tile_width_m`, `tile_strength`,
  `tile_fade_far`): nas águas viradas para cima (célula (0, 3) da paleta), fileiras de telha ao longo da água — a distância
  do chão dividida pelo cosseno da inclinação —, telhas desencontradas fileira a fileira, a borda de baixo arredondada (o
  meio da telha desce mais que as juntas) com a sombra embaixo, a junta entre as telhas, a parte de cima coberta pela
  fileira de cima e um tom sorteado por telha. Tudo no shader, nenhum triângulo a mais; some de 40 a 80 m da câmera (de
  longe as linhas cintilariam).
- **Quinas arredondadas** (`BuildingKit._rod`, `RIDGE_CAP_M`, `RIDGE_SIDES`, `EAVE_ROLL_M`, `EAVE_SIDES`): uma haste redonda
  com a normal de cada vértice para fora do eixo (o sombreado sai liso). Na cumeeira das duas águas, a capa em meia volta de
  ponta a ponta; em cada água, o beiral redondo no lugar da quina viva; no telhado de quatro águas, a capa nos quatro
  espigões e na cumeeira e o beiral redondo em volta. O telhado plano fica como estava. As hastes usam a célula (1, 3) da
  paleta (`UV_ROOF_TRIM`), que o shader trata como telhado (textura e tom) sem as telhas.

## Números

- Constantes de apresentação. Cada haste de seis faces tem 12 triângulos: o telhado de duas águas ganha 36 (a capa e os
  dois beirais) e o de quatro águas até 108 (quatro espigões, a cumeeira e quatro beirais). As malhas seguem em cache por
  forma, na mesma superfície: nenhum draw call a mais (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase95_roof_tiles.gd`: a haste é redonda (na superfície e com a normal para fora do eixo; a
  meia volta só tem a metade de cima); o telhado de duas águas ganha a capa acima da cumeeira e o beiral embaixo; o de
  quatro águas também; o plano, nada.
- `tests/presentation/test_building_kit.gd`: a folga da caixa da igreja conta o beiral redondo (1 cm a mais).
- Captura: `tools/capture_phase95.tscn -- <pasta>` (na ilha plana: uma rua de casas por classe e uma de serviços e
  fábricas, às 10h; serve às Fases 95 a 99). A captura da Fase 39 deixou de achar lugar plano no terreno v3/v4 e
  fotografava o mar; a nova não depende do terreno.
