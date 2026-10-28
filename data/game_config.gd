class_name GameConfig
extends Resource
## Todas as constantes ajustáveis do jogo. Nenhum número de regra mora no código:
## o valor padrão fica em res://data/game_config.tres e os sistemas leem daqui.

const DEFAULT_PATH := "res://data/game_config.tres"

static var _default: GameConfig

@export_group("Tempo")
## Ticks de simulação por segundo de jogo (5 = um tick a cada 200 ms).
@export var ticks_per_second: int = 5
## Teto de ticks num quadro; o excedente é descartado para o jogo não entrar em espiral.
@export var max_ticks_per_frame: int = 20
## Velocidades disponíveis além da pausa, em múltiplos do tempo real.
@export var game_speeds: PackedFloat32Array = PackedFloat32Array([1.0, 2.0, 4.0])
## Duração de um dia (só visual) em minutos reais a 1x.
@export var day_length_real_minutes: float = 24.0
## Hora em que o jogo novo começa.
@export var day_start_hour: float = 7.0

@export_group("Céu")
## Onde e quando o céu do Sky3D é calculado: latitude da Europa industrial fictícia e um dia de
## lua cheia em abril (sem estações no jogo base): o sol nasce às 5h25 e se põe às 18h40, e a lua
## fica no céu das 19h às 4h, para a noite não ser um breu.
@export var sky_latitude_deg: float = 45.0
@export var sky_month: int = 4
@export var sky_day: int = 14
@export var sky_year: int = 1840
## Nascer e pôr do sol nesse dia e lugar (conferidos no Sky3D): as luzes acendem em volta deles.
@export var sunrise_hour: float = 5.42
@export var sunset_hour: float = 18.67
## Meia duração da transição das luzes (janelas, luzes de área) em volta do nascer e do pôr do sol.
@export var twilight_hours: float = 0.6
## Distância máxima da sombra do sol, em metros.
@export var sun_shadow_distance_m: float = 400.0
## Luz ambiente que não vem do céu: impede a cidade de sumir no escuro à noite e no fim de tarde.
@export var ambient_fill_color: Color = Color(0.55, 0.6, 0.72)
@export var ambient_fill_energy: float = 1.0
## Parte da luz ambiente que vem do céu, de dia e de noite (o resto é ambient_fill).
@export var sky_ambient_share_day: float = 0.6
@export var sky_ambient_share_night: float = 0.25
@export var moon_light_energy: float = 0.7
## Neblina da atmosfera do Sky3D: densidade e distância onde começa.
@export var sky_fog_density: float = 0.0002
@export var sky_fog_start_m: float = 60.0

@export_group("Economia")
@export var starting_money: int = 50000
## Abaixo deste saldo, construir fica bloqueado.
@export var min_balance_to_build: int = -10000
## Dificuldade do jogo novo (fácil, normal, difícil): multiplica o dinheiro inicial e o limite de
## saldo negativo. A normal é a da especificação.
@export var difficulty_money_factors: PackedFloat32Array = PackedFloat32Array([2.0, 1.0, 0.5])
@export var difficulty_debt_factors: PackedFloat32Array = PackedFloat32Array([2.0, 1.0, 0.5])
@export var default_difficulty: int = 1
## Bônus de imposto quando duas ou mais opções atendem a mesma categoria.
@export var extra_need_option_tax_bonus: float = 0.10
@export var happiness_tax_multiplier_min: float = 0.5
@export var happiness_tax_multiplier_max: float = 1.5
## Felicidade abaixo da qual a casa para de pagar imposto e protesta.
@export var protest_happiness_threshold: int = 20
@export var residents_lost_per_minute_on_shortage: int = 1
## Fração da manutenção cobrada com o prédio pausado.
@export var paused_upkeep_factor: float = 0.5
## Fábrica ociosa (Fase 28): produção não pausada abaixo desta produtividade média paga a manutenção inteira por
## pouco; a dica do saldo soma o que elas custam e o painel avisa (pausada, paga paused_upkeep_factor).
@export var idle_productivity: float = 0.5
@export var trader_price_variation: float = 0.10
## Carga do navio inicial (Fase 6): descarregada no estoque ao construir o primeiro entreposto.
## Sem navio inicial (starting_ship vazio), vai direto para o estoque da ilha principal.
@export var starting_materials: Dictionary[StringName, int] = {&"planks": 40}
@export var road_cost_per_cell: int = 5
## Nível de imposto por classe (baixo, normal, alto): multiplicador e efeito na felicidade.
@export var tax_level_multipliers: PackedFloat32Array = PackedFloat32Array([0.75, 1.0, 1.4])
@export var tax_level_happiness: PackedFloat32Array = PackedFloat32Array([10.0, 0.0, -20.0])

@export_group("População")
## Fração da casa ocupada mesmo sem nenhuma necessidade atendida (dá partida à economia).
@export var house_base_residents_fraction: float = 0.2
@export var residents_arrival_per_minute: float = 4.0
## Atendimento a partir do qual a categoria conta como coberta (verde) e como parcial (amarela).
@export var need_met_threshold: float = 0.9
@export var need_partial_threshold: float = 0.5
## Constante de tempo da média do atendimento das necessidades.
@export var supply_smoothing_seconds: float = 30.0
@export var happiness_base: float = 50.0
@export var happiness_per_luxury: float = 25.0
@export var happiness_shortage_penalty: float = 40.0
@export var happiness_pollution_penalty: float = 30.0
## Felicidade da casa com beleza 1 (Fase 16): a beleza vai de 0 a 1 e soma até isto.
@export var happiness_per_beauty: float = 12.0
@export var happiness_change_per_minute: float = 20.0
## Constante de tempo da produtividade mostrada no painel do prédio.
@export var productivity_smoothing_seconds: float = 20.0
## As casas são avaliadas em grupos alternados, um grupo por tick (10 = cada casa uma vez a
## cada 2 s, com o tempo de 10 ticks). Moradores e felicidade mudam por minuto: não precisam de
## todo tick, e assim o custo da população cabe no orçamento do tick.
@export var house_update_groups: int = 10
## Cada quantos ticks as metas guiadas são conferidas (5 = uma vez por segundo de jogo).
@export var goal_check_ticks: int = 5
## Patamares de população total que liberam ilhas, navios e regras.
@export var population_milestones: PackedInt32Array = PackedInt32Array([100, 500, 1000, 2500, 5000, 10000])

