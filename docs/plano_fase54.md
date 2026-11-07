# Plano da Fase 54 — Costa lisa (sem a escada da grade na linha d'água)

**Estado: feita em 26/10/2026, a pedido do dono** ("vá para a próxima fase"; o serrilhado da costa era o que mais se
destacava do Anno nas capturas das Fases 52 e 53). Só apresentação: a simulação, as alturas e as assinaturas do terreno
não mudam.

## O que causava a escada

1. A distância até a costa (`TerrainBake.signed_coast`, Fase 35) punha a linha d'água sempre no meio entre um canto de
   terra e um de mar: o contorno da espuma, da areia molhada e da plataforma seguia os quadrados da grade de 2 m.
2. A malha do terreno dividia todo quadrado pela mesma diagonal: a costa e a falésia que corriam na outra diagonal viravam
   dentes de serra.
3. A praia do shader vinha do tipo de chão por célula (`near_sea` da grade), com borda em quadrados.

## O que entrou

- **Linha d'água exata**: o canto dos dois lados da linha começa com a distância até onde a altura cruza o zero
  (interpolada pelas alturas, nos vizinhos de lado e de diagonal), e o chanfro espalha o resto. Numa costa a 30° o erro
  ficou abaixo de 1,2 m (antes chegava a uma célula inteira, em degraus).
- **Diagonal pelo relevo** (`TerrainView._chunk_mesh`): cada quadrado se divide pela diagonal de menor diferença de
  altura (a que segue a crista ou o vale).
- **Praia pela distância** (`terrain.gdshader`, `beach_m` 6 m e `beach_top_m` 2,4 m): com o campo da costa, a areia sai da
  distância até a linha d'água com borda de ruído; nunca acima da falésia nem na encosta de rocha (a falésia mostra rocha
  até a água).

## Números

- Benchmark (alto, RTX 5060): quadro com tudo visível 11 ms (90 FPS), dia inteiro 87,6 FPS, GPU 10,7 ms (igual); jogo
  novo 8,0 s contra 7,6 s (a distância até a costa olha os oito vizinhos de cada canto).

## Como testar

- `tests/world/test_phase54_smooth_coast.gd`: a distância numa costa diagonal perto da verdadeira, a diagonal de cada
  quadrado pelo relevo e a praia no shader pela distância.
- `tests/world/test_phase35_coast.gd`: os valores esperados mudaram para a linha exata (de −1 para 2 m a linha fica a um
  terço do canto do mar, não no meio).
- Capturas: `tools/capture_phase52.tscn -- <pasta>` (comparar `F:\ferramentas\capturas\fase53` e `fase54`).

## Fica de fora (proposta à espera do dono)

- Subdividir a malha só na beira (mais vértices que a grade da simulação) para costas ainda mais redondas de perto.
- Rochedos e falésias com malha de rocha própria; palmeiras e mata tropical nas ilhas do sul.
