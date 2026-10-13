# AGENTS.md — Society

City builder 3D de economia e logística no estilo do gênero de Anno 1800, em **Godot 4.7.2
(Forward+)**, GDScript com tipagem estática, para PC Windows. A especificação completa é
[`docs/especificacao.pdf`](docs/especificacao.pdf) e manda em tudo: este arquivo só
registra como se trabalha aqui e o estado das fases.

Repositório **só local**, sem remote (decisão do dono do produto em 12/10/2026). Por isso
ainda não há CI: o GitHub Actions com gdUnit4-action entra quando houver repositório.

## Regras da especificação (seção 17)

- **Uma fase por vez.** Antes de cada fase, um plano curto (arquivos, riscos, como testar);
  depois, o que mudou, como testar, o benchmark e um commit. **Nunca avance de fase sem a
  confirmação do dono do produto.**
- **Nada some sem aviso.** Não reescreva nem remova sistema que funciona sem avisar;
  mudança grande de arquitetura só depois de perguntar.
- **Contradição ou inviabilidade na especificação:** aponte e proponha alternativa antes de
  implementar.
- **Proibido:** qualquer conteúdo dos jogos Anno (nomes, textos, ícones, modelos, músicas,
  dados) e código GPL dentro do jogo.

## Língua

A especificação manda **nomes de código em inglês** e isso vale aqui, ao contrário do resto
da máquina. **Comentários, commits, documentação e mensagens de log seguem em português.**
Texto de interface só por chave de tradução, em `ui/translations/strings.csv` (`pt_BR` e
`en`); nunca string literal na tela.

## Comandos

```bash
tools/godot.sh importar            # importa os recursos; obrigatório num clone novo
tools/godot.sh testes              # suíte gdUnit4 no xvfb (res://tests), ~3 min
tools/godot.sh testes res://tests/core/test_tick_clock.gd   # um arquivo
tools/godot.sh rodar               # abre o jogo
tools/godot.sh editor              # abre o editor
tools/godot.sh captura saida.png 180   # grava o quadro 180 do jogo em PNG
tools/godot.sh exportar windows    # exportado/windows/Society.exe (ou: linux)
tools/godot.sh planilha            # CSV de balanceamento a partir dos dados (exportado/balanceamento/)

# verificação visual: Fase 2 (vila com economia rodando 30 min, painéis, estatísticas) e
# Fase 3 (carroças, armazém, corte de estrada); --quit-after evita travar se o script falhar
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 3000 res://tools/capture_phase3.tscn -- /pasta/de/saida
# Fase 4: céu em seis horas do dia, multidão de perto e de longe, janelas à noite
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 8000 res://tools/capture_phase4.tscn -- /pasta/de/saida
# Fase 5: arquipélago da semente 1840 (de cima, litoral, floresta, rio, jazida, vila, poluição, noite)
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_phase5.tscn -- /pasta/de/saida
# refaz os pedestres (VAT) a partir de assets/source/quaternius; com a pasta dos pacotes
# baixados (UAL1_Standard.glb, UAL2_Standard.glb) como argumento, refaz antes as animações
tools/godot.sh godot --headless --path . --script res://tools/bake_pedestrians.gd
# benchmark da fase, anexado ao registro
tools/godot.sh godot --path . --resolution 1920x1080 res://tools/benchmark.tscn -- "$PWD/docs/benchmark.md"
```

O binário fica em `~/ferramentas/godot/` (troque por `GODOT_BIN`), com os modelos de
exportação em `~/.local/share/godot/export_templates/4.7.2.stable/`.

**Esta VM não tem GPU.** Sem tela, `tools/godot.sh` roda o jogo e o editor no `xvfb-run`
com Vulkan por software (lavapipe). Serve para testar, capturar e exportar, mas **FPS medido
aqui não vale**: o benchmark de desempenho só conta no PC alvo (60 FPS em 1080p numa RTX
3060).

O runner do gdUnit4 imprime dois `ERROR` de "Remote Debugger" no início: é proposital (ele
aponta o depurador para a porta 0 para não travar em erro de parse). Os `WARNING:
SaveSystem` da suíte também são esperados, porque os testes forçam saves inválidos.

A suíte roda **com tela** (xvfb), não headless: `tests/ui/test_game_screen_input.gd` sobe a
partida e simula mouse e teclado, e em headless o clique não chega ao mundo 3D. Duas manias
do runner de cena do gdUnit4 (6.2.2), que não são defeito do jogo:

