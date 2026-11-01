# Plano da Fase 246 — Tronco caído com cogumelos

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_245_249.md` (coelho, cogumelo e pedra, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView`, `Kind.MOSSY_LOG`): a peça nova do recheio vem no fim do enum e no fim da lista `NEAR_FOREST` (o sorteio
  das peças de antes não muda), com a chance `MOSSY_LOG_CHANCE`, só nas ilhas temperadas e nas células de pouco desnível (até
  `SCREE_MIN_RELIEF_M`), deitada com o chão entre as duas pontas como a madeira à deriva da Fase 161 (que agora divide a conta com
  ela), e faz sombra.
- **O tronco** (`mossy_log_mesh`): a casca escura em dois lances tortos, o corte claro numa ponta e a ponta quebrada na outra, as
  almofadas de musgo por cima, três orelhas-de-pau de lado em prateleira e um punhado de cogumelos de chapéu vermelho no chão junto
  dele.

## Como testar

- `tests/world/test_phase246_mossy_logs.gd`: a peça é a última da lista da beira da mata e do enum, com sombra e fora das plantas;
  aparece nas ilhas temperadas da semente 1840, nunca nas tropicais, no chão de pouco desnível, deitada; a malha é comprida e
  baixa.
- Captura: `tools/capture_phase246.tscn` (a semente 1840; `tronco_de_perto.png`, `tronco.png`, `tronco_do_outro_lado.png`).
