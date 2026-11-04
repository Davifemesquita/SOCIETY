# Plano da Fase 316 — Capim pendendo na garganta

**Estado: feita em 04/11/2026**, a segunda do roteiro `docs/plano_fases_315_319.md` (garganta do rio). No Anno, o capim pende da
borda de cima da garganta sobre a rocha; no Society, a franja da Fase 312 só saía nas falésias do mar.

## O plano

- **Arquivos**: `presentation/cliff_fringe_view.gd` e o teste novo.
- **Risco**: franja em todo desnível. Continua valendo só com água a até `SEA_REACH` células para o lado da queda; o vale seco fica
  sem franja.
- **Como testar**: uma garganta feita à mão no teste, a captura do rio e o benchmark.

## O que entrou

- **`CliffFringeView._water_below`** (no lugar do `_sea_below`): a água abaixo da queda é o mar ou o rio (`IslandGrid.Ground.RIVER`).
  O resto da Fase 312 não muda: a queda de `DROP_M`, fora de prédio e estrada, `PER_EDGE` pedaços por lado e um MultiMesh por ilha.

## Medida

71,6 FPS (315: 71,4), GPU 13,0 ms (315: 13,0); ~7 mil primitivas a mais no quadro com tudo visível. Neutra.

## Como testar

- `tests/presentation/test_phase316_gorge_fringe.gd`: os dois lados de uma garganta feita à mão ganham a franja, com o rio para o lado
  da queda; o mesmo vale seco fica sem. O `test_phase312_cliff_fringe.gd` segue passando.
- Captura: `tools/capture_phase280.tscn -- <pasta>` (`05_rio.png`). O antes é o depois da Fase 315
  (`F:\ferramentas\capturas\fase315\depois\`); o depois está em `F:\ferramentas\capturas\fase316\depois\`.
