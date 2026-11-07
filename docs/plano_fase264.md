# Plano da Fase 264 — Sombra aberta

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_260_264.md` (cor viva II). O roteiro previa a sombra com o
azul do céu; no `tools/color_lab.tscn` a parte do céu na luz ambiente (0,6, 0,8 e 0,95) quase não mudou a sombra. O que fechava
a cena era a oclusão de ambiente: o vão entre as copas e o pé das matas ficavam quase pretos.

## O que entrou

- **SSAO mais leve** (`GameConfig.ssao_intensity` de 1,6 para 0,9, nos níveis que ligam o SSAO): a mata fica aberta, com o verde
  das copas de baixo aparecendo, e o contato dos prédios com o chão continua marcado. Escolhida no laboratório entre o SSAO a 0,9,
  a luz ambiente a 1,5 e as duas juntas (a luz ambiente mais forte clarearia também a noite).

## Como testar

- `tests/world/test_phase264_open_shade.gd`: a força nova e o nível passando ela ao ambiente.
- Capturas: `tools/capture_phase260.tscn -- <pasta>`; o ciclo inteiro, antes e depois, em
  `F:\ferramentas\capturas\fase264\ciclo_antes_depois.png`.
