# Plano da Fase 306 — Chão da mata

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_305_309.md`. No Anno, o chão da mata é escuro, de folhas e
agulhas, na sombra das copas; no Society, era a textura de folhas de sempre, parda e clara.

## O que entrou

- **`shaders/terrain.gdshader`**, logo depois da mistura da grama com a mata: no miolo da mata (`deep`, o peso dela no
  `surface_weights` com o ruído da borda, vezes o peso da mata misturada), o chão escurece `floor_dark` (0,6) e ganha manchas de
  musgo (`floor_moss_color`, em `floor_moss_share` do chão, ruído de `floor_moss_m` e um terço disso). A beira da mata fica em
  transição pelo próprio peso. `forest_floor` 0 desliga.
- Conferido com o miolo pintado de vermelho: a máscara cobre o chão debaixo das árvores até a beira, e o prado fica de fora.

## Medida

72,5 FPS, GPU 12,8 ms (305: 12,7). Neutra.

## Como testar

- `tests/world/test_phase306_forest_floor.gd`: o bloco depois da mistura da mata, com o escurecido e o musgo; o shader compilando
  com os uniformes novos (com tela).
- Captura do ciclo: `tools/capture_phase305.tscn -- <pasta>`; os recortes do chão entre os troncos estão em
  `F:\ferramentas\capturas\fase306\chao_antes.png` e `chao_depois.png`.
