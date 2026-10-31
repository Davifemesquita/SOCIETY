# Plano da Fase 165 — Chão batido das fábricas

**Estado: feita em 31/10/2026**, a primeira do roteiro `docs/plano_fases_165_169.md` (chão batido, feno e gaivota, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`RoadMask.works`): em volta de cada prédio de produção da ilha (as fazendas de campo, cuja terra é a da `CropView`,
  e os módulos ficam de fora), em qualquer ilha, o lote crescido de `WORKS_REACH_M`.
- **Como** (`RoadMask._stamp_yard` com `ragged`): no canal b da máscara das estradas, o mesmo chão batido do terreiro tropical
  da Fase 111, cheio junto das paredes e somindo em `WORKS_SOFT_M`, com a borda recortada até `WORKS_RAGGED_M` por um ruído de
  valor semeado pelo id (não é um retângulo). O terreno já mistura a terra com a grama pela altura dela. O `refresh` compara os
  pátios como compara os terreiros e refaz só o retângulo que mudou.

## No caminho

- A primeira versão tinha a borda recortada quase do tamanho do pátio: junto da parede ficava grama. O pátio cresceu e o
  recorte ficou só na beirada.

## Como testar

- `tests/world/test_phase165_works_yards.gd`: um lenhador ganha o pátio, com terra no canto do lote e nada longe dele; casas não
  têm; a borda varia ao longo do lado; construir uma oficina redesenha o pátio.
- Captura: `tools/capture_phase165.tscn` (uma olaria na ilha principal, de meia distância e de perto).
