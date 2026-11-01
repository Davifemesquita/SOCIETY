# Roteiro das Fases 215 a 219 — Tábua, cortina e andorinha

**01/11/2026.** Primeiro ciclo do sexto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono estava usando o PC,
ocioso 12 s). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): o porto com as
oficinas e os navios (`c5_06`), as vilas com os quintais e as oficinas (`c9_08`, `c4_02`). Como sempre, **só a ideia**: nenhum
modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 215 — Tábuas secando na serraria | as pilhas de tábuas com os tabiques entre as camadas, sobre dormentes, no lado da serraria oposto à roda d'água |
| 216 — Monte de carvão na usina | o monte de carvão com a pá e o carrinho no lado da usina a carvão |
| 217 — Cortinas nas janelas | as cortinas presas dos lados do vidro das janelas das casas, num tom por casa |
| 218 — Andorinhas no campanário | um bando de andorinhas dando voltas rápidas em volta da torre da igreja, de dia |
| 219 — Balanço e gangorra na escola | o balanço de madeira e a gangorra numa célula livre ao lado da escola |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase215.md` a `docs/plano_fase219.md`),
testes, captura e benchmark; as três pastas da suíte passaram no fim (world 464, presentation 365, ui 167). Diferenças do
roteiro: o carvão ganhou faces chapadas (liso, parecia um pano); as cortinas quase não
aparecem nas casas de madeira dos camponeses (a vidraça escura da peça do kit fica na frente); a pá e o carrinho do carvão viraram
só a pá (o carrinho de mão da Fase 172 já fica atrás das oficinas); a busca das duas células de lado das Fases 215, 216 e 219
virou o `SideYard`.