@export_group("Produção e logística")
## Capacidade de cada buffer de entrada e de saída de um prédio, em toneladas.
@export var building_buffer_t: int = 4
## Capacidade inicial do estoque da ilha por bem, em toneladas.
@export var island_storage_capacity_t: int = 50
@export var carts_per_building: int = 1
@export var cart_capacity_t: int = 2
## Velocidade da carroça na estrada de terra, em células por segundo de jogo.
@export var cart_speed_cells_per_s: float = 2.0
## Tempo na rampa por tonelada carregada ou descarregada.
@export var cart_seconds_per_ton: float = 2.0
## Só para testes e ferramentas: a produção vai e vem do estoque sem carroça e sem entreposto
## (o transporte provisório da Fase 2). O jogo usa sempre as carroças.
@export var instant_logistics: bool = false
## Distância máxima, por estrada, entre um prédio e um armazém.
@export var logistics_range_cells: int = 40
## Raio dos serviços (mercado, taverna, igreja, escola), medido por estrada.
@export var service_radius_cells: int = 25
@export var lumberjack_min_trees: int = 20
## Fábrica eletrificada (Fase 11): fração somada à velocidade enquanto uma usina no raio produz.
@export var electricity_bonus: float = 0.5
## Especialistas (Fase 11): quantos o comerciante oferece a cada volta e o teto de contratados.
@export var specialist_offers: int = 3
@export var max_specialists: int = 10

@export_group("Navios e comércio")
## Navio com que o jogo começa, ancorado na ilha principal (vazio = nenhum: testes da economia).
@export var starting_ship: StringName = &"merchant_ship"
## Lado da célula da carta náutica (a grade em que os navios acham caminho), em metros.
@export var sea_chart_cell_m: float = 8.0
## Mar além das ilhas que entra na carta, em metros.
@export var sea_margin_m: float = 200.0
## Profundidade mínima para navegar: o fundo precisa estar abaixo disto (metros, negativo).
@export var ship_min_depth_m: float = -1.5
## Distância máxima entre o entreposto ou píer e o ponto de atracação na água navegável.
@export var berth_search_m: float = 80.0
## Tempo no cais por tonelada carregada ou descarregada.
@export var ship_seconds_per_ton: float = 0.5
## Tempo de içar velas antes de zarpar, em segundos de jogo. É nele que o caminho no mar é
## calculado em outra thread; o navio sai sempre ao fim dele (com o caminho pronto, esperando se
## preciso), então a simulação não depende de quanto a thread demorou.
@export var ship_cast_off_seconds: float = 1.0
## Navios e ilhas com entreposto permitidos por marco de população atingido: o índice é o
## número de marcos (0 = nenhum; population_milestones tem os patamares).
@export var ships_by_milestone: PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 6, 8])
@export var islands_by_milestone: PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 7, 9])

@export_group("Eventos e encomendas")
## Eventos (Fase 11): o primeiro sai depois de event_first_after_s de jogo e os seguintes a cada
## event_interval_s, com até event_jitter_s a mais ou a menos (sorteado pela semente). No máximo
## max_active_events ao mesmo tempo.
@export var event_first_after_s: float = 900.0
@export var event_interval_s: float = 900.0
@export var event_jitter_s: float = 300.0
@export var max_active_events: int = 2
## Encomendas (Fase 11): a primeira é oferecida depois de mission_first_after_s de jogo com
## entreposto, as seguintes a cada mission_interval_s; a oferta espera mission_offer_s pela resposta.
## No máximo max_open_missions (oferecidas e aceitas) ao mesmo tempo.
@export var mission_first_after_s: float = 600.0
@export var mission_interval_s: float = 720.0
@export var mission_offer_s: float = 300.0
@export var max_open_missions: int = 2
## Eventos e encomendas são conferidos a cada tantos ticks.
@export var events_check_ticks: int = 5
## Jornal (Fase 63): a primeira edição sai depois de newspaper_first_after_s de jogo e as seguintes a cada
## newspaper_interval_s; a propaganda que troca a manchete da edição custa newspaper_propaganda_cost moedas.
@export var newspaper_first_after_s: float = 300.0
@export var newspaper_interval_s: float = 600.0
@export var newspaper_propaganda_cost: int = 2500

@export_group("Estaleiro")
## O navio encomendado ao estaleiro custa esta fração do preço do entreposto (moedas e materiais,
## arredondados para cima); cancelar devolve shipyard_cancel_refund das moedas pagas. Navio parado num
## porto de ilha com estaleiro se repara shipyard_repair_factor vezes mais depressa.
@export var shipyard_cost_factor: float = 0.75
@export var shipyard_cancel_refund: float = 0.5
@export var shipyard_repair_factor: float = 2.0

@export_group("Objetivo")
## Objetivos oferecidos no jogo novo (Fase 12), além da partida livre: tipo (GoalDef.Kind), alvo e
## quantidade, na mesma posição das três listas. Prazos oferecidos, em minutos de jogo (0 = sem prazo).
@export var victory_kinds: PackedInt32Array = PackedInt32Array([1, 1, 6, 5])
@export var victory_targets: Array[StringName] = [&"artisans", &"investors", &"", &""]
@export var victory_amounts: PackedInt32Array = PackedInt32Array([500, 100, 250000, 4])
@export var deadline_choices_min: PackedFloat32Array = PackedFloat32Array([0.0, 120.0, 240.0, 360.0])

