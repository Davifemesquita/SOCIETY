class_name SelectionPanel
extends PanelContainer
## Painel do prédio selecionado. Produção: estado, produtividade, ciclo, buffers,
## trabalhadores, manutenção, pausar, copiar e demolir. Casa: classe, moradores, necessidades
## em semáforo, felicidade, imposto e bloqueio de upgrade. Serviço: casas atendidas.
## Campo e pasto: a fazenda que servem.

const REFRESH_SECONDS := 0.25
const GREEN := Color(0.55, 0.9, 0.5)
const YELLOW := Color(1.0, 0.82, 0.3)
const RED := Color(1.0, 0.45, 0.35)
## Produtividade média a partir da qual o prédio aparece como produzindo.
const SHOWN_PRODUCING := 0.9

var _tool: BuildTool
var _simulation: Simulation
var _title := Label.new()
var _body := VBoxContainer.new()
var _buttons := HBoxContainer.new()
var _road := Label.new()
var _lines: Array[Label] = []
var _pause: Button
var _block: CheckBox
var _refresh_left: float = 0.0
var _building_id: int = 0


func setup(tool: BuildTool, simulation: Simulation) -> void:
	_tool = tool
	_simulation = simulation
	custom_minimum_size.x = 300
	add_theme_stylebox_override(&"panel", UiStyle.panel())
	var column := VBoxContainer.new()
	add_child(column)
	_title.add_theme_font_size_override(&"font_size", 20)
	column.add_child(_title)
	column.add_child(_body)
	_road.text = "INFO_ROAD_MISSING"
	_road.modulate = RED
	column.add_child(_road)
	column.add_child(_buttons)
	var hint := Label.new()
	hint.text = "INFO_CENTER_HINT"
	hint.modulate = Color(1, 1, 1, 0.6)
	column.add_child(hint)
	tool.selection_changed.connect(show_building)
	EventBus.house_upgraded.connect(func(building_id: int) -> void:
		if building_id == _building_id:
			show_building(building_id))
	show_building(0)


func shows_missing_road() -> bool:
	return visible and _road.visible


func show_building(building_id: int) -> void:
	_building_id = building_id
	var record := _simulation.world.building(building_id)
	visible = record != null
	for child: Node in _body.get_children() + _buttons.get_children():
		child.queue_free()
	_lines.clear()
	_pause = null
	_block = null
	if record == null:
		return
	var def := _simulation.def_of(record)
	match def.kind:
		BuildingDef.Kind.PRODUCTION:
			_build_production(record, def)
		BuildingDef.Kind.RESIDENCE:
			_build_house(record)
		_:
			_add_lines(1)
	if def.kind != BuildingDef.Kind.RESIDENCE:
		_add_button("PANEL_DEMOLISH", func() -> void:
			_simulation.execute(DemolishCommand.new(record.island_id, Rect2i(record.origin, Vector2i.ONE))))
	_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh()


func _build_production(record: BuildingRecord, def: BuildingDef) -> void:
	_add_lines(6 + def.inputs.size())
	_pause = _add_button("PANEL_PAUSE", func() -> void:
		_simulation.execute(SetPausedCommand.new(record.id, not _simulation.world.building(record.id).paused))
		_refresh())
	_add_button("PANEL_COPY", func() -> void: _tool.start_building(def))


func _build_house(record: BuildingRecord) -> void:
	var tier := _simulation.data.tier(record.tier)
	_add_lines(3 + tier.basic_needs.size() + tier.luxury_needs.size())
	_block = CheckBox.new()
	_block.text = "HOUSE_BLOCK_UPGRADE"
	_block.focus_mode = Control.FOCUS_NONE
	_block.toggled.connect(func(on: bool) -> void: _simulation.execute(SetUpgradeBlockedCommand.new(record.id, on)))
	_buttons.add_child(_block)


func _add_lines(count: int) -> void:
	for i: int in count:
		var label := Label.new()
		_body.add_child(label)
		_lines.append(label)


