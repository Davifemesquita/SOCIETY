# Roteiro das Fases 305 a 309 — Mata funda

**02/11/2026.** Terceiro ciclo da ideação de 02/11/2026 (tarde), sem abrir o Anno. A referência é a mata do Anno em `c10_02` e
`c10_09` (`F:\ferramentas\capturas\anno\`), comparada com a mata depois das Fases 275 a 279. **Só a ideia.**

## O diagnóstico

- **Folhosas da mesma cor.** Os carvalhos e as faias saem todos do mesmo verde-limão claro (Fase 256). No Anno, a mata mistura
  verdes escuros, oliva e amarelados, árvore a árvore.
- **Chão da mata claro.** Entre as árvores, o chão do Society é o capim do prado. No Anno, o chão da mata é escuro, de folhas e
  agulhas, na sombra das copas.
- **Mata sem sub-bosque.** No Anno há arbustos e samambaias debaixo das árvores. No Society, o recheio dentro da mata é ralo.
- **Abetos iguais de perto e de longe.** No Anno, os abetos de longe ficam escuros e azulados. No Society, a cor é a mesma.
- **Vale sem ar.** No Anno, de manhã, a névoa baixa fica presa nos vales da mata.

## As fases

| Fase | O quê |
|---|---|
| 305 — Tom por árvore | no `shaders/foliage.gdshaderinc`, o tom de cada árvore pelo hash inteiro da origem da instância (como o `strata_hash`): mais escuro, mais oliva ou mais amarelado; forte nas folhosas e leve nas coníferas |
| 306 — Chão da mata | no `shaders/terrain.gdshader`, onde a mata é densa, o capim vira chão de folhas e agulhas, mais escuro e com manchas de musgo; a beira da mata fica em transição |
| 307 — Sub-bosque | samambaias e um arbusto baixo também nas células de mata das temperadas (peças novas no fim do enum e das listas do recheio), só debaixo das árvores desenhadas |
| 308 — Abetos de longe | a cor das coníferas escurece e esfria com a distância da câmera |
| 309 — Névoa nos vales | de manhã, faixas de névoa baixa e mole presas nos vales (a curvatura dos dados do terreno) perto da mata, sumindo até o meio-dia, pela hora e pelo `WeatherCycle` |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push. Mudança na cor da folhagem vai no
`.gdshaderinc` (Fase 279).

## Estado

**A fazer.**
