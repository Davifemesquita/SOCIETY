# Plano da Fase 139 — Redes de pesca

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_135_139.md` (galinha, forno e mina, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`FishNetView.sites`, `cells`): ao lado de cada cabana de pesca, a célula livre encostada nela (lados e cantos)
  mais perto do meio da metade da cabana do lado do mar, num dos lados dela (o mar pelo `HarborView.seaward`); de terra,
  sem prédio, estrada, trilho nem árvore, fora do largo e da alameda e com até `MAX_RELIEF_M` de desnível. O recheio, os
  silos e as bombas d'água deixam a célula limpa.
- **Os cavaletes** (`_rack`): dois cavaletes em A ao longo da costa, cada um com a vara no alto e a rede caindo dos dois
  lados até perto do chão, com a barriga entre as pernas, e as boias de cortiça numa beira. A rede é recortada em
  losangos pela UV (em metros) no `shaders/fish_net.gdshader` (alpha scissor, os fios um pouco tortos pelo ruído).
- **As caixas** (`_crates`): três caixas de ripas empilhadas, com os peixes à mostra na de cima, e o cesto, no canto da
  célula longe dos cavaletes.
- Uma malha só para o arquipélago, em duas superfícies (madeira e rede), refeita na obra, na demolição, na estrada, no
  trilho, na derrubada de árvores e ao trocar de mundo (`GameScreen.fish_net_view`).

## Como testar

- `tests/world/test_phase139_fish_nets.gd`: a célula fica fora da cabana, encostada, de um lado dela e na fileira do mar;
  com ela tomada, vai para outra; outros prédios não têm; a vista conta as cabanas.
- Captura: `tools/capture_phase139.tscn` (semente 1840: uma cabana de pesca na costa da ilha principal; `redes.png` e
  `redes_de_perto.png`).
