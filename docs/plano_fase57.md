# Plano da Fase 57 — Pedras soltas com a rocha gerada

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir para a próxima fase"; era a primeira proposta que ficou
de fora da Fase 56). Só apresentação: a simulação, o terreno e as assinaturas não mudam; nada vai no save.

## O que faltava

As pedras soltas dos barrancos altos e do litoral rochoso (Fase 36, `TreeView`) ainda eram as lajes lisas do Kenney
(`rock_largeA`/`rock_largeB`, 1,6 m), ao lado dos rochedos e das rochas de falésia facetados da Fase 56: duas rochas de
estilos diferentes na mesma encosta.

## O que entrou

- A `TreeView` desenha as pedras soltas com as quatro formas da `RockModel` (uma cópia da malha guardada, com o material
  da `RockView`: a textura de rocha do terreno, triplanar no mundo, com a mesma cor). Os mesmos lugares e as mesmas
  chances de antes (`rock_chance`); a forma sai do mesmo sorteio da célula.
- Medida: raio de 1 m (de 0,7 a 1,3 vez, pelo sorteio de antes), 1,25 vez mais alta que larga; a parte de baixo da
  `RockModel` (y abaixo de zero) fica enterrada e a pedra ainda afunda 0,15 m na malha com o detalhe das encostas.
- Os dois `.glb` das pedras do Kenney saíram do projeto; as palmeiras do pacote continuam.

## Números

- Benchmark (alto, RTX 5060): 1109 draw calls (17 a menos); dia inteiro 55,6 FPS, GPU 10,7 ms, igual ao commit da
  Fase 56 medido na mesma hora (55,6 FPS, GPU 10,9 ms): a fase é neutra e a queda contra as Fases 55 e 56 é da máquina
  nesta hora (detalhes em `docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase57_loose_rocks.gd`: as camadas das pedras usam a malha da `RockModel` (mesmo número de
  vértices, a guardada sem material) com o material da `RockView`, em mais de uma forma; cada pedra é 1,25 vez mais alta
  que larga, com raio dentro do sorteio, e com o fundo abaixo do chão desenhado.
- `tests/world/test_phase36_slopes.gd` continua valendo (material triplanar com textura, chances nos barrancos e no
  litoral).
- Capturas: `tools/capture_phase57.tscn -- <pasta>` (pedras soltas de perto, longe da mata, semente 1840; em
  `F:\ferramentas\capturas\fase57`).

## Fica de fora (proposta à espera do dono)

- Tornar o rochedo não construível; afinar a malha da falésia; palmeiras e mata tropical nas ilhas do sul (as palmeiras
  ainda são do Kenney).