- **depois de `simulate_key_pressed`, o próximo clique sai em (0, 0)** — ele só copia a posição
  do mouse do último evento se esse evento for de mouse. Chame `simulate_mouse_move` antes de
  clicar.
- **ele entrega cada evento duas vezes ao nó raiz da cena** (`_unhandled_input` direto, além
  do caminho normal). Por isso a raiz da partida não trata entrada: os atalhos ficam em
  `GameShortcuts`, filho dela. Atalho que alterna (pausa) na raiz alternaria duas vezes.

No executável: `Society.exe -- --novo-jogo` abre direto uma partida, `-- --carregar` abre o
save rápido e `-- --benchmark` roda o benchmark e mostra o resultado na tela (é assim que se
mede no PC alvo; desde a Fase 4 inclui um dia inteiro renderizado com 2.000 pedestres, e desde
a Fase 5 é no arquipélago da semente 1840). `-- --semente 1234` escolhe o arquipélago do jogo
novo. F7
adianta 3 horas no relógio do dia e F8 dá dinheiro e 20 t de cada bem, os dois só em build de
depuração.

**Godot MCP** (`@coding-solo/godot-mcp`, MIT) está em `.mcp.json` e passa a valer na
próxima sessão do Claude Code aberta nesta pasta. Ele chama o Godot por
`tools/godot-mcp.sh`, que usa o xvfb quando não há tela.

## Arquitetura (seção 12)

A **simulação** roda em ticks fixos sobre dados puros e nunca toca na árvore de cenas; a
**apresentação** só lê o estado e reage a eventos. Um prédio é um registro, não um nó.

