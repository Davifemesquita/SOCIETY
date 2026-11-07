# Plano da Fase 207 — Pinheiro-anão na encosta

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_205_209.md` (estandarte, bebedouro e lanterna, a
partir das capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView.Kind.ROCK_PINE`, no fim do enum e das listas `OPEN` e `NEAR_FOREST`, com a chance `ROCK_PINE_CHANCE`):
  só nas células de encosta íngreme (desnível de `ROCK_PINE_MIN_RELIEF_M` entre os cantos, mais que o do cascalho da Fase 162)
  das ilhas temperadas; o sorteio das peças de antes não muda. De pé, quase no meio da célula, com o pé enterrado para não
  ficar no ar do lado de baixo.
- **O pinheiro** (`rock_pine_mesh`): o tronco baixo e torto em três lances, um galho comprido deitado para o lado e as
  almofadas de agulhas achatadas no alto, na ponta do galho e no meio, com um tufo mais claro por cima de cada uma. Entre as
  plantas do recheio (`PLANTS`): balança com o vento.

## Como testar

- `tests/world/test_phase207_rock_pines.gd`: a peça vem no fim das listas do campo aberto e da beira da mata; os pinheiros ficam
  só nas encostas íngremes das temperadas, de pé; a malha é baixa e torta.
- Captura: `tools/capture_phase207.tscn` (o trecho da ilha principal da semente 1840 com mais pinheiros-anões).
