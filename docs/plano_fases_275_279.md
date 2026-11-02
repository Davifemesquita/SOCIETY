# Roteiro das Fases 275 a 279 — Mata no jeito do Anno

**02/11/2026.** O dono pediu: "pode idealizar as próximas fases, se preciso abra o anno". Esta ideação cobre quatro ciclos, as
Fases 275 a 294 (`docs/plano_fases_275_279.md` a `docs/plano_fases_290_294.md`). O Anno **foi aberto**: o dono estava fora do PC
fazia dois minutos, e a partida dele foi carregada, olhada e fechada pelo menu. As capturas são `c10_01` a `c10_10` e o lado a
lado com o Society é `c10_comparacao.png`, todos em `F:\ferramentas\capturas\anno\`, fora do repositório. Como sempre, **só a
ideia**: nenhuma textura, modelo, cor tirada de arquivo nem número do jogo. Tudo é gerado no código e medido nas nossas capturas.

## O diagnóstico

Depois dos dois ciclos de cor (Fases 255 a 264), as nossas vistas do `tools/capture_phase260.tscn` foram postas ao lado do Anno
na mesma altura de câmera. A diferença maior já não é a cor; é a **forma** do que cobre a maior parte da tela. As quatro frentes,
uma por ciclo:

1. **a mata** (este ciclo), que é a maior parte da tela;
2. **o mar e o rio** (Fases 280 a 284);
3. **o prado** (Fases 285 a 289);
4. **a rocha e a costa** (Fases 290 a 294).

Na mata:

- **Copa grande demais e grudada.** O carvalho e a faia têm copa de ~8 m de largura, e a `TreeView` desenha até 2 árvores por
  célula de 2 m (escala de 0,75 a 1,25).
  - No Society, a mata vira um tapete contínuo de bolhas facetadas, sem nenhum vão.
  - No Anno, cada árvore se lê, com o capim e a sombra entre elas.
- **Paliçada de troncos.** O pinheiro-silvestre tem 10,6 m e a copa só no último terço.
  - No Society, na beira de toda mata de pinheiros aparece uma cerca de troncos vermelhos, vista de fora.
  - No Anno, as coníferas são abetos em cone, com os galhos em camadas até perto do chão, verde-escuros.
- **Uma só folha.** Todas as copas do Society são bolas lisas de faces chapadas, em três espécies.
  - O Anno mistura abetos escuros, folhosas claras e bétulas de tronco branco.
  - Lá, a borda da copa tem o recorte das folhas.

## As fases

| Fase | O quê |
|---|---|
| 275 — Abeto em camadas | espécie nova no `TreeModel`: tronco curto e escondido, cone de 6 a 8 camadas de galhos caídos, verde-escuro azulado, com o nível de longe; entra na mistura das coníferas no lugar de parte dos pinheiros (o pinheiro fica nas encostas altas e junto da costa) |
| 276 — Copas na medida | copa das folhosas ~35% mais estreita, mais variação de tamanho entre as árvores e, na maior parte das células, uma árvore desenhada em vez de duas (a simulação continua contando todas): a mata ganha vãos, capim e sombra entre as árvores; o quadro deve melhorar com menos instâncias |
| 277 — Bétula | espécie nova com o tronco branco de manchas pretas, galhos finos subindo e copa leve e clara em massas pequenas, na beira da mata e nos lugares baixos das temperadas |
| 278 — Orla da mata | nas células de mata que dão para o campo, árvores novas e menores e arbustos cobrindo o pé dos troncos, para que nenhuma beira de mata mostre a paliçada |
| 279 — Folhas recortadas | o recorte das folhas na borda das copas de perto: um atlas de folhas pintado no código (`Image`) nos tufos de fora, com alpha scissor; de longe continua a malha de hoje. É a fase mais cara do ciclo: se a GPU subir mais de ~0,5 ms, fica só no alto e no ultra |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

As capturas da mata usam as vistas do `tools/capture_phase260.tscn`: a vila de cima, os campos de perto e a falésia, antes e
depois.

Mudar o desenho das árvores mexe também nas vistas que as leem: a clareira do lenhador (`StumpView`, `TreeView.is_cut`), o tronco
caído (Fase 246) e o recheio da beira da mata. Os testes delas entram em cada fase.

## Estado

A fazer.
