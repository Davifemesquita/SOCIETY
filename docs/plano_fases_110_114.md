# Roteiro das Fases 110 a 114 — Sol, trópico e avenida

**30/10/2026.** O dono pediu para fazer todas as fases mapeadas e, se preciso, abrir o Anno de novo. As ideias saem de
capturas do Anno 1800 dele que este ciclo ainda não tinha usado (`F:\ferramentas\capturas\anno\tela6.png`, a vila tropical
com a praia e o rio; `ilha_b.png`, o mar aberto; `f95_11.png`, a avenida da cidade), fora do repositório. Como sempre,
**só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## O que o Anno mostra e o Society não tem

O mar aberto cintila onde o sol bate; a vila tropical tem o chão de terra batida em volta das casas e coqueiros pelas ruas;
a avenida da cidade é arborizada dos dois lados e as casas ricas têm gradil de ferro na frente.

## As fases

| Fase | O quê |
|---|---|
| 110 — Brilho do sol no mar | cintilação do sol na água: pontos de brilho que acendem e apagam onde o reflexo do sol cai, mais no mar aberto |
| 111 — Terreiro tropical | o chão em volta das casas das ilhas tropicais vira terra batida (como a porta, pela máscara das estradas) |
| 112 — Coqueiros na rua tropical | coqueiros pequenos na beira das ruas das ilhas tropicais, pelo recheio |
| 113 — Alameda | árvores plantadas a intervalos ao longo das ruas calçadas, dos dois lados, onde a célula vizinha é livre |
| 114 — Gradil das casas ricas | gradil baixo de ferro com portão na frente das casas dos engenheiros e investidores, entre a casa e a rua |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 30/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase110.md` a
`docs/plano_fase114.md`), testes, captura e benchmark, sem precisar abrir o Anno de novo (as capturas que este ciclo não
tinha usado bastaram). Diferenças do roteiro: o gradil (114) ficou só nos engenheiros, porque a frente dos investidores já
tem a sebe e o pórtico; a alameda (113) também aparece na ilha plana.