| Caminho | O que é |
|---|---|
| `core/tick_clock.gd` | `TickClock` (RefCounted): passo fixo de 5 ticks/s, velocidades 1x/2x/4x, pausa, teto de ticks por quadro, hora do dia (só visual, começa às 7h) |
| `core/day_clock.gd` | `DayClock`: o que sai da hora — quanto é noite (janelas, luzes) e quanta gente na rua |
| `core/game_clock.gd` | autoload `GameClock`: fonte da verdade do tempo; emite `ticked(tick_index)` |
| `core/event_bus.gd` | autoload `EventBus`: sinais tipados; interface e áudio só escutam |
| `core/save_system.gd` | autoload `SaveSystem`: JSON versionado + zstd + miniatura PNG; migrações por versão |
| `core/settings.gd` | autoload `Settings`: idioma e escala da interface em `user://settings.cfg` |
| `data/game_config.gd` + `.tres` | `GameConfig`: toda constante ajustável; `validate()` lista valor inválido |
| `core/input_actions.gd` | atalhos padrão registrados no InputMap (tecla física) |
| `data/game_data.tres` | todas as definições: 23 bens (`goods/`), 2 classes (`tiers/`), 30 prédios (`buildings/`), ilha de teste (`islands/`) |
| `data/*_def.gd` | `GoodDef`, `TierDef`, `NeedCategoryDef`, `BuildingDef`, `IslandProfileDef` |
| `sim/island_grid.gd` | grade da ilha: ocupação (`PackedInt32Array`, id do prédio) e estradas (`PackedByteArray`) |
| `sim/footprint.gd` | retângulo girado (rotação 0 = frente em −Z) e células da face de entrada |
| `sim/placement_rules.gd` | validação; o motivo da recusa é chave de tradução `REASON_*` |
| `sim/commands/` | construir, estrada e demolir: validam tudo antes de mudar o mundo |
| `sim/simulation.gd` | dona do `WorldState`; executa comandos e roda os sistemas na ordem da seção 12 |
| `sim/systems/` | força de trabalho → produção → logística (carroças) → necessidades → população → economia |
| `sim/logistics/` | `Cart` (registro da carroça), `RoadRouter` (AStarGrid2D por ilha), `WarehouseField` (armazém mais próximo) |
| `sim/derived_state.gd` | o que sai da geometria (acesso, cobertura, módulos, poluição) e os totais por tick; refeito na mudança |
| `sim/island_economy.gd` | estoque da ilha e atendimento das necessidades por classe |
| `sim/house_needs.gd` | avaliação de uma casa (necessidades, bônus, imposto), usada pela população e pelo painel |
| `sim/statistics.gd` | t/min produzido, potencial e consumido por bem; população e finanças |
| `sim/road_network.gd`, `road_path.gd` | acesso do prédio à estrada, trechos conectados, traçado em L |
| `world/camera/` | `CameraRig` (contas, testadas) e `StrategyCamera` (entrada e `Camera3D`) |
| `world/flat_island.gd` | ilha plana e mar dos testes e dos saves de antes da Fase 5 |
| `sim/world/archipelago_generator.gd` | arquipélago por semente: relevo em patamares, litoral, rios, floresta e jazidas; as alturas que o terreno desenha |
| `sim/world/site_finder.gd` | lugar mais perto onde um prédio cabe pelo terreno (câmera inicial, testes, capturas) |
| `world/terrain/terrain_view.gd` | adaptador do terreno: malha por trecho no relevo da grade e `shaders/terrain.gdshader` |
| `world/water/water_view.gd` | adaptador da água: Ocean do Boujie com a cópia editada do shader (poluição) |
| `presentation/tree_view.gd` | árvores e pedras em MultiMesh por trecho de 64×64 células |
| `world/sky/sky_adapter.gd` | `SkyAdapter`: a única peça que conhece o Sky3D; recebe a hora do GameClock. Sem o addon, céu simples |
| `presentation/` | caixas dos prédios, estradas em MultiMesh, prévia, grade e camadas F1/F2 |
| `ui/build/build_tool.gd` | ferramenta de construção; a lógica trabalha em células, testável sem mouse |
| `ui/hud/` | barra superior, menu por categoria, painel do selecionado, estatísticas (Tab) |
| `presentation/cart_view.gd` | carroças num MultiMesh, posição interpolada entre ticks |
| `presentation/pedestrians/` | `Crowd` (rotina dos pedestres, sem nós), `PedestrianView` (MultiMesh por classe e corpo), `SidewalkPath`, `VatModel` |
| `presentation/window_lights_view.gd` | janelas nas fachadas (um MultiMesh) e as luzes de área perto da câmera |
| `shaders/pedestrian_vat.gdshader` | boneco animado pela textura VAT, andando sozinho pelo trecho reto |
| `tools/vat/vat_baker.gd`, `tools/bake_pedestrians.gd` | gerador próprio de VAT a partir dos personagens da Quaternius (`assets/source/`) |
| `tools/demo_village.gd` | vila de demonstração com entreposto e armazéns (capturas) |
| `ui/screens/` | abertura (novo jogo, carregar) e a partida (`GameScreen` monta tudo) |
| `tools/town_layout.gd` | vila de teste por comandos (benchmark, testes, captura) |
| `audio/` | vazia até a fase que a usa |
| `addons/` | terceiros, **nunca editados**; para mudar, copie para `shaders/` ou `sim/` |

Regras que já custaram investigação:

- **Save nunca é `.tres`/`.res`**: Resource vindo de arquivo do usuário executa script. O
  save usa `JSON.from_native`/`to_native` sem objetos, que preserva `int`, vetores e
  `StringName` e recusa qualquer `Object`. Ao mudar o formato, some 1 em `SAVE_VERSION` e
  acrescente a migração em `migrations` — o teste confere que os dois andam juntos.
- **Aviso de tipo é erro** (`project.godot`, seção `[debug]`). Variant vindo de JSON ou
  ConfigFile se confere com `is` e se atribui a variável tipada; `int(variant)` e
  `variant as Dictionary` não compilam.
- **O acumulador do relógio conta em ticks e tem folga de 1e-6**: 0,6 s a 5 ticks/s dá
  2,999… em ponto flutuante e precisa virar 3 ticks.
- **Float no save vai como 8 bytes em hexadecimal** (`{"$f64": ...}`): o `JSON.from_native`
  grava só 15 dígitos e o giro da câmera voltava diferente na 15ª casa.
- **A ocupação não é salva**: sai dos prédios ao carregar, e um save com prédios sobrepostos,
  tipo errado ou prédio desconhecido é recusado inteiro (`WorldState.from_dict` devolve null)
  sem mexer na partida em andamento.
- **Prédio pode ser construído sem estrada** (decisão do dono do produto, 12/10/2026): fica
  com "!" laranja e "Sem acesso à estrada" no painel até uma estrada encostar na face de
  entrada. Estrada atrás ou do lado não conta.
