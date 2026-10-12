extends Control
## Tela de abertura: nome, validação dos dados, jogo novo ou carregar o save rápido.
## O menu principal completo entra na Fase 7. Atalhos de linha de comando (também no .exe):
## `-- --novo-jogo` abre direto uma partida nova, `-- --carregar` abre o save rápido.

const GAME_SCENE := "res://ui/screens/game_screen.tscn"

@onready var _config_label: Label = %ConfigLabel
@onready var _clock_label: Label = %ClockLabel
@onready var _new_game: Button = %NewGameButton
@onready var _load_game: Button = %LoadGameButton


func _ready() -> void:
	var problems := GameConfig.get_default().validate()
	problems.append_array(BuildingCatalog.get_default().validate())
	for problem: String in problems:
		push_error("GameConfig: " + problem)
	if problems.is_empty():
		_config_label.text = tr("BOOT_CONFIG_OK")
	else:
		_config_label.text = tr("BOOT_CONFIG_ERRORS") % problems.size()
	_load_game.disabled = not FileAccess.file_exists(SaveSystem.slot_path(GameScreen.QUICK_SLOT))
	_new_game.pressed.connect(_start.bind(""))
	_load_game.pressed.connect(_start.bind(GameScreen.QUICK_SLOT))
	_new_game.grab_focus()
	var args := OS.get_cmdline_user_args()
	if "--novo-jogo" in args:
		_start.call_deferred("")
	elif "--carregar" in args and not _load_game.disabled:
		_start.call_deferred(GameScreen.QUICK_SLOT)


func _process(_delta: float) -> void:
	var clock := GameClock.clock
	var minutes := floori(clock.time_of_day() * 24.0 * 60.0)
	var speed := tr("SPEED_PAUSED") if clock.is_paused() else tr("SPEED_MULTIPLIER") % String.num(clock.speed_multiplier())
	_clock_label.text = tr("BOOT_CLOCK") % [clock.day_number(), minutes / 60, minutes % 60, speed]


func _start(slot: String) -> void:
	GameScreen.load_slot_on_start = slot
	get_tree().change_scene_to_file(GAME_SCENE)
