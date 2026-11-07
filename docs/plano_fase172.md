# Plano da Fase 172 — Carrinho de mão

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_170_174.md` (laterita, lenha e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WheelbarrowView.cells`): no pátio de chão batido (Fase 165) de um prédio de produção a cada `BARROW_EVERY` pelo id
  (fora as fazendas de campo), parado na célula livre encostada no meio da face de trás (de terra, sem prédio, estrada, trilho
  nem árvore), girado pelo id. O recheio e as bombas d'água deixam a célula limpa.
- **O carrinho** (`barrow_mesh`): a caixa de tábuas abrindo para cima, a roda de aro de ferro na frente, os dois braços com os
  punhos para trás e as duas pernas. Um MultiMesh (`GameScreen.wheelbarrow_view`), com o pé no chão.

## Como testar

- `tests/world/test_phase172_wheelbarrows.gd`: só as oficinas do resto certo têm o carrinho, atrás delas e fora do lote; casas
  não; uma estrada na célula o tira; o recheio e as bombas deixam a célula; o carrinho tem o tamanho de um carrinho, com a roda
  na frente.
- Captura: `tools/capture_phase172.tscn` (uma olaria e um lenhador na ilha principal, a câmera no carrinho).
