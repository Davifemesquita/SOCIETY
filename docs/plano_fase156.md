# Plano da Fase 156 — Papoulas no prado

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_155_159.md` (carneirinho, papoula e colheita, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView.poppy_patch`): canteiros pelo ruído de valor da ilha, com os nós a cada `POPPY_PATCH_CELLS` células e o
  canteiro onde passa de `POPPY_THRESHOLD` (perto de 7% da terra, em manchas). O hash dos nós é aritmético, não o `hash()` de um
  Array: o recheio passa por dezenas de milhares de células no jogo novo.
- **Peça** (`ScatterView.Kind.POPPIES`, no fim do enum e no fim das listas `OPEN` e `NEAR_ROAD`, para o sorteio das peças de
  antes não mudar): na célula de canteiro, `POPPY_CHANCE`, só nas ilhas temperadas e acima de `POPPY_MIN_HEIGHT_M` (fora da
  areia da praia), quase no meio da célula.
- **O canteiro** (`poppy_mesh`): `POPPY_FLOWERS` flores num disco de `POPPY_RADIUS_M` em espiral de ângulo áureo, cada uma com a
  haste fina e a taça de quatro pétalas abertas, e umas folhas rentes ao chão, ~10 triângulos por flor; o material das plantas
  (balança com o vento).

## No caminho

- A primeira versão pôs um canteiro na faixa de areia da praia: as papoulas ficaram acima de `POPPY_MIN_HEIGHT_M`.
- O benchmark mostrou o carregar 0,2 s mais lento: o ruído inteiro em cada célula custava 1,5 µs. Guardar os quatro nós da
  última célula e recusar sem a conta quando nenhum passa do limite levou a 0,8 µs, e o carregar voltou a 5,4 s.

## Como testar

- `tests/world/test_phase156_poppies.gd`: a peça é a última das duas listas; os canteiros cobrem de 2 a 20% da terra, em manchas,
  e mudam de ilha para ilha; só nas temperadas, só em célula de canteiro e acima da areia; o canteiro é baixo, cabe na célula,
  é leve e vermelho.
- Captura: `tools/capture_phase156.tscn` (o trecho da ilha principal com mais papoulas, de perto, a meia distância e de longe).
