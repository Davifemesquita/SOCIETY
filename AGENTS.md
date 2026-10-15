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
tools/godot.sh testes              # suíte gdUnit4 no xvfb (res://tests), ~15 a 25 min nesta VM
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
# Fase 6: navio inicial, cais da colônia, navegando, posto do comerciante, painel do navio, rotas
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 12000 res://tools/capture_phase6.tscn -- /pasta/de/saida
# Fase 7: menu principal, jogo novo, partida de 30 min, painéis, estatísticas, camadas, menus,
# opções, salvar, créditos, inglês, rotas com o mapa ilustrado e comércio
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase7.tscn -- /pasta/de/saida
# Fase 8: a partida roteirizada até os investidores — rua das casas, painel do investidor, metas e
# conselheiro, abas de produção das classes novas, paralelepípedo, mover casa, conselheiro em inglês
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase8.tscn -- /pasta/de/saida
# Fase 9: vila de longe e de perto (miniatura), hora dourada, chuva, neblina, fumaça, andaime, os
# quatro níveis e o navio com rastro e gaivotas; CAPTURA_NIVEL=0..3 escolhe o nível e
# CAPTURA_SO=rapido tira só as duas primeiras (o nível alto por software leva ~30 s por captura)
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 200000 res://tools/capture_phase9.tscn -- /pasta/de/saida
# Fase 10: tutorial apontando o entreposto, aba Jogo das opções e o salvamento automático
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase10.tscn -- /pasta/de/saida
# Fase 11: ilhas tropicais da semente 1840, palmeiras, mina de ouro, canavial, mapa das rotas e a
# janela de encomendas com os eventos e os avisos
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase11.tscn -- /pasta/de/saida
# Fase 10: o jogador-robô joga 3 h e grava a linha do tempo do balanceamento
tools/godot.sh godot --headless --path . res://tools/balance_report.tscn -- "$PWD/docs/balanceamento.md"
# ícone do jogo (PNGs e o .ico do Windows)
tools/godot.sh godot --headless --path . --script res://tools/build_app_icon.gd && python3 tools/build_app_icon.py
# texturas dos prédios e estradas (Poly Haven, CC0) a partir da pasta baixada
tools/godot.sh godot --headless --path . --script res://tools/pack_material_textures.gd -- /pasta/baixada
# interface: refaz o atlas de ícones e os retratos (depois de mexer em tools/icons/icon_list.csv;
# os SVGs se baixam com tools/icons/fetch_icons.sh) e o Theme (depois de mexer no ThemeBuilder)
tools/godot.sh godot --headless --path . --script res://tools/build_icons.gd
tools/godot.sh godot --headless --path . --script res://tools/build_theme.gd
# compila todos os scripts e lista os com erro (mais rápido que a suíte para pegar erro de tipo)
tools/godot.sh godot --headless --path . --script res://tools/check_scripts.gd
# refaz os pedestres (VAT) a partir de assets/source/quaternius; com a pasta dos pacotes
# baixados (UAL1_Standard.glb, UAL2_Standard.glb) como argumento, refaz antes as animações
tools/godot.sh godot --headless --path . --script res://tools/bake_pedestrians.gd
# benchmark da fase, anexado ao registro
tools/godot.sh godot --path . --resolution 1920x1080 res://tools/benchmark.tscn -- "$PWD/docs/benchmark.md"
```

A suíte roda no **nível gráfico baixo** (`SOCIETY_NIVEL_GRAFICO=0`, posto pelo `tools/godot.sh
testes`): no alto, SSIL e neblina volumétrica por software deixavam a suíte três vezes mais lenta. A
mesma variável troca o nível em qualquer execução, sem gravar nas preferências.

**A VM tem 3 GB de RAM** divididos com outras sessões: um Godot que sobra de uma suíte interrompida
(processo `... -s -d --remote-debug tcp://127.0.0.1:0`) segura ~900 MB e o próximo cai por falta de
memória (código 137) ou fica lento pelo swap. Confira com `pgrep -fa godot` antes de rodar a suíte.

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

