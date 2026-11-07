# Roteiro das Fases 210 a 214 — Pombo, mó e buxo

**01/11/2026.** Quarto e último ciclo do quinto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono estava usando
o PC). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): a vila densa com os
telhados e as oficinas (`c9_08`), as fazendas com o moinho (`c9_14`), as casas ricas com os jardins (`c4_02`). Como sempre,
**só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 210 — Pombos na cumeeira | uma fila de pombos pousados no alto do telhado de parte das casas, cada um virando a cabeça de vez em quando |
| 211 — Mós no moinho | as mós de pedra encostadas na parede do moinho, com os sacos de farinha empilhados ao lado |
| 212 — Buxo na porta | os vasos de pedra com o buxo podado em bola dos dois lados da porta das casas dos investidores |
| 213 — Lenha da padaria | a pilha de lenha e a pá de forno encostadas na parede, ao lado da boca do forno da padaria |
| 214 — Escada de mão | a escada de madeira encostada na parede do lado de parte das casas, subindo até o beiral, com o balde no pé |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase210.md` a
`docs/plano_fase214.md`), testes, captura e benchmark; as três pastas da suíte passaram no fim (world 448, presentation 359, ui
167). Diferenças do roteiro: os pombos têm malha própria de poucas faces (a primeira custava ~1 FPS); a lenha da padaria só sai
com a célula do lado livre (encostada no vizinho entraria na parede dele), e a captura ganhou uma padaria sozinha; o moinho
entrou na rua dos prédios grandes da captura da Fase 95.
