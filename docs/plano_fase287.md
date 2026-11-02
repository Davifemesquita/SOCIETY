# Plano da Fase 287 — Flores miúdas

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_285_289.md`. No Anno, o capim tem pontinhos de flor
brancos e amarelos; no Society, o capim era só verde, com as papoulas em canteiros (Fase 156).

## O que entrou

- **No terreno** (`shaders/terrain.gdshader`, logo depois das manchas da Fase 285): pontos de flor de `flower_dot_m` (0,1 m).
  - No máximo um por célula de `flower_cell_m` (0,7 m), num lugar sorteado na célula.
  - Em `flower_share` (30%) das células, vezes os prados de flor (o ruído de `flower_meadow_m`, 36 m).
  - Mais no capim baixo e menos no alto; brancos (`flower_white`) ou amarelos (`flower_yellow`).
  - Somem de `flower_far_m` × 0,55 a `flower_far_m` (75 m) da câmera: mais longe seriam menores que um pixel e cintilariam.
  - Só na grama.
- **No tapete** (Fase 286):
  - o tufo ganhou uma flor de cinco pétalas deitadas a 0,42 m, com o alfa do vértice em 0;
  - o `shaders/grass_carpet.gdshader` a deixa só nos tufos sorteados, pelas mesmas regras e números do terreno;
  - nos outros tufos ela vira um ponto (`VERTEX = vec3(0.0)`) e não desenha nada;
  - a cor é branca ou amarela pelo lugar.
- **A primeira medida** (16% das células, ponto de 0,07 m, pétala de 0,05 m) quase não aparecia nas capturas.
- O roteiro previa menos flores junto das casas. O tapete e as manchas já não entram no lote nem na estrada, e o terreno não sabe
  das casas; ficou assim.

## Medida

Benchmark neutro: GPU 12,3 ms, igual à Fase 286. Sobre o prado aberto (`tools/grass_cost.tscn`), o tapete com as flores custa
+0,32 a 0,43 ms de GPU, perto dos +0,17 a 0,39 da Fase 286; as pétalas são cinco triângulos por tufo.

## Como testar

- `tests/world/test_phase287_flowers.gd`:
  - os uniformes nos dois shaders compilados (com tela);
  - os pontos do terreno só na grama, mais no capim baixo, sumindo de longe;
  - a flor do tufo com as pétalas no alfa 0 e na altura certa, pelas mesmas regras e números do terreno.
- `test_phase286_grass_carpet.gd` conta as pétalas no tufo.
- Captura: `tools/capture_phase285.tscn -- <pasta>` (o prado de perto em `01_`).
