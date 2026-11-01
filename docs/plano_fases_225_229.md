# Roteiro das Fases 225 a 229 — Lanterna, lã e morcego

**01/11/2026.** Terceiro ciclo do sexto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono estava ocioso, mas esta
sessão não tem o controle da tela).
As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): o porto com os navios de popa acesa
(`c5_06`), as fazendas e os pastos (`c9_14`), a vila de noite (`c9_08`). Como sempre, **só a ideia**: nenhum modelo, textura,
arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 225 — Lanterna na popa | a lanterna de popa num pau na ré de cada navio, acesa à noite |
| 226 — Fardos de lã | os fardos de lã amarrados empilhados no lado da fazenda de ovelhas, com a tesoura de tosquia num cepo |
| 227 — Lamaçal do chiqueiro | a poça de lama brilhante num canto de cada pasto de porcos |
| 228 — Barris de petróleo | os barris de ferro pintados em pé e deitados no lado do poço de petróleo |
| 229 — Morcegos ao anoitecer | os morcegos esvoaçando em zigue-zague em volta da torre da igreja, do anoitecer à madrugada |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase225.md` a `docs/plano_fase229.md`),
testes, captura e benchmark. Diferenças do roteiro: a lanterna de popa lê o casco uma vez junto do cordame (montada antes dele: a
busca do casco quebrava na malha do cordame); os fardos de lã viraram sacos estufados com as cordas em volta (as caixas pareciam de
papelão); o capim do pasto deixou de nascer dentro do lamaçal; os barris de petróleo são de madeira (o tambor de ferro é de
depois).
