# Roteiro das Fases 165 a 169 — Chão batido, feno e gaivota

**31/10/2026.** Terceiro ciclo do pedido "pode continuar" do dono. O Anno de novo **não foi aberto** (o dono mexia no PC poucos
minutos antes, com outra sessão na frente). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do
repositório): o chão de terra batida em volta das oficinas do bairro das fábricas (`c6_03`), o mato alto nos terrenos ainda
vazios (`c5_07`), as gaivotas e a espuma na pedra da costa (`c9_06`), e o feno e a água de chuva das casas de campo, que são
de qualquer vila do século XIX. Como sempre, **só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no
código.

## As fases

| Fase | O quê |
|---|---|
| 165 — Chão batido das fábricas | terra batida de borda recortada em volta de todo prédio de produção, pela máscara das estradas |
| 166 — Medas de feno | medas de feno redondas com a vara no meio junto das fazendas de gado e dos pastos |
| 167 — Capim alto nos terrenos vazios | manchas de capim alto e espigado no campo aberto, juntas pelo ruído |
| 168 — Gaivotas no cais | gaivotas pousadas nos cabeços do cais de pedra e dos píeres, virando a cabeça de vez em quando |
| 169 — Barril de chuva | o barril que recolhe a água do telhado, com a calha descendo, no canto de parte das casas |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 31/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase165.md` a
`docs/plano_fase169.md`), testes, captura e benchmark. Diferenças do roteiro: o chão batido (165) ficou com a borda recortada só
na beirada (o recorte do tamanho do pátio deixava grama junto da parede); as medas (166) também nas fazendas de trigo; o barril
de chuva (169) fica atrás das casas, na quina de −X (na frente não há lugar: a cerca de estacas e a rua).
