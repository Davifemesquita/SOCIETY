# Plano da Fase 126 — Alpendre tropical

**Estado: feita em 30/10/2026**, segunda do roteiro `docs/plano_fases_125_129.md` (recife, alpendre e nuvens, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingKit.spec_for`, `PORCH_TRIMS`): as casas dos operários e dos artesãos (`HouseTrim.NONE` e
  `FLOWER_BOXES`) de dois andares ou mais nas ilhas tropicais (`WorldState.is_tropical`). Os camponeses ficam com o quintal
  cercado (a fileira da frente é dele), e as classes de cima, com a sacada, o gradil e o pórtico.
- **A forma**: a fileira da frente vira a varanda da casa de engenho da Fase 23 (`Silhouette.VERANDA` com
  `court_rows = 1`): a casa recua uma fileira e o alpendre de tábuas, com os degraus, os esteios com mão-francesa, o
  guarda-corpo de balaústres e o telhado de uma água preso entre os andares, ocupa a frente. Essas casas não levam o
  enxaimel saliente (Fase 102), que avançaria sobre o telhado do alpendre, nem o toldo (Fase 101) nem a ala (Fase 96).

## Como testar

- `tests/presentation/test_phase126_tropical_porch.gd`: as casas de operários e artesãos das ilhas tropicais ganham a
  varanda, sem enxaimel, toldo nem ala; as temperadas e os camponeses ficam como eram; o alpendre é desenhado na frente.
- Captura: `tools/capture_phase126.tscn` (semente 1840: uma rua de casas de operários e artesãos na maior ilha tropical;
  `alpendres.png` e `alpendre_de_perto.png`).
