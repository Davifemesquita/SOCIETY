# Plano da Fase 108 — Farol

**Estado: feita em 30/10/2026**, quarta do roteiro `docs/plano_fases_105_109.md` (cidade e porto, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`LighthouseView.site`): em cada ilha com relevo e entreposto, a célula de terra livre (sem prédio, estrada,
  trilho nem árvore), baixa (até `MAX_HEIGHT_M`), a até `SEARCH_CELLS` do entreposto, com mais mar no quadrado de
  `EXPOSURE_CELLS` em volta (pelo menos `MIN_SEA_CELLS`); no empate, a mais perto. A célula não fica reservada: se alguém
  constrói ou passa estrada nela, o farol vai para a próxima ponta (a vista refaz na obra, na demolição e na estrada).
- **A torre** (`tower_mesh`): soco de pedra, fuste afinando em quatro lanços (caiados e com as faixas vermelhas), galeria de
  ferro com balaústres e corrimão, a base e os montantes da lanterna, a cúpula vermelha e o remate, cor no vértice.
- **A luz**: o vidro da lanterna (`lantern_mesh`) acende com a noite no material do vidro dos postes (`night_glow`); dois
  fachos opostos (`beam_mesh`, cones deitados de `BEAM_LENGTH_M`, mais fortes junto da lanterna e sumindo na ponta, em
  mistura aditiva) giram uma volta a cada `BEAM_TURN_S` de jogo (param na pausa) e só aparecem de noite.

## No caminho

- O facho não aparecia: a água é transparente e do tamanho do mar, e era desenhada depois dele, por cima. O material do
  facho ganhou `render_priority` acima da água (como a prévia de construção da Fase 33).

## Como testar

- `tests/world/test_phase108_lighthouse.gd`: a ponta é terra livre, baixa, perto do entreposto e com o mar em volta; uma
  estrada na ponta muda o farol de lugar; um farol por ilha com entreposto, nenhum antes; nada na ilha plana.
- Captura: `tools/capture_phase108.tscn` (semente 1840: `farol_dia.png`, `farol_de_perto.png`, `farol_anoitecer.png` e
  `farol_noite.png`, com os fachos).
