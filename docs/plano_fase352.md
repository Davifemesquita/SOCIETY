# Plano da Fase 352 — Beiral saliente

**Estado: feita em 07/11/2026**, a terceira do roteiro `docs/plano_fases_350_354.md` (cidade gasta). O telhado do Anno sai bem além da
parede e faz uma faixa de sombra no alto da fachada; o nosso beiral (0,3 a 0,5 m, Fase 39) quase não a fazia.

## A tentativa

Beirais de 0,4, 0,55 e 0,7 m (`BuildingKit.OVERHANGS_M`) quebraram três testes de geometria que pegavam defeitos de verdade: o telhado
do corpo passava por cima do telhado da ala (Fase 96), o enxaimel saía de debaixo do beiral (Fase 102) e a igreja passava do limite do
campanário (Fase 18). Os beirais voltaram ao que eram.

## O que entrou

- **A sombra do beiral no shader** (`shaders/building_kit.gdshader`): nas paredes de lado, numa faixa de `eave_band_m` (1 m) logo abaixo
  do alto da parede, a cor escurece até `eave_shade` (0,5), como faria o beiral largo. A altura vem do parâmetro de instância `eave_m`
  (a altura do alto da parede acima do piso do modelo, `spec.height_m`, posto pela `BuildingView`), e a do pixel, da origem do modelo
  (`model_floor`, no vértice). Na ala (Fase 96), mais baixa, a faixa não aparece.

## Medida

Uma conta por pixel de parede: sem custo à parte.

## Como testar

- `tests/world/test_phase352_eave_shade.gd`: o parâmetro, a faixa dentro do bloco das paredes pela altura acima do piso, o beiral de
  antes, e o shader compilando com os uniformes (com tela). Os testes de geometria das Fases 18, 96 e 102 seguem passando.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase351\depois\`, depois em
  `F:\ferramentas\capturas\fase352\depois\` (com a faixa de 0,75 m e 0,38; ficou mais forte).
