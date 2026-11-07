# Plano da Fase 300 — Telhas gastas

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_300_304.md`. Depois da cor viva (Fase 258), os telhados de
terracota saíam todos do mesmo laranja limpo. No Anno, cada telhado tem o tom dele e está gasto.

## O que entrou

- **`shaders/building_kit.gdshader`**, nas águas de telha (não no sapê, na ardósia nem na chapa):
  - **tom por casa**: a cor multiplicada entre `roof_tone_dark` e `roof_tone_light` pelo `roof_pick`, um sorteio pelo lugar do
    prédio (o mesmo hash inteiro dos postigos da Fase 177, outros bits);
  - **telhas trocadas**: uma em cada `roof_swap_share` (5%) mais clara e mais viva, pela telha (`roof_tile_at`, a mesma conta das
    fileiras da Fase 95); só de perto, como as telhas;
  - **musgo** (`roof_moss`) em manchas, mais no lado da sombra fixo (o norte, como na rocha da Fase 291) e mais nas casas de
    sorteio alto; de longe também;
  - **sujeira escorrida**: riscos finos ao longo da água, escurecendo `roof_streak_strength`.
- **Musgo demais no primeiro ajuste**: ele cobria quase todo o telhado de tábuas dos galpões. Passou a manchas menores
  (`roof_moss_strength` 0,45 e o corte mais alto).

## Medida

GPU 12,6 ms (299: 12,6). Neutra.

## Como testar

- `tests/presentation/test_phase300_worn_roofs.gd`:
  - o sorteio da casa no hash dos postigos;
  - o gasto só no ramo das telhas;
  - as telhas trocadas raras;
  - o shader compilando com os uniformes novos (com tela).
- Captura do ciclo: `tools/capture_phase300.tscn -- <pasta>` (a vila de cima e de perto, os telhados e os quintais).
