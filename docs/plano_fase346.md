# Plano da Fase 346 — Estratos de longe

**Estado: feita em 07/11/2026**, a segunda do roteiro `docs/plano_fases_345_349.md` (pedra grande). Os estratos da Fase 290 (camadas de
1,15 m) sumiam a mais de ~150 m, menores que um pixel; no Anno a face de pedra tem riscos fortes que se leem do alto.

## O que entrou

- **`strata_broad`** no `shaders/rock_strata.gdshaderinc`: bancadas de `strata_broad_m` (4,2 m), tortas por um ruído largo, com a borda
  clara (`strata_broad_light`) e a sombra embaixo (`strata_broad_shade`) mais fortes que as de perto, só nas faces de pé e só de longe
  (de `strata_broad_from_m`, 70 m, a `strata_broad_to_m`, 220 m). A distância vem de quem chama (função de include não lê a câmera).
- Na rocha do terreno (`terrain.gdshader`, depois dos estratos) e nas pedras (`sea_rock.gdshader`).

## Medida

Uma conta a mais por pixel de rocha: sem custo à parte (medido no fim do roteiro). Os barrancos da ilha principal têm de 2 a 4 m, e as
bancadas aparecem pouco neles; o efeito é das falésias altas.

## Como testar

- `tests/world/test_phase346_broad_strata.gd`: as bancadas mais largas que os estratos, só de longe, chamadas depois deles nos dois
  shaders, que compilam (com tela).
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase345\depois3\`, depois em
  `F:\ferramentas\capturas\fase346\depois\`.
