# Plano da Fase 133 — Bandeirolas da feira

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_130_134.md` (sapê, bueiro e ardósia, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`MarketBuntingView.posts`): sobre o pátio das bancas de cada prédio de `Silhouette.STALLS` (o mercado, a metade
  da frente do lote), quatro postes nos cantos do pátio, `POLE_INSET_M` para dentro do lote, na altura do assento do prédio.
- **As peças**: o poste e a corda de bandeirolas da festa da Fase 65 (`FestivalView._post` e `_string`), fixos o ano todo,
  em duas cordas em xis de canto a canto, presas `TIE_BELOW_M` abaixo do topo dos postes; uma malha só para o arquipélago,
  refeita na obra, na demolição e ao trocar de mundo (`GameScreen.market_bunting_view`).

## No caminho

- A captura mostrou um bueiro da Fase 131 debaixo do pé de um poste de gás: corrigido à parte, o bueiro pula as células
  dos postes de gás e dos postes dos fios.

## Como testar

- `tests/world/test_phase133_market_bunting.gd`: o mercado ganha quatro postes dentro do lote e na metade da frente, nas
  quatro rotações; outros prédios não têm; a vista conta os mercados.
- Captura: `tools/capture_phase133.tscn` (ilha plana: dois mercados com a rua calçada na frente; `feira.png` e
  `feira_de_perto.png`).
