# Plano da Fase 196 — Patos na água

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_195_199.md` (cemitério, pato e rede, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`DuckView.candidates`, `flocks`): numa rede de pontos de `GROUP_STEP` células, com a chance `GROUP_CHANCE`, a água
  (mar ou rio) mais perto do ponto encostada numa terra baixa (`LOW_M`) e de fundo raso (`SHALLOW_M`); o meio da roda sai da
  costa até a roda toda passar sobre fundo de `RING_FLOOR_M` e longe da terra (`LAND_CLEAR_M`): perto da costa a espuma da
  linha d'água pinta a água de branco, e o pato boiava nela. Os bandos que o terreno permite são feitos uma vez por mundo; na
  obra só se refaz o filtro dos portos (`HARBOR_CELLS` do entreposto, do píer, da cabana de pesca e do estaleiro).
- **Os bandos**: metade é a pata na frente com três a seis patinhos em fila atrás, mais juntos; a outra, de dois a cinco patos e
  patas. Nadam em roda no tempo de jogo, de frente para onde vão, balançando na água, e os grandes mergulham a cabeça de tempos
  em tempos, girando no peito com o rabo para cima (`pose`, `dabble`). Os patos (o macho de cabeça verde e colar branco, a pata
  parda) um pouco maiores que de verdade (`SIZE`), para se verem da câmera do jogo. Dois MultiMesh sem sombra; somem à noite.
- **Custo**: a primeira busca levava 226 ms no arquipélago da semente 1840 (o jogo novo e o carregar subiram ~0,25 s). Ficou em
  12 ms: os nove pontos de prova pulam o quadrado sem costa (`_mixed`), a varredura anda em anéis e lê a grade direto antes de
  conferir a beira (`_nearest_shallows`), e a distância da terra é guardada por célula (`clear_cell`).

## Como testar

- `tests/world/test_phase196_ducks.gd`: os bandos nadam sobre água funda o bastante e longe da terra; cada pato vai pela roda de
  frente para onde nada; os patinhos seguem a pata; nenhum bando perto do porto; o mergulho vem e vai; a ilha plana não tem.
- Captura: `tools/capture_phase196.tscn` (uma família e um bando na semente 1840, às 9h).
