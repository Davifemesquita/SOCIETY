# Plano da Fase 218 — Andorinhas no campanário

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_215_219.md` (tábua, cortina e andorinha, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SwallowView.towers`): o meio da sineira de cada prédio com campanário (`Silhouette.BELFRY`, a igreja), no lugar do
  modelo (`BuildingView.model_place`), pela conta da torre da Fase 18 (`BuildingKit.belfry_center`).
- **O voo** (`pose`, `_orbit`): `FLOCK` andorinhas por torre, cada uma numa elipse inclinada em volta da sineira, com o raio
  (`RADIUS_M`), a altura (`HEIGHT_M`), o sentido, a velocidade (`SPEED_M_S`), o achatamento e o giro da semente, subindo e
  descendo `WAVE_M` em oito; de frente para onde vai e inclinada para dentro da volta. Batem as asas em rajadas de `FLAP` de cada
  `CYCLE_S` e planam no resto (`beat`).
- **A malha** (`swallow_mesh`): costas azul-escuras, peito claro, garganta ruiva, asas compridas em foice e a cauda em forquilha,
  desenhada `SCALE` vezes maior; a asa bate pelo `shaders/bird.gdshader`, como as dos outros pássaros. Um MultiMesh sem sombra,
  no tempo de jogo (para na pausa); some à noite.

## Como testar

- `tests/world/test_phase218_swallows.gd`: só a igreja tem a torre, com a sineira acima do beiral e dentro da área; o voo fica na
  faixa de raio e altura, sem saltos; as asas batem em rajadas; a vista desenha um bando por torre.
- Captura: `tools/capture_phase218.tscn` (a igreja na ilha plana; `andorinhas_de_perto.png`, `andorinhas_de_lado.png`,
  `andorinhas_de_longe.png`).
