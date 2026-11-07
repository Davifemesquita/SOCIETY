# Plano da Fase 222 — Covos no cais

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_220_224.md` (bomba, barril e lençol, a partir das capturas do Anno
do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`LobsterPotView.pots`): nos lanços do cais de pedra dos entrepostos (Fase 106), fora da frente do entreposto, na ordem
  dos lanços, até `PILES_PER_POST` pilhas a `PILE_GAP_M` ou mais umas das outras, `POT_IN_M` para dentro da beira, ao longo dela.
  Fica de fora a pilha a menos de `CLEAR_M` de um lampião, de uma cisterna, de um mastro, do alto de uma escada ou de um banco, e a
  que a terra de trás cobriria. O roteiro pensava num resto fixo de lanço, como os bancos da Fase 198; no cais da semente 1840 os
  lanços desse resto já tinham o mastro, a escada e o lampião, e os covos ficavam sem lugar.
- **A pilha** (`pot_mesh`, `_pot`): três covos de vime em meia-lua embaixo e dois em cima nos vãos (a base de tábuas, quatro arcos,
  as varas de ponta a ponta e as duas cabeceiras tramadas, de poucas faces), o cabo enrolado em três voltas e duas boias de
  cortiça com a faixa
  vermelha, uma de pé com a vara e uma deitada. Um MultiMesh.

## Como testar

- `tests/world/test_phase222_lobster_pots.gd`: as pilhas ficam num lanço do cais, na altura dele, ao longo da beira e fora da
  frente do entreposto; longe das outras peças do cais; no máximo `PILES_PER_POST`, afastadas; nada na ilha plana; a malha não passa
  da beira.
- Captura: `tools/capture_phase222.tscn` (o entreposto da semente 1840; `covos_0_do_mar.png`, `covos_0_de_tras.png`,
  `covos_longe.png`).
