# Plano da Fase 62 — Malha fina na face da falésia

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir"; era a proposta "afinar a malha da falésia" que
ficou de fora das Fases 56 a 61). Só apresentação: a simulação, o terreno da simulação e as assinaturas não mudam;
nada vai no save.

## O que faltava

A Fase 55 afinou só os quadrados (2 m) que a linha d'água atravessa. A face seca da falésia continuava em planos de
2 m, de canto a canto, lisos e esticados: a textura de rocha escorria em faixas e a borda de cima era uma quina reta.

## O que entrou

- **`CoastRefine.steep` e `refines`** (`world/terrain/coast_refine.gd`): o quadrado todo acima do mar com desnível de
  `terrain_cliff_refine_relief_m` (2,4 m) ou mais entre os cantos também vira a subgrade de 3 × 3 da Fase 55, com a
  mesma curva de Catmull-Rom, os mesmos cantos e as mesmas bordas (reta na borda com um quadrado que não se divide,
  conta igual dos dois lados na borda comum). O limite fica acima de `max_road_relief_m` (2,0 m; a config recusa
  menos): nenhuma célula onde se constrói ou passa estrada muda.
- **Aspereza de rocha** (`terrain_cliff_rough_m`, 0,35 m): cada ponto novo bem acima d'água (de 0,5 m para cima, sem
  descer de 0,3 m) sobe ou desce por um ruído fixo do ponto, na medida do desnível dos cantos que pesam nele (nada até
  2,4 m, cheia a partir de 4,8 m). Vale para a falésia seca e para a que desce no mar; a praia suave e a linha d'água não
  mudam. Continua dentro dos cantos que pesam no ponto e a até 0,8 m da reta.
- **Normais pela subgrade**: os pontos novos tiram a normal das alturas da subgrade em volta, e a rocha partida aparece
  na luz; os cantos da grade seguem com a normal de sempre (contínua com o resto da malha).

## Números

- Benchmark (alto, RTX 5060), contra a mesma hora com a falésia desligada: +20 256 primitivas no quadro com tudo
  visível, os mesmos draw calls, a GPU igual (21,9 contra 22,0 ms) e ~1 s a mais no jogo novo com a máquina lenta
  (~0,4 s na velocidade normal; detalhes em `docs/benchmark.md`).

## Como testar

- `tests/world/test_phase62_cliff_mesh.gd`: numa falésia de teste, só a coluna da face se divide (cada quadrado troca 2
  triângulos por 18), o limite fica acima da estrada mais íngreme e a config recusa menos, os pontos ásperos ficam nos
  cantos e na folga da reta (e mexem), e o plano e a encosta suave não mudam nada.
- `tests/world/test_phase55_coast_mesh.gd` desliga a falésia e continua isolando a costa.
- Capturas: `tools/capture_phase62.tscn -- <pasta> [liso]` (os três trechos de maior desnível da ilha principal, com e
  sem o refinamento; em `F:\ferramentas\capturas\fase62`).

## Fica de fora (proposta à espera do dono)

- Tornar o rochedo não construível (mexe nas regras e nas assinaturas).
