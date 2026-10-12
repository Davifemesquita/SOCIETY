class_name Hud
extends Control
## Interface da Fase 1: barra superior (data, hora, velocidade, salvar e carregar), barra de
## construção, painel do prédio selecionado, avisos e a dica ao lado do cursor.
## Só lê o estado e chama a ferramenta; nenhuma regra de jogo aqui.

signal save_requested()
signal load_requested()

const MESSAGE_SECONDS := 2.5

var _tool: BuildTool
var _simulation: Simulation
var _clock_label := Label.new()
var _speed_buttons: Array[Button] = []
var _info_panel := PanelContainer.new()
var _info_name := Label.new()
var _info_road := Label.new()
var _message := Label.new()
var _hint := Label.new()
var _cursor_label := Label.new()
var _message_left: float = 0.0


func setup(tool: BuildTool, simulation: Simulation) -> void:
	_tool = tool
	_simulation = simulation
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_bottom_bar()
	_build_info_panel()
	_build_labels()
	tool.changed.connect(_refresh_tool)
	tool.selection_changed.connect(_on_selection_changed)
	tool.refused.connect(func(reason: StringName) -> void: show_message(tr(reason)))
	EventBus.time_speed_changed.connect(func(_speed_index: int, _paused: bool) -> void: _refresh_speed())
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _on_selection_changed(_tool.selected_id))
	_refresh_speed()
	_refresh_tool()
	_on_selection_changed(0)


func show_message(text: String) -> void:
	_message.text = text
	_message.visible = true
	_message_left = MESSAGE_SECONDS


func _process(delta: float) -> void:
	var clock := GameClock.clock
	var minutes := floori(clock.time_of_day() * 24.0 * 60.0)
	_clock_label.text = tr("HUD_CLOCK") % [clock.day_number(), minutes / 60, minutes % 60]
	if _message_left > 0.0:
		_message_left -= delta
		_message.visible = _message_left > 0.0
	_update_cursor_label()


func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.anchor_right = 1.0
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	panel.add_child(row)
	_clock_label.custom_minimum_size.x = 180
	row.add_child(_clock_label)
	var speeds := GameConfig.get_default().game_speeds
	for index: int in speeds.size() + 1:
		var label := "SPEED_PAUSED" if index == 0 else tr("SPEED_MULTIPLIER") % _speed_text(speeds[index - 1])
		var button := _button(label)
		button.toggle_mode = true
		var speed_index := TickClock.PAUSED if index == 0 else index - 1
		button.pressed.connect(func() -> void: GameClock.set_speed(speed_index))
		row.add_child(button)
		_speed_buttons.append(button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var save := _button("HUD_SAVE")
	save.pressed.connect(save_requested.emit)
	row.add_child(save)
	var load_button := _button("HUD_LOAD")
	load_button.pressed.connect(load_requested.emit)
	row.add_child(load_button)


func _build_bottom_bar() -> void:
	var panel := PanelContainer.new()
	_pin(panel, Vector2(0.5, 1.0), Vector2(0, -12), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	panel.add_child(row)
	for def: BuildingDef in _simulation.catalog.buildings:
		var button := _button(def.name_key)
		button.pressed.connect(func() -> void: _tool.start_building(def))
		row.add_child(button)
	var road := _button("HUD_ROAD")
	road.pressed.connect(_tool.start_road)
	row.add_child(road)
	var demolish := _button("HUD_DEMOLISH")
	demolish.pressed.connect(_tool.start_demolish)
	row.add_child(demolish)


func _build_info_panel() -> void:
	_pin(_info_panel, Vector2(0.0, 1.0), Vector2(16, -80), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)
	add_child(_info_panel)
	var column := VBoxContainer.new()
	_info_panel.add_child(column)
	_info_name.add_theme_font_size_override(&"font_size", 20)
	column.add_child(_info_name)
	column.add_child(_info_road)
	var hint := Label.new()
	hint.text = "INFO_CENTER_HINT"
	hint.modulate = Color(1, 1, 1, 0.7)
	column.add_child(hint)


func _build_labels() -> void:
	_pin(_message, Vector2(0.5, 0.0), Vector2(0, 56), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override(&"font_size", 22)
	_message.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_message.add_theme_constant_override(&"outline_size", 6)
	_message.visible = false
	add_child(_message)
	_pin(_hint, Vector2(0.5, 1.0), Vector2(0, -72), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override(&"outline_size", 5)
	add_child(_hint)
	_cursor_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_cursor_label.add_theme_constant_override(&"outline_size", 5)
	_cursor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cursor_label)


## Prende o controle num ponto relativo da tela (anchor) com deslocamento em pixels; o
## tamanho sai do conteúdo e cresce na direção pedida. Vale para qualquer resolução.
func _pin(control: Control, anchor: Vector2, offset: Vector2, grow_h: Control.GrowDirection, grow_v: Control.GrowDirection) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_right = offset.x
	control.offset_top = offset.y
	control.offset_bottom = offset.y
	control.grow_horizontal = grow_h
	control.grow_vertical = grow_v


static func _speed_text(speed: float) -> String:
	return String.num(speed, 0 if is_equal_approx(speed, roundf(speed)) else 1)


func _button(text_key: String) -> Button:
	var button := Button.new()
	button.text = text_key
	button.focus_mode = Control.FOCUS_NONE
	return button


func _refresh_speed() -> void:
	var clock := GameClock.clock
	for index: int in _speed_buttons.size():
		var speed_index := TickClock.PAUSED if index == 0 else index - 1
		_speed_buttons[index].set_pressed_no_signal(clock.speed_index == speed_index)


func _refresh_tool() -> void:
	match _tool.mode:
		BuildTool.Mode.BUILDING:
			_hint.text = tr("HUD_HINT_BUILDING")
		BuildTool.Mode.ROAD:
			_hint.text = tr("HUD_HINT_ROAD")
		BuildTool.Mode.DEMOLISH:
			_hint.text = tr("HUD_HINT_DEMOLISH")
		_:
			_hint.text = ""


func _update_cursor_label() -> void:
	var text := ""
	var reason := _tool.preview_reason()
	if reason != PlacementRules.OK:
		text = tr(reason)
	elif _tool.mode == BuildTool.Mode.ROAD and _tool.dragging:
		text = tr("PREVIEW_ROAD_LENGTH") % _tool.road_cells().size()
	_cursor_label.text = text
	_cursor_label.visible = not text.is_empty()
	_cursor_label.position = get_local_mouse_position() + Vector2(18, 18)


func _on_selection_changed(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	_info_panel.visible = record != null
	if record == null:
		return
	_info_name.text = tr(_simulation.def_of(record).name_key)
	var has_road := _simulation.has_road_access(building_id)
	_info_road.text = tr("INFO_ROAD_OK") if has_road else tr("INFO_ROAD_MISSING")
	_info_road.modulate = Color(0.6, 1.0, 0.6) if has_road else Color(1.0, 0.65, 0.3)
