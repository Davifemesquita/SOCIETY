# Plano da Fase 369 — Arco aceso

**Estado: feita em 08/11/2026**, a quarta do roteiro `docs/plano_fases_366_370.md` (acabamento do MegaKit).

## O problema

O vidro aceso à noite (`WindowLightsView`) é um quadrado esticado até o vão da janela. Nas janelas de volta redonda do MegaKit
(a larga de arco, na frente dos prédios de arco, e a estreita de arco) os cantos de cima do quadrado ficam atrás da moldura em
arco e acendem fora dela.

## O que entrou

- **`BuildingKit.window_rises(spec)`**: para cada vidro de `windows()`, na mesma ordem, quanto do alto dele é arco (meio círculo
  da largura do vão, em fração da altura, até 0,5). É zero nas janelas retas, no Kenney, nas claraboias e no lampião.
  `MEGAKIT_ROUND_WINDOWS` diz quais janelas do pacote são de volta redonda.
- **`WindowLightsView`**: põe o arco no z do dado da instância (`building_window_rises`).
- **`shaders/window_light.gdshader`**: descarta os cantos de cima fora do arco.

## Como testar

- `tests/presentation/test_phase369_round_lights.gd` confere quatro coisas:
  - um arco por vidro, com o MegaKit e sem ele;
  - o arco na frente da igreja;
  - tudo reto no Kenney;
  - a medida do arco.
- Capturas: `CAPTURA_SO=noite` no `tools/capture_buildings.tscn`.
