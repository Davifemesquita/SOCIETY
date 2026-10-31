# Roteiro das Fases 140 a 144 — Toco, bote e boia

**31/10/2026.** Sexto ciclo do pedido do dono ("pode continuar, faça mais 4 ciclos"): abrir o Anno, idealizar e fazer. As
ideias saem de capturas novas da ilha do Anno 1800 dele (`F:\ferramentas\capturas\anno\c6_*.png`, fora do repositório) e
das do ciclo anterior: a clareira de corte em volta do lenhador com as toras empilhadas, a árvore seca e nua na beira da
falésia, os botes a remo espalhados pela água do porto, a cerquinha de estacas brancas na frente das casas e os objetos
boiando perto da costa (`c6_01`, `c6_03` a `c6_05`, `c5_02`, `c5_08`). Como sempre, **só a ideia**: nenhum modelo,
textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 140 — Clareira do lenhador | em volta de cada lenhador, parte das células de mata perde as árvores no desenho e fica com os tocos e uma tora caída |
| 141 — Árvore seca | árvores secas e nuas, de galhos tortos, espalhadas de vez em quando pela beira da mata e pela costa |
| 142 — Botes no porto | botes a remo com o remador dando voltas na água diante de cada entreposto, os remos batendo |
| 143 — Cerca de estacas | cerquinha de estacas de madeira caiada com o portão na frente das casas dos operários |
| 144 — Boias no porto | boias de amarração pintadas boiando e balançando no mar em volta do cais de cada entreposto |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 31/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase140.md` a
`docs/plano_fase144.md`), testes, captura e benchmark. Diferenças do roteiro: a clareira (140) só refaz o corte quando um
lenhador entra ou sai (a primeira versão refazia tudo a cada prédio e encareceu a obra em 11 ms); a árvore seca (141) ficou
mais rara e escura depois da primeira captura; as boias (144) foram para além do cais de pedra.
