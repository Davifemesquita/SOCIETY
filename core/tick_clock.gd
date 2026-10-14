class_name TickClock
extends RefCounted
## Relógio de passo fixo da simulação, sem nó e sem árvore de cenas.
## Converte o tempo real de cada quadro em ticks inteiros, multiplicado pela velocidade.
## O dia e a noite derivam daqui, mas são só visuais: a economia conta ticks.

const PAUSED := -1
## Folga contra o arredondamento: 0,6 s a 5 ticks/s dá 2,9999… e precisa virar 3 ticks.
const _EPSILON := 1e-6

var tick_count: int = 0
## Índice em GameConfig.game_speeds, ou PAUSED.
var speed_index: int = 0

var _config: GameConfig
## Tempo acumulado ainda sem tick, medido em ticks (não em segundos).
var _accumulator: float = 0.0
## Índice da velocidade ativa antes da pausa, para retomar nela.
var _resume_speed_index: int = 0
## Horas somadas só ao relógio do dia (F7, em desenvolvimento). A economia não anda com elas.
var extra_hours: float = 0.0


func _init(config: GameConfig) -> void:
	_config = config


func is_paused() -> bool:
	return speed_index == PAUSED


func speed_multiplier() -> float:
	if is_paused():
		return 0.0
	return _config.game_speeds[speed_index]


## Escolhe uma velocidade de GameConfig.game_speeds ou PAUSED. Devolve false se o índice não existe.
func set_speed(index: int) -> bool:
	if index != PAUSED and (index < 0 or index >= _config.game_speeds.size()):
		return false
	if index != PAUSED:
		_resume_speed_index = index
	speed_index = index
	return true


func toggle_pause() -> void:
	if is_paused():
		set_speed(_resume_speed_index)
	else:
		set_speed(PAUSED)


## Avança o relógio pelo tempo real de um quadro e devolve quantos ticks rodar agora.
## Acima de max_ticks_per_frame o excedente é descartado: o jogo desacelera em vez de travar.
func advance(real_delta: float) -> int:
	if is_paused() or real_delta <= 0.0:
		return 0
	_accumulator += real_delta * speed_multiplier() * _config.ticks_per_second
	var due := floori(_accumulator + _EPSILON)
	if due > _config.max_ticks_per_frame:
		due = _config.max_ticks_per_frame
		_accumulator = 0.0
	else:
		_accumulator = maxf(_accumulator - due, 0.0)
	tick_count += due
	return due


## Fração do próximo tick já decorrida, de 0 a 1, para a apresentação interpolar agentes.
func interpolation_alpha() -> float:
	return clampf(_accumulator, 0.0, 1.0)


func game_seconds() -> float:
	return tick_count * _config.tick_interval()


## Hora do dia de 0 (meia-noite) a 1, só para céu e luzes. O jogo novo começa em day_start_hour.
func time_of_day() -> float:
	return _day_position(game_seconds()) - day_number() + 1


func day_number() -> int:
	return floori(_day_position(game_seconds())) + 1


## Hora de 0 a 24 que anda lisa entre os ticks (céu, luzes e pedestres a 60 quadros por segundo).
func hour() -> float:
	var position := _day_position((tick_count + interpolation_alpha()) * _config.tick_interval())
	return (position - floorf(position)) * 24.0


## Horas desde a meia-noite do dia 1, lisas entre os ticks (o clima anda nelas).
func total_hours() -> float:
	return _day_position((tick_count + interpolation_alpha()) * _config.tick_interval()) * 24.0


## Dias decorridos desde a meia-noite do dia 1, com a hora de início e as horas extras.
func _day_position(seconds: float) -> float:
	return seconds / _config.day_length_game_seconds() + (_config.day_start_hour + extra_hours) / 24.0


func to_dict() -> Dictionary:
	return {"tick_count": tick_count, "speed_index": speed_index, "resume_speed_index": _resume_speed_index,
			"extra_hours": extra_hours}


func load_dict(data: Dictionary) -> void:
	tick_count = maxi(_int_or(data.get("tick_count"), 0), 0)
	var raw_extra: Variant = data.get("extra_hours")
	extra_hours = raw_extra if raw_extra is float else 0.0
	_resume_speed_index = clampi(_int_or(data.get("resume_speed_index"), 0), 0, _config.game_speeds.size() - 1)
	if not set_speed(_int_or(data.get("speed_index"), 0)):
		set_speed(0)
	_accumulator = 0.0


static func _int_or(value: Variant, fallback: int) -> int:
	return value if value is int else fallback
