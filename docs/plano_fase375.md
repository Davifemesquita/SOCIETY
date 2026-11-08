# Plano da Fase 375 — Cerca do pacote

**Estado: feita em 08/11/2026**, a última do roteiro `docs/plano_fases_371_375.md` (peças do MegaKit II).

## O problema

O quintal cercado dos camponeses (Fase 13) usava a cerca do Kenney, de ripas lisas, ao lado do enxaimel e das janelas do MegaKit.

## O que entrou

- **`tools/pack_megakit.gd`**: as peças soltas (`PROPS`, Fase 373) levam uma transformação inteira, não só o deslocamento. A
  cerca de tábuas do pacote (`Prop_WoodenFence_Single`, 40 triângulos) vai para o referencial da peça `fence` do Kenney:
  - a face em x = 0,5;
  - de z −0,5 a 0,5;
  - 0,38 de altura.
- **Com o MegaKit, o `BuildingKit._parts_of` acha a `assets/models/megakit/fence.res` pelo nome** e a põe no lugar da do Kenney,
  sem mudar a montagem do quintal. O portão segue o do Kenney.

## Como testar

- `tests/presentation/test_phase375_pack_fence.gd` confere duas coisas:
  - a peça no referencial da do Kenney;
  - a troca pelo kit em uso.
- Captura: `banco_na_porta.png` no `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase375\dia`).
- As fotos do menu foram refeitas (`tools/bake_building_photos.tscn`), pelas Fases 371 a 375.
