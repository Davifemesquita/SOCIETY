# Plano da Fase 170 — Barranco de terra vermelha

**Estado: feita em 31/10/2026**, a primeira do roteiro `docs/plano_fases_170_174.md` (laterita, lenha e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A margem do rio** (`TerrainView.TROPICAL_MUD_TINT`): o terreno já pinta de lama o leito e a margem dos rios
  (`ArchipelagoGenerator.Surface.MUD`, Fase 19) com o uniforme `mud_tint` sobre a textura da areia. No material das ilhas
  tropicais esse uniforme passa a ser a cor da laterita, a terra vermelha dos trópicos; as temperadas ficam com a lama escura do
  shader. Nenhuma textura nova, nenhum custo no quadro.

## Como testar

- `tests/world/test_phase170_tropical_banks.gd`: o material de cada ilha tropical leva a cor vermelha (o vermelho bem acima do
  verde); o das temperadas, não.
- Captura: `tools/capture_phase170.tscn` (o rio de uma ilha tropical, de longe e de perto).
