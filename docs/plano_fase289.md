# Plano da Fase 289 — Beira do barranco

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_285_289.md`. Onde o capim encontra o barranco, o Society
cortava a cor de uma vez: capim verde e logo a rocha cinza. No Anno, o capim acaba numa faixa de terra com pedras e raízes à
mostra.

## O que entrou

- **`shaders/terrain.gdshader`**, depois da lama e antes das estradas: a faixa da beira de cima do barranco.
  - Ela fica onde o chão ainda é capim (fora da rocha, da areia e da lama), na crista (a curvatura dos dados abaixo do meio) e
    com a encosta começando logo adiante. A inclinação dos dados, de 2 em 2 m, sobe antes da normal: `bank_slope` de 0,22 a
    0,32, antes da rocha, que vem com uns 0,34.
  - A borda é recortada por um ruído de 0,6 m, e a faixa é interrompida a trechos (o ruído de ~4,5 m): em parte da beira, o
    capim chega até a rocha.
  - Na faixa vão:
    - a terra das estradas, mais escura (`bank_soil_tint`);
    - as pedras: a textura de rocha `bank_stone_scale` vezes menor, onde a altura dela passa do limite, no cinza da rocha da Fase
      261 e com o relevo dela;
    - as raízes: fios escuros e tortos (`bank_root_color`), só em parte da faixa.
  - `bank_edge` desliga a faixa.
- **A primeira versão** (a terra das estradas sem escurecer, a faixa de 0,18 a 0,3 sem os trechos) saiu laranja, larga e
  contínua demais, e uma linha fina escapava pelas dobras do prado.
- **A captura do ciclo** procura agora um barranco aberto (o pé e o alto sem árvore, 3 m ou mais de desnível) e o fotografa dos
  dois lados.
- **As raízes do recheio**, que o roteiro também previa, ficaram de fora: as raízes desenhadas no chão já aparecem de longe.

## Como testar

- `tests/world/test_phase289_bank_edge.gd`:
  - os uniformes no shader compilado (com tela);
  - a faixa na crista, fora da rocha, da areia e da lama, entre a lama e as estradas, começando antes da rocha;
  - os dados de uma rampa marcando a crista (curvatura abaixo do meio, inclinação subindo).
- Captura: `tools/capture_phase285.tscn -- <pasta>` (o barranco em `05_` e `06_`).
