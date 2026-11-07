# Plano da Fase 164 — Caldeira das árvores

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_160_164.md` (cunhal, deriva e horta, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A caldeira** (`AvenueView.pit_mesh`): no pé de cada árvore da alameda da Fase 113, o anel quadrado de `PIT_M` de pedras de
  meio-fio (um pouco enterradas, para acompanhar o chão torto), a terra escura dentro e a grade de ferro em barras cruzadas com o
  furo do tronco livre.
- **Onde**: num MultiMesh (`TreePits`) com o mesmo lugar das árvores, alinhado com a grade (a rua), não com o giro sorteado da
  árvore; sem sombra. Os lugares ficam em `pit_places` (sem tela o MultiMesh devolve transformações zeradas).

## Como testar

- `tests/world/test_phase164_tree_pits.gd`: sem rua calçada, nenhuma caldeira; com ela, uma por árvore da alameda, no lugar dela e
  alinhada com a grade; a caldeira cabe na célula, é baixa e a grade deixa o furo do tronco livre.
- Captura: `caldeiras.png` no `tools/capture_phase113.tscn` (a alameda de perto).
