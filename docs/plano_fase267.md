# Plano da Fase 267 — Espinheiro florido

**Estado: feita em 02/11/2026**, terceira do roteiro `docs/plano_fases_265_269.md` (garça, ruína e cruzeiro).

## O que entrou

- **`ScatterView.Kind.HAWTHORN`** (no fim do enum, no fim da lista `NEAR_FOREST`, entre as `SHADOWED` e as `PLANTS`, que balançam
  ao vento): com a chance `HAWTHORN_CHANCE` (0,05) por célula da beira da mata, só nas temperadas, de pé no meio da célula.
  `hawthorn_mesh`: o tronco curto que se abre em dois galhos, a copa em quatro massas de folhas mais larga que alta e caída de um
  lado, e as flores brancas (umas rosadas) em pencas por toda a copa, mais no alto. A primeira versão, com pouca flor, parecia uma
  árvore com neve em cima.

## Como testar

- `tests/world/test_phase267_hawthorns.gd`: a regra no fim da lista da beira da mata e no fim do enum, entre as plantas; só nas
  temperadas, de pé; o arbusto alto e largo com a flor branca no alto. Na semente 1840 de teste, 36 espinheiros.
- Captura: `tools/capture_phase267.tscn -- <pasta>` (o trecho da ilha principal com mais espinheiros, de fora da mata).
