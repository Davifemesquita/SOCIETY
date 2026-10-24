class_name SelectionPanel
extends PanelContainer
## Painel do prédio selecionado. Produção: estado, produtividade, ciclo, buffers,
## trabalhadores, manutenção, pausar, copiar e demolir. Casa: classe, moradores, necessidades
## em semáforo, felicidade, imposto e bloqueio de upgrade. Serviço: casas atendidas.
## Campo e pasto: a fazenda que servem. Entreposto (Fase 6): vagas de navio, comprar navio e o
## comércio com o comerciante; píer: se está em funcionamento. Desde a Fase 7: ícone do prédio no
## título, retrato da classe na casa, semáforo com forma (modo para daltonismo) e a calculadora de
## proporção na produção. Fase 11: eletricidade e o especialista do prédio.

signal trade_requested(island_id: int)
## O jogador pediu para a câmera ir até o prédio (botão do olho, igual à tecla F).
signal center_requested()
## Especialistas (Fase 11): abrir a janela para designar alguém a este prédio.
signal specialists_requested(building_id: int)

const REFRESH_SECONDS := 0.25
## Produtividade média a partir da qual o prédio aparece como produzindo.
const SHOWN_PRODUCING := 0.9

var _tool: BuildTool
var _simulation: Simulation
var _title := Label.new()
var _title_icon := TextureRect.new()
var _portrait := TextureRect.new()
var _body := VBoxContainer.new()
## Botões do bloco numa linha, que quebra quando não cabe (estaleiro com vários navios).
var _buttons := HFlowContainer.new()
var _road := Label.new()
var _lines: Array[Label] = []
var _pause: Button
var _block: CheckBox
var _refresh_left: float = 0.0
var _building_id: int = 0


func setup(tool: BuildTool, simulation: Simulation) -> void:
	_tool = tool
	_simulation = simulation
	custom_minimum_size.x = 400
	var column := VBoxContainer.new()
	add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 8)
	column.add_child(head)
	_title_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title_icon.custom_minimum_size = Vector2(44, 44)
	head.add_child(_title_icon)
	_title.theme_type_variation = &"HeaderLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(_title)
	head.add_child(UiKit.icon_button("action_center", "INFO_CENTER_HINT", func() -> void: center_requested.emit()))
	head.add_child(UiKit.icon_button("action_close", "UI_CLOSE", func() -> void: tool.select(0)))
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(96, 120)
	_portrait.visible = false
	var body_row := HBoxContainer.new()
	body_row.add_theme_constant_override(&"separation", 10)
	column.add_child(body_row)
	body_row.add_child(_portrait)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_row.add_child(_body)
	_road.text = "INFO_ROAD_MISSING"
	UiPalette.paint(_road, UiPalette.Status.BAD)
	column.add_child(_road)
	_buttons.add_theme_constant_override(&"h_separation", 6)
	_buttons.add_theme_constant_override(&"v_separation", 6)
	column.add_child(_buttons)
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
	# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
	UiKit.clear(_body)
	UiKit.clear(_buttons)
	_lines.clear()
	_portrait.visible = false
	_pause = null
	_block = null
	if record == null:
		return
	var def := _simulation.def_of(record)
	_title_icon.texture = Icons.building(def.id)
	match def.kind:
		BuildingDef.Kind.PRODUCTION:
			_build_production(record, def)
		BuildingDef.Kind.RESIDENCE:
			_build_house(record)
		BuildingDef.Kind.WAREHOUSE:
			_build_warehouse(record, def)
		_:
			_add_lines(1)
	_add_button("PANEL_MOVE", "action_move", func() -> void: _tool.start_move(record.id))
	if def.kind != BuildingDef.Kind.RESIDENCE:
		_add_button("PANEL_DEMOLISH", "action_demolish", func() -> void:
			_simulation.execute(DemolishCommand.new(record.island_id, Rect2i(record.origin, Vector2i.ONE))))
	_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh()


