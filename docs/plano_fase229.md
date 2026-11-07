# Plano da Fase 229 — Morcegos ao anoitecer

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_225_229.md` (lanterna, lã e morcego, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SwallowView.towers`): a sineira de cada igreja, a mesma das andorinhas da Fase 218.
- **O voo** (`pose`, `_point`): `FLOCK` morcegos por torre, cada um em voltas tortas em volta da sineira, com o raio (`RADIUS_M`), a
  altura (`HEIGHT_M`), o sentido e a velocidade da semente, o raio e a altura tremendo em zigue-zague (`ZIG_M`, `ZIG_HZ`, as viradas
  bruscas atrás dos insetos); de frente para onde vai e inclinado para dentro da volta. Batem as asas sem parar (`beat`).
- **A malha** (`bat_mesh`): o corpo escuro com as orelhas e as asas de membrana em três dedos, com a borda de trás recortada entre
  eles, desenhada `SCALE` vezes maior; a asa bate pelo `shaders/bird.gdshader`. Um MultiMesh sem sombra, no tempo de jogo; aparece
  só com a noite (`NIGHT_SHOW` da `DayClock.night_factor`, o contrário das andorinhas; `show_for_night` nos testes e nas capturas).

## Como testar

- `tests/world/test_phase229_bats.gd`: o voo fica na faixa de raio e altura, sem saltos; as asas quase nunca param; a igreja tem um
  bando, escondido de dia e à vista de noite.
- Captura: `tools/capture_phase229.tscn` (a igreja na ilha plana às 21h30; `morcegos_de_perto.png`, `morcegos_de_lado.png`,
  `morcegos_de_longe.png`).
