# Plano da Fase 73 — O cavalo-de-pau do poço de petróleo

**Estado: feita em 28/10/2026, a pedido do dono** ("pode ir para a próxima fase"; proposta deixada de fora na Fase 70).
Só apresentação: a simulação, o save, o lote e as assinaturas não mudam.

## O que entrou

- **Silhueta nova** (`BuildingDef.Silhouette.PUMPJACK`, no fim do enum: os números dos `.tres` não mudam): o poço
  deixa a torre de mina (que era emprestada das minas) e ganha o cavalo-de-pau.
- **A forma** (`BuildingKit`): as duas fileiras da frente do lote viram pátio (`PUMPJACK_ROWS`), com o estrado de
  madeira, o cavalete em A com a escora, o mancal do eixo, a caixa de engrenagens com as manivelas e os contrapesos e a
  cabeça do poço com a haste; o galpão baixo (até `PUMPJACK_SHED_M`) fica na fileira de trás. Tudo com as peças e a
  folha de texturas do kit (madeira e ferro): nenhum asset novo e nenhum material novo.
- **O balancim** (`BuildingKit.Rotor.rock`, `BuildingView`): a viga com a cabeça de ferro, a travessa e as bielas
  balançam em volta do eixo no alto do cavalete, até `PUMPJACK_ROCK` (0,28 rad) para cada lado, enquanto o poço produz,
  no tempo de jogo (para na pausa e com o poço parado). As partes que giram (moinho, roda d'água, polia) seguem iguais.
- A foto do poço no menu foi refeita.

## Números

- Benchmark: o mundo do benchmark não tem poço; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase73_pumpjack.gd`: o poço com o pátio e o galpão baixo (a torre continua nas minas), o
  balancim no alto do cavalete e dentro do pátio mesmo no ângulo maior, e o balanço para os dois lados sem passar da
  amplitude enquanto produz, parado com a saída cheia.
- Capturas: `tools/capture_phase73.tscn -- <pasta>` (no mundo plano, o poço de dois lados e de longe; em
  `F:\ferramentas\capturas\fase73`).

## Fica de fora (proposta à espera do dono)

- Um modelo próprio da usina a petróleo, o tanque de armazenagem ao lado do poço e o barulho da bomba.
