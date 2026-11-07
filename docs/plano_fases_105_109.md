# Roteiro das Fases 105 a 109 — Cidade e porto

**29/10/2026.** Depois da rua habitada (Fases 100 a 104), o dono pediu para continuar. As ideias saem das capturas do Anno
1800 dele já tiradas (`F:\ferramentas\capturas\anno\f95_10.png` a `f95_12.png`, fora do repositório: a cidade inteira com
o porto, e as ruas de perto). Como sempre, **só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado
no código.

## O que o Anno mostra e o Society não tem

Entre as casas do Anno há árvores nos quintais e nos cantos; a costa da cidade é um cais de pedra comprido, com os píeres
saindo dele; no porto andam barcos pequenos (de pesca e de vela) além dos navios; na ponta do quebra-mar há um farol; e a
frente dos prédios públicos é um largo calçado. No Society o quintal tem arbusto, flor e barril, a costa da cidade é a praia
ou a falésia até o entreposto, o porto só tem os navios do jogador, das rivais e do comerciante, e a frente da igreja é
grama.

## As fases

| Fase | O quê |
|---|---|
| 105 — Árvores de quintal | macieiras pequenas (com fruta) nas células livres junto das casas, pelo recheio da Fase 41; bananeira nas tropicais |
| 106 — Cais de pedra | muro de cantaria com capeamento, cabeços e escadas ao longo da beira-mar dos dois lados do entreposto e dos píeres |
| 107 — Barcos de pesca | barcos pequenos de vela saindo da cabana de pesca para o mar e voltando, enquanto ela trabalha (só visual) |
| 108 — Farol | farol de pedra caiada na ponta de terra mais perto do entreposto, com a lanterna girando à noite |
| 109 — Largo calçado | o chão de pedra na frente dos serviços (igreja, teatro, universidade, prefeitura, escola), da porta até a rua |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 30/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase105.md` a
`docs/plano_fase109.md`), testes, captura e benchmark. Diferenças do roteiro: o cais de pedra (106) ficou só no
entreposto (o píer segue de madeira), sem as escadas e em linha reta, depois de uma primeira versão pela escada das células; o farol (108)
fica na ponta mais exposta ao mar perto do entreposto, não num quebra-mar; o largo (109) aparece nos lados e nos fundos dos
serviços, porque a frente encosta na rua.
