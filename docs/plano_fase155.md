# Plano da Fase 155 — Carneirinhos no mar

**Estado: feita em 31/10/2026**, a primeira do roteiro `docs/plano_fases_155_159.md` (carneirinho, papoula e colheita, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quanto** (`WeatherView.whitecaps_of`, global `sea_whitecaps`): nada até `WHITECAP_CALM` de força do vento, subindo em
  linha até `WHITECAP_FULL` (o vento de chuva); a `WeatherView` publica o global junto com o vento.
- **Onde e como** (`shaders/water.gdshader`, grupo `Whitecaps`, `whitecap_at`): no mar aberto (a partir de `whitecap_open_m`
  da costa), no máximo um carneirinho por célula de `whitecap_cell_m`, sorteado de novo a cada volta de `whitecap_period_s`
  (cada célula na sua fase, com o hash sem seno da Fase 125) com a chance `whitecap_share` × `sea_whitecaps`. A mancha é
  comprida de través ao vento, com a crista fina na frente e a espuma arrastada atrás, a borda torta pelo ruído; acende
  depressa, anda `whitecap_drift_m_s` com o vento crescendo um pouco e se desfaz em renda (furos macios em riscas ao longo do
  vento, mais furos quanto mais fraca). Some longe da câmera (`whitecap_fade_m`).

## Como testar

- `tests/presentation/test_phase155_whitecaps.gd`: o global existe; a quantidade é zero com o ar parado e sobe do dia limpo
  ao nublado e à chuva, sem passar de 1; com tela, o shader compila com os uniformes novos.
- Captura: `tools/capture_phase155.tscn` (o mar a leste da ilha principal com o ar parado, a brisa, o vento forte e de perto).
