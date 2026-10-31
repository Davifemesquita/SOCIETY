# Plano da Fase 129 — Sombra das nuvens

**Estado: feita em 30/10/2026**, a última do roteiro `docs/plano_fases_125_129.md` (recife, alpendre e nuvens, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A sombra** (`shaders/cloud_shadow.gdshaderinc`, `cloud_shadow`): manchas grandes e macias de um ruído de valor de duas
  oitavas (`CLOUD_SHADOW_CELL_M`), cortadas pela cobertura do céu (global `cloud_cover`, do `WeatherCycle`): com o céu
  limpo, nada; nublado, metade do chão na sombra, escurecendo até `CLOUD_SHADOW_MAX`. Só de dia (pela altura do sol, o
  global `sun_direction` da Fase 110). Hash sem seno, pela lição da Fase 125.
- **Onde**: o terreno (`shaders/terrain.gdshader`) e a água (`shaders/water.gdshader`, a cor e a emissão, antes do brilho
  do sol). A mata, os prédios e as peças soltas não escurecem (usam outros shaders).
- **O movimento** (`WeatherView.drift_clouds`, global `cloud_offset`): a cada quadro o deslocamento soma a direção do vento
  vezes `CLOUD_DRIFT_M_S` mais `CLOUD_WIND_M_S` × a força dele, no tempo de jogo — a direção muda sem as sombras saltarem e
  elas param na pausa.

## Como testar

- `tests/presentation/test_phase129_cloud_shadows.gd`: os globais estão no projeto; as sombras andam na direção do vento,
  mais depressa com ele forte, e param na pausa; com tela, o terreno e a água compilam com o include.
- Captura: `tools/capture_phase129.tscn` (semente 1840: a ilha principal com o céu limpo, nublado e meio nublado, as
  sombras depois de andar e de perto).
