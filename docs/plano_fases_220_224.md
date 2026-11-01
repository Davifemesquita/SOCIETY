# Roteiro das Fases 220 a 224 — Bomba, barril e lençol

**01/11/2026.** Segundo ciclo do sexto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono estava usando o PC).
As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): as cidades com os serviços e as
oficinas (`c9_08`, `c4_02`) e o porto (`c5_06`). Como sempre, **só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo;
tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 220 — Bomba de incêndio no quartel | a bomba de incêndio de mão sobre rodas, com a mangueira enrolada, os baldes de couro e a escada, no lado do quartel de bombeiros |
| 221 — Barris na cervejaria | os barris deitados em pirâmide sobre os calços, no lado da cervejaria, das destilarias e da adega |
| 222 — Covos no cais | os covos de pesca empilhados com o cabo enrolado e as boias, em parte dos lanços do cais de pedra |
| 223 — Lençóis no hospital | os lençóis brancos estendidos em varais compridos no lado do hospital |
| 224 — Relógio de sol no largo | o relógio de sol de pedra sobre a coluna no largo calçado dos serviços |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase220.md` a `docs/plano_fase224.md`),
testes, captura e benchmark. Diferenças do roteiro: as buscas dos pátios de lado passaram a ficar guardadas (`SideYard.remember`:
cada pátio refazia as dos de antes, e o carregar subia 0,3 s); os covos não seguem um resto fixo de lanço como os bancos (os lanços
desse resto já tinham o mastro, a escada e o lampião) e ficam nos primeiros lanços livres, até dois por entreposto, com poucas
faces (a primeira malha punha +0,16 milhão de primitivas).
