# Plano da Fase 135 — Galinhas no quintal

**Estado: feita em 31/10/2026**, primeira do roteiro `docs/plano_fases_135_139.md` (galinha, forno e mina, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ChickenView.yards`, `yard_row`): o quintal cercado das casas de classe com `TierDef.HouseTrim.YARD` (os
  camponeses) é a fileira da frente do lote; numa casa a cada `CHICKEN_EVERY` (pelo id) ele ganha `HENS` galinhas, longe
  `YARD_MARGIN_M` da cerca e da parede. O primeiro bicho de um quintal a cada `ROOSTER_EVERY` é um galo, maior e ruivo.
- **Andando e ciscando** (`pose`, `patch`): cada galinha fica no seu trecho do quintal (juntas, uma atravessava a outra);
  parada, vira para um lado e para o outro e bica o chão em rajadas (o corpo inclina até `PECK_TILT`), e no fim da volta
  anda até o ponto seguinte, com o passo subindo e descendo. Os pontos saem do hash e do relógio da vista, no tempo de jogo
  (para na pausa); à noite somem (foram para o poleiro). Teto de `MAX_CHICKENS`.
- **A malha** (`chicken_mesh`): corpo cheio, pescoço, cabeça e rabo erguido (a plumagem, tingida pela cor de cada galinha
  no `shaders/chicken.gdshader`, pelo `INSTANCE_CUSTOM`), crista e barbela vermelhas, bico e pernas amarelos; desenhada
  `SCALE` vezes maior para aparecer de onde a câmera fica. Um MultiMesh só, com a caixa fixa do arquipélago
  (`GameScreen.chicken_view`), refeito na obra, na demolição, na subida de classe e ao trocar de mundo.

## Como testar

- `tests/world/test_phase135_chickens.gd`: o quintal é a fileira da frente nas quatro rotações; as galinhas ficam no
  quintal e no trecho delas, andam e bicam; só as casas dos camponeses têm; o galo é maior e ruivo; a vista desenha três
  por quintal.
- Captura: `tools/capture_phase135.tscn` (ilha plana: uma fileira de casas de camponeses com a rua de terra na frente;
  `quintais.png`, `galinhas_de_perto.png` e `galinhas_bicando.png`).