func _build_warehouse(record: BuildingRecord, def: BuildingDef) -> void:
	_add_lines(6)
	var upgrade := _add_button("PANEL_UPGRADE", "action_upgrade", func() -> void:
		var result := _simulation.execute(UpgradeBuildingCommand.new(record.id))
		if not result.ok():
			_tool.refused.emit(result.reason)
		_refresh())
	upgrade.name = "Upgrade"
	if def.is_trading_post:
		var buy := _add_button("PANEL_BUY_SHIP", "action_buy_ship", func() -> void:
			var result := _simulation.execute(BuyShipCommand.new(record.island_id))
			if not result.ok():
				_tool.refused.emit(result.reason)
			else:
				_tool.select_ship(result.created_id))
		buy.name = "BuyShip"
		buy.tooltip_text = _ship_cost_tip(&"merchant_ship")
		# fragata (Fase 11): navio de guerra, liberado por um marco
		var frigate := _simulation.data.ship(&"frigate")
		if frigate != null:
			var buy_frigate := _add_button("PANEL_BUY_FRIGATE", "action_buy_frigate", func() -> void:
				var result := _simulation.execute(BuyShipCommand.new(record.island_id, &"frigate"))
				if not result.ok():
					_tool.refused.emit(result.reason)
				else:
					_tool.select_ship(result.created_id))
			buy_frigate.name = "BuyFrigate"
			buy_frigate.tooltip_text = tr("PANEL_BUY_FRIGATE_TIP") % [Fmt.integer(frigate.cannons), Fmt.integer(frigate.hull_points)] \
					+ "\n" + _ship_cost_tip(&"frigate")
			if _simulation.world.milestones_reached < frigate.unlock_milestone and not _simulation.free_build:
				buy_frigate.disabled = true
				buy_frigate.tooltip_text += "\n" + tr(PlacementRules.SHIP_LOCKED)
		var trade := _add_button("PANEL_TRADE", "action_trade", func() -> void: trade_requested.emit(record.island_id))
		trade.name = "Trade"


## Custo do navio (moedas e materiais) para a dica do botão de comprar.
func _ship_cost_tip(def_id: StringName) -> String:
	var ship_def := _simulation.data.ship(def_id)
	if ship_def == null:
		return ""
	var cost: PackedStringArray = [tr("TIP_COINS") % Fmt.integer(ship_def.cost_money)]
	for material: StringName in ship_def.cost_materials:
		cost.append("%d %s" % [ship_def.cost_materials[material], tr(_simulation.data.good(material).name_key)])
	return tr("TIP_COST") % ", ".join(cost)


func _build_production(record: BuildingRecord, def: BuildingDef) -> void:
	_add_lines(11 + def.inputs.size())
	for text: String in RatioCalculator.lines(def, _simulation.data):
		var ratio := UiKit.label(text, &"DimLabel")
		ratio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(ratio)
	_pause = _add_button("PANEL_PAUSE", "action_pause", func() -> void:
		_simulation.execute(SetPausedCommand.new(record.id, not _simulation.world.building(record.id).paused))
		_refresh())
	_add_button("PANEL_COPY", "action_copy", func() -> void: _tool.start_building(def))
	if def.is_shipyard():
		_build_shipyard(record, def)
	if _simulation.data.specialists.any(func(specialist: SpecialistDef) -> bool: return specialist.covers(def)):
		var specialists := _add_button("PANEL_SPECIALIST", "action_specialists", func() -> void: specialists_requested.emit(record.id))
		specialists.name = "Specialist"


