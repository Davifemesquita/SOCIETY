# Plano da Fase 373 — Sacada do pacote

**Estado: feita em 08/11/2026**, a terceira do roteiro `docs/plano_fases_371_375.md` (peças do MegaKit II).

## O problema

Com as paredes do MegaKit, a sacada corrida dos engenheiros seguia com a grade de ferro fina gerada no código (Fase 18), que de
longe some e não combina com o enxaimel e as janelas de moldura de madeira do pacote.

## O que entrou

- **`tools/pack_megakit.gd`**: `PROPS`, peças soltas do pacote em metros (não no referencial da célula), inteiras e com a camada na
  UV2.x (`_convert_prop`). A primeira é o guarda-corpo de madeira em xis (`Balcony_Cross_Straight`, 132 triângulos), em
  `assets/models/megakit/balcony-cross.res`: 2 m ao longo de x, centrado em z.
- **`BuildingKit._cross_rails`**: com o MegaKit, a sacada dos engenheiros leva um lanço por célula na frente (esticado até a largura
  dela) e um em cada ponta, girado e encolhido até o fundo da sacada, na altura de `CROSS_RAIL_SCALE`. A madeira sai no tom da
  madeira do pacote pelo shader de sempre.
- Os investidores seguem com a balaustrada de pedra (Fase 24), e sem o MegaKit volta a grade de ferro.

## Como testar

- `tests/presentation/test_phase373_cross_rails.gd` confere três coisas:
  - a peça empacotada e a medida dela;
  - a madeira do pacote na casa dos engenheiros;
  - nada mudou nos investidores e no Kenney.
- Captura: `sacadas_floridas.png` no `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase373\dia`).
