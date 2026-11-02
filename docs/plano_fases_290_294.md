# Roteiro das Fases 290 a 294 — Rocha e costa

**02/11/2026.** Quarto ciclo da ideação de 02/11/2026 (ver `docs/plano_fases_275_279.md`). A referência é o Anno aberto nesse
dia, em `F:\ferramentas\capturas\anno\`:

- a falésia sobre o mar (`c10_03`);
- a garganta do rio (`c10_04`);
- a montanha com os abetos no pé (`c10_09`);
- a costa de pedra da cidade (`c10_10`).

Como sempre, **só a ideia**: tudo é gerado no código.

## O diagnóstico

- **Rocha lisa.** As encostas e as falésias do Society são a textura de rocha cinza (Fase 261) sem estrutura. No Anno, a rocha tem
  estratos e sulcos descendo, com capim e musgo nas saliências.
- **Costa de dois tipos.** Nas temperadas do Society, a costa é praia de areia ou falésia. O Anno tem também a praia de seixos
  cinzentos junto das pedras, molhada na beira.
- **Pedra sem espuma.** No Society, a água encosta nas rochas soltas e nos rochedos sem a linha branca em volta.
- **Encosta pelada.** As encostas íngremes do Society só têm o pinheiro-anão (Fase 207) e o cascalho (Fase 162). No Anno, os
  abetos sobem pela rocha.

## As fases

| Fase | O quê |
|---|---|
| 290 — Estratos na rocha | no `shaders/terrain.gdshader` e no `shaders/sea_rock.gdshader`, camadas quase horizontais e sulcos descendo pela encosta (ruído esticado ao longo da inclinação), com a borda de cima de cada camada mais clara e a de baixo na sombra |
| 291 — Musgo nas saliências | nas partes quase planas da rocha (pela normal), manchas de capim e musgo, mais no lado da sombra e menos nas faces de pé |
| 292 — Praia de seixos | nas costas baixas das temperadas encostadas em rocha, a areia vira seixos cinzentos e redondos (no shader e com pedrinhas do recheio), escuros e brilhantes junto da água |
| 293 — Espuma nas pedras | a linha de espuma fina e animada em volta das rochas e dos rochedos na água, pela profundidade da pedra logo abaixo da superfície (a conta da espuma do Ocean, mais fina) |
| 294 — Abetos na rocha | abetos pequenos e esparsos (a espécie da Fase 275, reduzida) presos nas saliências das encostas íngremes e das falésias das temperadas, pelo recheio |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push. Peça nova do
recheio vai no fim do enum e da lista dela.

## Estado

**Concluído em 02/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase290.md` a `docs/plano_fase294.md`),
testes, captura e benchmark (todas neutras). As três pastas da suíte passaram no fim (world 695, presentation 389, ui 167).

Diferenças do roteiro:

- os estratos e o musgo ficaram num `.gdshaderinc` só (`shaders/rock_strata.gdshaderinc`), dividido pelo terreno e pelas pedras;
- o musgo vai mais para um lado fixo da sombra (o norte), não pelo sol do dia, que o faria andar;
- os seixos são células de Voronoi no shader (a textura de rocha menor saía lisa), sem as pedrinhas do recheio;
- a espuma nas pedras é o anel fino da profundidade longe da linha d'água (a Fase 281 tinha tirado), sem conta nova de distância;
- os abetos da rocha usam a malha de perto do abeto (a de longe parecia cipreste).

Também se achou e corrigiu um furo nos testes: com tela, a lista de uniformes vazia passava como se fosse o renderer falso, e um
shader que não compilava (Fase 290) passou no primeiro teste; agora os testes de shader das Fases 290 a 294 exigem a lista cheia
com tela.

O antes e depois deste ciclo está em `F:\ferramentas\capturas\fase294\ciclo_antes_depois.png`, e o dos quatro ciclos (a vila de
cima, a mata, a praia e o prado), em `F:\ferramentas\capturas\fase294\quatro_ciclos_antes_depois.png`.
