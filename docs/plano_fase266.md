# Plano da Fase 266 — Ruínas de muro

**Estado: feita em 02/11/2026**, segunda do roteiro `docs/plano_fases_265_269.md` (garça, ruína e cruzeiro).

## O que entrou

- **`ScatterView.Kind.RUIN`** (no fim do enum, no fim da lista `OPEN` e entre as `SHADOWED`): com a chance `RUIN_CHANCE` (0,004)
  por célula de campo aberto, só nas temperadas e no chão de pouco desnível (`SCREE_MIN_RELIEF_M`), de pé no meio da célula, com as
  pedras de baixo enterradas. `ruin_mesh`: um pedaço de muro de pedra seca de `RUIN_M` (2,2 m) em fiadas desencontradas, quebrado em
  degraus (alto numa ponta, um toco na outra), o canto que volta numa ponta, as pedras caídas do lado e o musgo no alto. As peças
  de antes não mudam (a regra nova vem no fim da lista).

## Como testar

- `tests/world/test_phase266_ruins.gd`: a regra no fim da lista do campo aberto e no fim do enum, só nas temperadas e no chão pouco
  inclinado, de pé; a malha é um muro comprido e baixo.
- Captura: `tools/capture_phase266.tscn -- <pasta>` (o trecho da ilha principal com mais ruínas).
