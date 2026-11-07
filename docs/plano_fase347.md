# Plano da Fase 347 — Leque de cascalho

**Estado: feita em 07/11/2026**, a terceira do roteiro `docs/plano_fases_345_349.md` (pedra grande). No Anno a encosta de pedra derrama
um leque de cascalho no pé; o nosso pé da encosta era capim.

## O que entrou

- **No `shaders/terrain.gdshader`**, logo depois de `land`: o pé da encosta é onde há encosta íngreme (a inclinação dos dados do terreno)
  a `scree_reach_m` (3,5 m) em algum dos quatro lados, e o próprio chão é quase plano (a inclinação dele abaixo de 0,12–0,26) e côncavo
  (a curvatura acima de 0,48–0,56: o pé, não a crista). Ali, recortado por dois ruídos, o cascalho da textura de rocha miúda
  (`scree_scale`) na cor `scree_color`, com o relevo dela; fora da areia, da lama, da rocha e da água. `scree_foot` 0 desliga.
- **As tentativas** (`fase347\depois\` e `depois2\`): com 4 m e o corte baixo, uma faixa clara e lisa no pé, parecendo um caminho; com
  3 m e o corte alto, quase nada.

## Medida

Quatro leituras da textura de dados por pixel de terra (como os seixos da Fase 292): medido no fim do roteiro.

## Como testar

- `tests/world/test_phase347_scree_fan.gd`: o bloco depois de `land`, com a encosta perto, o chão plano e côncavo e fora da areia, da
  lama, da rocha e da água; o shader compila (com tela).
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase346\depois\`, depois em
  `F:\ferramentas\capturas\fase347\depois3\`.
