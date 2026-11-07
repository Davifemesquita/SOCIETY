# Plano da Fase 256 — Copas verdes

**Estado: feita em 01/11/2026**, segunda do roteiro `docs/plano_fases_255_259.md` (cor viva, a pedido do dono).

## O que entrou

- **Folhas mais claras** (`TreeModel`): carvalho (0,37; 0,57; 0,19), faia (0,48; 0,66; 0,22), pinheiro (0,24; 0,45; 0,21), coqueiro
  e folhosa tropical também; a sombra de baixo da massa de 0,74 para 0,8 da cor e o alto de 1,12 para 1,22.
- **Sol no alto da copa** (`TreeModel.CROWN_SUN`): os vértices de cima de cada massa puxam para o amarelo (nada do meio para
  baixo), como a copa do Anno, clara em cima.
- **Luz própria das folhas** (`shaders/foliage.gdshader`, `leaf_fill`; `TreeModel.LEAF_FILL` 0,22): de dia as folhas somam uma
  fração da própria cor como emissão (o sol atravessando e voltando da copa), e à noite isso some pelo global `night_light`.
  Escolhida no `tools/color_lab.tscn` entre 0, 0,22 e 0,35 (com 0,35 a copa perdia o volume). As plantações e o capim, que usam
  o mesmo shader, ficam com 0.

## Como testar

- `tests/world/test_phase256_canopy.gd`: folhas mais claras que as da Fase 53, o alto da copa mais amarelo que o pé, a luz
  própria só de dia e no material das árvores.
- Capturas: `tools/capture_phase255.tscn -- <pasta>`; antes (Fase 255) e depois em `F:\ferramentas\capturas\fase255\depois` e
  `F:\ferramentas\capturas\fase256\depois`, e o laboratório em `F:\ferramentas\capturas\fase256\lab`.