O jogo abre no **menu principal** (continuar, jogo novo, carregar, opções, créditos, sair). No
executável: `Society.exe -- --novo-jogo` abre direto uma partida, `-- --carregar` abre o
save rápido e `-- --benchmark` roda o benchmark e mostra o resultado na tela (é assim que se
mede no PC alvo; desde a Fase 4 inclui um dia inteiro renderizado com 2.000 pedestres, e desde
a Fase 5 é no arquipélago da semente 1840). `-- --semente 1234` escolhe o arquipélago do jogo
novo. F1/F2 (camadas de depuração), F7 (adianta 3 horas no relógio do dia) e F8 (dinheiro e
20 t de cada bem) só funcionam em build de depuração.

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
| `core/settings.gd` | autoload `Settings`: gráficos, áudio (5 barramentos), teclas, idioma, escala e daltonismo em `user://settings.cfg` |
| `data/game_config.gd` + `.tres` | `GameConfig`: toda constante ajustável; `validate()` lista valor inválido |
| `core/input_actions.gd` | atalhos padrão no InputMap (tecla física), os remapeáveis e o nome da tecla no teclado do jogador |
| `data/game_data.tres` | todas as definições: 41 bens (`goods/`), 5 classes (`tiers/`), 53 prédios (`buildings/`), perfis de ilha (`islands/`, temperados e tropicais), 2 navios (`ships/`), o comerciante (`traders/`), 14 metas guiadas (`goals/`), 7 eventos (`events/`) e 12 encomendas (`missions/`) |
| `data/*_def.gd` | `GoodDef`, `TierDef`, `NeedCategoryDef`, `BuildingDef`, `IslandProfileDef`, `ShipDef`, `TraderDef`, `GoalDef` |
| `sim/island_grid.gd` | grade da ilha: ocupação (`PackedInt32Array`, id do prédio) e estradas (`PackedByteArray`) |
| `sim/footprint.gd` | retângulo girado (rotação 0 = frente em −Z) e células da face de entrada |
| `sim/placement_rules.gd` | validação; o motivo da recusa é chave de tradução `REASON_*` |
| `sim/commands/` | construir, estrada (terra ou paralelepípedo), demolir e mover: validam tudo antes de mudar o mundo |
| `sim/simulation.gd` | dona do `WorldState`; executa comandos e roda os sistemas na ordem da seção 12 |
| `sim/systems/` | força de trabalho → produção → logística (carroças) → necessidades → população → marcos → metas → economia → navios → eventos → encomendas |
| `data/event_def.gd`, `data/mission_def.gd` | `EventDef` (efeito, grupo, multiplicador, duração, peso, marco) e `MissionDef` (bem, toneladas, prazo, prêmio, peso, marco) |
| `sim/events/` | `EventsState` (no save: ligado ou não, eventos, encomendas, os contadores dos sorteios), `WorldEvent`, `Mission` e `EventEffects` (os multiplicadores que os sistemas leem) |
| `sim/logistics/` | `Cart` (registro da carroça), `RoadRouter` (AStarGrid2D por ilha), `WarehouseField` (armazém mais próximo) |
| `sim/ships/` | `SeaChart` (carta náutica, AStarGrid2D no mar), `Ship`, `TradeRoute`, `Harbors` (cais, ancoradouros, posto do comerciante), `CargoTransfer`, `TraderState`/`TraderVisits`, `ShipRules` |
| `sim/derived_state.gd` | o que sai da geometria (acesso, cobertura, módulos, poluição) e os totais por tick; refeito na mudança |
| `sim/island_economy.gd` | estoque da ilha e atendimento das necessidades por classe |
| `sim/house_needs.gd` | avaliação de uma casa (necessidades, bônus, imposto), usada pela população e pelo painel |
| `sim/statistics.gd` | t/min produzido, potencial e consumido por bem; população e finanças |
| `sim/statistics_history.gd`, `sim/systems/statistics_system.gd` | histórico dos gráficos: uma amostra por minuto de jogo (vai no save) |
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
| `ui/hud/` | barra superior, menu por categoria com as camadas, painel do selecionado, estatísticas (Tab) com gráficos (`line_chart.gd`), notificações (`notification_feed.gd` + `notice_watcher.gd`), calculadora de proporção |
| `ui/theme/` | `ThemeBuilder` (o Theme único, gravado em `society_theme.tres`) e `UiPalette` (cores e semáforo com o modo daltônico) |
| `ui/icons/` | `Icons`: atlas `icons.png` + índice `icons.json`, nomes padronizados; `ui/portraits/` tem os retratos placeholder |
| `ui/ui_kit.gd` | botão com ícone e dica, rótulo por variação, cabeçalho de janela |
| `presentation/map_overlays.gd` | camadas do jogador: raio de serviço, alcance de armazém, fertilidade, poluição e estradas |
| `presentation/cart_view.gd` | carroças num MultiMesh, posição interpolada entre ticks |
| `presentation/ship_view.gd` | navios provisórios balançando no mar, o posto do comerciante e a marca do selecionado; acha o navio sob o cursor |
| `ui/build/ship_picker.gd` | clique no navio (seleciona) e no mar (destino de "navegar para"); recebe a entrada antes da `BuildTool` |
| `ui/hud/ship_panel.gd`, `route_window.gd`, `archipelago_map.gd`, `trade_window.gd` | painel do navio, janela de rotas com o mapa, comércio passivo da ilha |
| `ui/hud/goal_panel.gd` | meta da vez com o progresso e a fala do conselheiro (retrato, texto, continuar) |
| `ui/hud/mission_window.gd` | encomendas (aceitar, recusar, entregue e prazo) e os eventos em andamento; os selos dos eventos ficam na barra (`Hud`) |
| `data/graphics/*.tres`, `data/graphics_preset_def.gd` | níveis gráficos baixo, médio, alto e ultra (Fase 9) |
| `world/graphics_quality.gd` | aplica o nível ao ambiente, ao sol, à câmera (miniatura), aos pedestres, às luzes de área e aos efeitos |
| `world/sky/clouds_adapter.gd` | adaptador do SunshineClouds2 (nuvens volumétricas) |
| `presentation/weather_cycle.gd`, `weather_view.gd` | clima só visual: sorteio por dia pela semente, chuva, neblina, chão molhado |
| `presentation/smoke_view.gd` | chaminés com fumaça e vapor enquanto produzem, fuligem no chão |
| `presentation/building_materials.gd`, `shaders/building.gdshader` | material PBR dividido dos prédios (paredes e telhados) |
| `ui/advisor/` | `advisor.dialogue` (as falas, em chaves de tradução) e `AdvisorDialogue`, o adaptador do Dialogue Manager |
| `tools/progression_demo.gd` | partida roteirizada do camponês ao investidor (critério da Fase 8, captura) |
| `presentation/pedestrians/` | `Crowd` (rotina dos pedestres, sem nós), `PedestrianView` (MultiMesh por classe e corpo), `SidewalkPath`, `VatModel` |
| `presentation/window_lights_view.gd` | janelas nas fachadas (um MultiMesh) e as luzes de área perto da câmera |
| `shaders/pedestrian_vat.gdshader` | boneco animado pela textura VAT, andando sozinho pelo trecho reto |
| `tools/vat/vat_baker.gd`, `tools/bake_pedestrians.gd` | gerador próprio de VAT a partir dos personagens da Quaternius (`assets/source/`) |
| `tools/demo_village.gd` | vila de demonstração com entreposto e armazéns (capturas) |
| `ui/screens/` | menu principal (`boot_screen`), `Modal`, jogo novo, salvar/carregar, opções, créditos, menu da partida e a partida (`GameScreen` monta tudo) |
| `tools/town_layout.gd` | vila de teste por comandos (benchmark, testes, captura) |
| `tools/trade_demo.gd` | duas ilhas com a rota de tijolos (critério da Fase 6, captura, benchmark) |
| `audio/` | `AudioMix` (contas do clima da música e do volume das zonas), `MusicDirector` (música adaptativa), `AmbiencePlayer` (ambiente por zona, vento e chuva gerados) e `SoundEffects` (efeitos, cliques e fábricas com som posicional) |
| `ui/screens/autosave.gd` | salvamento automático em slots que se revezam |
| `tools/auto_player.gd` | jogador-robô que joga de verdade (balanceamento e critério das 3 horas) |
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