- **Câmera própria, sem addon** (decisão do dono do produto, 12/10/2026): o único addon de
  câmera RTS para Godot 4 não tinha zoom no cursor, Q/E de 90° nem limites.

### Economia (Fase 2)

- **Os números que o PDF não traz são propostos por nós** (decisão do dono do produto,
  12/10/2026): custos, manutenção dos serviços, desbloqueios (só a olaria = 150 operários vem
  do PDF), preços, raio dos módulos (5 células), ritmo de chegada de moradores, felicidade e
  níveis de imposto. **Nunca dados dos jogos Anno.** Ajuste nos `.tres`, conferindo pela
  planilha (`tools/godot.sh planilha`).
- **Terreno até a Fase 5** (decisão do dono do produto, 12/10/2026): árvores, jazida e margem
  de rio valem como presentes; o litoral é a borda da ilha (cabana de pesca); a ilha de teste
  é fértil para batata, trigo e lúpulo.
- **A produção vai e vem do estoque pela carroça** (Fase 3). O `DirectTransferSystem` (o
  transporte instantâneo da Fase 2) ficou só para testes e ferramentas.
- **Fazenda sem todos os campos/pastos no raio fica parada** ("faltam campos ou pastos"); cada
  módulo serve a uma fazenda só.
- **Ponto flutuante de novo**: o fim do ciclo tem folga de 1e-6 (75 ticks de 0,2/15 somam
  0,99999… e o ciclo atrasava um tick por volta).
- **Estado e estatística "atuais" usam médias**, não o instante: entre um ciclo e outro o
  prédio passa um tick "sem entrada" sem perder tempo. A etiqueta de parado só aparece com a
  produtividade média abaixo de 90%.
- **Casas em 10 grupos alternados** (`house_update_groups`): cada casa é avaliada a cada 2 s
  com o tempo de 10 ticks. As somas por grupo e o imposto de cada casa (salvo no save) mantêm
  o carregar determinístico: depois de carregar, a simulação segue idêntica à original (há
  teste disso).
- **Aviso de falta só para bem de necessidade básica**; luxo não é exigido.

### Logística (Fase 3)

- **Entreposto primeiro**: sem ele na ilha só ele pode ser construído (nem estrada). O
  primeiro do jogo é gratuito; as 40 tábuas iniciais são a carga do navio.
- **Carroça por prédio de produção**, 2 t: sai com a saída (≥ 1 t) e, na mesma viagem, traz a
  entrada que o estoque tem. A carga só entra no estoque ao descarregar na rampa (2 s/t).
  Estoque cheio: descarrega o que cabe e volta com o resto.
- **Alcance de 40 células de estrada** até um armazém ligado (mesma rede de estrada que um
  entreposto). Fora disso o prédio para com "sem acesso a armazém".
- **Rotas**: o `WarehouseField` (busca em largura saindo de todos os armazéns) diz o armazém
  mais próximo e a distância; o AStarGrid2D (`RoadRouter`) dá o caminho da carroça. Rodar o A*
  por par prédio × armazém custaria segundos a cada estrada nova.
- **Estrada cortada**: a carroça refaz a rota de onde está; sem caminho, espera parada
  (`blocked`) até a rede mudar de novo.
- **`GameConfig.instant_logistics`** é só para testes e ferramentas: volta ao transporte
  instantâneo da Fase 2 (sem carroça e sem entreposto). Os testes da economia usam; os de
  logística (`SimFixture.simulation(..., true)`) não. O jogo nunca usa.
- **Busca em largura por índice da grade** (sem `Vector2i`) nas buscas que rodam sobre a ilha
  inteira a cada estrada nova; com coordenadas, construir com a ilha cheia passava de 50 ms.
- Saves da Fase 2 abrem: ganham as carroças e esperam o entreposto (decisão do dono do
  produto, 12/10/2026).
- Nenhum número de regra no código: vai para `GameConfig` ou para os Resources de
  `data/`.

### Vida e tempo (Fase 4)

- **A hora sai dos ticks da partida**: `TickClock.hour()` = início (`day_start_hour`, 7h) + segundos
  de jogo, liso entre ticks. A `GameScreen` iguala o relógio ao `world.tick` no jogo novo e ao
  carregar (saves antigos tinham o relógio adiantado pela tela de abertura). F7 (só em build de
  depuração) soma 3 horas só na vista (`extra_hours`, salvo junto do relógio).