@export_group("Riscos")
## Incêndio e doença (seção 8, opcionais): conferidos a cada risk_check_ticks. Cada prédio que pode
## arder tem fire_chance_per_hour (por hora de jogo, vezes o fire_risk do prédio) de pegar fogo; no
## raio de um quartel de bombeiros, só fire_protected_factor disso. O fogo protegido se apaga em
## fire_extinguish_s; o desprotegido queima fire_burnout_s e o prédio se perde.
@export var risk_check_ticks: int = 25
@export var fire_after_milestone: int = 1
@export var fire_chance_per_hour: float = 0.015
@export var fire_protected_factor: float = 0.25
@export var fire_extinguish_s: float = 20.0
@export var fire_burnout_s: float = 90.0
@export var max_active_fires: int = 3
## Doença: cada casa tem disease_chance_per_hour de adoecer (mais com a poluição, até
## 1 + disease_pollution_factor); no raio de um hospital, só disease_protected_factor disso. A casa
## doente perde disease_residents_lost_per_min moradores e disease_happiness_penalty de felicidade;
## sara em disease_cure_s com hospital, em disease_duration_s sem.
@export var disease_after_milestone: int = 2
@export var disease_chance_per_hour: float = 0.015
@export var disease_pollution_factor: float = 2.0
@export var disease_protected_factor: float = 0.25
@export var disease_cure_s: float = 45.0
@export var disease_duration_s: float = 240.0
@export var disease_residents_lost_per_min: float = 2.0
@export var disease_happiness_penalty: float = 25.0
@export var max_active_outbreaks: int = 3

@export_group("Rivais")
## Relação para onde cada personalidade volta sozinha (pacífica, ambiciosa, agressiva).
@export var rival_base_relation: PackedFloat32Array = PackedFloat32Array([20.0, 0.0, -20.0])
## Fração das ilhas além da principal que as rivais podem tomar juntas.
@export var rival_island_share: float = 0.5
## Ilha tropical só entra na lista das rivais depois de tanto tempo de jogo.
@export var rival_tropical_after_s: float = 3600.0
## Moradores com que a colônia rival começa, teto por célula da ilha e moradores por casa desenhada.
@export var rival_founding_population: float = 40.0
@export var rival_residents_per_cell: float = 0.04
@export var rival_residents_per_house: float = 25.0
@export var rival_max_houses: int = 40
## Tempo que o navio da rival fica parado em cada ponta da viagem.
@export var rival_ship_dwell_s: float = 30.0
## Quanto a relação anda por minuto de volta à da personalidade.
@export var rival_relation_drift_per_min: float = 1.0
## Diplomacia: relação mínima para o acordo comercial, renda dele por morador da rival por minuto,
## presente (custo, ganho, espera), paz (relação mínima, custo), quanto o jogador perde ao colonizar,
## desfazer o acordo e declarar guerra; a agressiva declara guerra abaixo de rival_war_relation e a
## não agressiva faz as pazes sozinha acima de rival_auto_peace_relation. Postura não muda de novo
## antes de rival_stance_cooldown_s.
@export var rival_trade_relation: float = 30.0
@export var rival_trade_income_per_resident: float = 0.3
@export var rival_gift_money: int = 2000
@export var rival_gift_relation: float = 15.0
@export var rival_gift_cooldown_s: float = 300.0
@export var rival_peace_relation: float = -40.0
@export var rival_peace_money: int = 5000
@export var rival_colony_penalty: float = 8.0
@export var rival_cancel_penalty: float = 15.0
@export var rival_war_penalty: float = 40.0
@export var rival_war_relation: float = -60.0
@export var rival_auto_peace_relation: float = -10.0
@export var rival_stance_cooldown_s: float = 300.0
## Combate naval: o casco se repara tanto por segundo parado num porto do dono; em guerra a rival arma
## até rival_warships fragatas (o navio rival_warship), uma a cada rival_warship_build_s, que param
## rival_warship_dwell_s em cada ponta; cada uma afundada melhora a relação em rival_loss_relation.
@export var ship_repair_per_s: float = 2.0
@export var rival_warship: StringName = &"frigate"
@export var rival_warships: int = 2
@export var rival_warship_build_s: float = 180.0
@export var rival_warship_dwell_s: float = 90.0
@export var rival_loss_relation: float = 15.0

@export_group("Ilhas")
## Área da ilha plana (testes e saves de antes da Fase 5), em células.
@export var main_island_size_cells: Vector2i = Vector2i(250, 250)

