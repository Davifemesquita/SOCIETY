# Plano da Fase 185 — Hera nas paredes

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_185_189.md` (hera, estaca e arco-íris, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingView.ivy_of`, o parâmetro de instância `ivy`): nas ilhas temperadas, `IVY_FULL` nos serviços de pedra de
  `IVY_SERVICES` (igreja, escola, prefeitura, universidade, museu, teatro) e `IVY_HOUSE` numa casa a cada `IVY_HOUSE_EVERY` dos
  artesãos para cima (pelo hash da casa); nada nas casas de madeira dos camponeses e operários, nas fábricas e nas tropicais.
- **O desenho** (`shaders/building_kit.gdshader`): só nas células de parede (a textura PBR da parede), nas faces de lado; a hera
  sobe do chão em colunas de altura sorteada ao longo da parede (até `ivy * ivy_reach_m`), com a borda de cima recortada por
  ruído e as folhas em manchas de dois verdes (`ivy_dark`, `ivy_light`). Janelas, portas e madeiramento ficam livres (não são
  célula de parede). Sem triângulo a mais.

## Como testar

- `tests/presentation/test_phase185_ivy.gd`: os serviços de pedra cheios, parte das casas de alvenaria com menos, nada nas
  outras nem nas tropicais; com tela, o shader do kit compila com os uniformes da hera.
- Captura: a rua dos prédios grandes e as casas dos artesãos para cima no `tools/capture_phase95.tscn`.
