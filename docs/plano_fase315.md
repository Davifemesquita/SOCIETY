# Plano da Fase 315 — Capim no alto da garganta

**Estado: feita em 04/11/2026**, a primeira do roteiro `docs/plano_fases_315_319.md` (garganta do rio). No Anno, o capim vem até a
beira da garganta do rio; no Society, o alto das paredes tinha uma faixa larga de lama marrom-alaranjada, e havia manchas de lama
soltas no planalto. Desde a Fase 283, acima de `gravel_top_m` (2,5 m) a margem voltava à lama de antes.

## O plano

- **Arquivos**: `shaders/terrain.gdshader` (o corte da lama), `world/terrain/terrain_view.gd` (liga nas temperadas), o teste novo.
- **Risco**: a lama também marca o leito seco da cabeceira e a margem baixa. Por isso o corte vale só acima de `gravel_top_m`, onde o
  cascalho já tinha acabado. As tropicais ficam de fora, com a laterita da Fase 170.
- **Como testar**: o teste do shader e da `TerrainView`, a captura do rio antes e depois e o benchmark.

## O que entrou

- **`shaders/terrain.gdshader`**: `high_bank_grass` (0 por padrão) e `high_bank_fade_m` (1,2 m). Logo depois do `mud`, acima de
  `gravel_top_m`, a lama some no capim em `high_bank_fade_m`, com a borda recortada pelo mesmo ruído da lama (`ragged`). O corte
  vem antes da areia, da mata e da camada da lama, que leem o `mud`.
- **`TerrainView`**: põe `high_bank_grass` em 1 nas temperadas, junto do `gravel`.
- Na crista sobra um fio de terra: é a beira do barranco da Fase 289, que a lama escondia e agora aparece.

## Medida

71,4 FPS (314: 72,0), GPU 13,0 ms (314: 12,8). Objetos, draw calls e primitivas iguais. A conta nova é um `smoothstep` por pixel
de terreno: a diferença está dentro do que a máquina oscila entre rodadas. Neutra.

## Como testar

- `tests/world/test_phase315_high_bank_grass.gd`: o shader com os uniformes novos (com tela); o corte depois do `mud` e antes das
  camadas que o usam, acima de `gravel_top_m` e desligado por padrão; a `TerrainView` ligando nas temperadas e não nas tropicais.
- Captura: `tools/capture_phase280.tscn -- <pasta>` (`05_rio.png` e `05b_leito_seco.png`). O antes e depois está em
  `F:\ferramentas\capturas\fase315\antes\` e `depois\`. O antes saiu do mesmo código, com `high_bank_grass` em 0.
