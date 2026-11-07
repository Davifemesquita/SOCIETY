# Plano da Fase 132 — Bomba d'água

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_130_134.md` (sapê, bueiro e ardósia, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WaterPumpView.cells`): junto de uma casa a cada `PUMP_EVERY` (pelo id), na célula livre encostada nela que tem
  estrada num dos lados e fica mais perto da porta (fora do largo, da alameda, das mesas da taverna e dos silos, e quase
  plana). A célula guarda o lado da rua, para onde a bica vira. Sem célula assim, sem bomba.
- **A peça** (`pump_mesh`): a laje de pedra com o ralo, o corpo de ferro fundido com o capitel e a tampa, a bica para a
  frente, a alavanca para trás e dois baldes de aduelas com os arcos; um MultiMesh do arquipélago
  (`GameScreen.water_pump_view`).
- **O recheio** deixa a célula limpa (`ScatterView.island_context`).

## No caminho

- A captura mostrou pedras de minério da Fase 128 em cima do calçamento (a jazida ficava debaixo da rua): corrigido à
  parte, a vista das jazidas pula ruas e trilhos e se refaz quando eles mudam.

## Como testar

- `tests/world/test_phase132_water_pumps.gd`: as bombas ficam em células livres encostadas nas casas da vez, com a rua ao
  lado; o recheio deixa a célula limpa; a ilha plana não tem.
- Captura: `tools/capture_phase132.tscn` (semente 1840: uma rua calçada com casas; `bomba_de_perto.png` e `bombas.png`).
