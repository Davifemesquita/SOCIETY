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
## Patamares de população total que liberam ilhas, navios e regras.
@export var population_milestones: PackedInt32Array = PackedInt32Array([100, 500, 1000, 2500, 5000, 10000])

@export_group("Produção e logística")
## Capacidade de cada buffer de entrada e de saída de um prédio, em toneladas.
@export var building_buffer_t: int = 4
## Capacidade inicial do estoque da ilha por bem, em toneladas.
@export var island_storage_capacity_t: int = 50
@export var carts_per_building: int = 1
@export var cart_capacity_t: int = 2
## Distância máxima, por estrada, entre um prédio e um armazém.
@export var logistics_range_cells: int = 40
## Raio dos serviços (mercado, taverna, igreja, escola), medido por estrada.
@export var service_radius_cells: int = 25
@export var lumberjack_min_trees: int = 20
@export var ship_cargo_slots: int = 4
@export var ship_slot_capacity_t: int = 50

@export_group("Construção")
@export var cell_size_m: float = 2.0
## Diferença de altura máxima dentro da área de um prédio.
@export var max_build_height_delta_m: float = 0.5
## Fração dos materiais devolvida ao demolir.
@export var demolish_refund: float = 0.5
## Ganho de velocidade da estrada de paralelepípedo sobre a de terra.
@export var paved_road_speed_bonus: float = 0.5

@export_group("Mundo vivo")
@export var max_visible_pedestrians: int = 2000

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
	if happiness_tax_multiplier_min > happiness_tax_multiplier_max:
		problems.append("happiness_tax_multiplier_min passa do máximo")
	if ui_scale_min <= 0.0 or ui_scale_min > ui_scale_max:
		problems.append("ui_scale_min deve ser positivo e não passar de ui_scale_max")
	if supported_locales.is_empty():
		problems.append("supported_locales precisa de pelo menos um idioma")
	if autosave_slots <= 0:
		problems.append("autosave_slots deve ser maior que zero")
	for fraction: float in [demolish_refund, paused_upkeep_factor, trader_price_variation]:
		if fraction < 0.0 or fraction > 1.0:
			problems.append("frações (devolução, manutenção pausada, variação de preço) ficam entre 0 e 1")
			break
	return problems