@export_group("Arquipélago")
## Lado de cada ilha em células, a principal primeiro (seção 7: ~250, ~150 e ~80). O arquipélago
## usa as primeiras da lista, quantas o tamanho escolhido pedir (archipelago_island_counts).
@export var island_sizes_cells: PackedInt32Array = PackedInt32Array([250, 150, 150, 80, 80, 150, 80, 150, 80])
## Ilhas no arquipélago (com a principal) por tamanho escolhido no jogo novo: pequeno, médio e
## grande (seção 7: de 4 a 8 ilhas menores).
@export var archipelago_island_counts: PackedInt32Array = PackedInt32Array([5, 7, 9])
## Tamanho usado quando ninguém escolhe (testes, ferramentas, `-- --novo-jogo`).
@export var default_archipelago_size: int = 0
## Fase 45: o gerador dos jogos novos (1, o de sempre; 2, as ilhas orgânicas; desde a Fase 52, a pedido do dono, 3: as
## ilhas alongadas com enseadas e falésias). Os saves refazem o terreno na versão que gravaram.
@export var new_game_terrain_version: int = 3
@export var main_island_profile: StringName = &"main_island"
## Perfis sorteados (pela semente) para as outras ilhas.
@export var other_island_profiles: Array[StringName] = [&"farmland", &"highlands", &"woodland", &"reef"]
## Segunda região climática (Fase 11): ilhas tropicais a leste, longe das temperadas, cada uma
## numa destas regiões (com um mar aberto no meio). Saem da semente à parte, depois das
## temperadas, e são as mesmas em qualquer tamanho de arquipélago.
@export var tropical_island_sizes_cells: PackedInt32Array = PackedInt32Array([150, 120, 80])
@export var tropical_regions: Array[Vector2i] = [Vector2i(3, -1), Vector2i(3, 0), Vector2i(3, 1)]
## Perfis sorteados (pela semente) para as ilhas tropicais.
@export var tropical_island_profiles: Array[StringName] = [&"cane_coast", &"coffee_hills", &"tobacco_valley"]
## Marcos de população atingidos que liberam colonizar ilha tropical (3 = o de 1.000 moradores).
@export var tropical_milestone: int = 3
## Lado da região do terreno de cada ilha, em metros (uma ilha por região).
@export var terrain_region_m: float = 512.0
## Patamares planos, em metros acima do mar: é neles que se constrói. Entre um e outro, encosta.
@export var terrace_levels_m: PackedFloat32Array = PackedFloat32Array([1.2, 4.0, 7.5, 12.0, 17.0])
## Fração de cada degrau que fica plana (o resto é a encosta até o patamar de cima).
@export var terrace_flat_fraction: float = 0.7
@export var sea_floor_m: float = -6.0
@export var river_bed_m: float = -1.2
## Fundo do mar desenhado (só visual; a simulação usa sea_floor_m): desce da costa até
## deep_sea_floor_m nesta distância, e na borda da região já está lá, sem degrau contra o mar aberto.
@export var sea_shelf_width_m: float = 60.0
@export var deep_sea_floor_m: float = -40.0
## Largura do rio em células e até onde ele entra na ilha (em células).
@export var river_width_cells: int = 2
@export var river_length_cells: int = 45
## Diferença máxima de altura dentro de uma célula de estrada (acima disso é barranco).
@export var max_road_relief_m: float = 2.0
@export var max_trees_per_cell: int = 4
## Raio (em células) em volta do lenhador onde as árvores contam.
@export var lumberjack_radius_cells: int = 5
## Lado da mancha de jazida, em células (cabe uma mina 4×4 com folga).
@export var deposit_spot_cells: int = 6

@export_group("Construção")
@export var cell_size_m: float = 2.0
## Diferença de altura máxima dentro da área de um prédio.
@export var max_build_height_delta_m: float = 0.5
## Fração dos materiais devolvida ao demolir.
@export var demolish_refund: float = 0.5
## Fase 49: desfazer vale por este tempo de jogo depois da ação (s), com no máximo tantas ações guardadas.
@export var undo_window_s: float = 120.0
@export var undo_max_entries: int = 30
## Ganho de velocidade da estrada de paralelepípedo sobre a de terra.
@export var paved_road_speed_bonus: float = 0.5
## Paralelepípedo (Fase 8): moedas e tijolos por célula (os tijolos somam e arredondam para cima,
## e pagar terra por baixo não dá desconto) e a classe que o libera, como num prédio.
@export var paved_road_cost_per_cell: int = 10
@export var paved_road_bricks_per_cell: float = 0.5
@export var paved_road_unlock_tier: StringName = &"workers"
@export var paved_road_unlock_residents: int = 150

@export_group("Câmera")
@export var camera_min_distance_m: float = 12.0
@export var camera_max_distance_m: float = 420.0
@export var camera_start_distance_m: float = 110.0
## Inclinação, em graus abaixo do horizonte, com o zoom mais perto e mais longe.
@export var camera_pitch_near_deg: float = 28.0
@export var camera_pitch_far_deg: float = 70.0
## Velocidade do pan em frações da distância da câmera por segundo.
@export var camera_pan_speed: float = 1.2
## Quanto cada passo da roda aproxima ou afasta (0,15 = 15%).
@export var camera_zoom_step: float = 0.15
## Constante de tempo do zoom da roda indo até a distância-alvo (Fase 31).
@export var camera_zoom_seconds: float = 0.12
## Duração do giro de 90° do Q/E.
@export var camera_rotate_seconds: float = 0.25
@export var camera_free_rotate_deg_per_px: float = 0.3
## Constante de tempo da câmera indo até o prédio selecionado.
@export var camera_center_seconds: float = 0.15
@export var camera_edge_margin_px: int = 12
## Folga além da borda da ilha que a câmera ainda alcança.
@export var camera_bounds_margin_m: float = 60.0
@export var camera_min_height_m: float = 3.0

@export_group("Mundo vivo")
## Teto de pedestres visíveis (seção 9).
@export var max_visible_pedestrians: int = 2000
## Um pedestre na rua para cada tantos moradores (10 mil moradores → 2.000 pedestres).
@export var residents_per_pedestrian: float = 5.0
## Fração dos pedestres na rua a cada hora (0h a 23h); entre as horas, interpolado.
@export var pedestrian_activity_by_hour: PackedFloat32Array = PackedFloat32Array([
	0.08, 0.05, 0.05, 0.05, 0.08, 0.2, 0.5, 0.85, 0.95, 0.85, 0.8, 0.85,
	0.95, 0.9, 0.85, 0.85, 0.9, 1.0, 0.95, 0.75, 0.5, 0.3, 0.18, 0.12])
