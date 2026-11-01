# Plano da Fase 197 — Casinha do cão

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_195_199.md` (cemitério, pato e rede, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`KennelView.spot`, `_cell`, `cells`): nas casas que têm cão na porta (as mesmas do `AnimalView`, `DOG_EVERY` pelo id),
  na célula do lado de −X do lote, na fileira da frente (`FROM_WALL_M`, `FROM_FRONT_M` no referencial do modelo da casa, com o
  desvio da variação de `BuildingView.model_place`); só com a célula livre (terra sem prédio, estrada, trilho nem árvore) e
  quase plana. Do outro lado do lote fica a lenha da Fase 171; o barril de chuva da Fase 169 fica atrás.
- **A casinha** (`kennel_mesh`): soalho, paredes de tábuas com as frestas, telhado de duas águas com beiral e cumeeira, as
  empenas, a porta em arco virada para a frente da casa e a tigela de lata com água. Um MultiMesh.
- O recheio (`ScatterView.island_context`) e as bombas d'água deixam a célula.

## Como testar

- `tests/world/test_phase197_kennels.gd`: só as casas com cão têm a casinha, do lado de −X, na metade da frente, com a porta
  para a frente e assentada no chão; célula com estrada não tem; o recheio e as bombas deixam a célula; a casinha cabe na
  célula.
- Captura: `casinha_do_cao.png` e `casinha_do_cao_rua.png` no `tools/capture_phase95.tscn` (a rua de casas espaçadas).
