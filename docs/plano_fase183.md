# Plano da Fase 183 — Barco na areia

**Estado: feita em 31/10/2026**, do roteiro `docs/plano_fases_180_184.md` (borboleta, correio e galo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BeachBoatView.sites`): junto de cada cabana de pesca, na célula de terra a até `REACH` células dela que encosta no
  mar pelo lado — baixa (`MAX_HEIGHT_M`) e quase plana (`MAX_RELIEF_M`), sem prédio, estrada, trilho nem árvore, fora das redes
  da Fase 139, do largo e da alameda —, com as duas vizinhas ao longo da costa também livres (o barco é mais comprido que a
  célula); a mais perto da cabana. Só nas ilhas com relevo.
- **O barco** (`boat_place`): o bote do porto (`HarborView.boat_mesh`, a madeira dele) virado de borco, o comprimento ao longo da
  costa, a borda na areia e uma ponta apoiada um pouco mais alta (`TILT`).
- **Os remos** (`oar_places_of`): os dois remos do bote da Fase 142 (`RowboatView.oar_mesh`) deitados na areia do lado de terra.
- **O recheio** deixa as três células limpas (`cells`, somadas às portas no `ScatterView.island_context`). Dois MultiMesh
  (`GameScreen.beach_boat_view`), refeitos na obra, na demolição, na estrada, nas árvores e ao trocar de mundo.

## Como testar

- `tests/world/test_phase183_beach_boats.gd`: o barco na praia junto da cabana, com as vizinhas livres; virado de borco ao
  longo da costa, a borda na areia, os remos do lado de terra; o recheio deixa as células; nada na ilha plana.
- Captura: `tools/capture_phase183.tscn` (cabanas de pesca na ilha principal da semente 1840).