## Velocidade de caminhada, em metros por segundo de jogo.
@export var pedestrian_speed_m_s: float = 1.3
## Distância do meio da estrada até a calçada de cada lado.
@export var pedestrian_sidewalk_offset_m: float = 0.62
## Quanto tempo o pedestre fica conversando na porta do serviço (mínimo e máximo, s de jogo).
@export var pedestrian_service_seconds: Vector2 = Vector2(20.0, 60.0)
## Pausa na porta do trabalho e de casa antes da próxima perna (s de jogo).
@export var pedestrian_door_seconds: Vector2 = Vector2(2.0, 8.0)
## Quantos prédios de trabalho mais perto da casa entram no sorteio do pedestre.
@export var pedestrian_work_choices: int = 4
## Tempo de CPU por quadro para calcular rotas novas de pedestres; o resto fica para o próximo.
@export var pedestrian_route_budget_ms: float = 1.0
@export var pedestrian_shadows: bool = true
## Luzes de área (AreaLight3D) nas janelas dos prédios mais perto da câmera, à noite.
@export var night_area_lights: int = 12
## Acima desta distância da câmera, as luzes de área se apagam (as janelas continuam acesas).
@export var night_area_light_camera_distance_m: float = 160.0
@export var window_light_color: Color = Color(1.0, 0.72, 0.38)

@export_group("Clima")
## Clima só visual (seção 9, Fase 9), sorteado por dia a partir da semente da partida: chance de
## um dia nublado e de um dia com chuva (o resto é céu limpo), e de neblina de manhã.
@export var weather_cloudy_chance: float = 0.35
@export var weather_rain_chance: float = 0.2
@export var weather_mist_chance: float = 0.5
## Cobertura de nuvens (0 a 1) no céu limpo, no nublado e no meio da chuva.
@export var weather_clear_coverage: float = 0.35
@export var weather_cloudy_coverage: float = 0.7
@export var weather_rain_coverage: float = 0.95
## A chuva começa entre estas horas do dia, dura entre estas horas e leva rain_fade_hours para
## chegar e para parar; o chão seca em dry_hours depois.
@export var weather_rain_start_hours: Vector2 = Vector2(8.0, 18.0)
@export var weather_rain_duration_hours: Vector2 = Vector2(1.5, 5.0)
@export var weather_rain_fade_hours: float = 0.5
@export var weather_dry_hours: float = 2.0
## Neblina da manhã: cresce a partir de mist_start, é mais forte em mist_peak e some em mist_end.
@export var weather_mist_start_hour: float = 4.0
@export var weather_mist_peak_hour: float = 6.5
@export var weather_mist_end_hour: float = 9.5
## Densidade extra da neblina de distância e da volumétrica no auge da neblina e da chuva.
@export var weather_mist_fog_density: float = 0.0022
@export var weather_rain_fog_density: float = 0.0015
## Vento (Fase 22): força de 0 a 1 no dia limpo, no nublado e no meio da chuva; cada dia sorteia um
## fator dentro de day_factor; a direção vira até veer_rad para cada lado ao longo do dia; no auge da
## neblina a força cai em mist_calm.
@export var weather_wind_clear: float = 0.25
@export var weather_wind_cloudy: float = 0.45
@export var weather_wind_rain: float = 0.85
@export var weather_wind_day_factor: Vector2 = Vector2(0.7, 1.15)
@export var weather_wind_veer_rad: float = 0.5
@export var weather_wind_mist_calm: float = 0.8
## Gotas de chuva no nível mais alto, a caixa em volta da câmera e a velocidade de queda.
@export var rain_max_drops: int = 6000
@export var rain_box_m: Vector3 = Vector3(140.0, 60.0, 140.0)
@export var rain_fall_speed_m_s: float = 28.0

@export_group("Áudio")
## Música (seção 11): a cada tanto (s reais) o diretor decide o clima da música. Alerta depois de uma
## falta de bem há menos de alert_after_shortage_s ou com o saldo abaixo de zero; progresso depois de
## um marco ou meta há menos de progress_after_event_s; senão, calma. A troca leva fade_seconds.
@export var music_check_seconds: float = 5.0
@export var music_alert_after_shortage_s: float = 180.0
@export var music_progress_after_event_s: float = 240.0
@export var music_fade_seconds: float = 4.0
## Ambiente por zona: prédios contados num raio em volta do ponto que a câmera olha; cada zona chega
## ao volume cheio com estes prédios (porto, fábrica, campo, cidade).
@export var ambience_radius_m: float = 90.0
@export var ambience_full_counts: PackedFloat32Array = PackedFloat32Array([2.0, 4.0, 6.0, 14.0])
## O ambiente acompanha o zoom: cheio até near_m, mudo a partir de far_m (sobra o vento, que cresce).
@export var ambience_near_m: float = 40.0
@export var ambience_far_m: float = 320.0
@export var ambience_fade_per_second: float = 0.6
## Fábricas trabalhando com som posicional: no máximo work_voices ao mesmo tempo, as mais perto do
## ponto da câmera até work_sound_radius_m, cada uma batendo a cada work_sound_interval_s.
@export var work_voices: int = 6
@export var work_sound_radius_m: float = 70.0
@export var work_sound_interval_s: Vector2 = Vector2(1.5, 4.0)
## O mesmo efeito não toca de novo antes disto (s reais): construir 50 casas não faz 50 marteladas.
@export var sfx_cooldown_s: float = 0.12

@export_group("Salvar")
@export var autosave_interval_minutes: float = 10.0
@export var autosave_slots: int = 3

@export_group("Interface")
@export var ui_scale_min: float = 0.8
@export var ui_scale_max: float = 2.0
## Idiomas oferecidos, na ordem do menu. O primeiro é o padrão.
@export var supported_locales: PackedStringArray = PackedStringArray(["pt_BR", "en"])
## Gráficos históricos das estatísticas: uma amostra a cada tantos segundos de jogo, guardando as
## últimas history_samples (180 amostras de 60 s = as últimas 3 horas de jogo).
@export var history_interval_s: float = 60.0
@export var history_samples: int = 180
## Notificações: quanto tempo cada uma fica na tela (s reais) e quantas aparecem ao mesmo tempo.
@export var notice_seconds: float = 12.0
@export var notice_max_visible: int = 5
## Prédio parado só vira notificação depois de tanto tempo parado (s de jogo), para não avisar o
## intervalo normal entre um ciclo e outro.
@export var stopped_notice_after_s: float = 60.0
## Estoque cheio: avisa ao chegar nesta fração da capacidade e volta a avisar só depois de cair
## abaixo de storage_full_reset_fraction.
@export var storage_full_fraction: float = 0.98
@export var storage_full_reset_fraction: float = 0.85
## Cada quanto (s reais) a interface confere prédios parados, estoque e navios para notificar.
@export var notice_check_seconds: float = 1.0
## Escala da resolução 3D (FSR 2) oferecida nas opções.
@export var render_scale_min: float = 0.5

