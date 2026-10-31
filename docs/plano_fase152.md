# Plano da Fase 152 — Balizas com corrente

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_150_154.md` (coluna, placa e velocípede, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BollardView.edges`): em cada lado de uma célula do largo calçado da Fase 109 (`ForecourtView.cells`, em volta
  da igreja, do teatro, da universidade, da prefeitura, do museu e da escola) que dá para uma estrada, `BOLLARD_IN_M` para
  dentro da célula, na altura das lajes. Um lado em `OPEN_EVERY` fica aberto, pelo desenho da grade (é por onde se entra
  no largo), e o lado do poste de gás da rua também (a corrente passaria por ele). Só nas ilhas com relevo (o largo é delas).
- **As balizas e a corrente** (`bollard_mesh`, `_chain`): uma baliza de ferro em cada ponta do lado — pé largo, fuste
  afinando, o anel e a cabeça —, as que se encontram valendo uma só, e a corrente caindo em parábola de `CHAIN_SAG_M` entre
  elas, em elos alternados deitados e em pé. Uma malha só para o arquipélago (`GameScreen.bollard_view`), refeita na obra,
  na demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

## Como testar

- `tests/world/test_phase152_bollards.gd`: com a rua na frente de uma escola, os lados com balizas têm uma célula de
  comprimento, ficam numa célula do largo e na altura das lajes; nenhuma corrente passa pelo lado do poste de gás; sem rua
  encostada no largo, nada; a ilha plana não tem.
- Captura: `tools/capture_phase152.tscn` (semente 1840: uma escola com a rua calçada em volta; `largo.png` e
  `balizas_de_perto.png`, esta com a câmera posta à mão).
