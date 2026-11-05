# Plano da Fase 320 — Franja em tufos

**Estado: feita em 05/11/2026**, a primeira do roteiro `docs/plano_fases_320_324.md` (garganta de perto). De perto (abaixo de ~15
m), a franja de capim das Fases 312 e 316 parecia um pente: onze folhas chatas, iguais e paralelas, em fileira reta ao longo de cada
lado de célula.

## O plano

- **Arquivos**: `presentation/cliff_fringe_view.gd` e o teste novo.
- **Risco**: mais triângulos por pedaço (a franja está em toda borda de falésia e de garganta). O lugar e o tamanho de cada pedaço
  (Fase 312) não mudam; o giro e o recuo saem de um sorteio à parte.
- **Como testar**: o teste novo, os das Fases 312 e 316, a captura da garganta e o benchmark.

## O que entrou

- **`CliffFringeView.tuft_blades`**: `TUFTS` (4) tufos ao longo do pedaço, cada um com `BLADES_PER_TUFT` (6) folhas saindo do
  mesmo pé e abrindo num leque de `FAN_RAD`; comprimento (`REACH`), subida (`LIFT`), queda (`DROOP`), meia largura (`HALF_WIDTH`),
  torção (`TWIST_RAD`) e tom (do verde-escuro `LEAF_DARK` ao seco `LEAF_DRY`) sorteados por um gerador de semente fixa (a malha é a
  mesma em toda partida). A ponta não passa de `EDGE_X` para os lados.
- **`fringe_mesh`**: cada folha é uma fita de `SEGMENTS` pedaços, que vai para fora depressa no começo e devagar no fim (curva),
  sobe e pende, afinando e clareando para a ponta. 192 triângulos por pedaço (antes 66).
- **`_edge`**: cada pedaço sai girado até `YAW_JITTER_RAD` e com o pé até `INSET_JITTER_M` mais para dentro ou para fora, pelo
  hash da célula com a semente 320.

## Medida

31,0 FPS, GPU 26,9 ms, primitivas +0,4%. A máquina estava mais lenta nesta rodada: o código da 319, medido logo antes nas mesmas
condições, deu 30,9 FPS e GPU 26,7 ms. Neutra.

## Como testar

- `tests/presentation/test_phase320_fringe_tufts.gd`: os tufos em leque, folhas de comprimento, largura e tom diferentes, a malha
  igual a cada vez e ainda pendendo para fora, os pedaços girados sem perder o rumo da queda; os das Fases 312 e 316 seguem passando.
- Captura: `tools/capture_phase317.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase317\garganta3\` e depois em
  `F:\ferramentas\capturas\fase320\depois\`.
