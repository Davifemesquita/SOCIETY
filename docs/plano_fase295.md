# Plano da Fase 295 — Espuma em trechos

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_295_299.md`. Longe da areia, uma linha branca contínua
corria paralela à costa por centenas de metros.

## De onde vinha a linha

O laboratório da captura (`CAPTURA_MAR=espuma` no `tools/capture_phase295.tscn`) troca um parâmetro da água por vez. A linha anda
com o tempo e some ao tirar o alcance das bandas. Ela é a última banda de espuma da Fase 35 (a ~9 m da linha d'água, o fim de
`shore_foam_width_m`): numa costa reta, a crista de seno da banda vira uma linha inteira. Não era a espuma das pedras (Fase 293):
a linha já estava nas capturas da Fase 284. O perfil da praia (`CAPTURA_MAR=perfil`) mostra a plataforma plana a −1,2 m por ~80 m,
sem banco de areia.

## O que entrou

- **`shaders/water.gdshader`**, nas bandas da Fase 35:
  - cada banda se quebra em trechos de `band_piece_m` (6 m) por um ruído de valor (o do recife, sem seno);
  - a falta cresce de zero junto da areia (`band_whole_m`, 2,5 m) até `band_gap` (0,55) no fim do alcance: a espuma que chega na
    areia continua inteira;
  - cada onda sorteia os seus trechos (o número da crista entra no ruído). O número só muda no vale, onde a banda não aparece,
    então nada pisca.

## Medida

GPU 12,4 ms (294: 12,6). Neutra.

## Como testar

- `tests/world/test_phase295_broken_bands.gd`:
  - a quebra depois da banda, crescendo de `band_whole_m` até o alcance, com a crista no ruído;
  - o número da crista só muda no vale;
  - o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase295.tscn -- <pasta>` (`02_praia.png` e `02b_praia_de_perto.png`); `CAPTURA_MAR=espuma` para o
  laboratório.
