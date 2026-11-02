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

### Lampião, grade e chaminé de tijolo (Fase 104, nossa)

- **Plano** em `docs/plano_fase104.md`. A chaminé das casas é gerada (`_brick_chimney`, tijolo na célula (7, 1),
  `UV_BRICK`, desenhado no shader); a peça `chimney.glb` do kit não é mais desenhada. `Spec.lantern` (serviços sem arcada
  nem toldo e casas dos artesãos para cima sem toldo): `lantern_pane` entra em `windows()` e acende à noite. A grade do pátio
  do museu é `_gallery_fence`. Antes de dar outra célula da paleta a uma peça gerada, confira (como os testes das Fases
  101 e 104) que nenhuma peça do kit cai nela.

### Árvores de quintal (Fase 105, nossa)

- **Plano** em `docs/plano_fase105.md`, primeira do roteiro `docs/plano_fases_105_109.md` (cidade e porto).
  `ScatterView.Kind.YARD_TREE` (macieira pequena) no fim da lista `NEAR_HOUSE`, no meio da célula; bananeira na tropical.
  **Regra nova no recheio vai no fim da lista dela**: o sorteio da célula anda pela lista em ordem, e assim as peças de
  antes não mudam. A captura com relevo é `tools/capture_phase105.tscn` (a da Fase 95 é na ilha plana, que não tem
  recheio).

### Cais de pedra (Fase 106, nossa)

- **Plano** em `docs/plano_fase106.md`. `HarborView.stone_quay` (lanços retos dos dois lados do entreposto, na linha do
  cais de tábuas) e `_quay_segment`. **Nada que acompanhe a costa pela escada das células**: a linha d'água desenhada é
  curva e não bate com ela. Base de MultiMesh tem de ser de mão direita (`Basis(along, UP, -outward)`), senão as faces
  invertem.

### Barcos de pesca (Fase 107, nossa)

- **Plano** em `docs/plano_fase107.md`. `FishingBoatView` (`GameScreen.fishing_boat_view`): um barco a vela por cabana de
  pesca, `route` (amarra e pesqueiro em água funda), `pose` (ida, volta de pesca e regresso) e `phase_of` (pelo id), no
  tempo de jogo; amarrado com a cabana parada. Captura em `tools/capture_phase107.tscn`.

### Farol (Fase 108, nossa)

- **Plano** em `docs/plano_fase108.md`. `LighthouseView` (`GameScreen.lighthouse_view`): `site` (a ponta livre e baixa mais
  exposta ao mar perto do entreposto, não reservada), `tower_mesh`, `lantern_mesh` (vidro dos postes) e `beam_mesh` (fachos
  aditivos girando à noite). **Efeito transparente sobre o mar precisa de `render_priority` acima da água**, senão ela o
  cobre. Captura em `tools/capture_phase108.tscn`.

### Largo calçado (Fase 109, nossa)

- **Plano** em `docs/plano_fase109.md`. `ForecourtView` (`GameScreen.forecourt_view`): `cells` (o anel livre e quase plano
  em volta dos serviços de `PLAZA_SERVICES`) e `slabs` (lajes no relevo). O recheio deixa essas células limpas
  (`ScatterView.island_context` as soma às portas). Captura em `tools/capture_phase109.tscn`.

### Brilho do sol no mar (Fase 110, nossa)

- **Plano** em `docs/plano_fase110.md`, primeira do roteiro `docs/plano_fases_110_114.md` (sol, trópico e avenida). Global de
  shader `sun_direction` (para o sol, atualizado pela `GameScreen`) e o grupo `Glints` do `shaders/water.gdshader`. O brilho só
  aparece de frente para o sol: a captura (`tools/capture_phase110.tscn`) gira a câmera nos quatro lados.

### Terreiro tropical (Fase 111, nossa)

- **Plano** em `docs/plano_fase111.md`. `RoadMask.yards` e `_stamp_yard`: o lote das casas das ilhas tropicais, crescido, no
  canal b (chão batido) da máscara das estradas, refeito no `refresh` como as trilhas. Captura em
  `tools/capture_phase111.tscn`.

### Coqueiros na rua tropical (Fase 112, nossa)

- **Plano** em `docs/plano_fase112.md`. `ScatterView.Kind.STREET_PALM` (o coqueiro do `TreeModel` reduzido, com o material
  dele) no fim de `NEAR_ROAD`, só nas tropicais.

### Alameda (Fase 113, nossa)

- **Plano** em `docs/plano_fase113.md`. `AvenueView` (`GameScreen.avenue_view`): `cells` (as livres em volta das células
  calçadas da vez, achadas pelo `find` do array) e a faia reduzida num MultiMesh do arquipélago, **sem alcance de
  visibilidade** (contaria do meio do arquipélago). O recheio deixa as células limpas. Captura em `tools/capture_phase113.tscn`.

### Gradil das casas ricas (Fase 114, nossa)

- **Plano** em `docs/plano_fase114.md`. `BuildingKit._front_railing` (casas de `HouseTrim.BALCONIES`, na faixa de `INSET_M`
  entre a parede e a divisa, com o vão da porta).

### Carreira do estaleiro (Fase 115, nossa)

- **Plano** em `docs/plano_fase115.md`, primeira do roteiro `docs/plano_fases_115_119.md` (fazenda, taverna e estaleiro).
  `ShipwayView` (`GameScreen.shipway_view`): `site` (a rampa do lado do mar até a água funda, sem prédio nem estrada no
  caminho), `ramp_mesh` e o casco em obra (`hull_mesh` pelo progresso da encomenda, `hull_transform` com a popa para o mar),
  refeito só quando muda de degrau. Captura em `tools/capture_phase115.tscn`.

### Mesas da taverna (Fase 116, nossa)

- **Plano** em `docs/plano_fase116.md`. `TavernGardenView` (`GameScreen.tavern_garden_view`): `cells` (até `MAX_TABLES`
  células livres em volta de cada taverna, fora do largo e da alameda), mesa com bancos e guarda-sol listrado (duas malhas:
  gomos brancos e gomos tingidos pela instância), fechado à noite (`set_furled`). O recheio deixa as células limpas.
  Captura em `tools/capture_phase116.tscn`.

### Silos das fazendas (Fase 117, nossa)

- **Plano** em `docs/plano_fase117.md`. `FarmSiloView` (`GameScreen.farm_silo_view`): `cells` (a célula livre atrás de
  cada fazenda de `FARMS`), silo de aduelas ou caixa d'água sobre pés (`kind_of`, pelo resto do id: o `hash` de ids pequenos
  puxa para um lado). O recheio deixa a célula limpa. Captura em `tools/capture_phase117.tscn`.

### Chão gasto no pasto (Fase 118, nossa)

- **Plano** em `docs/plano_fase118.md`. `RoadMask.patches` (manchas de borda recortada no canal b: porteira, cocho e duas
  soltas pelo hash, comparadas no `refresh` como as trilhas) e `RoadMask.trough_of` (o cocho junto da cerca de trás), que a
  `PastureTroughView` (`GameScreen.pasture_trough_view`) desenha. Captura em `tools/capture_phase118.tscn`.

### Poças de luz à noite (Fase 119, nossa)

- **Plano** em `docs/plano_fase119.md`. `LightPoolView` (`GameScreen.light_pool_view`): `pools` (postes, fogueiras e portas
  das casas com morador), discos no chão somados pelo `shaders/light_pool.gdshader` (aceso pelo global `night_light`, sem
  luz de verdade), escondidos de dia; a `LampView` avisa com o sinal `rebuilt`. Captura em `tools/capture_phase119.tscn`.

### Postes e fios (Fase 120, nossa)

- **Plano** em `docs/plano_fase120.md`, primeira do roteiro `docs/plano_fases_120_124.md` (fios, riacho e mansarda).
  `PowerLineView` (`GameScreen.power_line_view`): `poles` (ruas até o raio das usinas, resto `POLE_REST` de `x + 3y`, longe
  dos postes de gás), `links` só com vão livre (`clear_span`: fio por cima de prédio entrava na parede) e dois fios por
  ligação pelo `HarborView.rope_span`. Captura em `tools/capture_phase120.tscn`.

### Gavião sobre a cidade (Fase 121, nossa)

- **Plano** em `docs/plano_fase121.md`. `HawkView` (`GameScreen.hawk_view`): `centers` (um por ilha com `MIN_HOUSES` casas,
  mais um a cada `HOUSES_PER_HAWK`), `pose` (círculos altos derivando) e `beat` (planeio quase sempre), com a `hawk_mesh`
  gerada aqui no `shaders/bird.gdshader`. **A câmera da partida fica presa ao chão**: a captura
  (`tools/capture_phase121.tscn`) põe a `Camera3D` à mão e para o processamento da `StrategyCamera`.

### Pedras no rio (Fase 122, nossa)

- **Plano** em `docs/plano_fase122.md`. `RiverStoneView` (`GameScreen.river_stone_view`): `places` (matacões da `RockModel`
  no leito raso dos rios, saindo da água, fora das pontes; seixos na margem baixa e livre). Os rios do v4 correm quase todos
  em gargantas: a captura (`tools/capture_phase122.tscn`) procura a margem mais baixa.

### Borrifo nas falésias (Fase 123, nossa)

- **Plano** em `docs/plano_fase123.md`. `RockView.spray_sites` (as rochas que encostam no mar, com o raio) e `SurfSprayView`
  (`GameScreen.surf_spray_view`): `pick` (um dos pontos mais perto de onde a câmera olha), `spot` (o lado de chão mais baixo
  da rocha) e um punhado de jatos `one_shot` reaproveitados, parados na pausa. Partículas só sobem com o relógio andando: a
  captura (`tools/capture_phase123.tscn`) põe o jogo a 1x.

### Mansarda dos investidores (Fase 124, nossa)

- **Plano** em `docs/plano_fase124.md`. `Spec.mansard` (investidores de duas águas sem ala; na chave), `mansard_levels`,
  `_mansard` (água de baixo íngreme até o rebordo, a de cima quase plana, cumeeira na altura de antes) e `_dormers` (as
  lucarnas da água de baixo); a `_lucarnes` da Fase 39 pula a mansarda. Captura em `tools/capture_phase124.tscn`.

### Recife de coral (Fase 125, nossa)

- **Plano** em `docs/plano_fase125.md`, primeira do roteiro `docs/plano_fases_125_129.md` (recife, alpendre e nuvens).
  `shaders/water.gdshader` (grupo `Reef`, `reef_at`) e `WaterView.reef_min_x` (a borda oeste das regiões tropicais).
  **Hash de ruído em shader sem `sin`**: com as coordenadas do arquipélago o `fract(sin(...))` perde precisão na GPU e o
  desenho sai em escada. Captura em `tools/capture_phase125.tscn`.

### Alpendre tropical (Fase 126, nossa)

- **Plano** em `docs/plano_fase126.md`. No `BuildingKit.spec_for`, as casas de `PORCH_TRIMS` (operários e artesãos) de dois
  andares nas ilhas tropicais ganham `Silhouette.VERANDA` com `court_rows = 1` (a varanda da Fase 23), sem enxaimel, toldo
  nem ala. Captura em `tools/capture_phase126.tscn`.

### Cisternas no cais (Fase 127, nossa)

- **Plano** em `docs/plano_fase127.md`. `HarborView.cistern_places` (no cais de pedra da Fase 106, uma de cada lado, fora da
  largura do entreposto) e `FarmSiloView.cistern_mesh`. Captura: `CAPTURA_SO=porto` no `tools/capture_phase5.tscn`
  (`14b_cisternas.png`).

### Jazidas à vista (Fase 128, nossa)

- **Plano** em `docs/plano_fase128.md`. `DepositView` (`GameScreen.deposit_view`): `patches` (as células de jazida ligadas
  pelos lados) e `places` (o afloramento no meio da mancha livre e as pedras do minério na cor do bem, `ORE_COLORS`); a mina
  em cima tira os da mancha. Captura em `tools/capture_phase128.tscn`.

### Sombra das nuvens (Fase 129, nossa)

- **Plano** em `docs/plano_fase129.md`. `shaders/cloud_shadow.gdshaderinc` (incluído pelo terreno e pela água) e os globais
  `cloud_cover` (a cobertura do `WeatherCycle`) e `cloud_offset` (que a `WeatherView.drift_clouds` soma com o vento a cada
  quadro). Captura em `tools/capture_phase129.tscn` (põe a cobertura direto no global, com a `WeatherView` parada).

### Telhado de sapê (Fase 130, nossa)

- **Plano** em `docs/plano_fase130.md`, primeira do roteiro `docs/plano_fases_130_134.md` (sapê, bueiro e ardósia).
  `BuildingView.thatched` (as casas de `HouseTrim.YARD`) põe o parâmetro de instância `thatch`, e o
  `shaders/building_kit.gdshader` troca as telhas por `thatch_shade` (fiadas, fios e palha velha). Captura em
  `tools/capture_phase130.tscn`.

### Bueiros na rua calçada (Fase 131, nossa)

- **Plano** em `docs/plano_fase131.md`. `ManholeView` (`GameScreen.manhole_view`): `cells` (paralelepípedo da vez pela grade,
  no meio de rua reta) e `cover_mesh`. **O que se põe sobre o paralelepípedo parte de `PavedDual.LIFT_M`**: pela altura da
  estrada fica debaixo do calçamento. Captura em `tools/capture_phase131.tscn`.

### Bomba d'água (Fase 132, nossa)

- **Plano** em `docs/plano_fase132.md`. `WaterPumpView` (`GameScreen.water_pump_view`): `cells` (a célula livre junto de uma
  casa a cada `PUMP_EVERY`, com a rua ao lado, e o lado da rua) e `pump_mesh`. O recheio deixa a célula limpa. Captura em
  `tools/capture_phase132.tscn`.

### Bandeirolas da feira (Fase 133, nossa)

- **Plano** em `docs/plano_fase133.md`. `MarketBuntingView` (`GameScreen.market_bunting_view`): `posts` (os quatro cantos
  do pátio das bancas) e as cordas em xis com o poste e a corda da festa (`FestivalView._post`, `_string`). Captura em
  `tools/capture_phase133.tscn`.

### Ardósia nos prédios de pedra (Fase 134, nossa)

- **Plano** em `docs/plano_fase134.md`. `BuildingView.SLATE_ROOFS` põe o parâmetro de instância `slate`, e o
  `shaders/building_kit.gdshader` troca as telhas por `slate_shade` (placas retangulares cinza-azuladas). As bancas do
  mercado, peças do kit na célula do telhado, ficam de ardósia junto. Captura: a rua dos prédios grandes do
  `tools/capture_phase95.tscn`.

### Galinhas no quintal (Fase 135, nossa)

- **Plano** em `docs/plano_fase135.md`, primeira do roteiro `docs/plano_fases_135_139.md` (galinha, forno e mina).
  `ChickenView` (`GameScreen.chicken_view`): `yards` (a fileira da frente do lote das casas de `HouseTrim.YARD`, uma a cada
  `CHICKEN_EVERY`), `patch` (o trecho de cada galinha), `pose` (anda e bica, no tempo de jogo) e `chicken_mesh`, com a
  plumagem tingida pelo `INSTANCE_CUSTOM` no `shaders/chicken.gdshader`. Captura em `tools/capture_phase135.tscn`.

### Vagoneta e rejeito (Fase 136, nossa)

- **Plano** em `docs/plano_fase136.md`. `SpoilTipView` (`GameScreen.spoil_tip_view`): `sites` (duas células em linha num lado
  de cada mina de `Silhouette.HEADFRAME`), `track` (da parede até a beira do monte), `_heap` e `_rails` numa malha só, e a
  vagoneta (`cart_pose`, `loaded`, `phase_of`) indo e virando só com a mina produzindo. O recheio, os silos e as bombas
  deixam as células limpas (`cells`). Captura em `tools/capture_phase136.tscn`.

### Boca do forno acesa (Fase 137, nossa)

- **Plano** em `docs/plano_fase137.md`. `FurnaceGlowView` (`GameScreen.furnace_glow_view`): `mouth` (no térreo de uma fachada do
  lado das fábricas de `FURNACES`, na parede lisa mais perto do meio), `frame_mesh` (arco de tijolo, soleira e portinhola),
  `glow_mesh` com o fogo do `shaders/furnace_glow.gdshader` (aceso produzindo, `INSTANCE_CUSTOM.r`) e a poça de luz da
  Fase 119 à noite. Captura em `tools/capture_phase137.tscn`.

### Telhado de chapa ondulada (Fase 138, nossa)

- **Plano** em `docs/plano_fase138.md`. `BuildingView.IRON_ROOFS` (as fábricas pesadas) põe o parâmetro de instância
  `corrugated`, e o `shaders/building_kit.gdshader` troca as telhas por `iron_sheet_shade` (ondas, chapas sobrepostas e a
  ferrugem escorrendo das juntas), sem o relevo das telhas no mapa de normais. Captura em `tools/capture_phase138.tscn`.

### Redes de pesca (Fase 139, nossa)

- **Plano** em `docs/plano_fase139.md`. `FishNetView` (`GameScreen.fish_net_view`): `sites` (a célula livre ao lado de cada
  cabana de pesca, mais para o mar, e o lado longe dela), dois cavaletes com a rede recortada em losangos no
  `shaders/fish_net.gdshader` (alpha scissor pela UV em metros) e as caixas de peixe, numa malha de duas superfícies. O
  recheio, os silos e as bombas deixam a célula limpa (`cells`). Captura em `tools/capture_phase139.tscn`.

### Clareira do lenhador (Fase 140, nossa)

- **Plano** em `docs/plano_fase140.md`, primeira do roteiro `docs/plano_fases_140_144.md` (toco, bote e boia).
  `StumpView` (`GameScreen.stump_view`): `cut_cells` / `cut_cells_of` (as células de mata em volta de cada lenhador que o
  desenho corta, mais perto mais cortadas) e os tocos e toras por trecho; a `TreeView` não desenha as árvores delas
  (`is_cut`). As duas guardam os lenhadores pelo id: **só um lenhador que entra ou sai refaz o corte**, só na ilha dele e
  no quadro seguinte (refazer tudo a cada prédio custava 11 ms na obra com a ilha cheia). Captura em
  `tools/capture_phase140.tscn`.

### Árvore seca (Fase 141, nossa)

- **Plano** em `docs/plano_fase141.md`. `ScatterView.Kind.SNAG` (no fim do enum e no fim das listas `NEAR_FOREST` e
  `NEAR_SEA`, para o sorteio de antes não mudar) e `snag_mesh` (tronco nu torto com cinco galhos, madeira cinzenta); só
  nas ilhas temperadas. Captura em `tools/capture_phase141.tscn`.

### Botes no porto (Fase 142, nossa)

- **Plano** em `docs/plano_fase142.md`. `RowboatView` (`GameScreen.rowboat_view`): `loop` (a roda de água funda diante de
  cada entreposto), `pose` (os botes na roda, um em cada sentido, com o arranco da remada), `rower_pose` e `oar_pose`; o
  casco é o `HarborView.boat_mesh`. Captura em `tools/capture_phase142.tscn`.

### Cerca de estacas (Fase 143, nossa)

- **Plano** em `docs/plano_fase143.md`. `Spec.picket` (casas de `HouseTrim.NONE`, os operários, sem pátio; na chave) e
  `BuildingKit._front_picket` (nos trechos do gradil da Fase 114, estacas com a ponta em pirâmide na célula `UV_CANVAS`,
  pintada de creme pelo shader). Captura: `cerca_de_estacas.png` no `tools/capture_phase95.tscn`.

### Boias no porto (Fase 144, nossa)

- **Plano** em `docs/plano_fase144.md`. `BuoyView` (`GameScreen.buoy_view`): `spots` (pares mar adentro diante de cada
  entreposto, além do cais de pedra, a vermelha no +través do mar), `pose` (afundada, subindo, descendo e tombando) e
  `buoy_mesh`. Captura em `tools/capture_phase144.tscn`.

### Relógio da igreja (Fase 145, nossa)

