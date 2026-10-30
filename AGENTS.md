# AGENTS.md — Society

City builder 3D de economia e logística no estilo do gênero de Anno 1800, em **Godot 4.7.2
(Forward+)**, GDScript com tipagem estática, para PC Windows. A especificação completa é
[`docs/especificacao.pdf`](docs/especificacao.pdf) e manda em tudo: este arquivo só
registra como se trabalha aqui e o estado das fases.

Repositório em `github.com/Davifemesquita/SOCIETY` (**público**, da conta do dono do produto, fora da `CAAD-LABS`), desde
20/10/2026; até ali era só local. O `exportado/` (o `Society.exe` tem ~230 MB, acima do limite de 100 MB do GitHub)
fica fora.

**CI** (desde 24/10/2026, `.github/workflows/testes.yml`): a cada push e pull request, um job compila os scripts
(`tools/check_scripts.gd`) e, depois dele, uma pasta de `tests/` por job em paralelo, pelo próprio `tools/godot.sh
testes` (xvfb e Vulkan por software, como na VM). Workflow próprio em vez do gdUnit4-action: os testes de
interface precisam de tela. A preparação (pacotes, o Godot de `GODOT_VERSION` em cache em `/home/runner/godot` e a
importação) fica na action local `.github/actions/godot`. A rodada leva ~15 min, quase tudo na pasta `ui`; o
relatório da pasta que falhou fica como artefato `relatorio-<pasta>`. Mudou a versão do Godot, troque
`GODOT_VERSION` e `GODOT_BIN` no workflow.

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
# no PC do dono (Windows), nada na tela dele: core/data/sim/tools/world sem janela, presentation e ui COM janela numa
# área de trabalho escondida (ambos fora do repositório, em F:\ferramentas)
#   powershell -File F:\ferramentas\testes_society.ps1
#   powershell -File F:\ferramentas\testes_janela_oculta.ps1 [res://tests/ui/x.gd]
# teste que espera animação suavizada pelo tempo (câmera, contadores) espera tempo (simulate_frames(n, ms)), não quadros:
# na GPU os quadros passam rápido demais, no lavapipe do CI devagar demais
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
# Fase 5: arquipélago da semente 1840 (de cima, litoral, floresta, rio, jazida, vila, poluição, noite);
# CAPTURA_SO=ponte tira só a ponte de madeira sobre o rio (Fase 14) e ponte_pedra, a de pedra (Fase 24); porto, o entreposto com o píer (Fase 15)
# e a gaivota de perto (Fase 21); mata, a mata de carvalhos, faias e pinheiros (Fase 22)
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_phase5.tscn -- /pasta/de/saida
# Fase 6: navio inicial, cais da colônia, navegando, posto do comerciante, painel do navio, rotas;
# CAPTURA_SO=posto tira só a feitoria do comerciante (Fase 15), com a bandeira ao vento (Fase 22)
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
# janela de encomendas com os eventos e os avisos, e as rivais (vila, navio, mapa e diplomacia);
# o combate naval e os especialistas; CAPTURA_SO=eventos, rivais, combate ou especialistas tira só essas
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
# refaz os animais (VAT) a partir dos FBX de assets/source/quaternius/animals; a captura dos bichos é
# CAPTURA_SO=animais no tools/capture_phase3.tscn
tools/godot.sh godot --headless --path . --script res://tools/bake_animals.gd
# Fase 30: moedas e "+X" sobre o entreposto e a cortina escura com o texto no meio de uma troca
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_phase30.tscn -- /pasta/de/saida
# Fase 31: casa subindo, casa demolida afundando na poeira, balas de uma salva no ar e os respingos com o alvo adernado
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 12000 res://tools/capture_phase31.tscn -- /pasta/de/saida
# Fase 32: o conjunto padrão do roteiro (arquipélago, ilha, vila no relevo, litoral, jazida e vila de perto) em cada
# nível gráfico, para comparar o antisserrilhado; CAPTURA_NIVEIS=0,2 escolhe os níveis
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 400000 res://tools/capture_phase32.tscn -- /pasta/de/saida
# Fase 39: uma rua de casas por classe, o entreposto e a casa no barranco, de perto, às 10h
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase39.tscn -- /pasta/de/saida
# Fase 83: o bairro com a festa às 22 h (hora presa), moradores e turistas em volta do mastro; o resumo vai em <pasta>/fase83.txt
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase83.tscn -- /pasta/de/saida
# Fase 84: a mesma, e de perto alguém batendo palmas olhando para o céu (palmas.png, palmas_lado.png)
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase84.tscn -- /pasta/de/saida
# Fase 85: a mesma com as palmas por estouro; grava estouro.wav e palmas.wav para ouvir
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 40000 res://tools/capture_phase85.tscn -- /pasta/de/saida
# Fase 86: um foguete parado no meio da subida (foguete.png); grava também assobio.wav
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 40000 res://tools/capture_phase86.tscn -- /pasta/de/saida
# Fase 87: cada forma de estouro sozinha no céu (forma_<forma>.png) e o foguete com o rastro
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase87.tscn -- /pasta/de/saida
# Fase 88: a mesma com a bomba de duas etapas (forma_dupla.png)
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase88.tscn -- /pasta/de/saida
# Fase 89: o grand finale (finale_meio.png e finale_chuva.png)
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase89.tscn -- /pasta/de/saida
# Fase 94: a câmera indo à praça no rufar (camera_na_praca.png), o grand finale e rufar.wav
tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase94.tscn -- /pasta/de/saida
# cidade de teste: o jogador-robô joga 4 h (todas as classes), mais praças, zoológico e museu cheios, prefeitura, eventos
# ligados com uma festa e o relógio às 18h, no slot "cidade_de_teste" (abre pelo Carregar); ~3 min, sem tela
tools/godot.sh godot --headless --path . res://tools/build_test_city.tscn
# benchmark da fase, anexado ao registro (os quadros brutos vão em docs/benchmark_quadros.json); -- --nivel N mede
# outro nível e -- --todos-os-niveis, os quatro
tools/godot.sh godot --path . --resolution 1920x1080 res://tools/benchmark.tscn -- "$PWD/docs/benchmark.md"
```

A suíte roda no **nível gráfico baixo** (`SOCIETY_NIVEL_GRAFICO=0`, posto pelo `tools/godot.sh
testes`): no alto, SSIL e neblina volumétrica por software deixavam a suíte três vezes mais lenta. A
mesma variável troca o nível em qualquer execução, sem gravar nas preferências.

**Com outras sessões abertas a suíte inteira pode cair por memória** (código 137, aconteceu duas vezes em 17/10/2026,
na partida de 3 horas): rode os arquivos que faltaram um por vez (`tools/godot.sh testes res://tests/<arquivo>.gd`).
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
| `data/game_data.tres` | todas as definições: 41 bens (`goods/`), 5 classes (`tiers/`), 63 prédios (`buildings/`, com as 6 decorações da Fase 16), perfis de ilha (`islands/`, temperados e tropicais), 4 navios (`ships/`: mercante, o do comerciante, a fragata e o clíper), o comerciante (`traders/`), 14 metas guiadas (`goals/`), 7 eventos (`events/`), 12 encomendas (`missions/`), 3 companhias rivais (`rivals/`) 8 especialistas (`specialists/`), 3 cenários (`scenarios/`) e 11 conquistas (`achievements/`) |
| `data/*_def.gd` | `GoodDef`, `TierDef`, `NeedCategoryDef`, `BuildingDef`, `IslandProfileDef`, `ShipDef`, `TraderDef`, `GoalDef` |
| `sim/island_grid.gd` | grade da ilha: ocupação (`PackedInt32Array`, id do prédio) e estradas (`PackedByteArray`) |
| `sim/footprint.gd` | retângulo girado (rotação 0 = frente em −Z) e células da face de entrada |
| `sim/placement_rules.gd` | validação; o motivo da recusa é chave de tradução `REASON_*` |
| `sim/commands/` | construir, estrada (terra ou paralelepípedo), demolir e mover: validam tudo antes de mudar o mundo |
| `sim/simulation.gd` | dona do `WorldState`; executa comandos e roda os sistemas na ordem da seção 12 |
| `sim/systems/` | força de trabalho → produção → logística (carroças) → necessidades → população → marcos → metas → economia → navios → combate → eventos → encomendas → oferta de especialistas → riscos → rivais |
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
| `presentation/tree_model.gd` | carvalho, faia e pinheiro-silvestre gerados no código, perto e longe (Fase 22) |
| `world/sky/sky_adapter.gd` | `SkyAdapter`: a única peça que conhece o Sky3D; recebe a hora do GameClock. Sem o addon, céu simples |
| `presentation/` | caixas dos prédios, estradas em MultiMesh, prévia, grade e camadas F1/F2 |
| `ui/build/build_tool.gd` | ferramenta de construção; a lógica trabalha em células, testável sem mouse |
| `ui/hud/` | barra superior, menu por categoria com as camadas, painel do selecionado, estatísticas (Tab) com gráficos (`line_chart.gd`), notificações (`notification_feed.gd` + `notice_watcher.gd`), calculadora de proporção |
| `ui/theme/` | `ThemeBuilder` (o Theme único, gravado em `society_theme.tres`) e `UiPalette` (cores e semáforo com o modo daltônico) |
| `ui/icons/` | `Icons`: atlas `icons.png` + índice `icons.json`, nomes padronizados; `ui/portraits/` tem os retratos placeholder |
| `ui/ui_kit.gd` | botão com ícone e dica, rótulo por variação, cabeçalho de janela |
| `presentation/map_overlays.gd` | camadas do jogador: raio de serviço, alcance de armazém, fertilidade, poluição e estradas |
| `presentation/cart_view.gd` | carroças num MultiMesh, posição interpolada entre ticks |
| `presentation/ship_view.gd`, `ship_rigging.gd` | navios balançando no mar (desde a Fase 26 com o cordame e a carga no convés), o posto do comerciante e a marca do selecionado; acha o navio sob o cursor |
| `ui/build/ship_picker.gd` | clique no navio (seleciona) e no mar (destino de "navegar para"); recebe a entrada antes da `BuildTool` |
| `ui/hud/ship_panel.gd`, `route_window.gd`, `archipelago_map.gd`, `trade_window.gd` | painel do navio, janela de rotas com o mapa, comércio passivo da ilha |
| `ui/hud/goal_panel.gd` | meta da vez com o progresso e a fala do conselheiro (retrato, texto, continuar) |
| `data/rival_def.gd`, `sim/rivals/`, `sim/systems/rival_system.gd` | companhias rivais: `RivalDef` (personalidade, cor, ritmo das colônias), `RivalsState`/`RivalState` (no save), `RivalShips` (o navio delas) e o `RivalSystem` (colônias, crescimento, relação, IA da postura, renda do acordo) |
| `sim/commands/diplomacy_command.gd`, `ui/hud/diplomacy_window.gd`, `presentation/rival_view.gd` | gestos de diplomacia, a janela das rivais (atalho K) e as vilas delas no mundo |
| `sim/systems/combat_system.gd` | combate naval: tiro, casco, afundar e reparo no porto |
| `data/specialist_def.gd`, `sim/specialists/`, `sim/systems/specialist_system.gd` | especialistas: `SpecialistDef` (efeito, grupo de prédios, contratação, salário), `SpecialistsState`/`Specialist` (no save) e o sorteio da oferta por volta do comerciante |
| `sim/commands/specialist_command.gd`, `ui/hud/specialist_window.gd` | contratar, designar, retirar e dispensar; a janela dos especialistas (atalho L) |
| `sim/risks/risks_state.gd`, `sim/systems/risk_system.gd` | incêndio e doença: `RisksState` (no save: ligado ou não, prédios em chamas e casas doentes com o tick do começo) e o `RiskSystem` (sorteio, fogo apagado ou prédio perdido, cura) |
| `sim/ships/shipyard_state.gd`, `sim/systems/shipyard_system.gd`, `sim/commands/shipyard_command.gd` | estaleiro: as encomendas (no save), o avanço pela força de trabalho e a entrega do navio, e o gesto de encomendar e cancelar |
| `sim/victory_state.gd`, `sim/systems/victory_system.gd`, `data/scenario_def.gd` | objetivo da partida (Fase 12): o alvo, o prazo e o resultado (no save), a conferência e os cenários prontos |
| `core/achievements.gd`, `ui/achievement_watcher.gd`, `data/achievement_def.gd` | conquistas do jogador em `user://achievements.cfg` (fora do save) e quem as confere na partida |
| `ui/screens/scenario_dialog.gd`, `achievements_dialog.gd`, `ui/hud/victory_dialog.gd`, `ui/objective_text.gd` | telas da Fase 12 e o texto do objetivo |
| `presentation/fire_view.gd` | labaredas, fumaça escura e luz laranja no prédio em chamas |
| `ui/hud/mission_window.gd` | encomendas (aceitar, recusar, entregue e prazo) e os eventos em andamento; os selos dos eventos ficam na barra (`Hud`) |
| `data/graphics/*.tres`, `data/graphics_preset_def.gd` | níveis gráficos baixo, médio, alto e ultra (Fase 9) |
| `presentation/warm_up.gd` | `WarmUp` (Fase 32): a primeira vez de cada material, num mundo de rascunho, atrás da cortina |
| `presentation/world_bounds.gd` | `WorldBounds` (Fase 32): a caixa fixa do arquipélago para os MultiMeshes que mudam a cada quadro |
| `tools/frame_stats.gd` | `FrameStats` (Fase 32): p50, p95, p99 e os lows de 1% e 0,1% dos quadros do benchmark |
| `world/graphics_quality.gd` | aplica o nível ao ambiente, ao sol, à câmera (miniatura), aos pedestres, às luzes de área e aos efeitos |
| `world/sky/clouds_adapter.gd` | adaptador do SunshineClouds2 (nuvens volumétricas) |
| `presentation/weather_cycle.gd`, `weather_view.gd` | clima só visual: sorteio por dia pela semente, chuva, neblina, chão molhado e, desde a Fase 22, o vento |
| `presentation/wind_flag.gd` | bandeira de mastro que aponta para o vento (Fase 22) |
| `presentation/cargo_kit.gd`, `stockpile_view.gd` | peças de carga (saco, barril, caixote, toras, monte) e as pilhas de estoque diante dos prédios (Fase 13) |
| `presentation/crop_view.gd` | plantações nos campos, crescendo com o ciclo da fazenda (Fase 14) |
| `presentation/bird_view.gd` | pombos nas ruas e estorninhos sobre os campos (Fase 14) |
| `presentation/harbor_view.gd`, `trader_post_model.gd` | trapiche dos píeres, cais do entreposto e feitoria do comerciante (Fase 15) |
| `presentation/yard_view.gd` | varais atrás e vasos na porta das casas de camponeses e operários (Fase 15) |
| `presentation/decoration_view.gd` | peças de decoração (Fase 16) |
| `presentation/animal_view.gd`, `shaders/animal_vat.gdshader`, `tools/bake_animals.gd` | ovelhas e porcos nos pastos, cães nas portas e o cavalo da carroça, em VAT (Fase 13) |
| `presentation/lamp_view.gd`, `shaders/night_glow.gdshader` | postes nas ruas calçadas e fogueiras atrás das casas de camponeses, acesos à noite (Fase 13) |
| `presentation/smoke_view.gd` | chaminés com fumaça e vapor enquanto produzem, fuligem no chão |
| `presentation/building_materials.gd`, `shaders/building.gdshader` | material PBR dividido dos prédios (paredes e telhados) |
| `presentation/building_kit.gd`, `shaders/building_kit.gdshader` | prédios de modelo: fachadas com as peças do Kenney Fantasy Town Kit e telhado gerado, uma malha por forma |
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
- **A casa sobe ao chegar aos moradores que o atendimento permite**, não cheia (15/10/2026): a
  categoria conta como atendida a partir de `need_met_threshold` (90%), mas a casa só enche com 100%;
  exigir a casa cheia travava a subida para sempre com um bem em 95%, com o painel todo verde.

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
  inteira a cada estrada nova; com coordenadas, construir com a ilha cheia passava de 50 ms. Os
  vizinhos se conferem um a um, sem montar `[esq, dir, cima, baixo]` por célula, a varredura atrás de
  estrada usa o `find` do `PackedByteArray`, e a frente do prédio no recálculo é
  `Footprint.front_indices` (índices, sem `Vector2i`): construir voltou de 52 para 37 ms.
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
- **Árvores** (desde a Fase 22, as do `TreeModel`; ver "Mata e vento"): MultiMesh por trecho de 64×64 células e por modelo; no máximo 2 desenhadas por
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
  dos detalhes, pedestres, luzes de área, o antisserrilhado (desde a Fase 32; antes, MSAA) e a escala FSR sugerida. O padrão é o **alto** (o do
  critério). `Settings.apply()` faz a janela (AA, FSR, LOD, atlas e filtro de sombra); o
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
  armazéns, numa ilha plana de 350×350 (a terra do arquipélago: ele não coloniza); até 3 faltas e 3
  obras por rodada, pulando a obra da frente que espera gente; não repete um produtor antes de 2 min nem
  ergue fábrica no vermelho perdendo dinheiro; põe o produtor na frente da fila quando um bem falta (necessidade básica, entrada parada ou
  material de construção), gasta até perto do limite só contra falta, pausa fábrica com o estoque
  cheio, trava o upgrade das casas pela mão de obra. Critério da fase: 3 horas sem erro no log (um
  `Logger` captura), com save e carga a cada meia hora (`tests/sim/test_phase10_criteria.gd`).
- **Executável do Windows**: ícone (`assets/icon/society.ico`), versão 0.22.0 (0.21.0 na Fase 21, 0.20.0 na Fase 20, 0.19.0 na Fase 19, 0.18.0 na Fase 18, 0.17.0 na Fase 17, 0.16.0 na Fase 16, 0.15.0 na Fase 15, 0.14.0 na Fase 14, 0.13.0 na Fase 13, 0.12.0 na Fase 12, 0.11.0 na Fase 11, 0.10.0 na Fase 10), nome e descrição no
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
  tempestade (navios a 60%) é o único efeito ruim. Os riscos (incêndio, doença) são um sistema à parte
  (ver "Riscos").
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

### Companhias rivais e diplomacia (Fase 11)

- **Ligadas pelo jogo novo** (caixa "Companhias rivais"; `GameScreen.rivals_enabled`), desligadas em todo
  mundo novo da simulação, como os eventos. Save antigo (migração 9 → 10) ganha as rivais.
- **Sem prédios na simulação**: a rival é um registro (`RivalState`) com as ilhas dela e os moradores de
  cada uma, que crescem até `rival_residents_per_cell` × células da ilha. A vila no mundo (`RivalView`)
  sai da grade da ilha (terra plana sem árvore, em espiral do meio), uma casa por
  `rival_residents_per_house` moradores. Não entra na economia, nas carroças nem nos pedestres.
- **Colônias** (`RivalSystem`, a cada `events_check_ticks`): cada rival funda a primeira depois de
  `first_colony_s` e as seguintes a cada `colony_interval_s`, até `max_islands` dela e
  `rival_island_share` das ilhas além da principal para todas juntas; só ilha sem entreposto do jogador
  e sem dono, tropical só depois de `rival_tropical_after_s`. Sorteio pela semente. Ilha de rival
  recusa a colônia do jogador (`REASON_RIVAL_ISLAND`).
- **Navio da rival** (`Ship.Owner.RIVAL`, achado por `RivalsState.by_ship`): vai e volta entre as ilhas
  dela e o posto do comerciante, parando `rival_ship_dwell_s`; não ocupa vaga de porto (ancora como quem
  coloniza) e ancora no posto do lado dele. Velas e marca no mapa na cor da rival.
- **Relação** (-100 a 100) volta aos poucos (`rival_relation_drift_per_min`) à da personalidade
  (`rival_base_relation`: pacífica 20, ambiciosa 0, agressiva -20; com acordo, pelo menos
  `rival_trade_relation`); cada colônia do jogador esfria as não pacíficas (`rival_colony_penalty`).
- **Gestos** (`DiplomacyCommand`, motivo da recusa por `check`, que a janela usa para desligar o botão):
  presente, propor e desfazer acordo, declarar guerra e propor paz (custa `rival_peace_money`). O acordo
  rende `rival_trade_income_per_resident` × moradores da rival por minuto, somado no `income_per_min`.
- **IA da postura**: a agressiva declara guerra com a relação em `rival_war_relation` ou menos; a não
  agressiva faz as pazes sozinha acima de `rival_auto_peace_relation`; o acordo cai com relação
  negativa; a postura não muda de novo antes de `rival_stance_cooldown_s`. Em guerra o mercante dela
  afundado só volta na paz.
- **Save versão 10** (a 11 acrescenta casco e fragatas): `rivals` no mundo; ilha de rival com entreposto do jogador, ilha 0 ou repetida, ou
  navio de rival que não existe recusa o save.

### Combate naval (Fase 11)

- **Casco e canhões no `ShipDef`** (grupo Combate): `hull_points`, `cannons`, `salvo_damage`,
  `cannon_range_m`, `reload_s` e `unlock_milestone` (a compra espera o marco: `REASON_SHIP_LOCKED`). A
  fragata (`frigate`, 12 canhões, casco 500) é o único navio armado; o mercante tem casco 120. Comprada no
  entreposto ("Comprar fragata"), entra em rota como qualquer navio (porão de 20 t): é a escolta.
- **`CombatSystem`**, logo depois dos navios: só jogador contra rival **em guerra com ele** (o
  comerciante é neutro, rivais não brigam entre si). Navio armado recarrega e atira no inimigo mais perto
  ao alcance (desempate pelo id); casco a zero afunda o navio com a carga (`ship_sunk`); parado num porto
  do dono, o casco volta `ship_repair_per_s`. Sem guerra só o reparo roda.
- **Fragatas da rival** (`RivalState.warships`, achadas pelo `by_ship` junto do mercante): em guerra, uma
  a cada `rival_warship_build_s` até `rival_warships`, revezando entre a ilha dela e o posto do
  comerciante com `rival_warship_dwell_s` em cada ponta (guarda e bloqueio); na paz somem. Cada uma
  afundada soma `rival_loss_relation` na relação (a guerra cansa).
- **Na tela**: clarão no navio que atira, fumaça no avariado (casco abaixo da metade), o afundado desce
  adernando por `SINK_SECONDS` antes de sumir (o nó sai do `_nodes` no `ship_sunk`), som de canhão
  próprio (`tools/build_cannon_sound.py`, ruído filtrado, sem arquivo de terceiros), casco e canhões no
  painel do navio, avisos de navio sob fogo e afundado.
- **Save versão 11**: `hp` e `reload` em cada navio; `warships` e `next_warship_tick` em cada rival.

### Eletricidade (Fase 11)

- **Usina elétrica** (`power_station`, engenheiros 150): prédio de produção com `power_radius_cells`
  e sem `output`; queima 1 t de carvão por ciclo de 60 s e não põe bem no estoque
  (`BuildingDef.is_power_plant`). Polui e solta fumaça pesada como a fundição.
- **Quem ganha**: só fábrica, isto é, produção com entrada (`is_electrifiable`); extração, fazenda e a
  própria usina não. A fábrica a até o raio (folga entre os retângulos, como a poluição) de uma usina
  da mesma ilha **que produzia no tick anterior** ganha `electricity_bonus` (+50%) na velocidade,
  multiplicado com os eventos; a produtividade passa de 100%.
- **Sem estado novo no save**: as usinas de cada fábrica (`ProductionEntry.power_plants`) saem da
  geometria no `DerivedState`; `powered` se refaz a cada tick pelo estado da usina. O save segue na
  versão 11.
- **Na tela**: camada de mapa "Eletricidade" (raio amarelo com a usina ligada, cinza parada; fábrica
  verde com eletricidade, vermelha sem), linha no painel da fábrica (só com usina na ilha) e "Fábricas
  no raio" no painel da usina; a dica do menu diz o raio e o bônus.

### Especialistas (Fase 11)

- **Ideia própria** (a especificação só diz "especialistas"): gente de ofício que o comerciante traz.
  Cada um trabalha num prédio de produção do grupo dele (`SpecialistDef.covers`: todos, fazendas,
  minas, fábricas ou uma lista; a usina nunca), **um por prédio**, e ganha `salary_per_min` enquanto
  está contratado, posto ou não (somado na manutenção pelo `DerivedState`).
