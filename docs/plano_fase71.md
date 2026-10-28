# Plano da Fase 71 — O trem no trilho

**Estado: feita em 28/10/2026, a pedido do dono** ("pode ir para a próxima"; a primeira proposta deixada de fora na
Fase 70). Só apresentação: a simulação, o save, o determinismo e as assinaturas não mudam; o petróleo continua indo na
hora pelo `RailSystem`.

## O que entrou

- **Caminho pelo trilho** (`RailNetwork.route`): o caminho mais curto, célula a célula (vizinhas de lado), de uma
  célula de trilho encostada no lote do poço até uma encostada no lote da usina; vazio se nenhum trilho liga os dois.
  `RailNetwork.side_cells` (as células encostadas num lado do lote) passa a servir o `touching` e o `route`.
- **Trem** (`TrainView`): um por ligação do `DerivedState.rail_feeds` — uma locomotiva a vapor (estrado vermelho, três
  pares de rodas, caldeira com chaminé, cabine verde) puxando um vagão-tanque, gerados no código (sem asset). Espera
  carregando no poço com o trem inteiro no trilho, anda até a usina a 5 m/s de jogo, espera descarregando e volta de ré,
  com a locomotiva sempre virada para a usina; cada vagão segue as curvas e as encostas do trilho
  (`RailView.ground_point`). O relógio de cada trem anda no tempo de jogo (para na pausa) e para quando o poço ou a usina
  estão pausados; trilho cortado, prédio novo ou demolido refazem os trens no quadro seguinte (o trem que continua
  segue de onde estava). Trilho mais curto que o trem: o trem fica parado.
- O material é o mesmo do trilho (cor por vértice): nenhuma pipeline nova para compilar no meio da partida.

## Números

- Benchmark (alto, RTX 5060): o mundo do benchmark não tem trilho, então nada muda nele (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase71_train.gd`: o caminho pelo trilho (encostado nos dois lotes, contínuo, o mais curto),
  um trem por ligação esperando e depois andando com o vagão atrás, o vaivém da frente da locomotiva ao longo do ciclo,
  o trem parado com o poço pausado e sumindo com o trilho cortado.
- Capturas: `tools/capture_phase71.tscn -- <pasta>` (no mundo plano: o trem no poço, na curva do L e de longe chegando
  à usina; em `F:\ferramentas\capturas\fase71`).

## Fica de fora (proposta à espera do dono)

- Fumaça na chaminé, o trem levando o petróleo de verdade (hoje a carga vai na hora e o trem é enfeite), mais de um trem
  por linha, desvios e sinais, e o desfazer do trilho no histórico.
