# Plano da Fase 203 — Carrinho de feira

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_200_204.md` (gato, poço e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`MarketCartView.cells`): junto de cada mercado, na célula livre encostada nele que dá para a rua e fica mais perto
  da porta, pela busca da bomba (`WaterPumpView.beside_street`, fora de `taken_cells`). A bomba e o poço desviam do carrinho
  nas buscas deles (fora de `taken_cells`, que o carrinho usa: senão a lista chamaria a si mesma).
- **O carrinho** (`cart_mesh`): a caixa de tábuas sobre o eixo, as duas rodas, o pé de trás, os varais, o tabuleiro inclinado
  com montinhos de maçãs, couves, cenouras, batatas e peras (`PRODUCE`) e o guarda-sol de gomos vermelhos e creme num mastro
  no canto, de comprido ao longo da rua. Um MultiMesh, sem descarte de face (o guarda-sol é visto por baixo).
- O recheio deixa a célula (`ScatterView.island_context`). Só a ilha com relevo, como a bomba.

## Como testar

- `tests/world/test_phase203_market_carts.gd`: o carrinho fica numa célula livre encostada no mercado, com a rua ao lado; a
  bomba, o poço e o recheio deixam a célula; sem mercado e na ilha plana não há; o carrinho assenta no chão.
- Captura: `tools/capture_phase203.tscn` (uma rua de terra com dois mercados e casas na ilha principal da semente 1840).