- **Efeitos**: velocidade (multiplica junto com eventos e eletricidade), corte da manutenção do prédio
  e 1 t a mais na saída a cada N ciclos completos (`Specialist.cycles`, no save; a tonelada extra só
  entra se couber no buffer). Navio não recebe especialista.
- **Oferta** (`SpecialistSystem`): a cada volta nova do comerciante (`trader.tour`), `specialist_offers`
  sorteados pelo peso entre os liberados por marco, sem repetir, com `hash([semente, &"specialist",
  volta, i])`. A oferta fica guardada como lista de ids: contratar tira dela e a mesma volta não repõe.
  Sem o navio do comerciante no mar não há oferta. Sempre ligados (não há caixa no jogo novo): quem
  não contrata não muda nada, e o jogador-robô não contrata.
- **Gestos** (`SpecialistCommand`, motivo da recusa por `check`, que a janela usa para desligar o
  botão): contratar paga `hire_cost` (até `max_specialists`), designar (o já posto muda de prédio),
  retirar e dispensar (sem devolução). Demolir o prédio devolve o especialista à lista, sem posto;
  mover o prédio leva o especialista junto (o id não muda).
- **Save versão 12**: `specialists` no mundo; especialista em prédio que não existe ou fora do grupo
  dele recusa o save. Saves antigos (migração 11 → 12) começam sem contratados e recebem a oferta da
  volta em que o comerciante está no primeiro tick.
- **Na tela**: botão dos especialistas na barra, com o ícone e o número de contratados (laranja com
  contratado sem posto; atalho L), janela
  com a oferta e os contratados, e no painel da produção a linha do especialista (efeito na dica), a
  manutenção já com o corte e o botão "Especialista", que abre a janela apontando para o prédio
  ("Designar aqui" nos contratados sem posto que servem a ele).
- **Barra superior em 1920 px**: com rivais e especialistas ela passava da tela e empurrava salvar,
  carregar e menu para fora. Estatísticas, Rotas e Rivais viraram botões só de ícone (o nome e o
  atalho ficam na dica); Encomendas mantém o texto com a contagem.

### Riscos (seção 8, opcionais; depois da Fase 11)

- **Ideia própria nos números** (a especificação só diz "incêndio e doença, com bombeiros e hospital").
  Ligados pela caixa "Incêndio e doença" do jogo novo (`GameScreen.risks_enabled`, marcada por padrão) e
  desligados em todo mundo novo da simulação, como os eventos: os testes e o jogador-robô não mudam.
- **Quartel de bombeiros e hospital** são serviços (`BuildingDef.protects`, raio por estrada como os
  outros, 30 células) que não atendem necessidade de classe. O quartel protege casa e produção cuja
  frente encosta na estrada ao alcance dele (`DerivedState.fire_protected`); o hospital, as casas que ele
  cobre (`health_protected`). `protected_by` dá, por quartel ou hospital, o que ele protege (painel e
  destaque). Quartel livre com 50 camponeses; hospital com 200 operários.
- **`RiskSystem`**, a cada `risk_check_ticks`, depois dos especialistas: resolve e depois sorteia, pela
  semente e pelo tick. Fogo só em casa e produção (`BuildingDef.can_burn`, `fire_risk` multiplica: 2 nas
  fábricas de forno), a partir de `fire_after_milestone`; doença só em casa com morador, a partir de
  `disease_after_milestone`, mais com a poluição. Teto de `max_active_fires` e `max_active_outbreaks`.
- **Proteção é a de agora**: fogo no raio do quartel se apaga em `fire_extinguish_s`; fora dele queima
  `fire_burnout_s` e o prédio se perde (sai do mundo como na demolição, sem devolver material; o
  especialista volta para a lista). Quartel erguido durante o fogo ainda salva o prédio. A doença sara em
  `disease_cure_s` com hospital e em `disease_duration_s` sem.
- **Efeitos**: produção em chamas para (`State.ON_FIRE`, no fim da lista); casa em chamas não paga
  imposto, não recebe gente e não sobe; casa doente perde `disease_residents_lost_per_min` moradores e
  `disease_happiness_penalty` de felicidade e não sobe.
- **O sorteio anda pela lista do estado derivado**, que ainda tem os prédios perdidos na mesma
  conferência (saem do mundo depois, pela `Simulation`): eles ficam de fora, senão pegavam fogo de novo
  e a partida carregada divergia (o teste de save pegou).
- **Save versão 13**: `risks` no mundo (`RisksState.to_dict`, listas de prédio e tick); fogo em prédio
  que não arde, doença fora de casa ou prédio inexistente recusa o save. Demolir esquece o risco do
  prédio. Saves antigos (migração 12 → 13) abrem com os riscos **desligados**: nada pega fogo de repente
  numa cidade erguida sem bombeiros.
- **Na tela**: caixa no jogo novo, dica do menu com o raio e o tempo de apagar/curar, linha dos riscos
  no painel (em chamas, doente, no raio ou fora), "Protege n prédios" no painel do quartel e do hospital
  e o destaque do que ele protege, avisos de fogo (sem bombeiros diz em quanto tempo o prédio se perde),
  fogo apagado, prédio perdido e doença, com som de alerta, e o fogo desenhado (`FireView`).

### Estaleiro (depois da Fase 11)

- **Ideia própria** (pendência antiga: "estaleiro, se a compra no entreposto não bastar"). Produção sem
  bem no litoral (`BuildingDef.shipyard_ships`, `is_shipyard`), 60 operários, livre com 300 operários.
  Não tem ciclo: o `ProductionSystem` o pula e o `ShipyardSystem` (logo depois da produção) cuida do
  estado (sem encomenda fica `IDLE`, "Sem encomenda" no painel, e não vira aviso de parado) e do avanço.
- **Encomenda** (`ShipyardCommand`, motivo por `check`, que o painel usa para desligar o botão): um
  navio por estaleiro, pago na hora a `shipyard_cost_factor` (75%) do preço do entreposto (moedas e
  materiais, para cima), esperando o marco do navio; **conta no limite de navios** (o entreposto também
  conta as encomendas). Anda `dt × força de trabalho / build_time_s` (`ShipDef`); pronta, o navio
  aparece no porto da ilha (`ship_built`). Cancelar devolve `shipyard_cancel_refund` das moedas; o
  material não volta. Demolir ou perder o estaleiro no fogo perde a encomenda.
- **Clíper** (`clipper`, `ShipDef.shipyard_only`): 5 porões, 9 m/s, casco 150, terceiro marco; o
  entreposto recusa (`REASON_SHIPYARD_ONLY`). O estaleiro também faz o mercante e a fragata.
- **Reparo**: navio do jogador parado no porto de ilha com estaleiro se repara `shipyard_repair_factor`
  (2×) mais depressa. Especialista não vai para o estaleiro.
- **Save versão 14**: `shipyard` no mundo (encomendas por estaleiro, com o progresso e as moedas pagas);
  encomenda em prédio que não é estaleiro ou de navio que ele não faz recusa o save.
- **Na tela**: um botão por navio no painel (custo e tempo na dica, motivo quando não dá), a encomenda
  com o progresso e o cancelar, a dica do menu e o aviso do navio pronto. A fila de botões do painel
  virou `HFlowContainer` (quebra a linha quando não cabe).

### Cenários e vitória (Fase 12)

- **A especificação acaba na Fase 11**; a 12 é proposta nossa (15/10/2026): a partida ganha um fim.
- **Objetivo** (`VictoryState`, no save): um `GoalDef.Kind` (a mesma conta das metas guiadas, com
  `MONEY` acrescentado no fim da lista), o alvo, a quantidade e o prazo em ticks. Sem objetivo
  (`kind = -1`) a partida é livre, como antes. O `VictorySystem` confere a cada `goal_check_ticks`,
  logo depois das metas: cumprido, `match_won`; passado o prazo, `match_lost`. Depois disso não confere
  mais e a partida segue livre ("Continuar jogando").
- **Jogo novo**: "Objetivo" (partida livre ou um dos de `GameConfig.victory_kinds/targets/amounts`) e
  "Prazo" (`deadline_choices_min`; desligado na partida livre). A escolha vai pelas variáveis estáticas
  da `GameScreen` (`victory_*`, `scenario_id`, `starting_money`), zeradas por `reset_new_game()` antes de
  cada jogo novo.
- **Cenários** (`ScenarioDef`, `data/scenarios/`): semente, tamanho, dificuldade, dinheiro inicial,
  eventos, rivais, riscos, objetivo e prazo. `GameScreen.apply_scenario` prepara o jogo novo. Colônia
  pobre (300 artesãos, sem rivais, difícil), Corrida pelas ilhas (4 ilhas em 3 h,
  arquipélago grande) e Príncipe mercador (250.000 moedas em 4 h).
- **Conquistas** (`AchievementDef`, `data/achievements/`): de estado (população de uma classe, moedas,
  ilhas, navios do estaleiro), conferidas a cada 2 s reais, e de acontecimento (fogo apagado, navio de
  rival afundado, vitória), somadas em contadores pelo `EventBus`. A de cenário só vale com aquele
  cenário vencido. Ficam em `user://achievements.cfg`, valem para todas as partidas e **não vão no save**;
  arquivo estragado começa do zero. Construir de graça (`free_build`) não ganha nada. Os testes trocam a
  instância (`Achievements.use`) para não mexer no arquivo do jogador.
- **Save versão 15**: `victory` no mundo; classe ou cenário desconhecido recusa o save. Saves antigos
  (migração 14 → 15) seguem livres.
- **Na tela**: menu principal com "Cenários" e "Conquistas", linha do objetivo no painel das metas
  (progresso e tempo que falta; verde vencida, vermelha perdida), tela de fim com o resumo (tempo,
  moradores por classe, moedas, ilhas, navios, prédios perdidos no fogo, encomendas) e aviso de
  conquista.

## Assets e licenças (seção 14)

- **Navios e carroças de modelo** (15/10/2026): Kenney Pirate Kit e Fantasy Town Kit (CC0). Cada
  `ShipDef.model` aponta um `.glb` de `assets/models/ships/`, esticado até `length_m`, girado com a proa
  para +X e afundado `MODEL_DRAFT` (`ShipView`); as velas são o texel claro e sem saturação da textura,
  tingido na cor do tipo ou da rival (`shaders/ship_model.gdshader`). A carroça junta as peças do
  `cart.glb` numa malha só (`CartView.model_mesh`), porque o MultiMesh só desenha uma. Sem o arquivo,
  os dois voltam ao placeholder gerado no código. `tools/capture_ships.tscn` tira as capturas.
- **Prédios de modelo** (16/10/2026): `BuildingKit` monta cada prédio com as peças de parede do mesmo
  kit (`assets/models/buildings/`): uma peça por célula da borda e por andar (andar de ~2,6 m), porta na
  célula da entrada (arco no armazém, estaleiro e serviços de pedra), janelas no resto (alternadas com
  parede lisa nas fábricas com fumaça e nos depósitos). O telhado é gerado (duas águas, quatro águas na
  igreja/teatro/universidade, plano em mina, poço e prédio baixo; a casa sorteia três). Uma malha por
  forma (`Spec.key`), em cache, com LOD gerado (`ImporterMesh.generate_lods`); a vista gira o nó
  (`-PI/2 × rotação`, a porta canônica fica em −Z e o índice dela espelha nas rotações 2 e 3). As peças
  chegam indexadas: alicerce e telhado vão num `SurfaceTool` à parte, senão os vértices soltos ficam fora
  do índice e não aparecem. O material (`BuildingMaterials.kit`, `shaders/building_kit.gdshader`)
  reconhece parede e telhado pela célula da paleta na UV e põe a textura PBR, o tom, a fuligem e a chuva
  de antes; o madeiramento vira madeira escura no tom do prédio. As janelas acesas seguem as do modelo
  (`WindowLightsView.building_windows`). Campo, pasto e píer, e tudo sem o kit, continuam caixas.
  `tools/capture_buildings.tscn` tira as capturas (`CAPTURA_SO=casas`, `noite`, `silhuetas`, `postes` (com os pombos), `detalhes`, `plantacoes` (com os estorninhos) ou `decoracao` ou `diagonal`).

### Cidade viva (Fase 13, nossa)

- **A especificação acaba na Fase 11** e a 12 foi nossa; a 13 fecha o que as seções 9 (mundo vivo) e
  11 (arte) pedem e ainda faltava, em partes com commit próprio. Tudo é só visual: nada muda na
  simulação nem no save (segue na versão 15).
- **Silhueta por cadeia** (`BuildingDef.silhouette`, nos `.tres`): pás na empena do moinho (o telhado vira
  de frente), roda d'água no lado da serraria, torre de vigas com polia nas minas, pátio de bancas na
  metade da frente do mercado (`Spec.court_rows`: o corpo é `Spec.hall()`, deslocado por `hall_offset()`,
  e as janelas e a porta seguem), guindaste no armazém, entreposto e estaleiro, lanternim nas fábricas
  pesadas e bandeira em cima da porta dos serviços (a janela de cima da porta vira parede lisa). As peças
  paradas entram na malha da forma; vigas são a `pillar-wood` do kit esticada de um ponto a outro
  (`BuildingKit._beam`). A parte que gira (`BuildingKit.rotor`, malha em cache com o meio no eixo) é um nó
  `Rotor` filho do modelo, que a `BuildingView` gira em torno do x local enquanto o prédio produz, no tempo
  de jogo (`spin_rotors`, para na pausa).
- **Pilhas de estoque** (`StockpileView`): diante de cada prédio de produção, uma peça por tonelada pronta
  no estoque de saída (até `building_buffer_t`), duas lado a lado e subindo em camadas, no canto da frente
  mais longe da porta (`StockpileView.anchor`). A peça é a forma do bem (`GoodDef.pile`: saco, barril,
  caixote, toras ou monte; o porco não tem pilha), feita pelo `CargoKit`: barril e caixote do Kenney Pirate
  Kit (`assets/models/cargo/`), saco, tora e monte gerados no código na cor do bem. Um MultiMesh por tipo de
  peça, refeito só quando alguma pilha muda (conferência a cada 0,5 s).
- **Carga da carroça** (`CartView`): as mesmas peças, uma por tonelada começada (até duas, frente e trás da
  caçamba, `CARGO_SLOTS`), num MultiMesh por tipo de peça; a caixa colorida de antes fica só para o bem sem
  peça (o porco). Volta vazia, sem peça.
- **Postes e fogueiras** (`LampView`): o lampião do kit (desde a Fase 18, o poste de ferro fundido gerado no código) numa célula
  calçada a cada `LAMP_EVERY` (pelo desenho da grade, `posmod(x + 3y, 4)`), deslocado para o lado da
  célula que não é rua; fogueira (pedras, lenha e chama gerados) atrás de uma casa de camponeses a cada
  `BONFIRE_EVERY` (pelo id), só com a célula de trás livre. O vidro e a chama acendem pelo `night_light`
  (`shaders/night_glow.gdshader`; a cor da instância chega em sRGB e é convertida lá, senão a chama saía
  branca); luz de verdade (OmniLight3D) só nos `LIGHTS` mais perto de onde a câmera olha, de noite e com a
  câmera perto. Refeito quando estrada, prédio ou classe da casa muda.
- **Detalhe das casas** (`TierDef.house_trim`, nos `.tres` das classes; `BuildingKit._trim`): quintal cercado
  com portão na fileira da frente dos camponeses (`court_rows = 1`, como o pátio do mercado: a casa, a porta e
  as janelas recuam e o alicerce é só o do corpo), floreiras debaixo das janelas de cima dos artesãos, sacadas
  (piso de tábuas e frente com parapeito) nos andares do meio dos engenheiros e, nos investidores, sacada no
  primeiro andar, duas colunas de pedra na porta e sebe florida no térreo. As peças são do kit; o verde da
  sebe (célula (3, 3) da paleta) vira folhagem com flores no `shaders/building_kit.gdshader`.
- **Animais** (`AnimalView`): ovelhas e porcos (`PER_PASTURE` por pasto) no pasto que tem dono
  (`DerivedState.module_owner`: `PASTURE_ANIMAL` diz o bicho de cada fazenda; pasto sem fazenda fica vazio), um
  cão ao lado da porta de uma casa a cada `DOG_EVERY` (pelo id) e o cavalo andando na frente de cada carroça,
  entre os varais (`CartView`). Os bichos são do Farm Animals Pack da Quaternius (FBX em
  `assets/source/quaternius/animals/`, com `.gdignore`), gravados em VAT por `tools/bake_animals.gd` com o mesmo
  `VatBaker` dos pedestres: a cor sai do material de cada superfície (cor do vértice) e o lado para onde o bicho
  olha, da cabeça (não há pés para medir). Ovelha, porco e cão só têm a animação parada; o cavalo anda. O
  `shaders/animal_vat.gdshader` anima no `visual_time` (para na pausa). **A carroça andava de ré** até aqui
  (`CartView.MODEL_YAW` era PI): com o cavalo se viu, e os varais agora vão na frente. Pássaros nas ruas ficaram
  de fora (`assets/TODO_ASSETS.md`).

### Campo e caminho (Fase 14, nossa)

- **Proposta nossa** (16/10/2026), em partes com commit próprio: plantações nos campos, cerca e capim nos
  pastos, meio-fio e emenda nas estradas, ponte de madeira e pássaros. Só visual; o save fica na versão 15.
- **Plantações** (`CropView`, `BuildingDef.crop` nas fazendas de campo): o campo que tem dono
  (`DerivedState.module_owner`) ganha fileiras da planta da fazenda (cereal, batata, lúpulo na estaca, parreira,
  cana, café, tabaco), geradas no código com a cor no vértice, um MultiMesh por planta. Crescem com o ciclo da
  fazenda (`BuildingRecord.progress`, em `GROWTH_STEPS` degraus, a partir de `MIN_GROWTH`); o cereal vai do verde
  ao dourado. Na colheita o ciclo volta a zero e a planta também. Só o campo que mudou de degrau é reescrito
  (conferência a cada 0,5 s). Campo sem dono fica na terra arada (a cor do `field.tres` virou de solo).
- **Pastos** (também na `CropView`): todo pasto, de dono ou não, ganha cerca de madeira por dentro da borda, em
  lanços de `FENCE_STEP_M` (o lanço é esticado em x), e touceiras de capim. O lado que encosta em outro pasto
  fica aberto: pastos vizinhos viram um cercado só. As ovelhas e os porcos ficam a `PASTURE_MARGIN_M` da borda.
- **Estradas** (`RoadView`): o paralelepípedo ganha meio-fio de pedra (um MultiMesh filho, no referencial do
  ladrilho: segue a ladeira) em cada lado que não dá para outra estrada; a terra ganha dois sulcos de roda no
  `shaders/road.gdshader`, pela direção que vai no dado da instância (`RoadView.ruts`: ao longo de x, de z, os
  dois no cruzamento e na curva, nenhum na célula solta). O poste da Fase 13 fica em cima do meio-fio.
- **Ponte** (também na `RoadView`): tábuas de través no `shaders/road.gdshader` (pela direção dos sulcos, alinhadas
  no mundo para emendar entre células, cada uma num tom) e, em cada lado da célula de rio que não dá para outra
  estrada (`RoadView.railed`), corrimão de duas travessas com poste no meio e nos cantos (o canto da frente só onde
  o corrimão acaba, para não repetir o poste da vizinha) e uma estaca do tabuleiro até `PILE_SINK_M` dentro do leito.
  Postes e estacas são a mesma caixa de 1 m esticada, num MultiMesh só. A cor da instância chega em sRGB no
  shader e é convertida lá (a tábua saía desbotada desde a Fase 9).
- **Pássaros** (`BirdView`): um bando de `PIGEONS_PER_FLOCK` pombos nas células de estrada em que
  `posmod(7x + 13y, PIGEON_EVERY)` = 0 (sem sorteio), ciscando no chão e levantando voo uma vez por ciclo do bando
  (`pigeon_flight`: uma volta que sobe e desce), e um de estorninhos sobre cada `FIELD_FLOCK_EVERY`-ésimo campo com
  dono, circulando e derivando. Teto de `MAX_BIRDS` no mundo; somem à noite. O voo é contado na CPU a cada quadro
  (como as gaivotas), no tempo de jogo (para na pausa; `advance` anda o relógio à mão nos testes e nas capturas).
  Duas malhas, pousado (corpo e cabeça) e voando (com as asas), cada uma num MultiMesh com uma instância por
  pássaro; a do que ele não está fazendo fica encolhida a zero. Asa encolhida no chão parecia aviãozinho de papel.

### Porto e quintal (Fase 15, nossa)

- **Proposta nossa** (16/10/2026), em partes com commit próprio: trapiche no píer, cais do entreposto com barcos e
  carga, feitoria do comerciante, cestos e sacos na mão dos pedestres (seção 9) e varais e vasos nas casas (seção
  11). Só visual; o save fica na versão 15.
- **Trapiche** (`HarborView`): o píer não tem mais caixa na `BuildingView` (só a etiqueta). Tábuas de través sobre
  a área dele e uma passarela de `WALK_WIDTH_M` saindo pelo lado mais virado para o cais (`Harbors.berth_point`,
  parando `BERTH_CLEARANCE_M` antes: o casco encosta ali), com estacas nas duas bordas a cada `PILE_STEP_M` e dois
  cabeços de amarração de ferro na ponta. Sem cais (píer sem estrada até um entreposto), a passarela vai para o
  mar mais perto (`seaward`, pela célula de mar: a altura não serve, a ilha plana fica no zero); antes ia para trás
  da entrada e entrava pela terra, por baixo do prédio vizinho.
- **Cais do entreposto** (também na `HarborView`): tábuas de `QUAY_DEPTH_M` no lado do mar, na largura do prédio,
  cabeços na beira, a carga de `QUAY_CARGO` (barris, caixotes e sacos do `CargoKit`) no fundo e dois barcos a remo
  (`boat_mesh`, casco aberto gerado no código) amarrados de comprido; cada píer ganha um barco ao lado da
  passarela. O barco só fica onde boia (`afloat`: célula de mar **e** fundo abaixo da quilha; a praia é célula de
  mar e fica acima da água), andando para fora até `BOAT_SEARCH_M`; sem isso, nenhum barco.
- **Feitoria do comerciante** (`TraderPostModel`, no lugar das caixas da `ShipView._build_post`): plataforma de
  tábuas sobre estacas que entram na água, galpão de tábuas com telhado de duas águas (`PrismMesh`) e porta larga,
  guindaste de vigas para o mar com um caixote pendurado, carga do `CargoKit`, dois barcos a remo e o mastro com a
  bandeira. A captura é `CAPTURA_SO=posto` no `tools/capture_phase6.tscn`.
- **Cesto e saco na mão** (`CarriedGoods`, `shaders/carried_vat.gdshader`): quem sai do mercado leva cesto e quem
  sai de fazenda leva saco (`Crowd.Load`, guardado no agente junto da animação de carregar). Cada grupo da
  `PedestrianView` tem um MultiMesh de cestos e um de sacos, com uma instância por pedestre no mesmo lugar dele e o
  mesmo dado (o shader faz a mesma conta do passo; em w vai o passo da animação, que dá o balanço), escondida em
  quem não leva aquilo. A peça fica em `HOLD_HEIGHT` da altura do corpo e `HOLD_FORWARD_M` à frente. A captura é
  `CAPTURA_SO=cestos` no `tools/capture_phase4.tscn`.
- **Varais e vasos** (`YardView`): varal com roupa (`CLOTH_COLORS`) na célula livre de trás de uma casa de
  camponeses ou operários a cada `CLOTHESLINE_EVERY` (resto `CLOTHESLINE_REST`: a fogueira da `LampView` usa o resto
  0 de 3, e as duas nunca disputam o lugar, que é o mesmo `LampView.bonfire_spot`); vasos de flor dos dois lados da
  porta em uma casa a cada `POT_EVERY`, na frente do corpo (no quintal cercado dos camponeses a casa recua uma
  fileira, `TierDef.HouseTrim.YARD`). As capturas saem no `CAPTURA_SO=postes`.

### Praças e jardins (Fase 16, nossa)

- **Proposta nossa** (17/10/2026): a seção 10 pede a categoria **decoração** no menu de construção, e ela não
  existia. Partes com commit próprio: beleza na simulação com as peças pequenas, praça calçada com chafariz,
  estátua e coreto, e a camada de mapa "Beleza" com o balanceamento conferido.