func _add_button(text_key: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_key
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button


func _refresh() -> void:
	var record := _simulation.world.building(_building_id)
	if record == null:
		visible = false
		return
	var def := _simulation.def_of(record)
	_road.visible = def.kind != BuildingDef.Kind.MODULE and not _simulation.has_road_access(record.id)
	match def.kind:
		BuildingDef.Kind.PRODUCTION:
			_refresh_production(record, def)
		BuildingDef.Kind.RESIDENCE:
			_refresh_house(record)
		BuildingDef.Kind.SERVICE:
			_title.text = tr(def.name_key)
			var houses: Array = _simulation.derived_state().service_houses.get(record.id, [])
			_lines[0].text = tr("SERVICE_HOUSES") % Fmt.integer(houses.size())
		BuildingDef.Kind.MODULE:
			_title.text = tr(def.name_key)
			var owner: int = _simulation.derived_state().module_owner.get(record.id, 0)
			var farm := _simulation.world.building(owner)
			_lines[0].text = tr("MODULE_OF") % tr(_simulation.def_of(farm).name_key) if farm != null else tr("MODULE_LOOSE")


func _refresh_production(record: BuildingRecord, def: BuildingDef) -> void:
	var data := _simulation.data
	var config := _simulation.config
	_title.text = tr(def.name_key)
	var state := shown_state(record)
	_lines[0].text = tr(state_key(state))
	_lines[0].modulate = GREEN if state == BuildingRecord.State.PRODUCING else (Color(0.8, 0.8, 0.8) if record.paused else RED)
	_lines[1].text = tr("PANEL_PRODUCTIVITY") % Fmt.percent(record.productivity)
	_lines[2].text = tr("PANEL_CYCLE") % Fmt.integer(def.cycle_s)
	var index := 3
	for input: StringName in def.inputs:
		var held: float = record.input_buffer.get(input, 0.0)
		_lines[index].text = tr("PANEL_BUFFER") % [tr(data.good(input).name_key), Fmt.decimal(held), config.building_buffer_t]
		index += 1
	_lines[index].text = tr("PANEL_BUFFER") % [tr(data.good(def.output).name_key), Fmt.decimal(record.output_buffer), config.building_buffer_t]
	var workforce := _simulation.world.economy(record.island_id).workforce(def.workforce_tier)
	_lines[index + 1].text = tr("PANEL_WORKERS") % [def.workers, tr(data.tier(def.workforce_tier).name_key), Fmt.percent(workforce)]
	_lines[index + 2].text = tr("PANEL_UPKEEP") % Fmt.integer(def.upkeep_per_min * (config.paused_upkeep_factor if record.paused else 1.0))
	if _pause != null:
		_pause.text = tr("PANEL_RESUME") if record.paused else tr("PANEL_PAUSE")


func _refresh_house(record: BuildingRecord) -> void:
	var data := _simulation.data
	var config := _simulation.config
	var world := _simulation.world
	var derived := _simulation.derived_state()
	var tier := data.tier(record.tier)
	_title.text = tr("HOUSE_TITLE") % tr(tier.name_key)
	_lines[0].text = tr("HOUSE_RESIDENTS") % [floori(record.residents), tier.residents_per_house]
	_lines[1].text = tr("HOUSE_HAPPINESS") % roundi(record.happiness) \
			+ ("  ·  " + tr("STATE_PROTEST") if record.happiness < config.protest_happiness_threshold else "")
	_lines[1].modulate = RED if record.happiness < config.protest_happiness_threshold else Color.WHITE
	_lines[2].text = tr("HOUSE_TAX") % Fmt.decimal(HouseNeeds.tax_per_min(world, data, config, derived, record))
	var index := 3
	for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
		var value := HouseNeeds.satisfaction(world, derived, record, need)
		var luxury := tier.luxury_needs.has(need)
		_lines[index].text = "● %s%s  %s" % [tr(need.name_key), " (" + tr("HOUSE_LUXURY") + ")" if luxury else "", Fmt.percent(value)]
		_lines[index].modulate = GREEN if value >= config.need_met_threshold else (YELLOW if value >= config.need_partial_threshold else RED)
		index += 1
	if _block != null:
		_block.set_pressed_no_signal(record.upgrade_blocked)


## Estado para mostrar: entre um ciclo e o próximo o prédio passa um tick "sem entrada" sem
## perder tempo; só vale como parado quando a produtividade média cai.
static func shown_state(record: BuildingRecord) -> BuildingRecord.State:
	if record.paused or record.state in [BuildingRecord.State.NO_ROAD, BuildingRecord.State.NO_MODULES]:
		return record.state
	return BuildingRecord.State.PRODUCING if record.productivity >= SHOWN_PRODUCING else record.state


static func state_key(state: BuildingRecord.State) -> String:
	match state:
		BuildingRecord.State.PRODUCING:
			return "STATE_PRODUCING"
		BuildingRecord.State.NO_INPUT:
			return "STATE_NO_INPUT"
		BuildingRecord.State.NO_WORKERS:
			return "STATE_NO_WORKERS"
		BuildingRecord.State.OUTPUT_FULL:
			return "STATE_OUTPUT_FULL"
		BuildingRecord.State.NO_ROAD:
			return "STATE_NO_ROAD"
		BuildingRecord.State.NO_MODULES:
			return "STATE_NO_MODULES"
		BuildingRecord.State.PAUSED:
			return "STATE_PAUSED"
	return "STATE_IDLE"