### Navios e comércio (Fase 6)

- **Carta náutica** (`SeaChart`): grade de 8 m (`sea_chart_cell_m`) sobre o arquipélago e 200 m de
  mar em volta; célula navegável se todos os cantos do terreno nela ficam abaixo de
  `ship_min_depth_m` (−1,5 m). Rio (−1,2 m) é raso demais; a ilha plana é toda terra. Feita uma vez
  por mundo, fora do save; o caminho é AStarGrid2D com diagonal, encurtado por linha de visada e
  guardado por par de células.
- **Busca com distância infinita**: `ceili(INF)` não é número; `nearest_navigable` sem limite usa o
  tamanho da carta (o bug parava todo navio sem caminho, em silêncio).
- **Portos** (`Harbors`, fora do save, refeito com o `DerivedState`): cada entreposto é uma vaga, e
  cada píer ligado por estrada à rede de um entreposto é mais uma. O cais é a água navegável mais
  perto do prédio (até `berth_search_m`); o ancoradouro, onde se espera vaga, fica mais para o mar.
  Ilha sem porto: o navio ancora no mar mais perto do meio da borda norte (é onde se coloniza).
- **Caminho no mar em outra thread**: o caminho novo entre portos distantes passa de 20 ms na
  semente 1840 (com ou sem o salto do AStarGrid2D). O navio iça velas por `ship_cast_off_seconds`
  enquanto o `WorkerThreadPool` calcula (`SeaChart.request`), e ao fim desse tempo recolhe o
  caminho, esperando a tarefa se ela ainda não acabou: sai sempre no mesmo tick, e a partida
  carregada segue igual à original (o cache não vai para o save). O A* só é usado pelas tarefas,
  com mutex; toda tarefa é esperada (`_reap`, `finish` ao trocar de mundo).
