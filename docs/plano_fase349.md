# Plano da Fase 349 — Matacões no capim

**Estado: feita em 07/11/2026**, a quinta e última do roteiro `docs/plano_fases_345_349.md` (pedra grande). O Anno espalha pedras grandes
no capim perto da rocha; as nossas pedras soltas (Fase 57) eram poucas e só nos barrancos.

## O que entrou

- **`ScatterView.Kind.BOULDER`**, no fim do enum e das listas `OPEN` e `NEAR_FOREST` (o sorteio das peças de antes não muda): a forma da
  `RockModel` com o material da `RockView` (a rocha triplanar com os estratos, os blocos e as fendas), de `BOULDER_SCALE` (0,55 a 1,3 m)
  de raio, mais larga que alta, meio enterrada (`BOULDER_SINK`). Chance `BOULDER_CHANCE` (10%), só nas temperadas e na célula junto de
  um desnível de `BOULDER_NEAR_RELIEF_M` (1,6 m) ou mais (`_near_relief`: ela ou uma vizinha pelos lados — o pé e a beira da encosta e
  do barranco). Sem sombra (como as peças miúdas do recheio).
- **Dois testes antigos** conferiam que a peça deles era a última do enum ou da lista (Fases 313 e 338); passam a conferir a ordem
  relativa, que é o que protege o sorteio.

## Medida (o roteiro das Fases 345 a 349)

A máquina mudou de estado no meio das medidas (do lento, ~63 FPS, para o rápido, ~70); valem as da mesma janela:

| configuração | FPS | GPU |
|---|---|---|
| sem as rochas do alto e sem os matacões | 70,0 | 13,3 ms |
| só as rochas do alto | 69,3 | 13,5 ms |
| tudo (matacões a 10%), com interferência (p95 de 23 ms) | 65,3 | 13,8 ms |

Antes, no estado lento: a 344 a 63,4 FPS e GPU 14,7 ms; o roteiro com os matacões a 18%, 61,5–62,0 FPS e GPU 15,1–15,2 ms. As fendas e as
bancadas das Fases 346 e 348 não mudam o quadro (medido desligando as duas); o leque de cascalho da 347 passou a fazer o teste barato
primeiro (−0,1 ms). **O custo do roteiro, ~0,3 a 0,5 ms de GPU, é das rochas novas** (a rocha triplanar com os blocos de Voronoi 3D é
cara por pixel); os matacões caíram de 18% para 10% por isso. Fica para depois, se precisar: um material de rocha mais barato de longe.

## Como testar

- `tests/world/test_phase349_boulders.gd`: a peça no fim do enum e das duas listas, fora das plantas; os matacões só junto de desnível,
  do tamanho deles, enterrados e só nas temperadas.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase344\depois\`, depois (com as Fases 345 a
  349) em `F:\ferramentas\capturas\fase349\depois\`.
