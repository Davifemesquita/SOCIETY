# Plano da Fase 169 — Barril de chuva

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_165_169.md` (chão batido, feno e gaivota, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`RainBarrelView.spot`, `_cell`, `cells`): numa casa de camponeses ou operários a cada `BARREL_EVERY` pelo id,
  encostado na parede de trás junto da quina de −X do corpo, na célula de trás desse canto quando ela está livre (sem prédio
  nem estrada, em terra). A célula sai só do lote (sem o desenho da casa, que pede a `Simulation`), para o recheio, as bombas
  d'água, os silos e as medas poderem deixá-la limpa só com o mundo.
- **O barril** (`barrel_body_mesh`, `pipe_mesh`, `pipe_place`): as aduelas com dois arcos de ferro e a água escura um palmo
  abaixo da boca, e a calha de lata descendo do beiral pela parede com o cotovelo para dentro dele; com a ala da Fase 96 desse
  lado, a calha sai do beiral dela, um andar mais baixo. No lugar do modelo da casa (`BuildingView.model_place`), com o pé no
  chão de verdade. Dois MultiMesh (`GameScreen.rain_barrel_view`): o barril com o cotovelo, e o cano de 1 m esticado da curva
  até o beiral por instância.

## No caminho

- A primeira versão juntava todos os barris numa malha refeita em GDScript a cada obra: ~120 ms com 300 barris, e o carregar
  do benchmark subiu 0,15 s. Com os dois MultiMesh, refazer é só pôr as transformações.

## Como testar

- `tests/world/test_phase169_rain_barrels.gd`: só as casas do resto certo têm o barril, atrás delas e fora do lote, na célula
  que as outras peças deixam limpa, com a calha subindo mais de um andar; artesãos não; uma estrada atrás tira o barril; o
  recheio e as bombas deixam a célula; o barril é baixo, redondo e a calha chega ao beiral.
- Captura: `barris_de_chuva.png` no `tools/capture_phase95.tscn` (e nas vistas dos fundos das hortas).
