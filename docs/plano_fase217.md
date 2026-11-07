# Plano da Fase 217 — Cortinas nas janelas

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_215_219.md` (tábua, cortina e andorinha, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BuildingKit.Spec.curtains`, na chave da forma; `spec_for` liga em todas as casas): em cada janela do corpo, no mesmo
  referencial do vidro da Fase 39 (`_cell_transform`: o balanço do enxaimel, a ala e as rotações acompanham), logo à frente dele
  (`CURTAIN_X`, entre o vidro e o caixilho).
- **O pano** (`_curtains`): os dois panos presos dos lados do vão, cada um de `CURTAIN_MIN` a `CURTAIN_MAX` dele no alto (pela
  janela, sem sorteio) e franzidos até `CURTAIN_TIE` disso embaixo, na abraçadeira, e a sanefa de `VALANCE` do vão em cima; seis
  triângulos por janela (a casa dos investidores do teto continua abaixo dos 20.000).
- **A cor** (`shaders/building_kit.gdshader`): a célula (0, 0) da paleta, que o kit não usa (a fileira de cima inteira está livre),
  pintada numa de quatro cores de pano por casa (renda, creme, rosa e verde-sálvia, `curtain_pick` pelo lugar do modelo, como os
  postigos), com as pregas descendo, que somem de longe como as telhas.
- As janelas das casas de madeira dos camponeses mostram a vidraça escura da peça do kit na frente do vidro: lá as cortinas quase
  não aparecem.

## Como testar

- `tests/presentation/test_phase217_curtains.gd`: todas as casas têm as cortinas e os outros prédios não; cada janela do corpo
  ganha seis triângulos; o pano fica entre o vidro e o caixilho e os dois panos nunca fecham a janela; a casa dos investidores do
  teto fica em 20.000 triângulos ou menos; nenhuma peça do kit nem outra cor gerada cai na célula da cortina; o shader pinta a
  célula.
- Captura: `tools/capture_phase217.tscn` (uma rua por classe na ilha plana; `cortinas_<classe>.png`, `cortinas_de_longe.png`).
