# Plano da Fase 188 — Arco-íris

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_185_189.md` (hera, estaca e arco-íris, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quando** (`RainbowView.amount_at`, função pura da semente e das horas): só no dia de chuva do `WeatherCycle`, subindo um
  pouco antes do fim da chuva (`BEFORE_END_H`) e sumindo `AFTER_RAIN_H` horas depois; vezes a luz do dia
  (`DayClock.night_factor`).
- **Onde** (`place`): um anel de `RAINBOW_DEG` graus em volta do ponto oposto ao sol (o sol do `SkyAdapter`), posto a
  `DISTANCE_M` da câmera a cada quadro; nada com o sol abaixo do horizonte ou alto demais (o arco todo abaixo dele).
- **O desenho** (`ring_mesh`, `shaders/rainbow.gdshader`): o anel largo do violeta (dentro) ao vermelho (fora), somado à cena,
  sem escrever profundidade (o morro na frente o tapa), sem neblina, cortado no mar e mais fraco junto do horizonte.
  `hours_override` deixa a captura prender a hora (como o `WeatherView`). Um nó (`GameScreen.rainbow_view`); nada no save.

## Como testar

- `tests/world/test_phase188_rainbow.gd`: aparece quando a chuva passa e some depois; nunca no dia seco; o anel tem 42 graus em
  volta do ponto oposto ao sol, com o alto acima do olho; nada com o sol baixo demais ou alto demais.
- Captura: `tools/capture_phase188.tscn` (o primeiro dia da semente 1840 com a chuva acabando de tarde; com e sem o arco).