- **Rota**: paradas (ilha ou posto do comerciante) com ordens de carregar e descarregar até X t;
  primeiro desce tudo, depois sobe. O navio espera na fila do porto (ordem de chegada), encosta,
  fica `ship_seconds_per_ton` por tonelada planejada e só então a carga passa. Parada em ilha sem
  porto é pulada. Mudou a rota, os navios dela recomeçam da primeira parada.
- **Navio inicial** (`starting_ship`) traz as 40 tábuas e fica ancorado na principal; o primeiro
  entreposto continua grátis e o navio descarrega nele. Sem navio inicial (testes da economia,
  `SimFixture`), a carga vai direto para o estoque, como antes.
- **Colonização**: entreposto em ilha nova pede o marco que libera a ilha (`islands_by_milestone`),
  um navio do jogador ancorado nela com os materiais (saem do porão) e o dinheiro; o resto do
  porão desce no estoque novo.
- **Marcos** (`population_milestones`): atingido, fica para sempre e libera navios
  (`ships_by_milestone`) e ilhas. O jogo começa com 1 navio e 1 ilha; a segunda libera aos 100.
- **Comerciante neutro**: o navio dele (sem manutenção) aparece com o primeiro entreposto, espera
  `visit_interval_s` no posto (o canto da carta mais longe da principal), sorteia os preços da volta
  (base ± `trader_price_variation`, pela semente e pelo número da volta: o save guarda só o número)
  e passa por cada entreposto, negociando até `max_tons_per_visit` por bem pelos ajustes da ilha
  ("vender acima de", "comprar até"). No posto, o jogador compra e vende com o navio dele; o posto
  também pode ser parada de rota.
- **Save versão 5**: navios, rotas, comerciante, marcos e os ajustes de comércio; a ilha plana
  guarda `origin` (pode haver mais de uma). Saves da Fase 5 abrem sem navios e com o estoque que
  tinham.
- **Painéis que se refazem**: o filho antigo sai da árvore antes do `queue_free`; senão o novo de
  mesmo nome ganha nome gerado e `find_child` não acha (os testes de interface procuram por nome).
- **Testes de interface com clique**: o mouse começa no canto e a câmera anda sozinha (pan pela
  borda); mova o mouse para o meio antes de calcular onde clicar.

### Interface (Fase 7)

- **Um Theme só** (`ui/theme/society_theme.tres`, em `gui/theme/custom`), montado pelo
  `ThemeBuilder` e gravado por `tools/build_theme.gd`: mudou o builder, rode a ferramenta (o teste
  compara o gravado com o montado). Variações: `TitleLabel`, `HeaderLabel`, `DimLabel`,
  `BigLabel`, `TopBar`, `MenuPanel`, `NoticePanel`, `ToastPanel`, `IconButton`, `MenuButtonLarge`,
  `CardButton`, `NoticeButton`. Nada de `add_theme_stylebox_override` nos painéis (o `UiStyle`
  provisório saiu). Os desenhos pequenos (caixa de marcar, seta, alça) são feitos no builder: os do
  Godot são para fundo escuro e somem no papel.
- **Cor de estado no papel**: `UiPalette.paint(label, status)`, nunca `modulate` (escurece a tinta).
  O modo daltônico troca a paleta e o indicador também tem forma (círculo, triângulo, xis).
- **Ícones** (`Icons.get_icon("<tipo>_<id>")`): atlas de 128 px gerado de SVGs do game-icons.net
  (`tools/icons/icon_list.csv`); ícone que falta vira a interrogação e avisa no log. **Todo botão leva
  ícone e dica** (`UiKit.button`/`icon_button`); o teste do critério anda pela interface inteira e
  falha com botão sem ícone, chave sem tradução ou formato (`%s`) sobrando. `Sprite3D` desenha o
  atlas inteiro de uma `AtlasTexture`: use `region_rect`.
- **Textos**: chave de tradução sempre; a dica de botão é `<CHAVE>_TIP`; as teclas são
  `ACTION_<AÇÃO>`; o teste varre o código atrás de chave que não está no CSV.
- **Notificações**: falta, marco, colônia e comerciante vêm do EventBus; prédio parado (depois de
  `stopped_notice_after_s`), estoque cheio (`storage_full_fraction`, volta a avisar abaixo de
  `storage_full_reset_fraction`) e navio que chegou saem da comparação com a conferência anterior
  (`NoticeWatcher`, puro e testado). Ao trocar de mundo, o estado atual vira referência (nada de
  aviso em massa ao carregar). O clique seleciona e leva a câmera.
