# Plano da Fase 311 — Blocos caídos

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_310_314.md`. No Anno, o pé das falésias tem um amontoado de
blocos caídos dentro da água; no Society, a rocha da falésia descia até a água e parava ali.

## O que entrou

- **`RockView`**, `Kind.TALUS` (no fim do enum): no `_cliffs`, depois de cada rocha de falésia, de `TALUS_BLOCKS` (2 a 4) blocos da
  `RockModel` em volta do primeiro canto de mar abaixo dela (`TALUS_SPREAD_M`), com o pé abaixo da água (o fundo, preso entre
  −1,2 m e 0, menos 0,3 m) e o topo de `TALUS_TOP_M` (0,25 a 1,1 m) acima dela, tortos. Saem do mesmo sorteio da rocha de cima,
  depois dela: as rochas de falésia de antes não mudam. Só onde a obra não cabe (`_rock_allowed`).
- A espuma em volta é a das pedras da Fase 293 (anel do que entra na água) e o borrifo da Fase 123 conta os blocos novos.

## Medida

71,9 FPS, GPU 12,9 ms (310: 12,9); ~340 mil primitivas a mais no quadro com tudo visível. Neutra.

## Como testar

- `tests/presentation/test_phase311_talus.gd`: de 2 a 4 blocos por rocha de falésia, meio dentro da água, junto da borda; as rochas
  de falésia iguais.
- Captura do ciclo: `tools/capture_phase310.tscn -- <pasta>`; os recortes do pé da falésia estão em
  `F:\ferramentas\capturas\fase311\pe_antes.png` e `pe_depois.png`.