- **Céu: Sky3D 2.1.0**, atrás do `SkyAdapter`, carregado pelo caminho e usado só por `set`/`get`/
  `call`. O relógio próprio dele fica desligado; a hora só é repassada quando anda 15 s de jogo
  (cada repasse refaz as contas do sol e da lua em GDScript). Lua sem sombra (duas sombras
  direcionais custam caro). **Latitude 45° e 14/04/1840, dia de lua cheia** (escolhido no
  próprio Sky3D): sem lua, a noite era um breu. O nascer e o pôr do sol do `GameConfig` (5h25 e
  18h40) têm teste contra o sol do Sky3D: mudou a data, refaça os dois.
- **Pedestres são só visuais e não vão para o save** (a `Crowd` refaz tudo ao carregar). Um para
  cada 5 moradores, teto de 2.000; rotina casa → trabalho → serviço → casa pela calçada
  (`SidewalkPath`, deslocada para a direita de quem anda). Sem trabalho da classe, vão a qualquer
  prédio de trabalho da rede; sem serviço que atenda a casa, ao mais perto.
- **O pedestre anda na placa de vídeo**: a instância guarda o começo do trecho reto, o
  comprimento, a velocidade e a animação; o shader calcula a posição com o tempo visual
  (`visual_time`, que para na pausa). A CPU só mexe no pedestre que troca de trecho — eventos num
  calendário de baldes de 0,25 s. Evento marcado para o balde em leitura é lido de novo; evento
  que ainda não venceu vai para o quadro seguinte (os dois já custaram um teste travado).
- **Mudança de instância é por lista**, não por buffer: escrever num `PackedFloat32Array` guardado
  em outro objeto copia o array inteiro a cada escrita (copy-on-write).
- **VAT gerado aqui, sem Blender e sem OpenVAT** (GPL): `tools/bake_pedestrians.gd` reduz o
  personagem com o gerador de LOD do Godot (~12.600 → ~1.600 triângulos), calcula cada quadro
  (skinning na CPU) e grava em `.res` (posição RGBAH exata, sem mipmap). O boneco é virado para
  −Z pela direção em que o pé apoiado anda; o passo (m por ciclo) também sai dos pés.
- **Roupa por região do corpo** (UV.x): pele, cabelo, roupa de cima (cor sorteada da paleta da
  classe em `TierDef.clothing_colors`), calça e sapato. A cor da instância chega ao shader em
  sRGB e é convertida lá.
- **Janelas** em todas as fachadas, num MultiMesh só, acesas pela noite (`night_light`) se o
  prédio está aceso; o térreo da frente desvia da porta de verdade (em prédio de largura par ela
  fica meia célula fora do meio). `AreaLight3D` ilumina para −Z.
- **O reflexo do céu é incremental** (`Sky.PROCESS_MODE_INCREMENTAL`, cubo de 128): o céu muda com
  a hora, e refazer o reflexo inteiro a cada mudança custava ~150 ms por quadro no xvfb (na
  placa de vídeo também pesa, só que menos).
- **Testes de interface usam o céu simples** (`GameScreen.use_sky3d = false`): o Sky3D por
  software leva segundos por quadro e a suíte passava de 5 minutos. O Sky3D na partida tem o
  teste dele (`tests/ui/test_sky_in_game.gd`).

### Mundo (Fase 5)

- **Arquipélago por semente** (`ArchipelagoGenerator`, simulação pura): a principal (250×250
  células) na região (0, 0) e 4 menores (150, 150, 80, 80) em regiões vizinhas sorteadas, uma
  ilha por região de 512 m. Relevo = ruído + máscara de quadrado arredondado, em **patamares
  planos** (`terrace_levels_m`: é neles que se constrói) com encostas entre eles; litoral de praia
  (planície a 1,2 m) ou de falésia; **rios** são braços de mar que entram pela planície (nível do
  mar, sem água própria), e só os cantos de dentro afundam: a margem fica plana para a olaria;
  floresta pelo ruído até cobrir `forest_coverage` da terra; jazidas em manchas planas de 6×6,
  de preferência nos morros. Perfis em `data/islands/*.tres`.
- **O save guarda a semente** (`terrain_version` = versão do gerador; 0 = ilha plana antiga) e as
  árvores que a construção derrubou; o terreno é refeito ao carregar e conferido por uma
  assinatura (diferença só avisa: `terrain_mismatch`). Mudou o gerador, some 1 em `VERSION`.
