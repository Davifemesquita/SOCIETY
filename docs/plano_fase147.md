# Plano da Fase 147 — Mastros no cais

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_145_149.md` (relógio, cais e cata-vento, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`QuayMastView.masts`): no lanço do cais de pedra (Fase 106) mais longe do entreposto de cada lado, fora da
  frente do prédio, `MAST_IN_M` para dentro da beira (atrás da grade e dos lampiões da Fase 146); nada do lado sem cais além
  da frente.
- **O mastro** (`mast_mesh`): o soco de pedra, o mastro de madeira caiada afinando em quatro lanços, dois anéis de ferro e
  a bola dourada no alto.
- **A flâmula** (`pennant_mesh`): comprida, de rabo de andorinha, presa perto do alto; é uma `WindFlag` (Fase 22): o
  `WeatherView` a vira para o lado do vento e a faz tremular, e com o ar parado ela cai. As cores se alternam pelo mastro
  (`PENNANTS`: vermelha, azul, branca). Nós de verdade, dois por entreposto (`GameScreen.quay_mast_view`), refeitos na
  obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase147_quay_masts.gd`: no máximo um mastro de cada lado, fora da frente do prédio e para dentro da
  beira; cada mastro tem a flâmula no grupo das `WindFlag`; a ilha plana não tem; a flâmula tem o comprimento e a altura
  dela.
- Captura: `tools/capture_phase147.tscn` (semente 1840: um entreposto na costa da ilha principal, o jogo andando um pouco
  para o vento virar as flâmulas; `mastros.png` e `flamula_de_perto.png`).
