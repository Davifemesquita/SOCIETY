# Plano da Fase 55 — Malha fina na linha d'água

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir para a próxima fase"; era a primeira proposta que ficou
de fora da Fase 54). Só apresentação: a simulação, as alturas da grade e as assinaturas do terreno não mudam.

## O que faltava

Depois da Fase 54 a espuma, a areia e a plataforma já seguiam a linha d'água exata, mas a malha do terreno continuava com
um vértice a cada 2 m: dentro de cada quadrado a costa era uma reta de canto a canto, e de perto o contorno da água
contra a terra virava um polígono.

## O que entrou

- **`CoastRefine`** (`world/terrain/coast_refine.gd`): o quadrado que a linha d'água atravessa (um canto abaixo do mar e
  outro acima) vira uma subgrade de `terrain_coast_subdivisions` × `terrain_coast_subdivisions` (3, ou seja, 0,67 m).
  As alturas novas saem por Catmull-Rom das 4 × 4 alturas vizinhas.
  - Os cantos da grade ficam iguais (a simulação continua mandando neles).
  - A altura curva fica entre os cantos que pesam no ponto (sem ressalto acima da terra nem abaixo do fundo) e a até
    `terrain_coast_refine_max_m` (0,8 m) da reta entre eles.
  - Sem fresta: toda conta parte das coordenadas absolutas da subgrade, então o ponto da borda comum a dois quadrados
    finos sai igual dos dois lados (na borda só os dois cantos dela pesam). Na borda com um quadrado comum, a altura é a
    da reta dele.
  - A normal dos pontos novos é a dos cantos pela interpolação linear (contínua com o resto da malha).
- **`TerrainView._chunk_mesh`**: os quadrados comuns continuam pela diagonal do relevo (Fase 54); os da linha d'água
  levam a subgrade, cada subquadrado também pela diagonal do relevo. `terrain_coast_subdivisions = 1` desliga.

## Números

- Benchmark (alto, RTX 5060): quadro com tudo visível 11 ms (91 FPS), dia inteiro 88,9 FPS, GPU 10,6 ms (igual à Fase
  54); jogo novo 8,7 s contra 8,0 s (a subgrade sai em GDScript; o resto da rodada também mediu um pouco mais lento).

## Como testar

- `tests/world/test_phase55_coast_mesh.gd`: só os quadrados da costa se dividem, os cantos da grade ficam na altura da
  simulação, a borda comum sem fresta, a borda com quadrado comum na reta, a costa curva mais perto do relevo de
  verdade que a reta (uma ilha redonda e lisa: menos da metade do erro) e a validação da configuração.
- `tests/world/test_terrain_water_trees.gd`: os vértices da grade seguem exatos; os da subgrade, a até 0,8 m.
- Capturas: `tools/capture_phase52.tscn -- <pasta>` (comparar `F:\ferramentas\capturas\fase54` e `fase55`; de longe a
  diferença é pequena, ela aparece de perto).

## Fica de fora (proposta à espera do dono)

- Rochedos e falésias com malha de rocha própria; palmeiras e mata tropical nas ilhas do sul.
- Afinar também a falésia (os quadrados íngremes longe da água seguem de 2 em 2 m).
