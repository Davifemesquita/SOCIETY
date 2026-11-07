# Roteiro das Fases 180 a 184 — Borboleta, correio e galo

**31/10/2026.** Segundo ciclo do quarto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono seguia usando o PC).
As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): os canteiros floridos com vida
em volta (`f115_05`), a rua calçada com o mobiliário de ferro (`c9_14`), os telhados das fazendas e da igreja com os enfeites
no alto, a praia junto das cabanas de pesca e a pedra molhada na beira do mar (`c3_*`). Como sempre, **só a ideia**: nenhum
modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 180 — Borboletas nos canteiros | borboletas coloridas esvoaçando sobre os canteiros de papoulas e de flores, de dia |
| 181 — Caixa de correio | a caixa de correio de ferro fundido, redonda e vermelha, na calçada de parte das ruas calçadas |
| 182 — Galo do cata-vento | o galo de ferro no alto da cumeeira das fazendas, virando para o lado de onde vem o vento |
| 183 — Barco na areia | o barco de pesca virado de borco na areia, com os remos encostados, ao lado das cabanas de pesca |
| 184 — Limo na pedra | a faixa escura e esverdeada de limo e alga na pedra das rochas da costa, junto da linha d'água |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 31/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase180.md` a
`docs/plano_fase184.md`), testes, captura e benchmark. Diferenças do roteiro: as borboletas cresceram depois da primeira
captura (sumiam nas papoulas), e refazer o arquipélago a cada obra custava ~48 ms, o que trouxe o `IslandDirty` (a ilha que
mudou) também para os vaga-lumes da Fase 178; o limo ganhou a crosta da maré, porque sozinho se confundia com o musgo da
rocha.
