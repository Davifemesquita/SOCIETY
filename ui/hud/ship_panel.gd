class_name ShipPanel
extends PanelContainer
## Painel do navio selecionado (Fase 6): estado, onde está, porão por compartimento e a rota.
## Botões: navegar para (escolher no mapa), a rota (lista) e, parado num porto do jogador, a carga
## à mão; parado no posto do comerciante, comprar e vender. Só chama comandos.

const REFRESH_SECONDS := 0.25
## Toneladas de cada clique de carga, compra ou venda.
const STEP_T := 10.0

var _tool: BuildTool
var _simulation: Simulation
var _title := Label.new()
var _state := Label.new()
var _hold := VBoxContainer.new()
var _route := OptionButton.new()
var _actions := VBoxContainer.new()
var _refresh_left: float = 0.0
var _ship_id: int = 0
## Para refazer as linhas de ação só quando o lugar ou o estado muda.
var _actions_key: String = ""


func setup(tool: BuildTool, simulation: Simulation) -> void:
	_tool = tool
	_simulation = simulation
	custom_minimum_size.x = 340
	add_theme_stylebox_override(&"panel", UiStyle.panel())
	var column := VBoxContainer.new()
	add_child(column)
	_title.add_theme_font_size_override(&"font_size", 20)
	column.add_child(_title)
	column.add_child(_state)
	var hold_title := Label.new()
	hold_title.text = "SHIP_HOLD"
	hold_title.modulate = Color(1, 1, 1, 0.6)
	column.add_child(hold_title)
	column.add_child(_hold)
	var route_row := HBoxContainer.new()
	column.add_child(route_row)
	var route_label := Label.new()
	route_label.text = "SHIP_ROUTE"
	route_row.add_child(route_label)
	_route.focus_mode = Control.FOCUS_NONE
	_route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_route.item_selected.connect(_on_route_selected)
	route_row.add_child(_route)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	var sail := _button("SHIP_SAIL_TO", func() -> void: tool.start_sail_to())
	sail.name = "SailTo"
	buttons.add_child(sail)
	column.add_child(_actions)
	tool.ship_selection_changed.connect(show_ship)
	EventBus.routes_changed.connect(func() -> void: _fill_routes())
	EventBus.ships_changed.connect(func() -> void: _actions_key = "")
	show_ship(0)


func show_ship(ship_id: int) -> void:
	_ship_id = ship_id
	visible = _simulation.world.ship(ship_id) != null
	_actions_key = ""
	if visible:
		_fill_routes()
		_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh()


func _refresh() -> void:
	var ship := _simulation.world.ship(_ship_id)
	if ship == null:
		visible = false
		return
	var def := _simulation.data.ship(ship.def_id)
	_title.text = tr("SHIP_TITLE") % [tr(def.name_key), ship.id]
	_state.text = state_text(ship)
	var lines := _hold.get_children()
	while lines.size() < ship.slot_goods.size():
		var label := Label.new()
		_hold.add_child(label)
		lines.append(label)
	for slot: int in ship.slot_goods.size():
		var label: Label = lines[slot]
		var good := ship.slot_goods[slot]
		label.text = tr("SHIP_SLOT_EMPTY") % [slot + 1, def.slot_capacity_t] if good == &"" \
				else tr("SHIP_SLOT") % [slot + 1, tr(_simulation.data.good(good).name_key), Fmt.decimal(ship.slot_tons[slot]), def.slot_capacity_t]
	var key := "%d/%d/%d/%d" % [ship.state, ship.at, ship.route_id, ship.goods().size()]
	if key != _actions_key:
		_actions_key = key
		_build_actions(ship)


## Frase do estado: navegando para, esperando vaga, no cais, ancorado.
func state_text(ship: Ship) -> String:
	match ship.state:
		Ship.State.SAILING:
			return tr("SHIP_SAILING") % Fmt.place(ship.destination)
		Ship.State.WAITING:
			return tr("SHIP_WAITING") % Fmt.place(ship.at)
		Ship.State.DOCKED:
			return tr("SHIP_DOCKED") % [Fmt.place(ship.at), Fmt.integer(maxf(ship.timer, 0.0))]
	return tr("SHIP_ANCHORED") % Fmt.place(ship.at) if ship.at != Ship.NOWHERE else tr("SHIP_AT_SEA")


