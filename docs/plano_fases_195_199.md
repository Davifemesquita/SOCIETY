# Roteiro das Fases 195 a 199 — Cemitério, pato e rede

**01/11/2026.** Primeiro ciclo do quinto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono estava usando o
PC). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): o pasto com o lago redondo
e a vila ao longo da estrada (`c6_03`), o porto com o cais de passeio cheio de bancos (`f115_07`). Como sempre, **só a ideia**:
nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 195 — Cemitério da igreja | lápides, cruzes e pequenos obeliscos em fileiras atrás da igreja, além do largo, dentro de um muro baixo de pedra com o portão virado para ela |
| 196 — Patos na água | bandos de patos nadando em fila na água rasa e calma junto da costa baixa, de dia |
| 197 — Casinha do cão | a casinha de tábuas com telhado de duas águas ao lado das casas que têm cão na porta |
| 198 — Bancos no cais | bancos de tábua com pés de ferro no cais de pedra, de costas para a cidade e virados para o mar |
| 199 — Rede na varanda | a rede de dormir listrada pendurada entre dois esteios do alpendre das casas das ilhas tropicais |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase195.md` a
`docs/plano_fase199.md`), testes, captura e benchmark; as três pastas da suíte passaram no fim (world 400, presentation 357, ui
167). Diferenças do roteiro: os patos ficam longe da costa o bastante para sair da espuma da linha d'água (perto dela boiavam no
branco), e a busca deles foi refeita (de 226 para 12 ms); a casinha do cão fica na célula do lado do lote, porque o cão deita na
beira da rua; os bancos do cais são o banco de praça da decoração.
