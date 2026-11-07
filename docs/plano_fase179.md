# Plano da Fase 179 — Juncos na margem

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_175_179.md` (espantalho, cegonha e vaga-lume, a partir
das capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A peça** (`ScatterView.Kind.REEDS`, no fim do enum e na lista `PLANTS`: balança com o vento como as outras plantas):
  `reeds_mesh`, uma touceira de `REEDS_BLADES` folhas compridas e estreitas quase de pé, verdes no pé e secando na ponta, e a
  cada quarta folha a haste da taboa com a espiga marrom em cruz.
- **Onde** (`ScatterView._reeds`): na célula de terra livre encostada num rio pelo lado (o laço do recheio já olha os quatro
  lados), só na margem baixa (`REEDS_MAX_HEIGHT_M`: num rio de garganta o alto da parede fica sem), de uma a `REEDS_CLUMPS`
  touceiras na beira da água, espalhadas ao longo dela, com a chance `REEDS_CHANCE`.
- **Sorteio próprio, depois das outras peças da célula**: a regra da célula (campo aberto, beira da mata, costa…) não muda e
  as peças de antes saem iguais. Nas tropicais também (taboa e papiro dão nas duas).

## Como testar

- `tests/world/test_phase179_reeds.gd`: a peça é a mais nova do enum e está nas plantas; as touceiras só na terra encostada no
  rio, na margem baixa, de pé; o mesmo mundo dá os mesmos juncos; as medidas da touceira.
- Captura: `tools/capture_phase179.tscn` (as touceiras da ilha principal, de perto e de meia distância, da terra para o rio).
