# Roteiro das Fases 335 a 339 — Estrada no jeito do Anno

**07/11/2026.** Segundo dos seis roteiros da ideação de 07/11/2026, sem abrir o Anno. A referência são as estradas do Anno em
`c10_01`, `c10_06`, `c10_09` e `c2_05` (`F:\ferramentas\capturas\anno\`), comparadas com a vila e o campo da semente 1840. **Só a
ideia.**

## O diagnóstico

- **Estrada que some.** No Anno a estrada de terra é uma faixa clara, cinza-bege, mais clara que o capim e de borda firme: lê-se de
  longe. No Society (Fase 38) ela é marrom e quase do brilho do capim, e some a 200 m.
- **Superfície lisa.** De perto, a estrada do Anno tem cascalho e pedrinhas; a nossa tem sulcos numa terra lisa.
- **Mesma largura em todo lugar.** No Anno a rua da vila é larga e a estrada do campo estreita. A nossa tem uma largura só.
- **Beira nua.** Fora da vila o Anno tem capim alto e escuro junto da estrada; a nossa encosta no capim baixo.
- **Campo sem marco.** Ao longo da estrada do campo o Anno tem cercas e mourões de vez em quando.

## As fases

| Fase | O quê |
|---|---|
| 335 — Estrada clara | a terra batida das estradas (`terrain.gdshader`, camada da estrada) mais clara e cinza-bege, com a borda mais firme |
| 336 — Cascalho na estrada | pedrinhas e cascalho miúdo na superfície da estrada de terra, mais no meio e menos nos sulcos |
| 337 — Rua larga na vila | a estrada mais larga onde passa entre casas e mais estreita no campo, pela máscara das estradas |
| 338 — Capim na beira | uma faixa de capim alto e escuro junto das estradas de campo, no terreno e no tapete de capim |
| 339 — Mourões na estrada | cercas baixas de mourões e travessas em trechos das estradas de terra fora da vila |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push.

## Estado

- **335 feita em 07/11/2026** (`docs/plano_fase335.md`): a terra das estradas cinza-bege e mais clara; capturas em
  `F:\ferramentas\capturas\fase335\`.
- **336 feita em 07/11/2026** (`docs/plano_fase336.md`): o cascalho de Voronoi na estrada de terra, só de perto; capturas em
  `F:\ferramentas\capturas\fase336\`.
