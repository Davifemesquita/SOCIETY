# Plano da Fase 200 — Gato na porta

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_200_204.md` (gato, poço e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`CatView.spot`): numa casa a cada `CAT_EVERY` pelo id (resto `CAT_REST`), menos as que têm cão
  (`AnimalView.DOG_EVERY`), sentado no chão ao lado da porta (a conta da porta do banco da Fase 174: `BuildingKit._wall_point`
  no corpo), `SIDE_M` do meio dela para o lado que o banco não usa e antes dos vasos da Fase 15, `OUT_M` à frente da parede, de
  frente para a rua e um pouco torto; um pouco maior que de verdade (`SIZE`), na escala das galinhas e do cão.
- **O gato**: o corpo sentado com as patas da frente e o rabo enrolado em volta delas (`body_mesh`) e a cabeça com as orelhas,
  os olhos e o nariz (`head_mesh`); a pelagem é a cor da instância (`FURS`: ruivo, preto, cinza, branco, creme). A cabeça olha
  para um lado ou para o outro de tempos em tempos, no `shaders/cat_head.gdshader` (tempo visual), com a conta de `glance`
  pelo dado da instância (`glance_data`). Dois MultiMesh sem sombra.
- **Custo**: a primeira versão virava as cabeças na CPU a cada quadro e se refazia a cada `building_state_changed` (o sinal
  dispara a cada troca de estado das fábricas): na cidade do benchmark, ~120 gatos, o FPS médio caiu 1,4 e o p95 subiu 1 ms. O
  giro foi para o shader e a vista passou a ouvir só o `house_upgraded` (a subida de classe); a rede da Fase 199 tinha o mesmo
  sinal e foi corrigida junto. Com o gato, o quadro ficou igual ao de antes.

## Como testar

- `tests/world/test_phase200_cats.gd`: só as casas do resto certo e sem cão têm o gato, ao lado da porta, à frente da parede, de
  frente para a rua e no chão; nenhum gato onde mora o cão; a cabeça olha para os dois lados e volta; o gato é pequeno.
- Captura: `gato_na_porta.png` e `gato_da_rua.png` no `tools/capture_phase95.tscn`.
