# Plano da Fase 353 — Miolo da quadra

**Estado: feita em 07/11/2026**, a quarta do roteiro `docs/plano_fases_350_354.md` (cidade gasta). No Anno o miolo da quadra é de terra
pisada, com hortas, varais e árvores; o nosso era capim entre os chãos de vila de cada casa.

## O que entrou

- **O chão de vila mais largo** (`RoadMask.TOWN_YARD_REACH_M`, Fase 301): o lote de cada casa das temperadas cresce 3,4 m (era 2,2) no
  chão batido do canal b da máscara das estradas. Duas casas com um vão de três células (6 m) têm o miolo todo de terra pisada. A força
  segue 0,85 (mais fraca que o terreiro tropical, a intenção da Fase 301). A rua larga da Fase 337 lê o mesmo canal e fica larga onde
  passa por ele. As hortas (Fase 163), os varais (Fase 15) e as árvores de quintal (Fase 105) já existiam; o capim do tapete não cresce
  colado nos prédios (Fase 301).
- **O teste da Fase 301** media a borda recortada a 30% do alcance, que agora cai dentro do chão cheio: passa a medir a 80%.

## Medida

O mesmo carimbo, maior: sem custo de quadro.

## Como testar

- `tests/world/test_phase353_block_ground.gd`: o alcance cobre o vão de três células, a força e a folga da máscara refeita em volta da
  obra. Os das Fases 111, 301 e 337.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase352\depois\`, depois em
  `F:\ferramentas\capturas\fase353\depois\`. A vila das capturas é compacta, e a diferença se vê pouco nela.
