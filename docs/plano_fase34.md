# Plano da Fase 34 — Chão sem xadrez (nossa)

**Estado: concluída em 25/10/2026**, começada com a confirmação do dono do produto ("pode ir para a próxima fase").
Ele aprovou as capturas e decidiu o hex-tiling **só no ultra** (~1,2 ms de GPU na RTX 5060; a reamostragem de longe
já tira o xadrez visto do alto).
Terceira fase do roteiro de `docs/plano_melhorias.md`. Só apresentação: **nenhuma altura, contorno ou assinatura do
terreno muda**, e nada vai para o save.

## 1. Texturas de dados por região (`world/terrain/terrain_bake.gd`, `TerrainView`)

- `TerrainBake.bake(heights, side, spacing)`: uma imagem RGBA8 por ilha, na resolução dos cantos (2 m), tirada só das
  alturas que o `region_corners` já gera: **r** inclinação, **g** curvatura (vale acima de 0,5, crista abaixo),
  **b** distância até a água (até `terrain_water_distance_m`) e **a** umidade (perto da água e nos vales).
- Função pura e determinística (mesmas alturas, mesmos bytes), em `PackedByteArray` direto (sem `set_pixel`); a
  distância é por chanfro em duas passadas. Meta: somar menos de 1 s ao jogo novo.

## 2. Shader do terreno (`shaders/terrain.gdshader`)

- **Máscaras com ruído e height-blend**: areia, floresta e lama ganham um ruído de mundo de 2 e 4 m antes do corte, e a
  troca entre camadas segue a altura do alfa de cada textura (a areia "cai" entre as pedras), no lugar do degradê linear
  que desenhava os losangos de 2 m.
- **Macro-variação** em três escalas (40, 150 e 500 m), por ruído no próprio shader: claro e escuro, e grama mais seca
  nas cristas e mais verde perto da água (das texturas de dados). É o que apaga a repetição de 12 m vista do alto.
- **Hex-tiling** (implementação própria, pelo artigo de Mikkelsen, JCGT 2022) na grama e no chão de floresta, com o
  normal map girado junto; só até `hex_distance_m` da câmera e só nos níveis com `terrain_hex_tiling` (desligado no
  baixo).
- **Reamostragem por distância** (entrou depois da primeira captura: a 420 m o xadrez de 12 m continuava, porque ali o
  hex-tiling já não vale e a macro-variação sozinha não bastou): de 60 a 320 m a textura se mistura com ela mesma 8×
  maior, e o normal map aplaina.
- **Triplanar** na rocha, só onde a encosta passa de ~35°: a textura não estica mais nas ladeiras.

## Fica de fora

Alturas, contorno e assinatura do terreno; estrada pintada e desgaste (Fase 38); o normal map assado de 0,5–1 m (as
alturas da grade são de 2 m: assar a 1 m só interpolaria, sem detalhe novo — fica para quando houver relevo visual
próprio, na Fase 36).

## Riscos

- O hex-tiling triplica as leituras da grama e da floresta: medido no benchmark por nível; desligado no baixo.
- Normal map girado no hex-tiling: errar o sentido inverte a luz das texturas.
- Assar em GDScript alonga o jogo novo e o carregar.

## Como testar

- `tests/world/test_phase34_ground.gd` (sem tela): o bake é determinístico; a inclinação, a curvatura, a distância e a
  umidade saem certas numa rampa, num vale e junto da água; o tamanho é o da região; o bake da semente 1840 cabe no
  tempo; o nível baixo desliga o hex-tiling e os outros ligam; o shader compila com os uniformes novos.
- O teste dourado do terreno (`tests/sim/test_terrain_golden.gd`) segue passando: as assinaturas não mudam.
- Capturas do arquipélago (`tools/capture_phase5.tscn`) antes e depois: `01_arquipelago`, `02_ilha_principal`,
  `07_vila_no_relevo`.
- Benchmark: jogo novo e carregar, e o FPS por nível.

## Pronto quando

A 420 m e a 1.500 m não há padrão regular; a 55 m o chão continua tão bom quanto hoje; o jogo novo subiu pouco; o custo
de GPU cabe no nível.
