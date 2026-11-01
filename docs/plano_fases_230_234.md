# Roteiro das Fases 230 a 234 — Sinal, cormorão e castanha

**01/11/2026.** Quarto e último ciclo do sexto pedido "pode continuar" do dono. O Anno **não foi aberto** (esta sessão não tem o
controle da tela). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): o porto com as
estacas e as aves (`c5_06`), a vila com as janelas e as esquinas (`c9_08`, `c4_02`). Como sempre, **só a ideia**: nenhum modelo,
textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 230 — Sinal no trilho | o poste de sinal de braço com o lampião na ponta de cada linha de trilho |
| 231 — Cormorões nas estacas | os cormorões de asas abertas secando no alto das estacas da Fase 186 |
| 232 — Tapete na janela | o tapete estendido no peitoril de uma janela de cima de parte das casas |
| 233 — Cabines de banho | as cabines de banho de rodas, listradas, na areia das praias temperadas perto do entreposto |
| 234 — Fogareiro de castanhas | o carrinho do fogareiro de castanhas com as brasas acesas à noite numa esquina calçada |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase230.md` a `docs/plano_fase234.md`),
testes, captura e benchmark. Diferenças do roteiro: os cormorões ficam num feixe sim, outro não, na ordem dos feixes (pelo hash do
lugar, o cais da semente 1840 ficava sem nenhum), e sem sombra; o tapete tem a franja em poucos fios e não faz sombra (a primeira
malha punha +50 mil primitivas na cidade do benchmark); as brasas do fogareiro acendem como vidro, não como chama. A máquina passou
ao estado lento no meio do ciclo (da Fase 230 em diante, ~70 FPS): as Fases 230 e 231 foram conferidas com um A/B no mesmo estado.
