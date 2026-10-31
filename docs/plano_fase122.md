# Plano da Fase 122 — Pedras no rio

**Estado: feita em 30/10/2026**, terceira do roteiro `docs/plano_fases_120_124.md` (fios, riacho e mansarda, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Matacões** (`RiverStoneView.places`): nas células de rio, uma a cada `BOULDER_CHANCE` pelo hash da célula, uma rocha da
  `RockModel` (com o material da `RockView`) sentada no leito e saindo de `EMERGE_M` da água, só onde o leito não passa de
  `MAX_BED_DEPTH_M`. A célula de rio com ponte (estrada) não leva. A espuma em volta sai da água, pela profundidade.
- **Seixos**: nas células de terra encostadas no rio, livres e baixas (até `BANK_MAX_M`), uma a cada `PEBBLE_CHANCE`, um
  punhado de pedrinhas meio enterradas.
- Um MultiMesh por variante da rocha; refeito quando estrada ou prédio muda e ao trocar de mundo
  (`GameScreen.river_stone_view`).

## No caminho

- Na semente 1840 os rios do terreno v4 correm quase todos em gargantas fundas: os seixos ficavam no alto do barranco (por
  isso o `BANK_MAX_M`) e os matacões, escondidos lá embaixo. A captura procura o matacão com a margem mais baixa em volta,
  que fica na foz.

## Como testar

- `tests/world/test_phase122_river_stones.gd`: os matacões ficam em células de rio, com o pé no leito e o topo acima da
  água; os seixos ficam na terra baixa e livre da margem; a ponte tira o matacão; o sorteio se repete; a ilha plana não tem.
- Captura: `tools/capture_phase122.tscn` (semente 1840: a foz com a margem mais baixa; `rio.png` e `rio_de_perto.png`).
