# Plano da Fase 363 — Testes da paleta

**Estado: feita em 07/11/2026**, a terceira do roteiro `docs/plano_fases_361_365.md` (ligar o MegaKit). O MegaKit segue desligado
por padrão; a suíte agora passa com ele ligado (`SOCIETY_MEGAKIT=1`) e desligado.

## O problema

Com o MegaKit ligado, ~800 asserções falhavam: os testes que procuram as células da paleta do Kenney (toldo, tijolo da chaminé,
postigo, cortina, a capa das telhas) pegavam a UV de verdade das peças do pacote, que nem usam a paleta; e os que conferem os
enfeites do Kenney (vergas, peitoris, arcos de pedra, o vidro e a cruz gerados, o vão das janelas acesas) não valem para a janela
do pacote, que traz a moldura dela.

## O que entrou

- **`BuildingKit.reset_megakit()`**: volta ao padrão (relê a variável) e esquece as malhas; todo teste que mexe na chave chama no
  fim.
- Os testes do que é do Kenney rodam com ele (`use_megakit(false)` no começo): `test_building_kit`, `test_phase39_buildings` (o
  vidro gerado), `test_phase95_roof_tiles`, `test_phase99_arches`, `test_phase101_awnings`, `test_phase104_lanterns_chimneys`,
  `test_phase177_shutters`, `test_phase217_curtains` e `test_window_lights`. O MegaKit tem os dele (Fases 360 a 362).
- **O lote e o orçamento valem para os dois kits**: `test_every_building_but_fields_piers_and_decorations_gets_a_model_inside_its_area`
  confere o Kenney e o MegaKit, com o teto de triângulos em **40.000** (a igreja e a universidade do MegaKit chegam a ~35 mil).
- `test_phase102_jetty`: a janela acesa do MegaKit fica mais para dentro (no vidro do fundo da parede); a frente vai até 0,6 m.

## Como testar

- `testes_janela_oculta.ps1 res://tests/presentation` com e sem `SOCIETY_MEGAKIT=1`: 425 casos, nenhuma falha nos dois.
- `testes_society.ps1 res://tests/world` com o MegaKit ligado: só o vidro da Fase 39 falhava, agora no Kenney.
