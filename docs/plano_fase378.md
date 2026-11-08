# Plano da Fase 378 — Lucarna do pacote

**Estado: feita em 08/11/2026**, a terceira do roteiro `docs/plano_fases_376_380.md` (peças do MegaKit III).

## O problema

A lucarna gerada no código (Fase 39) é uma caixa de parede com um telhadinho de duas águas e um vidro liso: de perto, ao lado das
telhas redondas e das janelas de moldura do MegaKit, parecia um bloco.

## O que entrou

- **`tools/pack_megakit.gd`**: a lucarna de telhas redondas do pacote (`Roof_Dormer_RoundTile`, 904 triângulos) nas `PROPS`, em
  metros do pacote (`assets/models/megakit/dormer.res`); as telhas dela na camada 7 (`MI_RoundTiles` entrou em `MATERIALS`).
- **`BuildingKit._mega_dormer`**: com o MegaKit, nas casas dos engenheiros e dos investidores (`MEGAKIT_DORMER_TRIMS`: o telhado
  delas é sempre de telha; nas outras classes há sapê e tábuas), cada lucarna é a do pacote, encolhida a `MEGAKIT_DORMER_SCALE`
  com o pé da frente onde ficava a frente da gerada. Como as águas são menos inclinadas que as do pacote, ela é esticada para trás
  (`mega_dormer_depth`) até o fundo ficar dentro do telhado; se não couber até a cumeeira, fica a gerada.
- **`shaders/building_kit.gdshader`**: as telhas da lucarna (camada 7 na UV2) no tom das águas da casa, pela mesma conta das telhas
  redondas da Fase 371.
- Sem o MegaKit, e nas outras classes, a lucarna gerada de sempre.

## Como testar

- `tests/presentation/test_phase378_pack_dormer.gd`: a peça empacotada e a medida dela; as telhas do pacote nas casas dos engenheiros
  e dos investidores, abaixo da cumeeira e dentro do teto de 40.000 triângulos; o fundo sempre dentro da água; os operários e o
  Kenney com a gerada.
- Captura: `lucarna_do_pacote.png` e `lucarna_de_longe.png` no `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase378\dia`).
