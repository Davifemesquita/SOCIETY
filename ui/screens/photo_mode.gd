class_name PhotoMode
extends PanelContainer
## Modo foto (Fase 47): a interface some, a partida pausa e sobra um painel pequeno com a hora do dia e a inclinação
## da câmera (dentro de PITCH_RANGE_DEG: livre, mas sem ir para baixo do chão nem virar câmera de mapa). O painel some
## depois de HIDE_AFTER_S sem mexer o mouse e volta quando ele mexe. Esc ou o botão sai e devolve tudo como estava
## (hora, inclinação, velocidade e a interface).

const HIDE_AFTER_S := 3.0
## Quanto a inclinação pode sair da que o zoom dá (graus, para baixo e para cima).
const PITCH_RANGE_DEG := Vector2(-20.0, 15.0)

var active: bool = false

var _game: GameScreen
var _hour := HSlider.new()
var _tilt := HSlider.new()
var _idle: float = 0.0
var _speed_before: int = TickClock.PAUSED
var _extra_before: float = 0.0


func setup(game: GameScreen) -> void:
	_game = game
	name = "PhotoMode"
	visible = false
	theme_type_variation = &"NoticePanel"
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -24
	offset_bottom = -24
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	add_child(row)
	row.add_child(UiKit.icon_rect(Icons.action("photo"), 28))
	row.add_child(UiKit.label("PHOTO_HOUR"))
	_hour.name = "PhotoHour"
	_hour.min_value = 0.0
	_hour.max_value = 24.0
	_hour.step = 0.25
	_hour.custom_minimum_size.x = 220
	_hour.tooltip_text = "PHOTO_HOUR_TIP"
	_hour.focus_mode = Control.FOCUS_NONE
	_hour.value_changed.connect(set_hour)
	row.add_child(_hour)
	row.add_child(UiKit.label("PHOTO_TILT"))
	_tilt.name = "PhotoTilt"
	_tilt.min_value = PITCH_RANGE_DEG.x
	_tilt.max_value = PITCH_RANGE_DEG.y
	_tilt.step = 1.0
	_tilt.custom_minimum_size.x = 160
	_tilt.tooltip_text = "PHOTO_TILT_TIP"
	_tilt.focus_mode = Control.FOCUS_NONE
	_tilt.value_changed.connect(func(degrees: float) -> void:
		_game.camera.rig.pitch_offset_deg = clampf(degrees, PITCH_RANGE_DEG.x, PITCH_RANGE_DEG.y)
		_game.camera.apply())
	row.add_child(_tilt)
	var leave := UiKit.button("PHOTO_EXIT", "action_back", toggle, "PHOTO_EXIT_TIP")
	leave.name = "PhotoExit"
	row.add_child(leave)


func toggle() -> void:
	if active:
		_leave()
	else:
		_enter()


func _enter() -> void:
	active = true
	var clock := GameClock.clock
	_speed_before = clock.speed_index
	_extra_before = clock.extra_hours
	GameClock.set_speed(TickClock.PAUSED)
	_game.tool.select(0)
	_game.tool.select_ship(0)
	while _game.tool.mode != BuildTool.Mode.NONE or _game.tool.dragging:
		_game.tool.cancel()
	_game.hud.visible = false
	_game.building_view.hide_icons = true
	# o clique no mundo não seleciona nada (o contorno sairia na foto); a câmera segue com o input dela
	_game.tool.set_process_unhandled_input(false)
	_game.ship_picker.set_process_unhandled_input(false)
	_hour.set_value_no_signal(clock.hour())
	_tilt.set_value_no_signal(0.0)
	_idle = 0.0
	visible = true


func _leave() -> void:
	active = false
	GameClock.clock.extra_hours = _extra_before
	_game.camera.rig.pitch_offset_deg = 0.0
	_game.camera.apply()
	GameClock.set_speed(_speed_before)
	_game.tool.set_process_unhandled_input(true)
	_game.ship_picker.set_process_unhandled_input(true)
	_game.building_view.hide_icons = false
	_game.hud.visible = true
	visible = false


## A hora mostrada (0 a 24), sem mexer nos ticks da partida: só o deslocamento visual do relógio.
func set_hour(hour: float) -> void:
	_hour.set_value_no_signal(hour)
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)


func _process(delta: float) -> void:
	if not active:
		return
	_idle += delta
	# o painel some sem o mouse mexer (a foto sai limpa), e não some com o mouse em cima dele
	var over := get_global_rect().has_point(get_global_mouse_position())
	modulate.a = 1.0 if over or _idle < HIDE_AFTER_S else 0.0


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		_idle = 0.0
	elif event.is_action_pressed(&"game_menu") or event.is_action_pressed(&"photo_mode"):
		_leave()
		get_viewport().set_input_as_handled()
