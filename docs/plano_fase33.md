# Plano da Fase 33 — Por cima do mundo (nossa)

**Estado: concluída em 25/10/2026**, começada com a confirmação do dono do produto ("pode seguir para a próxima
fase"); a regra dos ícones (seção 3) foi aprovada por ele no mesmo dia.
Segunda fase do roteiro de `docs/plano_melhorias.md`. Só apresentação: **nada muda na simulação nem no save**.

## 1. A grade fica no chão (`presentation/debug_overlay.gd`, `shaders/grid_overlay*.gdshader*`)

- A causa: com um destaque pedido pela partida (jazida, mata, litoral, raio de serviço, camada de mapa), o
  `DebugOverlay` trocava a malha inteira para o material raio-X (`depth_test_disabled`), e as **linhas da grade da ilha
  toda** passavam a ser desenhadas por cima das copas e dos prédios.
- Agora são duas passadas na mesma malha: as **linhas** sempre com teste de profundidade (`material_override`), e só as
  **células destacadas** atravessam (`material_overlay`, raio-X sem linhas), para o alcance continuar visível debaixo
  das casas.
- As linhas aparecem **só em volta do cursor** (`build_grid_radius_m`, com o fade nos últimos 45%), e não mais até o
  horizonte.

## 2. A prévia mostra o prédio (`presentation/build_preview_view.gd`, `shaders/build_ghost.gdshader`)

- No lugar da caixa chapada, o **fantasma do próprio modelo** (`BuildingKit`), girado como vai ficar; a caixa fica para
  o que não tem modelo (campo, pasto, píer, decoração).
- Válido e inválido **por cor e por padrão**: inválido (e a área de demolição) leva listras diagonais, para não depender
  só do vermelho e do verde. Borda clara pelo ângulo (fresnel), que desenha o contorno sem stencil.

## 3. Os ícones de estado deixam de fazer fila (`presentation/status_icon_rule.gd`, `presentation/building_view.gd`)

Regra (a aprovar pelo dono do produto; os números ficam no `GameConfig`):

- Até `status_icon_full_m` da câmera, cada prédio parado mostra o seu ícone, inteiro.
- Mais longe, os ícones **iguais** que caem no mesmo quadrado de `status_icon_cluster_m` viram **um só** (o indicador
  agregado), que esmaece até `status_icon_min_alpha` em `status_icon_fade_end_m`. Nenhum problema some: cada motivo
  continua com um ícone em cada pedaço da cidade.
- O prédio sob o cursor e o selecionado sempre mostram o seu; com uma camada do mapa ligada, todos aparecem.

## Fica de fora

Regras de construção; o feed de avisos (Fase 43); contorno de seleção por stencil (o fresnel do fantasma cobre a prévia,
e a seleção atual segue como está).

## Riscos

- O fantasma é transparente e disputa ordem com água e fumaça: `render_priority` acima delas.
- Agregar ícones esconde quantos prédios têm o problema: o painel e as notificações continuam contando todos.
- `material_overlay` desenha a malha da grade duas vezes quando há destaque (só nesse caso).

## Como testar

- `tests/presentation/test_phase33_over_the_world.gd`: as linhas da grade sempre com teste de profundidade e as células
  destacadas no overlay sem linhas; o foco da grade segue o cursor; a prévia usa o modelo do kit, com listras quando
  não pode; a regra dos ícones por distância (perto todos, longe um por motivo e quadrado, o selecionado e o do cursor
  sempre, todos com a camada ligada).
- Capturas `06_mina_na_jazida` e `07_vila_no_relevo` antes e depois (`tools/capture_phase5.tscn`).
- Benchmark sem custo no tick.

## Pronto quando

A 55 m nenhuma linha da grade aparece sobre a mata; a prévia mostra o prédio; a 110 m não há fila de ícones iguais.
