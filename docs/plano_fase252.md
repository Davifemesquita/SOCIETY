# Plano da Fase 252 — Carruagem à porta do teatro

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_250_254.md` (balança, cabra e canoa, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`CarriageView.spot`): em cada teatro, na célula de estrada logo à frente da fachada de entrada (`Footprint.front_cells`)
  mais perto do meio dela, ao longo da rua (o eixo da fachada); na rua calçada, em cima do calçamento (`PavedDual.LIFT_M`). Sem
  estrada encostada na entrada, nada.
- **A carruagem** (`carriage_mesh`): a caixa laqueada de vinho com as janelas, a porta e o friso dourado, o teto de couro com a
  borda, o chassi, as rodas (as de trás maiores) com os cubos de ferro, a boleia na frente com o banco do cocheiro, as duas lanternas
  e os varais pousados no chão, sem os cavalos. Um MultiMesh; refeito na obra, na demolição e na estrada.

## Como testar

- `tests/world/test_phase252_carriages.gd`: o teatro com a estrada na frente ganha a carruagem numa célula de estrada à frente da
  entrada, ao longo da rua; sem estrada ali, nada; a escola não tem; a carruagem é comprida e de pé.
- Captura: `tools/capture_phase252.tscn` (a ilha plana; `carruagem_de_perto.png`, `carruagem_e_predio.png`,
  `carruagem_de_longe.png`).
