# Plano da Fase 151 — Placas das lojas

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_150_154.md` (coluna, placa e velocípede, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingKit.SHOP_SIGNS`, `Spec.shop_sign`, na chave da forma): a padaria, o açougue, a taverna, o ourives, o
  relojoeiro, o óptico, a torrefação e a charutaria, cada uma com a figura do ofício.
- **Onde** (`shop_sign_center`): na divisa de −X da célula da porta (o lampião da Fase 104 fica do outro lado), pendurada
  do braço de ferro que sai da parede `SIGN_ABOVE_AWNING_M` acima do toldo da Fase 101 (ou a meia altura do térreo sem ele),
  a tábua de lado para a rua (perpendicular à fachada), `SIGN_OUT_M` para fora da parede.
- **A placa** (`_shop_sign`, `_sign_figure`, `_sign_ring`): o braço de ferro com a mão-francesa, as duas argolas, a tábua
  de madeira escura com o painel creme dos dois lados e a figura sobre ele, sem texto — pão em anel, presunto, caneca com a
  espuma, anel com a pedra, relógio, óculos, xícara no pires e charuto com a cinta —, nas células da paleta do kit (bronze,
  ferro, pedra clara, as cores dos toldos).

## Como testar

- `tests/presentation/test_phase151_shop_signs.gd`: cada loja da lista tem uma figura diferente, e outros prédios não têm
  placa; a placa fica inteira para fora da fachada da frente, meia célula ao lado da porta, acima do toldo e abaixo do
  beiral; ela muda a chave da forma e soma triângulos.
- Captura: `tools/capture_phase151.tscn` (ilha plana: as oito lojas em fila; `lojas.png`, `placas_de_perto.png` e
  `placas_de_perto_b.png`).
