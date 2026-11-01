# Plano da Fase 193 — Carroça de feno parada

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_190_194.md` (colmeia, pombal e varal, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`HayWagonView.cells`): ao lado das medas de feno da Fase 166, numa fazenda a cada `WAGON_EVERY` pelo id, na célula
  livre e quase plana vizinha da delas pelo lado, fora do lote da fazenda e das outras peças de célula. O recheio deixa a célula
  limpa.
- **A carroça** (`wagon_place`): o modelo das carroças das estradas (`CartView.model_mesh`) sem o cavalo, girado pelo id da
  fazenda e tombado para a frente (`TILT`, os varais no chão); a carga de feno alta e desarrumada sobre a caçamba
  (`load_mesh`, nas cores das medas). Dois MultiMesh (`GameScreen.hay_wagon_view`).

## Riscos

- A carga em caixas saiu quadrada demais; as camadas viraram bolas achatadas (o feno solto não tem quina).

## Como testar

- `tests/world/test_phase193_hay_wagons.gd`: as carroças ao lado das medas da fazenda certa, na célula livre vizinha; tombadas
  um pouco; o recheio deixa a célula; a carga sobre a caçamba.
- Captura: `tools/capture_phase193.tscn` (o roteiro das fazendas da Fase 190, com as fotos da carroça).
