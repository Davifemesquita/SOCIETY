# Roteiro das Fases 235 a 239 — Cervo, âncora e marco

**01/11/2026.** Primeiro ciclo do sétimo pedido "pode continuar" do dono. O Anno **não foi aberto** (esta sessão não tem o controle
da tela). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): a mata e os prados
(`c3_05`, `c9_14`), o porto (`c5_06`), a cidade com a prefeitura (`c4_02`). Como sempre, **só a ideia**: nenhum modelo, textura,
arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 235 — Cervos na beira da mata | pequenos grupos de cervos pastando na beira da mata das ilhas temperadas, longe das vilas, erguendo a cabeça de vez em quando |
| 236 — Âncora no cais | a âncora velha de ferro deitada no cais de pedra com a amarra enrolada ao lado |
| 237 — Marco de légua | os marcos de pedra ao longo das estradas de terra compridas fora das vilas |
| 238 — Bandeira na prefeitura | o mastro com a bandeira tremulando ao vento no alto do telhado da prefeitura |
| 239 — Algas na praia | os montes de algas e sargaço deixados pela maré na areia junto do mar |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase235.md` a `docs/plano_fase239.md`),
testes, captura e benchmark; as três pastas da suíte passaram no fim (world 533, presentation 368, ui 167). Diferenças do
roteiro: a âncora fica no fundo do cais, não junto da beira (as peças das fases de antes já tomavam todos os lanços da beira); a
bandeira da prefeitura sobe do remate da cúpula (o `BuildingKit.dome_finial` agora é a conta única do remate); as algas viraram uma
faixa de bolos encostados (soltos, os bolos pareciam bichos e depois contas). A máquina seguiu no estado lento (~70 FPS) o ciclo
todo; todas as fases ficaram neutras nele.
