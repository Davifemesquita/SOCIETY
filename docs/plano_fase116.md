# Plano da Fase 116 — Mesas da taverna

**Estado: feita em 30/10/2026**, segunda do roteiro `docs/plano_fases_115_119.md` (fazenda, taverna e estaleiro, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save; as células das mesas continuam livres.

## O que entrou

- **Onde** (`TavernGardenView.cells`): em volta de cada taverna, as células livres encostadas nela (lados e cantos), de
  terra, sem prédio, estrada, trilho nem árvore, fora do largo calçado (Fase 109) e da alameda (Fase 113) e quase planas,
  até `MAX_TABLES`, as mais perto da frente primeiro. Cada célula leva o id da taverna, que escolhe a cor dos guarda-sóis.
- **As peças**: mesa redonda no pé central e dois bancos (`set_mesh`), e o guarda-sol listrado em `CANOPY_SEGMENTS` gomos
  alternando o branco da lona e a cor da taverna (`canopy_mesh`: duas malhas, uma sem cor de instância e outra tingida
  pela instância, de `PARASOL_COLORS`), virados pelo hash da célula. À noite (`DayClock.night_factor` a partir de
  `FURL_AT`) os guarda-sóis fecham num fuso em volta da haste (`furled_mesh`, `set_furled`).
- **O recheio** deixa essas células limpas (`ScatterView.island_context`).

## Como testar

- `tests/world/test_phase116_tavern_garden.gd`: as mesas ficam em células livres encostadas na taverna, no máximo
  `MAX_TABLES`; o recheio as deixa limpas; uma estrada tira a mesa da célula; a vista desenha uma mesa por célula e fecha
  os guarda-sóis à noite; os gomos brancos e coloridos se alternam.
- Captura: `tools/capture_phase116.tscn` (semente 1840: uma taverna na ilha principal, com a mata em volta derrubada;
  `mesas.png`, `mesas_de_perto.png` e `mesas_a_noite.png`).
