# Plano da Fase 270 — Corvos no campo

**Estado: feita em 02/11/2026**, primeira do roteiro `docs/plano_fases_270_274.md` (corvo, dedaleira e nenúfar).

## O que entrou

- **`CropView.field_ids`**: os campos que a vista desenha (os com dono).
- **`CrowView`** (`GameScreen.crow_view`, com a `CropView`): nos campos de um a cada `CROW_EVERY` pelo id, enquanto a plantação
  ainda está até `YOUNG_UNTIL` (0,45) do crescimento, um corvo em um a cada `CROW_SPOT_EVERY` dos lugares da colheita da Fase 157
  (`CropView.harvest_places`, nos vãos entre as fileiras; os caixotes só aparecem perto da colheita, e aí os corvos já foram)
  (`crow_spots`); cada um virando pelo `PerchedGullView.heading_at` e bicando em rajadas (`peck`), no tempo de jogo, e todos somem
  de noite (`NIGHT_HIDE`). `crow_mesh`: o corpo preto com o brilho azulado nas asas, a cauda em leque, a cabeça, o bico grosso e as
  patas. Um MultiMesh sem sombra, conferido a cada `REFRESH_S`.

## Como testar

- `tests/presentation/test_phase270_crows.gd`: corvos só nos campos novos da vez, a vista seguindo os campos (somem quando a
  plantação cresce), as bicadas em rajadas e o corvo de pé com o bico para a frente.
- Captura: `tools/capture_phase270.tscn -- <pasta>` (a vila do ciclo da cor com as fazendas recém-plantadas).
