# Roteiro das Fases 300 a 304 — Telhado gasto e chão de vila

**02/11/2026.** Segundo ciclo da ideação de 02/11/2026 (tarde), sem abrir o Anno. A referência é a cidade do Anno em `c10_01`
(`F:\ferramentas\capturas\anno\`), comparada com a vila do Society nos quatro ciclos anteriores. **Só a ideia.**

## O diagnóstico

- **Telhado de brinquedo.** Depois da cor viva (Fase 258), os telhados de terracota saem todos do mesmo laranja limpo. No Anno,
  cada telhado tem o tom dele e está gasto: musgo, sujeira escorrida, telhas trocadas mais claras.
- **Casa na grama.** No Society, as casas das temperadas assentam direto no gramado. No Anno, o chão entre as casas é terra e
  cascalho pisados, com a grama só nos cantos.
- **Parede limpa.** No Anno, a base das paredes é suja de terra e respingo, e escorre sujeira debaixo das janelas e do beiral.
- **Telhado de um material.** No Anno, as casas pobres têm telhado de tábuas cinzentas, ao lado das de telha.
- **Quintal sem divisa.** No Anno, os quintais de trás têm muros baixos e cercas entre eles.

## As fases

| Fase | O quê |
|---|---|
| 300 — Telhas gastas | no `shaders/building_kit.gdshader`, nas telhas: tom por casa (mais claro, mais escuro, mais pardo, pelo lugar do prédio, como os postigos da Fase 177), telhas soltas mais claras, musgo nas fiadas de baixo e sujeira escorrendo da cumeeira |
| 301 — Chão de vila | na `RoadMask`, o lote das casas das temperadas crescido no canal b (o chão batido), como o terreiro tropical da Fase 111, com a borda recortada, fora das hortas, dos quintais cercados e do largo |
| 302 — Sujeira nas paredes | no `shaders/building_kit.gdshader`, a faixa de terra e respingo no pé da parede (acima do musgo da Fase 39) e os escorridos debaixo dos peitoris e do beiral, pela altura na parede e um ruído vertical |
| 303 — Telhado de tábuas | parte das casas dos operários troca a telha por tábuas cinzentas sobrepostas (parâmetro de instância, como a ardósia da Fase 134 e o sapê da Fase 130) |
| 304 — Muro dos quintais | muretas de pedra seca e cercas de tábua nas divisas de trás entre casas vizinhas das temperadas, abertas nas hortas e nos varais, numa vista própria |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push. Antes de dar uma célula da paleta a
uma peça nova, conferir que nenhuma peça do kit cai nela.

## Estado

**Concluído em 02/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase300.md` a `docs/plano_fase304.md`),
testes, captura e benchmark (todas neutras, GPU de 12,5 a 12,7 ms). As três pastas da suíte passaram no fim (world 712,
presentation 396, ui 167).

Diferenças do roteiro:

- o chão de vila não aparecia na primeira versão: o tapete de capim da Fase 286 cobria a terra batida; o capim alto deixou de
  crescer colado nos prédios e o alcance do chão cresceu;
- o musgo das telhas cobria os telhados de tábua dos celeiros e foi reduzido;
- o muro dos quintais não se abre nas hortas e nos varais: eles ficam na fileira de trás, dentro do quintal fechado; e só sai com
  a fileira de trás livre (na vila de teste, a primeira fileira, de fundos para o campo).

O antes e depois de cada fase está em `F:\ferramentas\capturas\faseNNN\` (300 a 304).
