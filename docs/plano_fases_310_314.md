# Roteiro das Fases 310 a 314 — Falésia de verdade

**02/11/2026.** Quarto ciclo da ideação de 02/11/2026 (tarde), sem abrir o Anno. A referência são as falésias do Anno em
`c10_03`, `c10_04` e `c10_10` (`F:\ferramentas\capturas\anno\`), comparadas com a costa depois das Fases 290 a 294. **Só a ideia.**

## O diagnóstico

- **Falésia em bolhas.** A face das falésias do Society é o terreno com rochas redondas encaixadas (Fase 56). No Anno, a falésia
  é uma parede de rocha escura em blocos grandes de faces planas.
- **Pé da falésia vazio.** No Anno, o pé das falésias tem um amontoado de blocos caídos dentro da água.
- **Borda de cima seca.** No Anno, o capim passa da borda e pende sobre a rocha.
- **Face nua.** No Anno, as fendas da face têm arbustos e capim agarrados.
- **Água sem sombra.** No Anno, a água junto das falésias fica escura na sombra delas. No Society, a cor da água não recebe
  sombra (sai pela `EMISSION`, Fase 282).

## As fases

| Fase | O quê |
|---|---|
| 310 — Blocos na face | na face das falésias (a subgrade da Fase 62), facetas grandes: a normal da rocha quantizada por um Voronoi largo no `shaders/rock_strata.gdshaderinc`, com juntas escuras entre os blocos |
| 311 — Blocos caídos | na `RockView`, um amontoado de blocos da `RockModel` no pé das falésias, meio dentro da água, com a espuma da Fase 293 em volta |
| 312 — Capim na borda | uma franja de capim pendendo da borda de cima das falésias (os tufos do tapete da Fase 286, numa vista fixa ao longo da borda), fora de estrada e prédio |
| 313 — Fendas com mato | arbustos pequenos e capim nas saliências da face da falésia (peça nova do recheio no fim do enum, só nas células de face) |
| 314 — Sombra da falésia na água | a água junto das falésias escurece do lado da sombra, pela direção do sol (`sun_direction`) e pela altura da terra perto, sem precisar da luz de verdade |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push.

## Estado

**A fazer.**
