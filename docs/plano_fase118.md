# Plano da Fase 118 — Chão gasto no pasto

**Estado: feita em 30/10/2026**, quarta do roteiro `docs/plano_fases_115_119.md` (fazenda, taverna e estaleiro, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **As manchas** (`RoadMask.patches`, `_stamp_patch`): no canal b da máscara das estradas (o chão batido das portas e as
  trilhas dos bichos da Fase 40), cada pasto ganha uma mancha de terra pisada na porteira (`GATE_PATCH_M`, onde os bichos se
  juntam), uma em volta do cocho (`TROUGH_PATCH_M`) e `PATCHES_PER_PASTURE` soltas dentro da cerca, de raio entre
  `PATCH_RADIUS_M` e posição pelo hash do pasto. A borda é recortada em lóbulos (o raio varia com o ângulo) e a força fica em
  `PATCH_STRENGTH`, abaixo do chão batido da porta. O `refresh` compara as manchas como as trilhas e refaz só a área do
  pasto que entrou ou saiu.
- **O cocho** (`RoadMask.trough_of`, `PastureTroughView`): junto da cerca de trás (a oposta à porteira),
  `TROUGH_INSET_M` para dentro e `TROUGH_SIDE_M` do meio dela para um lado pelo hash, um cocho de tábuas com a água dentro,
  sobre dois pés, ao longo da cerca e assentado no relevo; um MultiMesh do arquipélago (`GameScreen.pasture_trough_view`).
  Só a ilha com relevo, como a máscara.

## Como testar

- `tests/world/test_phase118_pasture_wear.gd`: o cocho fica dentro do pasto, do lado de trás e ao longo da cerca; as manchas
  ficam pintadas no canal b; demolir o pasto as apaga; a vista põe um cocho por pasto.
- Captura: `tools/capture_phase118.tscn` (semente 1840: uma fazenda de ovelhas com os pastos na ilha principal;
  `pasto.png` e `pasto_de_perto.png`).
