# Plano da Fase 297 — Fiapos de espuma nas pedras

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_295_299.md`. No Anno, a espuma que bate nas pedras sai
levada em fiapos compridos pela corrente (`c10_10`). No Society, ela ficava só colada na pedra (o anel da Fase 293).

## O que entrou

- **`shaders/water.gdshader`**, no bloco da espuma por profundidade (`SHORE_FOAM`), depois do anel da Fase 293 e somado por `max`:
  - **a forma**: dois ruídos de valor num sistema de coordenadas do vento, compridos ao longo dele (`streak_length_m`, 16 m) e
    finos de través (`streak_width_m`, 1,1 m), andando com ele (`streak_drift_m_s`). Um terceiro ruído miúdo renda cada fio.
    Na primeira versão os fios saíam como fitas brancas e lisas, e foi isso que fez entrar o ruído miúdo e o fio mais fino;
  - **onde**: de 1,5 × `shore_line_m` até `streak_reach_m` (26 m) da linha d'água;
  - **lado de baixo do vento**: o ponto meio alcance contra o vento tem de ficar perto da terra ou em cima dela;
  - **só na água funda junto da costa**: a diferença de profundidade passa de `streak_deep_m` (2,5 m). Na plataforma rasa da
    praia (−1,2 m) não há fiapos;
  - nada no rio.

## Medida

GPU 12,5 ms (296: 12,5). Neutra.

## Como testar

- `tests/world/test_phase297_rock_streaks.gd`:
  - o bloco depois do anel, andando com o vento, do lado de baixo dele, na água funda, fora do rio e por `max`;
  - fios bem mais compridos que largos;
  - o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase295.tscn -- <pasta>` (`01_falesia.png`; os fiapos dependem do vento do dia).
