# Plano da Fase 304 — Muro dos quintais

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_300_304.md`. No Anno, os quintais das casas pobres ficam
fechados por muretas e cercas baixas; no Society, o fundo das casas se abria direto para o campo.

## O que entrou

- **`YardWallView`** (`presentation/yard_wall_view.gd`, `GameScreen.yard_wall_view`):
  - `yard_lines`: atrás das casas dos camponeses, operários e artesãos das ilhas temperadas, quando a fileira de células de trás do
    lote está toda livre (terra sem prédio nem estrada), três divisas: o fundo no fim dessa fileira (`INSET_M` para dentro) e os
    dois lados, da quina de trás da casa até ele;
  - `segments`: as divisas da ilha, cada uma uma vez só (a divisa do lado entre duas casas vizinhas é o mesmo segmento, porque os
    lados ficam na divisa exata do lote);
  - pelo hash da casa, mureta de pedra seca (`wall_mesh`: pedras de altura e tom sorteados e a capa) ou cerca de tábuas
    (`fence_mesh`: esteios, duas travessas e tábuas de pé);
  - uma malha só para o arquipélago, no relevo, refeita no quadro seguinte à obra, à demolição, à subida de classe e à estrada.
- O roteiro pedia o muro aberto nas hortas e nos varais; eles ficam na fileira de trás, então ficam **dentro** do quintal fechado.

## Medida

72,5 FPS, GPU 12,7 ms (303: 12,7). Neutra.

## Como testar

- `tests/world/test_phase304_yard_walls.gd`: a fileira livre fecha o quintal (o fundo à distância certa e na largura do lote); uma
  estrada atrás deixa aberto; duas vizinhas dividem o lado; outras classes e as tropicais sem muro.
- Captura: `tools/capture_phase300.tscn -- <pasta>` (`05_fundos_dos_quintais.png`, `06_fundos_de_perto.png`); o antes e depois está
  em `F:\ferramentas\capturas\fase304\antes_depois_fundos.png`.
