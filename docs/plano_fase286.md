# Plano da Fase 286 — Tapete de capim

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_285_289.md`. De perto, o capim era a textura chapada do
terreno com umas touceiras soltas do recheio (Fase 41). No Anno, o prado é um tapete de capim com as folhas à mostra perto da
câmera.

## O que entrou

- **`GrassCarpetView`** (`presentation/grass_carpet_view.gd`, `GameScreen.grass_carpet_view`), a primeira vista que segue a câmera
  e não o mundo.
  - Em volta do ponto do chão que a câmera olha, até `radius_m` (90 m vezes o alcance dos detalhes do nível gráfico).
  - `TUFTS_PER_CELL` (8) tufos por célula de capim livre (`grows_at`): terra sem árvore, prédio, estrada nem trilho, a mais de
    três células do mar (a praia) e de duas do rio (a margem), com desnível de até `MAX_RELIEF_M` (0,6 m).
  - Lugares, giros e tamanhos dos tufos (`tufts`) são sorteados pela célula: os mesmos sempre.
- **Os blocos**: um MultiMesh sem sombra por bloco de 8 × 8 células.
  - Até `BUILDS_PER_FRAME` (3) por quadro, o mais perto primeiro; os que saem do raio são soltos.
  - Montar um bloco leva ~0,7 ms (129 blocos em 94 ms no teste).
  - Uma obra, uma demolição, uma estrada ou uma derrubada de árvores marca os blocos da ilha, refeitos aos poucos.
  - Com a câmera a mais de `MAX_CAMERA_M` (150 m) do chão, a vista fica escondida. Nada vai para o save.
- **O tufo** (`tuft_mesh`): sete folhas finas em leque, de 0,4 a 0,75 m, escuras no pé e claras na ponta, com a normal para cima
  (pegam a luz do chão).
- **`shaders/grass_carpet.gdshader`**:
  - o tufo cresce nas manchas do prado da Fase 285 (o mesmo ruído do terreno): mais alto e escuro no capim alto, baixo e claro
    no baixo;
  - balança com o vento (só a ponta); "reduzir movimento" (Fase 43) para o balanço;
  - encolhe até sumir de 55 a 95 m da câmera: o tapete acaba sem borda.
- **A primeira versão**, de folhas de 0,22 a 0,42 m sumindo de 30 a 55 m, não aparecia na distância normal da câmera.

## Medida

O trajeto do benchmark passa quase só pela vila e ficou neutro: GPU 12,3 ms, contra 12,2 na Fase 285. Com a câmera em cima do
prado aberto (`tools/grass_cost.tscn`, ~32 mil tufos), o tapete custa na GPU:

- +0,39 ms a 30 m;
- +0,34 ms a 60 m;
- +0,17 ms a 110 m.

## Como testar

- `tests/presentation/test_phase286_grass_carpet.gd`:
  - o tufo de folhas finas, escuras no pé;
  - o tapete só no capim livre;
  - os tufos na própria célula e no chão, com o mesmo sorteio;
  - os blocos seguindo o foco, aos poucos pelo orçamento e soltos quando ele vai longe;
  - uma casa no prado refazendo o bloco sem tufo no lote;
  - escondido sem câmera;
  - o shader compilando com os uniformes dele (com tela).
- Captura: `tools/capture_phase285.tscn -- <pasta>` (o prado de perto, de meia distância e as papoulas). O custo é medido em
  `tools/grass_cost.tscn -- <saida.md>`.
