# Roteiro das Fases 200 a 204 — Gato, poço e carrinho

**01/11/2026.** Segundo ciclo do quinto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono estava usando o
PC). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): a vila densa com os quintais
cheios de miudezas e os carrinhos na rua (`c9_08`), o porto tropical com o guarda-sol no deque e a praia de coqueiros
(`c3_05`). Como sempre, **só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 200 — Gato na porta | um gato sentado no degrau, ao lado da porta de parte das casas (as que não têm cão), virando a cabeça de vez em quando |
| 201 — Poço da vila | o poço de pedra com o telhadinho, o sarilho e o balde numa célula livre junto da rua, perto das casas dos camponeses |
| 202 — Secadouro de peixe | as varas em cavalete com os peixes pendurados secando ao lado das cabanas de pesca das ilhas temperadas |
| 203 — Carrinho de feira | o carrinho de mão com frutas e verduras e o guarda-sol, parado numa célula livre ao lado do mercado |
| 204 — Guarda-sol de palha | os guarda-sóis de folha de palmeira com um banco na areia das praias das ilhas tropicais, perto do porto |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase200.md` a
`docs/plano_fase204.md`), testes, captura e benchmark; as três pastas da suíte passaram no fim (world 420, presentation 357, ui
167). Diferenças do roteiro: o gato vira a cabeça pelo shader e a vista dele (e a da rede da Fase 199) passou a ouvir só o
`house_upgraded` (o `building_state_changed` a refazia a cada troca de estado das fábricas e derrubava o quadro); a busca da
bomba d'água foi separada para o poço e o carrinho usarem a mesma, e ficou guardada até a próxima obra (o carregar tinha subido
0,4 s); os guarda-sóis ficam além do cais de pedra, que é só desenho.
