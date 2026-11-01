# Plano da Fase 205 — Estandartes na fachada

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_205_209.md` (estandarte, bebedouro e lanterna, a
partir das capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BannerView.places_of`): na prefeitura, no teatro, na universidade, no museu e na escola (`SERVICES`), um de cada
  lado da porta, na divisa da célula dela (a conta da porta do banco da Fase 174: `BuildingKit._wall_point` no corpo), pendurado
  num braço de ferro `ARM_M` para fora da parede, com o alto `BELOW_FLOOR_M` abaixo do alto do segundo andar (do primeiro, no
  prédio de um andar) e o pano esticado até o que cabe acima da porta (`DOOR_CLEAR_M`, no mínimo `MIN_LENGTH_M`). No lugar do
  modelo (`BuildingView.model_place`).
- **O estandarte** (`banner_mesh`, `shaders/banner.gdshader`): o braço com a mão-francesa, a vara dourada, o pano de rabo de
  andorinha na cor do prédio (`COLORS`: vermelho, roxo, azul, verde, ocre, pelo dado da instância), o galão dourado nas beiras e
  no alto e o emblema em losango. O shader balança o pano para fora e para dentro da fachada, mais embaixo, com uma onda pelo
  comprido, mais forte com o vento (os globais da Fase 22), no tempo visual; no máximo ~0,3 m embaixo, menos que o braço. Um
  MultiMesh.

## Como testar

- `tests/world/test_phase205_banners.gd`: cada serviço tem dois estandartes, nas duas divisas da célula da porta, `ARM_M` para
  fora, com o comprimento na faixa e o pano acabando acima da porta; o pano desce do braço.
- Captura: `estandartes.png` e `estandartes_da_rua.png` no `tools/capture_phase95.tscn` (a rua dos prédios grandes).
