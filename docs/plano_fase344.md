# Plano da Fase 344 — Sebe alta

**Estado: feita em 07/11/2026**, a quinta e última do roteiro `docs/plano_fases_340_344.md` (campos em faixa). A sebe da Fase 40 era uma
faixa baixa e regular (três bolas iguais por metro, ~0,84 m); a do Anno é alta, de copas irregulares.

## O que entrou

- **A malha** (`CropView.hedge_mesh`): quatro massas de folhagem de tamanhos e alturas diferentes, até ~1,3 m, um pouco mais compridas
  que o metro do lanço (emendam com as vizinhas).
- **Cada lanço de uma altura**: de 0,8 a 1,45 vez (era de 0,85 a 1,15), e um em `HEDGE_TREE_EVERY` (8) vira uma moita alta,
  `HEDGE_TREE_SCALE` (1,35 de largura, 2,3 de altura), como uma árvore pequena na sebe. O muro de pedra seca (na encosta) não muda.

## Medida

Benchmark (o fim do roteiro das Fases 340 a 344): 63,6 FPS, GPU 14,7 ms, carregar 6.915 ms (a 339 na mesma sessão: 63,4 FPS, GPU
14,7 ms). As mesmas instâncias de antes, um pouco maiores.

## Como testar

- `tests/world/test_phase344_tall_hedge.gd`: a peça mais alta e mais comprida; os lanços de alturas diferentes e algumas moitas altas,
  poucas.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase337\depois\`, depois (com as Fases 340 a 344)
  em `F:\ferramentas\capturas\fase344\depois\`.
