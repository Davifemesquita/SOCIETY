# Plano da Fase 36 — Encostas de pedra (nossa)

**Estado: em andamento desde 25/10/2026**, com a confirmação do dono do produto ("pode ir para a próxima fase").
Quinta fase do roteiro de `docs/plano_melhorias.md`. Só apresentação: nenhuma altura da simulação, contorno ou
assinatura muda, e nada vai para o save. **Feita sem tela** (decisão do dono): capturas e benchmark esperam ele liberar.

## 1. Detalhe visual do relevo (`world/terrain/terrain_detail.gd`, `TerrainView`)

- Um deslocamento de altura por canto da grade, só na malha desenhada: os barrancos ganham largura variável (ruído
  suave, até `WIDTH_M`) e sulcos de erosão "falsa" (ruído ridged, até `GULLY_M`), mais fortes quanto mais íngreme.
- **Onde**: um canto só se mexe se as 4 células que o tocam forem terra, íngremes demais para prédio, sem árvore (nem
  derrubada, para o save carregado desenhar igual) e sem estrada nem prédio. Assim toda célula com algo em cima (ou que
  possa receber prédio) tem os 4 cantos na altura da simulação.
- **Desvio do plano**: o plano pedia também as células vizinhas protegidas. Com esse anel nenhum canto se mexia na
  semente 1840 (os barrancos têm 1 a 2 células de largura); ficou só a própria célula.
- **Estrada nova num barranco** (a estrada vai até `max_road_relief_m`, 2 m, então pode cair numa célula com detalhe):
  a `TerrainView` zera os cantos da célula e refaz só os trechos de malha atingidos.
- O cursor continua na altura da simulação (`StrategyCamera.ground_point` lê `surface_height`, não a malha).

## 2. Pedras de rocha de verdade (`TreeView`)

- As pedras do Kenney Nature Kit (já no projeto) perdem o recolorido "verde-cinza" e ganham a textura de rocha do
  terreno, triplanar no mundo (casa com a falésia em volta e não estica).
- Mais pedras nos barrancos altos (chance de 12% para 25%) e pedras no litoral rochoso (terra encostada no mar com
  desnível de pelo menos 1,2 m), sentadas na malha com o detalhe e afundadas um pouco.
- As rochas da Poly Haven do plano não entraram: as do kit com a textura de rocha resolvem sem asset novo.

## Fica de fora

Alturas da simulação; os níveis globais dos patamares (Fase 45); erosão real por gotas.

## Riscos

- Normais na emenda de trechos refeitos por estrada nova podem ficar levemente diferentes do vizinho.
- Uma pedra perto de uma estrada nova pode ficar um pouco acima ou abaixo do chão refeito (as pedras não são refeitas).
- Sem captura, o tamanho do detalhe vai sem ser visto: os números ficam em constantes do `TerrainDetail`.

## Como testar

- `tests/world/test_phase36_slopes.gd` (sem tela): os 4 cantos de toda célula protegida sem deslocamento e o detalhe
  existindo nos barrancos (semente 1840), determinismo, árvores derrubadas não mudam nada, estrada nova num barranco
  volta à altura da simulação, e as pedras com material de rocha triplanar.
- `tests/world/test_terrain_water_trees.gd`: a malha é a altura da simulação mais o detalhe.
- O teste dourado do terreno segue passando.
- Quando o dono liberar a tela: capturas `02_ilha_principal` e `06_mina_na_jazida`, e o benchmark.

## Pronto quando

A 420 m as encostas deixam de ser riscos claros e finos; a 55 m a falésia tem pedra de verdade (as duas só na tela).