- **Plano** em `docs/plano_fase145.md`, primeira do roteiro `docs/plano_fases_145_149.md` (relógio, cais e cata-vento).
  `ClockView` (`GameScreen.clock_view`): `dials` (dois mostradores na torre do campanário, `Silhouette.BELFRY`), o disco
  aceso à noite pelo `shaders/night_glow.gdshader`, a moldura e os ponteiros marcando a hora do jogo (`hand_angles`).
  **Peça presa na fachada usa `BuildingView.model_place`** (o lugar do modelo com o desvio de meio grau da variação; sem
  ele a parede passava na frente). Captura em `tools/capture_phase145.tscn`.

### Grade e lampiões no cais (Fase 146, nossa)

- **Plano** em `docs/plano_fase146.md`. `QuayRailView` (`GameScreen.quay_rail_view`): `rails` (a grade de ferro na beira dos
  lanços do cais de pedra, aberta nos cabeços e na frente do entreposto) e `lamps` (o poste de gás da rua com o vidro aceso
  num lanço a cada `LAMP_EVERY`). Captura em `tools/capture_phase146.tscn`.

### Mastros no cais (Fase 147, nossa)

- **Plano** em `docs/plano_fase147.md`. `QuayMastView` (`GameScreen.quay_mast_view`): `masts` (na ponta de cada lado do cais de
  pedra), `mast_mesh` e a flâmula de rabo de andorinha (`pennant_mesh`) como `WindFlag`, que o `WeatherView` vira com o
  vento. Captura em `tools/capture_phase147.tscn`.

### Cavalete do lenhador (Fase 148, nossa)

- **Plano** em `docs/plano_fase148.md`. `LumberYardView` (`GameScreen.lumber_yard_view`): `cell_of` (a célula num lado do
  lenhador) e `yard_mesh` (cavalete com a tora, cepo com o machado, lenha rachada e lascas). A clareira corta a célula
  inteira sem toco (`StumpView.cut_cells_of`), e a `TreeView` refaz o corte também na estrada e na derrubada de árvores, no
  quadro seguinte (`_recut`, `_recut_now`). Captura em `tools/capture_phase148.tscn`.

### Cata-vento no pasto (Fase 149, nossa)

- **Plano** em `docs/plano_fase149.md`. `WindpumpView` (`GameScreen.windpump_view`, com o `WeatherView`): `spot` (ao lado do
  cocho de cada pasto), `tower_mesh` e a roda (`rotor_mesh`, `rotor_pose`) que vira para o vento e gira pela força
  (`turn`, `spin_of`). Captura em `tools/capture_phase149.tscn`.

### Coluna de anúncios (Fase 150, nossa)

- **Plano** em `docs/plano_fase150.md`, primeira do roteiro `docs/plano_fases_150_154.md` (coluna, placa e velocípede).
  `AdColumnView` (`GameScreen.ad_column_view`): `cells` (o canto de dentro das esquinas calçadas, achado pelo `find` das
  células calçadas) e `column_mesh` (cartazes coloridos sem texto, cornija e chapéu de ferro). O recheio deixa a célula
  limpa. Captura em `tools/capture_phase150.tscn`.

### Placas das lojas (Fase 151, nossa)

- **Plano** em `docs/plano_fase151.md`. `BuildingKit.SHOP_SIGNS` / `Spec.shop_sign` (na chave): `shop_sign_center` (meia célula
  ao lado da porta, acima do toldo) e `_shop_sign` (braço de ferro, tábua com o painel creme e a figura do ofício, sem
  texto: `_sign_figure`, `_sign_ring`). Captura em `tools/capture_phase151.tscn`.

### Balizas com corrente (Fase 152, nossa)

- **Plano** em `docs/plano_fase152.md`. `BollardView` (`GameScreen.bollard_view`): `edges` (os lados do largo calçado da Fase
  109 que dão para a estrada, com aberturas e sem o lado do poste de gás), `bollard_mesh` e `_chain`, numa malha só.
  Captura em `tools/capture_phase152.tscn`.

### Flores nas sacadas (Fase 153, nossa)

- **Plano** em `docs/plano_fase153.md`. `Spec.balcony_flowers` (engenheiros e investidores; na chave) e `_balcony_box` (a caixa
  de madeira e a folhagem com flores na célula (3, 3) da paleta, `UV_FOLIAGE`, por fora do guarda-corpo). **Teste que
  compara a forma com e sem um detalhe usa a mesma casa** (cada id tem a sua variação). Captura: `sacadas_floridas.png` no
  `tools/capture_phase95.tscn`.

### Velocípede encostado (Fase 154, nossa)

- **Plano** em `docs/plano_fase154.md`. `VelocipedeView` (`GameScreen.velocipede_view`): `spot` (na célula ao lado da porta de
  uma casa dos artesãos a cada `BIKE_EVERY`, no lugar do modelo com `BuildingView.model_place`) e `bike_mesh` (roda grande,
  rodinha, quadro curvo, guidão e selim). Captura: `velocipede.png` no `tools/capture_phase95.tscn`.

### Carneirinhos no mar (Fase 155, nossa)

- **Plano** em `docs/plano_fase155.md`, primeira do roteiro `docs/plano_fases_155_159.md` (carneirinho, papoula e colheita).
  Global `sea_whitecaps` (`WeatherView.whitecaps_of`, pela força do vento) e o grupo `Whitecaps` do `shaders/water.gdshader`
  (`whitecap_at`: uma mancha por célula sorteada a cada volta, comprida de través ao vento, andando com ele e se desfazendo em
  renda). Captura em `tools/capture_phase155.tscn` (põe o vento direto nos globais, com a `WeatherView` parada).

### Papoulas no prado (Fase 156, nossa)

- **Plano** em `docs/plano_fase156.md`. `ScatterView.Kind.POPPIES` (no fim do enum e das listas `OPEN` e `NEAR_ROAD`) só nas
  células de canteiro (`poppy_patch`, ruído de valor com hash aritmético e os nós da última célula guardados: o recheio passa
  por dezenas de milhares de células), nas temperadas e acima da areia (`POPPY_MIN_HEIGHT_M`); `poppy_mesh` (~10 triângulos
  por flor). Captura em `tools/capture_phase156.tscn`.

### Caixas da colheita (Fase 157, nossa)

- **Plano** em `docs/plano_fase157.md`. Na `CropView`, `harvest_shown_at` (nenhum antes do degrau `HARVEST_FROM`, todos no
  cheio), `_harvest_places` (pares de caixotes ou sacos do `CargoKit` no vão entre as fileiras, em cache pelo lote) e os
  MultiMesh `HarvestCrates` e `HarvestSacks` (a peça escondida fica encolhida a zero; `harvest_count` e `harvest_places` para os
  testes). **O material dos sacos do `CargoKit` lê a cor da instância como linear**: cor nova para ele vai com
  `srgb_to_linear()`. Captura em `tools/capture_phase157.tscn`.

### Carroça de lona (Fase 158, nossa)

- **Plano** em `docs/plano_fase158.md`. `CartView.covers` (bem da casa em saco ou caixote, uma casa a cada `COVER_EVERY`),
  `canvas_mesh` (a lona com os arcos, medida na caçamba do modelo do kit: tábuas de z −0,59 a 1,35) e o MultiMesh `Covers`; a
  carga da carroça coberta não aparece. Captura em `tools/capture_phase158.tscn` (ilha plana, mira a carroça de lona mais
  adiantada).

### Tijolos secando (Fase 159, nossa)

- **Plano** em `docs/plano_fase159.md`. `BrickYardView` (`GameScreen.brick_yard_view`): `sites` (três células em fila ao longo
  de um lado da olaria; **o lado de +X da frente fica por último, porque é o da boca do forno da Fase 137**), `cells` (o
  recheio, os silos e as bombas deixam limpas) e `yard_mesh` (fileiras de tijolos crus em grade com as tábuas na cumeeira e o
  monte de barro). Captura em `tools/capture_phase159.tscn` (a câmera do lado do pátio: o offset da câmera do `CameraRig` é
  (sen yaw, ·, cos yaw)).

### Cunhais de pedra (Fase 160, nossa)

- **Plano** em `docs/plano_fase160.md`, primeira do roteiro `docs/plano_fases_160_164.md` (cunhal, deriva e horta; o Anno não
  foi aberto: o dono estava usando o PC, e as ideias vieram das capturas guardadas). `Spec.quoins` (artesãos e engenheiros; na
  chave) e `BuildingKit._quoins` (blocos alternados nas quatro quinas, a da ala até o alto dela, a da frente pelo balanço). **A
  casa dos investidores está no teto de 20.000 triângulos** do `test_building_kit.gd` (19.480): detalhe novo nela precisa caber.
  Captura: `cunhais.png` no `tools/capture_phase95.tscn`.

### Madeira à deriva (Fase 161, nossa)

- **Plano** em `docs/plano_fase161.md`. `ScatterView.Kind.DRIFTWOOD` (no fim do enum e da lista `NEAR_SEA`) só nas células baixas
  da costa (`DRIFTWOOD_MAX_HEIGHT_M`) e de chão pouco inclinado (`DRIFTWOOD_MAX_SLOPE`), deitado com o terreno; `driftwood_mesh`.
  **Peça nova do recheio vai no fim do enum**: os testes das peças de antes conferem só a ordem relativa. Captura em
  `tools/capture_phase161.tscn`.

### Cascalho nas encostas (Fase 162, nossa)

- **Plano** em `docs/plano_fase162.md`. `ScatterView.Kind.SCREE` (no fim do enum e das listas `OPEN`, `NEAR_FOREST` e `NEAR_SEA`)
  só nas células de encosta (`cell_relief` pelos cantos, a partir de `SCREE_MIN_RELIEF_M`), deitado no plano dela
  (`cell_normal`); `scree_mesh`. Captura em `tools/capture_phase162.tscn`.

### Horta no quintal (Fase 163, nossa)

- **Plano** em `docs/plano_fase163.md`. `KitchenGardenView` (`GameScreen.kitchen_garden_view`): `cells`/`spot` (a célula de trás
  das casas de camponeses e operários no resto `GARDEN_REST` do id; **a mesma célula da fogueira, resto 0, e do varal, resto 1**)
  e `garden_mesh` (canteiro, couves, alfaces e a tenda de feijão). O recheio e as bombas deixam a célula. **Não misture
  `CropView._part` (põe normal) com `VertexShapes` (sem normal) no mesmo `SurfaceTool`**: o Godot reclama no log; aqui as folhas
  vão por `_blob`, sem normal. Captura: `hortas_*.png` no `tools/capture_phase95.tscn`.

### Caldeira das árvores (Fase 164, nossa)

- **Plano** em `docs/plano_fase164.md`. Na `AvenueView`, `pit_mesh` (anel de pedra, terra e grade de ferro) num MultiMesh
  `TreePits` no pé de cada árvore da alameda, alinhado com a rua; `pit_places` para os testes. Captura: `caldeiras.png` no
  `tools/capture_phase113.tscn`.

### Chão batido das fábricas (Fase 165, nossa)

- **Plano** em `docs/plano_fase165.md`, primeira do roteiro `docs/plano_fases_165_169.md` (chão batido, feno e gaivota; o Anno
  não foi aberto: o dono estava no PC). `RoadMask.works` (o lote dos prédios de produção, menos as fazendas de campo, crescido de
  `WORKS_REACH_M`) no canal b, pelo `_stamp_yard` com a borda recortada (`ragged`, `_edge_noise`). Captura em
  `tools/capture_phase165.tscn`.

### Medas de feno (Fase 166, nossa)

- **Plano** em `docs/plano_fase166.md`. `HaystackView` (`GameScreen.haystack_view`): `cells` (a célula livre ao lado das fazendas
  de ovelhas, porcos e trigo, mais perto do meio da face de +X da frente, fora do silo e das outras peças de célula) e
  `stack_mesh` (corpo em barril, cúpula em anéis e a vara). O recheio e as bombas deixam a célula. **Anel girado em volta de +y:
  o ângulo anda no sentido do `VertexShapes.cylinder`** (x = cos, z = −sen), senão as faces ficam para dentro. Captura em
  `tools/capture_phase166.tscn`.

### Capim alto nos terrenos vazios (Fase 167, nossa)

- **Plano** em `docs/plano_fase167.md`. `ScatterView.Kind.TALL_GRASS` (no fim do enum e da lista `OPEN`) só nas manchas de
  `tall_grass_patch` (o ruído das papoulas com outro passo e semente), fora dos canteiros de papoulas e das tropicais;
  `tall_grass_mesh`. Captura em `tools/capture_phase167.tscn`.

### Gaivotas no cais (Fase 168, nossa)

- **Plano** em `docs/plano_fase168.md`. `PerchedGullView` (`GameScreen.perched_gull_view`): uma gaivota de pé em parte dos
  cabeços que a `HarborView` desenhou (`bollard_places`, e o sinal `rebuilt` a cada desenho), virando de tempos em tempos pelo
  tempo de jogo (`heading_at`, `advance`); `gull_mesh`. Captura em `tools/capture_phase168.tscn`.

### Barril de chuva (Fase 169, nossa)

- **Plano** em `docs/plano_fase169.md`. `RainBarrelView` (`GameScreen.rain_barrel_view`): `spot` (a quina de −X de trás das casas
  de camponeses e operários do resto certo, no lugar do modelo, com a calha até o beiral ou o da ala), `_cell`/`cells` (a célula
  só pelo lote, sem a `Simulation`, para o recheio, as bombas, os silos e as medas a deixarem limpa), `barrel_body_mesh` e o cano
  esticado até o beiral (`pipe_mesh`, `pipe_place`), em dois MultiMesh (a malha inteira refeita em GDScript custava ~120 ms
  com 300 barris). Captura: `barris_de_chuva.png` no `tools/capture_phase95.tscn`.

### Barranco de terra vermelha (Fase 170, nossa)

- **Plano** em `docs/plano_fase170.md`, primeira do roteiro `docs/plano_fases_170_174.md` (laterita, lenha e carrinho; o Anno
  não foi aberto: o dono estava no PC). O material do terreno das ilhas tropicais leva `mud_tint` =
  `TerrainView.TROPICAL_MUD_TINT`: a margem dos rios em laterita vermelha. Captura em `tools/capture_phase170.tscn`.

### Lenha na parede (Fase 171, nossa)

- **Plano** em `docs/plano_fase171.md`. `LogPileView` (`GameScreen.log_pile_view`): `spot`/`_cell`/`cells` (a parede de +X do
  corpo das casas de camponeses e operários do resto certo, na célula do lado livre; o recheio e as bombas a deixam) e
  `pile_mesh`, num MultiMesh. Captura: `lenha_*.png` no `tools/capture_phase95.tscn` (rua nova de casas espaçadas).

### Carrinho de mão (Fase 172, nossa)

- **Plano** em `docs/plano_fase172.md`. `WheelbarrowView` (`GameScreen.wheelbarrow_view`): `cells` (a célula livre atrás de um
  prédio de produção a cada `BARROW_EVERY`, no pátio da Fase 165; o recheio e as bombas a deixam) e `barrow_mesh`, num
  MultiMesh. Captura em `tools/capture_phase172.tscn`.

### Tina de lavar (Fase 173, nossa)

- **Plano** em `docs/plano_fase173.md`. Na `YardView`, `tub_place` (ao lado de cada varal, mais para longe da casa) e `tub_mesh`
  num MultiMesh `Washtubs` (`tub_count`, `tub_transform`). Captura: `tina_de_lavar.png` no `tools/capture_phase95.tscn`.

### Banco na porta (Fase 174, nossa)

- **Plano** em `docs/plano_fase174.md`. `DoorBenchView` (`GameScreen.door_bench_view`): `spot` (no quintal cercado da frente de
  parte das casas dos camponeses, encostado na parede além dos vasos, no lugar do modelo) e `bench_mesh`, num MultiMesh. Captura:
  `banco_na_porta.png` no `tools/capture_phase95.tscn`.

### Espantalho no campo (Fase 175, nossa)

- **Plano** em `docs/plano_fase175.md`, primeira do roteiro `docs/plano_fases_175_179.md` (espantalho, cegonha e vaga-lume; o
  Anno não foi aberto: o dono estava no PC). `ScarecrowView` (`GameScreen.scarecrow_view`): `spot` (um campo a cada
  `SCARECROW_EVERY` cuja fazenda, pelo `module_owner`, planta uma das `CROPS`; no vão do meio entre as fileiras, pela conta da
  `CropView`) e `scarecrow_mesh`, num MultiMesh. Captura em `tools/capture_phase175.tscn`.

### Cegonha na chaminé (Fase 176, nossa)

- **Plano** em `docs/plano_fase176.md`. `StorkView` (`GameScreen.stork_view`): `has_nest` (camponeses e operários a cada
  `STORK_EVERY`, nas temperadas), `nest_place` (o capitel da chaminé, no lugar do modelo), `nest_mesh` e `stork_mesh`, virando pelo
  `PerchedGullView.heading_at`. **A chaminé com ninho não fumega** (`ChimneySmokeView.chimney_world` a pula). Captura em
  `tools/capture_phase176.tscn` (a câmera à mão: a da partida fica presa ao chão).

### Postigos nas janelas (Fase 177, nossa)

- **Plano** em `docs/plano_fase177.md`. `Spec.shutters` (todas as casas de `SHUTTER_TRIMS`; na chave) e `BuildingKit._shutters`
  (duas folhas por janela do corpo, na célula (1, 1) da paleta, `UV_SHUTTER`). O `shaders/building_kit.gdshader` pinta a célula
  numa das quatro cores de postigo pelo lugar do prédio (`shutter_pick`, hash inteiro da origem do modelo), com as réguas.
  Captura: as ruas do `tools/capture_phase95.tscn`.

### Vaga-lumes no prado (Fase 178, nossa)

- **Plano** em `docs/plano_fase178.md`. `FireflyView` (`GameScreen.firefly_view`): `swarms` (a rede de pontos a cada
  `SWARM_STEP` células, em terra livre longe de prédio e estrada, mais na beira da mata) e `flies`, num MultiMesh com o dado da
  instância, escondido de dia; o `shaders/firefly.gdshader` os faz vagar e piscar no tempo visual, acesos pelo `night_light`.
  Captura em `tools/capture_phase178.tscn`.

### Juncos na margem (Fase 179, nossa)

- **Plano** em `docs/plano_fase179.md`. `ScatterView.Kind.REEDS` (no fim do enum e nas `PLANTS`) e `reeds_mesh`; `_reeds` põe as
  touceiras na terra encostada no rio, na margem baixa (`REEDS_MAX_HEIGHT_M`), com **sorteio próprio depois das outras peças da
  célula** (a regra dela não muda, e o recheio de antes sai igual). Captura em `tools/capture_phase179.tscn`.

### Borboletas nos canteiros (Fase 180, nossa)

- **Plano** em `docs/plano_fase180.md`, primeira do roteiro `docs/plano_fases_180_184.md` (borboleta, correio e galo; o Anno não
  foi aberto: o dono estava no PC). `ButterflyView` (`GameScreen.butterfly_view`): `groups` (a rede de pontos a cada
  `GROUP_STEP` células, sobre as papoulas nas temperadas e no capim aberto nas tropicais) e `butterfly_mesh`, num MultiMesh com
  o dado da instância, escondido à noite; o `shaders/butterfly.gdshader` as faz esvoaçar e bater as asas no tempo visual.
  Captura em `tools/capture_phase180.tscn`.
- **`IslandDirty`** (`presentation/island_dirty.gd`): quais ilhas uma vista do arquipélago inteiro refaz — a obra, a estrada e as
  árvores dizem a ilha, o demolido sai pela ilha guardada; as borboletas e os vaga-lumes (Fase 178) refazem só ela, com o hash
  aritmético `FireflyView.cell_hash` (o `hash()` de um Array por ponto custava dezenas de ms).

### Caixa de correio (Fase 181, nossa)

- **Plano** em `docs/plano_fase181.md`. `PostBoxView` (`GameScreen.post_box_view`): `spots` (células calçadas do desenho
  `posmod(7x + 13y, POST_EVERY)`, fora das dos postes de gás e da escada diagonal, no lado da calçada como o poste) e `box_mesh`
  (sólido de revolução por `_lathe`), num MultiMesh. Captura: `caixa_de_correio.png` no `tools/capture_phase150.tscn`.

