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
@export var sky_fog_density: float = 0.00035
@export var sky_fog_start_m: float = 60.0

@export_group("Economia")
@export var starting_money: int = 50000
## Abaixo deste saldo, construir fica bloqueado.
@export var min_balance_to_build: int = -10000
## Bônus de imposto quando duas ou mais opções atendem a mesma categoria.
@export var extra_need_option_tax_bonus: float = 0.10
@export var happiness_tax_multiplier_min: float = 0.5
@export var happiness_tax_multiplier_max: float = 1.5
## Felicidade abaixo da qual a casa para de pagar imposto e protesta.
@export var protest_happiness_threshold: int = 20
@export var residents_lost_per_minute_on_shortage: int = 1
## Fração da manutenção cobrada com o prédio pausado.
@export var paused_upkeep_factor: float = 0.5
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
@export var happiness_change_per_minute: float = 20.0
## Constante de tempo da produtividade mostrada no painel do prédio.
@export var productivity_smoothing_seconds: float = 20.0
## As casas são avaliadas em grupos alternados, um grupo por tick (10 = cada casa uma vez a
## cada 2 s, com o tempo de 10 ticks). Moradores e felicidade mudam por minuto: não precisam de
## todo tick, e assim o custo da população cabe no orçamento do tick.
@export var house_update_groups: int = 10
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
@export var islands_by_milestone: PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 5, 5])

@export_group("Ilhas")
## Área da ilha plana (testes e saves de antes da Fase 5), em células.
@export var main_island_size_cells: Vector2i = Vector2i(250, 250)

@export_group("Arquipélago")
## Lado de cada ilha em células, a principal primeiro (seção 7: ~250, ~150 e ~80).
@export var island_sizes_cells: PackedInt32Array = PackedInt32Array([250, 150, 150, 80, 80])
@export var main_island_profile: StringName = &"main_island"
## Perfis sorteados (pela semente) para as outras ilhas.
@export var other_island_profiles: Array[StringName] = [&"farmland", &"highlands", &"woodland", &"reef"]
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
## Ganho de velocidade da estrada de paralelepípedo sobre a de terra.
@export var paved_road_speed_bonus: float = 0.5

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

@export_group("Salvar")
@export var autosave_interval_minutes: float = 10.0
@export var autosave_slots: int = 3

@export_group("Interface")
@export var ui_scale_min: float = 0.8
@export var ui_scale_max: float = 1.5
## Idiomas oferecidos, na ordem do menu. O primeiro é o padrão.
@export var supported_locales: PackedStringArray = PackedStringArray(["pt_BR", "en"])

@export_group("Desempenho")
## Orçamento de um tick de simulação na carga do benchmark.
@export var tick_budget_ms: float = 4.0


## A configuração padrão do projeto, carregada uma vez.
static func get_default() -> GameConfig:
	if _default == null:
		_default = load(DEFAULT_PATH) as GameConfig
	return _default


func tick_interval() -> float:
	return 1.0 / float(ticks_per_second)


## Segundos de jogo num dia. Como o dia é medido a 1x, coincide com os segundos reais.
func day_length_game_seconds() -> float:
	return day_length_real_minutes * 60.0


## Lista os valores inválidos. Vazia quando a configuração está boa.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
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
	if island_sizes_cells.is_empty() or island_sizes_cells.size() > other_island_profiles.size() + 1:
		problems.append("island_sizes_cells: a principal e no máximo uma ilha por perfil de other_island_profiles")
	for side: int in island_sizes_cells:
		if side * cell_size_m > terrain_region_m:
			problems.append("ilha de %d células não cabe numa região de %.0f m" % [side, terrain_region_m])
			break
	if terrace_levels_m.is_empty() or terrace_levels_m[0] <= 0.0:
		problems.append("terrace_levels_m começa acima do mar (> 0)")
	if sea_shelf_width_m <= 0.0 or deep_sea_floor_m >= sea_floor_m:
		problems.append("sea_shelf_width_m deve ser positivo e deep_sea_floor_m ficar abaixo de sea_floor_m")
	if cell_size_m <= 0.0:
		problems.append("cell_size_m deve ser maior que zero")
	if camera_min_distance_m <= 0.0 or camera_min_distance_m >= camera_max_distance_m:
		problems.append("camera_min_distance_m deve ser positivo e menor que camera_max_distance_m")
	if camera_rotate_seconds <= 0.0 or camera_center_seconds <= 0.0:
		problems.append("as durações da câmera devem ser maiores que zero")
	if tax_level_multipliers.size() != 3 or tax_level_happiness.size() != 3:
		problems.append("os níveis de imposto são três: baixo, normal e alto")
	if need_partial_threshold > need_met_threshold:
		problems.append("need_partial_threshold passa de need_met_threshold")
	if supply_smoothing_seconds <= 0.0 or productivity_smoothing_seconds <= 0.0:
		problems.append("as constantes de tempo das médias devem ser maiores que zero")
	if autosave_slots <= 0:
		problems.append("autosave_slots deve ser maior que zero")
	if ships_by_milestone.size() != population_milestones.size() + 1 or islands_by_milestone.size() != population_milestones.size() + 1:
		problems.append("ships_by_milestone e islands_by_milestone têm um valor a mais que population_milestones")
	if sea_chart_cell_m <= 0.0 or ship_min_depth_m >= 0.0 or ship_seconds_per_ton < 0.0:
		problems.append("sea_chart_cell_m positivo, ship_min_depth_m abaixo do mar e ship_seconds_per_ton não negativo")
	for fraction: float in [demolish_refund, paused_upkeep_factor, trader_price_variation]:
		if fraction < 0.0 or fraction > 1.0:
			problems.append("frações (devolução, manutenção pausada, variação de preço) ficam entre 0 e 1")
			break
	return problems
