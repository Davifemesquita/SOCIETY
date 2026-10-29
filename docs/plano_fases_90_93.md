# Roteiro das Fases 90 a 93

**28/10/2026.** O roteiro de `docs/plano_melhorias.md` (Fases 32 a 50) acabou, e desde a 51 cada fase saiu de um pedido do
dono ou da proposta da anterior. Nesta data o dono desligou de vez a cor de época (Fase 37), aprovou tudo o que esperava
por ele (Fases 35 a 47 e 49) e pediu para seguir em sequência pelas fases que faltam. Este roteiro junta o que sobrou das
pendências do `AGENTS.md` e da última proposta, na ordem em que vale fazer.

O que **não** entra por depender de fora: a Fase 48 (Godot 4.8 estável não saiu), a arte do kit de época (Fase 50), o
balanceamento com gente de verdade jogando e o teste do `.exe` em outro PC.

| Fase | O quê | Por quê |
|---|---|---|
| 90 — Daltônico no Windows | achar e corrigir por que `test_colorblind_option_repaints_the_house_needs` falha no Windows do dono (passa no CI) | é o único teste vermelho conhecido; um teste que falha sempre esconde a próxima falha de verdade |
| 91 — Travadas do ultra | medir o ultra na área de trabalho escondida, achar a causa do pior quadro de até ~2 s e corrigir | é a pendência de desempenho mais grave (Fase 32) |
| 92 — Medidas que faltam | 4K, VSync desligado e o executável exportado com o shader baker, medidos | ficaram em aberto desde a Fase 32 |
| 93 — Som e câmera do grand finale | um rufar gerado no código antes da salva e a opção de levar a câmera à praça às 23h | a proposta deixada pela Fase 89 |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura ou benchmark quando couber e um
commit (e push) por fase.
