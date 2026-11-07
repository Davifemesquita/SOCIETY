# Plano da Fase 293 — Espuma nas pedras

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_290_294.md`. Na Fase 281, a espuma por profundidade do Ocean
ficou presa a 3 m da linha d'água, para não cobrir a praia rasa. Isso também tirou a linha branca em volta do que entra na água
longe da costa: as estacas, as boias, os degraus do cais, os cascos e as pedras soltas. No Anno, toda pedra na água tem a
espuma colada nela.

## O que entrou

- **`shaders/water.gdshader`**, no bloco da espuma por profundidade (`SHORE_FOAM`): um anel fino.
  - Onde: só onde o objeto fica a menos de `rock_foam_m` (0,45 m, ao longo da vista) da superfície, e longe da linha d'água.
    Perto dela, a espuma da Fase 281 já faz o serviço.
  - No raso da praia a diferença de profundidade cresce devagar, e o anel não se forma.
  - Pulsa devagar, quebrado pela textura da espuma, e fica na metade no rio (Fase 283).
  - Entra por `max` com a espuma de antes: não reabre a faixa larga.
- **A conferência**: a captura das estacas da Fase 186 (`tools/capture_phase186.tscn`) mostra o anel nas estacas, nas boias e nos
  degraus do cais.
  - Na captura do ciclo, as rochas da falésia ficam coladas na linha da costa, onde a espuma já existia.
  - As estacas não viram coluna branca (o problema da Fase 186 era a faixa larga de 2 a 6 m do Ocean).

## Medida

GPU 12,5 ms (292: 12,6). Neutra.

## Como testar

- `tests/world/test_phase293_rock_foam.gd`:
  - o anel depois do corte da Fase 281 e do rio da Fase 283, longe da linha, entrando por `max`, mais fino que a faixa do Ocean;
  - o shader compilando com o uniforme novo (com tela).
- Capturas: `tools/capture_phase290.tscn -- <pasta>` e `tools/capture_phase186.tscn -- <pasta>` (as estacas).
