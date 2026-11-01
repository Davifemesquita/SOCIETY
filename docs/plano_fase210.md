# Plano da Fase 210 — Pombos na cumeeira

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_210_214.md` (pombo, mó e buxo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`RoofPigeonView.pigeons`): numa casa a cada `PIGEON_EVERY` pelo id (resto `PIGEON_REST`), de telhado de duas águas
  (sem a ala da Fase 96, a mansarda da Fase 124 nem a abóbada da Fase 98), uma fila de três a cinco pombos na capa da cumeeira
  (`hall_offset` + a altura das paredes e do telhado, a conta do galo da Fase 182), na metade dela longe da chaminé
  (`BuildingKit.chimney_top`), a `STEP_M` um do outro, cada um virado para uma das águas e um pouco torto. No lugar do modelo.
- **O pombo** (`pigeon_mesh`): o pombo cinza-azulado da rua, um pouco maior que de verdade (`SIZE`), com o corpo e a cabeça em
  bolas de 6 × 3 faces (`_ball`, sem normal: misturar com as faces do `VertexShapes` pedia o `generate_normals` do fim), o
  peito furta-cor, o rabo escuro em cunha, as faixas da asa e as patas. Parado; um MultiMesh sem sombra.
- **Custo**: a primeira malha, de bolas do `PerchedGullView._blob`, punha ~110 mil primitivas a mais no quadro do benchmark e
  ~1 FPS (A/B na mesma hora); a de bolas pequenas não muda o quadro.

## Como testar

- `tests/world/test_phase210_roof_pigeons.gd`: só as casas do resto certo e de duas águas têm os pombos, na capa da cumeeira,
  sobre a linha dela e longe da chaminé.
- Captura: `pombos_na_cumeeira.png` e `pombos_da_rua.png` no `tools/capture_phase95.tscn`, com a câmera posta à mão (`_aimed`:
  a da partida fica presa ao chão).