## Estaleiro: um botão por navio que ele faz e o de cancelar a encomenda.
func _build_shipyard(record: BuildingRecord, def: BuildingDef) -> void:
	for ship_id: StringName in def.shipyard_ships:
		var ship_def := _simulation.data.ship(ship_id)
		var button := UiKit.button(tr("SHIPYARD_ORDER") % tr(ship_def.name_key), "ship_" + ship_id, func() -> void:
			var result := _simulation.execute(ShipyardCommand.order(record.id, ship_id))
			if not result.ok():
				_tool.refused.emit(result.reason)
			_refresh())
		button.name = "Order_" + ship_id
		_buttons.add_child(button)
	var cancel := _add_button("SHIPYARD_CANCEL", "action_close", func() -> void:
		_simulation.execute(ShipyardCommand.cancel_order(record.id))
		_refresh())
	cancel.name = "CancelOrder"


## Estado da encomenda e os botões: desligados com o motivo na dica.
func _refresh_shipyard(record: BuildingRecord, def: BuildingDef) -> String:
	var config := _simulation.config
	var item := _simulation.world.shipyard_state.order(record.id)
	for ship_id: StringName in def.shipyard_ships:
		var button := _buttons.find_child("Order_" + ship_id, false, false) as Button
		if button == null:
			continue
		var ship_def := _simulation.data.ship(ship_id)
		var cost: PackedStringArray = [tr("TIP_COINS") % Fmt.integer(ShipyardSystem.cost_money(ship_def, config))]
		var materials := ShipyardSystem.cost_materials(ship_def, config)
		for material: StringName in materials:
			cost.append("%d %s" % [materials[material], tr(_simulation.data.good(material).name_key)])
		var reason := ShipyardCommand.check(_simulation.world, _simulation.data, config, record.id, ship_id, _simulation.free_build)
		button.disabled = reason != PlacementRules.OK
		button.tooltip_text = tr("SHIPYARD_ORDER_TIP") % [Fmt.decimal(ship_def.build_time_s / 60.0), ", ".join(cost)] \
				+ ("\n" + tr(reason) if reason != PlacementRules.OK else "")
		button.visible = item == null
	var cancel := _buttons.find_child("CancelOrder", false, false) as Button
	if cancel != null:
		cancel.visible = item != null
		if item != null:
			cancel.tooltip_text = tr("SHIPYARD_CANCEL_TIP") % Fmt.integer(floorf(item.paid_money * config.shipyard_cancel_refund))
	if item == null:
		return tr("SHIPYARD_IDLE")
	return tr("SHIPYARD_BUILDING") % [tr(_simulation.data.ship(item.def_id).name_key), Fmt.percent(item.progress)]


func _build_house(record: BuildingRecord) -> void:
	var tier := _simulation.data.tier(record.tier)
	_title_icon.texture = Icons.tier(tier.id)
	_portrait.texture = Icons.portrait("tier_" + tier.id)
	_portrait.visible = _portrait.texture != null
	_add_lines(4)
	for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 6)
		row.add_child(UiKit.icon_rect(Icons.need(need.id), 26))
		var status := UiKit.icon_rect(Icons.status(UiPalette.Status.GOOD), 16)
		status.name = "Status"
		row.add_child(status)
		var label := Label.new()
		row.add_child(label)
		_body.add_child(row)
		_lines.append(label)
	_block = CheckBox.new()
	_block.text = "HOUSE_BLOCK_UPGRADE"
	_block.tooltip_text = "HOUSE_BLOCK_UPGRADE_TIP"
	_block.focus_mode = Control.FOCUS_NONE
	_block.toggled.connect(func(on: bool) -> void: _simulation.execute(SetUpgradeBlockedCommand.new(record.id, on)))
	_buttons.add_child(_block)


func _add_lines(count: int) -> void:
	for i: int in count:
		var label := Label.new()
		_body.add_child(label)
		_lines.append(label)


