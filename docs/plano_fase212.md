# Plano da Fase 212 — Buxo na porta

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_210_214.md` (pombo, mó e buxo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`TopiaryView.places_of`): nas casas de pórtico (`TierDef.HouseTrim.PORTICO`, os investidores), um de cada lado da porta,
  `SIDE_CELLS` da largura da célula para fora do meio dela (por fora das colunas do pórtico da Fase 13, a 0,42) e `OUT_M` à frente
  da parede, na frente da sebe. A conta da porta é a do banco da Fase 174. No lugar do modelo.
- **O vaso** (`pot_mesh`): o vaso de pedra torneado pelo perfil `POT_PROFILE` (o pé, a cintura, o bojo e a borda mais escura), a
  terra e a bola de buxo podada em esfera de 10 × 5 faces (`_ball`, sem normal), com um tufo mais claro em cima. Um MultiMesh.

## Como testar

- `tests/world/test_phase212_topiary.gd`: as casas dos investidores têm dois vasos, um de cada lado da porta, por fora das colunas,
  à frente da parede e no chão; as outras classes não têm; o vaso é baixo e estreito.
- Captura: `buxo_na_porta.png` no `tools/capture_phase95.tscn` (a rua dos investidores).