- **Janelas de menu** (`Modal`): o Esc é lido em `_input`, antes dos atalhos; com janela aberta os
  atalhos da partida não respondem. Na partida o Esc fecha a janela de cima, depois cancela a
  ferramenta ou a seleção, e só então abre o menu (que pausa e volta à velocidade de antes).
- **Lambda ligada a sinal do EventBus** que mexe em nó de janela temporária: use método do nó (a
  ligação some com ele); a lambda do diálogo de opções ficou viva e quebrou o teste seguinte.
- **Save versão 6**: dificuldade (fácil/normal/difícil multiplica o dinheiro inicial e o limite do
  saldo negativo) e o histórico das estatísticas. O tamanho do arquipélago (4, 6 ou 8 ilhas
  menores) não vai à parte: é o número de ilhas do save, e a ilha N sai igual em qualquer tamanho
  da mesma semente. Saves da Fase 6 abrem em dificuldade normal e com o gráfico vazio.
- **Salvar com nome**: o slot sai do nome digitado (`SaveSystem.slot_from_name`: minúsculas sem
  acento) e o resumo (nome, dia, população, dinheiro) vai num `<slot>.info.json` ao lado, para
  listar sem abrir cada save. Nome repetido grava por cima.
- **Créditos** saem do `CREDITS.md`, que entra na exportação (`include_filter`).
- **Dialogue Manager** (seção 13 o põe na Fase 7) entrou na Fase 8, com as metas guiadas.

### Conteúdo (Fase 8)

- **Classes 3 a 5** (artesãos, engenheiros, investidores) com a tabela da seção 4; as necessidades
  e as cadeias são propostas nossas sobre as sugestões do PDF (números nos `.tres`, proporções em
  `tests/data/test_game_data.gd`). Cadeias novas: areal → vidraria → janelaria, conservas (peixe +
  aço), máquinas de costura (aço + tábuas), lâmpadas (vidro + carvão), relojoaria (vidro + aço),
  ótica, vinhedo → adega de champanhe, destilaria de rum, torrefação, charutaria e ourivesaria;
  serviços novos: teatro e universidade.
- **Importados** (decisão tomada aqui, a especificação deixa o clima temperado e põe a segunda
  região climática na Fase 11): cana-de-açúcar, café em grão, tabaco e ouro vêm só do comerciante
  (ele vende), e as fábricas daqui os processam. O ouro não virou jazida porque jazida nova muda o
  gerador do arquipélago e recusa os saves. **Nenhuma necessidade básica de quem ainda sobe de
  classe depende de importado** (há teste): os importados ficam no luxo e nos investidores. Desde a
  Fase 11 os quatro também crescem nas ilhas tropicais (a jazida de ouro saiu num perfil novo, sem
  mexer no gerador das temperadas).
- **Uva** é fertilidade nova (farmland, reef e a ilha de teste); fertilidade não mexe no gerador.
- **Paralelepípedo** (`IslandGrid.Road.PAVED`): moedas e tijolos por célula, libera com 150
  operários (`paved_road_*` no `GameConfig`), calça por cima da terra cobrando só o calçamento;
  carroça +50% na célula calçada. No A*, **a terra pesa 1,5 e o calçado 1** (não o contrário): com
  o calçado abaixo de 1 a heurística de Manhattan passa do custo real e o A* devolve o caminho de
  terra. Ilha só de terra fica com peso 1 em tudo (busca curta).
- **Mover prédio** (`MoveBuildingCommand`): sem custo, mesmas regras de lugar e terreno, a área
  antiga não atrapalha a conferência; o prédio leva moradores, buffers, nível e pausa; a carroça
  volta para casa na hora (a entrada a bordo entra no buffer, a saída segue na próxima viagem).
  Píer ou entreposto com navio encostado não sai do lugar. A vista recebe saída + entrada do mesmo
  id.
- **Metas guiadas** (`data/goals/`, `GoalSystem`): uma por vez, conferida a cada segundo de jogo,
  com prêmio em moedas; a ligada a marco (`after_milestone`) só conta depois dele. Título
  `GOAL_<ID>`; o conselheiro fala os blocos `<id>` e `<id>_done` do `advisor.dialogue`, cada fala
  uma chave do `strings.csv` (o Dialogue Manager traduz pela chave ao entregar a fala). Partida nova: o
  conselheiro apresenta a primeira meta; carregada, só o painel.
- **Dialogue Manager 4.1.0** só pelo `AdvisorDialogue` (get_node/call); sem o addon o conselheiro
  fica calado. O plugin precisa estar ligado no `project.godot` para o editor importar o
  `.dialogue` (`tools/godot.sh importar`).
