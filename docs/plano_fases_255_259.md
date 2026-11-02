# Roteiro das Fases 255 a 259 — Cor viva

**01/11/2026.** Primeiro ciclo do oitavo pedido "pode continuar" do dono, que desta vez pediu também: "melhorar a coloração do
jogo, estou achando muito morto, gostaria de algo mais vivo, parecido com o anno". O Anno **não foi aberto** (esta sessão não
tem o controle da tela); a referência são as capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório: a vila
`c4_02`, o campo `c9_14`, o porto `c5_06`, a rocha `c6_02`). Como sempre, **só a ideia**: nenhuma textura, cor tirada de
arquivo, LUT ou número do jogo; tudo é ajuste nosso, medido nas nossas capturas.

## O diagnóstico

Capturas de antes (`tools/capture_phase255.tscn`, semente 1840, 10h30) e o laboratório de cor (`tools/color_lab.tscn`, a mesma
vila com várias combinações) mostram o que deixa o jogo apagado:

- **véu cinza-azulado**: a névoa volumétrica do nível alto (0,0018 por metro em 220 m) cobre a vista de longe; de 520 m a
  ilha parece vista através de vidro sujo;
- **tom chapado**: o AgX padrão (contraste 1,25, exposição 1) achata e dessatura; o sol é branco, sem o calor do dia;
- **copas quase pretas**: as árvores ocupam boa parte da tela e o lado da sombra delas fica verde-escuro, quase preto;
- **grama cor de oliva**: o verde puxa para o amarelo-oliva; com mais saturação vira amarelo-limão, não o verde do Anno.

## As fases

| Fase | O quê |
|---|---|
| 255 — Ar limpo e tom vivo | menos névoa, AgX com mais contraste, saturação e exposição, sol mais quente e mais forte |
| 256 — Copas verdes | folhas mais claras e verdes, o alto da copa iluminado e a sombra dela menos fechada |
| 257 — Grama viva | a grama puxa do oliva para o verde, com manchas mais claras e mais escuras |
| 258 — Telhado e parede com cor | telhas, caiação e madeiras mais vivas e com mais variação entre as casas |
| 259 — Praia dourada | a areia da praia sai do cinza-taupe para o dourado (o mar já estava vivo depois da Fase 255) |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura (as mesmas vistas do
`tools/capture_phase255.tscn`, antes e depois) e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase255.md` a `docs/plano_fase259.md`),
testes, captura e benchmark (todas neutras). As três pastas da suíte passaram no fim (world 608, presentation 368, ui 167). Diferença do roteiro: a Fase 259 virou a praia dourada, porque o mar ficou vivo já
na Fase 255. As fotos dos cartões do menu foram refeitas com as cores novas. O antes e depois do ciclo está em
`F:\ferramentas\capturas\fase259\ciclo_antes_depois.png`.