@export_group("Gráficos")
## Níveis de qualidade (seção 11), do mais leve ao mais pesado; as opções mostram nesta ordem.
@export var graphics_presets: Array[GraphicsPresetDef] = [
	preload("res://data/graphics/low.tres"), preload("res://data/graphics/medium.tres"),
	preload("res://data/graphics/high.tres"), preload("res://data/graphics/ultra.tres")]
## Nível de quem abre o jogo pela primeira vez (o alto, que é o da meta de desempenho).
@export var default_graphics_preset: int = 2
## Até onde telhados, chaminés e portas aparecem no nível alto (o nível multiplica).
@export var building_detail_range_m: float = 260.0
## Quanto tempo (s reais) o andaime e a poeira ficam na casa que subiu de classe.
@export var upgrade_scaffold_seconds: float = 6.0
## Fase 33: as linhas da grade de construção só aparecem até esta distância do cursor (some aos poucos nos últimos 45%).
@export var build_grid_radius_m: float = 30.0
## Fase 33: ícones de estado sobre os prédios. Até full_m da câmera aparece cada um; mais longe, os iguais no mesmo
## quadrado de cluster_m viram um só, que esmaece até min_alpha em fade_end_m.
@export var status_icon_full_m: float = 90.0
@export var status_icon_fade_end_m: float = 400.0
@export var status_icon_cluster_m: float = 48.0
@export var status_icon_min_alpha: float = 0.45
## Fase 34: até que distância da água o bake do terreno mede (o canal b satura ali), e até onde da câmera a grama e a
## floresta usam o hex-tiling (some aos poucos no último quinto; mais longe fica a macro-variação).
@export var terrain_water_distance_m: float = 64.0
@export var terrain_hex_distance_m: float = 220.0
## Fase 35: até onde (m) o campo de distância da costa mede, para cada lado da linha d'água.
@export var coast_field_max_m: float = 64.0
## Fase 55: em quantas partes de lado se divide o quadrado da malha que a linha d'água atravessa (1 desliga), e quanto
## (m) a altura curva pode sair da reta entre os cantos.
@export var terrain_coast_subdivisions: int = 3
@export var terrain_coast_refine_max_m: float = 0.8
## Fase 62: o quadrado seco com pelo menos este desnível (m) entre os cantos também se divide (0 desliga); fica acima de
## max_road_relief_m, então nenhuma célula onde se constrói muda. E a aspereza de rocha (m) dos pontos novos da falésia.
@export var terrain_cliff_refine_relief_m: float = 2.4
@export var terrain_cliff_rough_m: float = 0.35
## Fase 38: a estrada de terra pintada no terreno (desligada, volta o ladrilho), os pixels da máscara por célula e até
## onde (m da linha do meio) ela mede a distância.
@export var road_paint: bool = true
@export var road_mask_px_per_cell: int = 4
@export var road_mask_max_m: float = 1.6
## Até onde a fumaça das chaminés aparece no nível alto, e a força da fuligem no chão.
@export var smoke_visibility_range_m: float = 450.0
@export var soot_decal_alpha: float = 0.55
## Força dos efeitos do ambiente quando o nível os liga.
@export var ssao_intensity: float = 1.6
@export var glow_intensity: float = 0.5
@export var glow_bloom: float = 0.03
@export var glow_hdr_threshold: float = 1.1
@export var volumetric_fog_density: float = 0.0018
@export var volumetric_fog_length_m: float = 220.0
## Fase 37: com a "Cor de época" ligada, o branco e o contraste do AgX (6 a 8 é a faixa das cenas realistas).
@export var period_agx_white: float = 7.0
@export var period_agx_contrast: float = 1.1
## Efeito miniatura (tilt-shift): só com a câmera até esta distância; o desfoque longe começa em
## distância × far_factor e o de perto termina em distância × near_factor.
@export var tilt_shift_max_distance_m: float = 90.0
@export var tilt_shift_far_factor: float = 1.6
@export var tilt_shift_near_factor: float = 0.35
@export var tilt_shift_amount: float = 0.08

@export_group("Desempenho")
## Orçamento de um tick de simulação na carga do benchmark.
@export var tick_budget_ms: float = 4.0


## A configuração padrão do projeto, carregada uma vez.
static func get_default() -> GameConfig:
	if _default == null:
		_default = load(DEFAULT_PATH) as GameConfig
	return _default


## Dinheiro inicial e limite de saldo para construir na dificuldade dada.
func starting_money_for(difficulty: int) -> float:
	return starting_money * difficulty_money_factors[clampi(difficulty, 0, difficulty_money_factors.size() - 1)]


func min_balance_for(difficulty: int) -> float:
	return min_balance_to_build * difficulty_debt_factors[clampi(difficulty, 0, difficulty_debt_factors.size() - 1)]


## Número de ilhas (com a principal) do tamanho de arquipélago dado.
func island_count_for(archipelago_size: int) -> int:
	return mini(archipelago_island_counts[clampi(archipelago_size, 0, archipelago_island_counts.size() - 1)], island_sizes_cells.size())


## Segundos de jogo em ticks (arredondado).
func ticks_of(seconds: float) -> int:
	return roundi(seconds * ticks_per_second)


func tick_interval() -> float:
	return 1.0 / float(ticks_per_second)


## Segundos de jogo num dia. Como o dia é medido a 1x, coincide com os segundos reais.
func day_length_game_seconds() -> float:
	return day_length_real_minutes * 60.0


