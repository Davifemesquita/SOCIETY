# Plano da Fase 131 — Bueiros na rua calçada

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_130_134.md` (sapê, bueiro e ardósia, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ManholeView.cells`): nas células de paralelepípedo, uma a cada `MANHOLE_EVERY` pelo desenho da grade
  (`posmod(5x + 3y, 7) = 0`, sem sorteio), só no meio de uma rua reta (estrada dos dois lados numa direção só: nem a
  esquina, nem o cruzamento, nem a ponta) e fora do rio. A busca anda só nas células calçadas (o `find` do array).
- **A tampa** (`cover_mesh`): disco de ferro fundido com o aro, a grade em cruz e dois anéis, rente ao calçamento, girada
  pelo desenho da grade; um MultiMesh do arquipélago, refeito quando a estrada muda (`GameScreen.manhole_view`).

## No caminho

- O calçamento da grade dual (Fase 46) fica `PavedDual.LIFT_M` acima do chão: a primeira tampa, assentada pela altura da
  estrada, sumia por baixo dele. Agora `LIFT_M` parte do `PavedDual.LIFT_M` (o teste confere).

## Como testar

- `tests/world/test_phase131_manholes.gd`: as tampas ficam só no meio das ruas retas de paralelepípedo, pelo desenho da
  grade; a rua de terra não tem; a vista acompanha a estrada; a tampa fica acima do calçamento e abaixo do meio-fio.
- Captura: `tools/capture_phase131.tscn` (semente 1840: uma rua calçada com casas; `bueiro_de_perto.png` e `bueiros.png`).
