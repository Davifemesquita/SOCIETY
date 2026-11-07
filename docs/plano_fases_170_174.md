# Roteiro das Fases 170 a 174 — Laterita, lenha e carrinho

**31/10/2026.** Quarto e último ciclo do pedido "pode continuar" do dono. O Anno de novo **não foi aberto** (o dono usava o PC
naquele momento). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): a terra vermelha
na beira dos rios da ilha tropical (`c3_06`), a lenha empilhada na parede das casas pobres, os carrinhos de mão e as tinas nos
pátios das oficinas e o quintal de terra das casas do bairro dos operários (`c4_02`). Como sempre, **só a ideia**: nenhum
modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 170 — Barranco de terra vermelha | a margem dos rios das ilhas tropicais em laterita vermelha, no lugar da lama escura |
| 171 — Lenha na parede | a pilha de lenha encostada na parede do lado de parte das casas dos camponeses e operários |
| 172 — Carrinho de mão | o carrinho de mão de madeira, parado no pátio de chão batido de parte das oficinas |
| 173 — Tina de lavar | a tina de madeira com a tábua de esfregar ao lado do varal das casas |
| 174 — Banco na porta | o banco de tábua encostado na parede da frente, ao lado da porta, de parte das casas dos camponeses |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 31/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase170.md` a
`docs/plano_fase174.md`), testes, captura e benchmark (173 e 174 medidas juntas). Diferenças do roteiro: a lenha (171) e o
banco (174) pediram uma rua nova de casas espaçadas na captura das ruas (com as casas coladas não há célula do lado); o banco
fica dentro do quintal cercado, além dos vasos da porta.
