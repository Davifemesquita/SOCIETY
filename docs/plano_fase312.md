# Plano da Fase 312 — Capim na borda

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_310_314.md`. No Anno, o capim passa da borda de cima das
falésias e pende sobre a rocha; no Society, a grama parava seca na quina.

## O que entrou

- **`CliffFringeView`** (`presentation/cliff_fringe_view.gd`, `GameScreen.cliff_fringe_view`):
  - `places_of`: na célula de terra do alto de uma falésia (uma vizinha pelo lado `DROP_M` (2 m) mais baixa, a água contando como o
    nível do mar, e o mar a até `SEA_REACH` células naquela direção), sem prédio nem estrada, `PER_EDGE` pedaços de franja por
    lado, o pé `INSET_M` para dentro da borda e o +z para fora da queda;
  - `fringe_mesh`: onze folhas lado a lado saindo do pé, subindo um pouco para fora e pendendo, com a ponta mais clara, no material
    das plantas (balançam com o vento);
  - um MultiMesh por ilha, refeito só na ilha da obra ou da estrada (`IslandDirty`).
- **`IslandGrid.cell_heights`**: a lista das alturas médias das células (a mesma que o `cell_height` lê), para o laço pela grade
  inteira ler os arrays direto.
- O roteiro falava dos tufos do tapete da Fase 286; a franja é uma malha própria, mais comprida, porque o tufo é curto demais
  para pender.

## Medida

72,0 FPS, GPU 12,9 ms (311: 12,9); jogo novo igual (12,4 s). Neutra.

## Como testar

- `tests/presentation/test_phase312_cliff_fringe.gd`: a malha pende para fora; os pedaços no alto das falésias, virados para a
  queda; a estrada na borda tira a franja; a ilha plana sem.
- Captura do ciclo: `tools/capture_phase310.tscn -- <pasta>`; os recortes da borda estão em
  `F:\ferramentas\capturas\fase312\borda_antes.png` e `borda_depois.png`.
