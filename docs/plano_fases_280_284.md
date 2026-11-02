# Roteiro das Fases 280 a 284 — Mar e rio

**02/11/2026.** Segundo ciclo da ideação de 02/11/2026 (ver `docs/plano_fases_275_279.md`). A referência é o Anno aberto nesse
dia: o mar diante da falésia (`c10_03` e `c10_10`) e o rio na garganta (`c10_04` e `c10_05`), em
`F:\ferramentas\capturas\anno\`. Como sempre, **só a ideia**: tudo é gerado no código.

## O diagnóstico

- **Mar de piscina.** O `WaterView` põe o fundo em (0,05; 0,19; 0,42) e uma plataforma turquesa de 40 m em (0,24; 0,76; 0,72).
  - No Society, o mar inteiro sai azul-elétrico e claro.
  - No Anno, o mar temperado é azul-petróleo escuro, com o marulho à mostra, e é ele que faz a terra verde saltar. O turquesa
    fica para os trópicos.
- **Lençol de espuma.** A espuma da praia (`shore_foam_width_m`, 9 m, com as bandas andando) vira uma faixa branca larga. No
  Anno, a rebentação é uma linha fina e quebrada.
- **Água que brilha à noite.** A cor da água sai pela `EMISSION`, o truque da refração do Ocean do Boujie, que não recebe a luz
  da cena. De noite, a plataforma fica ciano acesa e o mar fundo, azul vivo (`08_noite.png` do ciclo da cor).
- **Rio de espuma.** Os rios estreitos ficam cobertos da espuma da beira; os nenúfares da Fase 274 sumiam nela. No Anno, o rio é
  água escura e calma, com a margem de seixos cinzentos.
- **Mar liso de longe.** De cima, o mar aberto do Society quase não tem textura; no Anno, a ondulação larga se lê de longe.

## As fases

| Fase | O quê |
|---|---|
| 280 — Mar fundo | o fundo em azul-petróleo profundo e a plataforma mais estreita e menos clara nas ilhas temperadas; nas tropicais, o turquesa de hoje (pela região, como o recife da Fase 125). Escolha no `tools/color_lab.tscn`, lado a lado |
| 281 — Rebentação fina | a espuma da beira vira linhas finas e quebradas que chegam e somem, mais larga só no espraiado da praia; nas pedras, a linha branca colada nelas |
| 282 — Água de noite | a cor da água (fundo, plataforma, recife, carneirinhos) escurece com a luz do dia pelo global `night_light`; de noite, o mar fica azul-escuro com o reflexo da lua e o brilho das luzes |
| 283 — Rio escuro | nos rios, a espuma da beira some (pela largura da água: a distância à costa das duas margens) e a água fica escura e calma; a lama da margem das temperadas vira cascalho cinza com seixos (a laterita das tropicais, Fase 170, fica) |
| 284 — Marulho | ondulação larga no mar aberto (normal em duas escalas grandes, andando com o vento), que se lê de longe; os carneirinhos da Fase 155 seguem por cima |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura (as vistas do
`tools/capture_phase260.tscn`, de dia e de noite, antes e depois) e benchmark, commit e push. O shader da água só compila com
GPU: o teste dele é o da lista de uniformes (Fase 35), na pasta `presentation`, com a janela oculta.

## Estado

A fazer.
