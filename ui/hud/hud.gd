class_name Hud
extends Control
## Interface da partida: barra superior (data, velocidade, dinheiro, população, estatísticas,
## salvar e carregar), menu de construção por categoria, painel do selecionado, avisos e a dica
## ao lado do cursor. Só lê o estado e chama a ferramenta; nenhuma regra de jogo aqui.

signal save_requested()
signal load_requested()

const MESSAGE_SECONDS := 3.0
const REFRESH_SECONDS := 0.5

var selection_panel: SelectionPanel
var statistics_window: StatisticsWindow

var _tool: BuildTool
var _simulation: Simulation
var _clock_label := Label.new()
var _money_label := Label.new()
var _population_label := Label.new()
var _speed_buttons: Array[Button] = []
var _category_buttons: Array[Button] = []
var _items := HFlowContainer.new()
var _item_buttons: Dictionary[StringName, Button] = {}
var _message := Label.new()
var _hint := Label.new()
var _cursor_label := Label.new()
var _message_left: float = 0.0
var _refresh_left: float = 0.0
var _category: int = 0


func setup(tool: BuildTool, simulation: Simulation) -> void:
	_tool = tool
	_simulation = simulation
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_build_menu()
	selection_panel = SelectionPanel.new()
	_pin(selection_panel, Vector2(0.0, 1.0), Vector2(16, -110), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)
	add_child(selection_panel)
	selection_panel.setup(tool, simulation)
	statistics_window = StatisticsWindow.new()
	_pin(statistics_window, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	add_child(statistics_window)
	statistics_window.setup(simulation)
	_build_labels()
	tool.changed.connect(_refresh_tool)
	tool.refused.connect(func(reason: StringName) -> void: show_message(tr(reason)))
	EventBus.time_speed_changed.connect(func(_speed_index: int, _paused: bool) -> void: _refresh_speed())
	EventBus.good_shortage.connect(func(_island: int, good: StringName) -> void:
		show_message(tr("MSG_SHORTAGE") % tr(simulation.data.good(good).name_key)))
	_select_category(0)
	_refresh_speed()
	_refresh_tool()
	_refresh()


func show_message(text: String) -> void:
	_message.text = text
	_message.visible = not text.is_empty()
	_message_left = MESSAGE_SECONDS


func toggle_statistics() -> void:
	statistics_window.visible = not statistics_window.visible


func _process(delta: float) -> void:
	var clock := GameClock.clock
	var minutes := floori(clock.time_of_day() * 24.0 * 60.0)
	_clock_label.text = tr("HUD_CLOCK") % [clock.day_number(), minutes / 60, minutes % 60]
	if _message_left > 0.0:
		_message_left -= delta
		_message.visible = _message_left > 0.0
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh()
	_update_cursor_label()


func _refresh() -> void:
	var world := _simulation.world
	_money_label.text = tr("HUD_MONEY") % [Fmt.integer(world.money), Fmt.signed(world.income_per_min - world.upkeep_per_min)]
	_money_label.tooltip_text = tr("HUD_MONEY_TIP") % [Fmt.integer(world.income_per_min), Fmt.integer(world.upkeep_per_min)]
	var parts: PackedStringArray = []
	for tier: TierDef in _simulation.data.tiers:
		parts.append("%s %s" % [tr(tier.name_key), Fmt.integer(world.population(tier.id))])
	_population_label.text = " · ".join(parts)
	for def_id: StringName in _item_buttons:
		var def := _simulation.data.building(def_id)
		_item_buttons[def_id].disabled = not _simulation.free_build and PlacementRules.check_unlock(world, def) != PlacementRules.OK


func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	panel.anchor_right = 1.0
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	panel.add_child(row)
	_clock_label.custom_minimum_size.x = 150
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
	row.add_child(VSeparator.new())
	_money_label.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(_money_label)
	row.add_child(VSeparator.new())
	row.add_child(_population_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var stats := _button("HUD_STATS")
	stats.pressed.connect(toggle_statistics)
	row.add_child(stats)
	var save := _button("HUD_SAVE")
	save.pressed.connect(save_requested.emit)
	row.add_child(save)
	var load_button := _button("HUD_LOAD")
	load_button.pressed.connect(load_requested.emit)
	row.add_child(load_button)


## Duas linhas: as categorias e, abaixo, os prédios da categoria escolhida (quebrando a linha
## quando não cabem).
func _build_build_menu() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	_pin(panel, Vector2(0.5, 1.0), Vector2(0, -8), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var categories := HBoxContainer.new()
	categories.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(categories)
	for index: int in _categories().size():
		var button := _button(_category_label(index))
		button.toggle_mode = true
		button.pressed.connect(_select_category.bind(index))
		categories.add_child(button)
		_category_buttons.append(button)
	_items.custom_minimum_size.x = 900
	_items.alignment = FlowContainer.ALIGNMENT_CENTER
	column.add_child(_items)


## Categorias do menu: residências, produção por classe, serviços e infraestrutura.
func _categories() -> Array[Array]:
	var data := _simulation.data
	var groups: Array[Array] = [data.buildings.filter(func(def: BuildingDef) -> bool: return def.kind == BuildingDef.Kind.RESIDENCE)]
	for tier: TierDef in data.tiers:
		groups.append(data.buildings.filter(func(def: BuildingDef) -> bool:
			return (def.is_production() and def.workforce_tier == tier.id) \
					or (def.kind == BuildingDef.Kind.MODULE and def.unlock_tier == tier.id)))
	groups.append(data.buildings.filter(func(def: BuildingDef) -> bool: return def.kind == BuildingDef.Kind.SERVICE))
	groups.append([])
	return groups


func _category_label(index: int) -> String:
	var tiers := _simulation.data.tiers
	if index == 0:
		return tr("HUD_CATEGORY_RESIDENCES")
	if index <= tiers.size():
		return tr("HUD_CATEGORY_PRODUCTION") % tr(tiers[index - 1].name_key)
	return tr("HUD_CATEGORY_SERVICES") if index == tiers.size() + 1 else tr("HUD_CATEGORY_INFRASTRUCTURE")


func _select_category(index: int) -> void:
	_category = index
	for i: int in _category_buttons.size():
		_category_buttons[i].set_pressed_no_signal(i == index)
	for child: Node in _items.get_children():
		child.queue_free()
	_item_buttons.clear()
	var defs: Array = _categories()[index]
	for def: BuildingDef in defs:
		var button := _button(def.name_key)
		button.tooltip_text = _tooltip(def)
		button.pressed.connect(func() -> void: _tool.start_building(def))
		_items.add_child(button)
		_item_buttons[def.id] = button
	if defs.is_empty():
		var road := _button("HUD_ROAD")
		road.pressed.connect(_tool.start_road)
		_items.add_child(road)
		var demolish := _button("HUD_DEMOLISH")
		demolish.pressed.connect(_tool.start_demolish)
		_items.add_child(demolish)
	_refresh()


func _tooltip(def: BuildingDef) -> String:
	var data := _simulation.data
	var lines: PackedStringArray = [tr(def.name_key)]
	var cost: PackedStringArray = [tr("TIP_COINS") % Fmt.integer(def.cost_money)]
	for material: StringName in def.cost_materials:
		cost.append("%d %s" % [def.cost_materials[material], tr(data.good(material).name_key)])
	lines.append(tr("TIP_COST") % ", ".join(cost))
	if def.upkeep_per_min > 0:
		lines.append(tr("TIP_UPKEEP") % Fmt.integer(def.upkeep_per_min))
	if def.is_production():
		lines.append(tr("TIP_PRODUCES") % [Fmt.decimal(def.output_per_min()), tr(data.good(def.output).name_key)])
		if not def.inputs.is_empty():
			lines.append(tr("TIP_NEEDS") % ", ".join(def.inputs.map(func(good: StringName) -> String: return tr(data.good(good).name_key))))
		lines.append(tr("TIP_WORKERS") % [def.workers, tr(data.tier(def.workforce_tier).name_key)])
		if def.modules_required > 0:
			lines.append(tr("TIP_MODULES") % [def.modules_required, tr(data.building(def.module_id).name_key)])
		if def.terrain == BuildingDef.Terrain.COAST:
			lines.append(tr("TIP_COAST"))
	if def.unlock_tier != &"":
		lines.append(tr("TIP_UNLOCK") % [Fmt.integer(def.unlock_residents), tr(data.tier(def.unlock_tier).name_key)])
	return "\n".join(lines)


func _build_labels() -> void:
	_pin(_message, Vector2(0.5, 0.0), Vector2(0, 56), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override(&"font_size", 22)
	_message.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_message.add_theme_constant_override(&"outline_size", 6)
	_message.visible = false
	add_child(_message)
	_pin(_hint, Vector2(0.5, 1.0), Vector2(0, -96), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
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
static func _pin(control: Control, anchor: Vector2, offset: Vector2, grow_h: Control.GrowDirection, grow_v: Control.GrowDirection) -> void:
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


static func _button(text_key: String) -> Button:
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
		text = tr("PREVIEW_ROAD_COST") % [_tool.road_cells().size(), Fmt.integer(_tool.road_cost())]
	_cursor_label.text = text
	_cursor_label.visible = not text.is_empty()
	_cursor_label.position = get_local_mouse_position() + Vector2(18, 18)