- **Beleza** (`BuildingDef.beauty`, `beauty_radius_cells`; `BuildingDef.Kind.DECORATION`, no fim do enum): como a
  poluição, cada decoração cai linear com a distância até o raio dela e a soma por casa vai até 1
  (`DerivedState.beauty`); a felicidade ganha `happiness_per_beauty` × beleza. Sai da geometria: o save segue na
  versão 15. A decoração não pede estrada (`RoadNetwork.has_access`), não pega fogo e não tem trabalhador.
- **Peças pequenas** (livres desde o começo): árvore plantada, canteiro de flores e banco de praça, desenhados pela
  `DecorationView` (geradas no código, cor no vértice, um MultiMesh por tipo). A `BuildingView` não desenha caixa
  nem porta para a decoração, e a `WindowLightsView` não põe janela nela nem no píer (a árvore ganhava janela
  preta, e o píer da Fase 15 ficava com janelas soltas no ar).
- **Aba Decoração** no menu, antes da infraestrutura (que continua a última: as estradas entram nela). Com seis
  abas de texto a barra passava de 1920 px; as de produção levam só o nome da classe, e "Produção: <classe>" vai na
  dica. O painel da decoração diz quantas casas ela embeleza; o da casa mostra "Beleza" ao lado da felicidade.
- **Praça com chafariz** (3×3, operários 100, 900 moedas e 6 tijolos, beleza 0,45 em 7 células): lajes de pedra em
  tons, meio-fio, bacia octogonal com a coluna e a taça, dois bancos (o mesmo `_bench`, virado) e o jato, um
  `CPUParticles3D` por praça que a `DecorationView` cria e tira junto com ela.
- **Estátua** (2×2, artesãos 100, beleza 0,35 em 6) e **coreto** (3×3, engenheiros 100, beleza 0,55 em 9): figura
  genérica de bronze com azinhavre sobre pedestal de degraus num canteiro de grama; coreto de piso octogonal
  elevado, oito colunas de ferro, guarda-corpo aberto na escada da frente e telhado de oito águas. Leque de
  triângulos (piso e telhado) segue a ordem da `CarriedGoods._lump`, que é a que o Godot desenha por fora.
- **Camada Beleza** (`MapOverlays.Layer.BEAUTY`, no fim do enum): a beleza por célula em rosa, como a poluição; ao
  escolher ou selecionar uma decoração, o chão destaca o raio dela. Balanceamento em `docs/balanceamento.md`
  (beleza cheia = +12 de felicidade = +12% do imposto da casa; o robô não constrói decoração).

### Porto e diagonais (Fase 17, nossa)

- **Escolhida pelo dono do produto** (17/10/2026) entre as sobras da especificação: a aba **Porto** do menu (seção
  10) e as **estradas em diagonal**, que a seção 7 deixa "para depois do jogo base". Mudança grande de arquitetura,
  com a aprovação dele. Partes com commit próprio.
- **Aba Porto**: entreposto, píer e estaleiro (que saiu da aba de produção dos operários), antes da
  infraestrutura, que segue a última (armazém e as estradas). Com dez abas a barra passava de 1920 px: as de
  produção ficaram só com o medalhão da classe (como a população na barra de cima) e "Produção: <classe>" na dica.
  O tutorial do entreposto aponta a aba Porto.
- **Diagonal pura** (`RoadNetwork.linked_diagonal`): duas células de estrada que se tocam só pelo canto se ligam
  quando nenhuma das duas vizinhas em comum é estrada; numa esquina em L a do meio já liga e o canto não conta (a
  carroça não corta caminho por cima da grama). Sai do desenho da grade: **o save não mudou**. Entra nas três buscas
  por índice (`components`, `ServiceReach.road_cells`, `WarehouseField`), sempre depois dos quatro lados, e conta
  um passo, como o lado: o alcance de serviço e de armazém é de Chebyshev na diagonal. A carroça usa o
  `RoadRouter.DiagonalGrid` (AStarGrid2D com `DIAGONAL_MODE_ALWAYS`, heurística octil e `_compute_cost` que dá √2
  à diagonal pura e `BLOCKED_COST` às outras; `path` ainda descarta um caminho que passe por uma delas) e anda o
  passo diagonal √2 vezes mais devagar em índice de caminho (`RoadRouter.step_length`), para manter a velocidade.
- **Traçado** (`RoadPath.diagonal_path`): a escada diagonal enquanto sobram as duas distâncias e o resto em linha
  reta. Na ferramenta de estrada a tecla de girar (`build_rotate`) alterna entre o L e a diagonal; a dica diz qual
  está valendo e a tecla.
- **Desenho** (`RoadView`): entre duas células ligadas pela diagonal vai uma faixa (o ladrilho esticado √2 e girado
  45°, `diagonal_transform`) com os sulcos ao longo dela; a célula do meio da escada (`in_diagonal_run`) não leva
  ladrilho quadrado, que deixava a borda serrilhada; a da ponta leva os sulcos na diagonal (`Ruts.DIAGONAL_DOWN`
  e `DIAGONAL_UP`, 4 e 5 no shader). O meio-fio não sai nos lados que a faixa corta e o poste não vai na escada. A
  calçada dos pedestres estica a esquina pela meia-esquadria (`SidewalkPath.offset_polyline`): na de 45° a soma dos
  dois deslocamentos dava o ponto errado. Captura: `CAPTURA_SO=diagonal` no `tools/capture_buildings.tscn`.

### Detalhes de época (Fase 18, nossa)

