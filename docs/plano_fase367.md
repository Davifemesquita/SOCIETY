# Plano da Fase 367 — Pedra clara no tom do pacote

**Estado: feita em 08/11/2026**, a segunda do roteiro `docs/plano_fases_366_370.md` (acabamento do MegaKit).

## O problema

O que parecia um beiral branco nas capturas da Fase 366 era a cornija de pedra clara (Fase 18), no alto das paredes.

A pedra clara gerada no código (cornija, faixa entre os andares, frontão, balaustrada, arcos e consolos) usa a célula
(2, 2) da paleta do Kenney. Essa célula é quase branca e destoava ao lado das paredes do pacote, que têm textura.

## O que entrou

- **`shaders/building_kit.gdshader`**: com `megakit_stone` ligado, a célula (2, 2) vira `megakit_stone_color`, o tom da
  cantaria do pacote. Ela ganha a mancha de `megakit_stone_mottle`, pelo lugar no mundo.
- **`BuildingMaterials.sync_megakit()`**: põe o `megakit_stone` pelo `BuildingKit.megakit_walls()`. Ele é chamado ao montar
  o material e de novo no `use_megakit` e no `reset_megakit`, para os testes e a comparação. Com o Kenney nada muda.

## Como testar

- `tests/presentation/test_phase367_light_stone.gd` confere duas coisas:
  - o parâmetro segue a troca do kit;
  - os uniformes estão no shader compilado (com tela).
- Capturas: `tools/capture_phase95.tscn` (`F:erramentas\capturasase367\dia\`; antes em `fase366\dia\`).
