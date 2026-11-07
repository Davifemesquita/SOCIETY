# Plano da Fase 227 — Lamaçal do chiqueiro

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_225_229.md` (lanterna, lã e morcego, a partir das capturas do Anno
do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`MudWallowView.spot`): em cada pasto de uma fazenda de porcos (o dono pelo `DerivedState.module_owner`, como os bichos
  da Fase 13), do meio do pasto `ASIDE_M` para o lado oposto ao do cocho da Fase 118 (`RoadMask.trough_of`) e `AHEAD_M` para a
  frente, girada pelo id, na altura do chão.
- **A poça** (`mud_mesh`): a lama escura numa elipse de borda recortada (sem sorteio, pelo ângulo), com a orla de terra pisada mais
  clara em volta e quatro torrões na beira; o material liso e molhado (pouca aspereza, especular alto). Um MultiMesh sem sombra.
- **O capim do pasto** (`CropView._pasture`): as touceiras não nascem dentro do lamaçal do pasto dos porcos (atravessavam a lama).

## Como testar

- `tests/world/test_phase227_mud_wallows.gd`: só os pastos de uma fazenda de porcos têm a poça, uma por pasto; ela fica dentro do
  pasto e longe do cocho; a malha é rasa e cabe no pasto. O `tests/presentation/test_crops.gd` segue contando as touceiras do pasto
  sem dono.
- Captura: `tools/capture_phase227.tscn` (a fazenda de porcos com os pastos na ilha plana; `lama_de_perto.png`,
  `lama_no_pasto.png`, `lama_de_cima.png`).
