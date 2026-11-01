# Plano da Fase 171 — Lenha na parede

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_170_174.md` (laterita, lenha e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`LogPileView.spot`, `_cell`, `cells`): numa casa de camponeses ou operários a cada `PILE_EVERY` pelo id, encostada
  na parede do lado de +X do corpo (no referencial do modelo), na célula do lado quando ela está livre (sem prédio nem estrada,
  em terra). A célula sai só do lote, e o recheio e as bombas d'água a deixam limpa.
- **A pilha** (`pile_mesh`): `COURSES` fiadas de achas de ponta para fora, desencontradas, com a casca escura e a ponta cortada
  clara, e a cobertura de duas tábuas caindo para fora. A peça é a mesma em todas: um MultiMesh (`GameScreen.log_pile_view`), no
  lugar do modelo da casa (`BuildingView.model_place`), com o pé no chão de verdade.

## Como testar

- `tests/world/test_phase171_log_piles.gd`: só as casas do resto certo têm a pilha, do lado delas, fora do lote, virada para
  fora; artesãos não; uma estrada na célula tira a pilha; o recheio e as bombas deixam a célula; a pilha é baixa e comprida.
- Captura: `lenha_na_parede.png` e `lenha_de_perto.png` no `tools/capture_phase95.tscn` (uma rua nova de casas de camponeses e
  operários com uma célula livre entre elas).