func _add_button(text_key: String, icon_name: String, action: Callable) -> Button:
	var button := UiKit.button(text_key, icon_name, action, text_key + "_TIP")
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
		BuildingDef.Kind.WAREHOUSE:
			_refresh_warehouse(record, def)
		BuildingDef.Kind.SERVICE:
			_title.text = tr(def.name_key)
			var houses: Array = _simulation.derived_state().service_houses.get(record.id, [])
			_lines[0].text = tr("SERVICE_HOUSES") % Fmt.integer(houses.size())
			if def.protects != BuildingDef.Hazard.NONE:
				var guarded: Array = _simulation.derived_state().protected_by.get(record.id, [])
				_lines[0].text = tr("SERVICE_PROTECTS") % Fmt.integer(guarded.size())
		BuildingDef.Kind.DECORATION:
			_title.text = tr(def.name_key)
			_lines[0].text = tr("DECORATION_HOUSES") % Fmt.integer(DecorationView.houses_near(_simulation, record).size())
		BuildingDef.Kind.PIER:
			_title.text = tr(def.name_key)
			var berths: Array = _simulation.derived_state().berths.get(record.island_id, [])
			var working := berths.has(record.id)
			_lines[0].text = tr("PIER_WORKING") if working else tr("PIER_DISCONNECTED")
			UiPalette.paint(_lines[0], UiPalette.Status.GOOD if working else UiPalette.Status.BAD)
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
	UiPalette.paint(_lines[0], UiPalette.Status.GOOD if state == BuildingRecord.State.PRODUCING \
			else (UiPalette.Status.NEUTRAL if record.paused else UiPalette.Status.BAD))
	if def.is_shipyard() and record.state == BuildingRecord.State.IDLE:
		_lines[0].text = tr("SHIPYARD_IDLE")
		UiPalette.paint(_lines[0], UiPalette.Status.NEUTRAL)
	_lines[1].text = tr("PANEL_PRODUCTIVITY") % Fmt.percent(record.productivity)
	_lines[2].text = tr("PANEL_CYCLE") % Fmt.integer(def.cycle_s)
	var entry := _simulation.derived_state().entry_of(record.id)
	if entry != null and entry.trees >= 0:
		# lenhador no terreno gerado: quantas árvores ele alcança
		_lines[2].text += "  ·  " + tr("PANEL_TREES") % [entry.trees, config.lumberjack_min_trees]
	var index := 3
	for input: StringName in def.inputs:
		var held: float = record.input_buffer.get(input, 0.0)
		_lines[index].text = tr("PANEL_BUFFER") % [tr(data.good(input).name_key), Fmt.decimal(held), config.building_buffer_t]
		index += 1
	_lines[index].text = _output_or_power_text(record, def, entry)
	var workforce := _simulation.world.economy(record.island_id).workforce(def.workforce_tier)
	_lines[index + 1].text = tr("PANEL_WORKERS") % [def.workers, tr(data.tier(def.workforce_tier).name_key), Fmt.percent(workforce)]
	var specialist := _simulation.world.specialists_state.at(record.id)
	var upkeep := Fmt.integer(def.upkeep_per_min * (config.paused_upkeep_factor if record.paused else 1.0)
			* DerivedState.upkeep_factor(specialist))
	# Fase 28: a fábrica ociosa avisa que paga a manutenção inteira por pouco
	if _simulation.is_idle(record):
		_lines[index + 2].text = tr("PANEL_UPKEEP_IDLE") % [upkeep, Fmt.percent(config.paused_upkeep_factor)]
		UiPalette.paint(_lines[index + 2], UiPalette.Status.PARTIAL)
	else:
		_lines[index + 2].text = tr("PANEL_UPKEEP") % upkeep
		UiPalette.unpaint(_lines[index + 2])
	_refresh_logistics(record, index + 3)
	_lines[index + 5].text = _electricity_text(def, entry)
	_lines[index + 5].visible = not _lines[index + 5].text.is_empty()
	if entry != null and entry.powered:
		UiPalette.paint(_lines[index + 5], UiPalette.Status.GOOD)
	else:
		UiPalette.paint(_lines[index + 5], UiPalette.Status.BAD)
	_lines[index + 6].text = tr("PANEL_SPECIALIST_AT") % tr(specialist.def.title_key()) if specialist != null else ""
	_lines[index + 6].visible = specialist != null
	_lines[index + 6].tooltip_text = SpecialistWindow.description_of(specialist.def) if specialist != null else ""
	_lines[index + 6].mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_risks(record, _lines[index + 7])
	if _pause != null:
		_pause.text = tr("PANEL_RESUME") if record.paused else tr("PANEL_PAUSE")
		_pause.icon = Icons.action("play" if record.paused else "pause")


