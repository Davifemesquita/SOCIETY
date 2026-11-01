# Plano da Fase 228 — Barris de petróleo

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_225_229.md` (lanterna, lã e morcego, a partir das capturas do Anno
do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`OilBarrelView.sites`, `cells`): em cada poço de petróleo (Fase 70), as duas células do meio do lado de −X do modelo,
  depois o de +X e por fim o de trás (a frente é o pátio do cavalo-de-pau da Fase 73), pelo `SideYard` (guardado pelo
  `SideYard.remember`). O recheio e as bombas as deixam limpas.
- **Os barris** (`barrels_mesh`): os barris de madeira de época (o barril torneado da Fase 221, enegrecido pelo óleo, `TONE`; nada
  de tambor de ferro, que é de depois), cinco em pé em duas filas e dois deitados sobre os calços, e a mancha de óleo preta de
  borda recortada no chão debaixo deles. Um MultiMesh, no meio das duas células.

## Como testar

- `tests/world/test_phase228_oil_barrels.gd`: nas quatro rotações os barris ficam de lado, encostados no poço, nunca na frente; com
  uma das células bloqueada, vão para o outro lado; outros prédios não têm; o recheio e as bombas deixam as células; a malha cabe
  nas duas células.
- Captura: `tools/capture_phase228.tscn` (dois poços na ilha plana; `barris_de_perto.png`, `barris_e_poco.png`,
  `barris_de_longe.png`).
