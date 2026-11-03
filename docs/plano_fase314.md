# Plano da Fase 314 — Sombra da falésia na água

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_310_314.md`. No Anno, a água junto das falésias fica escura na
sombra delas; no Society, a cor da água sai pela `EMISSION` (Fase 282) e não recebe a sombra de verdade.

## O que entrou

- **`CoastField`**: com `"heights"` nas regiões (a `TerrainView` passa as alturas dos cantos), guarda também a altura da terra nos
  mesmos pixels (o mar em 0) e dá a `height_texture`. A `WaterView` a põe no `land_height` e liga `has_cliff_shade`.
- **`shaders/water.gdshader`**, `cliff_shadow`: na água a até `cliff_shade_reach_m` (36 m) da costa, de dia, uma marcha de
  `cliff_shade_steps` (8) passos na direção do sol (`sun_direction`): onde a terra passa da altura do raio de sol naquele ponto, a
  água fica na sombra. A cor (e o albedo) escurece `cliff_shade` (0,45), e a cintilação da Fase 110 some nela. Conferido com a
  sombra pintada de magenta: ela cai do lado oposto ao sol, atrás dos promontórios.
- O roteiro falava da altura da terra perto; a marcha na direção do sol dá a sombra de verdade (o comprimento pela altura do sol).

## Medida

72,0 FPS, GPU 12,8 ms (313: 12,9). Neutra.

## Como testar

- `tests/world/test_phase314_cliff_shade.gd`: o `CoastField` com a altura da terra (e sem ela, nada); a marcha no shader e a `WaterView`
  ligando; o shader compilando com os uniformes novos (com tela).
- Captura do ciclo: `tools/capture_phase310.tscn -- <pasta>` (`05_` e `06_falesia_a_tarde`, às 17h); os recortes da enseada estão em
  `F:\ferramentas\capturas\fase314\sombra_antes.png` e `sombra_depois.png`.