## Buffer de saída; na usina (Fase 11), quantas fábricas ela alcança.
func _output_or_power_text(record: BuildingRecord, def: BuildingDef, entry: DerivedState.ProductionEntry) -> String:
	if def.is_shipyard():
		return _refresh_shipyard(record, def)
	if def.is_power_plant():
		return tr("PANEL_POWER_SUPPLIES") % _simulation.derived_state().powered_by(record.id).size() if entry != null else ""
	return tr("PANEL_BUFFER") % [tr(_simulation.data.good(def.output).name_key), Fmt.decimal(record.output_buffer),
			_simulation.config.building_buffer_t]


## Fábrica (Fase 11): com eletricidade (o bônus), alcançada por usina parada ou fora de alcance.
## Sem usina na ilha a linha some.
func _electricity_text(def: BuildingDef, entry: DerivedState.ProductionEntry) -> String:
	if entry == null or not def.is_electrifiable() or not _simulation.derived_state().has_power_plant(entry.record.island_id):
		return ""
	if entry.powered:
		return tr("PANEL_POWERED") % Fmt.percent(_simulation.config.electricity_bonus)
	return tr("PANEL_POWER_IDLE") if not entry.power_plants.is_empty() else tr("PANEL_UNPOWERED")


## Armazém que atende o prédio e o que a carroça está fazendo.
func _refresh_logistics(record: BuildingRecord, line: int) -> void:
	var derived := _simulation.derived_state()
	var entry := derived.entry_of(record.id)
	if entry == null or _simulation.config.instant_logistics:
		_lines[line].text = ""
		_lines[line + 1].text = ""
		return
	var config := _simulation.config
	if entry.warehouse_id != 0:
		var warehouse := _simulation.world.building(entry.warehouse_id)
		_lines[line].text = tr("PANEL_WAREHOUSE") % [tr(_simulation.def_of(warehouse).name_key), entry.warehouse_distance]
		UiPalette.unpaint(_lines[line])
	elif entry.warehouse_distance >= 0:
		_lines[line].text = tr("PANEL_WAREHOUSE_FAR") % [entry.warehouse_distance, config.logistics_range_cells]
		UiPalette.paint(_lines[line], UiPalette.Status.BAD)
	else:
		_lines[line].text = tr("STATE_NO_WAREHOUSE")
		UiPalette.paint(_lines[line], UiPalette.Status.BAD)
	_lines[line + 1].text = cart_text(_simulation.world.cart(record.id))


func cart_text(cart: Cart) -> String:
	if cart == null:
		return ""
	if cart.blocked:
		return tr("PANEL_CART_BLOCKED")
	var goods := ", ".join(cart.cargo.keys().map(func(good: StringName) -> String:
		return "%s t %s" % [Fmt.decimal(cart.cargo[good]), tr(_simulation.data.good(good).name_key)]))
	match cart.state:
		Cart.State.OUTBOUND:
			if not goods.is_empty():
				return tr("PANEL_CART_OUT") % goods
			return tr("PANEL_CART_OUT_EMPTY") % ", ".join(cart.wanted.keys().map(func(good: StringName) -> String:
				return tr(_simulation.data.good(good).name_key)))
		Cart.State.QUEUED:
			return tr("PANEL_CART_QUEUED")
		Cart.State.AT_RAMP:
			return tr("PANEL_CART_RAMP")
		Cart.State.INBOUND:
			return tr("PANEL_CART_BACK") % goods if not goods.is_empty() else tr("PANEL_CART_BACK_EMPTY")
	return tr("PANEL_CART_HOME")


