# Plano da Fase 232 — Tapete na janela

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_230_234.md` (sinal, cormorão e castanha, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WindowRugView.spot`): numa casa dos operários e dos artesãos a cada `RUG_EVERY` pelo id (resto `RUG_REST`), com andar de
  cima, na primeira janela desse andar na fachada da frente, no referencial das janelas da Fase 39 (`BuildingKit._cell_transform`:
  o balanço do enxaimel e a ala acompanham), no lugar do modelo; o meio do peitoril, `OUT_M` para fora da parede, numa base de mão
  direita com o y para cima.
- **O tapete** (`rug_mesh`): a dobra por cima do peitoril, o pano caindo `DROP_M` pela parede em `STRIPES` listras e a franja
  embaixo, de poucas faces; a cor das listras pela casa (`TINTS`, na cor da instância). Um MultiMesh sem descarte de face e sem
  sombra (o pano colado na parede quase não faz sombra, e a cidade tem centenas).

## Como testar

- `tests/world/test_phase232_window_rugs.gd`: só as casas do resto certo têm o tapete, na fachada da frente (a da rua), acima do
  térreo, com o y para cima e de mão direita; os camponeses nunca; a malha cai pela parede.
- Captura: `tools/capture_phase232.tscn` (uma rua por classe na ilha plana; `tapete_0.png` a `tapete_2.png`,
  `tapetes_na_rua.png`).
