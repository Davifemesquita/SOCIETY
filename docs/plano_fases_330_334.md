# Roteiro das Fases 330 a 334 — Luz e sombra

**07/11/2026.** Primeiro dos seis roteiros da ideação de 07/11/2026 (Fases 330 a 359), sem abrir o Anno (o dono estava no PC). A
referência é o Anno em `c10_01`, `c10_06`, `c10_07` e `c9_04` (`F:\ferramentas\capturas\anno\`), comparado com a semente 1840 depois
das Fases 304 a 329 (`F:\ferramentas\capturas\fase304\depois`, `fase327\depois`, `fase328\b`, `fase329\depois`). **Só a ideia.**

## O diagnóstico

- **Sombra rala.** No Anno cada árvore e cada casa deixa no capim uma sombra escura e de borda firme; a mata tem o pé escuro. No
  Society a sombra do sol quase some no prado (a luz do céu enche demais o lado da sombra).
- **Abeto ciano.** As coníferas saem verde-azuladas, quase ciano, de perto e de longe. No Anno o abeto é verde-escuro, puxando para o
  oliva.
- **Pé solto.** A árvore não "pisa" no chão: falta o escuro de contato logo debaixo da copa.
- **Sem ar.** No Anno a ilha do fundo fica mais azulada e mais clara que a da frente (perspectiva aérea). No Society, desde a Fase 255,
  o longe tem a cor do perto.
- **Prado limão.** O capim de longe é um verde-amarelo claro e liso; no Anno é verde mais fundo, com o capim alto escuro.

## As fases

| Fase | O quê |
|---|---|
| 330 — Sombra funda | a sombra do sol mais escura no chão e na mata (menos luz do céu no lado da sombra, de dia), medida pela razão entre o capim ao sol e na sombra |
| 331 — Abeto sem ciano | o verde das coníferas (`TreeModel`, `far_cool_tint`) puxado do ciano para o verde-escuro oliva |
| 332 — Pé das árvores | uma mancha de sombra de contato debaixo de cada árvore e arbusto, do tamanho da copa |
| 333 — Ar de longe | a névoa de distância leve, azul-acinzentada, só no longe (perspectiva aérea), sem voltar ao cinza de antes da Fase 255 |
| 334 — Prado fundo | o capim de longe mais escuro e menos amarelo, pela régua do brilho do prado contra a mata |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push.

## Estado

- **330 feita em 07/11/2026** (`docs/plano_fase330.md`): a sombra rala era o sol às costas da câmera padrão; o sol girou 180° e a
  luz ambiente de dia caiu para 0,75; capturas em `F:\ferramentas\capturas\fase330\`.
