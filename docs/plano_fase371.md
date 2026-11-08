# Plano da Fase 371 — Telhas redondas

**Estado: feita em 08/11/2026**, a primeira do roteiro `docs/plano_fases_371_375.md` (peças do MegaKit II).

## O problema

Com as paredes do MegaKit, o telhado de telhas seguia com a textura de telha do Poly Haven projetada de três lados e as telhas
desenhadas no shader (Fase 95), num vermelho escuro que destoava das paredes do pacote.

## O que entrou

- **`tools/pack_megakit.gd`**: a camada 7 das pilhas, as telhas redondas do pacote (`T_RoundTiles`, cor, aspereza e normal). As
  pilhas passaram de 7 para 8 fatias (os dois `.import`). Nenhuma peça empacotada usa a camada: as malhas saíram iguais.
- **`shaders/building_kit.gdshader`**: com o MegaKit (`megakit_stone`, que o `BuildingMaterials.sync_megakit` já põe) e o telhado
  de telhas (`roof_layer` 0), as águas viradas para cima levam a camada 7:
  - a UV ao longo da água (u de través, v descendo), `megakit_tile_m` de telhado por repetição (6 telhas e 4 fileiras);
  - a cor puxada `megakit_tile_tint` para o tom do telhado da casa, com o tom por casa, o musgo e a sujeira da Fase 300 (as
    telhas trocadas e o desenho da Fase 95 saem: a textura já as tem);
  - o mapa de normais do pacote no referencial da água, posto direto no `NORMAL`.
- O sapê, a ardósia, as tábuas e a chapa ondulada não mudam, nem a capa da cumeeira e o beiral.

## Como testar

- `tests/presentation/test_phase371_round_tiles.gd` confere a camada nas pilhas e os uniformes no shader.
- Capturas: `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase371\dia`).
