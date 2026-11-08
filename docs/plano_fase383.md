# Plano da Fase 383 — Pedra clara em blocos

**Estado: feita em 08/11/2026**, a terceira do roteiro `docs/plano_fases_381_385.md` (texturas do MegaKit).

## O problema

Com o MegaKit, a pedra clara gerada (célula (2, 2): cornija, faixa, frontão, balaustrada, arcos) saía numa cor só com um ruído
(Fase 367), lisa ao lado da cantaria do pacote.

## O que entrou

- No `shaders/building_kit.gdshader`, com o MegaKit, o brilho dela sai dos blocos aparelhados da cantaria do pacote
  (`megakit_ashlar_v`, as quatro fiadas de baixo, e `megakit_ashlar_per_m`, os mesmos números do `BuildingKit` da Fase 377),
  projetados pela face e divididos pelo brilho médio (`megakit_ashlar_luma`); a cor segue a `megakit_stone_color`. A aspereza
  também sai da textura.

## Como testar

- `tests/presentation/test_phase381_pack_textures.gd`: os uniformes e as faixas, iguais às do `BuildingKit`.
- Captura: `rua_investors_a.png` no `tools/capture_phase95.tscn` (a balaustrada e a cornija).
