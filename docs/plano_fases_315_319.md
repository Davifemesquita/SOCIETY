# Roteiro das Fases 315 a 319 — Garganta do rio

**04/11/2026.** Quinto ciclo da ideação de 02/11/2026, sem abrir o Anno. A referência é o rio na garganta de pedra do Anno em
`c10_06` e `c10_08` (`F:\ferramentas\capturas\anno\`), comparado com o rio da semente 1840 depois das Fases 310 a 314
(`05_rio` e `05b_leito_seco` do `tools/capture_phase280.tscn`). **Só a ideia.**

## O diagnóstico

- **Lama no alto.** No Society, o alto das paredes da garganta tem uma faixa larga de lama marrom-alaranjada, e há manchas de lama
  soltas no planalto (Fase 283: acima de `gravel_top_m` a margem voltava à lama). No Anno, o capim vem até a beira da garganta.
- **Borda seca.** No Anno, o capim pende da borda de cima da garganta sobre a rocha, como nas falésias do mar (Fase 312, só no mar).
- **Pé da parede vazio.** No Anno, há blocos caídos no leito, junto das paredes. No Society, a parede desce limpa até a água.
- **Pedras sem água mexida.** No Anno, a água faz espuma branca em volta das pedras do rio. No Society, o canal escuro (Fase 283)
  tirou a espuma do rio inteiro, e os matacões da Fase 122 ficam na água parada.
- **Rio parado.** No Anno, a água do rio corre: riscos claros andam ao longo do canal. No Society, o rio é um braço de mar parado.

## As fases

| Fase | O quê |
|---|---|
| 315 — Capim no alto da garganta | no `shaders/terrain.gdshader`, nas temperadas, a lama acima de `gravel_top_m` some no capim, com a borda recortada; a margem baixa segue de cascalho e as tropicais, de laterita |
| 316 — Capim pendendo na garganta | a franja da `CliffFringeView` (Fase 312) também na borda de cima das gargantas dos rios, com o rio abaixo, fora de estrada e prédio |
| 317 — Blocos no pé da garganta | na `RiverStoneView`, blocos da `RockModel` caídos no leito junto das paredes íngremes da garganta, meio dentro da água |
| 318 — Espuma nas pedras do rio | a espuma em volta do que entra na água (Fase 293) também nos matacões e nos blocos do rio, que o canal escuro hoje apaga |
| 319 — Correnteza | no canal (Fase 283), riscos claros e finos andando ao longo do rio, pela direção do mapa da costa, devagar |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push.

## Estado

Fase 315 feita em 04/11/2026 (`docs/plano_fase315.md`); as Fases 316 a 319 esperam a confirmação do dono.
