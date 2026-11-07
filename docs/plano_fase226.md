# Plano da Fase 226 — Fardos de lã

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_225_229.md` (lanterna, lã e morcego, a partir das capturas do Anno
do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WoolBaleView.sites`, `cells`): em cada fazenda de ovelhas, as duas células do meio do lado de −X do modelo, depois o de
  trás e por fim o de +X (as medas da Fase 166 preferem o +X), pelo `SideYard` (guardado pelo `SideYard.remember`), fora das medas,
  do silo e da carroça de feno. Com os pastos encostados, a fazenda costuma ficar sem lado livre; o recheio e as bombas deixam as
  células.
- **Os fardos** (`bale_mesh`, `_bale`): três fardos de juta embaixo e um em cima, estufados como sacos cheios (o blob esticado sobre
  um miolo de caixa), cada um com duas cordas dando a volta no corte dele, encostados na parede; ao lado, o cepo de tosquia com a
  tesoura de duas lâminas e o velo solto no chão. Um MultiMesh, no meio das duas células.

## Como testar

- `tests/world/test_phase226_wool_bales.gd`: nas quatro rotações os fardos ficam de lado ou atrás, encostados na fazenda, nunca na
  frente, fora das medas e do silo; com uma das células bloqueada, vão para outro lado; outros prédios não têm; o recheio e as
  bombas deixam as células; a malha cabe nas duas células.
- Captura: `tools/capture_phase226.tscn` (duas fazendas sem pasto na ilha plana; `la_de_perto.png`, `la_e_fazenda.png`,
  `la_de_longe.png`).