func _refresh_warehouse(record: BuildingRecord, def: BuildingDef) -> void:
	var derived := _simulation.derived_state()
	_title.text = tr(def.name_key)
	var busy := 0
	var waiting := 0
	for cart: Cart in _simulation.world.carts.values():
		if cart.warehouse_id == record.id:
			if cart.state == Cart.State.AT_RAMP:
				busy += 1
			elif cart.state == Cart.State.QUEUED:
				waiting += 1
	var ramps: int = derived.ramps.get(record.id, 0)
	_lines[0].text = tr("WAREHOUSE_LEVEL") % [record.level + 1, def.levels.size()]
	_lines[1].text = tr("WAREHOUSE_RAMPS") % [busy, ramps, waiting]
	var connected: bool = derived.warehouse_connected.get(record.id, false)
	_lines[2].text = tr("WAREHOUSE_CONNECTED") if connected else tr("WAREHOUSE_DISCONNECTED")
	UiPalette.paint(_lines[2], UiPalette.Status.GOOD if connected else UiPalette.Status.BAD)
	var served := 0
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		if entry.warehouse_id == record.id:
			served += 1
	_lines[3].text = tr("WAREHOUSE_SERVES") % served
	_lines[4].text = tr("WAREHOUSE_CAPACITY") % Fmt.integer(_simulation.storage_capacity(record.island_id)) if def.is_trading_post else ""
	if def.is_trading_post:
		var berths: Array = derived.berths.get(record.island_id, [])
		var docked := 0
		for ship: Ship in _simulation.world.ships.values():
			if ship.state == Ship.State.DOCKED and berths.has(ship.berth_id):
				docked += 1
		_lines[5].text = tr("WAREHOUSE_BERTHS") % [docked, berths.size()]
	else:
		_lines[5].text = ""
	var upgrade := _buttons.get_node_or_null("Upgrade") as Button
	if upgrade != null:
		var next := record.level + 1
		upgrade.disabled = next >= def.levels.size()
		upgrade.tooltip_text = "" if upgrade.disabled else tr("TIP_UPGRADE") % _level_text(def, next)


func _level_text(def: BuildingDef, index: int) -> String:
	var level := def.levels[index]
	var parts: PackedStringArray = [tr("TIP_COINS") % Fmt.integer(level.cost_money)]
	for material: StringName in level.cost_materials:
		parts.append("%d %s" % [level.cost_materials[material], tr(_simulation.data.good(material).name_key)])
	parts.append(tr("TIP_RAMPS") % level.ramps)
	if def.is_trading_post:
		parts.append(tr("TIP_STORAGE") % level.storage_capacity_t)
	return ", ".join(parts)