- **Proposta nossa** (17/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede e dá para gerar no código, sem asset novo. Só visual; o save fica na
  versão 15. Partes com commit próprio.
- **Campanário e portão** (`BuildingKit`): a igreja ganha `BuildingDef.Silhouette.BELFRY` (no fim do enum):
  torre quadrada de `BELFRY_SIDE_M` no canto da frente à esquerda, saindo `BELFRY_OUT_M` das paredes, com
  cornija no beiral e no alto do fuste, sineira aberta de quatro pilares, o sino de bronze (`_bell`, perfil de
  `BELL_PROFILE` em `BELL_SEGMENTS` faces) pendurado numa trave e a agulha com a cruz de ferro; a cumeeira de
  quatro águas da igreja baixou (`SPIRE_SLOPE` 0,55) para a torre ser o ponto mais alto. As fábricas de fumaça
  pesada e as de lanternim ganham `Door.GATE`: o vão em arco com dois esteios, a verga e duas folhas de tábua
  entreabertas a `GATE_OPEN` (aberta de todo, a folha passava da área e entrava na rua). Cores novas da paleta
  do kit: `UV_TIMBER` (o madeiramento escuro), `UV_IRON` e `UV_BRONZE`. Captura: `CAPTURA_SO=epoca` no
  `tools/capture_buildings.tscn`.
- **Ornamento das casas** (`BuildingKit._ornament`, `_pediment`, `_railing`), dos artesãos para cima: cornija de
  pedra clara (`UV_LIGHT_STONE`) no alto das paredes, verga sobre cada janela e, nos engenheiros e investidores,
  a faixa entre os andares. A sacada troca a frente de madeira do kit por grade de ferro (corrimão, travessa e
  balaústres a cada `RAIL_STEP_M`) na frente e nas pontas. O frontão dos investidores fica no alto da fachada,
  sobre a porta: em cima do pórtico ele atravessava a sacada. Captura: `CAPTURA_SO=detalhes` (`21_frontao.png`).
- **Poste de gás** (`LampView.post_mesh`, gerado no código; o `lantern.glb` do kit saiu do projeto): pedestal,
  fuste de ferro fundido verde-escuro (`IRON_COLOR`) afinando, colar com a travessa de apoiar a escada do
  acendedor, assento, quatro montantes em volta do vidro aceso (o mesmo `glass_mesh`) e chapéu de quatro águas
  com remate, tudo em `LAMP_HEIGHT_M`. Captura: `CAPTURA_SO=postes`.
- **Arreio** (`CartView.harness_mesh`, uma instância por carroça na mesma transformação do corpo): os varais do
  kit acabam na anca do cavalo (`SHAFT_TIP`) e seguem até o ombro; colar de couro deitado com o pescoço
  (`COLLAR_TILT`: de pé parecia uma tábua sobre o cavalo) com as hastes de latão, tirante do colar ao varal,
  selote no lombo (`BACK_M`, medido no cavalo andando) e a correia descendo aos varais. Medidas a partir de
  `horse_offset()`, o mesmo lugar onde o cavalo é posto. Captura: `CAPTURA_SO=animais` no
  `tools/capture_phase3.tscn` (`09b_arreio.png`, de lado).

### Chão e margem (Fase 19, nossa)

- **Proposta nossa** e aceita pelo dono do produto (17/10/2026): o chão entre os prédios, pelas pendências
  do `assets/TODO_ASSETS.md` (terreno, estrada de terra, paralelepípedo, campo e pasto). Só visual; o save
  fica na versão 15. Partes com commit próprio.
- **Lama na margem** (`ArchipelagoGenerator.Surface.MUD`, canal azul do `surface_weights`): o leito do rio e
  `RIVER_BANK_CELLS` de margem (`near_river`), fora da praia, viram lama no `shaders/terrain.gdshader`: a
  textura de areia tingida de `mud_tint`, quase sem relevo e lisa, com a borda recortada pela altura da
  textura de rocha em escala larga. A areia da praia escurece e fica lisa até `wet_sand_m` acima do mar. A
  assinatura do terreno não muda (o tipo de chão é só desenho). Captura: `CAPTURA_SO=margem` no
  `tools/capture_phase5.tscn`.
- **Campo arado** (`CropView`, multimesh `Furrows`): uma leira de terra em telhado (`furrow_mesh`,
  `FURROW_HEIGHT_M`) por fileira da planta da fazenda, de ponta a ponta do campo, ocupando `FURROW_FILL` da
  fileira; a cor vai de `FRESH_SOIL` (úmida, logo depois de lavrar) a `DRY_SOIL` (seca, clara) com o ciclo
  da fazenda. Campo sem dono: leiras secas a cada `BARE_SPACING_M`. As leiras não têm alcance de
  visibilidade: o multimesh cobre todos os campos e o alcance contaria do centro dele (os campos longe do
  meio sumiam). Captura: `CAPTURA_SO=plantacoes` (`26_`, `27_` e `28_campo_sem_dono.png`).
- **Borda da estrada** (`RoadView`, `shaders/road.gdshader`): o ladrilho inclinado leva a torção da célula
  (`RoadView.twist`, em `INSTANCE_CUSTOM.a`) e o shader a soma nos vértices: o ladrilho passa pelos quatro
  cantos como o terreno, sem degrau entre células na ladeira. Na terra, os lados sem estrada vizinha
  (`open_edges`, bits de `SIDE_BITS` somados aos sulcos em `INSTANCE_CUSTOM.b` × `OPEN_SHIFT`) têm a borda
  recortada por um ruído ao longo do lado (no mundo, emenda entre células; a face de lado some junto), a terra
  esverdeia junto dela e `VERGE_TUFTS` touceiras de capim (`CropView.tuft_mesh`) crescem por lado aberto. A
  cor da instância entra na cor final da estrada: nada de dado nela. Captura: `CAPTURA_SO=estrada` no
  `tools/capture_phase5.tscn`.
- **Sarjeta e meio-fio**: no paralelepípedo, os lados abertos (os mesmos do meio-fio) levam a sarjeta no
  `road.gdshader`, uma canaleta de `gutter_width_m` junto do meio-fio, mais escura, lisa e com a normal
  pendendo para ele. O meio-fio troca a cor lisa por `shaders/curb.gdshader`: a textura do paralelepípedo
  quase sem cor, clareada, projetada pela face, com junta a cada `block_m`. A face de lado do ladrilho projeta
  a textura de lado (de cima ela esticava em listras). Captura: `CAPTURA_SO=postes` (`27b_sarjeta.png`).
- **Bichos andando** (`AnimalView.wander`, `advance`): o pacote da Quaternius só traz a animação parada e o
  pulo, então a caminhada é no código. A cada `WANDER_PERIOD_S` (± `PERIOD_VARIATION`) o bicho pasta no ponto
  da volta, vira em `TURN_S` e anda a `WALK_SPEED_M_S` até o ponto seguinte, subindo e descendo `STEP_BOB_M`;
  os pontos e a fase saem do hash do bicho e da volta (os mesmos depois de carregar), e o relógio é o da
  `AnimalView`, pela velocidade do jogo (para na pausa). Cada bicho anda no seu quarto do pasto (os quatro
  juntos no meio se atravessavam). O cão anda `DOG_PACE_M` para cada lado ao longo da frente da casa e
  descansa olhando para a rua. Captura: `CAPTURA_SO=animais` no `tools/capture_phase3.tscn`
  (`07b_ovelha_andando.png`).

### Corda e gravura (Fase 20, nossa)

- **Proposta nossa** (18/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede no porto, na estrada de terra, nos pássaros e na carta, tudo gerado no
  código. Só visual; o save fica na versão 15. Partes com commit próprio.
- **Amarras** (`HarborView._moor_lines`, `rope_span`, `rope_mesh`): cada barco do píer e do cais leva um cabo
  da proa e outro da popa até o cabeço mais perto do mesmo píer ou cais (até `ROPE_MAX_M`), caindo em
  parábola (`ROPE_SAG` do vão); os cabos são tubos de quatro faces de `ROPE_RADIUS_M`, todos numa malha só
  (`Ropes`). Captura: `CAPTURA_SO=porto` no `tools/capture_phase5.tscn` (`13b_amarras.png`).
- **Madeira e cordame** (`shaders/plank.gdshader`, `TraderPostModel.plank_material`, `_rigging`): veio ao
  longo da tábua e o tom de cada uma (pelo `INSTANCE_ID` na peça de uma tábua só), em metros da peça (a caixa
  esticada do multimesh tem o veio do mesmo tamanho); com `board_m`, as tábuas em pé e as frestas da parede
  do galpão e da porta. O convés e as estacas da feitoria e as tábuas e estacas do píer usam a mesma madeira.
  A feitoria ganha o cordame (`Rigging`): os estais do guindaste, a adriça e os estais do mastro da bandeira
  e as amarras dos dois barcos. Captura: `CAPTURA_SO=posto` no `tools/capture_phase6.tscn`.
- **Pedras soltas** (`RoadView.stone_spots`, `stone_mesh`, multimesh `Stones`): de zero a `STONES_MAX` seixos
  por célula de terra, pelo hash da célula, fora da faixa dos sulcos (`RUT_LANE_M`, `keep_off_ruts`) e longe
  da borda, no topo do ladrilho, afundados `STONE_SINK`; a cor de cada um varia em volta de `STONE_COLOR`. O
  paralelepípedo e a ponte não têm. Captura: `CAPTURA_SO=estrada` no `tools/capture_phase5.tscn` e
  `CAPTURA_SO=postes` no `tools/capture_buildings.tscn` (`26_estrada_de_terra.png`).
- **Asa batendo** (`shaders/bird.gdshader`, `BirdView.wing_beat`): a ponta da asa da malha do voo leva
  UV.x = 1 e o shader a gira em volta do corpo pelo ângulo que o BirdView põe em `INSTANCE_CUSTOM.r` a cada
  quadro (o relógio dos pássaros, que para na pausa). O pombo bate a `PIGEON_BEAT_HZ` e plana na descida; o
  estorninho bate em rajadas (`STARLING_BURST_S`, `FLAP_BURST`) e plana o resto. O corpo só inclina para
  dentro da volta (antes ele balançava de lado no lugar da asa). Captura: `CAPTURA_SO=postes` no
  `tools/capture_buildings.tscn` (`28c_asas.png`).
- **Carta gravada** (`ArchipelagoMap.engrave`, `coast_distance`): a carta passa a `ENGRAVE_SCALE` pixels
  por célula, e a distância com sinal até o litoral (chanfro de duas passadas, + no mar) dá o litoral a
  tinta, as linhas d'água em volta da costa (`WATERLINES`, cada uma mais fraca), a faixa rasa e a hachura
  em diagonal na terra junto do mar (`HATCH_REACH`), sumindo para dentro. Captura: `CAPTURA_SO=carta` no
  `tools/capture_phase6.tscn`.

### Gaivota e papel (Fase 21, nossa)

- **Proposta nossa** (18/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede nas gaivotas, no píer e no papel, tudo gerado no código. Só visual; o
  save fica na versão 15. Partes com commit próprio. (Os prédios tropicais já saíam caiados e com telha e os
  campos tropicais já tinham as plantas desde a Fase 14: a linha do TODO estava velha.)
- **Gaivotas batendo asa** (`BirdView.gull_mesh`, `gull_beat`; desenhadas pelo `ShipView`): corpo branco e
  asa longa dobrada no cotovelo (UV.x = 0,5, o shader do pássaro gira pela metade do ângulo) com a ponta preta
  (UV.x = 1); batem devagar (`GULL_BEAT_HZ`) por `GULL_FLAP` do ciclo de `GULL_CYCLE_S` e planam o resto, e
  o corpo só inclina para dentro da volta (antes ele balançava de lado). Captura: `CAPTURA_SO=porto` no
  `tools/capture_phase5.tscn` (`13c_gaivota.png` planando e `13d_gaivota_batendo.png`).
- **Nó no cabeço** (`HarborView.hitch`, `hitch_count`): cada amarra dá `HITCH_TURNS` voltas em hélice no fuste
  do cabeço, descendo `HITCH_PITCH_M` por volta, e sai dele do lado do barco (antes o cabo nascia no meio do
  ferro); o segundo cabo no mesmo cabeço dá as voltas dele logo abaixo. As voltas entram na malha `Ropes`.
  Captura: `CAPTURA_SO=porto` (`13b_amarras.png`).
- **Papel envelhecido** (`ui/theme/paper_grain.gd`, `PaperGrain`): as linhas do papel vergê (as finas a cada
  `LAID_PX`, cada uma com a força dela e falhando ao longo, e as de corrente a cada `CHAIN_PX`), manchas de
  ferrugem redondas e mais escuras na borda (uma no máximo por quadro de `FOX_CELL_PX`, pelo hash da semente) e
  a borda gasta recortada por ruído. O `ThemeBuilder.paper_image` passa cada pixel do papel por `age` e grava as
  cantoneiras gravadas (filete em anel em `CORNER_RING` e prego em `CORNER_NAIL`); mudou o grão, rode
  `tools/build_theme.gd`. A carta do arquipélago desenha a camada `PaperGrain.overlay` por cima
  (`ArchipelagoMap.grain`, `GRAIN_PX`, feita uma vez): na própria carta gravada o grão sumiria, porque ela é
  reduzida 3 a 5 vezes ao ser desenhada. Captura: `CAPTURA_SO=carta` no `tools/capture_phase6.tscn`.

### Mata e vento (Fase 22, nossa)

- **Proposta nossa** (19/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede nas árvores (espécies europeias de 1840, dois níveis de detalhe e balanço
  ao vento), tudo gerado no código, com o vento do clima por trás. Só visual; o save fica na versão 15. Partes
  com commit próprio. (As árvores já balançavam desde a Fase 9, num movimento fixo sem direção nem força.)
- **Vento** (`WeatherCycle`, `weather_wind_*` no `GameConfig`): cada dia sorteia para onde ele sopra e um fator
  de força, **depois** do resto do sorteio do dia (o céu de cada semente não mudou). A força vem do tipo do dia,
  sobe até `weather_wind_rain` com a chuva e cai `weather_wind_mist_calm` no auge da neblina; a direção vira até
  `weather_wind_veer_rad` ao longo do dia e troca para a do dia seguinte nas duas últimas horas, como a
  cobertura. O `WeatherView` publica os uniformes globais `wind_direction` e `wind_strength` e vira as bandeiras
  de mastro (`WindFlag`, grupo `wind_flags`: a da feitoria e as das rivais) a cada quadro, no relógio dele
  (`wind_time`, que para na pausa). Com o ar parado a bandeira cai por cisalhamento (a beira fica no mastro;
  girada, ela atravessava o mastro) e encolhe para `LIMP_WIDTH`. A fumaça das chaminés deita para o vento
  (`SmokeView.drift`, na gravidade das partículas) e sobe reta com o ar parado. Captura: `CAPTURA_SO=posto` no
  `tools/capture_phase6.tscn` (`04d_bandeira_ao_vento.png`).
- **Balanço pelo vento** (`shaders/foliage.gdshader`): a planta deita a favor do vento (`lean` × força, com um
  vaivém lento) e balança em volta disso mais forte e mais depressa quanto mais forte ele é (`hurry`); com o ar
  parado sobra a brisa (`calm`). A direção do vento entra no espaço do modelo pela inversa da `MODEL_MATRIX` (cada
  árvore vem girada). O mesmo shader, com `use_vertex_color` (a cor do vértice e da instância chegam em sRGB e
  são convertidas lá), passou para as plantações e o capim dos pastos (`CropView.plant_material`, `PLANT_SWAY`,
  `GRASS_SWAY`) e o capim da beira da estrada (`RoadView`); a cerca e as leiras continuam paradas. Captura:
  `CAPTURA_SO=plantacoes` no `tools/capture_buildings.tscn`.
- **Árvores de época** (`TreeModel`, no lugar das cinco árvores do Kenney, que saíram do projeto; pedras e
  palmeiras ficam): carvalho (tronco curto e grosso, quatro galhos abertos com uma massa de folhagem na ponta
  de cada um e a do alto; copa mais larga que alta), faia (tronco liso e cinzento, copa oval) e pinheiro-
  silvestre (tronco alto, marrom embaixo e avermelhado em cima, copa em massas achatadas só no último terço),
  duas variantes de cada pelo sorteio. A massa de folhagem é um icosaedro subdividido esticado, cada vértice
  amassado `CROWN_LUMP`, mais escuro embaixo (`CROWN_SHADE`), com a normal de bola; cada massa sorteia no
  gerador dela, então os dois níveis de detalhe têm as massas no mesmo lugar. Tudo numa superfície com a cor
  no vértice, no material da folhagem, já em metros (a `TreeView` não reescala: escala 1 vezes o sorteio de
  0,75 a 1,25). De 330 a 460 triângulos de perto (as do Kenney tinham de 50 a 230).
- **Dois níveis de detalhe** (`TreeModel.DETAIL_FAR`: a esfera sem subdividir, o tronco de quatro faces e
  sem galhos, ~100 triângulos): cada trecho tem a camada de perto até `NEAR_UNTIL_M` e a de longe (`...Far`,
  o mesmo buffer) daí até `VISIBLE_UNTIL_M`, pelo alcance de visibilidade do trecho. A captura de 260 m caiu
  de mais de 5 min para ~70 s no llvmpipe. Refazer o trecho tira os nós antigos da árvore antes do
  `queue_free` (o novo de mesmo nome ganhava nome gerado e perdia o "Far"). Captura: `CAPTURA_SO=mata` no
  `tools/capture_phase5.tscn` (borda da mata, morro de pinheiros e a mata na chuva; `CAPTURA_LONGE=1` também
  de 260 m e `CAPTURA_LONGE=so` só ela).

### Varanda e galpão (Fase 23, nossa)

- **Proposta nossa** (19/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede nos prédios de modelo e dá para gerar no código. Só visual; o save fica na
  versão 15. Partes com commit próprio.
- **Varanda da casa de engenho** (`BuildingDef.Silhouette.VERANDA`, no fim do enum, no canavial, no cafezal e
  na plantação de tabaco): a fileira da frente vira alpendre (`court_rows = 1`, como o pátio do mercado: a casa,
  a porta e as janelas recuam), com assoalho de tábuas a `VERANDA_DECK_M`, dois degraus de pedra diante da
  porta, esteios de madeira com mão-francesa em cada divisa de célula, a viga do beiral, guarda-corpo de
  balaústres de madeira (o `_railing` das sacadas, com cor, altura, balaústre e passo próprios) menos no vão da
  porta, e o telhado de uma água preso na parede entre os dois andares, abaixo das janelas de cima
  (`veranda_box`). Captura: `CAPTURA_SO=galpao` no `tools/capture_buildings.tscn`.
- **Plataforma de carga do armazém** (`Spec.dock`, só no armazém do interior: o entreposto tem o cais da
  `HarborView`): a fileira da frente vira plataforma de tijolo na altura da caçamba (`DOCK_M`), com tampo de
  tábuas, defensa de madeira e uma rampa de pedra com meio-fio em cada ponta (`dock_box`). A forma segue o
  nível do armazém (`Spec.level`, na chave da malha): no nível 1 ganha o alpendre de uma água em mãos-francesas
  de ferro e portas de carga em arco nas células alternadas do térreo da frente; no 2 (o que custa tijolo,
  `BuildingKit.brick`) as paredes passam a tijolo e o telhado a telha. **A `BuildingView` refaz o modelo quando
  a forma muda sem o prédio sair do lugar** (`building_state_changed` com a chave diferente, com andaime), e a
  `WindowLightsView` refaz os vidros do prédio de níveis. Captura: `CAPTURA_SO=galpao` (`45_armazens.png`,
  `45b_plataforma.png`).
- **Guindaste de porto** (`BuildingKit._crane`, no lugar das vigas em forca da Fase 13) no entreposto e no
  estaleiro: soco de pedra, mastro no canto de trás por fora da parede do lado, escora para a frente, a lança
  saindo do mastro a `CRANE_BOOM_FOOT` da altura e subindo até `CRANE_RISE_M` acima dele, com a ponta
  `CRANE_REACH_M` para fora (o caixote pende longe da parede), dois tirantes de ferro do topo à ponta, sarilho
  de manivela no pé (montantes, tambor de oito faces e manivelas), o cabo do tambor à ponta, o moitão e o
  caixote nas lingas (`crane_tip`, `crane_hook`). **O armazém com plataforma** troca o guindaste de coluna (que
  invadia o vizinho) pelo guincho de armazém (`_hoist`): a viga sai da fachada logo abaixo do beiral, sobre a
  porta, até `HOIST_OUT_M` além da frente da área (passa do alpendre), com a mão-francesa de ferro, e a janela
  de cima da porta vira a porta de carga do sótão (`hoist_tip`). Capturas: `48_guindaste.png`,
  `48b_sarilho.png` e `49_guincho.png` no `CAPTURA_SO=galpao`.

### Pedra e torno (Fase 24, nossa)

- **Proposta nossa** (20/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede em pedra e ornamento e dá para gerar no código. Só visual; o save fica na
  versão 15. Partes com commit próprio.
- **Ponte de pedra** (`RoadView._add_stone_bridge`): a rua de paralelepípedo sobre o rio deixa de ser de tábua
  (a de terra continua a ponte de madeira da Fase 14). O calçamento segue por cima, sem a marca de tábua no
  shader; parapeito de pedra com capeamento (`parapet_mesh`) nos lados que dão para o rio; um arco por célula
  (`arch_mesh`: as duas faces com a volta em meio círculo entre os meios pilares, o fecho a `ARCH_CROWN_M` do
  tabuleiro, o intradorso e as pontas), girado na direção da rua; e, nas duas pontas do arco, meio pilar com o
  talha-mar (`CUTWATER_M` para fora das faces) do nascimento até o leito. Tudo na pedra do meio-fio
  (`shaders/curb.gdshader`). Captura: `CAPTURA_SO=ponte_pedra` no `tools/capture_phase5.tscn`
  (`10b_ponte_de_pedra.png`, `11b_ponte_de_pedra_de_perto.png`).
- **Balaústre, consolo e peitoril** (`BuildingKit._balustrade`, `_baluster`, `_corbel`): a sacada dos
  investidores troca a grade de ferro pela balaustrada de pedra — soco, balaústres torneados a cada
  `BALUSTER_STEP_M` (o perfil `BALUSTER_PROFILE` girado em `BALUSTER_SIDES` faces) e corrimão largo; a dos
  engenheiros continua de ferro. Sob as duas, consolos de pedra em cada divisa de célula (a face de baixo num
  quarto de elipse, `CORBEL_M` abaixo do piso). E, junto com a verga da Fase 18, o peitoril de pedra debaixo de
  cada janela. Captura: `CAPTURA_SO=detalhes` no `tools/capture_buildings.tscn` (`21b_balaustrada.png`,
  `21c_consolos_e_peitoril.png`).
- **Poste com caneluras e volutas** (`LampView.fluted_shaft`, `volute_points`): o fuste do poste de ferro
  fundido da Fase 18 ganha `FLUTES` caneluras (a seção alterna o raio cheio e o fundo, `FLUTE_DEPTH`) e, sob a
  travessa da escada, duas volutas de ferro — um braço curvo do fuste até a ponta da travessa, enrolado na
  ponta. **O fuste é malha indexada de propósito**: o `SurfaceTool` do poste é indexado (os cilindros), e malha
  sem índice anexada a ele entra sem triângulo nenhum (o fuste sumia; o teste confere que ele é desenhado).
  Captura: `CAPTURA_SO=postes` no `tools/capture_buildings.tscn` (`14b_poste_de_perto.png`).

### Cantaria e moldura (Fase 25, nossa)

- **Proposta nossa** (24/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede em cantaria e dá para gerar no código. Só visual; o save fica na versão 15.
  Partes com commit próprio.
- **Guarnição das janelas** (`BuildingKit._window_frame`): nos engenheiros e investidores, cada janela com verga
  ganha as duas ombreiras de pedra de `JAMB_M` (do peitoril até encostar na verga, que fica meia altura dela acima
  do vão) e a pedra de fecho no meio da verga, `KEYSTONE_M` de alto e saindo mais da parede. Os artesãos ficam só
  com verga e peitoril. Captura: `CAPTURA_SO=detalhes` no `tools/capture_buildings.tscn` (`20_portico.png`,
  `21c_consolos_e_peitoril.png`).
- **Aduelas do arco** (`RoadView._voussoir`): a volta do arco da ponte de pedra leva `VOUSSOIRS` aduelas (ímpar,
  o fecho no alto) em cada face, de `VOUSSOIR_M` de fundo a partir do intradorso, saltadas `VOUSSOIR_PROUD_M`
  da face e com a junta de `VOUSSOIR_JOINT_RAD` entre elas; o fecho é reto em cima, sobe até o tabuleiro e salta
  o dobro. Captura: `CAPTURA_SO=ponte_pedra` no `tools/capture_phase5.tscn`.
- **Meio-fio chanfrado** (`RoadView.curb_mesh`, no lugar da `BoxMesh`): o mesmo bloco, com as duas quinas de cima
  gastas num chanfro de `CURB_CHAMFER_M`. A malha leva UV e tangentes (`_uv_face`, `generate_tangents`): o
  `shaders/curb.gdshader` usa o mapa de normais. Captura: `CAPTURA_SO=postes` no `tools/capture_buildings.tscn`
  (`27b_sarjeta.png`).

### Convés e cordame (Fase 26, nossa)

- **Proposta nossa** (24/10/2026), com a autorização permanente de seguir pela recomendação: o que o
  `assets/TODO_ASSETS.md` ainda pede nos navios (cordame e carga no convés) e no poste (capitel e base moldados),
  gerado no código. Só visual; o save fica na versão 15. Partes com commit próprio.
- **Cordame** (`ShipRigging`, chamado pelo `ShipView._model`): os navios do Kenney Pirate Kit vêm só com mastros,
  velas e bandeiras, e o cordame é lido do próprio modelo, no espaço dele (filho do nó `Hull`, que o ShipView
  estica e gira; o raio do cabo é `ROPE_RADIUS_M` dividido pela escala). O alto de cada mastro é a origem da
  bandeira dele (`mast_tops`, da proa para a popa); `SHROUDS` ovéns de cada lado de cada mastro, de
  `SHROUD_DROP` abaixo da bandeira até a borda, puxando para a popa; o estai do mastro de proa ao bico de proa
  (`bow_point`), um estai de cada mastro ao de vante (a `STAY_FOOT` da altura dele) e o brandal do último à popa.
  **A borda é o corte do casco** (`rail_at`: as arestas dos triângulos que atravessam o plano z do pé do cabo):
  o modelo tem poucos vértices, uma face comprida atravessa metros sem nenhum, e procurar vértice perto do pé
  achava zero na proa. Na abertura da amurada do meio do navio médio, a borda é a do próprio convés
  (`DECK_Y`). Os cabos vão no `HarborView.rope_mesh`, numa malha só (`Rigging`).
- **Carga no convés** (`ShipView.deck_goods`, `_update_deck`): uma peça do `CargoKit` por porão com carga, na forma
  de pilha do bem (o porco fica de fora), em duas filas a partir de `DECK_CARGO_AHEAD` à frente do mastro grande
  (o mais alto), no tamanho de verdade (a transformação desfaz a escala do modelo); um MultiMesh por tipo de peça
  no nó `DeckCargo`, refeito só quando os bens a bordo mudam. Captura: `tools/capture_ships.tscn` (carrega o
  mercante e o clíper; `03b_cordame_e_carga.png`, `03c_cliper_de_perto.png`). A mancha escura junto da escada do
  castelo de popa é a porta da cabine do modelo, não a carga.
- **Base e capitel torneados** (`LampView.lathe`, `BASE_PROFILE`, `CAPITAL_PROFILE`): o pedestal de três cilindros
  lisos vira o perfil girado em `LATHE_SIDES` faces — plinto chanfrado, toro, escócia, filete, o dado afinando, a
  cornija e o pescoço até o fuste — e o colar sob a travessa vira o capitel (astrágalo, equino e ábaco). Indexada,
  como o fuste da Fase 24. Captura: `CAPTURA_SO=postes` no `tools/capture_buildings.tscn`
  (`14b_poste_de_perto.png`).

### Contas do meio da partida (Fase 27, nossa)

- **Proposta nossa** (24/10/2026), com a autorização permanente de seguir pela recomendação: medir de onde vem o aperto
  de dinheiro do meio da partida, a pendência de balanceamento que sobrou. Nada muda na simulação nem no save.
- **Raio-x no relatório** (`tools/balance_report.gd`): além da linha do tempo, a manutenção por grupo (`upkeep_groups`:
  bens de consumo, intermediários, material de construção, serviços, logística e navios), a parte que vai para fábricas
  abaixo de 50% de produtividade e a renda por classe (`breakdown`), e as obras de cada intervalo por grupo, com as
  moedas (`new_works`). Campos e pastos contam com os intermediários.
- **Cadeia × imposto** (`tools/balance_math.gd`, `BalanceMath`): a manutenção da cadeia por tonelada, somando cada etapa,
  e por morador, com o consumo **dividido entre os bens da categoria** (seção 4; somar cada bem inteiro dava os
  operários e artesãos pagando menos que a cesta, o que não é verdade). A planilha das classes mostra as duas razões.
- **Robô junta para a obra da frente** (`AutoPlayer.SAVE_FRONT_AFTER_S`): esperando só dinheiro há 90 s, as obras de
  trás que não são urgentes esperam também. A fundição (portão do aço) esperava 45 min na frente.
- **Conclusão** (`docs/balanceamento.md`): os números estão sãos (cada classe paga a cesta de 1,5 a 3,4 vezes) e o meio
  da partida é lento, não quebrado; nenhum número dos dados mudou. As alavancas, se o dono do produto quiser o meio mais
  folgado, estão no fim do documento. **`tools/godot.sh planilha` imprime erros de compilação** de scripts que usam o
  `EventBus` (não existe pelo `--script`), mas grava os CSVs.

### Folga do meio da partida (Fase 28, nossa)

- **Decisão do dono do produto** (24/10/2026, "pode fazer tudo"): as quatro alavancas do diagnóstico da Fase 27, uma
  por vez, medidas com o robô. Comparação em `docs/balanceamento.md`. O save não muda (são números dos `.tres`).
- **Fábrica ociosa** (`GameConfig.idle_productivity`, `Simulation.is_idle`, `idle_upkeep`): produção não pausada abaixo
  de 50% de produtividade; a dica do saldo na barra soma quantas são e o custo por minuto, e o painel da fábrica pinta a
  manutenção de laranja com quanto ela pagaria pausada (`HUD_MONEY_IDLE`, `PANEL_UPKEEP_IDLE`).
- **Números nossos**: teatro 90 e universidade 150 moedas/min de manutenção; vidraria 1.500, janelaria, máquinas de
  costura e conservas 1.900, destilaria de rum 1.100 e fundição 1.200 moedas de construção (a tabela da especificação
  só traz a manutenção).
- **Imposto dos operários 1,4** (a especificação diz 1,2): é a única mudança num número da especificação, e o
  `test_tiers_follow_the_spec_table` registra a decisão. Resultado no robô: pior saldo −745 (antes −7.654), a
  fundição não espera mais na frente da fila, engenheiros aos ~120 min e investidores aos ~225.

### Fôlego da simulação (Fase 29, nossa)

- **Proposta nossa** (24/10/2026), com a autorização permanente de seguir pela recomendação: o tick médio do benchmark
  tinha passado do orçamento (4,22 ms contra 4,0) e a obra com a ilha cheia estava em 48 ms (limite 50). Só desempenho:
  nada muda no resultado da simulação nem no save. Registro em `docs/benchmark.md`.
- **Perfil do tick** (`Simulation.profiling`, `profile`, `_lap`): cada etapa do tick soma o tempo dela com o perfil
  ligado (desligado, um if por etapa); o benchmark mostra as etapas da mais pesada para a mais leve. O `_per_system` de
  antes chamava só sete sistemas, e a produção pela assinatura antiga (sem eventos e riscos, dava 0,04 ms).
  `-- --so-tick` no benchmark mede só o tick e a obra com a ilha cheia e sai (~1 min, só no terminal): é o laço de
  medida para otimizar.
- **População** (1,27 → 0,70 ms): a avaliação de uma casa só depende do `TierSupply` da classe na ilha e da cobertura
  de serviços dela, e fica guardada por cobertura dentro do tick (a mesma cobertura em ordem diferente só erra o
  cache); chegada, efeito de evento e felicidade do nível de imposto saíram do laço.
- **Logística** (1,28 → 0,91 ms): a fila das rampas ordena por uma chave inteira (`queued_at << 32 + home_id`) no sort
  nativo; a carroça em casa sem saída pronta, sem carga e sem entrada que caiba sai antes de montar o pedido; a
  velocidade da célula fica na carroça (`Cart.speed_at`, `speed`, fora do save) até ela mudar de célula, e volta a -1
  quando o caminho muda ou o estado derivado é refeito (a estrada pode ter sido calçada).
- **Produção e estaleiro** (0,91 → 0,77 ms): `ProductionEntry.shipyard` e `workforce_tier` guardados no estado
  derivado.
- **Buscas em largura das estradas** (`WarehouseField`, `RoadNetwork.components`, `ServiceReach.road_cells`): cada
  vizinha é lida uma vez, e os quatro cantos da diagonal pura (Fase 17) ficam de fora quando nenhuma dupla de vizinhas
  perpendiculares está livre (rua reta, cruzamento). Armazéns 16,0 → 9,7 ms; a obra com a ilha cheia ~41 ms.

### Transição e retorno visual (Fase 30, nossa)

- **Plano** em `docs/plano_fase30.md` (escrito noutra sessão a partir de um curso de Godot), confirmado pelo dono do
  produto em 24/10/2026. Só apresentação e interface: nada muda na simulação nem no save. As duas perguntas do plano
  ficaram com as propostas dele: o pulso a partir de 500 moedas ou 5% do saldo, e as animações seguem com o jogo
  pausado (são tweens de interface; a pausa é do `TickClock`).
- **Cortina** (autoload `SceneFader`, `core/scene_fader.gd`): `change_to(path, chave)` escurece em `FADE_S`, mostra o
  texto ("Gerando o arquipélago…", "Carregando…"), troca a cena, espera `SETTLE_FRAMES` (a cena nova entra no fim do
  quadro e monta tudo no `_ready` seguinte) e clareia; no meio, come mouse e teclado. `change_with(callable, chave)` é
  a cortina em volta de qualquer troca (o teste a usa sem trocar a cena do executor). **Direta** sem tela, com
  `SOCIETY_SEM_TRANSICAO=1` ou com `instant`: o `tools/godot.sh testes` (e, com ele, o CI) liga a variável, porque a
  suíte roda com tela no xvfb e os testes leem a cena logo depois de trocar. O benchmark continua direto.
- **Contadores da barra** (`Hud._count_money`, `_count_population`): andam até o valor novo em `COUNT_S` com
  `tween_method`, matando o anterior a cada `_refresh`; ganho de `BIG_GAIN` ou `BIG_GAIN_FRACTION` do saldo pulsa o
  dinheiro (`_pulse`: escala e `self_modulate` dourado, por cima da cor de estado do `UiPalette`). Com
  `SceneFader.is_instant()`, o texto vai direto.
- **Notificações** (`NotificationFeed`): aparecem e esmaecem em `FADE_S`; ao sair, a chave deixa `_items`, `_ages` e
  `_notices` na hora (o `shown()` e o limite não a veem) e só o desenho esmaece; o laço do limite procura o mais
  antigo entre os que ainda contam. O deslizar lateral do plano ficou de fora: o feed é um `VBoxContainer`, que manda
  na posição dos filhos.
- **Moedas no entreposto** (`MoneyFxView`, montada pelo `GameScreen` como `money_fx_view`): no
  `EventBus.trader_visited` com `earned > 0`, `COINS` moedas (cilindro dourado gerado no código) saltam em arco a
  `LIFT_M` acima das paredes do entreposto (`BuildingDef.height_m`: mais baixo, saltavam dentro do telhado) e o "+X"
  (`Label3D` em billboard, sem teste de profundidade) sobe e some. No máximo `MAX_EFFECTS` ao mesmo tempo, nós
  reaproveitados. A encomenda entregue não traz a ilha: aparece só no pulso da barra.

### Obra e combate (Fase 31, nossa)

- **Plano** em `docs/plano_fase31.md`: três das candidatas que a Fase 30 deixou, pela autorização permanente de seguir
  pela recomendação (25/10/2026). Só apresentação: nada muda na simulação nem no save. Como na Fase 30, tudo é direto
  com `SceneFader.is_instant()` (a suíte liga `SOCIETY_SEM_TRANSICAO`) e anda com o jogo pausado.
- **Obra** (`BuildingView._pop`, só no `building_placed`: o `rebuild` do carregamento e a casa que sobe de classe não
  pulam): o nó nasce com `BUILD_START_Y` de altura, passa do ponto (`BUILD_OVERSHOOT_Y`, afinando para
  `BUILD_OVERSHOOT_XZ`) e assenta em `BUILD_POP_S`, com poeira na base (`_dust`, a mesma nuvem do andaime da Fase 9).
  Mover um prédio dá as duas coisas: o velho afunda e o novo sobe.
- **Demolição** (`_sink`, no `building_removed`, também o prédio perdido no fogo): o nó sai de `_nodes` na hora
  (`building_count()` não o vê), perde o ocultador e o ícone e afunda a altura da malha mais o alicerce em `DEMOLISH_S`,
  com poeira, antes do `queue_free`. No máximo `MAX_DEMOLISHING` afundando (`demolishing_count()`); demolir uma rua
  inteira faz o resto sumir na hora. O `rebuild` apaga os que estiverem afundando.
- **Balas** (`ShipView._fire_salvo`, no `ship_fired` com o alvo desenhado): `BALLS_PER_SALVO` balas, uma a cada
  `BALL_STAGGER_S`, saem do costado do atacante e voam `BALL_FLIGHT_S` num arco de `BALL_ARC_M` até um ponto até
  `BALL_SHORT_M` antes do alvo na linha do tiro e até `BALL_SPREAD_M` para cada lado (com menos, caíam debaixo do casco
  da fragata e o respingo não aparecia). Pool de `MAX_BALLS` (`Ball`, classe interna).
- **Respingo** (`_build_splash`): coluna de espuma `one_shot` onde a bala cai, com `ABOVE_WATER` como o rastro (a água
  transparente apagava o que vem antes); no máximo `MAX_SPLASHES`.
- **Adernar** (`heel`): a bala que cai faz o alvo adernar para longe do tiro, `HEEL_RAD` × `exp(-t/HEEL_DECAY_S)` ×
  `sin(t·HEEL_HZ)`, somado ao balanço das ondas no `_process`. Com o cosseno ele começava no máximo e já estava quase
  no prumo meio segundo depois.
- **Zoom suave** (`CameraRig.zoom_toward`, `ease_zoom`, `target_distance`; `StrategyCamera._keep_under`): a roda anda o
  alvo e a distância vai até ele em `camera_zoom_seconds` (`GameConfig`, 0,12 s, validado), com o ponto do chão sob o
  cursor parado quadro a quadro; toques seguidos somam no alvo. `CameraRig.zoom()` continua direto e cancela o suave
  (testes, ferramentas, carregar). Nos testes a roda é direta.

### Medida e nitidez (Fase 32, nossa)

- **Plano** em `docs/plano_fase32.md`, a primeira fase do roteiro de `docs/plano_melhorias.md`; o dono do produto pediu
  para retomá-la em 25/10/2026. Só configuração e ferramentas: nada muda na simulação nem no save. **Fechada pelo dono
  do produto em 25/10/2026 com a medição no PC dele (RTX 5060, não a 3060)**, só em 1080p (tabela em
  `docs/benchmark.md`): Vulkan e D3D12 empatam e fica o Vulkan; o alto dá ~48 FPS (GPU ~20 ms por quadro, abaixo da
  meta de 60); o ultra trava (pior quadro de até ~2 s). Ficaram para depois: 4K, VSync desligado, o export com o shader
  baker e as nuvens volumétricas conferidas no olho.
- **No PC do dono (Windows)**: o Godot 4.7.2 fica em `F:\ferramentas\godot` em modo autocontido (`._sc_`, com os
  modelos de exportação em `editor_data/`), o clone em `F:\repos\society`, e o `Society.exe` sai pelo
  `--export-release "Windows"` do binário `_console`. **Nada grande vai para o disco C** (está quase cheio). O benchmark
  aberto pelo executável espera o Esc no fim: para automatizar, espere o `benchmark_quadros.json` de
  `%APPDATA%\Godot\app_userdata\Society\` mudar e feche o processo.
- **Teste dourado do terreno** (`tests/sim/test_terrain_golden.gd`): as assinaturas do v1 (semente 1840 e quatro
  arquipélagos pequenos) e da ilha plana (v0) gravadas como número. Falhou, o terreno que os saves refazem mudou: o
  gerador sem subir `VERSION`, um ajuste dos patamares no `GameConfig` (o v1 lê `terrace_levels_m` e
  `terrace_flat_fraction`) ou o motor (o `FastNoiseLite` ou o `hash()` na subida à 4.8). Mudança de propósito vira
  versão nova, com as assinaturas dela à parte.
- **Antisserrilhado** (`GraphicsPresetDef.screen_space_aa`, `temporal_native`, `fsr_sharpness`): FXAA no baixo, SMAA no
  médio e no alto, FSR 2.2 na resolução cheia no ultra (nitidez 0,2). O **MSAA saiu** de todos (trocá-lo em jogo recompila
  pipelines e ele não pega a borda do alpha). Com o FSR ligado (escala abaixo de 100% ou o ultra) o AA de tela desliga
  (`uses_temporal`, `screen_aa_for`); o `validate` recusa nível sem nenhum AA. Trocar o nível nas opções acontece atrás
  da cortina (`SceneFader.change_with`, "Aplicando os gráficos…").
- **Primeira vez atrás da cortina** (`WarmUp`): no `_ready` da `GameScreen` (jogo novo e carregar), um mundo de rascunho
  (`WarmUp.scratch`: ilha plana, um de cada prédio, uma casa por classe, rua de terra e calçada) desenhado pelas mesmas
  vistas da partida, encolhido a `SHRINK` na frente da câmera por `FRAMES` quadros, com o andaime e a poeira numa casa.
  **O rascunho é construído pelos comandos direto**, sem o `Simulation.execute` (que avisaria o `EventBus` e as vistas da
  partida receberiam ids de outro mundo), e cada vista de rascunho sai do `EventBus` logo depois do `setup`
  (`disconnect_from_bus`). A cortina espera o grupo `HOLD_GROUP` (até `SceneFader.MAX_HOLD_FRAMES`). Sem tela ou com
  `SOCIETY_SEM_WARMUP=1` (posto pelo `tools/godot.sh testes`) não roda. Montar o rascunho leva ~1,5 s na VM; as malhas
  dos prédios ficam no cache do `BuildingKit` e o primeiro prédio de cada tipo da partida sai mais rápido.
- **Caixa fixa** (`WorldBounds.of`): carroças, cavalos, pilhas de estoque e gaivotas, que mudam a cada quadro, levam o
  `MultiMesh.custom_aabb` do arquipélago inteiro (sem ela, cada atualização percorre as instâncias na CPU). **A caixa
  dos pedestres não cobria as ilhas tropicais** (parava em x = 2 regiões; elas ficam em x = 3): os pedestres de lá
  podiam sumir com a câmera olhando para elas. Agora usam a mesma caixa.
- **Benchmark** (`tools/benchmark.gd`, `FrameStats`): trajeto de câmera fixo, quadro bruto, CPU e GPU do viewport, tick
  por quadro, pipelines compiladas, p50/p95/p99 e lows de 1% e 0,1%, os quadros num JSON (`FRAMES_FORMAT`) ao lado do
  `.md`, `-- --todos-os-niveis` e a placa, o driver, a janela e o VSync no topo.
- **Export**: `shader_baker/enabled=true` no preset do Windows. O baker só roda com um renderer de verdade no editor:
  o export pelo `--headless` (CI, esta VM) sai sem ele, e o de release sai do editor, no Windows.

### Por cima do mundo (Fase 33, nossa)

- **Plano** em `docs/plano_fase33.md`, a segunda fase do roteiro de `docs/plano_melhorias.md`, começada em 25/10/2026
  com a confirmação do dono do produto. Só apresentação: nada muda na simulação nem no save.
- **Grade no chão** (`DebugOverlay`): duas passadas na mesma malha. As linhas ficam no `material_override`, sempre com
  teste de profundidade e só até `build_grid_radius_m` do cursor (`set_focus`, com fade nos últimos 45%); as células
  destacadas vão no `material_overlay` (raio-X, `show_lines` desligado). Antes, qualquer destaque (jazida, mata,
  alcance, camada do mapa) trocava a malha inteira para o raio-X e a grade da ilha toda aparecia sobre as copas.
- **Prévia com o prédio** (`BuildPreviewView`, `shaders/build_ghost.gdshader`): o fantasma é a malha do `BuildingKit`
  montada por um `BuildingRecord` de mentira (id 0, a primeira classe na casa; ao mover, o id, a classe e o nível do
  prédio de verdade), na rotação da ferramenta; a caixa fica para quem não tem modelo. Borda clara por fresnel, e
  **listras** quando não pode e na demolição (nada depende só da cor). `render_priority` 20, acima da água e da fumaça.
- **Ícones de estado** (`StatusIconRule`, `BuildingView.apply_icon_rule`, a cada quadro com a câmera): até
  `status_icon_full_m` cada um; mais longe, os de mesmo motivo no mesmo quadrado de `status_icon_cluster_m` viram um só
  (o de menor id), esmaecendo até `status_icon_min_alpha` em `status_icon_fade_end_m`. O prédio sob o cursor
  (`hovered_id`) e o selecionado sempre mostram; com uma camada do mapa ligada (`show_all_icons`), todos. O
  `_refresh_label` só esconde o que perdeu o motivo: quem aparece é da regra.

### Chão sem xadrez (Fase 34, nossa)

- **Plano** em `docs/plano_fase34.md`, começada em 25/10/2026 com a confirmação do dono do produto. Só apresentação:
  nenhuma altura nem assinatura muda (o `test_terrain_golden` segue passando).
- **Texturas de dados** (`TerrainBake.bake`, função pura): por ilha, das alturas do `region_corners`, uma RGBA8 de 2 em
  2 m com inclinação (r), curvatura (g, vale acima de 0,5, laplaciano a 4 m), distância da água por chanfro (b, satura
  em `terrain_water_distance_m`) e umidade (a). Escrita direto num `PackedByteArray`; a semente 1840 inteira (8 ilhas)
  assa em ~0,5 s no PC do dono.
- **Shader** (`shaders/terrain.gdshader`): bordas de areia, floresta e lama com ruído de 2 e 4 m e height-blend pelo
  alfa das texturas; macro-variação em 40, 150 e 500 m; grama seca nas cristas e verde junto da água, terra úmida nos
  vales (das texturas de dados); hex-tiling próprio (Mikkelsen, JCGT 2022) na grama e na floresta até
  `terrain_hex_distance_m`, só com `GraphicsPresetDef.terrain_hex_tiling` (**só no ultra**, decisão do dono do produto
  depois do benchmark; a `TerrainView` ouve o `settings_changed`); **reamostragem por distância** (de 60 a 320 m a textura se mistura com ela mesma 8× maior e o
  normal map aplaina: sem isso o xadrez de 12 m continuava a 420 m, onde o hex-tiling já não vale); triplanar na rocha
  só onde ela aparece.
- **Testes sem tela**: o `tests/world/test_phase34_ground.gd` confere o bake; o shader só compila com GPU, então quem o
  confere são as capturas (`tools/capture_phase5.tscn`, que no PC do dono roda com a janela fora do monitor,
  `--position -6000,0`).
- **Custo por efeito** (`tools/terrain_cost.tscn -- saida.md [shader_antigo]`): desenha só o terreno da semente 1840 a
  40, 120 e 300 m e mede a GPU do viewport com cada efeito desligado (`use_edge_noise`, `use_macro`, `use_far`,
  `use_triplanar`, `hex_tiling`) e, se passar o caminho, com outro `.gdshader`. Na RTX 5060: o shader novo custa
  ~0,5 ms a mais que o da Fase 33 de perto, quase tudo hex-tiling.
- **Benchmark: um número de FPS só vale repetido.** Na Fase 33 uma rodada deu o alto a 62 FPS e a repetição, 49.

### Costa viva (Fase 35, nossa)

- **Plano** em `docs/plano_fase35.md`, começada em 25/10/2026 com a confirmação do dono do produto. Só apresentação.
  **Feita sem tela**: o dono decidiu que nada abre no PC dele (nem captura, nem benchmark, nem janela fora do monitor,
  que o Windows trazia de volta); o visual espera ele liberar a tela, e a compilação dos shaders fica com o CI.
- **Distância até a costa com sinal** (`TerrainBake.signed_coast`): positiva na terra, negativa na água, linha d'água
  no meio entre os cantos, cortada em `coast_field_max_m`; chanfro em duas passadas (não EDT exata, erro de até ~10%
  fora dos eixos), dividindo a distância até a água com o bake da Fase 34 (`distance_to_water`). `CoastField.compose`
  junta as regiões num mapa do arquipélago (float, 2 m, mar fundo fora delas; `bounds()` com meio pixel de margem).
- **Água** (`shaders/water.gdshader`, `has_coast`, `WaterView.setup(simulation, coast)`): cor de plataforma no raso
  (`shelf_m`), bandas de espuma andando para a praia e espuma na linha d'água (`shore_foam_width_m`), ondas acalmadas no
  vértice (`wave_calm_m`). A espuma por profundidade do Boujie continua.
- **Terreno**: fundo raso pela distância da costa (sai o halo marrom), cáusticas, espraiado e areia molhada no mesmo
  ritmo da espuma (`shaders/coast_waves.gdshaderinc`: mesma fase, mesmo `TIME`) e linha de detritos acima do espraiado.
- **Ficou de fora** a suavização visual da linha d'água: precisa ser validada contra os portos, olhando a tela.
- **Shader com tela no CI**: `test_shaders_compile_with_the_coast_uniforms` confere os uniformes novos na lista do
  shader, que só existe se ele compilou; sem tela (dummy) a lista vem vazia e o teste pula.

### Encostas de pedra (Fase 36, nossa)

- **Plano** em `docs/plano_fase36.md`, começada em 25/10/2026 com a confirmação do dono do produto, feita sem tela.
- **Detalhe visual do relevo** (`TerrainDetail.offsets`, cache por ilha): deslocamento por canto só na malha (largura
  variável por ruído suave, sulcos por ruído ridged, pela inclinação). Um canto só se mexe se as 4 células dele forem
  terra, mais íngremes que `max_build_height_delta_m`, sem árvore (nem `cleared_trees`) e sem estrada nem prédio: toda
  célula protegida (`protected_cell`) tem os 4 cantos na altura da simulação. O anel de vizinhas do plano zerava o
  efeito (barrancos de 1 a 2 células) e saiu. A estrada vai até `max_road_relief_m` (2 m): estrada nova numa célula
  com detalhe faz a `TerrainView` (`_on_roads_changed`) chamar `TerrainDetail.zero_cell` e refazer só os trechos
  atingidos. O bake, a costa e o cursor seguem na altura da simulação; `shown_height` soma o detalhe.
- **Pedras** (`TreeView`): sem o recolorido verde-cinza, com a textura de rocha do terreno triplanar no mundo
  (`_stone`); chance de 25% nos barrancos acima de 2,5 m e de 35% no litoral rochoso (`rock_chance`), sentadas na malha
  com o detalhe (`ROCK_SINK_M`). A `TreeView.setup` recebe o config.
- Custo: ~0,13 s a mais no jogo novo (o `TerrainView.setup` da semente 1840 foi de ~1,9 para ~2,0 s no PC do dono).

### Luz e cor de época (Fase 37, nossa)

- **Plano** em `docs/plano_fase37.md`, começada em 25/10/2026 com a confirmação do dono do produto, feita sem tela: o
  visual novo fica atrás de uma opção desligada, para o dono comparar quando liberar a tela.
- **Cor de época** (`PeriodGrade`, `Settings.period_look`, Opções → Gráficos, "Cor de época"): LUT 3D de 33³ gerado no
  código (realces âmbar, sombras frias, verdes e azuis ~15% menos saturados, preto erguido) no
  `adjustment_color_correction`, e o AgX com `period_agx_white`/`period_agx_contrast`. Desligada, o `Environment` volta
  aos valores do motor (`GraphicsQuality._environment_defaults`).
- **SSR e PCSS só no ultra** (`GraphicsPresetDef.ssr`, `ssr_half_size`, `sun_angular_distance_deg`; o plano pedia também
  no alto, que já está abaixo dos 60 FPS). A meia resolução do SSR é global
  (`RenderingServer.environment_set_ssr_half_size`).
- **Luzes noturnas**: todas sem sombra; no pior caso 24 de área + 10 lampiões + incêndios + decals de fuligem, longe dos
  512 elementos por tela.
- **Para comparar**: `tools/capture_phase37.tscn` (ilha e litoral em quatro horas, com e sem a cor de época; precisa
  de GPU). Névoa aérea, sol, câmera e navios ficaram para uma rodada com tela (ver o plano).

### Estradas no chão (Fase 38, nossa)

- **Plano** em `docs/plano_fase38.md`, começada em 25/10/2026 com a confirmação do dono do produto, feita sem tela.
- **Máscara das estradas** (`world/terrain/road_mask.gd`, `RoadMask`): uma imagem RGBA8 por ilha com relevo, do tamanho
  da grade, a `road_mask_px_per_cell` (4) pixels por célula. r: distância (até `road_mask_max_m`) ao grafo de segmentos
  da terra (centro a centro, a diagonal pura a 45°, um segmento que arredonda o L, ponto na célula solta; o trecho entre
  dois paralelepípedos não entra); g: calçamento; b: chão batido das portas (`RoadMask.doors`); a: poças. Função pura
  do estado (nada no save); `refresh()` refaz só o retângulo do que mudou (estradas e portas) com `MARGIN_CELLS` de
  margem. A `TerrainView` agrupa os `roads_changed`, `building_placed` e `building_removed` e refaz uma vez no quadro
  seguinte (`flush_road_masks`). Custo: 6.000 células de estrada em ~0,25 s; uma estrada nova em ~2 ms.
- **Terreno** (`shaders/terrain.gdshader`): a terra batida (camada 0 das texturas das estradas) onde a distância fica
  abaixo de `road_half_width_m` mais o ruído de 1 e 4 m, misturada pela altura da grama; sulcos pela distância (somem
  depois de `road_rut_far_m`), capim pisado na beira, poças lisas e o chão batido das portas.
- **RoadView**: na ilha com relevo (`RoadMask.paints`) a terra não leva ladrilho (`painted_count`); ficam o
  paralelepípedo da ponte de pedra (o resto é da grade dual desde a Fase 46), as pontes, as touceiras e as pedras soltas (no chão). Na ilha plana tudo segue
  ladrilho. `GameConfig.road_paint` desligado volta o ladrilho (para comparar).

### Prédios assentados (Fase 39, nossa)

- **Plano** em `docs/plano_fase39.md`, começada em 26/10/2026 pelo pedido do dono do produto de fazer todas as fases que
  faltam. Só apresentação. **GPU sem tela**: o benchmark e as capturas rodam numa área de trabalho escondida do Windows
  (`F:\ferramentas\desktop_oculto.ps1 -Exe <godot _console> -Arguments "..."`; a lógica do `CreateDesktop` fica em C#,
  porque a estrutura montada no PowerShell dava erro 3). Os números assim só valem comparados entre si (ver
  `docs/benchmark.md`); a referência de antes da fase sai de um worktree no commit anterior (`F:\repos\society_base`).
- **Variação** (`BuildingKit.variation_hash`: id, tipo e rotação): nunca muda lote, porta nem andares. Cumeeira e beiral
  em três degraus (`RIDGE_SCALES`, `OVERHANGS_M`) pelo resto do id por 3 — casas em fila (ids seguidos) nunca ficam com
  o telhado na mesma altura —, chaminé no degrau do meio e lucarnas no alto (`lucarne_fits`: o telhadinho abaixo da
  cumeeira). Cada malha nova custa ~18 ms: 3 telhados × 3 degraus × 2 janelas por classe. O tipo que não é casa tira o
  beiral pelo tipo. Paletas (`BuildingView.palette_of`, quatro, a 0 é o tom de antes), a invertida (`inverted`,
  `trim_paint`) e um desvio de 1 cm e 0,5° no modelo: **proposta à espera do dono**.
- **Assentar**: o piso do prédio de modelo fica no canto mais alto do lote (`BuildingKit.seat`, `seat_lift`; a
  `WindowLightsView` e a prévia usam o mesmo). Plinto e degraus (`BuildingKit.plinth`, `steps_for`) só no lote em
  barranco, **todos numa malha só** (`BuildingView` nó `Plinths`, `plinth_of`, `rebuild_plinths` no quadro seguinte):
  como nó por prédio eram ~600 objetos a mais no benchmark.
- **Forma por tipo**: o entreposto é armazém (`Spec.storehouse`: empena na frente, portas de carga alternadas, as do
  sótão e o guincho); a casa de camponeses recua `YARD_SIDE_GAP_M` das divisas dos lados (`hall_side_gap_m`, só no
  `hall()`).
- **Shader do kit**: vidro e caixilho em cada janela (`_glazing`, célula (0, 1) da paleta, que o kit não usa; Fresnel com
  o céu), sombra de contato pela fachada (`instance uniform side_shade`, de `BuildingView.side_shade`, refeita nos
  vizinhos quando um prédio entra ou sai), musgo na faixa de baixo. **`return` no `fragment` não compila** (o renderer
  falso dos testes sem tela pega o erro: "Shader compilation failed" no log).
- **Capturas**: `tools/capture_phase39.tscn` (uma rua por classe, o entreposto e a casa no barranco, às 10h).

### Campos em colcha (Fase 40, nossa)

- **Plano** em `docs/plano_fase40.md`, começada em 26/10/2026. Só apresentação: o campo e o pasto seguem 3 × 3 na
  simulação. **A `BuildingView` não desenha mais caixa para módulo** (campo e pasto): a terra lavrada é da `CropView`, e
  o pasto é o capim do terreno com a cerca e as touceiras no chão.
- **Contorno** (`CropView.field_outline`, `border_inset`): recuo de `FIELD_INSET_M` a mais `FIELD_WIGGLE_M`, com ruído
  semeado pela linha da divisa (x ou z no mundo) e pela posição ao longo dela — os dois campos de uma divisa recuam
  igual. A terra de todos os campos numa malha só (`Soil`), em três anéis seguindo o terreno, normal para cima; os
  triângulos de cada campo, os lugares das plantas e das leiras ficam em cache pelo lote (`_soil_cache`,
  `_place_cache`, limpos no `world_replaced`): refazer a vista a cada obra custa ~7 ms para 39 campos (5,5 antes), a
  primeira vez ~27.
- **Fileiras** em x ou em z pela posição na grade de 3 células (`rows_along_x`: vizinhos alinhados sempre diferentes),
  cabeceira de `HEADLAND_M` com uma leira de través em cada ponta, plantas e leiras na altura do chão (a leira inclina
  com o terreno). Tom da terra e da planta por campo (`field_soil`, `field_shade`, pela cor da instância; o
  `INSTANCE_CUSTOM` ficou de fora).
- **Divisas** (`_add_borders`): sebe (`hedge_mesh`) ou, no lote com mais de `WALL_RELIEF_M` de desnível, muro de pedra seca
  (`wall_mesh`), uma vez por aresta de célula; sem peça na porteira (a célula da entrada), para outro pasto, para a
  água, entre campos da mesma fazenda (um cercado só) e entre o campo e a fazenda; nada nas ilhas tropicais. Sem sombra.
- **Trilhas no pasto** (`RoadMask.trails`, canal b): porteira → meio → um canto pelo id, refeitas com o pasto.
- **Medida**: `tools/fields_cost.tscn` monta um bairro rural, mede a `CropView`, o quadro, a GPU e as draw calls a 110 e
  420 m e fotografa (`docs/benchmark.md`). Sem tela, o MultiMesh devolve transformações zeradas: os testes leem os lugares
  das funções (`_furrow_places`, `_add_borders`), não do MultiMesh.

### Mata e recheio (Fase 41, nossa)

- **Plano** em `docs/plano_fase41.md`, começada em 26/10/2026 (41a e 41b juntas). Só apresentação.
- **Árvores**: normais da folhagem puxadas para a da copa inteira (`TreeModel.CROWN_ROUND`, o `hull` de cada espécie) e
  tufos pequenos (`_puffs`, só no nível de perto, depois de todas as massas: o sorteio do nível de longe não muda);
  `BACKLIGHT` no `foliage.gdshader` onde a cor puxa para o verde; histerese de `TreeView.LOD_MARGIN_M` nas margens do
  alcance. Folha recortada e impostor ficaram de fora (pedem arte e spike de GPU).
- **Recheio** (`ScatterView`, criada pela `GameScreen._build_ground` com as árvores): `places()` é função pura do mundo
  (por trecho de `CHUNK_CELLS`, com `island_context` das portas e dos tipos calculado uma vez por ilha); regras por
  vizinhança (`NEAR_HOUSE`, `NEAR_WORKS`, `NEAR_FOREST`, `NEAR_ROAD`, `NEAR_SEA`, `OPEN`); MultiMesh por trecho e peça
  até `VISIBLE_UNTIL_M`; refaz só os trechos marcados (obra pela área; demolição pela diferença da ocupação; estrada pela
  diferença das linhas; árvores pela área). Ao carregar segue o `simulation.world`; não refaz duas vezes no mesmo quadro.
  O laço por célula indexa os arrays direto (0,75 → 0,45 s no arquipélago da semente 1840).

### Quadro estável e carregamento real (Fase 42, nossa)

- **Plano** em `docs/plano_fase42.md`, começada em 26/10/2026. Nada muda na simulação nem no save.
- **`ArchipelagoJob`** (`sim/world/archipelago_job.gd`): uma tarefa do `WorkerThreadPool` por ilha, montagem na thread
  principal por `ArchipelagoGenerator.assemble` (o `new_world` usa a mesma); idêntico ao caminho direto com qualquer
  número de threads (teste). `IslandSpec` é classe interna do gerador (`ArchipelagoGenerator.IslandSpec`).
- **Cortina** (`SceneFader.change_with_job`): porcentagem, barra (`progress_bar()`), dica (`LOADING_TIP_1` a
  `SceneFader.TIPS`, `tip_label()`) e "Montando a partida…" (`LOADING_BUILDING`); direta sem tela. O menu
  (`BootScreen._start`) gera o jogo novo pelo job e entrega `GameScreen.prepared_world` (usado uma vez e zerado); sem
  ele a partida gera síncrona, como antes (testes, ferramentas, benchmark).
- **Benchmark**: a linha "gerar o arquipélago: em série / em threads (pior quadro durante)" (semente 1840: ~980 / ~430
  ms, pior quadro ~15 ms com 16 núcleos). Montar as vistas (~5 s) segue na thread principal: ficou de fora.

### Interface enxuta (Fase 43, nossa)

- **Plano** em `docs/plano_fase43.md`, começada em 26/10/2026. Nada na simulação nem no save.
- **Contraste**: teste WCAG com a luminância relativa de verdade (`srgb_to_linear`; o `Color.get_luminance()` do Godot
  não lineariza e dá números errados). Indicadores escurecidos (`UiPalette.STATUS_*`) e `UiPalette.FOCUS` no contorno do
  foco. Mudou o `ThemeBuilder`, rode `tools/build_theme.gd` (o `society_theme.tres` é gravado).
- **Fontes**: Playfair só em TitleLabel, BigLabel e PeriodTitle; HeaderLabel e MenuButtonLarge na Old Standard Bold;
  `NumberLabel` (algarismos tabulares) no dinheiro e na população; variações PlainCard e MedallionButton.
- **Settings** novos: `reduce_motion` (`SceneFader.still()` no lugar de `is_instant()` nas animações de interface e de
  obra e no zoom suave), `readable_font` (troca o `default_font` do Theme do projeto por uma `SystemFont`),
  `notice_duration` (`Settings.notice_seconds()`), `muted_notices` e `pause_on_alert`; escala até 200%
  (`ui_scale_max`) com o aviso de texto pequeno (`OptionsDialog.small_text`). A escala aplicada é
  `Settings.effective_ui_scale(largura)`: a HUD pede `UI_LOGICAL_WIDTH` (1.920) px lógicos, então 200% só vale a partir
  de 4K (em 1080p fica em 100%, com o aviso `OptionsDialog.limited`); refeita quando a janela muda de tamanho.
  Capturas: `tools/capture_phase43.tscn` (a HUD em 80/100/150/200% na resolução da janela).
- **Avisos**: categoria pela chave (`NotificationFeed.category_of`, `CATEGORIES`), contador "×N" na repetição
  (`count_of`), silenciar por categoria, pausa num alerta grave.
- **Menu de construção**: os cartões num painel próprio (`BuildItems`) do tamanho deles (`ITEMS_PER_ROW`); a aba de
  produção escolhida mostra o nome da classe.
- **`UiSfx`** (autoload): o clique e o toque ao passar o mouse em todo botão de qualquer tela; a `SoundEffects` não liga
  mais o clique dos botões.

### Primeira tela (Fase 44, nossa)

- **Plano** em `docs/plano_fase44.md`, começada em 26/10/2026.
- **`ArchipelagoPreview`** (`ui/screens/archipelago_preview.gd`): o mundo da semente pelo `new_world` da partida e a
  carta gravada (`ArchipelagoMap.engrave(chart, escala)`, a escala virou parâmetro) numa tarefa do `WorkerThreadPool`;
  `cancel()` descarta, `poll()` recolhe; quem sai da tela com uma no meio passa para `adopt()`, e o `SceneFader._process`
  chama `reap()`. ~1,7 s (médio, escala 1).
- **Jogo novo**: a carta ao lado das opções, refeita `PREVIEW_DELAY_S` depois de trocar semente ou tamanho
  (`start_preview`, `current_preview`).
- **Menu**: `MenuBackground` sem a grade, com a carta gravada da semente 1840 (escala cheia, numa thread, deriva lenta,
  parada com `SceneFader.still()`); os botões entram esmaecendo. `UiSfx.end_of_game` toca no `VictoryDialog`.
- **Capturas**: `tools/capture_phase44.tscn`.

### Ilhas novas (Fase 45, nossa)

- **Plano** em `docs/plano_fase45.md`, começada em 26/10/2026. **O v1 é congelado e continua o padrão**
  (`GameConfig.new_game_terrain_version = 1`) até o dono aprovar o v2; o diálogo de jogo novo já deixa escolher
  ("Orgânicas (experimental)", `NewGameDialog.chosen_terrain`, `GameScreen.terrain_version`).
- **Versões**: `ArchipelagoGenerator.VERSION` (1) e `VERSION_V2` (2), `VERSIONS` aceitas no save; `build_island`,
  `new_world`, `assemble`, `ArchipelagoJob` e `ArchipelagoPreview` recebem a versão. Teste que gera terreno do v1 pede a
  versão 1 explicitamente (o padrão pode mudar).
- **v2** (`_heights_v2`, `height_at_v2`, `lobes_v2`, `NoisesV2`, `Lobe`, `_limit_steps`; parâmetros em `TerrainV2Params`,
  `data/terrain_v2.tres`): elipses em volta do meio enquadradas até `shore`, warp em dois níveis, costa fractal,
  ilhotas, bancos de areia, borda da grade sempre mar (`EDGE_SEA`), patamares por região de Voronoi com a leitura torcida
  (`PLATEAU_BEND_M`), planície do litoral até uma borda irregular, ondulação, degrau máximo entre cantos. No v2 a jazida
  sem lugar plano aplaina o lote menos acidentado (`_place_deposits(..., flatten)`; o sorteio do v1 é o mesmo).
- **Teste dourado**: as assinaturas do v2 (`V2_SEED_1840`, `V2_SMALL`) são provisórias até a aprovação; mudar um número
  do `TerrainV2Params` muda o terreno dos saves v2.
- **Igual em toda plataforma**: no caminho das alturas do v2, nada de `sin`, `cos`, `pow`, `exp`, `log` nem `rotated`
  (a biblioteca do sistema erra o último bit diferente no Windows e no Linux, e a assinatura é o hash das alturas cruas):
  use `DetMath` (`sim/world/det_math.gd`) e a tabela `_rise`. Conferir no Linux: Godot de Linux no WSL
  (`F:\ferramentas\godot_linux`), num worktree próprio (o cache de importação não se mistura).
- **Capturas**: `tools/capture_phase45.tscn` (v1 e v2 lado a lado e as cartas).

### Calçamento e esquinas (Fase 46, nossa)

- **Plano** em `docs/plano_fase46.md`, começada em 26/10/2026. Grade dual (plano A); a escolha contra o grafo e as peças
  esperam a aprovação do dono pelas capturas.
- **`PavedDual`** (`presentation/paved_dual.gd`): máscara de 4 bits por canto (`mask_at`, bits em `AROUND`),
  `case_of` → peça (`Piece`: vazio, canto de fora, borda, sela, canto de dentro, cheio) e giro; sela vira faixa só se
  `RoadNetwork.linked_diagonal` liga as duas (`saddle_linked`); canto de fora de célula ligada na diagonal ao lado vira
  chanfro (`in_side_diagonal`, `_chamfer`), senão arredonda (`ROUND`). Meio-fio e sarjeta dentro da peça;
  `corner_geometry` devolve [vértices, cores, normais] no mundo; `build_mesh` só junta. Ponte de pedra conta como
  calçada (`paved_for_dual`). Shader `shaders/paved_dual.gdshader` (a cor do vértice escolhe a pedra).
- **RoadView**: o paralelepípedo fora da ponte saiu do MultiMesh (sem ladrilho, sem meio-fio, sem faixa diagonal);
  `_rebuild_dual` refaz só os cantos em volta da diferença das estradas (folga de -1 a 2 células: o chanfro olha duas
  adiante) em trechos de `DUAL_CHUNK` (`Paved_<ilha>/Chunk_x_y`); `dual_mesh`, `dual_corner_count`, `dual_corners_rebuilt`.
- **Benchmark**: a linha "calçar as ruas da cidade" (no fim, sem mexer nas outras) mede calçar tudo, mais uma rua e o
  quadro com o calçamento.
- **Capturas**: `tools/capture_phase46.tscn` (roda igual numa cópia anterior, para o antes e depois).

### QoL de interface (Fase 47, nossa)

- **Plano** em `docs/plano_fase47.md`, começada em 26/10/2026. Sem campo novo no save (nome e grupo da rota: Fase 49).
- **Copiar**: `BuildTool.copy_building` (tipo, rotação; `copy_paused` e `copy_upgrade_blocked` vão para cada cópia pelos
  comandos de sempre; qualquer obra nova zera `copying`). Botão em todo prédio; ação `build_copy`.
- **Busca**: `Hud.search`, `search_results`, `folded` (sem acento e maiúscula), campo `BuildSearch`; ação `build_search`.
  `SelectionPanel.same_kind` e `next_same` ("Próximo igual"); a dica do cartão diz quantos existem.
- **Estatística e produtores**: `SelectionPanel.statistics_requested` → `StatisticsWindow.show_good`;
  `StatisticsWindow.producer_requested` → `Hud.next_producer`.
- **Decompor**: `Breakdown` (`sim/breakdown.gd`, só leitura, sob demanda): `good(world, data, derived, ilha, bem)` e
  `money(...)`, parcelas `Source` (tipo, id, quantos, por minuto) que fecham exatamente com a tela. `BreakdownLabel`
  monta a dica no hover (`_make_custom_tooltip`); `text_of` é estático para os testes.
- **Rotas**: `RouteWindow.duplicate_route`, `add_order(parada, cheia)` (Shift), `slot_tons`, `hover_route` →
  `ArchipelagoMap.hover_route_id`, filtro `RouteFilter` em `Settings.route_filter`.
- **Modo foto**: `PhotoMode` (`GameScreen.photo_mode`): HUD e ícones (`BuildingView.hide_icons`) escondidos, pausa,
  ferramenta e seletor de navio sem input; hora (`set_hour`, só o deslocamento visual) e `CameraRig.pitch_offset_deg`
  (`PITCH_RANGE_DEG`); `MENU_PHOTO` no menu da partida; ação `photo_mode`. Os três atalhos novos nascem sem tecla.
- **Benchmark**: a linha "dica que decompõe" mede o pior caso no hover.
- **Capturas**: `tools/capture_phase47.tscn`.

### Godot 4.8 (Fase 48, nossa)

- **Plano** em `docs/plano_fase48.md`. A 4.8 estável não saiu (26/10/2026); o ensaio com a 4.8-beta1 está no ramo
  `godot-4.8` (sem merge), com a beta em `F:\ferramentas\godot48` e o worktree em `F:\repos\society_48`. Os nomes das
  opções novas estão na tabela do plano.
- **No `main`**: o pan pela borda só vale depois de um movimento real do mouse (`StrategyCamera.mouse_seen`; o xvfb e a
  área de trabalho escondida liam o mouse num canto); filtro de nós que podem ter sido liberados usa parâmetro `Variant`
  (a 4.8 recusa objeto liberado em parâmetro tipado).

### Desfazer e planta (Fase 49, nossa)

- **Plano** em `docs/plano_fase49.md`, começada em 26/10/2026. **Save na versão 16** (`SaveMigrations.from_15_to_16`:
  `plans` vazio, `next_plan_id` 1).
- **Desfazer**: `Simulation.execute_undoable` (a ferramenta usa sempre), `undo_last`, `redo_last`, `undo` (`UndoHistory`,
  fora do save, zerado no setter de `world`). `UndoHistory.Entry` guarda dinheiro e estoque (antes e depois), estradas,
  árvores e `cleared_trees` do retângulo (`area_of`), prédios criados e tirados (o registro) e as plantas;
  `UndoCommand` volta (exato no mesmo tick, diferença depois). `GameConfig.undo_window_s` e `undo_max_entries`. Comando
  novo que deva entrar no histórico: um caso em `UndoHistory.area_of` e `_island_of`.
- **Plantas**: `PlanRecord`, `WorldState.plans`, `PlacePlanCommand`, `RemovePlansCommand`, `BuildPlansCommand`,
  `CommandResult.plans_changed` → `EventBus.plans_changed`; `PlanView` (`GameScreen.plan_view`). A planta não reserva
  a célula.
- **Substituir**: `ReplaceCommand` (Ctrl+arrastar na obra, `BuildTool.replace_drag`).
- **Rotas**: `TradeRoute.name` e `group` (no save), `RenameRouteCommand`, `RouteWindow.display_name` e `ordered`.
- **Teclas**: `InputActions.CTRL_KEYS` (`game_undo` Ctrl+Z, `game_redo` Ctrl+Shift+Z e Ctrl+Y, fixas); `build_plan` sem
  tecla.

### Kit de época (Fase 50, nossa)

- **Plano** em `docs/plano_fase50.md`. O caminho está pronto; a arte é do dono (`assets/TODO_ASSETS.md`, seção da Fase 50).
- **Regras**: `AssetRules` (`tools/import/asset_rules.gd`): orçamento por categoria, uma malha, nó `Front` em −Z, pivô no
  centro do lote e no chão, tamanho no lote, LOD na importação, nome pelo id do prédio, crédito. `validate_assets.tscn`
  confere `assets/kit` (também no CI).
- **Gancho**: `BuildingKit.kit_root`, `asset_path`, `asset_mesh`, `Spec.asset`: a peça `<prédio>[_<classe>].glb` entra no
  lugar da forma procedural em `BuildingKit.mesh`; `forget_assets` nos testes.

### Fotos e retratos nos menus (Fase 51, nossa)

- **Plano** em `docs/plano_fase51.md`. Ideias de apresentação do Anno 1800, nenhum arquivo dele.
- **Fotos**: `tools/bake_building_photos.tscn` fotografa os nossos modelos (`ui/photos/building_<id>.png`,
  `house_<classe>.png`, 320 × 240) com o acabamento de `PhotoGrade` (`ui/photo_grade.gd`); `Icons.photo(prédio, classe)`,
  null sem foto (cai no ícone). Prédio novo: refazer as fotos.
- **Retratos**: pinturas CC0 do Art Institute of Chicago (`assets/source/portraits/aic_<id>.jpg`), recortadas por
  `tools/build_portraits.gd` em `ui/portraits/`; crédito de cada obra no `CREDITS.md`. O `build_icons.gd` não gera mais
  retratos.
- **Interface**: cartões do menu com a foto (`Hud.PHOTO_CARD_HEIGHT`); faixa `Photo` no topo do painel do selecionado.

### Ilhas no jeito do Anno (Fase 52, nossa)

- **Plano** em `docs/plano_fase52.md`. O Anno 1800 do dono foi só olhado (capturas fora do repositório); nada de
  engenharia reversa nem arquivo dele.
- **Gerador v3** (`terrain_version = 3`, padrão dos jogos novos até a Fase 93, que trouxe o v4 com porto em toda ilha): `ArchipelagoGenerator.shape_v3` (espinha curva,
  penínsulas, enseadas, rochedos) e `height_at_v3`; parâmetros em `TerrainV3Params` (herda do `TerrainV2Params`, pega por
  `TerrainV3Params.get_v3()`). Faixas da costa em células. Mudou um número dali, regrave as assinaturas do v3 no
  `test_terrain_golden.gd` (pegue os valores dentro do gdUnit: o modo `--script` não carrega os autoloads e os perfis
  das ilhas podem sair diferentes).
- **Plataforma desenhada** no v3 pela distância até a terra (`_distance_to_land`), não pelo quadrado do v1.

### Cor no jeito do Anno (Fase 53, nossa)

- **Plano** em `docs/plano_fase53.md`. Tratamento de cor no `terrain.gdshader` (`grass_grade`, `grass_saturation`,
  `dry_strength`, `forest_grade`, `sand_grade`, `rock_grade`), folhas do `TreeModel`, água turquesa no `WaterView`
  (`color_shelf`, `shelf_m`, `color_deep`) e névoa mais leve no `GameConfig`. No v3 não se desenha praia acima de
  `ArchipelagoGenerator.CLIFF_SAND_MAX_M`.

### Costa lisa (Fase 54, nossa)

- **Plano** em `docs/plano_fase54.md`. `TerrainBake.signed_coast` parte de onde a altura cruza o zero (não mais do meio
  da célula; a assinatura perdeu o `to_water`); `TerrainView._chunk_mesh` divide cada quadrado pela diagonal de menor
  diferença de altura; a praia do `terrain.gdshader` sai do `coast_distance` (`beach_m`, `beach_top_m`), sem rocha nem
  falésia. Só apresentação: as assinaturas do terreno não mudam.

### Malha fina na linha d'água (Fase 55, nossa)

- **Plano** em `docs/plano_fase55.md`. `CoastRefine` (`world/terrain/coast_refine.gd`): o quadrado da malha que a linha
  d'água atravessa vira subgrade de `terrain_coast_subdivisions` (3) de lado, com alturas por Catmull-Rom limitadas aos
  cantos que pesam e a `terrain_coast_refine_max_m` (0,8 m) da reta; os cantos da grade não mudam, a borda comum sai da
  mesma conta dos dois lados e a borda com quadrado comum fica na reta dele. Só apresentação.

### Rocha nos rochedos e nas falésias (Fase 56, nossa)

- **Plano** em `docs/plano_fase56.md`. `RockModel` (`presentation/rock_model.gd`): rocha gerada no código (icosfera com
  ruído, planos de corte e topo cortado, faces chapadas, 4 variantes). `RockView` (`presentation/rock_view.gd`, montada
  pela `GameScreen`): pelas alturas desenhadas (`TerrainView.region_heights`), bloco e pilar em cada rochedo solto no
  mar e rochas encaixadas na face das falésias, com o topo abaixo da borda e nunca onde caberia estrada ou prédio
  (`RockView.places` é função pura). Só apresentação.

### Pedras soltas com a rocha gerada (Fase 57, nossa)

- **Plano** em `docs/plano_fase57.md`. As pedras soltas da `TreeView` (barrancos e litoral rochoso, Fase 36) usam as
  quatro formas da `RockModel` com o material da `RockView` (`TreeView._stone`), raio de 1 m e 1,25 vez mais altas que
  largas (`ROCK_SIZE_M`, `ROCK_TALL`), nos mesmos lugares e chances de antes. Os `.glb` das pedras do Kenney saíram.
  Só apresentação.

### Coqueiro gerado no código (Fase 58, nossa)

- **Plano** em `docs/plano_fase58.md`. `TreeModel.Species.COCONUT_PALM`: tronco curvo em gomos com anéis, coroa de
  folhas que sobem e caem com folíolos em serra, dobradas em V, e cocos; malha de longe. A `TreeView` desenha três
  variantes nas ilhas tropicais, perto e longe. A pasta `assets/models/nature/` (Kenney Nature Kit) saiu. Só
  apresentação.

### Mata tropical (Fase 59, nossa)

- **Plano** em `docs/plano_fase59.md`. `TreeModel.Species.TROPICAL_BROADLEAF`: tronco nu com sapopemas e copa em
  guarda-chuva; malha de longe. Na ilha tropical a `TreeView` sorteia coqueiro ou folhosa pela altura do terreno (80% de
  coqueiro abaixo de `PALM_HEIGHT_M`, 30% acima); camadas `Tropical<n>` e `tropical_count`. Só apresentação.

### Sub-bosque tropical (Fase 60, nossa)

- **Plano** em `docs/plano_fase60.md`. `ScatterView.Kind.BANANA` e `Kind.FERN` (bananeira e samambaia, geradas no
  código): na ilha tropical o arbusto do recheio vira uma delas (`BANANA_SHARE`); o contexto da ilha diz se ela é
  tropical. As temperadas ficam iguais. Só apresentação.

### Helicônias (Fase 61, nossa)

- **Plano** em `docs/plano_fase61.md`. `ScatterView.Kind.HELICONIA` (gerada no código, brácteas vermelhas de ponta
  amarela no vértice): na ilha tropical as flores do campo do recheio viram helicônia. Só apresentação.

### Malha fina na face da falésia (Fase 62, nossa)

- **Plano** em `docs/plano_fase62.md`. `CoastRefine.steep`/`refines`: o quadrado seco com desnível de
  `terrain_cliff_refine_relief_m` (2,4 m, sempre acima de `max_road_relief_m`) também vira a subgrade da Fase 55; os
  pontos novos acima d'água ganham aspereza de rocha (`terrain_cliff_rough_m`) pelo desnível dos cantos, e a normal
  pela subgrade. Cantos, bordas e linha d'água como na Fase 55. Só apresentação.

### Jornal (Fase 63, nossa)

- **Plano** em `docs/plano_fase63.md`. `HeadlineDef` (`data/headlines/`, notícia e propaganda), `NewspaperSystem`
  (edição a cada `newspaper_interval_s`, manchete pela semente e pelo número da edição, felicidade em todas as ilhas
  pelo `EventEffects.happiness`) e `BuyPropagandaCommand` (uma vez por edição, `newspaper_propaganda_cost`). Só com os
  eventos ligados; vai no `EventsState` (save antigo sem as chaves carrega sem edição). Na tela, no alto da janela das
  encomendas (J), e aviso a cada edição.

### Baleias e golfinhos (Fase 64, nossa)

- **Plano** em `docs/plano_fase64.md`. `MarineLifeView` (montada com a água): baleias no mar aberto e bandos de
  golfinhos em águas médias, pelo `CoastField` e pela semente, malhas geradas no código; a baleia sobe, sopra e
  mergulha com a cauda erguida, o golfinho salta em arco (`whale_pose`, `dolphin_pose`, no tempo de jogo). Só
  apresentação.

### Festa na cidade (Fase 65, nossa)

- **Plano** em `docs/plano_fase65.md`. `FestivalView`: com o evento `festival` numa ilha, mastro na porta de cada
  praça (chafariz, coreto, mercado; sem nenhum, o entreposto) e cordas de bandeirolas só por cima da rua
  (`strings_of`); fogos de artifício à noite sobre os mastros. Some quando a festa acaba. Só apresentação.

### Prefeitura e políticas (Fase 66, nossa)

- **Plano** em `docs/plano_fase66.md`. Prédio `town_hall` (`BuildingDef.policy_radius_cells`), `PolicyDef`
  (`data/policies/`: velocidade da produção, chance de incêndio, felicidade, imposto), `SetPolicyCommand` e
  `BuildingRecord.policy` no save. `DerivedState._apply_policies` soma os efeitos por prédio no raio (a mesma política
  uma vez) e a manutenção; produção, riscos e população leem `policy_speed`, `policy_fire`, `policy_happiness` e
  `policy_tax`. Painel com um botão por política.

### Zoológico e museu (Fase 67, nossa)

- **Plano** em `docs/plano_fase67.md`. Prédios `zoo` e `museum` (`BuildingDef.exhibit_slots`, `exhibit_kind`),
  `ExhibitDef` (`data/exhibits/`: seis animais, seis objetos), `PlaceExhibitCommand` (compra e põe; a guardada de
  graça) e `ExhibitsState` no save (demolir guarda). A beleza do prédio soma as peças (`DerivedState.beauty_strength`,
  também na camada Beleza). Painel com um botão por peça.

### Atratividade e turistas (Fase 68, nossa)

- **Plano** em `docs/plano_fase68.md`. `DerivedState.attractiveness` (por ilha com entreposto e casas: beleza menos
  poluição, nos pesos da config) e `TourismSystem` (só com os eventos ligados: paga por ponto, mais na festa; soma no
  dinheiro e em `income_per_min`, guarda `WorldState.tourism_per_min`). Parcela `Breakdown.Kind.TOURISM` e a linha no
  painel do entreposto.

### Expedições (Fase 69, nossa)

- **Plano** em `docs/plano_fase69.md`. `ExpeditionDef` (`data/expeditions/`), `StartExpeditionCommand` (o navio sai
  do mapa para o `ExpeditionsState`), `ExpeditionSystem` (a volta sorteada pela semente e pelo número: naufrágio, mãos
  vazias ou a recompensa — peça guardada da Fase 67 ou moedas; o navio volta ao porto de origem) e o sinal
  `expedition_returned`. Botões no painel do navio, viagens na janela das encomendas, aviso da frota.

### Ferrovia e petróleo (Fase 70, nossa)

- **Plano** em `docs/plano_fase70.md`. `OilFields` (campos pela semente, depois da assinatura: `IslandGrid.oil_spots`),
  `GoodDef.rail_only` (petróleo), `oil_well` (`Terrain.OIL`) e `oil_power_station`, `IslandGrid.rails` com
  `BuildRailCommand` (bloqueia prédio e estrada; demolir tira; no save), `RailNetwork` e `DerivedState._link_rails`
  (poço e usina no mesmo grupo de trilho) e `RailSystem` (leva o petróleo, sem carroça). `BuildTool.road_rail` (o
  arrasto da estrada, sempre em L), cartão "Trilho", `RailView` (trilho e manchas de petróleo).

### O trem no trilho (Fase 71, nossa)

- **Plano** em `docs/plano_fase71.md`. Só apresentação: `RailNetwork.route` (o caminho mais curto pelo trilho entre os
  lotes) e `TrainView` (um trem por ligação do `rail_feeds`, locomotiva e vagão-tanque gerados no código, vaivém com
  espera nas pontas, parado com o poço ou a usina pausados; mesmo material do trilho).

### Desfazer o trilho (Fase 72, nossa)

- **Plano** em `docs/plano_fase72.md`. `UndoHistory` guarda a camada de trilho do retângulo (`rails_before`/`after`) e
  aceita o `BuildRailCommand`; o `UndoCommand` devolve o trilho (posto ou demolido) e recusa se ele mudou depois.

### O cavalo-de-pau (Fase 73, nossa)

- **Plano** em `docs/plano_fase73.md`. `Silhouette.PUMPJACK` (no fim do enum) no poço: pátio na frente com o cavalete,
  a caixa de engrenagens e a cabeça do poço (`BuildingKit._pumpjack`, `pumpjack_layout`), galpão baixo atrás, e o
  balancim que balança (`Rotor.rock`, `BuildingView._rotor_rocks`) enquanto o poço produz.

### Recintos e vitrines (Fase 74, nossa)

- **Plano** em `docs/plano_fase74.md`. `Silhouette.MENAGERIE` (zoológico: seis cercados no pátio) e `GALLERY` (museu:
  seis pedestais na frente), `BuildingKit.exhibit_spots` (uma vaga por cercado ou pedestal), `ExhibitModels` (bichos e
  peças com cor por vértice) e `BuildingView._dress_exhibits`; formas simples em `VertexShapes`.

### Bichos no cercado (Fase 75, nossa)

- **Plano** em `docs/plano_fase75.md`. `PenWalk` (descansa, vira no lugar e anda até um ponto sorteado; toda pose
  conferida pela pegada do corpo contra a cerca), `ExhibitModels.FACING`/`footprint`/`roams`, `BuildingKit.pen_half`,
  `PenWalk.fit_scale` (o bicho grande demais fica menor no cercado) e `BuildingView.walk_animals` pelos segundos de jogo.

### Fumaça do trem (Fase 76, nossa)

- **Plano** em `docs/plano_fase76.md`. `TrainView._chimney_smoke` (a fumaça das fábricas, `SmokeView._process_material` e
  `_draw_mesh` agora estáticas, solta no mundo na boca da chaminé), forte andando e fraca na ponta (`moving_at`), parada
  com o trem ou o jogo parados, no vento (`weather`) e pelo nível gráfico (`set_quality`).

### Chão e bebedouro no cercado (Fase 77, nossa)

- **Plano** em `docs/plano_fase77.md`. `ExhibitModels.pen_dressing` (o chão do bicho e o cocho, por cercado ocupado),
  `trough_rect` e `PenWalk.blocked`/`path_clear` (o bicho desvia do cocho pelo teste dos eixos separadores).

### Tanques da usina a petróleo (Fase 78, nossa)

- **Plano** em `docs/plano_fase78.md`. `Silhouette.TANKFARM` (no fim do enum) na usina a petróleo: pátio da frente com
  dois tanques (`BuildingKit._tankfarm`, `_tank`, `tank_layout`), dique, escada e tubo; galpão atrás. Peças geradas no
  código vão no `extra` do `_build` (no `tool`, já indexado, somem).

### O bicho vai beber (Fase 79, nossa)

- **Plano** em `docs/plano_fase79.md`. `PenWalk._choose_drink` (por um ponto de virar até o `drink_spot`, de frente para
  o bebedouro), `drinking`, `_back_up` (sai de ré), `BuildingView.DRINK_TILT`; o bebedouro no meio da cerca de trás.

### Turistas na rua (Fase 80, nossa)

- **Plano** em `docs/plano_fase80.md`. Na `Crowd`: `Agent.tourist`, `_rebalance_tourists` (pela atratividade da ilha,
  com os eventos ligados; `tourists_per_point`, `max_tourists_per_island`), `_pick_attraction` (as atrações de mais
  beleza na rede do entreposto) e `TOURIST_COLORS`. Só visual.

### Festa cheia (Fase 81, nossa)

- **Plano** em `docs/plano_fase81.md`. Na festa, os turistas na rua (e o teto) vezes `1 + tourism_festival_bonus`;
  `TourismSystem.has_festival` usado pela renda e pela `Crowd`.

### Ver os fogos (Fase 82, nossa)

- **Plano** em `docs/plano_fase82.md`. Na festa, na hora dos fogos (`Crowd.fireworks_now`), o turista vai a uma das
  praças da festa (`FestivalView.squares`) e fica na rua ao longo das cordas do mastro, de frente para ele
  (`WATCH_NEAR_M`, `WATCH_FAR_M`, `WATCH_SIDE_SHARE`); anda da porta até o lugar e, ao sair, do lugar até a porta.

### Moradores na festa (Fase 83, nossa)

- **Plano** em `docs/plano_fase83.md`. Na hora dos fogos, `RESIDENT_WATCH_SHARE` dos moradores que saem vão a uma praça da
  festa que a casa alcança (`Crowd._resident_festival`) e ficam em volta do mastro como os turistas; a ilha da festa
  conta com pelo menos `FESTIVAL_NIGHT_ACTIVITY` dos pedestres dela na rua (`_festival_agents`, somado no
  `desired_out`); `Agent.watching` marca quem está num lugar de ver a festa (ao sair, anda dele até a porta). Só visual.

### Palmas e cota da festa (Fase 84, nossa)

- **Plano** em `docs/plano_fase84.md`. `CheerClip` (`tools/vat/cheer_clip.gd`): a animação de ver os fogos gerada da
  parada (cabeça erguida, palmas por IK de dois ossos), gravada pelo `tools/bake_pedestrians.gd` como a quinta do VAT
  (`Crowd.CLIP_CHEER`; o shader tem `clips[8]`, a `PedestrianView` completa até `MAX_CLIPS`). Quem vê a festa usa ela
  (desde a Fase 85, só ao reagir a um estouro). Na hora dos fogos, o pedestre de ilha sem festa só sai na cota da hora (`_quiet_full`): a gente a mais
  é só da ilha da festa. Mudou a parada ou o esqueleto, refaça os pedestres (`tools/bake_pedestrians.gd`).

### Palmas nos estouros (Fase 85, nossa)

- **Plano** em `docs/plano_fase85.md`. `FestivalView.exploded(ilha, posição)` a cada estouro; `Crowd.react_to_burst`
  (quem vê a festa perto bate palmas por `CHEER_SECONDS` depois de `REACT_DELAY_S` e volta a olhar o mastro;
  `_end_cheers`, `Agent.cheer_until`); `FestivalSounds` (`audio/festival_sounds.gd`, na `GameScreen`): estouro e palmas
  gerados no código (em cache, ~21 ms uma vez), o estouro atrasado pela distância até a câmera e as palmas pelo número de
  gente. Script que usa o `GameClock` (como este) não roda por `--script`: meça dentro de um teste.

### Foguete e assobio (Fase 86, nossa)

- **Plano** em `docs/plano_fase86.md`. O `_process` da `FestivalView` lança foguetes (`fire`): sobem do mastro em
  `ROCKET_RISE_S` (`advance_rockets`, `rocket_point`, no tempo de jogo) e estouram lá em cima (`burst_at`); `launch` segue
  sendo o estouro imediato. `launched(ilha, de, até, segundos)` dá ao `FestivalSounds` o assobio (`whistle_stream`, a voz
  segue o voo e cala no estouro); o estrondo ganha o eco (`ECHO_*`).

### Formas e vivas (Fase 87, nossa)

- **Plano** em `docs/plano_fase87.md`. `FestivalView.Shape` (bola, crisântemo, salgueiro, anel; `pick_shape`,
  `shape_burst` rearma a bomba a cada estouro); **os fogos estouram de 14 a 22 m** (`FIREWORK_HEIGHT_M`; de 28 a 42 m
  ficavam acima da borda da tela); o rastro do foguete mais forte. As vivas são a única gravação de terceiros da festa
  (`assets/audio/sfx/crowd_cheer.mp3`, Gregor Quendel, CC BY 4.0): em laço na praça, o nível (`cheer_level`) sobe a cada
  estouro com 3 ou mais reagindo e some devagar.

### Duas etapas e vivas calmas (Fase 88, nossa)

- **Plano** em `docs/plano_fase88.md`. `Shape.DOUBLE`: cada bomba tem o sub-emissor filho `Sub` (ligado só nessa forma,
  `SUB_EMITTER_AT_END`); as estrelas estouram de novo na segunda cor. As vivas tocam duas faixas do mesmo pacote
  (`crowd_cheer_soft.mp3` e `crowd_cheer.mp3`), misturadas pelo nível (`FestivalSounds.cheer_mix`).

### Grand finale (Fase 89, nossa)

- **Plano** em `docs/plano_fase89.md`. Às 23h de cada noite de festa, uma vez, a salva de `FINALE_SHAPES`
  (`FestivalView.start_finale`, `advance_finale`); o foguete leva a forma (`fire(site, shape)`). Todo foguete estoura
  (`burst_at` reaproveita a bomba usada há mais tempo). As vivas seguem `Crowd.cheering_count` (quem ainda bate palmas),
  não só quem reagiu ao estouro.

### Porto em toda ilha (Fase 93, nossa)

- **Plano** em `docs/plano_fase93.md`. **O terreno dos jogos novos é o v4** (`ArchipelagoGenerator.VERSION_V4`): o v3 com
  `_ensure_harbor` no fim, que aplaina um lote de costa do tamanho do entreposto na ilha que não tem nenhum lugar para ele
  (`harbor_site`); ilha que já tinha sai igual à do v3. O v3 fica para os saves dele. `SiteFinder` dilata a água até largura
  + altura do prédio (antes pulava lotes bons). Mudou um número do porto (`HARBOR_*`), regrave as assinaturas do v4.

### Rufar e câmera do grand finale (Fase 94, nossa)

- **Plano** em `docs/plano_fase94.md`. O grand finale começa com o rufar (`FestivalSounds.roll_stream`, `on_finale`) e o
  primeiro foguete espera `FestivalView.FINALE_ROLL_S`; `finale_started(site)` leva o mastro. Com `Settings.finale_camera`
  (Opções → Jogo, desligada por padrão) a câmera desliza até a praça.

### Telhado de telhas (Fase 95, nossa)

- **Plano** em `docs/plano_fase95.md` (roteiro `docs/plano_fases_95_99.md`, formas mais redondas, olhando o Anno do dono:
  só a ideia). As águas do telhado ganham telhas no shader (`roof_tile_shade`, só na célula (0, 3) da paleta, sem
  triângulo a mais) e as quinas ganham hastes redondas (`BuildingKit._rod`: capa da cumeeira e dos espigões, beiral
  redondo) na célula (1, 3) (`UV_ROOF_TRIM`). A captura das casas é `tools/capture_phase95.tscn` (ilha plana; a da Fase
  39 não acha mais lugar no terreno v3/v4).

### Casa em mais de um volume (Fase 96, nossa)

- **Plano** em `docs/plano_fase96.md`. `Spec.wing` (metade das casas dos operários para cima): a coluna de −X perde o último
  andar e ganha telhado próprio, cruzado e mais baixo que o beiral do corpo (`main_part`, `wing_part`). **`slot()` devolve
  `&"none"` nas células que a ala tira** (`in_wing`): paredes, vidros acesos, caixilho, floreiras e vergas acompanham
  sozinhos. Código novo que ande pelas paredes do prédio deve pular `&"none"`.

### Cúpulas e torreões (Fase 97, nossa)

- **Plano** em `docs/plano_fase97.md`. `Spec.dome` (os serviços de `DOMED` com telhado de quatro águas: tambor de pedra,
  meia esfera de cobre e lanternim, `_dome`) e `Spec.turret` (casas de pórtico com três andares ou mais: torreão redondo
  no canto da frente de +X, `_turret`, `turret_center`; a sacada encurta uma célula). Peças torneadas por `_turned`. O
  cobre é a célula (2, 1) da paleta (`UV_COPPER`), pintada de azinhavre no `shaders/building_kit.gdshader`.

### Abóbadas e tonéis (Fase 98, nossa)

- **Plano** em `docs/plano_fase98.md`. `Spec.vault` (os de `VAULTED`, no lugar das duas águas: `vault_profile`, `_vault`,
  faixas com a normal do arco por `_smooth_quad`), `Silhouette.VATS` (no fim do enum: cervejaria, destilarias e adega, com
  os tonéis no pátio da frente, `vat_layout`, `_vats`) e a chaminé redonda das fábricas (`SmokeView.stack_mesh`). **Erro de
  compilação num teste com a janela oculta deixa o Godot parado até o tempo acabar**: rode o arquivo sem janela primeiro.

### Arcos (Fase 99, nossa)

- **Plano** em `docs/plano_fase99.md`. `Spec.arched` (serviços de pedra e investidores: `_arch_head` com o tímpano de
  vidro, a arquivolta e a pedra de fecho; `_arches` nos serviços, o `_ornament` nas casas) e a arcada do mercado na fileira
  do pátio junto do corpo (`arcade_bays`, `_arcade`; as bancas ficam na fileira da rua). O tímpano usa `UV_GLASS`: contar
  vidro por janela tem de somar `ARCH_SEGMENTS` triângulos por janela em arco.

### Fumaça das casas (Fase 100, nossa)

- **Plano** em `docs/plano_fase100.md`, primeira do roteiro `docs/plano_fases_100_104.md` (a rua habitada).
  `BuildingKit.chimney_top` (a boca, pela mesma conta da chaminé), `ChimneySmokeView` (`GameScreen.chimney_smoke_view`:
  baforadas num MultiMesh só, só de casa com morador, `amount_at` pela hora) e `shaders/chimney_smoke.gdshader` (sobe,
  cresce e deita com o vento no tempo visual; esmaece pela distância, porque o alcance de visibilidade de um MultiMesh do
  mundo todo conta do meio dele).

### Toldos listrados (Fase 101, nossa)

- **Plano** em `docs/plano_fase101.md`. `Spec.awning` (as lojas de `AWNING_SHOPS` e uma em `AWNING_HOUSE_SHARE` das casas
  dos artesãos e engenheiros; `awning_cells`, `_awnings`). A lona usa as células (3..6, 1) da paleta (`UV_AWNING_COLORS`,
  `UV_CANVAS`), pintadas no `shaders/building_kit.gdshader`; o teste confere que nenhuma peça do kit cai nelas.

### Enxaimel saliente (Fase 102, nossa)

- **Plano** em `docs/plano_fase102.md`. `Spec.jetty` (operários e artesãos, cumeeira ao longo da frente, dois andares ou
  mais): **o avanço está no `_cell_transform`** (face 0, andar 1 para cima, `JETTY_M`), então tudo o que se põe pela célula
  acompanha; código novo que desenhe na fachada da frente sem passar por ele precisa somar o avanço. `_jetty` desenha a
  viga do balanço, as mãos-francesas, o enxaimel e o fecho das pontas.

### Claraboias (Fase 103, nossa)

- **Plano** em `docs/plano_fase103.md`. `Spec.skylights` (produção sem silhueta, lado menor de `SKYLIGHT_MIN_CELLS` ou mais,
  duas águas ou abóbada), `skylight_panes` (no formato das janelas) e `_skylights`. **As vidraças entram em `windows()`**:
  acendem com a fábrica pela `WindowLightsView` e contam como janela em qualquer teste que conte a lista.

Todo asset ou addon novo entra em `CREDITS.md` (autor, link, licença, arquivos). O que
faltar vira placeholder e entra em `assets/TODO_ASSETS.md`. Addon só na fase que o usa,
atrás de um script adaptador próprio, depois de confirmar a versão compatível com o 4.7.

## Fases (seção 16)

| Fase | Estado |
|---|---|
| 0 — Fundação | **concluída em 12/10/2026**; o CI veio em 24/10/2026, com o repositório no GitHub |
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
| 11 — Expansões | **concluída em 15/10/2026**: segunda região climática, eventos e encomendas, rivais com IA e diplomacia e combate naval em 14/10/2026; eletricidade e especialistas em 15/10/2026 |
| Depois da Fase 11 | 15/10/2026: robô até os investidores; riscos (incêndio e doença, seção 8); estaleiro e clíper; navios e carroça de modelo |
| 12 — Cenários e vitória (nossa) | 15/10/2026: objetivo e prazo no jogo novo, três cenários, conquistas e a tela de fim |
| Depois da Fase 12 | 16/10/2026: prédios de modelo (fachadas do Kenney Fantasy Town Kit) |
| 13 — Cidade viva (nossa) | **concluída em 16/10/2026**: silhueta por cadeia, pilhas de estoque, carga na carroça, postes e fogueiras, detalhe das casas e animais com o cavalo da carroça (os pássaros ficaram de fora) |
| 14 — Campo e caminho (nossa) | **concluída em 16/10/2026**: plantações nos campos, cerca e capim nos pastos, meio-fio e sulcos nas estradas, ponte de madeira com corrimão e pássaros (pombos nas ruas, estorninhos nos campos) |
| 15 — Porto e quintal (nossa) | **concluída em 17/10/2026**: trapiche no píer, cais do entreposto com barcos e carga, feitoria do comerciante, cestos e sacos nos pedestres, varais e vasos nas casas |
| 16 — Praças e jardins (nossa) | **concluída em 17/10/2026**: beleza nas casas, aba Decoração com árvore, canteiro, banco, praça com chafariz, estátua e coreto, camada Beleza |
| 17 — Porto e diagonais (nossa) | **concluída em 17/10/2026**: aba Porto e estradas em diagonal (simulação, traçado e desenho); a suíte inteira passa da memória da VM e foi conferida em duas rodadas |
| 18 — Detalhes de época (nossa) | **concluída em 17/10/2026**: campanário com sino na igreja e portão largo nas fábricas pesadas; cornija, vergas, frontão e grade de ferro nas casas; poste de ferro fundido com lampião a gás; arreio do cavalo; a suíte inteira (82 arquivos) passou, em três rodadas por falta de memória da VM |
| 19 — Chão e margem (nossa) | **concluída em 18/10/2026**: lama na margem do rio e areia molhada na praia; leiras da terra arada nos campos; estrada de terra com borda recortada e capim, sem degrau na ladeira; sarjeta e meio-fio de pedra no paralelepípedo; ovelhas, porcos e cães andando |
| 20 — Corda e gravura (nossa) | **concluída em 18/10/2026**: amarras no píer e no cais; madeira gasta e cordame na feitoria; pedras soltas na terra; asa batendo nos pássaros; carta gravada; a suíte inteira (83 arquivos, 586 casos) passou, por pasta, numa rodada só |
| 21 — Gaivota e papel (nossa) | **concluída em 18/10/2026**: gaivotas batendo asa; nó no cabeço; papel envelhecido na interface e na carta; a suíte inteira (84 arquivos, 594 casos) passou, por pasta e depois arquivo por arquivo (a memória da VM interrompeu duas vezes a rodada em segundo plano) |
| 22 — Mata e vento (nossa) | **concluída em 19/10/2026**: vento no clima, com a fumaça e as bandeiras; árvores, plantações e capim balançando pelo vento; carvalho, faia e pinheiro-silvestre gerados no código, com o nível de detalhe de longe; a suíte inteira (86 arquivos, 608 casos) passou, por pasta e depois arquivo por arquivo em primeiro plano |
| 23 — Varanda e galpão (nossa) | **concluída em 20/10/2026**: varanda da casa de engenho nas plantações; plataforma de carga do armazém, com alpendre e tijolo pelo nível; guindaste de porto no entreposto e no estaleiro e guincho no armazém; a suíte inteira (86 arquivos, 614 casos) passou, por pasta e a `ui` arquivo por arquivo em primeiro plano (a memória da VM interrompeu duas vezes a rodada em segundo plano) |
| 24 — Pedra e torno (nossa) | **concluída em 20/10/2026**: ponte de pedra em arco na rua calçada; balaustrada torneada, consolos e peitoris nas casas; caneluras e volutas no poste de ferro fundido; a suíte inteira (86 arquivos, 617 casos) passou, por pasta e a `ui` arquivo por arquivo em primeiro plano |
| 25 — Cantaria e moldura (nossa) | **concluída em 24/10/2026**: guarnição de pedra (ombreiras e pedra de fecho) nas janelas dos engenheiros e investidores; aduelas saltadas no arco da ponte de pedra; meio-fio com as quinas chanfradas; a suíte inteira (86 arquivos, 618 casos) passou, por pasta e a `ui` arquivo por arquivo (a pasta inteira passou do tempo com a memória da VM apertada) |
| 26 — Convés e cordame (nossa) | **concluída em 24/10/2026**: ovéns e estais nos navios, lidos do próprio modelo; carga do porão no convés; base e capitel torneados no poste de gás; a suíte inteira passou no CI |
| 27 — Contas do meio da partida (nossa) | **concluída em 24/10/2026**: raio-x da manutenção e das obras no relatório de balanceamento, cadeia × imposto na planilha, robô juntando para a obra da frente; diagnóstico em `docs/balanceamento.md`, nenhum número mudou; a suíte inteira passou no CI |
| 28 — Folga do meio da partida (nossa) | **concluída em 24/10/2026**: aviso de fábrica ociosa no saldo e no painel; teatro e universidade mais baratos de manter; fábricas dos artesãos e fundição mais baratas de construir; imposto dos operários 1,4 (decisão do dono do produto); pior saldo do robô de −7.654 para −745; a suíte inteira passou no CI |
| 29 — Fôlego da simulação (nossa) | **concluída em 24/10/2026**: perfil do tick por etapa e `-- --so-tick` no benchmark; tick médio de 4,19 para 3,10 ms (população, logística, produção) e obra com a ilha cheia de 48,1 para 41,2 ms (buscas em largura das estradas), sem mudar o resultado; a suíte inteira passou no CI |
| 30 — Transição e retorno visual (nossa) | **concluída em 24/10/2026**: cortina com texto na troca de tela, contadores animados e pulso de ganho na barra, notificações que aparecem e esmaecem, moedas e "+X" sobre o entreposto quando o comerciante paga; plano em `docs/plano_fase30.md`; a suíte inteira passou no CI |
| 31 — Obra e combate (nossa) | **concluída em 25/10/2026**: prédio subindo com squash & stretch e poeira, demolido afundando na poeira, balas em arco com respingo e o alvo adernando no combate naval, zoom suave no cursor; plano em `docs/plano_fase31.md` |
| 32 — Medida e nitidez (nossa) | **concluída em 25/10/2026** (fechada pelo dono do produto): teste dourado do terreno, AA em todos os níveis (sem MSAA), primeira vez atrás da cortina, caixa fixa dos MultiMeshes (e dos pedestres nas ilhas tropicais), benchmark com quadros brutos e lows, shader baker no export; primeira medição numa GPU (RTX 5060, 1080p, Vulkan e D3D12): fica o Vulkan, alto a ~48 FPS, ultra com travadas; plano em `docs/plano_fase32.md` |
| 33 — Por cima do mundo (nossa) | **concluída em 25/10/2026** (regra dos ícones aprovada pelo dono do produto): grade de construção com teste de profundidade e só em volta do cursor (o destaque é que atravessa), prévia com o modelo do prédio e listras quando não pode, ícones de estado iguais agregados de longe; no benchmark da RTX 5060 o FPS ficou igual ao da Fase 32 (uma primeira rodada com o alto a 62 FPS não se repetiu); a suíte inteira passou no Windows, menos o `test_colorblind_option_repaints_the_house_needs`, que já falhava ali antes da fase; plano em `docs/plano_fase33.md` |
| 34 — Chão sem xadrez (nossa) | **concluída em 25/10/2026** (capturas aprovadas; hex-tiling só no ultra, decisão do dono do produto): texturas de dados do terreno (inclinação, curvatura, água, umidade), bordas com ruído e height-blend, macro-variação, hex-tiling perto da câmera e reamostragem por distância (o xadrez de 12 m sumiu a 420 m), triplanar na rocha; a suíte inteira passou no CI; no benchmark da RTX 5060 a GPU subiu 0,4 ms no baixo e ~1,2 ms nos outros (o hex-tiling, medido à parte no `tools/terrain_cost.tscn`); plano em `docs/plano_fase34.md` |
| 35 — Costa viva (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 25/10/2026), feita sem tela: distância até a costa com sinal (por região e no arquipélago), plataforma rasa, espuma andando para a praia e ondas calmas na água; fundo raso pela distância, cáusticas, espraiado e detritos no terreno; as pastas sem tela passaram e o CI compilou os shaders (pasta `world`); faltam, quando o dono liberar a tela, as capturas e o benchmark; plano em `docs/plano_fase35.md` |
| 36 — Encostas de pedra (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 25/10/2026), feita sem tela: detalhe visual nos barrancos só na malha (5.277 cantos na semente 1840, zero em toda célula com algo em cima; estrada nova num barranco desfaz o da célula), pedras de rocha triplanar nos barrancos e no litoral rochoso; a suíte inteira passou no CI (com a Fase 35); faltam, quando o dono liberar a tela, as capturas e o benchmark; plano em `docs/plano_fase36.md` |
| 37 — Luz e cor de época (nossa) | **concluída em 28/10/2026, aprovada pelo dono, com a cor de época desligada** (em andamento desde 25/10/2026), feita sem tela: opção "Cor de época" (LUT de 33³ gerado no código e AgX ajustado, desligada por padrão), SSR e sol com PCSS só no ultra, auditoria das luzes noturnas (todas sem sombra, longe dos 512); a suíte inteira passou no CI; faltam, com tela, a comparação pelo `tools/capture_phase37.tscn` (o dono escolhe se a cor de época fica ligada) e o benchmark do ultra; plano em `docs/plano_fase37.md` |
| 38 — Estradas no chão (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 25/10/2026), feita sem tela: máscara das estradas por ilha (distância à linha do meio da terra, calçamento, chão batido das portas, poças), a terra pintada no terreno com borda de ruído, sulcos e poças, sem ladrilho na ilha com relevo; diagonal a 45° sem escada, cruzamento contínuo e L arredondado (provados em teste); a suíte inteira passou no CI; faltam, com tela, as capturas e o pior quadro ao construir estrada; plano em `docs/plano_fase38.md` |
| 39 — Prédios assentados (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: variação estável de telhado, beiral, chaminé, lucarnas e paletas (casas em fila nunca com o telhado na mesma altura), piso no canto alto do lote com plinto e degraus no barranco, entreposto em armazém, camponeses recuados das divisas, vidro e caixilho nas janelas, sombra de contato e musgo; benchmark e capturas na área de trabalho escondida (draw calls de 1.101 para 1.248, FPS igual, construir igual); a suíte inteira passou no CI; falta o dono aprovar as paletas e as regras; plano em `docs/plano_fase39.md` |
| 40 — Campos em colcha (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: terra lavrada com contorno ondulado igual dos dois lados da divisa, sem a caixa; fileiras em x ou z (vizinhos sempre diferentes) com cabeceira; tom por campo; sebe (muro de pedra na encosta) em volta de cada fazenda com porteira, nada nas tropicais; pasto sem caixa, com trilhas no terreno; GPU igual no bairro rural medido; falta o dono escolher sebe ou muro por região e o tratamento das tropicais; plano em `docs/plano_fase40.md` |
| 41 — Mata e recheio (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: copas fofas (normais da copa inteira, tufos, luz de trás) e histerese na troca de detalhe; recheio determinístico fora do save (arbustos, capim, flores, pedrinhas, barris, caixotes e lenha pela vizinhança), refeito só nos trechos atingidos; GPU de 11,1 para 11,4 ms no alto, jogo novo e carregar ~0,4 s a mais; folha recortada e impostor ficaram de fora; falta o dono aprovar a densidade e escolher a textura de folha; plano em `docs/plano_fase41.md` |
| 42 — Quadro estável e carregamento real (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: o jogo novo gera uma ilha por thread (idêntico ao direto, teste em três sementes) com porcentagem, barra e dicas na cortina; geração de ~980 para ~430 ms com pior quadro de 15 ms; tick p95 1,5 ms, obra 18 ms, o 4× limitado por quadro; montar as vistas (~5 s) segue na thread principal (fica de fora, medido); falta o dono medir no PC e aprovar as metas de quadro; plano em `docs/plano_fase42.md` |
| 43 — Interface enxuta (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: contraste WCAG provado em teste (estados e foco corrigidos), Playfair só nos títulos grandes e números tabulares, escala até 200% com aviso abaixo de 18 px, fonte legível e reduzir movimento, avisos com contador, categorias silenciáveis, pausa no alerta e duração, painel dos prédios do tamanho do conteúdo, sons de interface em toda tela, créditos dos ícones por autor; DPITexture e a barra de cima reorganizada ficaram de fora; falta o teste com uma pessoa de fora e o dono aprovar as fontes; plano em `docs/plano_fase43.md` |
| 44 — Primeira tela (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: fundo do menu sem a grade, com a carta gravada de um arquipélago numa thread e deriva lenta; botões entrando; prévia do jogo novo com as mesmas alturas da partida, numa thread cancelável (~1,7 s); som de vitória e derrota; o diorama 3D e a pré-carga ficaram de fora; falta o dono aprovar a gravura e o som; plano em `docs/plano_fase44.md` |
| 45 — Ilhas novas (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: gerador v2 (elipses unidas, warp, costa fractal, ilhotas, bancos de areia, patamares por região com divisas curvas) convivendo com o v1, que segue congelado e padrão; escolha no jogo novo com a prévia; saves na versão que gravaram, versão desconhecida recusada; a terra enche 63–80% do retângulo (v1 81–90%), área construível 45–98% da do v1; assinaturas do v2 gravadas (provisórias); falta o dono aprovar a forma, a faixa de balanceamento e quando o v2 vira padrão; plano em `docs/plano_fase45.md` |
| 46 — Calçamento e esquinas (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: paralelepípedo em grade dual (16 casos, 6 peças girando), esquinas arredondadas, cantos de dentro com concordância, meio-fio e sarjeta contínuos dentro das peças, diagonal como faixa reta (sela pela conectividade da simulação, chanfro nos cantos ao lado), refeito só em volta da rua nova; uma rua de pedra nova 70 → 40 ms, calçar a cidade inteira de uma vez 75 → 437 ms, quadro igual; falta o dono aprovar as peças e a escolha da grade dual pelas capturas; plano em `docs/plano_fase46.md` |
| 47 — QoL de interface (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: copiar prédio com rotação e configuração, busca no menu de construção (pt_BR e en, sem acento), quantos existem e "Próximo igual", do prédio para a estatística e da estatística para os produtores, dicas que decompõem bens e dinheiro por fonte (fecham com a tela, montadas só no hover), rotas com duplicar, vaga cheia com Shift, destaque no mapa e filtro guardado, modo foto (sem interface, pausa, hora e inclinação); atalhos novos sem tecla padrão; tick e quadro iguais; nome e grupo da rota foram para a Fase 49; falta o dono priorizar, testar com alguém de fora e escolher teclas; plano em `docs/plano_fase47.md` |
| 48 — Godot 4.8 (nossa) | **ensaio feito em 26/10/2026, à espera da 4.8 estável**, sem nada na tela do dono: a estável não saiu; a 4.8-beta1 roda o projeto no ramo `godot-4.8` (378 scripts sem erro, suíte sem janela verde, testes dourados iguais, benchmark com GPU +0,4 ms com sombras de contato e AO de vários quiques ligados no alto e no ultra); nomes reais das opções novas registrados; dois consertos achados medindo vieram para o main (pan pela borda sem mouse e filtro de nós liberados); falta a estável, o dono decidir quando subir e medir na 3060; plano em `docs/plano_fase48.md` |
| 49 — Desfazer e planta (nossa) | **concluída em 28/10/2026, aprovada pelo dono** (em andamento desde 26/10/2026), sem nada na tela do dono: desfazer e refazer de obra, estrada, demolição, substituição e plantas (Ctrl+Z, Ctrl+Shift+Z), idêntico no mesmo tick e com reembolso integral depois, janela de 120 s, fora do save; plantas sem custo no save (versão 16, com migração), construídas pelas regras de sempre, com fantasma; substituir em área com Ctrl+arrastar; nome e grupo das rotas; obra pelo histórico 14,6 ms e desfazer 15,3 ms com a ilha cheia; falta o dono aprovar as regras (janela, reembolso, reserva de célula) e a subida do save; plano em `docs/plano_fase49.md` |
| 50 — Kit de época (nossa) | **caminho pronto em 26/10/2026, à espera da arte**, sem nada na tela do dono: regras de importação com teste (orçamento de triângulos por categoria, uma malha, frente em −Z, pivô e tamanho no lote, LOD, nome, crédito), validação no CI, o BuildingKit pondo a peça no lugar da forma procedural sem quebrar a montagem por célula (sem peça, nada muda; benchmark igual), lista do que falta no `assets/TODO_ASSETS.md`; falta a arte (modelar, gerar ou comprar as peças) e as aprovações do dono; plano em `docs/plano_fase50.md` |
| 51 — Fotos e retratos nos menus (nossa) | **feita em 26/10/2026, a pedido do dono**, sem nada na tela dele: ideias do Anno 1800 (cartões ilustrados, painel com a imagem do prédio, retratos pintados), nenhum arquivo dele; 64 fotos dos nossos próprios modelos com acabamento de pintura nos cartões do menu de construção e no painel; retratos de pinturas do século XIX em domínio público (Pissarro, Renoir, Manet e outros, Art Institute of Chicago, CC0) nas classes, no conselheiro e no comerciante; quadro igual; plano em `docs/plano_fase51.md` |
| 52 — Ilhas no jeito do Anno (nossa) | **feita em 26/10/2026, a pedido do dono**, olhando o Anno 1800 dele (só capturas, nenhum arquivo): gerador v3, padrão dos jogos novos, com ilhas alongadas sobre uma espinha curva, 2–3 enseadas com praia larga e água rasa, falésias no resto da costa com a planície mais alta, rochedos soltos junto aos cabos, interior quase plano e a plataforma turquesa pela costa de verdade; cerca de metade dos lotes de casa do v1 (faixa provisória); a cor, a água e a rocha ficam para a Fase 53; plano em `docs/plano_fase52.md` |
| 53 — Cor no jeito do Anno (nossa) | **feita em 26/10/2026, a pedido do dono**: grama verde e saturada, areia clara, rocha escura, folhas mais vivas, água turquesa mais viva e larga junto à costa, névoa mais leve de longe; falésia do v3 descendo em 1,6 célula e sem praia em cima (assinaturas do v3 regravadas); o serrilhado da linha d'água (grade de 2 m) fica de fora; plano em `docs/plano_fase53.md` |
| 54 — Costa lisa (nossa) | **feita em 26/10/2026, a pedido do dono**: a distância até a costa parte de onde a altura cruza o zero (espuma, areia molhada e plataforma sem a escada da grade), cada quadrado do terreno pela diagonal que segue o relevo, a praia pela distância até a linha d'água e sem areia na falésia e na rocha; só apresentação (terreno e assinaturas iguais); plano em `docs/plano_fase54.md` |
| 55 — Malha fina na linha d'água (nossa) | **feita em 27/10/2026, a pedido do dono**: os quadrados da malha que a costa atravessa viram subgrade de 3 × 3 com alturas curvas (Catmull-Rom, até 0,8 m da reta), a linha d'água sai curva de perto em vez de reta de 2 em 2 m; cantos da grade iguais aos da simulação, sem fresta; só apresentação; plano em `docs/plano_fase55.md` |
| 56 — Rocha nos rochedos e nas falésias (nossa) | **feita em 27/10/2026, a pedido do dono**: rocha gerada no código (sem asset novo); cada rochedo solto no mar vira bloco de rocha com pilar e pedras em volta, e a face das falésias ganha rochas encaixadas, abaixo da borda e fora de onde se constrói; só apresentação; o rochedo segue construível na simulação (proposta à espera do dono); plano em `docs/plano_fase56.md` |
| 57 — Pedras soltas com a rocha gerada (nossa) | **feita em 27/10/2026, a pedido do dono**: as pedras dos barrancos e do litoral rochoso trocam as lajes do Kenney pela rocha facetada da Fase 56, nos mesmos lugares; só apresentação; plano em `docs/plano_fase57.md` |
| 58 — Coqueiro gerado no código (nossa) | **feita em 27/10/2026, a pedido do dono**: as ilhas tropicais trocam as palmeiras do Kenney por um coqueiro gerado no código, com malha de longe; sai o último modelo do Nature Kit; só apresentação; a mata tropical de folhosas fica como proposta; plano em `docs/plano_fase58.md` |
| 59 — Mata tropical (nossa) | **feita em 27/10/2026, a pedido do dono**: folhosa tropical gerada no código (tronco com sapopemas, copa em guarda-chuva) misturada aos coqueiros, mais coqueiro na costa baixa e mais folhosa no alto; só apresentação; plano em `docs/plano_fase59.md` |
| 60 — Sub-bosque tropical (nossa) | **feita em 27/10/2026, a pedido do dono**: bananeira e samambaia geradas no código no lugar do arbusto temperado nas ilhas tropicais; temperadas iguais; só apresentação; plano em `docs/plano_fase60.md` |
| 61 — Helicônias (nossa) | **feita em 27/10/2026, a pedido do dono**: helicônia gerada no código no lugar das flores do campo nas ilhas tropicais; só apresentação; plano em `docs/plano_fase61.md` |
| 62 — Malha fina na face da falésia (nossa) | **feita em 27/10/2026, a pedido do dono**: a face da falésia vira subgrade como a costa da Fase 55, com aspereza de rocha e normais pela subgrade, sem tocar célula construível nem a linha d'água; só apresentação; plano em `docs/plano_fase62.md` |
| 63 — Jornal (nossa) | **feita em 27/10/2026, a pedido do dono**: edição periódica com manchete sorteada que mexe na felicidade de todas as ilhas, e propaganda paga que troca a manchete; só com os eventos ligados (assinaturas iguais); números provisórios, à espera do dono; plano em `docs/plano_fase63.md` |
| 64 — Baleias e golfinhos (nossa) | **feita em 27/10/2026, a pedido do dono**: baleias que sobem, sopram e mergulham no mar aberto e golfinhos saltando em águas médias, gerados no código; só apresentação; a proposta de fábricas com estado visível já estava feita; plano em `docs/plano_fase64.md` |
| 65 — Festa na cidade (nossa) | **feita em 27/10/2026, a pedido do dono**: com a festa numa ilha, bandeirolas por cima das ruas das praças e fogos de artifício à noite; só apresentação; plano em `docs/plano_fase65.md` |
| 66 — Prefeitura e políticas (nossa) | **feita em 27/10/2026, a pedido do dono**: prefeitura com uma política por vez (jornada longa, vigia de incêndio, feriados, coletoria) que vale nos prédios em volta, com manutenção; no save; números provisórios, à espera do dono; plano em `docs/plano_fase66.md` |
| 67 — Zoológico e museu (nossa) | **feita em 28/10/2026, a pedido do dono**: zoológico e museu com seis vagas cada para peças compradas uma vez (animais e objetos), que somam beleza às casas em volta; no save; números provisórios; plano em `docs/plano_fase67.md` |
| 68 — Atratividade e turistas (nossa) | **feita em 28/10/2026, a pedido do dono**: atratividade por ilha (beleza menos poluição) e turistas que pagam por ela, mais na festa, com os eventos ligados; parcela no detalhamento e linha no entreposto; números provisórios; plano em `docs/plano_fase68.md` |
| 69 — Expedições (nossa) | **feita em 28/10/2026, a pedido do dono**: navio parado mandado a um de quatro destinos, que volta sorteado (peça de coleção, moedas, mãos vazias ou naufrágio); no save; números provisórios; plano em `docs/plano_fase69.md` |
| 70 — Ferrovia e petróleo (nossa) | **feita em 28/10/2026, a pedido do dono**: campos de petróleo pela semente (assinatura igual), poço, usina a petróleo e trilho que leva o petróleo do poço à usina (sem carroça); trilho no save; números provisórios; plano em `docs/plano_fase70.md` |
| 71 — O trem no trilho (nossa) | **feita em 28/10/2026, a pedido do dono**: locomotiva com vagão-tanque gerados no código indo e voltando pelo caminho mais curto do trilho entre o poço e a usina; só apresentação (a simulação e as assinaturas não mudam); plano em `docs/plano_fase71.md` |
| 72 — Desfazer o trilho (nossa) | **feita em 28/10/2026, a pedido do dono**: o trilho entra no histórico do Ctrl+Z (posto ou demolido, com o reembolso, e o refazer); só o histórico, fora do save; plano em `docs/plano_fase72.md` |
| 73 — O cavalo-de-pau (nossa) | **feita em 28/10/2026, a pedido do dono**: o poço de petróleo troca a torre de mina por um cavalo-de-pau gerado com as peças do kit, com o balancim balançando enquanto produz; só apresentação; plano em `docs/plano_fase73.md` |
| 74 — Recintos e vitrines (nossa) | **feita em 28/10/2026, a pedido do dono**: o zoológico ganha seis cercados e o museu seis pedestais, e cada peça posta aparece na sua vaga (bichos e peças gerados no código); só apresentação; plano em `docs/plano_fase74.md` |
| 75 — Bichos no cercado (nossa) | **feita em 28/10/2026, a pedido do dono**: os bichos do zoológico andam e viram dentro do cercado sem atravessar a cerca (o elefante fica menor para caber); as araras e as peças do museu ficam paradas; só apresentação; plano em `docs/plano_fase75.md` |
| 76 — Fumaça do trem (nossa) | **feita em 28/10/2026, a pedido do dono**: a locomotiva solta fumaça pela chaminé, cheia andando e fraca esperando nas pontas, deitando no vento e pelo nível gráfico; só apresentação; plano em `docs/plano_fase76.md` |
| 77 — Chão e bebedouro no cercado (nossa) | **feita em 28/10/2026, a pedido do dono**: cada cercado ocupado ganha o chão do bicho (areia ou capim) e um bebedouro, de que os bichos desviam; a ideia de pôr as partículas no rascunho da primeira vez foi medida e descartada; só apresentação; plano em `docs/plano_fase77.md` |
| 78 — Tanques da usina a petróleo (nossa) | **feita em 28/10/2026, a pedido do dono**: a usina a petróleo deixa a forma da usina a carvão e ganha o pátio com dois tanques, dique, escada e tubo até o galpão; foto do menu refeita; só apresentação; plano em `docs/plano_fase78.md` |
| 79 — O bicho vai beber (nossa) | **feita em 28/10/2026, a pedido do dono**: o leão e o tigre vão ao bebedouro, viram de frente e bebem inclinados, e saem de ré; os bichos maiores não cabem de frente para ele no cercado (medido); só apresentação; plano em `docs/plano_fase79.md` |
| 80 — Turistas na rua (nossa) | **feita em 28/10/2026, a pedido do dono**: com os eventos ligados, turistas de roupa clara saem do entreposto, visitam as atrações da ilha e voltam, na quantidade da atratividade; só visual; números provisórios; plano em `docs/plano_fase80.md` |
| 81 — Festa cheia (nossa) | **feita em 28/10/2026, a pedido do dono**: na festa vêm mais turistas para a rua, na mesma proporção da renda do turismo; só visual; plano em `docs/plano_fase81.md` |
| 82 — Ver os fogos (nossa) | **feita em 28/10/2026, a pedido do dono**: na festa, à noite, os turistas vão às praças e ficam em volta do mastro olhando os fogos; só visual; plano em `docs/plano_fase82.md` |
| 83 — Moradores na festa (nossa) | **feita em 28/10/2026, a pedido do dono**: na noite de fogos os moradores também vão às praças e ficam em volta do mastro, e a festa põe metade da gente da ilha na rua (à noite saíam só ~18%); só visual; plano em `docs/plano_fase83.md` |
| 84 — Palmas e cota da festa (nossa) | **feita em 28/10/2026, a pedido do dono**: quem vê os fogos olha para o céu batendo palmas (animação gerada no código a partir da parada, quinta do VAT), e a gente a mais na rua sai só da ilha da festa; só visual; plano em `docs/plano_fase84.md` |
| 85 — Palmas nos estouros (nossa) | **feita em 28/10/2026, a pedido do dono**: o povo bate palmas a cada estouro e volta a olhar o mastro; som do estouro (atrasado pela distância) e das palmas gerados no código; vivas ficaram de fora; o som falta ser ouvido pelo dono; plano em `docs/plano_fase85.md` |
| 86 — Foguete e assobio (nossa) | **feita em 28/10/2026, a pedido do dono**: o fogo sobe do mastro como foguete (brilho e rastro de faíscas) e só estoura lá em cima, com o assobio seguindo o voo e o eco do estrondo, tudo gerado no código; o som falta ser ouvido pelo dono; plano em `docs/plano_fase86.md` |
| 87 — Formas e vivas (nossa) | **feita em 28/10/2026, a pedido do dono**: estouros em bola, crisântemo, salgueiro e anel; os fogos mais baixos (de 28–42 para 14–22 m: lá em cima ficavam fora da tela); rastro do foguete mais forte; vivas do povo numa gravação CC BY 4.0 (Gregor Quendel) que sobem com a gente reagindo; o som falta ser ouvido pelo dono; plano em `docs/plano_fase87.md` |
| 88 — Duas etapas e vivas calmas (nossa) | **feita em 28/10/2026, a pedido do dono**: bomba de duas etapas (as estrelas estouram de novo, pelo sub-emissor) e a faixa calma das vivas para pouca gente, misturada com a forte pelo nível; cortar a gravação ficou de fora (pede `ffmpeg` no disco C); o som falta ser ouvido pelo dono; plano em `docs/plano_fase88.md` |
| 89 — Grand finale (nossa) | **feita em 28/10/2026, a pedido do dono**: às 23h de cada noite de festa, uma salva de 24 foguetes que acaba na chuva dourada; todo foguete estoura (antes sumia com as bombas ocupadas); as vivas seguem quem ainda bate palmas (na salva quase não tocavam); plano em `docs/plano_fase89.md` |
| 90 — Daltônico no Windows (nossa) | **feita em 28/10/2026**, primeira do roteiro `docs/plano_fases_90_94.md`: o teste do modo daltônico que falhava no Windows do dono já tinha sido corrigido em 26/10 (`2f735e3`: o painel repinta na hora em que a opção muda); a pendência saiu da lista e a suíte inteira foi conferida no PC do dono, 986 casos sem nenhum vermelho; plano em `docs/plano_fase90.md` |
| 91 — Travadas do ultra (nossa) | **feita em 28/10/2026**: três rodadas do ultra na RTX 5060 (62 a 64 FPS, pior quadro de 85, 32 e 28 ms), nenhuma travada de ~2 s; o benchmark grava por quadro a hora e as pipelines compiladas, e as compilações do anoitecer não coincidem com nenhum quadro lento (o Godot as faz por fora); nada mudou no jogo; plano em `docs/plano_fase91.md` |
| 92 — Medidas que faltam (nossa) | **feita em 28/10/2026**: alto em 1080p com VSync desligado 86 FPS, o 3D nos pixels do 4K 46,5 FPS (GPU 21 ms), o executável exportado 89 FPS; o shader baker não muda as compilações (fica registrado); o executável caía no benchmark porque um `assert` some na exportação, e por trás disso as ilhas 3 e 4 da semente 1840 no terreno v3 não têm lugar de entreposto (virou a Fase 93); plano em `docs/plano_fase92.md` |
| 93 — Porto em toda ilha (nossa) | **feita em 28/10/2026**: terreno v4, o padrão do jogo novo: o v3 com um porto aplainado na ilha que não tinha lugar de entreposto (12 de 31 sementes tinham ilha sem como colonizar); as outras ilhas saem iguais às do v3; o v1, o v2 e o v3 seguem para os saves; o `SiteFinder` deixou de pular lotes encostados no mar pelo canto; plano em `docs/plano_fase93.md` |
| 94 — Som e câmera do grand finale (nossa) | **feita em 28/10/2026**, a última do roteiro: rufar de caixa gerado no código antes da salva, com o primeiro foguete esperando ele acabar; opção "Câmera no grand finale" (desligada por padrão) que leva a câmera à praça às 23h; o som falta ser ouvido pelo dono; plano em `docs/plano_fase94.md` |
| 95 — Telhado de telhas (nossa) | **feita em 29/10/2026**, primeira do roteiro das formas mais redondas (Fases 95 a 99, olhando o Anno do dono): telhas em fileiras desencontradas com a borda redonda nas águas (no shader), capa redonda na cumeeira e nos espigões e beiral redondo; GPU igual no A/B; plano em `docs/plano_fase95.md` |
| 96 — Casa em mais de um volume (nossa) | **feita em 29/10/2026**: metade das casas dos operários para cima ganha uma ala de um andar a menos com telhado próprio cruzado com o do corpo (o telhado em L); as janelas acesas, o caixilho e a cornija acompanham; quadro igual no A/B, o carregar sobe com as formas em dobro; plano em `docs/plano_fase96.md` |
| 97 — Cúpulas e torreões (nossa) | **feita em 29/10/2026**: cúpula de cobre com tambor e lanternim no teatro, na universidade, na prefeitura e no museu; torreão redondo com telhado cônico no canto das casas altas dos investidores; plano em `docs/plano_fase97.md` |
| 98 — Abóbadas e tonéis (nossa) | **feita em 29/10/2026**: telhado em abóbada no mercado e nas fábricas de nave comprida; tonéis com arcos de ferro no pátio da cervejaria, das destilarias e da adega; chaminé de tijolo redonda e afunilada; plano em `docs/plano_fase98.md` |
| 99 — Arcos (nossa) | **feita em 29/10/2026**, a última do roteiro das formas mais redondas: janelas com a cabeça em arco (tímpano de vidro e arquivolta de pedra) nos serviços de pedra e nas casas dos investidores; arcada com pilares, arcos e água de telhas na frente do mercado; plano em `docs/plano_fase99.md` |
| 100 — Fumaça das casas (nossa) | **feita em 29/10/2026**, primeira do roteiro da rua habitada (Fases 100 a 104): baforadas saindo das chaminés das casas com morador, mais de manhã e à noite, deitando com o vento; plano em `docs/plano_fase100.md` |
| 101 — Toldos listrados (nossa) | **feita em 29/10/2026**: toldo de lona listrada sobre a porta e as janelas do térreo da padaria, do açougue, da taverna e de um terço das casas dos artesãos e engenheiros; plano em `docs/plano_fase101.md` |
| 102 — Enxaimel saliente (nossa) | **feita em 29/10/2026**: nas casas dos operários e artesãos com a cumeeira ao longo da frente, os andares de cima avançam sobre a rua numa viga com mãos-francesas, com o enxaimel (esteios e escoras) à mostra; plano em `docs/plano_fase102.md` |
| 103 — Claraboias (nossa) | **feita em 29/10/2026**: uma fileira de vidraças com caixilho de ferro em cada água (ou na abóbada) das fábricas grandes sem silhueta própria, acesas à noite com a fábrica produzindo; plano em `docs/plano_fase103.md` |

Pendências já vistas para fases futuras:

- Balanceamento: ver `docs/balanceamento.md`. Medido na Fase 27 e folgado na Fase 28 (24/10/2026): o robô joga 4 h
  numa ilha plana de 350×350, o pior saldo fica em −745 e ele chega aos engenheiros aos ~120 min e aos investidores
  aos ~225. Falta medir com gente de verdade jogando: o robô não sente a partida.
- Desempenho gráfico (RTX 5060, 1080p, `docs/benchmark.md`): em 25/10/2026 o alto dava ~48 FPS e o ultra travava até
  ~2 s; em 28/10/2026, na área de trabalho escondida, o alto dá ~86 FPS e o ultra 62 a 64 FPS, com o pior quadro entre 28
  e 85 ms em três rodadas e nenhuma travada longa (Fase 91: as compilações de shader do anoitecer não param o quadro). A
  máquina oscila entre um estado lento e um rápido (ver as entradas do benchmark). Medidos 4K, VSync desligado e o
  build com o shader baker (Fase 92: alto com VSync desligado 86 FPS, 4K 46,5 FPS, executável 89 FPS; o baker não
  mudou as compilações), e conferir no olho as nuvens volumétricas e o rastro do FSR no ultra; o detalhe que
  falta nos modelos segue no `assets/TODO_ASSETS.md`.
- Fase 10 em outro PC: o `Society.exe` abre, toca a música e salva/carrega (critério "abre em outro
  PC" só se confere fora desta VM).
