# Plano da Fase 268 — Casco naufragado

**Estado: feita em 02/11/2026**, quarta do roteiro `docs/plano_fases_265_269.md` (garça, ruína e cruzeiro).

## O que entrou

- **`WreckView`** (`GameScreen.wreck_view`): numa rede de `WRECK_STEP` (21) células da costa das ilhas temperadas, com a chance
  `WRECK_CHANCE` (0,5) e no máximo `MAX_PER_ISLAND` (2) por ilha, a célula da costa pela regra das focas (`SealView._shore`: terra
  baixa e quase plana encostada no mar, livre), com as duas vizinhas ao longo da costa também livres (o casco é comprido), fora das
  focas e longe das vilas (`sites`). `place_of`: de comprido ao longo da costa, adernado `HEEL_RAD` e afundado `SINK_M` na areia.
  `wreck_mesh`: a quilha, a roda de proa e o cadaste curvos, nove cavernas em U afinando para as pontas (duas quebradas no primeiro
  lance, uma desbotada pelo sol), duas fiadas do costado e o mastro partido caído de través. Um MultiMesh sem descarte de face. Na
  semente 1840 são 7.

## Como testar

- `tests/world/test_phase268_wrecks.gd`: na costa baixa das temperadas, fora das focas, no máximo dois por ilha, de comprido ao longo
  da costa e afundado; a vila afasta o casco; nada na ilha plana; o casco comprido com a quilha embaixo.
- Captura: `tools/capture_phase268.tscn -- <pasta>` (cada casco com a câmera do lado do mar: do lado de terra a mata tapava).
