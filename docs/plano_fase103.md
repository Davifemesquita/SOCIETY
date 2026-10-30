# Plano da Fase 103 — Claraboias

**Estado: feita em 29/10/2026**, quarta do roteiro `docs/plano_fases_100_104.md` (a rua habitada, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem tem** (`BuildingKit.Spec.skylights`): os prédios de produção sem silhueta própria, de lote com o lado menor de
  `SKYLIGHT_MIN_CELLS` células ou mais e telhado de duas águas ou abóbada (padaria, açougue, tecelagem, as fábricas dos
  artesãos e engenheiros...). Fazendas pequenas, minas (telhado plano) e quem já tem silhueta (lanternim, tonéis, moinho)
  ficam sem.
- **As vidraças** (`skylight_panes`): uma fileira em cada água, no meio da descida (`SKYLIGHT_AT` da meia largura), de
  `SKYLIGHT_PANE_M` a cada `SKYLIGHT_STEP_M` ao longo da cumeeira, assentadas na água (pela reta do telhado) ou na abóbada
  (pelo `vault_profile` da Fase 98) e erguidas `SKYLIGHT_LIFT_M` dela.
- **O desenho** (`_skylights`): o vidro e o caixilho de ferro em volta, com o montante do meio.
- **À noite**: as vidraças entram na lista `windows()`, no mesmo formato das janelas; a `WindowLightsView` as acende como as
  janelas da fábrica, isto é, com a fábrica produzindo. (Na captura da noite elas ficam apagadas: as fábricas da rua de
  teste não têm trabalhador.)

## Como testar

- `tests/presentation/test_phase103_skylights.gd`: quem tem e quem não tem; as vidraças ficam entre as paredes e a
  cumeeira, dentro da planta, viradas para o céu, uma fileira em cada água; todas entram na lista das janelas que acendem.
- O teste do vidro por janela da Fase 39 continua valendo: cada vidraça é um quadrilátero de vidro, como cada janela.
- Captura: `tools/capture_phase95.tscn` (`claraboias.png` e `claraboias_noite.png`).