## Lista os valores inválidos. Vazia quando a configuração está boa.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if new_game_terrain_version not in ArchipelagoGenerator.VERSIONS:
		problems.append("new_game_terrain_version deve ser 1, 2 ou 3")
	problems.append_array(TerrainV2Params.get_default().validate())
	problems.append_array(TerrainV3Params.get_v3().validate())
	if ticks_per_second <= 0:
		problems.append("ticks_per_second deve ser maior que zero")
	if max_ticks_per_frame <= 0:
		problems.append("max_ticks_per_frame deve ser maior que zero")
	if game_speeds.is_empty():
		problems.append("game_speeds precisa de pelo menos uma velocidade")
	for speed: float in game_speeds:
		if speed <= 0.0:
			problems.append("game_speeds só aceita valores positivos (a pausa é separada)")
			break
	if day_length_real_minutes <= 0.0:
		problems.append("day_length_real_minutes deve ser maior que zero")
	if day_start_hour < 0.0 or day_start_hour >= 24.0:
		problems.append("day_start_hour fica entre 0 e 24")
	if sunrise_hour < 0.0 or sunrise_hour >= sunset_hour or sunset_hour >= 24.0:
		problems.append("sunrise_hour vem antes de sunset_hour, os dois entre 0 e 24")
	if pedestrian_activity_by_hour.size() != 24:
		problems.append("pedestrian_activity_by_hour tem um valor por hora (24)")
	if residents_per_pedestrian <= 0.0 or pedestrian_speed_m_s <= 0.0:
		problems.append("residents_per_pedestrian e pedestrian_speed_m_s devem ser maiores que zero")
	if max_visible_pedestrians < 0 or night_area_lights < 0:
		problems.append("max_visible_pedestrians e night_area_lights não podem ser negativos")
	if happiness_tax_multiplier_min > happiness_tax_multiplier_max:
		problems.append("happiness_tax_multiplier_min passa do máximo")
	if ui_scale_min <= 0.0 or ui_scale_min > ui_scale_max:
		problems.append("ui_scale_min deve ser positivo e não passar de ui_scale_max")
	if supported_locales.is_empty():
		problems.append("supported_locales precisa de pelo menos um idioma")
	if main_island_size_cells.x <= 0 or main_island_size_cells.y <= 0:
		problems.append("main_island_size_cells deve ser positivo")
	if island_sizes_cells.is_empty() or island_sizes_cells.size() > ArchipelagoGenerator.REGION_SLOTS.size() + 1 or other_island_profiles.is_empty():
		problems.append("island_sizes_cells: a principal e no máximo uma ilha por região vizinha (8); other_island_profiles não fica vazio")
	if archipelago_island_counts.is_empty() or default_archipelago_size < 0 or default_archipelago_size >= archipelago_island_counts.size():
		problems.append("archipelago_island_counts precisa de um valor por tamanho, e default_archipelago_size é um deles")
	for count: int in archipelago_island_counts:
		if count < 1 or count > island_sizes_cells.size():
			problems.append("archipelago_island_counts: entre 1 e o número de ilhas de island_sizes_cells")
			break
	if tropical_island_sizes_cells.size() > tropical_regions.size() or (not tropical_island_sizes_cells.is_empty() and tropical_island_profiles.is_empty()):
		problems.append("tropical_island_sizes_cells: no máximo uma ilha por região de tropical_regions, e tropical_island_profiles não fica vazio")
	for region: Vector2i in tropical_regions:
		if region == Vector2i.ZERO or ArchipelagoGenerator.REGION_SLOTS.has(region):
			problems.append("tropical_regions não usa a região da principal nem as vizinhas (as das temperadas)")
			break
	if event_first_after_s <= 0.0 or event_interval_s <= 0.0 or event_jitter_s < 0.0 or event_jitter_s >= event_interval_s:
		problems.append("eventos: primeiro e intervalo positivos, variação menor que o intervalo")
	if mission_first_after_s <= 0.0 or mission_interval_s <= 0.0 or mission_offer_s <= 0.0:
		problems.append("encomendas: tempos positivos")
	if max_active_events < 1 or max_open_missions < 1 or events_check_ticks < 1:
		problems.append("max_active_events, max_open_missions e events_check_ticks pelo menos 1")
	if newspaper_first_after_s <= 0.0 or newspaper_interval_s <= 0.0 or newspaper_propaganda_cost < 0:
		problems.append("jornal: tempos positivos e propaganda não negativa")
	if rival_base_relation.size() != 3 or rival_island_share < 0.0 or rival_island_share > 1.0 or rival_residents_per_cell <= 0.0 \
			or rival_residents_per_house <= 0.0 or rival_max_houses < 2:
		problems.append("rivais: três relações de base, fração entre 0 e 1, teto e casas positivos")
	if rival_war_relation >= rival_auto_peace_relation or rival_peace_relation > rival_auto_peace_relation:
		problems.append("rivais: guerra abaixo da paz sozinha, paz pedida até a paz sozinha")
	if tropical_milestone < 0 or tropical_milestone > population_milestones.size():
		problems.append("tropical_milestone entre 0 e o número de marcos de population_milestones")
	if difficulty_money_factors.size() != 3 or difficulty_debt_factors.size() != 3 or default_difficulty < 0 or default_difficulty > 2:
		problems.append("as dificuldades são três: fácil, normal e difícil")
	if history_interval_s <= 0.0 or history_samples < 2:
		problems.append("history_interval_s positivo e history_samples de pelo menos 2")
	if notice_seconds <= 0.0 or notice_max_visible <= 0 or notice_check_seconds <= 0.0:
		problems.append("notice_seconds, notice_max_visible e notice_check_seconds devem ser maiores que zero")
	if storage_full_reset_fraction >= storage_full_fraction or storage_full_fraction > 1.0:
		problems.append("storage_full_reset_fraction fica abaixo de storage_full_fraction, que não passa de 1")
	for side: int in island_sizes_cells:
		if side * cell_size_m > terrain_region_m:
			problems.append("ilha de %d células não cabe numa região de %.0f m" % [side, terrain_region_m])
			break
	if terrace_levels_m.is_empty() or terrace_levels_m[0] <= 0.0:
		problems.append("terrace_levels_m começa acima do mar (> 0)")
	if sea_shelf_width_m <= 0.0 or deep_sea_floor_m >= sea_floor_m:
		problems.append("sea_shelf_width_m deve ser positivo e deep_sea_floor_m ficar abaixo de sea_floor_m")
	if graphics_presets.is_empty() or default_graphics_preset < 0 or default_graphics_preset >= graphics_presets.size():
		problems.append("graphics_presets não fica vazio e default_graphics_preset é um deles")
	for preset: GraphicsPresetDef in graphics_presets:
		problems.append_array(preset.validate())
	if cell_size_m <= 0.0:
		problems.append("cell_size_m deve ser maior que zero")
	if camera_min_distance_m <= 0.0 or camera_min_distance_m >= camera_max_distance_m:
		problems.append("camera_min_distance_m deve ser positivo e menor que camera_max_distance_m")
	if camera_rotate_seconds <= 0.0 or camera_center_seconds <= 0.0 or camera_zoom_seconds <= 0.0:
		problems.append("as durações da câmera devem ser maiores que zero")
	if build_grid_radius_m <= 0.0:
		problems.append("build_grid_radius_m deve ser maior que zero")
	if terrain_water_distance_m <= 0.0 or terrain_hex_distance_m <= 0.0 or coast_field_max_m <= 0.0:
		problems.append("terrain_water_distance_m, terrain_hex_distance_m e coast_field_max_m devem ser maiores que zero")
	if terrain_coast_subdivisions < 1 or terrain_coast_subdivisions > 8 or terrain_coast_refine_max_m < 0.0:
		problems.append("terrain_coast_subdivisions deve ficar entre 1 e 8 e terrain_coast_refine_max_m não pode ser negativo")
	if terrain_cliff_rough_m < 0.0 or (terrain_cliff_refine_relief_m > 0.0 and terrain_cliff_refine_relief_m <= max_road_relief_m):
		problems.append("terrain_cliff_rough_m não pode ser negativo e terrain_cliff_refine_relief_m (se ligado) deve passar de max_road_relief_m")
	if road_mask_px_per_cell < 1 or road_mask_max_m <= 0.0:
		problems.append("road_mask_px_per_cell deve ser pelo menos 1 e road_mask_max_m maior que zero")
	if status_icon_full_m <= 0.0 or status_icon_fade_end_m <= status_icon_full_m or status_icon_cluster_m <= 0.0 \
			or status_icon_min_alpha <= 0.0 or status_icon_min_alpha > 1.0:
		problems.append("ícones de estado: 0 < full_m < fade_end_m, cluster_m > 0 e min_alpha em (0, 1]")
	if tax_level_multipliers.size() != 3 or tax_level_happiness.size() != 3:
		problems.append("os níveis de imposto são três: baixo, normal e alto")
	if need_partial_threshold > need_met_threshold:
		problems.append("need_partial_threshold passa de need_met_threshold")
	if electricity_bonus < 0.0:
		problems.append("electricity_bonus não pode ser negativo")
	if specialist_offers < 0 or max_specialists < 0:
		problems.append("specialist_offers e max_specialists não podem ser negativos")
	if supply_smoothing_seconds <= 0.0 or productivity_smoothing_seconds <= 0.0:
		problems.append("as constantes de tempo das médias devem ser maiores que zero")
	if autosave_slots <= 0:
		problems.append("autosave_slots deve ser maior que zero")
	if ships_by_milestone.size() != population_milestones.size() + 1 or islands_by_milestone.size() != population_milestones.size() + 1:
		problems.append("ships_by_milestone e islands_by_milestone têm um valor a mais que population_milestones")
	if sea_chart_cell_m <= 0.0 or ship_min_depth_m >= 0.0 or ship_seconds_per_ton < 0.0:
		problems.append("sea_chart_cell_m positivo, ship_min_depth_m abaixo do mar e ship_seconds_per_ton não negativo")
	for fraction: float in [demolish_refund, paused_upkeep_factor, trader_price_variation, idle_productivity]:
		if fraction < 0.0 or fraction > 1.0:
			problems.append("frações (devolução, manutenção pausada, variação de preço) ficam entre 0 e 1")
			break
	if risk_check_ticks <= 0 or fire_extinguish_s <= 0.0 or fire_burnout_s <= 0.0 or disease_cure_s <= 0.0 or disease_duration_s <= 0.0:
		problems.append("risk_check_ticks e as durações do fogo e da doença devem ser positivos")
	if fire_chance_per_hour < 0.0 or disease_chance_per_hour < 0.0 or fire_protected_factor < 0.0 or fire_protected_factor > 1.0 \
			or disease_protected_factor < 0.0 or disease_protected_factor > 1.0:
		problems.append("chances dos riscos não negativas e fatores de proteção entre 0 e 1")
	if max_active_fires < 0 or max_active_outbreaks < 0:
		problems.append("max_active_fires e max_active_outbreaks não podem ser negativos")
	if shipyard_cost_factor <= 0.0 or shipyard_cancel_refund < 0.0 or shipyard_cancel_refund > 1.0 or shipyard_repair_factor < 1.0:
		problems.append("estaleiro: custo positivo, devolução entre 0 e 1 e reparo de pelo menos 1")
	if victory_kinds.size() != victory_targets.size() or victory_kinds.size() != victory_amounts.size() or deadline_choices_min.is_empty():
		problems.append("objetivos do jogo novo: tipos, alvos e quantidades do mesmo tamanho, e ao menos um prazo")
	return problems