### Galo do cata-vento (Fase 182, nossa)

- **Plano** em `docs/plano_fase182.md`. `WeathercockView` (`GameScreen.weathercock_view`, com o `WeatherView`): `spot` (o alto da
  cumeeira das fazendas de `FARMS` das temperadas, no lugar do modelo), `mast_mesh` e `cock_mesh` (o galo em chapa recortada,
  `_plate`, visto dos dois lados), virando a cabeça para o vento (`turn`). Captura em `tools/capture_phase182.tscn` (a câmera à
  mão no alto do telhado, com as árvores em volta derrubadas).

### Barco na areia (Fase 183, nossa)

- **Plano** em `docs/plano_fase183.md`. `BeachBoatView` (`GameScreen.beach_boat_view`): `sites` (a célula de praia livre junto da
  cabana de pesca, encostada no mar pelo lado, com as vizinhas ao longo da costa livres), `boat_place` (o `HarborView.boat_mesh`
  de borco ao longo da costa) e `oar_places_of` (os remos do `RowboatView` na areia). O recheio deixa as três células (`cells`,
  no `ScatterView.island_context`). Captura em `tools/capture_phase183.tscn`.

### Limo na pedra (Fase 184, nossa)

- **Plano** em `docs/plano_fase184.md`. `RockView.sea_material` (`shaders/sea_rock.gdshader`: a rocha triplanar de sempre com a faixa
  de limo e sargaço junto da linha d'água, a pedra molhada acima e a crosta da maré em manchas) nos rochedos, nas rochas da
  falésia e nos matacões do rio; as pedras soltas dos barrancos e das jazidas seguem com o `RockView.material`. Captura em
  `tools/capture_phase184.tscn`.

### Hera nas paredes (Fase 185, nossa)

- **Plano** em `docs/plano_fase185.md`, primeira do roteiro `docs/plano_fases_185_189.md` (hera, estaca e arco-íris; o Anno não foi
  aberto: o dono estava no PC). `BuildingView.ivy_of` põe o parâmetro de instância `ivy` (cheio nos serviços de pedra de
  `IVY_SERVICES`, menos numa casa a cada `IVY_HOUSE_EVERY` dos artesãos para cima, nada nas tropicais) e o
  `shaders/building_kit.gdshader` desenha a hera só nas células de parede, em colunas subindo do chão. **Parâmetro de instância
  não aparece no `get_shader_uniform_list`** (o teste confere os uniformes comuns). Captura: as ruas do `tools/capture_phase95.tscn`.

### Estacas na água (Fase 186, nossa)

- **Plano** em `docs/plano_fase186.md`. `MooringPileView` (`GameScreen.mooring_pile_view`): `spots` (diante do entreposto e na ponta
  do píer, pelo `HarborView.seaward`, onde boia) e `cluster_mesh` (cinco estacas amarradas, com o limo junto da água), num
  MultiMesh. **Objeto que entra fundo na água vira coluna branca pela espuma por profundidade**: o pé fica a `FOOT_M` (meio
  metro). Captura em `tools/capture_phase186.tscn`.

### Placa na encruzilhada (Fase 187, nossa)

- **Plano** em `docs/plano_fase187.md`. `SignpostView` (`GameScreen.signpost_view`): `junctions` (as células de terra com três ou
  quatro estradas pelos lados, sem casa a até `TOWN_CELLS`; o poste no lado sem estrada ou no canto entre duas) e uma tábua
  por estrada (`arm_mesh`, o +x apontando), em dois MultiMesh. Captura em `tools/capture_phase187.tscn`.

### Arco-íris (Fase 188, nossa)

- **Plano** em `docs/plano_fase188.md`. `RainbowView` (`GameScreen.rainbow_view`, com o `SkyAdapter`): `amount_at` (função pura da
  semente e das horas: logo depois da chuva do dia de chuva), `place` (o anel de 42 graus em volta do ponto oposto ao sol, a
  `DISTANCE_M` da câmera a cada quadro; nada com o sol baixo ou alto demais) e `ring_mesh` no `shaders/rainbow.gdshader`
  (somado, cortado no mar). `hours_override` prende a hora nas capturas. Captura em `tools/capture_phase188.tscn`.

### Focas nas pedras (Fase 189, nossa)

- **Plano** em `docs/plano_fase189.md`. `SealView` (`GameScreen.seal_view`): `colonies` (pontos a cada `COLONY_STEP` células, a
  célula da costa baixa e livre mais perto, longe dos prédios por blocos de `WILD_CELLS`; só temperadas) e `seals` (duas a
  quatro deitadas, a cabeça para o mar); o corpo parado (`body_mesh`) e a cabeça (`head_mesh`) erguendo pelo `head_lift`, em
  dois MultiMesh. Captura em `tools/capture_phase189.tscn`.

### Colmeias de palha (Fase 190, nossa)

- **Plano** em `docs/plano_fase190.md`, primeira do roteiro `docs/plano_fases_190_194.md` (colmeia, pombal e varal; o Anno não foi
  aberto: o dono estava no PC). `BeehiveView` (`GameScreen.beehive_view`): `cells` (a célula livre do lado de −X das fazendas de
  `FARMS`, o oposto das medas) e `hive_mesh` (o banco com três colmeias de palha), e as abelhas no `shaders/bee.gdshader`. O
  recheio deixa a célula. As capturas das Fases 191 e 193 herdam o `tools/capture_phase190.gd` (`_shoot`, `_away_from_farm`).

### Pombal (Fase 191, nossa)

- **Plano** em `docs/plano_fase191.md`. `DovecoteView` (`GameScreen.dovecote_view`): `spot` (a célula na diagonal do canto da frente
  de +X das fazendas de `FARMS` do resto certo, se livre), `dovecote_mesh` e os pombos pousados da `BirdView` nos `PERCHES`,
  virando pelo `PerchedGullView.heading_at`. Captura em `tools/capture_phase191.tscn`.

### Roupa sobre a rua (Fase 192, nossa)

- **Plano** em `docs/plano_fase192.md`. `StreetLaundryView` (`GameScreen.street_laundry_view`): `lines` (a casa de operários do resto
  certo com uma rua de uma célula diante dela e outra casa de operários virada para a rua do outro lado: o varal de beira a
  beira, a `HEIGHT_M`), o cabo pelo `HarborView.rope_span` e a roupa nas cores do `YardView.CLOTH_COLORS`, numa malha só.
  Captura em `tools/capture_phase192.tscn` (ilha plana, a câmera posta na rua).

### Carroça de feno parada (Fase 193, nossa)

- **Plano** em `docs/plano_fase193.md`. `HayWagonView` (`GameScreen.hay_wagon_view`): `cells` (a célula livre vizinha das medas da
  Fase 166, numa fazenda a cada `WAGON_EVERY`), `wagon_place` (o `CartView.model_mesh` sem cavalo, tombado para a frente) e
  `load_mesh` (o feno em camadas moles, `PerchedGullView._blob`). O recheio deixa a célula. Captura em `tools/capture_phase193.tscn`.

### Escada do cais (Fase 194, nossa)

- **Plano** em `docs/plano_fase194.md`. `QuayStairsView` (`GameScreen.quay_stairs_view`): `flights` (o alto de cada lance, no lanço do
  cais de pedra que passa `STAIR_CLEAR_M` da largura do entreposto, de cada lado), `step_places` (os degraus de pedra até dentro
  da água, encostados no paredão, na pedra das paredes do cais) e a argola (`ring_mesh`). Captura em `tools/capture_phase194.tscn`.

### Cemitério da igreja (Fase 195, nossa)

- **Plano** em `docs/plano_fase195.md`, primeira do roteiro `docs/plano_fases_195_199.md` (cemitério, pato e rede; o Anno não foi
  aberto: o dono estava no PC). `GraveyardView` (`GameScreen.graveyard_view`): `layout`/`cells` (as fileiras livres atrás da
  igreja, além do anel do largo da Fase 109, e o portão), `graves_of` (as covas com a lápide virada para a igreja, o tipo, o
  tombo e o tom pelo hash) e `walls` (o muro baixo nas bordas, aberto no portão), em quatro MultiMesh. O recheio e as bombas
  deixam as células. Captura em `tools/capture_phase195.tscn`.

### Patos na água (Fase 196, nossa)

- **Plano** em `docs/plano_fase196.md`. `DuckView` (`GameScreen.duck_view`): `candidates` (os bandos que o terreno permite, uma vez
  por mundo: a água rasa da beira de terra baixa e a roda sobre fundo de `RING_FLOOR_M`, a `LAND_CLEAR_M` da terra, fora da
  espuma da linha d'água), `flocks` (sem os perto dos portos), `pose` e `dabble` (a roda no tempo de jogo, o mergulho girando
  no peito). **Busca pela grade inteira em GDScript pesa**: leia o `PackedByteArray` direto e pule cedo o que não serve antes de
  chamar função por célula. Captura em `tools/capture_phase196.tscn`.

### Casinha do cão (Fase 197, nossa)

- **Plano** em `docs/plano_fase197.md`. `KennelView` (`GameScreen.kennel_view`): `spot`/`_cell`/`cells` (a célula do lado de −X do
  lote, na fileira da frente, das casas com cão do `AnimalView.DOG_EVERY`; o recheio e as bombas a deixam) e `kennel_mesh`, num
  MultiMesh. Captura: `casinha_do_cao.png` no `tools/capture_phase95.tscn`.

### Bancos no cais (Fase 198, nossa)

- **Plano** em `docs/plano_fase198.md`. `QuayBenchView` (`GameScreen.quay_bench_view`): `benches` (nos lanços do cais de pedra do
  resto `BENCH_REST`, para dentro da beira, a `CLEAR_M` dos lampiões, das cisternas, dos mastros e das escadas) com o banco de
  praça da decoração (`DecorationView._bench`), num MultiMesh. Captura em `tools/capture_phase198.tscn`.

### Rede na varanda (Fase 199, nossa)

- **Plano** em `docs/plano_fase199.md`. `HammockView` (`GameScreen.hammock_view`): `hang` (pela forma: o vão do lado da porta entre
  dois esteios da varanda, `post_xs` com a conta da `BuildingKit._veranda`), `spot` (no lugar do modelo), `hammock_mesh` (o pano
  listrado, as varas e os cabos) e `swing` (o balanço em volta dos nós), num MultiMesh sem descarte de face. Mudou a varanda,
  confira `post_xs`. Captura em `tools/capture_phase199.tscn`.

### Gato na porta (Fase 200, nossa)

- **Plano** em `docs/plano_fase200.md`, primeira do roteiro `docs/plano_fases_200_204.md` (gato, poço e carrinho; o Anno não foi
  aberto: o dono estava no PC). `CatView` (`GameScreen.cat_view`): `spot` (ao lado da porta das casas do resto certo sem cão,
  pela conta da porta do banco da Fase 174), `body_mesh` e `head_mesh` (a pelagem na cor da instância) e o giro da cabeça no
  `shaders/cat_head.gdshader` (`glance`, `glance_data`), em dois MultiMesh sem sombra. **Subida de classe é o sinal
  `house_upgraded`**: o `building_state_changed` dispara a cada troca de estado das fábricas, e uma vista de casas que se refaz
  nele (chamando `spec_for` em centenas delas) pesa no quadro. Captura: `gato_na_porta.png` no `tools/capture_phase95.tscn`.

### Poço da vila (Fase 201, nossa)

- **Plano** em `docs/plano_fase201.md`. `WellView` (`GameScreen.well_view`): `cells` (as casas dos camponeses do resto certo, fora
  das da bomba, pela busca da bomba) e `well_mesh` (o bocal em fiadas, `_ring`), num MultiMesh. A busca da bomba d'água foi
  separada em `WaterPumpView.taken_cells` e `beside_street`: **peça nova junto da rua usa as duas** (e a lista das tomadas
  ganha a peça nova, para a bomba e o poço desviarem dela). Captura em `tools/capture_phase201.tscn`.

### Secadouro de peixe (Fase 202, nossa)

- **Plano** em `docs/plano_fase202.md`. `FishRackView` (`GameScreen.fish_rack_view`): `sites`/`cells` (a célula livre ao lado de
  cada cabana de pesca das temperadas, na metade da terra, fora das redes e do barco virado; o recheio e as bombas a deixam) e
  `rack_mesh` (as varas em X e os peixes de `_fish`, lâminas dos dois lados), num MultiMesh. Captura em
  `tools/capture_phase202.tscn`.

### Carrinho de feira (Fase 203, nossa)

- **Plano** em `docs/plano_fase203.md`. `MarketCartView` (`GameScreen.market_cart_view`): `cells` (a célula da rua ao lado de cada
  mercado, pela busca da bomba) e `cart_mesh`, num MultiMesh. **Peça que usa `WaterPumpView.taken_cells` não pode entrar nela**
  (a lista chamaria a si mesma): a bomba e o poço desviam do carrinho à parte, nas buscas deles. Captura em
  `tools/capture_phase203.tscn`.

### Guarda-sol de palha (Fase 204, nossa)

- **Plano** em `docs/plano_fase204.md`. `PalapaView` (`GameScreen.palapa_view`): `cells` (a areia livre perto do mar em volta do
  entreposto e da cabana de pesca das tropicais, a partir de `near_of`, que no entreposto passa do cais de pedra) e
  `palapa_mesh`, num MultiMesh. **O cais de pedra é só desenho**: a célula debaixo dele parece livre; peça que procura areia em
  volta do entreposto precisa da folga. **O recheio se refaz até `ScatterView.FAR_REACH` em volta de um prédio novo**: peça cuja
  célula fica longe do prédio que a cria entra lá. **As buscas junto da rua ficam guardadas** (`WaterPumpView.remembered`,
  esquecidas a cada obra, estrada, trilho, árvore, subida de classe e troca de mundo, só com a vista da bomba na árvore): lista
  nova cara do mesmo tipo entra nela. Captura em `tools/capture_phase204.tscn`.

### Estandartes na fachada (Fase 205, nossa)

- **Plano** em `docs/plano_fase205.md`, primeira do roteiro `docs/plano_fases_205_209.md` (estandarte, bebedouro e lanterna; o
  Anno não foi aberto: o dono estava no PC). `BannerView` (`GameScreen.banner_view`): `places_of` (as divisas da célula da porta
  dos serviços de `SERVICES`, no alto do segundo andar, pela conta da porta do banco da Fase 174) e `banner_mesh`, num MultiMesh
  com o `shaders/banner.gdshader` (a cor do prédio e a fase no dado da instância; o balanço pelo vento global, menor que o braço,
  para o pano nunca entrar na parede). Captura: `estandartes.png` no `tools/capture_phase95.tscn`.

### Bebedouro de cavalos (Fase 206, nossa)

- **Plano** em `docs/plano_fase206.md`. `HorseTroughView` (`GameScreen.horse_trough_view`): `cells` (a célula encostada na taverna
  pelo lado mais perto da porta, fora das tomadas e do carrinho, guardada na memória da bomba) e `trough_mesh`, num MultiMesh. A
  bomba e o poço desviam das peças escolhidas antes deles pela `WaterPumpView.street_pieces` (o carrinho e o bebedouro). **As
  buscas de célula se consultam em cadeia** (as mesas, os silos, as medas, a lista das tomadas): antes de fazer uma peça
  desviar de outra, confira que a outra não chega nela, senão a busca chama a si mesma. Captura em `tools/capture_phase206.tscn`.

### Pinheiro-anão na encosta (Fase 207, nossa)

- **Plano** em `docs/plano_fase207.md`. `ScatterView.Kind.ROCK_PINE` (no fim do enum e das listas `OPEN` e `NEAR_FOREST`, entre as
  `PLANTS`) só nas células de desnível `ROCK_PINE_MIN_RELIEF_M` das temperadas, de pé; `rock_pine_mesh`. Captura em
  `tools/capture_phase207.tscn`.

### Rama de tecido (Fase 208, nossa)

- **Plano** em `docs/plano_fase208.md`. `TenterView` (`GameScreen.tenter_view`): `sites`/`cells` (três células em fila no meio de um
  lado da tecelagem, o de trás primeiro, como o pátio de tijolos da Fase 159; o recheio e as bombas as deixam) e `tenter_mesh`,
  num MultiMesh. Captura: `ramas_de_tecido.png` no `tools/capture_phase95.tscn`.

### Lanterna nas carroças (Fase 209, nossa)

- **Plano** em `docs/plano_fase209.md`. `CartView.lantern_mesh`, `lantern_glass_mesh` e `with_lantern` (a armação e o vidro como
  superfícies a mais da malha do corpo, no `night_glow` com o alfa 0 do vértice marcando o vidro). **Peça presa num objeto que
  anda vai na malha dele**: camada própria reposicionada a cada quadro custa caro com centenas de instâncias. Captura em
  `tools/capture_phase209.tscn`.

### Pombos na cumeeira (Fase 210, nossa)

- **Plano** em `docs/plano_fase210.md`, primeira do roteiro `docs/plano_fases_210_214.md` (pombo, mó e buxo; o Anno não foi aberto:
  o dono estava no PC). `RoofPigeonView` (`GameScreen.roof_pigeon_view`): `pigeons` (a fila na capa da cumeeira das casas de duas
  águas do resto certo, longe da chaminé) e `pigeon_mesh` (bolas de 6 × 3 faces), num MultiMesh sem sombra. **Peça que se repete
  centenas de vezes pede poucas faces**: as bolas do `PerchedGullView._blob` custaram ~1 FPS. Captura: `pombos_na_cumeeira.png`
  no `tools/capture_phase95.tscn` (câmera à mão, `_aimed`).

### Mós no moinho (Fase 211, nossa)

- **Plano** em `docs/plano_fase211.md`. `MillstoneView` (`GameScreen.millstone_view`): `sites`/`cells` (a célula do meio de um lado
  do moinho, nunca na frente das pás; o recheio e as bombas a deixam) e `millstone_mesh`, num MultiMesh. Captura:
  `mos_no_moinho.png` no `tools/capture_phase95.tscn`.

### Buxo na porta (Fase 212, nossa)

- **Plano** em `docs/plano_fase212.md`. `TopiaryView` (`GameScreen.topiary_view`): `places_of` (os dois lados da porta das casas de
  pórtico, por fora das colunas, pela conta da porta do banco da Fase 174) e `pot_mesh`, num MultiMesh. Captura:
  `buxo_na_porta.png` no `tools/capture_phase95.tscn`.

### Lenha da padaria (Fase 213, nossa)

- **Plano** em `docs/plano_fase213.md`. `OvenWoodView` (`GameScreen.oven_wood_view`): `spot` (no referencial da boca do forno da
  Fase 137, `ALONG_M` ao lado, só com a célula do lado livre) e `wood_mesh`, num MultiMesh. **Peça presa na fachada de lado
  confere a célula do lado**: com o vizinho encostado, entraria na parede dele. Captura: `lenha_da_padaria.png` no
  `tools/capture_phase95.tscn` (a padaria sozinha no fim da rua espaçada).

### Escada de mão (Fase 214, nossa)

- **Plano** em `docs/plano_fase214.md`. `LadderView` (`GameScreen.ladder_view`): `spot`/`_cell`/`cells` (a parede de −X do corpo
  das casas de duas águas do resto certo, na metade de trás, com a célula do lado livre; o recheio e as bombas a deixam) e
  `ladder_mesh` (esticada até o beiral), num MultiMesh. Captura: `escada_de_mao.png` no `tools/capture_phase95.tscn`.

### Tábuas secando na serraria (Fase 215, nossa)

- **Plano** em `docs/plano_fase215.md`, primeira do roteiro `docs/plano_fases_215_219.md` (tábua, cortina e andorinha; o Anno não
  foi aberto: o dono estava no PC). `PlankStackView` (`GameScreen.plank_stack_view`): `sites`/`cells` (as duas células do meio do
  lado de −X do modelo, oposto à roda d'água, ou dos fundos; o recheio e as bombas as deixam) e `stack_mesh` (camadas de tábuas
  com os tabiques sobre dormentes e a cobertura de tábuas velhas), num MultiMesh. Captura em `tools/capture_phase215.tscn`.

### Monte de carvão na usina (Fase 216, nossa)

- **Plano** em `docs/plano_fase216.md`. `CoalHeapView` (`GameScreen.coal_heap_view`): `sites`/`cells` (as duas células do meio de um
  lado da usina a carvão, pela regra das tábuas da Fase 215; o recheio e as bombas as deixam) e `heap_mesh` (a baia de tábuas e o
  monte de duas cristas pelo `height_at`, em faces chapadas com `set_smooth_group(-1)`, e a pá), num MultiMesh. Captura em
  `tools/capture_phase216.tscn`.

### Cortinas nas janelas (Fase 217, nossa)

- **Plano** em `docs/plano_fase217.md`. `Spec.curtains` (todas as casas; na chave) e `BuildingKit._curtains` (dois panos franzidos
  e a sanefa em cada janela do corpo, em `CURTAIN_X`, entre o vidro e o caixilho) na célula (0, 0) da paleta (`UV_CURTAIN`: a
  fileira de cima inteira o kit não usa), pintada pelo `shaders/building_kit.gdshader` numa cor de pano por casa
  (`curtain_pick`), com as pregas. Captura em `tools/capture_phase217.tscn`.

### Andorinhas no campanário (Fase 218, nossa)

- **Plano** em `docs/plano_fase218.md`. `SwallowView` (`GameScreen.swallow_view`): `towers` (o meio da sineira das igrejas, pelo
  `BuildingKit.belfry_center` no lugar do modelo), `pose` (elipses inclinadas em oito em volta dela), `beat` (rajadas) e
  `swallow_mesh` no `shaders/bird.gdshader`, num MultiMesh sem sombra, no tempo de jogo; some à noite. Captura em
  `tools/capture_phase218.tscn` (a câmera à mão).

### Balanço e gangorra na escola (Fase 219, nossa)

- **Plano** em `docs/plano_fase219.md`. `SideYard` (`presentation/side_yard.gd`): a busca das duas células do meio de um lado de um
  prédio, na ordem pedida no referencial do modelo (`pick`, `pair`, `is_free`, `cells_of`, `place`), usada pelas tábuas, pelo
  carvão e pelo pátio da escola. **Pátio novo de lado usa o `SideYard`** e põe na `taken` dele as células dos pátios de antes.
  `PlaygroundView` (`GameScreen.playground_view`): `sites`/`cells` e `playground_mesh` (o balanço em cavalete e a gangorra), num
  MultiMesh. Captura em `tools/capture_phase219.tscn`.

### Bomba de incêndio no quartel (Fase 220, nossa)

- **Plano** em `docs/plano_fase220.md`, primeira do roteiro `docs/plano_fases_220_224.md` (bomba, barril e lençol; o Anno não foi
  aberto: o dono estava no PC). `FirePumpView` (`GameScreen.fire_pump_view`): `sites`/`cells` (as duas células de lado do quartel
  pelo `SideYard`, fora dos pátios de lado de antes; o recheio e as bombas as deixam) e `pump_mesh` (a bomba de mão vermelha com
  os cilindros de latão e os braços, o carretel, a escada e os baldes na parede), num MultiMesh. Captura em
  `tools/capture_phase220.tscn`.

### Barris na cervejaria (Fase 221, nossa)

- **Plano** em `docs/plano_fase221.md`. `BarrelRackView` (`GameScreen.barrel_rack_view`): `sites`/`cells` (as duas células de lado
  da cervejaria, das destilarias e da adega pelo `SideYard`) e `rack_mesh` (a pirâmide de barris torneados sobre os calços e dois
  de pé com o funil), num MultiMesh. **O torneado anda de +x para +z**: as faces vão no sentido contrário ao do
  `VertexShapes.cylinder`. **As buscas de lado ficam guardadas** (`SideYard.remember`, na memória da Fase 204): pátio novo
  de lado chama `sites` por ela. Captura em `tools/capture_phase221.tscn`.

### Covos no cais (Fase 222, nossa)

- **Plano** em `docs/plano_fase222.md`. `LobsterPotView` (`GameScreen.lobster_pot_view`): `pots` (nos primeiros lanços livres do cais
  de pedra, até `PILES_PER_POST` afastadas, longe das outras peças do cais e dos bancos) e `pot_mesh` (covos de vime em meia-lua, o
  cabo enrolado e as boias), num MultiMesh. **Peça nova do cais procura lanço livre**: os restos fixos (bancos, cabeços) já se
  sobrepõem a lampiões, mastros e escadas. Captura em `tools/capture_phase222.tscn`.

### Lençóis no hospital (Fase 223, nossa)

- **Plano** em `docs/plano_fase223.md`. `LinenView` (`GameScreen.linen_view`): `sites`/`cells` (as duas células de lado do hospital
  pelo `SideYard`) e `linen_mesh` (dois varais com os lençóis enfunados e o cesto), num MultiMesh sem descarte de face. Captura em
  `tools/capture_phase223.tscn`.

### Relógio de sol no largo (Fase 224, nossa)

- **Plano** em `docs/plano_fase224.md`. `SundialView` (`GameScreen.sundial_view`): `cells` (o canto do anel do largo da Fase 109 mais
  para a frente, um por serviço) e `dial_mesh` (a coluna torneada com o mostrador de bronze e o gnomon), num MultiMesh, só na ilha
  com relevo. Captura em `tools/capture_phase224.tscn` (a câmera à mão do lado de fora do canto: entre os prédios a da partida
  fica dentro deles).

### Lanterna na popa (Fase 225, nossa)

- **Plano** em `docs/plano_fase225.md`, primeira do roteiro `docs/plano_fases_225_229.md` (lanterna, lã e morcego; o Anno não foi
  aberto: a sessão não tinha o controle da tela). `SternLantern` (`presentation/stern_lantern.gd`, chamada pelo `ShipView._model`):
  `stern_point` (a ré do casco pelos triângulos dele), `node` (filha do modelo, com a escala desfeita, a partir dos triângulos do
  casco lidos uma vez para ela e para o cordame), `frame_mesh` e `glass_mesh`
  (no `shaders/night_glow.gdshader`). **Peça nova no modelo do navio é montada antes do cordame**: a busca do casco
  (`ShipRigging.hull_points`) lê todas as malhas do modelo e quebra nas que não têm índice. Captura em
  `tools/capture_phase225.tscn`.

### Fardos de lã (Fase 226, nossa)

- **Plano** em `docs/plano_fase226.md`. `WoolBaleView` (`GameScreen.wool_bale_view`): `sites`/`cells` (as duas células de lado da
  fazenda de ovelhas pelo `SideYard`, fora das medas, do silo e da carroça de feno) e `bale_mesh` (os fardos estufados com as
  cordas em volta, o cepo com a tesoura e o velo), num MultiMesh. Captura em `tools/capture_phase226.tscn`.

### Lamaçal do chiqueiro (Fase 227, nossa)

- **Plano** em `docs/plano_fase227.md`. `MudWallowView` (`GameScreen.mud_wallow_view`): `spot` (em cada pasto de fazenda de porcos,
  do lado oposto ao cocho, pelo `module_owner`) e `mud_mesh` (a lama de borda recortada com a orla e os torrões), num MultiMesh
  sem sombra; a `CropView` não põe capim dentro dela. Captura em `tools/capture_phase227.tscn`.

### Barris de petróleo (Fase 228, nossa)

- **Plano** em `docs/plano_fase228.md`. `OilBarrelView` (`GameScreen.oil_barrel_view`): `sites`/`cells` (as duas células de lado do
  poço de petróleo pelo `SideYard`) e `barrels_mesh` (os barris da Fase 221 enegrecidos, em pé e deitados, e a mancha de óleo),
  num MultiMesh. Captura em `tools/capture_phase228.tscn`.

### Morcegos ao anoitecer (Fase 229, nossa)

- **Plano** em `docs/plano_fase229.md`. `BatView` (`GameScreen.bat_view`): as torres das andorinhas (`SwallowView.towers`), `pose`
  (voltas em zigue-zague em volta da sineira), `beat` (sem planeio) e `bat_mesh` (asas de membrana recortada) no
  `shaders/bird.gdshader`, num MultiMesh sem sombra; só à noite (`show_for_night`). Captura em `tools/capture_phase229.tscn`.

### Sinal no trilho (Fase 230, nossa)

- **Plano** em `docs/plano_fase230.md`, primeira do roteiro `docs/plano_fases_230_234.md` (sinal, cormorão e castanha; o Anno não foi
  aberto: a sessão não tinha o controle da tela). `RailSignalView` (`GameScreen.rail_signal_view`): `ends` (as pontas de linha do
  trilho), `place_of` (ao lado da linha, à direita de quem chega), `signal_mesh` (o poste, a escada e o braço) e `glass_mesh` (no
  `shaders/night_glow.gdshader`), em dois MultiMesh. Captura em `tools/capture_phase230.tscn`.

### Cormorões nas estacas (Fase 231, nossa)

- **Plano** em `docs/plano_fase231.md`. `CormorantView` (`GameScreen.cormorant_view`): `perches` (no alto da estaca do meio de um a
  cada `PERCH_EVERY` feixes de atracação da Fase 186, o primeiro sempre) e `cormorant_mesh` (de asas abertas), num MultiMesh sem
  descarte de face; some à noite. Captura em `tools/capture_phase231.tscn`.

### Tapete na janela (Fase 232, nossa)

- **Plano** em `docs/plano_fase232.md`. `WindowRugView` (`GameScreen.window_rug_view`): `spot` (o peitoril da primeira janela de cima
  da fachada da frente de parte das casas dos operários e artesãos, pelo `BuildingKit._cell_transform` no lugar do modelo) e
  `rug_mesh` (a dobra, o pano listrado e a franja), num MultiMesh com a cor por casa. Captura em `tools/capture_phase232.tscn`.

### Cabines de banho (Fase 233, nossa)

- **Plano** em `docs/plano_fase233.md`. `BathingMachineView` (`GameScreen.bathing_machine_view`): `cells` (a areia livre junto do mar
  perto dos entrepostos das ilhas temperadas, pela conta dos guarda-sóis da Fase 204; o recheio a deixa), `place_of` (a porta para
  o mar) e `machine_mesh` (a cabine listrada sobre rodas), num MultiMesh. Captura em `tools/capture_phase233.tscn`.

### Fogareiro de castanhas (Fase 234, nossa)

- **Plano** em `docs/plano_fase234.md`. `ChestnutRoasterView` (`GameScreen.chestnut_roaster_view`): `cells` (as esquinas calçadas da
  busca das colunas de anúncios, no resto ímpar que nunca é o delas; o recheio as deixa), `roaster_mesh` (o carrinho com o fogareiro)
  e `ember_mesh` (as brasas no `shaders/night_glow.gdshader`, como vidro), em dois MultiMesh. **Peça que acende no `night_glow` fora do
  pé da malha vai como vidro (alfa 0)**: a chama (alfa 1) encolhe até o y = 0. Captura em `tools/capture_phase234.tscn`.

### Cervos na beira da mata (Fase 235, nossa)

- **Plano** em `docs/plano_fase235.md`, primeira do roteiro `docs/plano_fases_235_239.md` (cervo, âncora e marco; o Anno não foi
  aberto: a sessão não tinha o controle da tela). `DeerView` (`GameScreen.deer_view`): `herds` (capim livre com mata perto, longe
  das vilas pela regra das focas), `deer`, `head_pitch` (a cabeça pastando e se erguendo) e as malhas do corpo e das cabeças (com e
  sem galhada), em três MultiMesh. Captura em `tools/capture_phase235.tscn`.

### Âncora no cais (Fase 236, nossa)

- **Plano** em `docs/plano_fase236.md`. `AnchorView` (`GameScreen.anchor_view`): `spot` (no fundo do cais de pedra, `ANCHOR_IN_M` da
  beira, do último lanço para o primeiro, longe das outras peças do cais, covos incluídos) e `anchor_mesh` (montada reta e tombada
  até o cepo e a pata tocarem o chão), num MultiMesh. **As peças do cais de pedra já tomam todos os lanços junto da beira**: peça
  nova procura o fundo do cais. Captura em `tools/capture_phase236.tscn`.

### Marco de légua (Fase 237, nossa)

- **Plano** em `docs/plano_fase237.md`. `MilestoneView` (`GameScreen.milestone_view`): `stones` (célula de terra do desenho
  `posmod(7x + 13y, STONE_EVERY)`, no meio de um trecho reto de `RUN_CELLS` para cada lado, fora das vilas pela regra das placas e
  dos postes de fio; na beira do lado livre, a face para a estrada) e `stone_mesh`, num MultiMesh. **As estradas retas e compridas
  são raras no relevo da semente 1840**: a captura (`tools/capture_phase237.tscn`) procura onde a obra passa.

### Bandeira na prefeitura (Fase 238, nossa)

- **Plano** em `docs/plano_fase238.md`. `TownFlagView` (`GameScreen.town_flag_view`): `foot_of` (o remate da cúpula pelo
  `BuildingKit.dome_finial`, que o `_dome` também usa, no lugar do modelo), `pole_mesh` e `flag_mesh` (a bandeira da cidade, sem
  nenhuma de verdade) numa `WindFlag`, um nó por prefeitura. Captura em `tools/capture_phase238.tscn`.

### Algas na praia (Fase 239, nossa)

- **Plano** em `docs/plano_fase239.md`. `ScatterView.Kind.SEAWEED` (no fim do enum e da lista `NEAR_SEA`) só nas células baixas e
  planas da costa (`SEAWEED_MAX_HEIGHT_M`, `SEAWEED_MAX_RELIEF_M`), deitada no plano da célula; `seaweed_mesh` (uma faixa torta de
  bolos chatos encostados, não bolos soltos: soltos pareciam bichos ou contas). Captura em `tools/capture_phase239.tscn`.

### Lagar no vinhedo (Fase 240, nossa)

- **Plano** em `docs/plano_fase240.md`, primeira do roteiro `docs/plano_fases_240_244.md` (lagar, terreiro e estacas; o Anno não
  foi aberto: a sessão não tinha o controle da tela). `WinePressView` (`GameScreen.wine_press_view`): `sites`/`cells` (as duas
  células de lado do vinhedo pelo `SideYard`, o +X primeiro, fora das colmeias e do silo; o recheio e as bombas as deixam) e
  `press_mesh` (a tina com o mosto, a prensa de fuso e os cestos), num MultiMesh. Captura em `tools/capture_phase240.tscn`.

### Terreiro de café (Fase 241, nossa)

- **Plano** em `docs/plano_fase241.md`. `CoffeeYardView` (`GameScreen.coffee_yard_view`): `sites`/`cells` (as duas células de lado
  do cafezal pelo `SideYard`; o recheio e as bombas as deixam) e `yard_mesh` (o terreiro com a camada de café e os sulcos do rodo),
  num MultiMesh. **Grão espalhado se faz com uma camada e sulcos**, não com bolinhos (pareciam escamas). Captura em
  `tools/capture_phase241.tscn`.

### Tabaco secando (Fase 242, nossa)

- **Plano** em `docs/plano_fase242.md`. `TobaccoRackView` (`GameScreen.tobacco_rack_view`): `sites`/`cells` (as duas células de lado
  da plantação pelo `SideYard`; o recheio e as bombas as deixam) e `rack_mesh` (os cavaletes, as varas e as réstias de folhas em
  três tons de cura), num MultiMesh sem descarte de face. Captura em `tools/capture_phase242.tscn`.

### Vigas de aço empilhadas (Fase 243, nossa)

- **Plano** em `docs/plano_fase243.md`. `SteelBeamView` (`GameScreen.steel_beam_view`): `sites`/`cells` (as duas células de lado da
  fábrica pelo `SideYard`, o −X primeiro, longe da boca do forno no +X, fora do carrinho de mão; o recheio e as bombas as deixam)
  e `pile_mesh` (`_beam`, a viga em I), num MultiMesh. Captura em `tools/capture_phase243.tscn`.

### Estacas de lúpulo (Fase 244, nossa)

- **Plano** em `docs/plano_fase244.md`. `HopPoleView` (`GameScreen.hop_pole_view`): `sites`/`cells` (as duas células de lado da
  fazenda pelo `SideYard`, o +X primeiro, fora das colmeias e do silo; o recheio e as bombas as deixam) e `pole_mesh` (os cavaletes
  com as estacas deitadas e o feixe de pé), num MultiMesh. Captura em `tools/capture_phase244.tscn`.

### Coelhos no prado (Fase 245, nossa)

- **Plano** em `docs/plano_fase245.md`, primeira do roteiro `docs/plano_fases_245_249.md` (coelho, cogumelo e pedra; o Anno não foi
  aberto: a sessão não tinha o controle da tela). `RabbitView` (`GameScreen.rabbit_view`): `warrens` (capim aberto longe das vilas
  pela regra das focas), `rabbits`, `sit_up` (o coelho sentando, girado em volta do pé de trás) e `rabbit_mesh`, num MultiMesh sem
  sombra. Captura em `tools/capture_phase245.tscn`. **Não edite `.gd` do projeto com um benchmark ou uma captura rodando**: o
  Godot carrega os scripts sob demanda e pega o arquivo pela metade (a primeira medida desta fase saiu inválida assim).

### Tronco caído com cogumelos (Fase 246, nossa)

- **Plano** em `docs/plano_fase246.md`. `ScatterView.Kind.MOSSY_LOG` (no fim do enum e da lista `NEAR_FOREST`, com sombra) só nas
  temperadas e no chão de pouco desnível, deitado com o chão pela conta da madeira à deriva; `mossy_log_mesh` (o tronco, o musgo,
  as orelhas-de-pau e os cogumelos). Captura em `tools/capture_phase246.tscn`.

### Madeira curvada no estaleiro (Fase 247, nossa)

- **Plano** em `docs/plano_fase247.md`. `ShipTimberView` (`GameScreen.ship_timber_view`): `sites`/`cells` (as duas células de lado
  do estaleiro pelo `SideYard`, com a fileira do lado do mar tomada para a carreira; o recheio e as bombas as deixam) e
  `timber_mesh` (`_rib`, a caverna em U), num MultiMesh. Captura em `tools/capture_phase247.tscn`.

### Caixotes de vidro (Fase 248, nossa)

- **Plano** em `docs/plano_fase248.md`. `GlassCrateView` (`GameScreen.glass_crate_view`): `sites`/`cells` (as duas células de lado
  da vidraria e da janelaria pelo `SideYard`, o −X primeiro, longe da boca do forno, fora do carrinho de mão; o recheio e as bombas
  as deixam) e `crate_mesh` (`_crate`), num MultiMesh. Captura em `tools/capture_phase248.tscn`.

### Montes de pedra nos campos (Fase 249, nossa)

- **Plano** em `docs/plano_fase249.md`. `FieldStoneView` (`GameScreen.field_stone_view`): `spot` (um campo com dono a cada
  `STONE_EVERY` das temperadas, num canto da cabeceira pelo `CropView._row_frame`, além do fim das fileiras) e `heap_mesh`, num
  MultiMesh. Captura em `tools/capture_phase249.tscn`.

### Balança de carga no armazém (Fase 250, nossa)

- **Plano** em `docs/plano_fase250.md`, primeira do roteiro `docs/plano_fases_250_254.md` (balança, cabra e canoa; o Anno não foi
  aberto: a sessão não tinha o controle da tela). `ScaleView` (`GameScreen.scale_view`): `sites`/`cells` (as duas células de lado do
  armazém pelo `SideYard`; o recheio e as bombas as deixam) e `scale_mesh` (`_sack`, o saco amarrado), num MultiMesh. Captura em
  `tools/capture_phase250.tscn`.

### Cabras nas encostas (Fase 251, nossa)

- **Plano** em `docs/plano_fase251.md`. `GoatView` (`GameScreen.goat_view`): `herds` (encosta livre de `MIN_RELIEF_M`, longe das
  vilas pela regra das focas), `goats` (a primeira na pedra), `head_pitch` e as malhas do corpo, da cabeça e da pedra, em três
  MultiMesh. Captura em `tools/capture_phase251.tscn`.

### Carruagem à porta do teatro (Fase 252, nossa)

- **Plano** em `docs/plano_fase252.md`. `CarriageView` (`GameScreen.carriage_view`): `spot` (a célula de estrada das
  `Footprint.front_cells` do teatro mais perto do meio da fachada, ao longo da rua) e `carriage_mesh`, num MultiMesh. Captura em
  `tools/capture_phase252.tscn`.

### Cestos de batata (Fase 253, nossa)

- **Plano** em `docs/plano_fase253.md`. `PotatoBasketView` (`GameScreen.potato_basket_view`): `sites`/`cells` (as duas células de lado
  da fazenda pelo `SideYard`, o +X primeiro, fora das colmeias e do silo; o recheio e as bombas as deixam) e `basket_mesh`
  (`_basket`, `_potato`), num MultiMesh. Captura em `tools/capture_phase253.tscn`.

### Canoas na margem do rio (Fase 254, nossa)

- **Plano** em `docs/plano_fase254.md`. `CanoeView` (`GameScreen.canoe_view`): `banks` (terra livre e baixa com o rio do lado, numa
  rede de pontos, longe das vilas pela regra das focas), `place_of` (de comprido ao longo da margem, deitada com o chão) e
  `canoe_mesh` (o casco em seções, como o barco da `HarborView`), num MultiMesh sem descarte de face. **Busca rara pela grade sai
  das células raras**: as margens partem das células de rio pelo `find` nativo (varrer a vizinhança de cada ponto custava 160 ms
  a cada obra; os bichos das Fases 235, 245 e 251 ainda varrem, de 27 a 44 ms). Captura em
  `tools/capture_phase254.tscn`.

### Ar limpo e tom vivo (Fase 255, nossa)

- **Plano** em `docs/plano_fase255.md`, primeira do roteiro `docs/plano_fases_255_259.md` (cor viva, a pedido do dono: "muito
  morto, gostaria de algo mais vivo, parecido com o anno"; o Anno não foi aberto, as ideias vêm das capturas guardadas). A cor
  viva (`GameConfig.vivid_exposure`, `vivid_agx_contrast`, `vivid_saturation`, no `GraphicsQuality.apply_to_environment`) é o
  padrão com a "Cor de época" desligada; névoa volumétrica 0,0004 e a do domo 0,0001; o sol do Sky3D quente e mais forte
  (`sun_light_color`, `sun_light_energy`, pelo `SkyAdapter`). **Ajuste de cor se escolhe no `tools/color_lab.tscn`** (a mesma
  vila com várias combinações, lado a lado) e se confere no `tools/capture_phase255.tscn` (as vistas do ciclo, antes e depois).

### Copas verdes (Fase 256, nossa)

- **Plano** em `docs/plano_fase256.md`. Folhas mais claras no `TreeModel`, o alto de cada massa puxando para o amarelo
  (`CROWN_SUN`) e a luz própria das folhas de dia (`leaf_fill` no `shaders/foliage.gdshader`, `TreeModel.LEAF_FILL`, apagada
  pelo `night_light`); as plantações e o capim, no mesmo shader, ficam com 0.

### Grama viva (Fase 257, nossa)

- **Plano** em `docs/plano_fase257.md`. No `shaders/terrain.gdshader`, depois da graduação, a grama vai `grass_tint_mix` (0,6)
  para o verde-amarelado `grass_tint` escalado à luminância do texel (o claro e o escuro da textura ficam, o matiz deixa de ser
  oliva); `grass_grade` (0,6; 1,12; 0,7), saturação 1,25 e a seca 0,15.

### Telhado e parede com cor (Fase 258, nossa)

- **Plano** em `docs/plano_fase258.md`. Todo telhado tira a cor de `BuildingView.ROOF_TINTS` pelo material e pela paleta
  (`palette_roof`; telhas de terracota, tábuas marrons); no `shaders/building_kit.gdshader` a tinta pesa `tint_strength` 0,68 na
  parede e `roof_tint_strength` 0,85 no telhado; o reboco dos artesãos, engenheiros e investidores é quente (`house_color`).
  **Cor azul ou cinza sobre a textura de telha vermelha sai lilás**: o telhado de outro matiz pede outra textura (a ardósia da
  Fase 134).

### Praia dourada (Fase 259, nossa)

- **Plano** em `docs/plano_fase259.md`. No `shaders/terrain.gdshader`, a areia vai `sand_tint_mix` (0,55) para o dourado
  `sand_tint` escalado à luminância, com `sand_grade` (1,5; 1,35; 1,1); a lama sai de `mud_base` (a areia com a graduação de antes),
  então a margem dos rios e a laterita não mudam.

### Hora dourada (Fase 260, nossa)

- **Plano** em `docs/plano_fase260.md`, primeira do roteiro `docs/plano_fases_260_264.md` (cor viva II). O sol do horizonte em ouro
  claro (`GameConfig.sun_horizon_color`, no domo pelo `SkyAdapter`); a exposição pela altura do sol (`GraphicsQuality.dusk_factor`
  e `follow_sun`, a cada quadro pela `GameScreen`; **quem mexe na exposição desliga o `sun_exposure`**, senão ela é refeita no
  quadro seguinte); a luz das folhas pelo global `sun_direction` (`shaders/foliage.gdshader`). Capturas do ciclo em
  `tools/capture_phase260.tscn` (campos, falésia, ilha tropical, fim da tarde, manhã e noite).

### Rocha cinza (Fase 261, nossa)

- **Plano** em `docs/plano_fase261.md`. Toda pedra no `shaders/sea_rock.gdshader`: a do mar (rochedos, falésia, rio) com a faixa
  da maré e as soltas (`RockView.material`, barrancos, jazidas) com `sea` desligado; o matiz vai `RockView.STONE_GREY_MIX` para o
  cinza e clareia `STONE_LIGHT`; a rocha do terreno faz a mesma conta (`rock_grey`, `rock_grey_mix`, `rock_light`). **Os testes da
  pasta `presentation` precisam da janela** (`testes_janela_oculta.ps1`): sem ela o MultiMesh devolve zeros e falham à toa.

### Campos coloridos (Fase 262, nossa)

- **Plano** em `docs/plano_fase262.md`. As leiras levam a cor da plantação conforme ela cresce (`CropView.furrow_color_at`, até
  `COVER_MAX`; o cereal do verde ao dourado, as outras em `CROP_COVER`): de longe cada campo é um retalho da cor da planta.

### Noite azul (Fase 263, nossa)

- **Plano** em `docs/plano_fase263.md`. De noite a exposição fica em 1 + `GameConfig.night_exposure_boost` vezes a do dia
  (`GraphicsQuality.dusk_factor`, sem degrau desde o fim da tarde). **O Sky3D leva 3 s para passar a luz ambiente do dia para a
  da noite**: captura de noite espera antes de fotografar.

### Sombra aberta (Fase 264, nossa)

- **Plano** em `docs/plano_fase264.md`. `GameConfig.ssao_intensity` 0,9 (era 1,6): o vão entre as copas e o pé das matas deixam de
  ficar quase pretos. A parte do céu na luz ambiente quase não muda a sombra (medido no laboratório).

### Garças no rio (Fase 265, nossa)

- **Plano** em `docs/plano_fase265.md`, primeira do roteiro `docs/plano_fases_265_269.md` (garça, ruína e cruzeiro; o Anno não foi
  aberto: a sessão não tinha o controle da tela). A busca das margens das canoas virou `CanoeView.river_banks` (rede, sal e chance
  como parâmetros). `HeronView` (`GameScreen.heron_view`): `spot` (junto da água, do lado do rio) e `heron_mesh`, virando pelo
  `PerchedGullView.heading_at` em volta da frente para o rio, num MultiMesh sem sombra. Captura em `tools/capture_phase265.tscn`.

### Ruínas de muro (Fase 266, nossa)

- **Plano** em `docs/plano_fase266.md`. `ScatterView.Kind.RUIN` (no fim do enum e da lista `OPEN`, com sombra) só nas temperadas e no
  chão de pouco desnível, de pé; `ruin_mesh` (o muro de pedra seca quebrado em degraus, as pedras caídas e o musgo). Captura em
  `tools/capture_phase266.tscn`.

### Espinheiro florido (Fase 267, nossa)

- **Plano** em `docs/plano_fase267.md`. `ScatterView.Kind.HAWTHORN` (no fim do enum e da lista `NEAR_FOREST`, entre as `PLANTS` e
  as `SHADOWED`) só nas temperadas, de pé; `hawthorn_mesh` (a copa em massas com as pencas de flor branca por toda ela). Captura em
  `tools/capture_phase267.tscn`.

### Casco naufragado (Fase 268, nossa)

- **Plano** em `docs/plano_fase268.md`. `WreckView` (`GameScreen.wreck_view`): `sites` (a costa baixa das temperadas pela regra das
  focas, com as vizinhas ao longo dela livres, fora das focas, longe das vilas, no máximo `MAX_PER_ISLAND` por ilha), `place_of`
  (ao longo da costa, adernado e afundado) e `wreck_mesh` (a quilha e as cavernas), num MultiMesh. Captura em
  `tools/capture_phase268.tscn` (a câmera do lado do mar).

### Cruzeiro no morro (Fase 269, nossa)

- **Plano** em `docs/plano_fase269.md`. `SummitCrossView` (`GameScreen.summit_cross_view`): `summit` (a célula livre e quase plana
  mais alta de cada ilha temperada, acima de `MIN_HEIGHT_M`), `place_of` (virado para o meio da ilha) e `cross_mesh`, num
  MultiMesh. Captura em `tools/capture_phase269.tscn`.

### Corvos no campo (Fase 270, nossa)

- **Plano** em `docs/plano_fase270.md`, primeira do roteiro `docs/plano_fases_270_274.md` (corvo, dedaleira e girassol; o Anno não
  foi aberto: a sessão não tinha o controle da tela). `CropView.field_ids` e `CrowView` (`GameScreen.crow_view`, com a `CropView`):
  `crow_spots` (os lugares da colheita dos campos novos da vez), `peck` e `crow_mesh`, num MultiMesh sem sombra, escondido de noite.
  Captura em `tools/capture_phase270.tscn`.

### Dedaleiras (Fase 271, nossa)

- **Plano** em `docs/plano_fase271.md`. `ScatterView.Kind.FOXGLOVE` (no fim do enum e da lista `NEAR_FOREST`, entre as `PLANTS`) só
  nas temperadas; `foxglove_mesh` (cinco hastes com os sinos roxos). Captura em `tools/capture_phase271.tscn`.

### Anel de cogumelos (Fase 272, nossa)

- **Plano** em `docs/plano_fase272.md`. `ScatterView.Kind.FAIRY_RING` (no fim do enum e da lista `OPEN`) só nas temperadas e no chão
  pouco inclinado, deitado no plano da célula; `fairy_ring_mesh` (a roda de cogumelos claros). Captura em `tools/capture_phase272.tscn`.

### Andorinhas no fio (Fase 273, nossa)

- **Plano** em `docs/plano_fase273.md`. `PowerLineView.rebuilt` e `spans` (as curvas dos fios); `WireBirdView`
  (`GameScreen.wire_bird_view`): `perches` (a fila no meio da curva de um vão a cada `SPAN_EVERY`) e `swallow_mesh`, num MultiMesh sem
  sombra, escondido de noite. Captura em `tools/capture_phase273.tscn` (a câmera à mão na altura do fio).

### Girassóis (Fase 274, nossa)

- **Plano** em `docs/plano_fase274.md`. `ScatterView.Kind.SUNFLOWER` (no fim do enum e da lista `NEAR_HOUSE`, entre as `PLANTS`) só nas
  temperadas; `sunflower_mesh` (quatro hastes com as flores amarelas). **A água dos rios fica coberta da espuma da beira** (são
  estreitos): peça que precise de água calma no rio não aparece (os nenúfares do roteiro sumiam). Captura em
  `tools/capture_phase274.tscn`.

### Abeto em camadas (Fase 275, nossa)

- **Plano** em `docs/plano_fase275.md`, primeira do roteiro `docs/plano_fases_275_279.md` (a mata no jeito do Anno; o Anno foi
  aberto em 02/11/2026, capturas `c10_*` fora do repositório). `TreeModel.Species.NORWAY_SPRUCE` (no fim do enum): `_spruce`
  (camadas de galhos em cone até perto do chão, `_skirt`, `_needle`); `TreeView.CONIFER` com abetos e pinheiros, escolhidos por
  `conifer_pick` (pinheiro mais acima de `PINE_HEIGHT_M`). **Face gerada para o material de duas faces vai no sentido horário
  visto de fora** (como o `_limb`): com a face trocada o Godot vira a normal e ela acende do lado da sombra. Captura do ciclo em
  `tools/capture_phase275.tscn` (a vila, os campos e a mata alta e baixa fora da vila).

### Copas na medida (Fase 276, nossa)

- **Plano** em `docs/plano_fase276.md`. Copas do carvalho, da faia e do pinheiro ~35% mais estreitas, da mesma altura; na mata
  temperada uma árvore por célula (`TreeView.TEMPERATE_PER_CELL`) e só em parte delas (`draws_tree`: 50% na beira, 65% e 80% para
  dentro); tamanho de 0,65 a 1,25 (`tree_scale`). **As árvores desenhadas numa célula saem de `TreeView.drawn_seeds`**, que os
  tocos da clareira (`StumpView.stump_places`) também usam; a simulação conta todas.

### Bétula (Fase 277, nossa)

- **Plano** em `docs/plano_fase277.md`. `TreeModel.Species.BIRCH` (no fim do enum): `_birch` (tronco branco com o pé escuro,
  massas pequenas e soltas) e `_birch_marks` (as manchas pretas, só de perto); `TreeView.BROADLEAF` com as bétulas no fim,
  escolhidas por `broadleaf_pick` (mais na beira da mata e na terra baixa). A cor da malha volta em 8 bits por canal: teste que
  procura uma cor exata compara com folga.

### Orla da mata (Fase 278, nossa)

- **Plano** em `docs/plano_fase278.md`. `TreeView.young_entry`: na célula de mata temperada com um lado de terra sem árvore, uma
  árvore nova (abeto, um pouco de bétula, carvalho ou faia de arbusto) de 0,32 a 0,55 do tamanho, puxada para o lado aberto sem
  sair da célula, nas mesmas camadas da mata.

### Folhas recortadas (Fase 279, nossa)

- **Plano** em `docs/plano_fase279.md`. **O corpo da folhagem está em `shaders/foliage.gdshaderinc`**: o `foliage.gdshader` só o
  inclui, e o `shaders/tree_foliage.gdshader` (`TreeModel.TREE_SHADER`, as árvores de perto menos o coqueiro) define
  `LEAF_DETAIL`: cachos de folhas por células sorteadas no modelo, com a normal estufada, e a borda da copa recortada por
  `discard`, até `leaf_far_m` (90 m). Mudança na folhagem vai no `.gdshaderinc`; o `discard` fica atrás do `LEAF_DETAIL` (tira a
  profundidade antecipada das plantações e do capim). GPU +0,3 a 0,4 ms.

### Mar fundo (Fase 280, nossa)

- **Plano** em `docs/plano_fase280.md`, primeira do roteiro `docs/plano_fases_280_284.md` (o mar e o rio). No
  `shaders/water.gdshader`, `cold_deep`, `cold_shelf` e `cold_shelf_m`: o mar das temperadas em azul-petróleo, com a plataforma
  mais estreita; o das tropicais segue o turquesa, pela borda `reef_min_x` (`tropic`, com a guarda do 1e9 sem ilha tropical).
  Captura do ciclo em `tools/capture_phase280.tscn` (`CAPTURA_MAR=lab` compara cores de água lado a lado).

### Rebentação fina (Fase 281, nossa)

- **Plano** em `docs/plano_fase281.md`. No `shaders/water.gdshader`, a espuma por profundidade do Ocean (`SHORE_FOAM`) só vale até
  `shore_line_m` (3 m) da linha d'água: vista de cima a diferença de profundidade é pequena na praia rasa inteira, e virava uma
  faixa branca de ~20 m. As bandas da Fase 35 viram linhas finas (`band_sharpness`) e quebradas pela textura da espuma.

### Água de noite (Fase 282, nossa)

- **Plano** em `docs/plano_fase282.md`. **A cor da água sai pela `EMISSION`, que não recebe luz**: no `shaders/water.gdshader`
  as cores postas (raso, fundo, plataforma, recife) passam pelo `water_light`, de 1 a `night_water` pelo global `night_light`.
  Cor nova posta na água passa por ele também.

### Rio escuro (Fase 283, nossa)

- **Plano** em `docs/plano_fase283.md`. No `shaders/water.gdshader`, `channel` (quatro sondas no mapa da costa, só perto da terra:
  em toda a água custavam 0,2 ms) marca o rio e a enseada fina: cor `river_color`, sem bandas nem espuma do Ocean, menos reflexo.
  No `shaders/terrain.gdshader`, `gravel` (a `TerrainView` liga nas temperadas): a lama junto da água vira cascalho cinza até
  `gravel_top_m`. A captura do ciclo procura o rio com água (`05_rio.png`) e o leito seco (`05b_leito_seco.png`).

### Marulho (Fase 284, nossa)

- **Plano** em `docs/plano_fase284.md`. No começo do fragment do `shaders/water.gdshader`, três trens de ondas longas
  (`swell_lengths_m`, `swell_slopes`) dobram a normal com o vento, longe da costa (`swell_open_m`), antes do Fresnel e do brilho:
  o mar aberto ondula de longe sem mexer nos vértices.

### Manchas do prado (Fase 285, nossa)

- **Plano** em `docs/plano_fase285.md`, primeira do roteiro `docs/plano_fases_285_289.md` (o prado). No `shaders/terrain.gdshader`,
  logo depois da cor da grama, manchas de capim alto escuro (com mais relevo) e baixo claro pelo ruído de `meadow_patch_m`; só na
  grama. Captura do ciclo em `tools/capture_phase285.tscn` (o prado aberto fora da vila, as papoulas e a borda de um barranco).

### Tapete de capim (Fase 286, nossa)

- **Plano** em `docs/plano_fase286.md`. `GrassCarpetView` (`GameScreen.grass_carpet_view`), **a primeira vista que segue a câmera**:
  blocos de 8 × 8 células em volta do ponto que ela olha (`wanted_blocks`, até `radius_m`), três por quadro, o mais perto
  primeiro; tufos (`tuft_mesh`, `tufts`) só no capim livre (`grows_at`); escondida com a câmera alta. O
  `shaders/grass_carpet.gdshader` repete o ruído das manchas do prado do `terrain.gdshader` (mudou um, mude o outro), balança com o
  vento e encolhe com a distância. Custo na GPU sobre o prado medido no `tools/grass_cost.tscn`.

### Flores miúdas (Fase 287, nossa)

- **Plano** em `docs/plano_fase287.md`. Pontos brancos e amarelos no capim do `shaders/terrain.gdshader` (`flower_*`, até
  `flower_far_m`) e a flor do tufo do tapete (as pétalas com o alfa 0 no vértice; o `shaders/grass_carpet.gdshader` a deixa só nos
  tufos sorteados pelas mesmas regras e números e reduz as outras a um ponto).

### Papoulas soltas (Fase 288, nossa)

- **Plano** em `docs/plano_fase288.md`. Na `ScatterView`, o canteiro anda mais do meio da célula (`POPPY_SPREAD`), fica menor na
  borda (`poppy_strength`, `POPPY_EDGE_SCALE`) e o meio do canteiro ganha touceiras pequenas a mais (`_poppy_extras`, sorteio
  próprio pelo hash da célula: o das outras peças não muda).

### Beira do barranco (Fase 289, nossa)

- **Plano** em `docs/plano_fase289.md`. No `shaders/terrain.gdshader` (`bank_*`), uma faixa de terra escura, pedras e raízes na
  crista dos barrancos (a curvatura dos dados abaixo do meio e a inclinação deles subindo antes da rocha), recortada e
  interrompida a trechos, fora da rocha, da areia e da lama.

### Estratos na rocha (Fase 290, nossa)

- **Plano** em `docs/plano_fase290.md`, primeira do roteiro `docs/plano_fases_290_294.md` (a rocha e a costa).
  `shaders/rock_strata.gdshaderinc` (`strata_factor`: camadas onduladas com a borda clara e a sombra, sulcos descendo) no
  `terrain.gdshader` (só onde há rocha) e no `sea_rock.gdshader`. **Função de `.gdshaderinc` não usa nome de varying nos
  parâmetros** (`world_position` não compilava). **Teste de uniformes de shader exige a lista cheia com tela**
  (`DisplayServer.get_name() != "headless"`): a lista vazia é também o shader que não compilou. Captura do ciclo em
  `tools/capture_phase290.tscn`.

### Musgo nas saliências (Fase 291, nossa)

- **Plano** em `docs/plano_fase291.md`. `moss_amount` no `shaders/rock_strata.gdshaderinc` (as partes planas e os ressaltos das
  camadas, em manchas, mais no lado da sombra fixo `moss_shade_dir`, nunca pelo sol do dia) pinta `moss_color` na rocha do terreno
  e nas pedras (na do mar, só acima da pedra molhada).

### Praia de seixos (Fase 292, nossa)

- **Plano** em `docs/plano_fase292.md`. No `shaders/terrain.gdshader` (`pebble_*`, ligado pela `TerrainView` nas temperadas), a
  areia com rocha a 5 m vira, em trechos, seixos de Voronoi (tom por pedra, junta escura, normal estufada), escuros e brilhantes
  na beira. **Hash de coordenada do mundo em shader é inteiro** (`strata_hash`): o `fract(p * 123,34)` quantiza a milhares de
  metros.

### Espuma nas pedras (Fase 293, nossa)

- **Plano** em `docs/plano_fase293.md`. No bloco `SHORE_FOAM` do `shaders/water.gdshader`, o anel fino (`rock_foam_m`) em volta do
  que entra na água longe da linha d'água (estacas, boias, degraus, cascos, pedras), por `max` com a espuma da Fase 281.

### Abetos na rocha (Fase 294, nossa)

- **Plano** em `docs/plano_fase294.md`. `ScatterView.Kind.CLIFF_SPRUCE` (no fim do enum e das listas `OPEN`, `NEAR_FOREST` e
  `NEAR_SEA`, com sombra): o abeto de perto da Fase 275 a 0,4 do tamanho, com o material dele, só nas células de desnível
  `CLIFF_SPRUCE_MIN_RELIEF_M` das temperadas, de pé.

### Espuma em trechos (Fase 295, nossa)

- **Plano** em `docs/plano_fase295.md`, primeira do roteiro `docs/plano_fases_295_299.md` (mar e costa II; o Anno não foi aberto:
  o dono estava no PC). No `shaders/water.gdshader`, as bandas da Fase 35 se quebram em trechos (`band_piece_m`, `band_gap`) longe
  da areia (`band_whole_m`), sorteados de novo a cada onda pelo número da crista (só muda no vale). A linha branca solta no mar era
  a última banda, não a espuma das pedras. Laboratório: `CAPTURA_MAR=espuma` (um parâmetro da água por vez) e `CAPTURA_MAR=perfil`
  (as alturas da praia) no `tools/capture_phase295.tscn`.

### Água picada de perto (Fase 296, nossa)

- **Plano** em `docs/plano_fase296.md`. No começo do fragment do `shaders/water.gdshader`, depois do marulho, quatro trens de
  ondinhas curtas (`chop_lengths_m`) em volta do vento, com a fase torcida por um ruído, dobram a normal até `chop_far_m` da câmera.

### Fiapos de espuma nas pedras (Fase 297, nossa)

- **Plano** em `docs/plano_fase297.md`. No bloco `SHORE_FOAM` do `shaders/water.gdshader`, depois do anel da Fase 293, fiapos de
  espuma (`streak_*`) compridos ao longo do vento e rendados, andando com ele, do lado de baixo do vento e só na água funda junto
  da costa (a pedra; a praia rasa fica de fora).

### Mar escuro de longe (Fase 298, nossa)

- **Plano** em `docs/plano_fase298.md`. No `shaders/water.gdshader`, de `far_sea_from_m` a `far_sea_to_m` da câmera, o fundo
  escurece (`far_sea_dark`) e o reflexo do céu cai (`far_sea_specular`). O horizonte claro é o reflexo do céu no ângulo raso e a
  névoa; a cor de Fresnel do material do Ocean fica (sem ela aparecem listras). Laboratório: `CAPTURA_MAR=longe` no
  `tools/capture_phase295.tscn`.

### Fundo à vista no raso (Fase 299, nossa)

- **Plano** em `docs/plano_fase299.md`. No fundo do mar do `shaders/terrain.gdshader`, nas temperadas (`seabed_detail`, ligado pela
  `TerrainView`): ondulações paralelas à costa, manchas de alga e pedrinhas até `seabed_detail_m`; no `shaders/water.gdshader`, a
  água rasa das temperadas perde até `clear_strength` da cobertura até `clear_depth_m` de água.

### Telhas gastas (Fase 300, nossa)

- **Plano** em `docs/plano_fase300.md`, primeira do roteiro `docs/plano_fases_300_304.md` (telhado gasto e chão de vila). No
  `shaders/building_kit.gdshader`, nas águas de telha: o tom de cada casa (`roof_pick`, outros bits do hash dos postigos), as telhas
  trocadas (`roof_tile_at`, `roof_swap_share`), o musgo em manchas e a sujeira escorrida (`roof_wear`). Captura do ciclo em
  `tools/capture_phase300.tscn`.

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
| 104 — Lampião, grade e chaminé de tijolo (nossa) | **feita em 29/10/2026**, a última do roteiro da rua habitada: chaminé de tijolo com capitel e potes no lugar do bloco do kit; lampião de ferro ao lado da porta dos serviços e das casas dos artesãos para cima, aceso à noite; grade de ferro com portão no pátio do museu; plano em `docs/plano_fase104.md` |
| 105 — Árvores de quintal (nossa) | **feita em 29/10/2026**, primeira do roteiro cidade e porto (Fases 105 a 109): macieiras pequenas com fruta nas células livres junto das casas, pelo recheio; bananeira nas tropicais; plano em `docs/plano_fase105.md` |
| 106 — Cais de pedra (nossa) | **feita em 29/10/2026**: cais reto de cantaria dos dois lados do entreposto, no nível do cais de tábuas, com paredão para o mar, capeamento e cabeços, parando onde a terra sobe; plano em `docs/plano_fase106.md` |
| 107 — Barcos de pesca (nossa) | **feita em 30/10/2026**: um barco a vela por cabana de pesca, que sai para o pesqueiro, pesca dando uma volta e retorna enquanto a cabana produz, e fica amarrado com ela parada; plano em `docs/plano_fase107.md` |
| 108 — Farol (nossa) | **feita em 30/10/2026**: farol caiado com faixas vermelhas na ponta de terra mais exposta ao mar perto de cada entreposto, com a lanterna acesa e dois fachos girando à noite; plano em `docs/plano_fase108.md` |
| 109 — Largo calçado (nossa) | **feita em 30/10/2026**, a última do roteiro cidade e porto: lajes de pedra em tons nas células livres em volta da igreja, do teatro, da universidade, da prefeitura, do museu e da escola, sem recheio em cima; plano em `docs/plano_fase109.md` |
| 110 — Brilho do sol no mar (nossa) | **feita em 30/10/2026**, primeira do roteiro sol, trópico e avenida (Fases 110 a 114): pontos de brilho cintilando no mar aberto onde o reflexo do sol cai, de dia; plano em `docs/plano_fase110.md` |
| 111 — Terreiro tropical (nossa) | **feita em 30/10/2026**: chão de terra batida em volta das casas das ilhas tropicais, pela máscara das estradas; plano em `docs/plano_fase111.md` |
| 112 — Coqueiros na rua tropical (nossa) | **feita em 30/10/2026**: coqueiros pequenos na beira das ruas das ilhas tropicais, pelo recheio; plano em `docs/plano_fase112.md` |
| 113 — Alameda (nossa) | **feita em 30/10/2026**: árvores plantadas a cada três células dos dois lados das ruas calçadas, onde a célula é livre; plano em `docs/plano_fase113.md` |
| 114 — Gradil das casas ricas (nossa) | **feita em 30/10/2026**, a última do roteiro sol, trópico e avenida: gradil baixo de ferro com lanças e o vão da porta na frente das casas dos engenheiros; plano em `docs/plano_fase114.md` |
| 115 — Carreira do estaleiro (nossa) | **feita em 30/10/2026**, primeira do roteiro fazenda, taverna e estaleiro (Fases 115 a 119): rampa de madeira do estaleiro até a água, com o casco em obra crescendo pelo progresso da encomenda (quilha, cavername, costado, borda, andaime) e sumindo quando o navio fica pronto; plano em `docs/plano_fase115.md` |
| 116 — Mesas da taverna (nossa) | **feita em 30/10/2026**: mesas redondas com bancos e guarda-sóis listrados na cor da taverna nas células livres em volta dela, fechados à noite; plano em `docs/plano_fase116.md` |
| 117 — Silos das fazendas (nossa) | **feita em 30/10/2026**: silo de aduelas com telhado cônico ou caixa d'água sobre pés numa célula livre atrás de cada fazenda; plano em `docs/plano_fase117.md` |
| 118 — Chão gasto no pasto (nossa) | **feita em 30/10/2026**: manchas de terra pisada na porteira, no cocho e soltas dentro de cada pasto, e um cocho de madeira com água junto da cerca de trás; plano em `docs/plano_fase118.md` |
| 119 — Poças de luz à noite (nossa) | **feita em 30/10/2026**, a última do roteiro fazenda, taverna e estaleiro: disco de luz quente no chão debaixo de cada poste e fogueira e diante da porta das casas com morador, só à noite e sem luz de verdade; plano em `docs/plano_fase119.md` |
| 120 — Postes e fios (nossa) | **feita em 30/10/2026**, primeira do roteiro fios, riacho e mansarda (Fases 120 a 124): postes de madeira com travessa e isoladores pelas ruas em volta de cada usina, com dois fios caindo em curva de um poste ao outro, sem passar por cima dos prédios; plano em `docs/plano_fase120.md` |
| 121 — Gavião sobre a cidade (nossa) | **feita em 30/10/2026**: um gavião (mais nas cidades grandes) planando em círculos largos e altos sobre cada cidade, batendo a asa de vez em quando, de dia; plano em `docs/plano_fase121.md` |
| 122 — Pedras no rio (nossa) | **feita em 30/10/2026**: matacões de rocha no leito raso dos rios, saindo da água com a espuma em volta, e seixos na margem baixa; plano em `docs/plano_fase122.md` |
| 123 — Borrifo nas falésias (nossa) | **feita em 30/10/2026**: jatos de espuma subindo de tempos em tempos onde o mar bate nos rochedos e nas falésias perto da câmera, do lado do mar; plano em `docs/plano_fase123.md` |
| 124 — Mansarda dos investidores (nossa) | **feita em 30/10/2026**, a última do roteiro fios, riacho e mansarda: telhado de mansarda (água de baixo íngreme com lucarnas, a de cima quase plana) nas casas dos investidores sem ala; plano em `docs/plano_fase124.md` |
| 125 — Recife de coral (nossa) | **feita em 30/10/2026**, primeira do roteiro recife, alpendre e nuvens (Fases 125 a 129): manchas escuras de coral no mar raso das ilhas tropicais; plano em `docs/plano_fase125.md` |
| 126 — Alpendre tropical (nossa) | **feita em 30/10/2026**: as casas dos operários e artesãos das ilhas tropicais recuam uma fileira e ganham alpendre de tábuas com esteios, guarda-corpo e telhado de uma água; plano em `docs/plano_fase126.md` |
| 127 — Cisternas no cais (nossa) | **feita em 30/10/2026**: duas cisternas redondas de aduelas sobre soco de pedra no cais de pedra de cada entreposto, uma de cada lado; plano em `docs/plano_fase127.md` |
| 128 — Jazidas à vista (nossa) | **feita em 30/10/2026**: um afloramento de rocha e pedras na cor do minério (carvão, ferro, ouro) sobre cada jazida ainda sem mina; plano em `docs/plano_fase128.md` |
| 129 — Sombra das nuvens (nossa) | **feita em 30/10/2026**, a última do roteiro recife, alpendre e nuvens: manchas de sombra das nuvens correndo pelo chão e pelo mar na direção do vento, mais com o céu nublado; plano em `docs/plano_fase129.md` |
| 130 — Telhado de sapê (nossa) | **feita em 31/10/2026**, primeira do roteiro sapê, bueiro e ardósia (Fases 130 a 134): as casas dos camponeses trocam as tábuas do telhado por sapê, com fiadas grossas, fios de palha e o tom de palha velha; plano em `docs/plano_fase130.md` |
| 131 — Bueiros na rua calçada (nossa) | **feita em 31/10/2026**: tampas redondas de ferro fundido no meio das ruas retas de paralelepípedo, pelo desenho da grade; plano em `docs/plano_fase131.md` |
| 132 — Bomba d'água (nossa) | **feita em 31/10/2026**: bomba de ferro fundido com alavanca, bica, laje e baldes numa célula livre junto de uma casa a cada seis, virada para a rua; plano em `docs/plano_fase132.md` |
| 133 — Bandeirolas da feira (nossa) | **feita em 31/10/2026**: quatro postes e duas cordas de bandeirolas em xis sobre o pátio das bancas de cada mercado, o ano todo; plano em `docs/plano_fase133.md` |
| 134 — Ardósia nos prédios de pedra (nossa) | **feita em 31/10/2026**, a última do roteiro sapê, bueiro e ardósia: a igreja, a escola, o mercado, a prefeitura, o teatro, a universidade e o museu trocam as telhas por ardósia cinza-azulada; plano em `docs/plano_fase134.md` |
| 135 — Galinhas no quintal (nossa) | **feita em 31/10/2026**, primeira do roteiro galinha, forno e mina (Fases 135 a 139): galinhas e um galo de vez em quando ciscando e andando no quintal cercado das casas dos camponeses, de dia; plano em `docs/plano_fase135.md` |
| 136 — Vagoneta e rejeito (nossa) | **feita em 31/10/2026**: em cada mina, um trilho curto sobre cavaletes sai da parede até um monte de rejeito na cor do minério, com a vagoneta saindo cheia, virando na ponta e voltando enquanto a mina produz; plano em `docs/plano_fase136.md` |
| 137 — Boca do forno acesa (nossa) | **feita em 31/10/2026**: a padaria, a olaria, a vidraria, a fundição e a de vigas de aço ganham uma boca de forno em arco de tijolo numa fachada do lado, com o fogo tremulando enquanto produzem e a luz laranja no chão à noite; plano em `docs/plano_fase137.md` |
| 138 — Telhado de chapa ondulada (nossa) | **feita em 31/10/2026**: a olaria, a fundição, a vidraria, as usinas, a de vigas de aço, as conservas, as máquinas de costura e a de lâmpadas trocam as telhas por chapa de ferro ondulada, cinza com a ferrugem escorrendo das juntas; plano em `docs/plano_fase138.md` |
| 139 — Redes de pesca (nossa) | **feita em 31/10/2026**, a última do roteiro galinha, forno e mina: ao lado de cada cabana de pesca, dois cavaletes com a rede estendida secando, as boias de cortiça, as caixas de peixe e o cesto; plano em `docs/plano_fase139.md` |
| 140 — Clareira do lenhador (nossa) | **feita em 31/10/2026**, primeira do roteiro toco, bote e boia (Fases 140 a 144): em volta de cada lenhador a mata recua no desenho, mais perto da cabana, e as células cortadas ficam com os tocos e umas toras caídas; plano em `docs/plano_fase140.md` |
| 141 — Árvore seca (nossa) | **feita em 31/10/2026**: árvores secas e nuas, de galhos tortos e madeira cinzenta, de vez em quando na beira da mata e na costa das ilhas temperadas; plano em `docs/plano_fase141.md` |
| 142 — Botes no porto (nossa) | **feita em 31/10/2026**: dois botes a remo por entreposto dando voltas na água funda diante dele, um em cada sentido, com o remador inclinando a cada remada e os remos varrendo; somem à noite; plano em `docs/plano_fase142.md` |
| 143 — Cerca de estacas (nossa) | **feita em 31/10/2026**: cerquinha de estacas caiadas com a ponta em pirâmide e o vão da porta na frente das casas dos operários; plano em `docs/plano_fase143.md` |
| 144 — Boias no porto (nossa) | **feita em 31/10/2026**, a última do roteiro toco, bote e boia: boias pintadas em pares marcando a entrada diante de cada entreposto, a vermelha de um lado e a verde do outro, balançando nas ondas; plano em `docs/plano_fase144.md` |
| 145 — Relógio da igreja (nossa) | **feita em 31/10/2026**, primeira do roteiro relógio, cais e cata-vento (Fases 145 a 149): dois mostradores na torre da igreja com os ponteiros marcando a hora do jogo, acesos à noite; plano em `docs/plano_fase145.md` |
| 146 — Grade e lampiões no cais (nossa) | **feita em 31/10/2026**: grade de ferro na beira do cais de pedra, aberta nos cabeços e diante do entreposto, e lampiões a gás acesos à noite; plano em `docs/plano_fase146.md` |
| 147 — Mastros no cais (nossa) | **feita em 31/10/2026**: um mastro caiado com a bola dourada e uma flâmula de rabo de andorinha na ponta de cada lado do cais de pedra, tremulando para o lado do vento; plano em `docs/plano_fase147.md` |
| 148 — Cavalete do lenhador (nossa) | **feita em 31/10/2026**: junto de cada lenhador, o cavalete de serrar com uma tora, o cepo com o machado cravado, a pilha de lenha rachada e as lascas no chão; plano em `docs/plano_fase148.md` |
| 149 — Cata-vento no pasto (nossa) | **feita em 31/10/2026**, a última do roteiro relógio, cais e cata-vento: torre de vigas junto do cocho de cada pasto com a roda de lâminas e o leme, virando para o vento e girando pela força dele; plano em `docs/plano_fase149.md` |
| 150 — Coluna de anúncios (nossa) | **feita em 31/10/2026**, primeira do roteiro coluna, placa e velocípede (Fases 150 a 154): colunas redondas de cartazes coloridos com o chapéu de ferro no canto de dentro das esquinas calçadas; plano em `docs/plano_fase150.md` |
| 151 — Placas das lojas (nossa) | **feita em 31/10/2026**: placa pendurada num braço de ferro ao lado da porta da padaria, do açougue, da taverna, do ourives, do relojoeiro, do óptico, da torrefação e da charutaria, com a figura do ofício pintada (sem texto); plano em `docs/plano_fase151.md` |
| 152 — Balizas com corrente (nossa) | **feita em 31/10/2026**: balizas de ferro com correntes caindo em curva na beira do largo calçado dos serviços, de frente para a rua, com aberturas para entrar; plano em `docs/plano_fase152.md` |
| 153 — Flores nas sacadas (nossa) | **feita em 31/10/2026**: floreiras de madeira com folhagem e flores vermelhas, rosas e amarelas penduradas por fora do guarda-corpo das sacadas dos engenheiros e investidores; plano em `docs/plano_fase153.md` |
| 154 — Velocípede encostado (nossa) | **feita em 31/10/2026**, a última do roteiro coluna, placa e velocípede: um velocípede de roda grande encostado na parede da frente, ao lado da porta, de uma casa dos artesãos a cada quatro; plano em `docs/plano_fase154.md` |
| 155 — Carneirinhos no mar (nossa) | **feita em 31/10/2026**, primeira do roteiro carneirinho, papoula e colheita (Fases 155 a 159): manchas de espuma que nascem, andam com o vento e se desfazem em renda no mar aberto, mais com o vento forte; plano em `docs/plano_fase155.md` |
| 156 — Papoulas no prado (nossa) | **feita em 31/10/2026**: canteiros de papoulas vermelhas no capim aberto e na beira das estradas das ilhas temperadas, juntos em manchas e fora da areia da praia; plano em `docs/plano_fase156.md` |
| 157 — Caixas da colheita (nossa) | **feita em 31/10/2026**: perto da colheita, pares de caixotes e sacos de juta vão aparecendo entre as fileiras dos campos, e somem quando o campo é colhido; plano em `docs/plano_fase157.md` |
| 158 — Carroça de lona (nossa) | **feita em 31/10/2026**: metade das carroças que levam saco ou caixote anda com os arcos de madeira e a lona sobre a caçamba, com a carga escondida debaixo dela; plano em `docs/plano_fase158.md` |
| 159 — Tijolos secando (nossa) | **feita em 31/10/2026**, a última do roteiro carneirinho, papoula e colheita: ao lado de cada olaria, duas fileiras de tijolos crus secando em grade com as tábuas na cumeeira e o monte de barro escavado; plano em `docs/plano_fase159.md` |
| 160 — Cunhais de pedra (nossa) | **feita em 31/10/2026**, primeira do roteiro cunhal, deriva e horta (Fases 160 a 164): blocos de pedra clara alternados nas quatro quinas das casas dos artesãos e engenheiros, da soleira à cornija; plano em `docs/plano_fase160.md` |
| 161 — Madeira à deriva (nossa) | **feita em 31/10/2026**: troncos velhos, cinzentos de sal, com as raízes quebradas, largados na praia e nas pedras baixas da costa; plano em `docs/plano_fase161.md` |
| 162 — Cascalho nas encostas (nossa) | **feita em 31/10/2026**: montinhos de pedrinhas soltas deitados nas encostas íngremes e acumulados no pé delas; plano em `docs/plano_fase162.md` |
| 163 — Horta no quintal (nossa) | **feita em 31/10/2026**: canteiro com couves, alfaces e a tenda de feijão atrás de uma casa de camponeses ou operários a cada três, ao lado do varal e da fogueira das vizinhas; plano em `docs/plano_fase163.md` |
| 164 — Caldeira das árvores (nossa) | **feita em 31/10/2026**, a última do roteiro cunhal, deriva e horta: anel de pedra com a terra e a grade de ferro no pé de cada árvore da alameda; plano em `docs/plano_fase164.md` |
| 165 — Chão batido das fábricas (nossa) | **feita em 31/10/2026**, primeira do roteiro chão batido, feno e gaivota (Fases 165 a 169): terra batida de borda recortada em volta de todo prédio de produção; plano em `docs/plano_fase165.md` |
| 166 — Medas de feno (nossa) | **feita em 31/10/2026**: duas medas de feno redondas com a vara no alto ao lado das fazendas de ovelhas, porcos e trigo; plano em `docs/plano_fase166.md` |
| 167 — Capim alto nos terrenos vazios (nossa) | **feita em 31/10/2026**: manchas de capim alto e espigado, verde no pé e cor de palha nas pontas, no campo aberto das ilhas temperadas, fora dos canteiros de papoulas; plano em `docs/plano_fase167.md` |
| 168 — Gaivotas no cais (nossa) | **feita em 31/10/2026**: gaivotas de pé em parte dos cabeços dos píeres e do cais, virando a cabeça de tempos em tempos; plano em `docs/plano_fase168.md` |
| 169 — Barril de chuva (nossa) | **feita em 31/10/2026**, a última do roteiro chão batido, feno e gaivota: o barril de aduelas com a calha descendo do beiral, na quina de trás de metade das casas dos camponeses e operários; plano em `docs/plano_fase169.md` |
| 170 — Barranco de terra vermelha (nossa) | **feita em 31/10/2026**, primeira do roteiro laterita, lenha e carrinho (Fases 170 a 174): a margem dos rios das ilhas tropicais em laterita vermelha, no lugar da lama escura; plano em `docs/plano_fase170.md` |
| 171 — Lenha na parede (nossa) | **feita em 31/10/2026**: a pilha de lenha rachada com a cobertura de tábuas encostada na parede do lado de parte das casas dos camponeses e operários; plano em `docs/plano_fase171.md` |
| 172 — Carrinho de mão (nossa) | **feita em 31/10/2026**: o carrinho de mão de madeira parado no pátio de chão batido atrás de metade das oficinas; plano em `docs/plano_fase172.md` |
| 173 — Tina de lavar (nossa) | **feita em 31/10/2026**: a tina de aduelas com a água ensaboada e a tábua de esfregar ao lado de cada varal; plano em `docs/plano_fase173.md` |
| 174 — Banco na porta (nossa) | **feita em 31/10/2026**, a última do roteiro laterita, lenha e carrinho: o banco de tábua encostado na parede da frente, no quintal cercado de parte das casas dos camponeses; plano em `docs/plano_fase174.md` |
| 175 — Espantalho no campo (nossa) | **feita em 31/10/2026**, primeira do roteiro espantalho, cegonha e vaga-lume (Fases 175 a 179): um espantalho de pau com casaco, chapéu e palha saindo das mangas no vão do meio de um a cada três campos de trigo e de batata; plano em `docs/plano_fase175.md` |
| 176 — Cegonha na chaminé (nossa) | **feita em 31/10/2026**: o ninho de gravetos com a cegonha de pé, virando de tempos em tempos, no alto da chaminé de uma a cada quatro casas dos camponeses e operários das ilhas temperadas; a chaminé com ninho não fumega; plano em `docs/plano_fase176.md` |
| 177 — Postigos nas janelas (nossa) | **feita em 31/10/2026**: as duas folhas de madeira abertas dos lados de cada janela das casas dos camponeses, operários e artesãos, pintadas de verde, azul, vermelho ou ocre pelo prédio, com as réguas da veneziana; plano em `docs/plano_fase177.md` |
| 178 — Vaga-lumes no prado (nossa) | **feita em 31/10/2026**: enxames de pontinhos de luz verde-amarela vagando baixo e piscando na beira da mata e no capim aberto, longe das casas e das estradas, ao anoitecer e à noite; plano em `docs/plano_fase178.md` |
| 179 — Juncos na margem (nossa) | **feita em 31/10/2026**, a última do roteiro espantalho, cegonha e vaga-lume: touceiras de junco alto com as espigas marrons da taboa na margem baixa dos rios, balançando com o vento; plano em `docs/plano_fase179.md` |
| 180 — Borboletas nos canteiros (nossa) | **feita em 31/10/2026**, primeira do roteiro borboleta, correio e galo (Fases 180 a 184): borboletas brancas, amarelas, laranja e azuis esvoaçando e batendo as asas sobre os canteiros de papoulas das ilhas temperadas e no capim aberto das tropicais, de dia; plano em `docs/plano_fase180.md` |
| 181 — Caixa de correio (nossa) | **feita em 31/10/2026**: a caixa de correio de ferro fundido, redonda e vermelha, com a boca e a plaquinha, encostada na calçada de parte das células das ruas calçadas, virada para a rua; plano em `docs/plano_fase181.md` |
| 182 — Galo do cata-vento (nossa) | **feita em 31/10/2026**: a haste de ferro com a rosa dos ventos e o galo de bronze recortado no alto da cumeeira das fazendas das ilhas temperadas, virando a cabeça para o lado de onde vem o vento; plano em `docs/plano_fase182.md` |
| 183 — Barco na areia (nossa) | **feita em 31/10/2026**: o bote de pesca virado de borco na praia, com uma ponta apoiada e os dois remos deitados na areia, ao lado de cada cabana de pesca; plano em `docs/plano_fase183.md` |
| 184 — Limo na pedra (nossa) | **feita em 31/10/2026**, a última do roteiro borboleta, correio e galo: a faixa escura de limo e sargaço, a pedra molhada e a crosta clara da maré nos rochedos, nas rochas da falésia e nas pedras do rio, junto da linha d'água; plano em `docs/plano_fase184.md` |
| 185 — Hera nas paredes (nossa) | **feita em 01/11/2026**, primeira do roteiro hera, estaca e arco-íris (Fases 185 a 189): a hera subindo em colunas pelas paredes da igreja e dos serviços de pedra e de parte das casas de alvenaria das ilhas temperadas; plano em `docs/plano_fase185.md` |
| 186 — Estacas na água (nossa) | **feita em 01/11/2026**: feixes de cinco estacas de madeira amarradas com cabo e o limo junto da água, cravados diante de cada entreposto e na ponta dos píeres; plano em `docs/plano_fase186.md` |
| 187 — Placa na encruzilhada (nossa) | **feita em 01/11/2026**: o poste de madeira com uma tábua em seta apontando cada estrada nos cruzamentos e entroncamentos das estradas de terra fora das vilas; plano em `docs/plano_fase187.md` |
| 188 — Arco-íris (nossa) | **feita em 01/11/2026**: o arco-íris no céu do lado oposto ao sol logo depois da chuva, sumindo em pouco mais de uma hora; plano em `docs/plano_fase188.md` |
| 189 — Focas nas pedras (nossa) | **feita em 01/11/2026**, a última do roteiro hera, estaca e arco-íris: grupos de focas malhadas deitadas na costa baixa das ilhas temperadas, longe das vilas, viradas para o mar, erguendo a cabeça de tempos em tempos; plano em `docs/plano_fase189.md` |
| 190 — Colmeias de palha (nossa) | **feita em 01/11/2026**, primeira do roteiro colmeia, pombal e varal (Fases 190 a 194): o banco com três colmeias de palha trançada ao lado das fazendas de lúpulo, vinhedo e batata, com as abelhas zunindo em volta de dia; plano em `docs/plano_fase190.md` |
| 191 — Pombal (nossa) | **feita em 01/11/2026**: o pombal de tábua no alto de um poste no canto da frente de metade das fazendas de gado, trigo e batata, com os pombos pousados no telhadinho e nos poleiros; plano em `docs/plano_fase191.md` |
| 192 — Roupa sobre a rua (nossa) | **feita em 01/11/2026**: o varal com a roupa colorida atravessando no alto a rua de terra entre casas de operários frente a frente; plano em `docs/plano_fase192.md` |
| 193 — Carroça de feno parada (nossa) | **feita em 01/11/2026**: a carroça carregada de feno, sem o cavalo, tombada para a frente com os varais no chão, ao lado das medas de metade das fazendas; plano em `docs/plano_fase193.md` |
| 194 — Escada do cais (nossa) | **feita em 01/11/2026**, a última do roteiro colmeia, pombal e varal: o lance de degraus de pedra descendo do cais de pedra até dentro da água, encostado no paredão, com a argola de ferro, dos dois lados de cada entreposto; plano em `docs/plano_fase194.md` |
| 195 — Cemitério da igreja (nossa) | **feita em 01/11/2026**, primeira do roteiro cemitério, pato e rede (Fases 195 a 199): lápides de topo redondo, cruzes e obeliscos em fileiras atrás da igreja, além do largo, umas tombando, dentro de um muro baixo de pedra com o portão virado para ela; plano em `docs/plano_fase195.md` |
| 196 — Patos na água (nossa) | **feita em 01/11/2026**: bandos de patos nadando em roda na água calma da costa, longe da espuma e dos portos, a pata com os patinhos em fila ou patos e patas juntos, mergulhando a cabeça de vez em quando, de dia; plano em `docs/plano_fase196.md` |
| 197 — Casinha do cão (nossa) | **feita em 01/11/2026**: a casinha de tábuas com telhado de duas águas, a porta em arco e a tigela de água ao lado das casas que têm cão na porta, virada para a rua; plano em `docs/plano_fase197.md` |
| 198 — Bancos no cais (nossa) | **feita em 01/11/2026**: bancos de praça de pés de ferro e tábuas no cais de pedra dos entrepostos, entre os cabeços, de costas para a cidade e virados para o mar, longe dos lampiões, das cisternas, dos mastros e das escadas; plano em `docs/plano_fase198.md` |
| 199 — Rede na varanda (nossa) | **feita em 01/11/2026**, a última do roteiro cemitério, pato e rede: a rede de dormir listrada pendurada entre dois esteios da varanda de parte das casas das ilhas tropicais, ao lado da porta, balançando de leve; plano em `docs/plano_fase199.md` |
| 200 — Gato na porta (nossa) | **feita em 01/11/2026**, primeira do roteiro gato, poço e carrinho (Fases 200 a 204): um gato ruivo, preto, cinza, branco ou creme sentado ao lado da porta de parte das casas (as que não têm cão), virando a cabeça de vez em quando; plano em `docs/plano_fase200.md` |
| 201 — Poço da vila (nossa) | **feita em 01/11/2026**: o poço de pedra em fiadas com o telhadinho de duas águas, o sarilho e o balde numa célula livre junto da rua, ao lado de parte das casas dos camponeses; plano em `docs/plano_fase201.md` |
| 202 — Secadouro de peixe (nossa) | **feita em 01/11/2026**: as varas cruzadas com os peixes abertos pendurados secando, do lado da terra de cada cabana de pesca das ilhas temperadas; plano em `docs/plano_fase202.md` |
| 203 — Carrinho de feira (nossa) | **feita em 01/11/2026**: o carrinho de mão de duas rodas com o tabuleiro de frutas e verduras e o guarda-sol listrado, numa célula junto da rua ao lado de cada mercado; plano em `docs/plano_fase203.md` |
| 204 — Guarda-sol de palha (nossa) | **feita em 01/11/2026**, a última do roteiro gato, poço e carrinho: guarda-sóis de folha de palmeira com o banco de toras na areia em volta do entreposto e das cabanas de pesca das ilhas tropicais, além do cais de pedra; e as buscas junto da rua guardadas até a próxima obra (o carregar voltou de 6,4 para 6,0 s); plano em `docs/plano_fase204.md` |
| 205 — Estandartes na fachada (nossa) | **feita em 01/11/2026**, primeira do roteiro estandarte, bebedouro e lanterna (Fases 205 a 209): estandartes de rabo de andorinha na cor do prédio, com o galão dourado, pendurados num braço de ferro de cada lado da porta da prefeitura, do teatro, da universidade, do museu e da escola, balançando com o vento; plano em `docs/plano_fase205.md` |
| 206 — Bebedouro de cavalos (nossa) | **feita em 01/11/2026**: o cocho comprido de pedra com a água, a coluna da bica e a argola de amarrar, encostado na parede do lado de cada taverna, ao lado das mesas; plano em `docs/plano_fase206.md` |
| 207 — Pinheiro-anão na encosta (nossa) | **feita em 01/11/2026**: pinheiros baixos e tortos, com as almofadas de agulhas achatadas pelo vento, agarrados nas encostas íngremes das ilhas temperadas; plano em `docs/plano_fase207.md` |
| 208 — Rama de tecido (nossa) | **feita em 01/11/2026**: duas ramas de madeira com os panos tingidos de garança e anil esticados secando, numa fila de três células atrás de cada tecelagem; plano em `docs/plano_fase208.md` |
| 209 — Lanterna nas carroças (nossa) | **feita em 01/11/2026**, a última do roteiro estandarte, bebedouro e lanterna: a lanterna de ferro pendurada num braço na frente de cada carroça, acesa à noite, na própria malha da carroça; plano em `docs/plano_fase209.md` |
| 210 — Pombos na cumeeira (nossa) | **feita em 01/11/2026**, primeira do roteiro pombo, mó e buxo (Fases 210 a 214): uma fila de pombos cinza-azulados pousados na cumeeira de parte das casas de duas águas, longe da chaminé; plano em `docs/plano_fase210.md` |
| 211 — Mós no moinho (nossa) | **feita em 01/11/2026**: duas mós de pedra de pé encostadas na parede do lado de cada moinho, com a pilha de sacos de farinha ao lado; plano em `docs/plano_fase211.md` |
| 212 — Buxo na porta (nossa) | **feita em 01/11/2026**: dois vasos de pedra com o buxo podado em bola, um de cada lado da porta das casas dos investidores, por fora das colunas; plano em `docs/plano_fase212.md` |
| 213 — Lenha da padaria (nossa) | **feita em 01/11/2026**: a pilha de lenha miúda sob uma tábua e a pá de forno de pé, encostadas na parede ao lado da boca do forno de cada padaria; plano em `docs/plano_fase213.md` |
| 214 — Escada de mão (nossa) | **feita em 01/11/2026**, a última do roteiro pombo, mó e buxo: a escada de madeira encostada na parede do lado de parte das casas, do chão até o beiral, com o balde de lata no pé; plano em `docs/plano_fase214.md` |
| 215 — Tábuas secando na serraria (nossa) | **feita em 01/11/2026**, primeira do roteiro tábua, cortina e andorinha (Fases 215 a 219): as pilhas de tábuas em camadas com os tabiques, sobre dormentes e cobertas por tábuas velhas, no lado de cada serraria oposto à roda d'água; plano em `docs/plano_fase215.md` |
| 216 — Monte de carvão na usina (nossa) | **feita em 01/11/2026**: a baia de tábuas com o monte de carvão em pedras escorrendo para fora, as pedras soltas no pé e a pá cravada, no lado de cada usina a carvão; plano em `docs/plano_fase216.md` |
| 217 — Cortinas nas janelas (nossa) | **feita em 01/11/2026**: os dois panos presos dos lados e a sanefa em cada janela das casas, em renda, creme, rosa ou verde-sálvia pela casa, com as pregas; plano em `docs/plano_fase217.md` |
| 218 — Andorinhas no campanário (nossa) | **feita em 01/11/2026**: um bando de andorinhas de costas azul-escuras e cauda em forquilha dando voltas rápidas em volta da torre de cada igreja, batendo as asas em rajadas, de dia; plano em `docs/plano_fase218.md` |
| 219 — Balanço e gangorra na escola (nossa) | **feita em 01/11/2026**, a última do roteiro tábua, cortina e andorinha: o balanço de madeira com dois assentos nas cordas e a gangorra pintada no lado de cada escola; a busca do lado livre virou o `SideYard`; plano em `docs/plano_fase219.md` |
| 220 — Bomba de incêndio no quartel (nossa) | **feita em 01/11/2026**, primeira do roteiro bomba, barril e lençol (Fases 220 a 224): a bomba de mão vermelha sobre rodas com os cilindros de latão e os braços dos bombeadores, o carretel da mangueira, a escada e os baldes de couro no lado de cada quartel; plano em `docs/plano_fase220.md` |
| 221 — Barris na cervejaria (nossa) | **feita em 01/11/2026**: a pirâmide de barris deitados sobre os calços e dois barris de pé com o funil no lado da cervejaria, das destilarias e da adega; plano em `docs/plano_fase221.md` |
| 222 — Covos no cais (nossa) | **feita em 01/11/2026**: pilhas de covos de vime em meia-lua com o cabo enrolado e as boias de cortiça nos lanços livres do cais de pedra dos entrepostos; plano em `docs/plano_fase222.md` |
| 223 — Lençóis no hospital (nossa) | **feita em 01/11/2026**: dois varais compridos com os lençóis brancos enfunados e o cesto de vime no lado de cada hospital; plano em `docs/plano_fase223.md` |
| 224 — Relógio de sol no largo (nossa) | **feita em 01/11/2026**, a última do roteiro bomba, barril e lençol: a coluna de pedra torneada com o mostrador de bronze e o gnomon num canto do largo calçado da igreja, do teatro, da universidade, da prefeitura, do museu e da escola; plano em `docs/plano_fase224.md` |
| 225 — Lanterna na popa (nossa) | **feita em 01/11/2026**, primeira do roteiro lanterna, lã e morcego (Fases 225 a 229): a lanterna de ferro num pau na ré de cada navio, acesa à noite; plano em `docs/plano_fase225.md` |
| 226 — Fardos de lã (nossa) | **feita em 01/11/2026**: os fardos de juta amarrados com cordas, o cepo de tosquia com a tesoura e o velo solto no lado das fazendas de ovelhas; plano em `docs/plano_fase226.md` |
| 227 — Lamaçal do chiqueiro (nossa) | **feita em 01/11/2026**: a poça de lama escura e molhada com a orla pisada e os torrões em cada pasto das fazendas de porcos, sem capim dentro; plano em `docs/plano_fase227.md` |
| 228 — Barris de petróleo (nossa) | **feita em 01/11/2026**: os barris de madeira enegrecidos pelo óleo, em pé e deitados sobre os calços, e a mancha de óleo no chão no lado de cada poço de petróleo; plano em `docs/plano_fase228.md` |
| 229 — Morcegos ao anoitecer (nossa) | **feita em 01/11/2026**, a última do roteiro lanterna, lã e morcego: os morcegos esvoaçando em zigue-zague em volta da torre de cada igreja, do anoitecer à madrugada; plano em `docs/plano_fase229.md` |
| 230 — Sinal no trilho (nossa) | **feita em 01/11/2026**, primeira do roteiro sinal, cormorão e castanha (Fases 230 a 234): o poste de sinal de braço vermelho com a escada e a lanterna acesa à noite em cada ponta de linha do trilho; plano em `docs/plano_fase230.md` |
| 231 — Cormorões nas estacas (nossa) | **feita em 01/11/2026**: o cormorão de pé com as asas abertas secando no alto das estacas de atracação diante dos entrepostos e dos píeres, de dia; plano em `docs/plano_fase231.md` |
| 232 — Tapete na janela (nossa) | **feita em 01/11/2026**: o tapete listrado com a franja estendido no peitoril de uma janela de cima de parte das casas dos operários e artesãos; plano em `docs/plano_fase232.md` |
| 233 — Cabines de banho (nossa) | **feita em 01/11/2026**: as cabines de banho de rodas, listradas de vermelho e branco, com a porta para o mar, na areia perto dos entrepostos das ilhas temperadas; plano em `docs/plano_fase233.md` |
| 234 — Fogareiro de castanhas (nossa) | **feita em 01/11/2026**, a última do roteiro sinal, cormorão e castanha: o carrinho do vendedor de castanhas com o fogareiro de ferro e as brasas acesas à noite no canto de parte das esquinas calçadas; plano em `docs/plano_fase234.md` |
| 235 — Cervos na beira da mata (nossa) | **feita em 01/11/2026**, primeira do roteiro cervo, âncora e marco (Fases 235 a 239): grupos de corças com um veado de galhada pastando na beira da mata das ilhas temperadas, longe das vilas, erguendo a cabeça de vez em quando; plano em `docs/plano_fase235.md` |
| 236 — Âncora no cais (nossa) | **feita em 01/11/2026**: a âncora velha de ferro deitada com um braço erguido, o cepo de madeira e a amarra enrolada ao lado, no fundo do cais de pedra de cada entreposto; plano em `docs/plano_fase236.md` |
| 237 — Marco de légua (nossa) | **feita em 01/11/2026**: o marco de pedra de topo redondo com a inscrição e o musgo no pé na beira das estradas de terra retas e compridas fora das vilas, um a cada 23 células; plano em `docs/plano_fase237.md` |
| 238 — Bandeira na prefeitura (nossa) | **feita em 01/11/2026**: o mastro de ferro com a bandeira da cidade (vermelha com o losango dourado) no alto da cúpula de cada prefeitura, virando e tremulando com o vento; plano em `docs/plano_fase238.md` |
| 239 — Algas na praia (nossa) | **feita em 01/11/2026**, a última do roteiro cervo, âncora e marco: a faixa torta de sargaço escuro com as fitas soltas, deixada pela maré na areia baixa e plana junto do mar; plano em `docs/plano_fase239.md` |
| 240 — Lagar no vinhedo (nossa) | **feita em 01/11/2026**, primeira do roteiro lagar, terreiro e estacas (Fases 240 a 244): a tina de pisar uvas com o mosto, a prensa de fuso e os cestos de uva no lado de cada vinhedo; plano em `docs/plano_fase240.md` |
| 241 — Terreiro de café (nossa) | **feita em 01/11/2026**: o terreiro caiado com o café espalhado secando ao sol, vermelho de um lado e seco do outro, com os sulcos do rodo, o montinho e os sacos, no lado de cada cafezal; plano em `docs/plano_fase241.md` |
| 242 — Tabaco secando (nossa) | **feita em 01/11/2026**: o varal de varas com as réstias de folhas de tabaco penduradas, verdes, douradas e curadas, e o cesto de folhas no lado de cada plantação de tabaco; plano em `docs/plano_fase242.md` |
| 243 — Vigas de aço empilhadas (nossa) | **feita em 01/11/2026**: a pilha de vigas de ferro em I em camadas sobre os dormentes, com uma viga solta no chão, no lado de cada fábrica de vigas de aço; plano em `docs/plano_fase243.md` |
| 244 — Estacas de lúpulo (nossa) | **feita em 01/11/2026**, a última do roteiro lagar, terreiro e estacas: as estacas compridas deitadas nos cavaletes e o feixe amarrado encostado na parede, no lado de cada fazenda de lúpulo; plano em `docs/plano_fase244.md` |
| 245 — Coelhos no prado (nossa) | **feita em 01/11/2026**, primeira do roteiro coelho, cogumelo e pedra (Fases 245 a 249): tocas de coelhos pardos de rabo branco pastando no capim aberto das ilhas temperadas, longe das vilas, sentando de vez em quando; plano em `docs/plano_fase245.md` |
| 246 — Tronco caído com cogumelos (nossa) | **feita em 01/11/2026**: troncos velhos caídos na beira da mata das ilhas temperadas, cobertos de musgo, com as orelhas-de-pau de lado e os cogumelos vermelhos no chão; plano em `docs/plano_fase246.md` |
| 247 — Madeira curvada no estaleiro (nossa) | **feita em 01/11/2026**: a pilha de tábuas e as cavernas curvas em U esperando a vez de entrar no casco, no lado de cada estaleiro, longe da carreira; plano em `docs/plano_fase247.md` |
| 248 — Caixotes de vidro (nossa) | **feita em 01/11/2026**: o cavalete com as chapas de vidro de pé e os caixotes de ripas com palha e vidraças no lado de cada vidraria e janelaria; plano em `docs/plano_fase248.md` |
| 249 — Montes de pedra nos campos (nossa) | **feita em 01/11/2026**, a última do roteiro coelho, cogumelo e pedra: os montes baixos de pedras tiradas da terra arada num canto da cabeceira de parte dos campos das ilhas temperadas; plano em `docs/plano_fase249.md` |
| 250 — Balança de carga no armazém (nossa) | **feita em 01/11/2026**, primeira do roteiro balança, cabra e canoa (Fases 250 a 254): a balança decimal de plataforma com os pesos, um saco em cima e os sacos amarrados esperando no lado de cada armazém; plano em `docs/plano_fase250.md` |
| 251 — Cabras nas encostas (nossa) | **feita em 01/11/2026**: grupos de cabras malhadas de chifres para trás pastando nas encostas íngremes das ilhas temperadas, longe das vilas, uma de pé numa pedra; plano em `docs/plano_fase251.md` |
| 252 — Carruagem à porta do teatro (nossa) | **feita em 01/11/2026**: a carruagem fechada laqueada de vinho, sem os cavalos, parada na rua diante da entrada de cada teatro; plano em `docs/plano_fase252.md` |
| 253 — Cestos de batata (nossa) | **feita em 01/11/2026**: os cestos de vime cheios de batata, um tombado com as batatas rolando, os sacos e o forcado no lado de cada fazenda de batata; plano em `docs/plano_fase253.md` |
| 254 — Canoas na margem do rio (nossa) | **feita em 01/11/2026**, a última do roteiro balança, cabra e canoa: a canoa escavada com o remo e o banco dentro, puxada para a margem baixa dos rios, de comprido ao longo dela, longe das vilas; plano em `docs/plano_fase254.md` |
| 255 — Ar limpo e tom vivo (nossa) | **feita em 01/11/2026**, primeira do roteiro cor viva (Fases 255 a 259), a pedido do dono: a névoa cinza-azulada de longe quase some, a cena ganha contraste, saturação e exposição e o sol fica quente; plano em `docs/plano_fase255.md` |
| 256 — Copas verdes (nossa) | **feita em 01/11/2026**: as matas deixam de ser blocos quase pretos: folhas mais claras, o alto das copas amarelado de sol e uma luz própria das folhas de dia; plano em `docs/plano_fase256.md` |
| 257 — Grama viva (nossa) | **feita em 01/11/2026**: a grama deixa o oliva-amarronzado e fica verde-amarelada e viva, de perto e de longe, guardando o claro e o escuro da textura; plano em `docs/plano_fase257.md` |
| 258 — Telhado e parede com cor (nossa) | **feita em 01/11/2026**: todo telhado em terracota viva ou tábua marrom quente (antes rosa-acinzentado), a tinta das paredes pesando mais que a textura cinza e o reboco quente nas classes de cima; plano em `docs/plano_fase258.md` |
| 259 — Praia dourada (nossa) | **feita em 01/11/2026**, a última do roteiro cor viva: a areia da praia deixa o cinza-taupe e fica dourada e clara; o mar já tinha ficado vivo na Fase 255; plano em `docs/plano_fase259.md` |
| 260 — Hora dourada (nossa) | **feita em 01/11/2026**, primeira do roteiro cor viva II (Fases 260 a 264): o fim da tarde e a manhã saem do vermelho-tijolo escuro para um dourado claro, a exposição sobe com o sol baixo e a mata para de brilhar sobre o chão escuro; plano em `docs/plano_fase260.md` |
| 261 — Rocha cinza (nossa) | **feita em 01/11/2026**: as falésias, os rochedos, as pedras e as encostas saem do marrom-oliva para um cinza claro, com o contraste do verde; plano em `docs/plano_fase261.md` |
| 262 — Campos coloridos (nossa) | **feita em 01/11/2026**: as leiras dos campos ganham a cor da plantação conforme ela cresce, o trigo do verde ao dourado e as outras no verde delas: de longe cada campo vira um retalho colorido; plano em `docs/plano_fase262.md` |
| 263 — Noite azul (nossa) | **feita em 01/11/2026**: a noite deixa de ser quase preta fora das janelas: as ruas, os telhados e a mata se leem no azul da lua, com as luzes por cima; plano em `docs/plano_fase263.md` |
| 264 — Sombra aberta (nossa) | **feita em 01/11/2026**, a última do roteiro cor viva II: a oclusão de ambiente mais leve, e o vão entre as copas e o pé das matas deixam de ficar quase pretos; plano em `docs/plano_fase264.md` |
| 265 — Garças no rio (nossa) | **feita em 02/11/2026**, primeira do roteiro garça, ruína e cruzeiro (Fases 265 a 269): a garça-real cinza de pé junto da água na margem baixa dos rios, longe das vilas, virando de um lado para o outro; plano em `docs/plano_fase265.md` |
| 266 — Ruínas de muro (nossa) | **feita em 02/11/2026**: pedaços de muro de pedra seca quebrados em degraus, com as pedras caídas e o musgo, de vez em quando no campo aberto das ilhas temperadas; plano em `docs/plano_fase266.md` |
| 267 — Espinheiro florido (nossa) | **feita em 02/11/2026**: o arbusto de espinheiro de copa torta coberto de flor branca e rosada na beira da mata das ilhas temperadas, balançando com o vento; plano em `docs/plano_fase267.md` |
| 268 — Casco naufragado (nossa) | **feita em 02/11/2026**: o esqueleto de um navio velho (a quilha, a roda de proa e as cavernas curvas, umas quebradas, e o mastro partido) encalhado na areia da costa baixa das ilhas temperadas, longe das vilas; plano em `docs/plano_fase268.md` |
| 269 — Cruzeiro no morro (nossa) | **feita em 02/11/2026**, a última do roteiro garça, ruína e cruzeiro: a cruz de pedra clara sobre o degrau e o pedestal, com o musgo no pé, no ponto mais alto e livre de cada ilha temperada, virada para o meio dela; plano em `docs/plano_fase269.md` |
| 270 — Corvos no campo (nossa) | **feita em 02/11/2026**, primeira do roteiro corvo, dedaleira e girassol (Fases 270 a 274): corvos pretos bicando a terra nos vãos entre as fileiras dos campos recém-plantados, indo embora quando a plantação cresce; plano em `docs/plano_fase270.md` |
| 271 — Dedaleiras (nossa) | **feita em 02/11/2026**: touceiras de dedaleira com as hastes altas de sinos roxos e rosados na beira da mata das ilhas temperadas, balançando com o vento; plano em `docs/plano_fase271.md` |
| 272 — Anel de cogumelos (nossa) | **feita em 02/11/2026**: uma roda de cogumelos claros de chapéu redondo no capim aberto das ilhas temperadas, de vez em quando; plano em `docs/plano_fase272.md` |
| 273 — Andorinhas no fio (nossa) | **feita em 02/11/2026**: filas de andorinhas de costas azuis e garganta ferrugem pousadas no meio dos fios dos postes das usinas, olhando para um lado e para o outro, de dia; plano em `docs/plano_fase273.md` |
| 274 — Girassóis (nossa) | **feita em 02/11/2026**, a última do roteiro corvo, dedaleira e girassol: touceiras de girassóis altos de flor amarela encostadas nas casas das ilhas temperadas, balançando com o vento; plano em `docs/plano_fase274.md` |
| 275 — Abeto em camadas (nossa) | **feita em 02/11/2026**, primeira do roteiro da mata no jeito do Anno (Fases 275 a 279): o abeto-vermelho, um cone escuro de camadas de galhos até perto do chão, vira a conífera da mata (o pinheiro fica em parte, mais no alto), e a beira da mata deixa de ser uma cerca de troncos; plano em `docs/plano_fase275.md` |
| 276 — Copas na medida (nossa) | **feita em 02/11/2026**: copas ~35% mais estreitas e uma árvore por célula em parte das células da mata temperada (mais no miolo, menos na beira): cada árvore se lê, com o chão e a sombra entre elas; 17.249 árvores desenhadas em vez de 28.830 e a GPU 0,5 ms mais leve; plano em `docs/plano_fase276.md` |
| 277 — Bétula (nossa) | **feita em 02/11/2026**: a bétula de tronco branco com manchas pretas e copa leve de massas soltas entre as folhosas, mais na beira da mata e na terra baixa das ilhas temperadas; plano em `docs/plano_fase277.md` |
| 278 — Orla da mata (nossa) | **feita em 02/11/2026**: abetos novos e arbustos de folhosa na beira de cada mata das ilhas temperadas, do lado do campo: a mata desce em degrau e cobre o pé dos troncos; plano em `docs/plano_fase278.md` |
| 279 — Folhas recortadas (nossa) | **feita em 02/11/2026**, a última do roteiro da mata: de perto, as copas viram cachos de folhas com volume e o contorno recortado, num shader só das árvores; de longe, iguais; plano em `docs/plano_fase279.md` |
| 280 — Mar fundo (nossa) | **feita em 02/11/2026**, primeira do roteiro do mar e do rio (Fases 280 a 284): o mar das ilhas temperadas sai do azul-elétrico para um azul-petróleo profundo, com a faixa turquesa da costa mais estreita; o das tropicais segue turquesa; plano em `docs/plano_fase280.md` |
| 281 — Rebentação fina (nossa) | **feita em 02/11/2026**: a faixa branca larga da praia vira a linha fina de espuma colada na areia e nas pedras, com as ondas chegando em linhas quebradas; plano em `docs/plano_fase281.md` |
| 282 — Água de noite (nossa) | **feita em 02/11/2026**: de noite o mar fica azul-escuro e a faixa da costa só pega a lua; acabou o halo ciano aceso em volta das ilhas; plano em `docs/plano_fase282.md` |
| 283 — Rio escuro (nossa) | **feita em 02/11/2026**: os rios deixam de ser espuma branca de margem a margem e viram água calma e escura; a margem baixa dos rios das ilhas temperadas vira cascalho cinza; plano em `docs/plano_fase283.md` |
| 284 — Marulho (nossa) | **feita em 02/11/2026**, a última do roteiro do mar e do rio: o mar aberto ganha a ondulação larga que se lê de longe, com o reflexo do céu ondulando, andando com o vento; plano em `docs/plano_fase284.md` |
| 285 — Manchas do prado (nossa) | **feita em 02/11/2026**, primeira do roteiro do prado (Fases 285 a 289): o capim deixa de ser de um verde só e ganha manchas de capim alto escuro e de capim baixo claro, de alguns metros; plano em `docs/plano_fase285.md` |
| 286 — Tapete de capim (nossa) | **feita em 02/11/2026**: perto da câmera o prado vira um tapete de folhas de capim, mais altas e escuras nas manchas de capim alto, balançando com o vento e sumindo aos poucos com a distância; plano em `docs/plano_fase286.md` |
| 287 — Flores miúdas (nossa) | **feita em 02/11/2026**: pontinhos de flor brancos e amarelos no capim, mais nos prados de flor e no capim baixo, no chão e nos tufos do tapete; plano em `docs/plano_fase287.md` |
| 288 — Papoulas soltas (nossa) | **feita em 02/11/2026**: os canteiros de papoulas deixam de parecer plantados em grade: touceiras soltas, de tamanhos diferentes, mais juntas no meio do canteiro e menores na borda; plano em `docs/plano_fase288.md` |
| 289 — Beira do barranco (nossa) | **feita em 02/11/2026**, a última do roteiro do prado: na beira de cima dos barrancos o capim acaba em trechos de terra escura com pedras e raízes, em vez de virar rocha de uma vez; plano em `docs/plano_fase289.md` |
| 290 — Estratos na rocha (nossa) | **feita em 02/11/2026**, primeira do roteiro da rocha e da costa (Fases 290 a 294): as falésias, os barrancos e as pedras ganham camadas de rocha onduladas com o ressalto claro e a sombra embaixo, e sulcos descendo; plano em `docs/plano_fase290.md` |
| 291 — Musgo nas saliências (nossa) | **feita em 02/11/2026**: manchas de musgo e capim nas partes planas e nos ressaltos da rocha, mais no lado da sombra, e nada na pedra molhada da maré; plano em `docs/plano_fase291.md` |
| 292 — Praia de seixos (nossa) | **feita em 02/11/2026**: nas ilhas temperadas, trechos da praia junto das pedras viram seixos cinzentos e redondos, escuros e brilhantes na beira da água; plano em `docs/plano_fase292.md` |
| 293 — Espuma nas pedras (nossa) | **feita em 02/11/2026**: volta a linha fina de espuma em volta do que entra na água longe da costa (pedras, estacas, boias, degraus do cais), sem reabrir a faixa branca da praia; plano em `docs/plano_fase293.md` |
| 294 — Abetos na rocha (nossa) | **feita em 02/11/2026**, a última do roteiro da rocha e da costa: abetos pequenos em camadas presos nas encostas íngremes e nas falésias das ilhas temperadas; plano em `docs/plano_fase294.md` |
| 295 — Espuma em trechos (nossa) | **feita em 02/11/2026**, primeira do roteiro mar e costa II (Fases 295 a 299): a linha branca contínua que corria solta no mar, paralela à praia, vira trechos curtos de espuma que mudam a cada onda; junto da areia a espuma segue inteira; plano em `docs/plano_fase295.md` |
| 296 — Água picada de perto (nossa) | **feita em 02/11/2026**: de perto, a água ganha a ondulação miúda e cruzada que quebra o reflexo do céu, mais forte com o vento; de longe nada muda; plano em `docs/plano_fase296.md` |
| 297 — Fiapos de espuma nas pedras (nossa) | **feita em 02/11/2026**: a espuma que bate nas pedras e nas falésias sai levada pelo vento em fiapos compridos e rendados, do lado de baixo do vento; plano em `docs/plano_fase297.md` |
| 298 — Mar escuro de longe (nossa) | **feita em 02/11/2026**: o mar aberto escurece para o azul-marinho com a distância e reflete menos o céu, mais visível de cima; plano em `docs/plano_fase298.md` |
| 299 — Fundo à vista no raso (nossa) | **feita em 02/11/2026**, a última do roteiro mar e costa II: nas ilhas temperadas, a água rasa fica mais clara e o fundo aparece, com manchas de alga, pedrinhas e a areia ondulada; plano em `docs/plano_fase299.md` |
| 300 — Telhas gastas (nossa) | **feita em 02/11/2026**, primeira do roteiro telhado gasto e chão de vila (Fases 300 a 304): cada telhado de telha com o seu tom, umas telhas trocadas mais claras, manchas de musgo e a sujeira escorrida; plano em `docs/plano_fase300.md` |

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
