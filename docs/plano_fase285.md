# Plano da Fase 285 — Manchas do prado

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_285_289.md` (o prado no jeito do Anno). Todo o capim tinha
o mesmo verde-amarelado das Fases 257 e 262. No Anno, o prado tem manchas de capim alto mais escuro e de capim baixo e seco mais
claro.

## O que entrou

- **`shaders/terrain.gdshader`**, logo depois da cor da grama: as manchas pelo ruído de `meadow_patch_m` (9 m), com uma oitava
  2,7 vezes menor que recorta a borda.
  - O capim alto (`meadow_tall_tint`, mais escuro e verde) ganha o relevo da textura da grama de novo,
    `meadow_tall_detail` (2,3) vezes menor, por cima.
  - O capim baixo (`meadow_short_tint`) é mais claro e seco.
  - `meadow_patches` (1) liga ou desliga.
- **Só na grama**: a mata, a estrada, a areia, a rocha e a lama entram por cima dela depois. Vale também nas ilhas tropicais.
- **A primeira medida**, com tons mais perto de 1, quase não aparecia nas capturas. Ficou com o alto a (0,64; 0,79; 0,58) e o
  baixo a (1,22; 1,15; 0,8), e as faixas um pouco mais largas.

## Como testar

- `tests/world/test_phase285_meadow_patches.gd`:
  - os uniformes no shader compilado (com tela);
  - o bloco das manchas depois da cor da grama e antes dos outros chãos, sem tocar neles;
  - o alto mais escuro e verde, o baixo mais claro e amarelo;
  - a mancha entre 3 e 12 m.
- Captura: `tools/capture_phase285.tscn -- <pasta>`, a captura do ciclo do prado. Mostra o prado aberto fora da vila de perto,
  de meia distância e de cima, um canteiro de papoulas e a borda de cima de um barranco.
