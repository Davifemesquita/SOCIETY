# Plano da Fase 211 — Mós no moinho

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_210_214.md` (pombo, mó e buxo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`MillstoneView.sites`, `cells`): em cada moinho, a célula do meio de um lado (o de −X da frente primeiro, depois o de
  +X; as pás ficam na frente), encostada nele, de terra, livre, fora do largo e da alameda, e quase plana.
- **As mós** (`millstone_mesh`, `_millstone`): duas mós de pedra velhas, de pé encostadas na parede, uma um pouco à frente da
  outra, com a borda, o furo do eixo e os sulcos em raio na face; ao lado, a pilha de cinco sacos de farinha brancos com o nó.
  Um MultiMesh.
- O recheio e as bombas deixam a célula. A captura da Fase 95 ganhou o moinho no fim da rua dos prédios grandes.

## Como testar

- `tests/world/test_phase211_millstones.gd`: as mós ficam de lado (nem na frente, nem atrás), encostadas no moinho; com a célula
  bloqueada, vão para o outro lado; outros prédios não têm; o recheio deixa a célula; a peça fica na célula.
- Captura: `mos_no_moinho.png` e `mos_de_longe.png` no `tools/capture_phase95.tscn`.
