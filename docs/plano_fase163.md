# Plano da Fase 163 — Horta no quintal

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_160_164.md` (cunhal, deriva e horta, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`KitchenGardenView.cells`, `spot`): a célula de trás de uma casa de camponeses ou operários a cada `GARDEN_EVERY`
  pelo id, no resto `GARDEN_REST` — a mesma célula da fogueira da `LampView` (resto 0) e do varal da `YardView` (resto 1): as três
  nunca a disputam —, livre de prédio e estrada e em terra. O recheio e as bombas d'água a deixam limpa.
- **A horta** (`garden_mesh`): o canteiro de terra escura com a beirada de tábuas, uma fileira de couves (cabeça e duas folhas
  abertas), uma de alfaces e, no fundo, três varas de feijão amarradas em tenda com as folhas subindo, as fileiras ao longo da
  parede de trás. Uma malha só para o arquipélago (`GameScreen.kitchen_garden_view`), refeita na obra, na demolição, na subida de
  classe, na estrada e ao trocar de mundo.

## Como testar

- `tests/world/test_phase163_kitchen_gardens.gd`: só as casas do resto certo têm horta, atrás delas, na célula da fogueira e do
  varal (que usam outros restos); artesãos não; uma estrada atrás tira a horta; o recheio e as bombas deixam a célula; o
  canteiro cabe na célula.
- Captura: `hortas_camponeses.png` e `hortas_operarios.png` no `tools/capture_phase95.tscn` (as ruas vistas dos fundos).
