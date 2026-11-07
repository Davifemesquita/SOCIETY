# Plano da Fase 182 — Galo do cata-vento

**Estado: feita em 31/10/2026**, do roteiro `docs/plano_fases_180_184.md` (borboleta, correio e galo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WeathercockView.spot`): no alto da cumeeira de cada fazenda de `FARMS` (trigo, batata, lúpulo, ovelhas, porcos e
  vinhedo) das ilhas temperadas, com telhado: o meio do telhado do corpo (`hall_offset` mais a altura das paredes e do
  telhado), no lugar do modelo (`BuildingView.model_place`).
- **A haste** (`mast_mesh`): a base que abraça a cumeeira, a haste de ferro, a bolinha de bronze e a rosa dos ventos de quatro
  braços com a bola na ponta.
- **O galo** (`cock_mesh`): a seta de ferro com a ponta e a pena e o galo de bronze recortado em chapa (`_plate`: o corpo, o
  rabo em leque, o pescoço, a cabeça com a crista vermelha e o bico, as pernas até a seta); o material é visto dos dois lados.
- **O vento** (`turn`): a cabeça (−x) vira devagar (`TURN_S`) para o lado de onde vem o vento do `WeatherView` (o rabo vai a
  favor dele, `WindFlag.yaw_of`) e treme um pouco com o vento forte (`SHAKE_RAD`), no tempo de jogo (para na pausa). Dois
  MultiMesh (`GameScreen.weathercock_view`), refeitos na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/presentation/test_phase182_weathercocks.gd`: só as fazendas têm o galo, na altura da cumeeira e dentro da planta; a
  cabeça vira para o vento devagar e o rabo fica a favor dele; as medidas da haste e do galo.
- Captura: `tools/capture_phase182.tscn` (fazendas na ilha principal da semente 1840, com a câmera posta à mão no alto do
  telhado).