- **Save versão 7**: estradas calçadas (`paved`, subconjunto de `roads`) e as metas (`goals_done`).
  Saves da Fase 7 abrem com tudo de terra e as metas do começo; na primeira conferência as já
  cumpridas passam **sem prêmio e sem aviso** (`goals_catch_up`).
- **Casas**: três modelos placeholder por classe e um tom da cor, sorteados pelo id (o mesmo depois
  de carregar); o telhado fica acima da altura da classe, então as janelas não mudam.
- **Desempenho**: com cinco classes as necessidades passaram de 0,35 a ~1 ms por tick na carga do
  benchmark (cinco ilhas com entreposto). Ilha **sem casa** agora pula as necessidades
  (`DerivedState.islands_with_houses`) e a lista básicas + luxo é feita uma vez por classe
  (`TierDef.all_needs()`): voltou a ~0,2 ms. A amostra do histórico das estatísticas (Fase 7, a
  cada 60 s) percorria os prédios uma vez por ilha e dava um tick de ~10 ms; agora é uma passada.
  A fala do conselheiro ao cumprir meta começa depois do tick (`call_deferred`).
- **Partida roteirizada** (`ProgressionDemo`): ilha plana de 250×250, transporte instantâneo, sem
  custo; o "jogador" trava o upgrade das primeiras casas de cada classe até a mão de obra que as
  fábricas pedem (+15%) e solta o resto. Chega aos investidores em ~50 min de jogo (o teste dá 2 h).
  Scripts que usam `EventBus` não rodam por `--script`: o autoload não existe na compilação; use
  uma cena (as capturas fazem assim).

### Gráficos finais (Fase 9)

- **Níveis gráficos** em `data/graphics/` (`GraphicsPresetDef`), lidos pelo `GameConfig.graphics_presets`:
  sombra, SSAO, SSIL, glow, neblina volumétrica, nuvens, miniatura, partículas, fuligem, LOD, alcance
  dos detalhes, pedestres, luzes de área, MSAA e a escala FSR sugerida. O padrão é o **alto** (o do
  critério). `Settings.apply()` faz a janela (MSAA, LOD, atlas e filtro de sombra); o
  `GraphicsQuality` faz o resto e repassa `set_quality(preset)` a quem se registrou com `add_effect`.
- **Nuvens volumétricas (SunshineClouds2) só no ultra**: no Vulkan por software o efeito escurece a
  tela inteira fora das nuvens (cena mínima confirmou), e não há como saber aqui se é limitação do
  llvmpipe ou do addon. O adaptador não liga no llvmpipe. **Conferir na RTX 3060** antes de pôr no
  alto (`assets/TODO_ASSETS.md`). O recurso é a cópia `world/sky/clouds.tres` (o do addon aponta
  para uma máscara na raiz do projeto dele). O alto tem as nuvens do Sky3D.
- **Clima** (`WeatherCycle`): só visual, fora do save, sorteado por dia pela semente; chuva numa
  janela do dia, neblina de manhã, chão molhado que seca em `weather_dry_hours`. O chão molhado é o
  uniforme global `wetness` (`shaders/wet_surface.gdshaderinc`), usado pelos shaders de prédio,
  estrada, terreno e árvore. A chuva é um GPUParticles3D em volta do ponto que a câmera olha.
- **Materiais PBR**: um ShaderMaterial para todas as paredes e um para os telhados (texturas em
  Texture2DArray, projeção triplanar porque a caixa não tem UV); camada, tom, base e fuligem vão em
  `instance uniform`. A camada sai de `BuildingDef.wall_material` e de `TierDef.wall_material` /
  `roof_material`. Campo e pasto continuam com cor lisa.
- **Fumaça** (`BuildingDef.smoke`: vapor, fumaça, pesada): chaminé de tijolo e partículas que só
  saem com o prédio produzindo; a pesada põe fuligem (Decal) em volta. A fuligem também escurece as
  casas poluídas (instance uniform `soot`).
- **Detalhe e ocultação**: telhado, chaminé, porta, velas, rastro e gaivotas têm `visibility_range`
  pelo nível; prédio a partir de 5 m de altura ganha `OccluderInstance3D` (caixa 8% menor que a
  parede), com a ocultação ligada no projeto.
- **Miniatura** (tilt-shift): `CameraAttributesPractical` com desfoque longe e perto só com a câmera
  até `tilt_shift_max_distance_m`.
- **Árvores** com shader de vento (`shaders/foliage.gdshader`), no tempo visual (para na pausa).
- **Navios**: casco afilado e velas enfunadas feitos no código (`ShipView.hull_mesh`, `sail_mesh`),
  rastro de espuma em partículas no mundo enquanto navega, gaivotas em volta de cada porto.
