# Plano da Fase 56 — Rocha nos rochedos e nas falésias

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir para a próxima fase"; era a proposta seguinte que ficou
de fora das Fases 54 e 55). Só apresentação: a simulação, o terreno e as assinaturas não mudam; nada vai no save.

## O que faltava

Os rochedos do v3 (Fase 52) eram montes lisos do relevo, com a textura de rocha do shader, e a face das falésias só
tinha as pedras do Kenney (1,6 m, as mesmas da Fase 36). De perto não pareciam rocha partida como no Anno.

## O que entrou

- **`RockModel`** (`presentation/rock_model.gd`): rocha gerada no código, sem asset novo. Icosfera subdividida duas vezes,
  raio mexido por ruído, seis planos de corte (faces chatas de rocha partida) e o topo sempre cortado quase na horizontal
  (bloco, não ponta); faces de normal chapada. Medida normalizada (x e z até 1, y de −0,4 a 1); quatro variantes fixas.
- **`RockView`** (`presentation/rock_view.gd`), montada pela `GameScreen` depois das árvores, a partir das alturas
  desenhadas de cada região (`TerrainView.region_heights`, com o detalhe das encostas). Um MultiMesh por ilha e por
  variante, com a textura de rocha do terreno, triplanar no mundo (casa com a falésia em volta), até 900 m.
  - **Rochedo**: pedaço de terra acima de 2 m (a faixa rasa que às vezes o liga à costa fica abaixo) com até 600 cantos,
    bem menor que a maior terra da região, com pelo menos 35% de um anel 3 células além dele debaixo d'água (um morro no
    meio da planície não conta) e sem praia baixa construível sob a borda do bloco. Ganha um bloco que cobre o monte, um
    pilar mais estreito que passa do topo e de 2 a 4 pedras na água em volta.
  - **Falésia**: canto de terra com queda de 2,4 m até o vizinho e mar até 3 cantos abaixo ganha uma rocha encaixada
    na encosta (no máximo uma por bloco de 2 × 2 cantos, 70% deles), deslocada para baixo, inclinada para o mar, larga
    (raio de pelo menos metade da altura) e com o topo 0,25 m abaixo do canto de cima: não sobe no lote plano da borda.
    Nunca onde caberia estrada ou prédio (só mar, fora da grade ou célula íngreme demais e sem nada em cima).

## Números

- Benchmark (alto, RTX 5060): +20 draw calls; na mesma hora, com e sem a `RockView`, o dia inteiro deu 77,7 e 78,8 FPS
  e a GPU 11,8 e 11,5 ms (a rocha custa até ~0,3 ms). A máquina mediu mais lenta nesta hora que na Fase 55 (91 FPS de
  manhã), com ou sem rocha.

## Como testar

- `tests/presentation/test_phase56_rocks.gd`: a malha (faces chapadas, de frente para fora no sentido do Godot, medida
  normalizada, variantes diferentes e guardadas), o rochedo de um mar de teste (bloco no meio, topo acima do monte,
  pilar mais alto, raio que cobre o pé), o morro na planície baixa sem rochedo, as rochas da falésia só na borda e com o
  topo abaixo dela, a praia suave sem rocha e, num arquipélago gerado, rochedos e falésias com rocha e nenhuma rocha de
  falésia em célula de obra.
- Capturas: `tools/capture_phase56.tscn -- <pasta>` (dois rochedos e dois trechos de falésia de perto, semente 1840; em
  `F:\ferramentas\capturas\fase56`).

## Fica de fora (proposta à espera do dono)

- O rochedo continua terra na simulação: quem construir em cima de um (se o lote couber) vê a rocha atravessando o
  prédio. Tornar o rochedo não construível mexe nas regras e nas assinaturas.
- Trocar as pedras do Kenney (lajes de 1,6 m) pela `RockModel`; afinar a malha da falésia; palmeiras e mata tropical
  nas ilhas do sul.
