# Roteiro das Fases 155 a 159 — Carneirinho, papoula e colheita

**31/10/2026.** Primeiro ciclo do pedido "pode continuar" do dono (lido como mais 4 ciclos, como o anterior): abrir o Anno,
idealizar e fazer. As ideias saem de capturas novas da ilha do Anno 1800 dele (`F:\ferramentas\capturas\anno\c9_*.png`, fora
do repositório): os carneirinhos de espuma espalhados no mar aberto (`c9_15`, `c9_16`), as manchas de papoulas no prado
(`c9_12`), as caixas e os sacos da colheita no meio do campo de batatas (`c9_03`, `c9_07`), as carroças cobertas de lona nas
ruas (`c9_08`) e o barreiro de terra vermelha (`c9_11`), que aqui vira o pátio de tijolos secando da olaria. Como sempre,
**só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 155 — Carneirinhos no mar | manchas de espuma que nascem, andam com o vento e se desfazem no mar aberto, mais com o vento forte |
| 156 — Papoulas no prado | manchas de papoulas vermelhas no capim aberto, juntas em canteiros pelo ruído, não soltas |
| 157 — Caixas da colheita | caixotes e sacos ao longo das fileiras do campo maduro, que somem na colheita |
| 158 — Carroça de lona | parte das carroças ganha os arcos e a lona por cima da caçamba |
| 159 — Tijolos secando | junto de cada olaria, o pátio com as fileiras de tijolos crus secando e o barreiro escavado |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 31/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase155.md` a
`docs/plano_fase159.md`), testes, captura e benchmark. Diferenças do roteiro: as papoulas (156) ficaram fora da areia da praia e
o ruído dos canteiros guarda os nós da última célula (o carregar subia 0,2 s); a colheita (157) vai em pares de peças, com a
juta dos sacos mais escura; a lona (158) vale para metade das carroças de saco e caixote, e no caminho saiu um erro antigo da
boca do forno do log; o pátio de tijolos (159) evita o lado da boca do forno.
