# Plano da Fase 93 — Porto em toda ilha

**Estado: feita em 28/10/2026**, quarta do roteiro `docs/plano_fases_90_94.md`. Achada na Fase 92: no terreno v3 (o
padrão do jogo novo desde a Fase 52), as ilhas 3 e 4 da semente 1840 não tinham nenhum lugar de entreposto — a costa
não era plana e o plano não encostava no mar — e **não podiam ser colonizadas**.

## O tamanho do problema

Em 31 sementes do arquipélago padrão no v3 (1840 e 1 a 30), 12 tinham ao menos uma ilha sem lugar de entreposto (quase
sempre as temperadas pequenas, de 80×80); nos arquipélagos pequenos dos testes, mais ainda. No v1 as oito ilhas da semente 1840
têm lugar.

## O que entrou

- **Terreno v4** (`ArchipelagoGenerator.VERSION_V4`, `_ensure_harbor`, `harbor_site`): o v3 com um passo no fim (depois
  dos rios e das jazidas, antes da mata). Se a ilha já tem um lote de `HARBOR_CELLS` (6, o lado do entreposto) em terra,
  plano, encostado no mar e com uma frente onde passa estrada, nada muda — **a ilha sai igual à do v3, assinatura por
  assinatura**. Se não tem, o passo aplaina o lote de costa que menos mexe no relevo (o desnível dos cantos de terra mais
  `HARBOR_SEA_COST_M` por célula de mar a aterrar, pelo menos `HARBOR_MIN_LAND` de terra, longe de rio e de jazida): o
  lote vai à altura média da terra dele (pelo menos `HARBOR_ABOVE_SEA_M` acima do mínimo de terra) e o anel em volta fica
  a até meio `max_road_relief_m` dela, para a rua da frente caber. O mar vizinho continua mar: o lote encosta nele. Só as
  células mexidas são reclassificadas (classificar a ilha toda apagaria os rios). Só aritmética no caminho das alturas
  (sem `sin`/`pow`), como pede a regra da Fase 45.
- **O jogo novo usa o v4** (`GameConfig.new_game_terrain_version` = 4); a opção "Enseadas e falésias" do diálogo de jogo
  novo cria o v4 (`NewGameDialog.TERRAIN_VERSIONS`). O v1, o v2 e o v3 seguem para os saves deles, com as assinaturas de
  sempre (o teste dourado passou sem mudar nenhuma).
- **`SiteFinder` não pula mais lotes bons**: o filtro rápido "a origem está perto da água" dilatava em 4 direções até o
  maior lado + 1, e um lote 6×6 encostado no mar pelo canto oposto ficava a até 12 células da água; o filtro passou a
  largura + altura. Na semente 12 a ilha 3 tinha lugar pelas regras e o `SiteFinder` não achava. O `SiteFinder` decide a
  câmera do jogo novo e serve às ferramentas e aos testes; quem constrói à mão já seguia as regras.

## Números

- Em 31 sementes, toda ilha do v4 tem lugar de entreposto pelo `SiteFinder` (as regras do jogo). Na 1840 só as ilhas 3
  e 4 mudam.
- Gerar o arquipélago padrão em série: ~2,5 s no v3, ~2,7 s no v4 (a conferência do porto em cada ilha e o aplainar).
- Save: nenhum campo novo (a versão do terreno já ia no save); o teste confere que um mundo v3 salvo abre v3.

## Como testar

- `tests/sim/test_phase93_harbors.gd`: toda ilha do v4 de seis sementes tem lugar; o entreposto é construído de verdade
  nas ilhas 3 e 4 da 1840; ilha que tinha porto no v3 sai igual, a que não tinha muda; o lote tem o lado do entreposto;
  o jogo novo usa o v4 e um save v3 abre v3.
- `tests/sim/test_terrain_golden.gd`: as assinaturas do v4 (semente 1840 e os quatro arquipélagos pequenos); as do v1,
  v2 e v3 não mudaram.
- A conferência no Linux (WSL), que a Fase 45 pede para o gerador, ficou de fora: o passo novo só faz soma, média,
  mínimo e máximo, sem as funções que erram o último bit entre sistemas.
