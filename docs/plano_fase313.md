# Plano da Fase 313 — Fendas com mato

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_310_314.md`. No Anno, as fendas da face das falésias têm
arbustos e capim agarrados; no Society, a face era nua.

## O que entrou

- **`ScatterView.Kind.CLIFF_SHRUB`**, no fim do enum e das listas `OPEN`, `NEAR_FOREST` e `NEAR_SEA` (o sorteio das peças de antes
  não muda), entre as `PLANTS` (balança): uma moita de três massas achatadas com um leque de capim (`cliff_shrub_mesh`), só nas
  células de desnível `CLIFF_SHRUB_MIN_RELIEF_M` (2 m) entre os cantos, em `CLIFF_SHRUB_CHANCE` delas, nas temperadas e nas
  tropicais.
- Meio deitada para fora da face (a normal da célula pela metade), o pé enterrado, `CLIFF_SHRUB_SCALE` (1,8) vezes o tamanho
  sorteado e posta na parte de cima da célula: no meio dela e menor, ela ficava dentro das rochas encaixadas da falésia (Fase 56)
  ou sumia vista de cima (conferido com a moita pintada de magenta).

## Medida

71,9 FPS, GPU 12,9 ms (312: 12,9). Neutra.

## Como testar

- `tests/world/test_phase313_cliff_shrubs.gd`: o fim do enum e das listas; as moitas só nas faces, deitadas para fora; a malha
  pequena.
- Captura do ciclo: `tools/capture_phase310.tscn -- <pasta>`; os recortes estão em
  `F:\ferramentas\capturas\fase313\fenda_antes3.png` e `fenda_depois3.png`.
