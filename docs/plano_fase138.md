# Plano da Fase 138 — Telhado de chapa ondulada

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_135_139.md` (galinha, forno e mina, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingView.IRON_ROOFS`): as fábricas pesadas — olaria, fundição, vidraria, usina, a de vigas de aço (todas
  as de fumaça pesada), a usina a petróleo, as máquinas de costura, as conservas e a de lâmpadas. A `BuildingView` põe o
  parâmetro de instância `corrugated` no corpo do prédio.
- **A chapa** (`shaders/building_kit.gdshader`, `iron_sheet_shade`): nas águas do telhado, no lugar das telhas da Fase 95,
  ondas de `corrugation_m` descendo a água (crista clara, vale escuro), chapas de `sheet_width_m` por `sheet_length_m`
  sobrepostas com a sombra na junta de baixo, um tom de ferro por chapa e a ferrugem (`rust_color`) escorrendo da junta de
  cima de cada chapa e em manchas pelo ruído; mais lisa (`roughness`) onde não enferrujou e sem o relevo das telhas do
  mapa de normais. De longe, o desenho some e fica o tom. A capa, o beiral e o telhado plano ficam no ferro escurecido.

## Como testar

- `tests/presentation/test_phase138_iron_roofs.gd`: a lista é de fábricas que existem, fora da lista da ardósia, e tem
  todas as de fumaça pesada; com tela, o shader do kit compila com os parâmetros novos.
- Captura: `tools/capture_phase138.tscn` (ilha plana: uma fileira de fábricas pesadas ao lado de uma padaria de telha;
  `fabricas.png`, `chapa_de_perto.png` e `chapa_e_telha.png`).
