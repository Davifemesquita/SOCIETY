# Roteiro das Fases 240 a 244 — Lagar, terreiro e estacas

**01/11/2026.** Segundo ciclo do sétimo pedido "pode continuar" do dono. O Anno **não foi aberto** (esta sessão não tem o controle
da tela). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): as fazendas e os pátios das
oficinas (`c3_05`, `c6_09`), a cidade industrial (`c8_03`). Como sempre, **só a ideia**: nenhum modelo, textura, arquivo ou medida
do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 240 — Lagar no vinhedo | a tina larga de pisar uvas com os cestos de uva e a prensa de fuso no lado de cada vinhedo |
| 241 — Terreiro de café | o terreiro de chão batido com os grãos de café espalhados secando ao sol e o rodo, ao lado de cada cafezal |
| 242 — Tabaco secando | o varal de varas com as folhas de tabaco penduradas em réstias, secando, no lado de cada plantação de tabaco |
| 243 — Vigas de aço empilhadas | a pilha de vigas de ferro em I sobre os dormentes no lado da fábrica de vigas de aço |
| 244 — Estacas de lúpulo | os feixes de estacas compridas encostados em cavaletes no lado de cada fazenda de lúpulo |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push. Os pátios de
lado usam o `SideYard` (com o `SideYard.remember`).

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase240.md` a `docs/plano_fase244.md`),
testes, captura e benchmark; as três pastas da suíte passaram no fim (world 553, presentation 368, ui 167). Diferenças do
roteiro: o café do terreiro virou uma camada fina com os sulcos do rodo (em cordões lisos parecia tábua, e em montinhos soltos,
escama); a pilha de vigas fica longe da boca do forno da Fase 137 (o −X primeiro); o feixe de estacas de pé passa da altura dos
outros pátios de lado. A máquina seguiu no estado lento (~70 FPS) o ciclo todo; todas as fases ficaram neutras nele (o
"construir" de 19,7 ms da Fase 243 foi conferido sem tela e era vaivém).
