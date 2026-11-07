# Plano da Fase 127 — Cisternas no cais

**Estado: feita em 30/10/2026**, terceira do roteiro `docs/plano_fases_125_129.md` (recife, alpendre e nuvens, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`HarborView.cistern_places`): uma cisterna de cada lado do entreposto, no primeiro lanço do cais de pedra da
  Fase 106 que passa `CISTERN_CLEAR_M` da largura do prédio (o cais de tábuas, a carga e os barcos ficam livres), no meio da
  plataforma, assentada no alto dela. Sem cais de pedra daquele lado (a ilha plana, a terra subindo), sem cisterna.
- **A peça** (`FarmSiloView.cistern_mesh`, junto do silo e da caixa d'água da Fase 117): baixa e larga, de aduelas em tons
  alternados com três arcos de ferro, sobre um soco de pedra, com a tampa cônica rasa e uma bica; um MultiMesh na
  `HarborView`, refeito com o resto do porto.

## Como testar

- `tests/world/test_phase127_cisterns.gd`: as cisternas ficam no cais de pedra, fora da largura do entreposto, uma de cada
  lado e no alto da plataforma; a vista as desenha; as aduelas têm as faces para fora.
- Captura: `CAPTURA_SO=porto` no `tools/capture_phase5.tscn` (`14_cais.png` e `14b_cisternas.png`).
