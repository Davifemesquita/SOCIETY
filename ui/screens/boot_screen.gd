extends Control
## Tela de abertura da Fase 0: mostra o nome, valida a configuração e o relógio rodando.

@onready var _config_label: Label = %ConfigLabel
@onready var _clock_label: Label = %ClockLabel


func _ready() -> void:
	var problems := GameConfig.get_default().validate()
	for problem: String in problems:
		push_error("GameConfig: " + problem)
	if problems.is_empty():
		_config_label.text = tr("BOOT_CONFIG_OK")
	else:
		_config_label.text = tr("BOOT_CONFIG_ERRORS") % problems.size()


func _process(_delta: float) -> void:
	var clock := GameClock.clock
	var minutes := floori(clock.time_of_day() * 24.0 * 60.0)
	var speed := tr("SPEED_PAUSED") if clock.is_paused() else tr("SPEED_MULTIPLIER") % String.num(clock.speed_multiplier())
	_clock_label.text = tr("BOOT_CLOCK") % [clock.day_number(), minutes / 60, minutes % 60, speed]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameClock.toggle_pause()
