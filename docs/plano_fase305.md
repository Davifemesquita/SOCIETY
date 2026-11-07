# Plano da Fase 305 — Tom por árvore

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_305_309.md` (mata funda; o Anno não foi aberto: o dono
estava no PC, e a ideia vem das capturas guardadas). No Anno, a mata mistura verdes escuros, oliva e amarelados, árvore a árvore;
no Society, os carvalhos e as faias saíam todos do mesmo verde-limão (Fase 256).

## O que entrou

- **`shaders/foliage.gdshaderinc`**: `tree_tint` e os tons `tint_dark`, `tint_olive` e `tint_yellow`. No `vertex`, o sorteio da
  árvore pelo hash inteiro da célula de 25 cm da origem da instância (`tree_pick`, sem `sin`); no `fragment`, um quarto das
  árvores de cada tom (a quarta fica a de sempre), com um pouco de claro e escuro, só na folhagem (a madeira fica).
- **`TreeModel.tint_of`**: `BROADLEAF_TINT` (1) no carvalho, na faia, na bétula e na folhosa tropical; `CONIFER_TINT` (0,35) no
  pinheiro, no abeto e no coqueiro, já escuros. As plantações e o capim, no mesmo shader, ficam com 0.

## Medida

72,0 FPS, GPU 12,7 ms (304: 12,7). Neutra.

## Como testar

- `tests/presentation/test_phase305_tree_tint.gd`: a força nas folhosas e nas coníferas, de perto e de longe; as plantações sem;
  os dois shaders compilando com os uniformes novos (com tela).
- Captura do ciclo: `tools/capture_phase305.tscn -- <pasta>`; o antes e depois está em
  `F:\ferramentas\capturas\fase305\antes_depois.png`.
