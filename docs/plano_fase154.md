# Plano da Fase 154 — Velocípede encostado

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_150_154.md` (coluna, placa e velocípede, olhando o
Anno do dono: só a ideia) e do oitavo ciclo. Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`VelocipedeView.spot`): numa casa dos artesãos (`TierDef.HouseTrim.FLOWER_BOXES`, a fachada da frente sem
  gradil, sebe nem alpendre) a cada `BIKE_EVERY` pelo id, sem pátio na frente, na célula ao lado da porta, as rodas
  `OUT_M` para fora da parede, deitado `LEAN_RAD` para ela. No lugar do modelo da casa, com o desvio da variação
  (`BuildingView.model_place`).
- **O velocípede** (`bike_mesh`, `_wheel`): a roda grande e a rodinha de trás com o pneu, os raios e o cubo, o garfo com o
  guidão de través, o quadro curvo de ferro do alto do garfo até a rodinha e o selim de couro, centrado de ponta a ponta
  para caber na célula. Um MultiMesh do arquipélago (`GameScreen.velocipede_view`), refeito na obra, na demolição, na subida
  de classe e ao trocar de mundo.

## Como testar

- `tests/world/test_phase154_velocipedes.gd`: só os artesãos do resto certo têm; nas quatro rotações ele fica no chão,
  diante da fachada da frente, fora da célula da porta, deitado para a parede e inteiro dentro de uma célula.
- Captura: a rua dos artesãos do `tools/capture_phase95.tscn` (`velocipede.png`).
