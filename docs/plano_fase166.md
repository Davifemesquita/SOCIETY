# Plano da Fase 166 — Medas de feno

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_165_169.md` (chão batido, feno e gaivota, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`HaystackView.cells`): ao lado de cada fazenda de ovelhas, de porcos e de trigo, na célula livre e quase plana
  encostada nela mais perto do meio da face do lado (a de +X da frente), fora do largo, da alameda, das mesas da taverna, do silo
  (Fase 117), do monte de rejeito, das redes, do pátio de tijolos e das hortas. O recheio e as bombas d'água deixam a célula.
  Só na ilha com relevo, como os silos.
- **As medas** (`stack_mesh`): duas por fazenda, uma grande e uma menor, cada uma com o corpo em barril (largo no meio, mais
  estreito no pé), a cúpula em anéis até o cocuruto e a vara saindo dele; os anéis um pouco tortos e o feno mais queimado de sol
  em cima. Uma malha só para o arquipélago (`GameScreen.haystack_view`), refeita na obra, na demolição, na estrada e ao trocar de
  mundo.

## Como testar

- `tests/world/test_phase166_haystacks.gd`: a fazenda de ovelhas ganha as medas numa célula encostada e livre, fora do silo;
  casas não; o recheio e as bombas deixam a célula; a meda fica de pé, redonda, com a vara acima do cocuruto e as faces para
  fora.
- Captura: `tools/capture_phase166.tscn` (fazendas na ilha principal, achadas pelo `SiteFinder`, com a câmera nas medas).