- **Casa que sobe de classe**: andaime e poeira por `upgrade_scaffold_seconds`.
- **Interface**: papel gerado por ruído com moldura e cantoneiras (`ThemeBuilder.paper_image`,
  gravado por `tools/build_theme.gd` em `ui/theme/paper_*.png`).

### Polimento (Fase 10)

- **Áudio** só lê o jogo e reage a eventos. Música: três climas (calma, progresso, alerta) num
  `AudioStreamInteractive`, cada um uma `AudioStreamPlaylist` de gravações em domínio público ou CC0
  (Satie, Chopin, Strauss), trocados com fade cruzado; alerta depois de falta de bem ou com saldo
  negativo, progresso depois de marco ou meta. Os `.ogg`/`.mp3` de música e ambiente são importados
  em laço com `bpm=60` (um tempo por segundo, para o fade medir em segundos). Ambiente por zona pelos
  prédios em volta do ponto da câmera e pelo zoom; **vento e chuva são ruído gerado**
  (`AudioStreamGenerator`, 22 kHz), sem arquivo. Efeitos com tempo mínimo entre repetições (construir
  50 casas toca uma martelada); todo botão ganha o clique pelo `node_added` da árvore. Fábricas com
  `BuildingDef.work_sound` ganham voz 3D, no máximo `work_voices`. **Sem tela (headless) nada toca**: os
  testes conferem `SoundEffects.played`.
- **Salvamento automático** a cada `Settings.autosave_minutes` de jogo (ticks: pausado não salva), no
  mais antigo de `autosave_slots` slots `autosave_N`. O "Continuar" pega o mais recente.
- **Opções**: aba Jogo (salvamento automático, conselheiro ligado ou não, velocidade da câmera). O
  conselheiro desligado também apaga o destaque do tutorial.
- **Tutorial pelas metas**: `GoalDef.hint` é o prédio do menu que a meta pede; a aba e o cartão dele
  piscam em dourado enquanto ela é a da vez.
- **Jogador-robô** (`AutoPlayer`): joga a partida inteira com custo, material, desbloqueio, carroças e
  armazéns; põe o produtor na frente da fila quando um bem falta (necessidade básica, entrada parada ou
  material de construção), gasta até perto do limite só contra falta, pausa fábrica com o estoque
  cheio, trava o upgrade das casas pela mão de obra. Critério da fase: 3 horas sem erro no log (um
  `Logger` captura), com save e carga a cada meia hora (`tests/sim/test_phase10_criteria.gd`).
- **Executável do Windows**: ícone (`assets/icon/society.ico`), versão 0.10.0, nome e descrição no
  `.exe` (`application/modify_resources`, sem rcedit). As cenas em C# dos addons ficam fora da exportação.

### Segunda região climática (Fase 11)

- **Ilhas tropicais** (`ArchipelagoGenerator.tropical_layout`): 3 ilhas (150, 120 e 80 células) nas
  regiões de `tropical_regions` (x = 3, com um mar aberto entre elas e as temperadas), perfis
  `cane_coast`, `coffee_hills` e `tobacco_valley` (`IslandProfileDef.climate = &"tropical"`). Saem da
  semente à parte e entram **depois** das temperadas; são as mesmas em qualquer tamanho de
  arquipélago. `layout()` e `VERSION` não mudaram: os saves de antes refazem o mesmo terreno.
  `ArchipelagoGenerator.world_specs(world)` dá as specs de um mundo (temperadas + tropicais, contadas
  pelo perfil da economia); use-a em vez de `layout()` para achar a região de uma ilha.
- **Cana, café, tabaco e ouro** crescem só lá: canavial (1:1 com a destilaria de rum), cafezal (2:1
  com a torrefação), plantação de tabaco (1:1 com a charutaria) e mina de ouro (jazida nova, 2:3 com
  a ourivesaria), liberados junto com a fábrica que os consome. O comerciante continua vendendo os
  quatro. O teste "nenhuma necessidade básica depende de importado" passou a exigir cadeia que
  comece em ilha **temperada**.
- **Colonizar ilha tropical** pede `tropical_milestone` marcos (3 = 1.000 moradores), além do limite
  de ilhas por marco (`REASON_TROPICAL_LOCKED`).
- **Save versão 8**: sem campo novo; a migração 7 → 8 acrescenta as ilhas tropicais da semente,
  virgens, aos saves de arquipélago (a ilha plana antiga fica sem elas). Tropical antes de temperada
  recusa o save.
