# Roteiro das Fases 265 a 269 — Garça, ruína e cruzeiro

**02/11/2026.** Terceiro ciclo do oitavo pedido "pode continuar" do dono (os dois primeiros foram da cor viva, a pedido dele). O
Anno **não foi aberto** (esta sessão não tem o controle da tela); as ideias saem das capturas guardadas
(`F:\ferramentas\capturas\anno\`: os rios e as encostas `c9_14`, a costa `c6_02`, o campo `c4_02`). Como sempre, **só a ideia**:
nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 265 — Garças no rio | a garça-real de pé na água rasa da margem dos rios, longe das vilas, virando de um lado para o outro |
| 266 — Ruínas de muro | pedaços de muro de pedra seca caídos, com o musgo, no campo aberto das ilhas temperadas |
| 267 — Espinheiro florido | o arbusto de espinheiro coberto de flor branca na beira da mata das ilhas temperadas |
| 268 — Casco naufragado | o casco velho de um navio, só a quilha e as cavernas, na praia baixa longe das vilas |
| 269 — Cruzeiro no morro | a cruz de pedra sobre o degrau no ponto mais alto e livre de cada ilha temperada |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push. Peça nova do
recheio vai no fim do enum e da lista dela.

## Estado

**Concluído em 02/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase265.md` a `docs/plano_fase269.md`),
testes, captura e benchmark (todas neutras). As três pastas da suíte passaram no fim (world 631, presentation 373, ui 167).
Diferenças do roteiro: a rede das garças ficou mais fina (com 17 células saía uma garça só no arquipélago); o espinheiro ganhou
mais flor (com pouca parecia uma árvore com neve); a captura dos cascos e dos espinheiros olha de fora da mata.
