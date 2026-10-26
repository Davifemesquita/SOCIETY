# Plano da Fase 38 — Estradas no chão

**Estado: em andamento desde 25/10/2026**, com a confirmação do dono do produto ("pode ir para a próxima fase").
Sétima fase do roteiro de `docs/plano_melhorias.md`. Só apresentação: a simulação, o save e o gerador não mudam.
**Feita sem tela** (decisão do dono): o visual fica para as capturas quando ele liberar a tela; a chave
`GameConfig.road_paint` (ligada) volta ao ladrilho para comparar.

## 1. Máscara das estradas (`world/terrain/road_mask.gd`)

- `RoadMask`: uma imagem RGBA8 por ilha com relevo, do tamanho da grade da ilha, a `road_mask_px_per_cell` (4) pixels
  por célula de 2 m (0,5 m por pixel; ~1 MB para 256 × 256 células). Função pura do estado da simulação: nada vai para o
  save.
  - **r**: distância (até `road_mask_max_m`) à linha do meio da estrada de terra. A linha é um grafo de segmentos: do
    centro da célula ao centro de cada vizinha com estrada, e à da diagonal pura (`RoadNetwork.linked_diagonal`), que vira
    um segmento a 45° sem escada. Na esquina em L, um segmento entre os meios dos dois lados arredonda o canto de dentro;
    o de fora já sai redondo da distância. Célula solta é um ponto. Trecho entre dois paralelepípedos não entra.
  - **g**: calçamento (1 dentro da célula de paralelepípedo), para as Fases 39 a 41 e 46.
  - **b**: desgaste em frente das portas (um disco na divisa entre a célula da entrada e o prédio).
  - **a**: poças na terra (pelo hash da célula), no meio da rua, fora dos sulcos.
- Distância por carimbo: cada segmento escreve o mínimo no retângulo de pixels em volta dele. A atualização refaz só o
  retângulo das células que mudaram (comparando com a cópia anterior de `roads` e das portas), com margem de duas células;
  o envio para a GPU é da imagem inteira, uma vez por quadro (arrastar estrada gera vários `roads_changed`, agrupados no
  quadro seguinte).

## 2. Terreno (`shaders/terrain.gdshader`, `terrain_view.gd`)

- A terra batida da textura das estradas (camada 0 de `roads_albedo_rough`), pintada onde a distância fica abaixo da meia
  largura (`road_half_width_m`) mais um ruído de 1 e 4 m, misturada pela altura da grama (borda irregular). Dois sulcos
  pela distância (`rut_offset_m`), uma faixa de capim pisado na beira, poças escuras e lisas, e o desgaste das portas
  como chão batido.
- Cruzamento: a distância mínima faz uma mancha contínua. Diagonal: o segmento a 45°.

## 3. Ladrilhos (`presentation/road_view.gd`)

- Nas ilhas com relevo a terra deixa de ser ladrilho (e a faixa diagonal de terra também). Ficam como estavam o
  paralelepípedo (ladrilho até a Fase 46), as pontes (tábua e pedra), as touceiras da beira e as pedras soltas (agora no
  chão). A ilha plana dos testes e saves antigos não tem terreno: lá a terra continua ladrilho.

## Fica de fora

- Meio-fio e calçamento arredondado (Fase 46); pontes, que ficam como estão.
- Atualização parcial da textura na GPU (o Godot 4.7 não tem `update` de um retângulo de `ImageTexture`).

## Riscos

- A resolução da máscara (0,5 m) limita a nitidez da borda; o ruído e o filtro bilinear da distância escondem o pixel.
- Costura com a ponte e com o paralelepípedo: o segmento da terra entra embaixo do ladrilho e some debaixo dele.
- O pior quadro ao arrastar estrada: o carimbo é só do retângulo que mudou, medido em teste.

## Como testar

- `tests/world/test_phase38_roads.gd` (sem tela): a máscara é determinística; a rua reta, a diagonal a 45° (distância
  igual ao longo dela, sem escada), o cruzamento contínuo e o L de canto arredondado; o calçamento no canal g; o desgaste
  na porta; uma estrada nova mexe só no retângulo dela; o hash da simulação é o mesmo com e sem a máscara; a RoadView não
  põe ladrilho na terra da ilha com relevo e põe na ilha plana; o tempo da máscara da semente 1840.
- O CI compila o shader (`tests/world/test_phase35_coast.gd` compila o do terreno).
- Quando o dono liberar a tela: capturas `02_ilha_principal`, `07_vila_no_relevo` e a vila de perto; o benchmark do pior
  quadro ao construir estrada com a ilha cheia.

## Pronto quando

A 420 m a rede não forma um retângulo de riscos em ângulo reto; a diagonal não tem escada; o pior quadro de construção
continua abaixo de 50 ms; o dono aprova a terra batida e aceita o paralelepípedo em ladrilho até a 46.
