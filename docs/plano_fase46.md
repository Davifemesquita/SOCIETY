# Plano da Fase 46 — Calçamento e esquinas

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima
quinta fase do roteiro de `docs/plano_melhorias.md`. Foi a grade dual (o plano A); o grafo com Chaikin (plano B) não foi
preciso, porque a sela decidida pela simulação e o chanfro da diagonal resolveram a escada. **A escolha entre dual e
grafo e a aprovação das peças continuam com o dono**, pelas capturas. Nada aparece na tela do dono (testes sem janela;
capturas e benchmark na área de trabalho escondida).

## 1. Grade dual (`presentation/paved_dual.gd`, `PavedDual`)

- **Máscara de 4 bits por canto da grade**: as quatro células em volta (1 a de cima à esquerda, 2 a de cima à direita,
  4 a de baixo à direita, 8 a de baixo à esquerda); `case_of(máscara)` devolve a peça e o giro em quartos de volta.
  Seis peças: vazio, canto de fora (arredondado, raio `ROUND` da meia célula), borda reta, sela, canto de dentro
  (concordância de raio igual) e cheio.
- **Sela pela simulação**: duas células só encostadas pela quina viram uma faixa a 45° se `RoadNetwork.linked_diagonal`
  as liga (a diagonal pura); se não, dois cantos de fora (`saddle_linked`).
- **Diagonal sem gomos**: o canto de fora de uma célula ligada na diagonal que passa ao lado dele vira chanfro — a mesma
  faixa reta da sela, com o meio-fio contínuo (`in_side_diagonal`, `_chamfer`). Sem isso a diagonal virava uma corrente de
  gomos redondos (achado na primeira captura).
- **Meio-fio e sarjeta dentro das peças**: o meio-fio (`CURB_WIDTH_M` 0,22, `CURB_HEIGHT_M` 0,1) e a sarjeta
  (`GUTTER_WIDTH_M` 0,3) seguem a borda de cada peça, deslocada para dentro; o calçamento fica `LIFT_M` (7 cm) acima do
  chão, a sarjeta 1 cm acima do calçamento (sem z-fighting). A cor do vértice escolhe calçamento, sarjeta ou meio-fio em
  `shaders/paved_dual.gdshader`, que reaproveita as texturas do paralelepípedo da RoadView.
- **A ponte de pedra conta como calçada** na máscara (sem meio-fio de través na cabeceira); o tabuleiro dela segue com a
  RoadView.

## 2. RoadView (`presentation/road_view.gd`)

- O paralelepípedo fora da ponte não tem mais ladrilho nem meio-fio no MultiMesh, e a faixa diagonal pedra–pedra é a
  sela. A terra (pintada pela Fase 38 na ilha com relevo, ladrilho na plana), as pontes, as touceiras e as pedras soltas
  ficam como estavam.
- **Malha por trechos**: `Paved_<ilha>` com filhos `Chunk_x_y` de `DUAL_CHUNK` (32) células; a geometria de cada canto
  fica guardada, e uma estrada nova refaz só os cantos em volta da diferença (com uma célula de folga: o chanfro olha duas
  células adiante) e só os trechos atingidos (`dual_corners_rebuilt`).

## Números

- **Testes** (sem janela): 7.911 células de paralelepípedo montam em ~1,1 s; uma rua nova, 76 ms, dos quais 70 são o resto
  da RoadView (ladrilhos de terra e pontes) e ~6 a grade dual.
- **Benchmark** (área de trabalho escondida, contra a Fase 45): todas as medidas antigas iguais dentro do ruído (a cidade
  do benchmark é de terra). A linha nova calça as 2.812 células da cidade no fim: calçar tudo de uma vez 75 → 437 ms (só
  ao carregar ou trocar o mundo), mais uma rua 70 → 40 ms, quadro com tudo visível 14,5 → 14,3 ms, objetos 2.916 → 2.964
  e draw calls 1.146 → 1.194 (os trechos).

## Fica de fora

- Road Generator, avenidas e estradas de 2 células; mudar a conectividade ou os caminhos dos pedestres.
- Peças de arte modeladas: as seis peças são geométricas, no código; o desenho do meio-fio (perfil, juntas) pode virar
  arte depois, se o dono quiser.
- Calçar tudo de uma vez numa thread (os 437 ms ao carregar uma cidade toda de pedra): medido, fica para quando pesar.

## Riscos

- O meio-fio cruza a calçada em transições raras (pedra encostando na ponte de terra); a faixa diagonal invade um pouco
  as células vizinhas perto das quinas (como invadia a faixa de ladrilho antes).
- Terreno muito inclinado: a peça segue a altura do chão vértice a vértice, a 7 cm.

## Como testar

- `tests/world/test_phase46_paving.gd`: a tabela dos 16 casos (6 peças e o giro); a sela segue `linked_diagonal`; o canto
  de fora arredondado e o de dentro com concordância; meio-fio e sarjeta dentro da peça; a diagonal pura é uma faixa
  reta (nenhum vértice passa da linha); uma rua nova refaz só 16 cantos; a RoadView sem ladrilho de paralelepípedo e com
  o shader novo; o tempo de uma cidade grande.
- `tests/world/test_phase38_roads.gd` e `tests/presentation/test_road_details.gd` atualizados (o paralelepípedo saiu dos
  ladrilhos). O teste da ponte de pedra lê dados do MultiMesh: só passa com janela (já era assim antes da fase; fica com
  o CI).
- Capturas: `tools/capture_phase46.tscn` (L, cruzamento, T, diagonal e a terra encostando, a 40, 70 e 120 m). O mesmo
  roteiro roda numa cópia anterior à fase, para o antes e depois.

## Pronto quando

A 40 m não há esquina em ângulo reto seco nem diagonal em escada (as capturas mostram); o pior quadro de construção se
mantém (obra com a ilha cheia 18 ms, igual). **Proposta à espera do dono**: aprovar as peças e a grade dual pelas
capturas.
