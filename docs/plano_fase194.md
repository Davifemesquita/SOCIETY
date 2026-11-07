# Plano da Fase 194 — Escada do cais

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_190_194.md` (colmeia, pombal e varal, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`QuayStairsView.flights`): em cada entreposto com cais de pedra (Fase 106), de cada lado, no lanço que fica
  `STAIR_CLEAR_M` além da largura do prédio (depois da cisterna da Fase 127) e que tem o lanço seguinte do mesmo lado.
- **A escada** (`step_places`): os degraus de pedra (caixas de `STEP_RUN_M` de piso descendo `STEP_RISE_M` cada) encostados no
  paredão, do lado do mar, descendo do alto do cais até dentro da água, afastando-se do prédio, na pedra das paredes do cais;
  a argola de ferro (`ring_mesh`) presa no paredão logo depois do último degrau. Dois MultiMesh (`GameScreen.quay_stairs_view`).

## Como testar

- `tests/world/test_phase194_quay_stairs.gd`: os degraus descem um a um até dentro da água, do lado do mar do paredão; nada sem
  cais de pedra.
- Captura: `tools/capture_phase194.tscn` (o entreposto da ilha principal da semente 1840, visto do mar).
