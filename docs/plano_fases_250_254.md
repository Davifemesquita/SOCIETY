# Roteiro das Fases 250 a 254 — Balança, cabra e canoa

**01/11/2026.** Quarto ciclo do sétimo pedido "pode continuar" do dono. O Anno **não foi aberto** (esta sessão não tem o controle
da tela). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): os armazéns e o porto
(`c5_06`), as encostas e os rios (`c9_14`), a cidade com os serviços (`c4_02`), as fazendas (`c6_09`). Como sempre, **só a ideia**:
nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 250 — Balança de carga no armazém | a balança decimal de plataforma com os pesos e os sacos esperando, no lado de cada armazém |
| 251 — Cabras nas encostas | cabras malhadas pastando nas encostas íngremes das ilhas temperadas, longe das vilas, uma de pé numa pedra |
| 252 — Carruagem à porta do teatro | a carruagem fechada de quatro rodas, sem cavalos, parada na rua diante de cada teatro |
| 253 — Cestos de batata | os cestos e sacos de batata recém-colhida e o forcado no lado de cada fazenda de batata |
| 254 — Canoas na margem do rio | a canoa escavada puxada para a margem baixa do rio, com o remo dentro, longe das vilas |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push. Os pátios de
lado usam o `SideYard` (com o `SideYard.remember`).

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase250.md` a `docs/plano_fase254.md`),
testes, captura e benchmark; as três pastas da suíte passaram no fim (world 593, presentation 368, ui 167). Diferenças do
roteiro: os sacos da balança viraram sacos de pé amarrados (redondos, pareciam bolas); os cestos de batata ganharam as batatas
soltas por cima e o vime mais claro (com o monte liso, pareciam bolinhos); a busca das canoas parte das células de rio (varrer a
vizinhança de cada ponto custava ~160 ms a cada obra). A máquina voltou ao estado rápido (~78 FPS) na Fase 250; todas as fases
ficaram neutras.
