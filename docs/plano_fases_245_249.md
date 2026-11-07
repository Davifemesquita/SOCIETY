# Roteiro das Fases 245 a 249 — Coelho, cogumelo e pedra

**01/11/2026.** Terceiro ciclo do sétimo pedido "pode continuar" do dono. O Anno **não foi aberto** (esta sessão não tem o controle
da tela). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): os prados e a beira da mata
(`c3_05`, `c9_14`), o estaleiro e o porto (`c5_06`), os campos (`c6_09`). Como sempre, **só a ideia**: nenhum modelo, textura,
arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 245 — Coelhos no prado | coelhos pastando no capim aberto das ilhas temperadas, longe das vilas, sentando e erguendo as orelhas de vez em quando |
| 246 — Tronco caído com cogumelos | troncos velhos caídos na beira da mata, cobertos de musgo, com os chapéus dos cogumelos saindo da casca |
| 247 — Madeira curvada no estaleiro | a pilha de tábuas e as cavernas curvas de madeira esperando no lado de cada estaleiro |
| 248 — Caixotes de vidro | os caixotes de vidraça com palha e as chapas de vidro de pé num cavalete no lado da vidraria e da janelaria |
| 249 — Montes de pedra nos campos | os montes de pedras tiradas da terra arada num canto de parte dos campos das ilhas temperadas |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase245.md` a `docs/plano_fase249.md`),
testes, captura e benchmark; as três pastas da suíte passaram no fim (world 570, presentation 368, ui 167), depois de um conserto:
o teste das algas (Fase 239) conferia que elas eram a última peça do enum do recheio, e o tronco caído entrou depois delas; agora
ele e o do tronco conferem só a ordem relativa, como os das peças de antes. Diferenças do roteiro: o musgo do tronco teve de subir
(saía enterrado na casca); a madeira do estaleiro nunca fica do lado do mar (a carreira); o monte de pedra ficou menor para caber
na cabeceira do campo. A primeira medida da Fase 245 saiu inválida (um `.gd` editado com o benchmark rodando) e foi refeita.