- **A ilha plana continua** (`IslandGrid.flat`): testes, `SimFixture`, saves das Fases 1 a 4
  (migração 3 → 4) e os testes de interface (`GameScreen.flat_world = true`, coordenadas
  conhecidas). Nela árvores, jazidas e rios valem como presentes e o litoral é a borda.
- **Regras** (`PlacementRules.check_terrain`): área em terra, plana até
  `max_build_height_delta_m`; litoral = encostar no mar; olaria = rio ou mar; mina = a área toda
  sobre a jazida do bem dela (`BuildingDef.deposit`); estrada fora do mar e sem barranco
  (`max_road_relief_m`), ponte sobre o rio. Construir derruba as árvores (`trees_changed`);
  lenhador com menos de `lumberjack_min_trees` no raio para (`NO_TREES`, no fim do enum: o
  número vai no save). `Simulation.ignore_terrain` é só do benchmark.
- **Terreno próprio no lugar do Terrain3D**: o 1.0.2 derruba o Godot 4.7.2 assim que recebe um
  relevo de verdade (condição de corrida no material, issue #945 do Terrain3D; corrigida só na
  versão noturna; com região de 256 vértices cai até com o terreno plano). `TerrainView`
  desenha uma malha por trecho de 64 cantos e o shader escolhe grama/rocha pela inclinação,
  areia na praia e chão de floresta por uma textura de 2 em 2 m. Voltar ao Terrain3D mexe só
  ali, quando sair versão estável compatível com o 4.7.
- **Tudo assenta no relevo**: a grade tem `origin_m` e altura por canto; prédio na altura média
  da área (a caixa desce 0,6 m), estrada inclinada como o plano dos cantos (cisalhamento),
  carroça e pedestre na altura da estrada, a grade de construção é uma malha no relevo da ilha
  da ferramenta, a câmera mira a altura do chão e o clique anda pelo raio até tocar o terreno.
- **Água**: Ocean do Boujie (malha em anéis que segue a câmera) com a cópia editada do shader;
  ondas de porto, baixas; a poluição é um mapa do arquipélago (4 m por pixel) refeito quando um
  prédio poluidor entra ou sai. A cor da água sai da profundidade até o fundo, e fora das regiões
  não há fundo: o fundo **desenhado** desce da costa até `deep_sea_floor_m` e já chega lá na borda
  da região (sem isso, cada região aparecia como um quadrado de água clara). A simulação continua
  com `sea_floor_m`. A leitura da tela desviada pela refração é presa dentro dela (repetia a
  profundidade do outro lado e manchava a borda de baixo).
- **Árvores**: MultiMesh por trecho de 64×64 células e por modelo; no máximo 2 desenhadas por
  célula (a regra conta todas); derrubar refaz só o trecho. As cores do Kenney (turquesa) são
  trocadas no código. Array empacotado dentro de outro array pode ser alterado numa cópia: os
  buffers são montados em variável local.
- **Destaque de terreno** (jazida, floresta, litoral, rio) ao escolher o prédio: percorre a ilha
  inteira, então fica em cache por ilha e prédio até árvores caírem.

## Assets e licenças (seção 14)

Todo asset ou addon novo entra em `CREDITS.md` (autor, link, licença, arquivos). O que
faltar vira placeholder e entra em `assets/TODO_ASSETS.md`. Addon só na fase que o usa,
atrás de um script adaptador próprio, depois de confirmar a versão compatível com o 4.7.

## Fases (seção 16)

| Fase | Estado |
|---|---|
| 0 — Fundação | **concluída em 12/10/2026**, exceto o CI (sem repositório remoto) |
| 1 — Protótipo cinza | **concluída em 12/10/2026** |
| 2 — Núcleo econômico | **concluída em 12/10/2026** |
| 3 — Logística | **concluída em 12/10/2026** |
| 4 — Vida e tempo | **concluída em 12/10/2026** (a medição de FPS na RTX 3060 ainda não voltou) |
| 5 — Mundo | **entregue em 12/10/2026**, aguardando a confirmação do dono do produto |
| 6 a 11 | — |

Pendências já vistas para fases futuras:

- Fase 6: o navio de verdade traz a carga inicial; hoje as 40 tábuas já estão no estoque.
- Fase 7: gráficos históricos nas estatísticas e o Theme (os painéis usam `UiStyle` provisório).
