# Plano da Fase 161 — Madeira à deriva

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_160_164.md` (cunhal, deriva e horta, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView.Kind.DRIFTWOOD`, no fim do enum e no fim da lista `NEAR_SEA`, para o sorteio das peças de antes não
  mudar): na célula da costa, `DRIFTWOOD_CHANCE`, nas ilhas temperadas e tropicais, só até `DRIFTWOOD_MAX_HEIGHT_M` (a praia e as
  pedras baixas, não o alto da falésia) e com o chão sob o tronco até `DRIFTWOOD_MAX_SLOPE` (~25°: na encosta íngreme ele
  rolaria para o mar). Deitado, inclinado com o terreno entre as duas pontas.
- **O tronco** (`driftwood_mesh`): dois lanços tortos afinando para a ponta, a toiça das raízes quebradas numa ponta e dois tocos
  de galho, na madeira cinza-castanha lavada pelo sal (`DRIFTWOOD_BLEACHED`, as pontas em `DRIFTWOOD_DARK`), meio afundado na
  areia; faz sombra.

## No caminho

- A primeira versão punha troncos em encostas de até 50°, e eles saíam finos e brancos demais na areia clara.
- Os testes das Fases 141 e 156 exigiam que a peça deles fosse a última do enum: agora conferem só que vem depois das de antes.

## Como testar

- `tests/world/test_phase161_driftwood.gd`: a peça é a última da lista da costa e vem depois das papoulas; os troncos aparecem,
  sempre baixos, com mar ao lado e quase na horizontal; a malha é comprida, baixa e só de madeira.
- Captura: `tools/capture_phase161.tscn` (o trecho da ilha principal com mais troncos, de perto e a meia distância).
