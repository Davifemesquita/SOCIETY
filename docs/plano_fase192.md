# Plano da Fase 192 — Roupa sobre a rua

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_190_194.md` (colmeia, pombal e varal, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`StreetLaundryView.lines`): numa casa de operários a cada `LINE_EVERY` pelo id, se diante do meio da frente dela há
  uma rua de uma célula e, do outro lado, outra casa de operários virada para a rua: o varal vai de uma beira da rua à outra (as
  duas fachadas), a `HEIGHT_M` do chão. Vale na ilha plana também (a rua dos testes e das capturas).
- **O varal** (`_rope`, `_cloths`): o cabo caindo em curva (`HarborView.rope_span`) e `CLOTHS` peças de roupa penduradas, nas
  cores dos varais dos quintais da Fase 15 (`YardView.CLOTH_COLORS`). Uma malha só (`GameScreen.street_laundry_view`), refeita na
  obra, na demolição, na subida de classe, na estrada e ao trocar de mundo.

## Como testar

- `tests/presentation/test_phase192_street_laundry.gd`: o varal atravessa a rua entre duas casas de operários frente a frente,
  no alto; nada com a casa do outro lado de costas, de outra classe ou sozinha.
- Captura: `tools/capture_phase192.tscn` (uma rua com casas de operários dos dois lados, na ilha plana).