func _fill_routes() -> void:
	var ship := _simulation.world.ship(_ship_id)
	_route.clear()
	_route.add_item(tr("SHIP_NO_ROUTE"), 0)
	for route_id: int in _simulation.world.route_ids():
		_route.add_item(tr("ROUTE_NAME") % route_id, route_id)
	if ship != null:
		_route.select(maxi(0, _route.get_item_index(ship.route_id)))


func _on_route_selected(index: int) -> void:
	var result := _simulation.execute(SetShipRouteCommand.new(_ship_id, _route.get_item_id(index)))
	if not result.ok():
		_tool.refused.emit(result.reason)


## Ações do lugar: carga à mão no porto do jogador, compra e venda no comerciante.
func _build_actions(ship: Ship) -> void:
	for child: Node in _actions.get_children():
		# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
		child.get_parent().remove_child(child)
		child.queue_free()
	if ship.state != Ship.State.IDLE or ship.route_id != 0 or ship.at == Ship.NOWHERE:
		return
	if ship.at == Ship.TRADER_POST:
		_build_trader_actions(ship)
	elif _simulation.world.has_trading_post(ship.at, _simulation.data):
		_build_port_actions(ship)


func _build_port_actions(ship: Ship) -> void:
	var title := Label.new()
	title.text = "SHIP_PORT_CARGO"
	title.modulate = Color(1, 1, 1, 0.6)
	_actions.add_child(title)
	for good: StringName in ship.goods():
		var row := HBoxContainer.new()
		_actions.add_child(row)
		var label := Label.new()
		label.text = tr(_simulation.data.good(good).name_key)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var unload := _button("SHIP_UNLOAD_ALL", func() -> void: _run(TransferCargoCommand.new(ship.id, good, -ship.tons_of(good))))
		row.add_child(unload)
	var load_row := HBoxContainer.new()
	_actions.add_child(load_row)
	var goods := OptionButton.new()
	goods.focus_mode = Control.FOCUS_NONE
	goods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var economy := _simulation.world.economy(ship.at)
	for good_def: GoodDef in _simulation.data.goods:
		if economy.amount(good_def.id) >= 1.0:
			goods.add_item("%s (%s t)" % [tr(good_def.name_key), Fmt.integer(economy.amount(good_def.id))])
			goods.set_item_metadata(goods.item_count - 1, good_def.id)
	load_row.add_child(goods)
	var load_button := _button("SHIP_LOAD_STEP", func() -> void:
		if goods.selected >= 0:
			var good: StringName = goods.get_item_metadata(goods.selected)
			_run(TransferCargoCommand.new(ship.id, good, STEP_T)))
	load_button.disabled = goods.item_count == 0
	load_row.add_child(load_button)


func _build_trader_actions(ship: Ship) -> void:
	var trader := _simulation.data.trader()
	if trader == null:
		return
	var title := Label.new()
	title.text = "SHIP_TRADER_DEALS"
	title.modulate = Color(1, 1, 1, 0.6)
	_actions.add_child(title)
	var goods: Array[StringName] = trader.sells.duplicate()
	for good: StringName in trader.buys:
		if not goods.has(good):
			goods.append(good)
	for good: StringName in goods:
		var row := HBoxContainer.new()
		_actions.add_child(row)
		var price := TraderState.price(_simulation.world.seed, _simulation.world.trader.tour, _simulation.data.good(good),
				_simulation.config.trader_price_variation)
		var label := Label.new()
		label.text = tr("TRADE_GOOD_PRICE") % [tr(_simulation.data.good(good).name_key), Fmt.integer(price)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if trader.sells.has(good):
			row.add_child(_button("TRADE_BUY_STEP", func() -> void: _run(TradeWithTraderCommand.new(ship.id, good, STEP_T))))
		if trader.buys.has(good) and ship.tons_of(good) > 0.0:
			row.add_child(_button("TRADE_SELL_STEP", func() -> void: _run(TradeWithTraderCommand.new(ship.id, good, -STEP_T))))


func _run(command: Command) -> void:
	var result := _simulation.execute(command)
	if not result.ok():
		_tool.refused.emit(result.reason)
	_actions_key = ""
	_refresh()


static func _button(text_key: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_key
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
