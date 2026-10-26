# Plano da Fase 45 — Ilhas novas (`terrain_version = 2`)

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima
quarta fase do roteiro de `docs/plano_melhorias.md`. O v1 fica congelado (o teste dourado confere) e continua o padrão dos
jogos novos (`GameConfig.new_game_terrain_version = 1`) **até o dono aprovar o v2 pela prévia** do jogo novo, onde ele já
pode escolher "Orgânicas (experimental)". O save não muda de versão: ele já guardava `terrain_version`, e os saves
refazem o terreno na versão que gravaram. Nada aparece na tela do dono (testes sem janela; capturas na área de trabalho
escondida).

## 1. Gerador v2 (`sim/world/archipelago_generator.gd`, `data/terrain_v2_params.gd` e `data/terrain_v2.tres`)

- **Contorno**: união suave de 5 a 7 elipses giradas e alongadas (uma no meio, as outras em volta, em ângulos
  espaçados), enquadradas para a mais longe tocar `shore` (0,9 da meia largura); domínio torcido em dois níveis (warp);
  costa fractal de rugosidade variável (enseadas lisas, cabos recortados); até três ilhotas baixas na faixa da costa e
  bancos de areia rasos logo depois dela. A borda da grade é sempre mar (`EDGE_SEA`).
- **Patamares por região**: o nível de cada região sai do valor da célula de Voronoi (`FastNoiseLite` celular), puxado um
  pouco para cima no miolo, e cai nos degraus de `terrace_levels_m`; o lugar de leitura é torcido (`PLATEAU_BEND_M`), então
  as divisas curvam. Uma planície do litoral no primeiro patamar até uma borda irregular (não anéis); ondulação de
  ±0,16 m dentro do patamar (cabe na tolerância de construção); nenhum canto mais de 2,5 m acima de um vizinho (encostas).
- **RNG por ilha**: a semente de cada ilha já é `hash(semente, índice)`; os ruídos e as elipses do v2 saem dela, com sais
  próprios. Chão, rios, floresta e jazidas são os do v1; no v2, sem lugar plano para a jazida, o lote de terra menos
  acidentado é aplainado (a mina sempre cabe onde o perfil pede).
- **Despacho**: `build_island(spec, config, versão)`, `new_world(..., versão)`, `assemble`, `ArchipelagoJob`,
  `ArchipelagoPreview` e `WorldState.from_dict` (aceita 1 e 2; versão desconhecida, recusado).

## 2. Prévia e escolha

- O diálogo de jogo novo tem "Ilhas: Clássicas / Orgânicas (experimental)", e a prévia da Fase 44 mostra a escolhida.

## Números (semente 1840 e mais três, ilhas de 120/70/50/50 células nos testes)

- **Não é quadrado**: a terra enche 63–80% do retângulo em volta dela no v2, contra 81–90% no v1.
- **Área construível**: 45–98% da do v1 por ilha (a principal 58–73%); lotes de casa válidos na principal 53–78%. O v2
  perde os cantos do quadrado: é uma mudança de balanceamento, e a faixa (provisória no teste: pelo menos 40% da do v1 e
  15% da grade) é decisão do dono.
- **Tempo de geração** do arquipélago padrão em série: v1 ~0,95 s, v2 ~1,9 s (em threads, a principal domina).

## Fica de fora

- Erosão (nem visual); Terrain3D; mudar a regra de inclinação construível.
- O jogador-robô no v2: ele joga numa ilha plana de 350 × 350 (a terra do arquipélago no lugar das colônias), então a
  comparação ficou pelas regras da simulação (lotes de casa, jazidas, entreposto) em vez de partidas inteiras.

## Riscos

- Balanceamento (menos terra construível); cenários de semente fixa (seguem no v1 enquanto o padrão for 1).
- `FastNoiseLite` e `hash()` numa versão nova do motor: o teste dourado do v2 pega (Fase 48).

## Como testar

- `tests/sim/test_phase45_terrain_v2.gd`: o padrão segue 1; v2 determinístico e independente da ordem (ilha sozinha =
  ilha no mundo); não quadrado e com área construível; entreposto em toda principal; métricas do robô (lotes de casa,
  jazidas onde o v1 tem); saves v1 e v2 refazem o mesmo terreno, versão 3 recusada; job e prévia seguem a versão; tempo.
- `tests/sim/test_terrain_golden.gd`: v0 e v1 inalterados (agora pedindo a versão 1 explicitamente) e as assinaturas do v2
  gravadas (provisórias até a aprovação).
- Capturas: `tools/capture_phase45.tscn` (v1 e v2 a 1.500, 420 e 110 m e a carta gravada de cada um).

## Pronto quando

Nenhuma ilha lê como quadrado a 1.500 m; os patamares deixam de ser concêntricos; o dono aprova a forma pela prévia e a
faixa de balanceamento, e decide quando o v2 vira o padrão (aí as assinaturas do v2 ficam definitivas).
