# Plano da Fase 213 — Lenha da padaria

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_210_214.md` (pombo, mó e buxo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`OvenWoodView.spot`): em cada padaria, ao lado da boca do forno da Fase 137 (`FurnaceGlowView.mouth`), `ALONG_M` ao
  longo da parede para o lado de +x da boca, encostada nela (fora do contorno de tijolo), no referencial da boca. Só se a célula
  do lado está livre: com um vizinho encostado, a lenha entraria na parede dele.
- **A lenha** (`wood_mesh`): a pilha de achas em fiadas, de ponta para fora (a casca e o miolo alternando, a ponta cortada mais
  clara), sob uma tábua, e a pá de forno de cabo comprido de pé, inclinada contra a parede. Um MultiMesh.
- A captura da Fase 95 ganhou uma padaria sozinha no fim da rua espaçada: a da rua dos prédios grandes encosta no museu.

## Como testar

- `tests/world/test_phase213_oven_wood.gd`: em todas as rotações a lenha fica na mesma parede da boca, `ALONG_M` ao lado dela;
  as outras fábricas de forno não têm; a pilha é baixa e não chega na boca; um canteiro encostado na célula do lado tira a lenha.
- Captura: `lenha_da_padaria.png` no `tools/capture_phase95.tscn` (câmera à mão).
