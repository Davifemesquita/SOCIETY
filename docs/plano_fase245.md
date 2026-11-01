# Plano da Fase 245 — Coelhos no prado

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_245_249.md` (coelho, cogumelo e pedra, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`RabbitView.warrens`, `_open`): numa rede de pontos de `WARREN_STEP` células das ilhas temperadas com relevo, a célula de
  capim aberto (terra sem árvore, prédio, estrada nem trilho, quase plana, acima da praia) mais perto do ponto e sem prédio perto,
  pelos blocos de `SealView.WILD_CELLS` das focas da Fase 189 (longe das vilas), com a chance `WARREN_CHANCE`.
- **Os coelhos** (`rabbits`, `rabbit_mesh`, `sit_up`): de três a cinco por toca em volta da célula, cada um virado pelo hash; o
  corpo redondo, a cabeça, as orelhas compridas em pé, os olhos, o rabo branco e as patas. Agachados pastando quase sempre, sentam
  nas patas de trás (o corpo gira em volta do pé de trás) um pouco a cada volta, cada um no seu ritmo, no tempo de jogo. Um
  MultiMesh sem sombra (são pequenos); refeito também na derrubada de árvores.

## Como testar

- `tests/world/test_phase245_rabbits.gd`: na semente 1840, as tocas ficam em capim aberto, com três a cinco coelhos cada; uma casa
  perto tira a toca dali; as tropicais e a ilha plana não têm; o coelho fica agachado na maior parte do tempo; ele é pequeno, com as
  orelhas compridas.
- Captura: `tools/capture_phase245.tscn` (a semente 1840; `coelhos_N.png`, `coelhos_N_sentados.png`, `coelhos_N_longe.png`).