- **Palmeiras** (Kenney Nature Kit) no lugar da mata nas ilhas tropicais (`TreeView`).

### Eventos e encomendas (Fase 11)

- **Ligados pelo jogo novo** (caixa "Eventos e encomendas", marcada por padrão; `GameScreen.events_enabled`).
  Todo mundo novo da simulação (`Simulation.new_world`, `ArchipelagoGenerator.new_world`, `SimFixture`,
  jogador-robô, benchmark) começa com `events_state.enabled = false`: os testes e o balanceamento não
  mudam com sorteio novo. Save antigo (migração 8 → 9) abre com eles ligados e o relógio do zero.
- **Eventos** (`EventSystem`, a cada `events_check_ticks`): o primeiro depois de `event_first_after_s`
  de jogo, os seguintes a cada `event_interval_s` ± `event_jitter_s`, no máximo `max_active_events` e
  nunca o mesmo duas vezes ao mesmo tempo. Sorteio pelo peso entre os liberados pelos marcos, com
  `hash([semente, &"event", event_count])`; o de ilha cai numa colonizada, a feira num bem que o
  comerciante compra. **Só multiplicadores** (`EventEffects`): produção por grupo (todos, fazendas,
  minas), preço do comerciante (`WorldState.trader_price`, que todo preço do comerciante usa agora),
  velocidade dos navios, felicidade (pontos) e chegada de moradores. Nada é destruído nem tirado: a
  tempestade (navios a 60%) é o único efeito ruim. Riscos (incêndio, doença) seguem de fora.
- **Encomendas** (`MissionSystem`): só com entreposto; a primeira depois de `mission_first_after_s`,
  as seguintes a cada `mission_interval_s`, no máximo `max_open_missions` abertas e nunca duas do mesmo
  bem. A oferta espera `mission_offer_s` e some calada; aceita (`AnswerMissionCommand`), o prazo é o
  `duration_s` dela. **A entrega é a venda no posto do comerciante** (rota ou painel do navio): o
  `CargoTransfer` entrega primeiro às encomendas aceitas do bem (a mais antiga antes), cada tonelada
  paga ao preço da volta, e o `settle` paga o prêmio (`bonus_fraction` do valor base) das cumpridas.
  Por isso o bem de toda encomenda tem de estar no `buys` do comerciante (o `GameData.validate` confere).
  Vencida, some sem multa. A venda passiva nas ilhas (`TraderVisits`) não conta.
- **Tempo em ticks** (`GameConfig.ticks_of`): os prazos e o fim dos eventos são ticks inteiros no save,
  e a partida carregada segue igual à original (há teste).
- **Save versão 9**: `events` no mundo (`EventsState.to_dict`); evento ou encomenda com definição
  desconhecida, ilha fora do mundo ou encomenda já cumprida recusa o save.
- **Interface**: botão "Encomendas (n)" na barra (laranja com oferta esperando resposta; atalho J), selos
  dos eventos ao lado da população com a dica (título, lugar, efeito e tempo), avisos de evento, oferta,
  cumprida e vencida; o aviso de encomenda e o de evento do arquipélago abrem a janela.

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
| 5 — Mundo | **concluída em 13/10/2026** |
| 6 — Navios e comércio | **concluída em 13/10/2026** |
| 7 — Interface completa | **concluída em 13/10/2026** (confirmada em 14/10/2026) |
| 8 — Conteúdo | **concluída em 14/10/2026** (confirmada em 14/10/2026) |
| 9 — Gráficos finais | **concluída em 14/10/2026** (confirmada em 14/10/2026; a medição na RTX 3060 segue pendente) |
| 10 — Polimento | **concluída em 14/10/2026** (confirmada em 14/10/2026; o teste do build em outro PC segue com o dono do produto) |
| 11 — Expansões | em andamento: segunda região climática (ilhas tropicais) e eventos e encomendas feitos em 14/10/2026; rivais com IA e combate naval a seguir |

Pendências já vistas para fases futuras:

- Balanceamento: ver `docs/balanceamento.md`. Manutenção e imposto andam colados no meio da partida;
  os números da tabela da especificação não foram mexidos (os candidatos estão anotados lá).
  Estaleiro, se a compra de navio no entreposto não bastar. Riscos (incêndio e doença, opcionais na
  seção 8) ficaram de fora.
- Fase 9 na RTX 3060: o benchmark no nível alto (`Society.exe -- --benchmark`) e se as nuvens
  volumétricas aparecem certas no ultra; modelos de verdade (prédios, casas, navios) seguem no
  `assets/TODO_ASSETS.md`.
- Fase 10 em outro PC: o `Society.exe` abre, toca a música e salva/carrega (critério "abre em outro
  PC" só se confere fora desta VM).
