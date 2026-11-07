# Plano da Fase 265 — Garças no rio

**Estado: feita em 02/11/2026**, primeira do roteiro `docs/plano_fases_265_269.md` (garça, ruína e cruzeiro).

## O que entrou

- **A busca das margens repartida** (`CanoeView.river_banks(world, ilha, passo, sal, chance)`): a das canoas da Fase 254, agora com
  a rede, o sal do sorteio e a chance como parâmetros; `CanoeView.banks` chama ela com os números de antes (as canoas não mudam).
- **`HeronView`** (`GameScreen.heron_view`): numa rede de `HERON_STEP` (9) células com a chance `HERON_CHANCE` (0,75), fora das
  margens com canoa, uma garça-real de pé junto da água (`spot`: `INTO_RIVER` da célula para o rio, no máximo `WADE_M` abaixo
  dela), de frente para o rio e virando até `SWING` para cada lado pelo `PerchedGullView.heading_at`, no tempo de jogo.
  `heron_mesh`: as patas compridas, o corpo cinza-azulado inclinado, as asas dobradas mais escuras, o pescoço claro em S com a lista
  preta, o penacho e o bico amarelo. Um MultiMesh sem sombra. Na semente 1840 são 4 (os rios baixos são raros).

## Como testar

- `tests/world/test_phase265_herons.gd`: na margem baixa sem canoa, na água rasa do lado do rio; viradas para o rio e virando com o
  tempo; nada na ilha plana; a garça de pé com o bico para a frente.
- Captura: `tools/capture_phase265.tscn -- <pasta>` (cada garça de lado, de frente e de longe).
