# Plano da Fase 121 — Gavião sobre a cidade

**Estado: feita em 30/10/2026**, segunda do roteiro `docs/plano_fases_120_124.md` (fios, riacho e mansarda, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`HawkView.centers`): cada ilha com pelo menos `MIN_HOUSES` casas ganha um gavião, e mais um a cada
  `HOUSES_PER_HAWK` casas, até `MAX_PER_ISLAND`, todos em volta do meio das casas da ilha.
- **O voo** (`pose`): círculos largos e altos (raio em `RADIUS_M`, altura em `HEIGHT_M`, sentido pela semente), subindo e
  descendo `BOB_M`, com o meio derivando `DRIFT_M` devagar; o corpo de frente para onde vai e inclinado para dentro da volta.
  No tempo de jogo (para na pausa); some à noite.
- **A batida** (`beat`): umas batidas no começo de cada ciclo de `CYCLE_S` (`FLAP` dele) e o planeio no resto, com as asas
  um pouco erguidas (`GLIDE`), pelo mesmo `shaders/bird.gdshader` dos outros pássaros.
- **A malha** (`hawk_mesh`, gerada no código): corpo, cabeça clara, cauda em leque e as asas largas com o cotovelo e as penas
  da ponta abertas em quatro dedos escuros; desenhada `SCALE` vezes maior que o real, que sumia de onde a câmera fica.

## Como testar

- `tests/world/test_phase121_hawks.gd`: sem cidade não há gavião, cidade grande ganha mais um; o voo fica dentro da faixa de
  raio e altura e sem saltos; ele plana quase o tempo todo; a vista põe um por meio.
- Captura: `tools/capture_phase121.tscn` (semente 1840: uma rua de casas e o gavião de perto planando e batendo a asa, com a
  câmera posta à mão, e a cidade de longe).
