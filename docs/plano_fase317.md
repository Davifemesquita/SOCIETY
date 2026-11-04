# Plano da Fase 317 — Blocos no pé da garganta

**Estado: feita em 04/11/2026**, a terceira do roteiro `docs/plano_fases_315_319.md` (garganta do rio). No Anno, há blocos caídos no
leito, junto das paredes da garganta; no Society, a parede descia limpa até a água.

## O plano

- **Arquivos**: `presentation/river_stone_view.gd`, o teste novo e a captura do ciclo (`tools/capture_phase317.tscn`).
- **Risco**: mudar os matacões e os seixos da Fase 122. Os blocos têm o sorteio deles (`&"river_fallen"`) e entram por último na lista.
- **Como testar**: um rio feito à mão entre paredes altas e baixas, a captura e o benchmark.

## O que entrou

- **`RiverStoneView.Kind.FALLEN`** (no fim do enum), em `_fallen`, depois dos matacões e dos seixos:
  - na célula de rio sem ponte, a parede é a vizinha de terra mais alta, a pelo menos `FALL_DROP_M` (2,4 m);
  - uma célula a cada `FALL_CHANCE` (0,45) leva de `FALL_BLOCKS` (1 a 3) blocos da `RockModel`, no material da rocha do mar (com o
    limo junto da água);
  - o bloco sai de um ponto da célula com o leito debaixo d'água (uma grade de `FALL_STEPS` × `FALL_STEPS` pontos, até
    `FALL_WATER_M`) e anda para a parede até onde o leito ainda fica debaixo d'água, sem sair da célula;
  - o pé fica `FALL_SINK_M` abaixo do leito e o topo, de `FALL_TOP_M` (0,2 a 0,9 m) acima da água.
- **A primeira versão** partia do meio da célula. Nos rios estreitos, o meio fica acima da água (os cantos sobem com as paredes) e o
  lado da parede já é a encosta: os blocos ficavam enterrados na rocha, ou não saíam.
- **`tools/capture_phase317.tscn`**: o trecho de garganta de ilha temperada com mais blocos juntos, de cima, de perto e do outro lado.
  Serve também às Fases 318 e 319.

## Medida

72,7 FPS (316: 71,6), GPU 12,8 ms (316: 13,0); ~360 mil primitivas a mais no quadro com tudo visível. Neutra.

## Como testar

- `tests/world/test_phase317_gorge_blocks.gd`: blocos na célula de rio, meio dentro da água e na metade do lado da parede; a margem
  baixa sem; a ponte tirando; os blocos depois das pedras de antes na lista. O `test_phase122_river_stones.gd` segue passando.
- Captura: `tools/capture_phase317.tscn -- <pasta>`; o depois está em `F:\ferramentas\capturas\fase317\garganta3\` (o antes é a mesma
  garganta sem blocos).