func _refresh_house(record: BuildingRecord) -> void:
	var data := _simulation.data
	var config := _simulation.config
	var world := _simulation.world
	var derived := _simulation.derived_state()
	var tier := data.tier(record.tier)
	_title.text = tr("HOUSE_TITLE") % tr(tier.name_key)
	_lines[0].text = tr("HOUSE_RESIDENTS") % [floori(record.residents), tier.residents_per_house]
	var beauty: float = derived.beauty.get(record.id, 0.0)
	_lines[1].text = tr("HOUSE_HAPPINESS") % roundi(record.happiness) \
			+ ("  ·  " + tr("HOUSE_BEAUTY") % Fmt.percent(beauty) if beauty > 0.0 else "") \
			+ ("  ·  " + tr("STATE_PROTEST") if record.happiness < config.protest_happiness_threshold else "")
	if record.happiness < config.protest_happiness_threshold:
		UiPalette.paint(_lines[1], UiPalette.Status.BAD)
	else:
		UiPalette.unpaint(_lines[1])
	var burning := world.risks_state.is_burning(record.id)
	_lines[2].text = tr("HOUSE_TAX") % Fmt.decimal(0.0 if burning else HouseNeeds.tax_per_min(world, data, config, derived, record))
	_refresh_risks(record, _lines[3])
	var index := 4
	for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
		var value := HouseNeeds.satisfaction(world, derived, record, need)
		var luxury := tier.luxury_needs.has(need)
		_lines[index].text = "%s%s  %s" % [tr(need.name_key), " (" + tr("HOUSE_LUXURY") + ")" if luxury else "", Fmt.percent(value)]
		var status := UiPalette.status_of(value, config.need_met_threshold, config.need_partial_threshold)
		UiPalette.paint(_lines[index], status)
		var marker := _lines[index].get_parent().get_node("Status") as TextureRect
		marker.texture = Icons.status(status)
		marker.modulate = UiPalette.status(status)
		index += 1
	if _block != null:
		_block.set_pressed_no_signal(record.upgrade_blocked)


## Linha dos riscos (com eles ligados): em chamas ou doente, em vermelho; senão, se o prédio está
## no raio dos bombeiros (e a casa, no do hospital).
func _refresh_risks(record: BuildingRecord, line: Label) -> void:
	var risks := _simulation.world.risks_state
	line.visible = risks.enabled
	if not risks.enabled:
		return
	var derived := _simulation.derived_state()
	if risks.is_burning(record.id):
		var config := _simulation.config
		var burning_s := float(_simulation.world.tick - risks.fires[record.id]) / config.ticks_per_second
		var protected := derived.fire_protected.has(record.id)
		var left := (config.fire_extinguish_s if protected else config.fire_burnout_s) - burning_s
		line.text = tr("RISK_FIRE_OUT_IN" if protected else "RISK_FIRE_LOST_IN") % Fmt.integer(maxf(left, 0.0))
		if record.is_house():
			line.text = tr("HOUSE_ON_FIRE") + "  ·  " + line.text
		UiPalette.paint(line, UiPalette.Status.PARTIAL if protected else UiPalette.Status.BAD)
		return
	if risks.is_sick(record.id):
		line.text = tr("HOUSE_SICK")
		UiPalette.paint(line, UiPalette.Status.BAD)
		return
	var fire := derived.fire_protected.has(record.id)
	var parts: PackedStringArray = [tr("HOUSE_FIRE_PROTECTION") % tr("RISK_COVERED" if fire else "RISK_UNCOVERED")]
	var covered := fire
	if record.is_house():
		var health := derived.health_protected.has(record.id)
		parts.append(tr("HOUSE_HEALTH_PROTECTION") % tr("RISK_COVERED" if health else "RISK_UNCOVERED"))
		covered = covered and health
	line.text = "  ·  ".join(parts)
	UiPalette.paint(line, UiPalette.Status.GOOD if covered else UiPalette.Status.PARTIAL)


## Estado para mostrar: entre um ciclo e o próximo o prédio passa um tick "sem entrada" sem
## perder tempo; só vale como parado quando a produtividade média cai.
static func shown_state(record: BuildingRecord) -> BuildingRecord.State:
	if record.paused or record.state in [BuildingRecord.State.NO_ROAD, BuildingRecord.State.NO_MODULES, BuildingRecord.State.NO_WAREHOUSE,
			BuildingRecord.State.NO_TREES, BuildingRecord.State.ON_FIRE]:
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
		BuildingRecord.State.NO_WAREHOUSE:
			return "STATE_NO_WAREHOUSE"
		BuildingRecord.State.NO_TREES:
			return "STATE_NO_TREES"
		BuildingRecord.State.ON_FIRE:
			return "STATE_ON_FIRE"
	return "STATE_IDLE"
