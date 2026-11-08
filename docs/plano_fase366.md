# Plano da Fase 366 — Empena e cunhais do MegaKit

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_366_370.md` (acabamento do MegaKit).

## O problema

Nas capturas da Fase 365, três defeitos destoavam das paredes do pacote:
- **A empena** (o triângulo da parede debaixo das duas águas) saía no reboco do Kenney, um cinza liso.
- **Os cunhais** (Fase 160) saíam brancos, grandes e chapados.
- **Os postigos** (Fase 177) passavam da célula: a janela larga do pacote é mais larga que a do Kenney, e as folhas de duas
  janelas vizinhas ficavam uma sobre a outra e por cima dos cunhais.

## O que entrou

- **`BuildingKit._mega_extra`**: com o MegaKit, um `SurfaceTool` à parte, com a UV2, para o que se gera no código e leva a
  textura do pacote. Ele é indexado antes de entrar na malha, como o alicerce e o telhado, porque as peças do kit chegam
  indexadas. `_roof_place` é o lugar do telhado que está sendo feito (o do corpo e o da ala são feitos no referencial deles).
- **A empena** (`_mega_triangle`) vai no reboco do pacote (UV2 = 1), com a escala da peça de parede
  (`MEGAKIT_PLASTER_UV`: 2 m dão 1 em u, 3 m dão 1 em v). O shader troca o reboco pela pedra ou pelo tijolo da parede do
  prédio, como nas peças.
- **Os cunhais** (`_mega_stone_box`) vão na cantaria do pacote (camada 4): a primeira fiada dos blocos aparelhados da
  textura (`MEGAKIT_STONE_V`), com o começo sorteado pelo lugar, para os blocos não repetirem o mesmo pedaço.
- **Os postigos** (`shutter_leaf`): no MegaKit, cada folha fica da metade do vão ou do que cabe até a divisa da célula
  (`SHUTTER_MARGIN_M`), menos o cunhal na célula da quina. A janela sem lugar para uma folha de `SHUTTER_MIN_M` fica sem
  as duas. No Kenney nada muda.

## Como testar

- `tests/presentation/test_phase366_megakit_trim.gd`:
  - a empena do MegaKit no reboco do pacote, a do Kenney sem ele;
  - os cunhais na cantaria;
  - toda folha de postigo cabendo na célula e fora do cunhal.
- Capturas: `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase366\dia\`; antes em `fase365\dia\`).

## Fica para depois

- O forro do beiral e as tábuas da ponta da água saem quase brancos (Fase 367).
- O reboco ao sol estoura de branco (Fase 368).
- Nas casas dos artesãos com cunhais, as janelas da quina ficam sem postigos.
