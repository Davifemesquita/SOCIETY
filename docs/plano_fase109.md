# Plano da Fase 109 — Largo calçado

**Estado: feita em 30/10/2026**, a última do roteiro `docs/plano_fases_105_109.md` (cidade e porto, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save; as células do largo continuam livres para construir.

## O que entrou

- **Onde** (`ForecourtView.cells`): em volta da igreja, do teatro, da universidade, da prefeitura, do museu e da escola
  (`PLAZA_SERVICES`), cada célula do anel de uma célula em volta do prédio (lados e cantos) que é terra livre — sem
  prédio, estrada, trilho nem árvore — e quase plana (até `MAX_RELIEF_M` entre os cantos). Na frente o prédio costuma
  encostar na rua, então o largo aparece nos lados e nos fundos.
- **As lajes** (`slabs`): `SLABS` × `SLABS` por célula, com a fresta de `SLAB_GAP_M`, cada uma na altura do chão no meio
  dela (`SLAB_LIFT_M` acima), num de quatro tons de pedra pela posição; um MultiMesh só, com a caixa do arquipélago.
- **O recheio** (`ScatterView.island_context`): as células do largo entram na lista das que ficam limpas (como as portas),
  e não ganham arbusto, barril nem capim em cima.

## Como testar

- `tests/world/test_phase109_forecourt.gd`: as células ficam no anel do prédio, livres e quase planas; as lajes ficam na
  célula delas, assentadas no chão; o recheio não cai em nenhuma; padaria e ilha plana sem largo.
- Captura: `tools/capture_phase109.tscn` (semente 1840: igreja, teatro, prefeitura e escola de frente para uma rua num
  descampado; `largo_rua.png`, `largo_de_perto.png` e `largo_fundos.png`).
