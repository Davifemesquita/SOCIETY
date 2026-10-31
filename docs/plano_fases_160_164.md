# Roteiro das Fases 160 a 164 — Cunhal, deriva e horta

**31/10/2026.** Segundo ciclo do pedido "pode continuar" do dono. Desta vez o Anno **não foi aberto**: o dono estava usando o
PC (outras sessões na tela), e abrir o jogo tomaria a tela e o mouse dele. As ideias saem das capturas que já estavam guardadas
(`F:\ferramentas\capturas\anno\`, fora do repositório): as quinas de pedra clara das casas de tijolo do centro (`c8_02`), os
troncos secos esbranquiçados largados nas pedras da costa (`c9_13`), o cascalho solto que escorre pelas encostas de rocha
(`c9_13`), as hortas atrás das casas (`c8_02`) e os canteiros de pedra em volta das árvores da rua (`c8_02`). Como sempre,
**só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 160 — Cunhais de pedra | blocos de pedra clara alternados nas quinas das casas dos artesãos, engenheiros e investidores |
| 161 — Madeira à deriva | troncos secos, esbranquiçados pelo sal, largados na praia e nas pedras da costa |
| 162 — Cascalho nas encostas | pedrinhas soltas espalhadas pelas encostas íngremes, mais embaixo |
| 163 — Horta no quintal | canteiros de horta (couve, alface, feijão na estaca) atrás de parte das casas dos camponeses e operários |
| 164 — Caldeira das árvores | o anel de pedra em volta do pé de cada árvore da alameda nas ruas calçadas |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 31/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase160.md` a
`docs/plano_fase164.md`), testes, captura e benchmark. Diferenças do roteiro: os cunhais (160) ficaram só nos artesãos e
engenheiros (a casa dos investidores já está no teto de triângulos e tem a parede de pedra clara); a madeira à deriva (161) só
no chão pouco inclinado; os testes das peças do recheio passaram a conferir a ordem relativa na lista (o da árvore seca quebrou
quando a madeira à deriva entrou depois dela); a horta (163) ficou só com couve, alface e feijão.
