# Plano da Fase 224 — Relógio de sol no largo

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_220_224.md` (bomba, barril e lençol, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SundialView.cells`): em cada serviço com largo calçado (`ForecourtView.PLAZA_SERVICES`, Fase 109: igreja, teatro,
  universidade, prefeitura, museu e escola), uma das quatro células de canto do anel em volta dele que esteja no largo, a mais para
  a frente; um relógio por serviço. Só na ilha com relevo (a ilha plana não tem largo).
- **O relógio** (`dial_mesh`): a coluna de pedra torneada (`COLUMN_PROFILE`: plinto, toro, fuste afinando e capitel), o mostrador de
  bronze esverdeado em cima com as marcas das horas em meia-volta e o gnomon em triângulo, o lado reto para o norte (−z do
  mundo), sobre as lajes do largo. Um MultiMesh; refeito também na derrubada de árvores, como o largo.

## Como testar

- `tests/world/test_phase224_sundials.gd`: na semente 1840, cada serviço do largo com um canto no largo ganha um relógio, só um,
  numa célula de canto do anel que é do largo; a ilha plana não tem; a coluna fica de pé, com o mostrador em cima, e cabe numa
  célula.
- Captura: `tools/capture_phase224.tscn` (a rua dos serviços da semente 1840; `relogio_de_sol_0.png`, `relogio_de_sol_1.png`, com a
  câmera posta à mão do lado de fora do canto, e `relogios_na_rua.png`).
