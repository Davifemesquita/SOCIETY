# Plano da Fase 370 — Portas variadas

**Estado: feita em 08/11/2026**, a última do roteiro `docs/plano_fases_366_370.md` (acabamento do MegaKit).

## O problema

Todo prédio do MegaKit tinha a mesma porta (a de uma tábua, `Door_1_Flat`).

## O que entrou

- **`tools/pack_megakit.gd`**:
  - empacota a porta de quatro e a de oito tábuas no mesmo vão (`wall-door-4`, `wall-door-8`);
  - ganhou a camada 6 nas pilhas de textura, o metal das ferragens (`T_MetalOrnaments`). Sem ela as ferragens caíam na
    textura de madeira e saíam como uma treliça listrada. As pilhas passaram de 6 para 7 fatias (os `.import`).
- **`BuildingKit.MEGAKIT_DOORS`** e **`Spec.door_style`** (na chave): a porta pelo tipo do prédio (`door_style_of`, um hash
  aritmético do nome, estável entre versões do motor).
- **As casas ficam com a porta de uma tábua**: as outras passavam a casa dos operários de 1,2 vez o peso da do Kenney
  (`test_phase362_window_weight`).
- **A porta de duas tábuas (`Door_2_Flat`) ficou de fora**: tem ~4 mil vértices, cinco vezes as outras.
- As fotos do menu foram refeitas (`tools/bake_building_photos.tscn`), pelas Fases 366 a 370.

## Como testar

- `tests/presentation/test_phase370_doors.gd` confere quatro coisas:
  - as peças empacotadas;
  - o sorteio estável e variado;
  - as casas com a porta simples;
  - a porta do tipo nos outros prédios, que muda a malha.
- Capturas: `tools/capture_phase95.tscn`.
