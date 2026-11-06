# Roteiro das Fases 325 a 329 — Prado e mata

**05/11/2026.** Sétimo ciclo da ideação de 02/11/2026, sem abrir o Anno. A referência é o campo e a mata do Anno em `c10_01` e
`c10_09` (`F:\ferramentas\capturas\anno\`), comparados com a semente 1840 depois das Fases 320 a 324 (`01_falesia`, `02_praia`,
`03_mar_de_cima` e `05_rio` do `tools/capture_phase280.tscn`, em `F:\ferramentas\capturas\fase325\diag\`). **Só a ideia.**

## O diagnóstico

- **Prado em xadrez.** O capim aberto tem quadrados claros e escuros alinhados com os eixos, de perto (90 m) e de cima (420 m).
  No Anno, o prado varia em manchas sem forma de grade.
- **Copa verde-limão.** As copas das folhosas são de um verde-limão claro e saturado, todas no mesmo tom. No Anno, a mata é de
  um verde mais fundo e frio, com cada árvore num tom.
- **Copa em bolhas.** De perto, cada massa de folhagem aparece como uma bola lisa e clara, e a copa vira um cacho de balões. No
  Anno, a copa é uma massa só, com o recorte das folhas e a sombra por dentro.
- **Capim espetado.** No prado de perto, os tufos do tapete de capim (Fase 286) saem como fios verdes soltos, altos e claros,
  espalhados como pelos sobre o chão. No Anno, o capim é rente e cerrado, no tom do chão.
- **Praia em degraus.** Na praia de seixos, a beira da areia com a água e a faixa de seixos fazem escadinha (os cantos das
  células) e um degrau marrom entre as duas. No Anno, a beira da praia é uma curva.

## As fases

| Fase | O quê |
|---|---|
| 325 — Prado sem xadrez | as manchas do prado (Fase 285) por um ruído girado e torcido, igual no terreno e no tapete de capim, sem a grade do ruído de valor |
| 326 — Mata no tom | a cor das folhosas (`TreeModel`) mais funda e menos saturada, e um tom sorteado por árvore |
| 327 — Copa sem bolhas | a luz da copa pela forma inteira (as normais das massas puxadas para a da copa e a sombra por dentro), sem o brilho de cada massa |
| 328 — Capim rente | o tapete de capim mais baixo, mais cerrado e no tom do chão debaixo dele |
| 329 — Praia em curva | a beira da areia e dos seixos sem a escadinha das células |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push.

## Estado

- **325 feita em 05/11/2026** (`docs/plano_fase325.md`): o xadrez eram as manchas do prado da Fase 285 (ruído de valor com corte estreito),
  não a repetição da textura; capturas em `F:\ferramentas\capturas\fase325\`.
- **326 feita em 05/11/2026** (`docs/plano_fase326.md`): a mata em verde fundo, com ~0,73 do brilho do prado (era 1,1; no Anno ~0,7);
  capturas em `F:\ferramentas\capturas\fase326\`.
