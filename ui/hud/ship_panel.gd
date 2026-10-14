class_name ShipPanel
extends PanelContainer
## Painel do navio selecionado (Fase 6): estado, onde está, porão por compartimento e a rota.
## Botões: navegar para (escolher no mapa), a rota (lista) e, parado num porto do jogador, a carga
## à mão; parado no posto do comerciante, comprar e vender. Só chama comandos.

const REFRESH_SECONDS := 0.25
## Toneladas de cada clique de carga, compra ou venda.
const STEP_T := 10.0

## O jogador pediu para a câmera ir até o navio.
signal center_requested()

var _tool: BuildTool
var _simulation: Simulation
var _title := Label.new()
var _icon := TextureRect.new()
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
	custom_minimum_size.x = 360
	var column := VBoxContainer.new()
	add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 8)
	column.add_child(head)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(44, 44)
	head.add_child(_icon)
	_title.theme_type_variation = &"HeaderLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	head.add_child(UiKit.icon_button("action_center", "INFO_CENTER_HINT", func() -> void: center_requested.emit()))
	head.add_child(UiKit.icon_button("action_close", "UI_CLOSE", func() -> void: tool.select_ship(0)))
	column.add_child(_state)
	column.add_child(UiKit.label("SHIP_HOLD", &"DimLabel"))
	column.add_child(_hold)
	var route_row := HBoxContainer.new()
	column.add_child(route_row)
	route_row.add_child(UiKit.icon_rect(Icons.action("routes"), 24))
	route_row.add_child(UiKit.label("SHIP_ROUTE"))
	_route.tooltip_text = "SHIP_ROUTE_TIP"
	_route.focus_mode = Control.FOCUS_NONE
	_route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_route.item_selected.connect(_on_route_selected)
	route_row.add_child(_route)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	var sail := _button("SHIP_SAIL_TO", "action_sail_to", func() -> void: tool.start_sail_to())
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
	_icon.texture = Icons.get_icon("ship_" + def.id)
	_state.text = state_text(ship)
	var lines := _hold.get_children()
	while lines.size() < ship.slot_goods.size():
		var row := UiKit.icon_line(Icons.get_icon("hud_storage"), "", 22)
		_hold.add_child(row)
		lines.append(row)
	for slot: int in ship.slot_goods.size():
		var row: HBoxContainer = lines[slot]
		var label: Label = row.get_child(1)
		var good := ship.slot_goods[slot]
		var slot_icon: TextureRect = row.get_child(0)
		slot_icon.texture = Icons.get_icon("hud_storage") if good == &"" else Icons.good(good)
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
	# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
	UiKit.clear(_actions)
	if ship.state != Ship.State.IDLE or ship.route_id != 0 or ship.at == Ship.NOWHERE:
		return
	if ship.at == Ship.TRADER_POST:
		_build_trader_actions(ship)
	elif _simulation.world.has_trading_post(ship.at, _simulation.data):
		_build_port_actions(ship)


func _build_port_actions(ship: Ship) -> void:
	_actions.add_child(UiKit.label("SHIP_PORT_CARGO", &"DimLabel"))
	for good: StringName in ship.goods():
		var row := UiKit.icon_line(Icons.good(good), tr(_simulation.data.good(good).name_key))
		_actions.add_child(row)
		var unload := _button("SHIP_UNLOAD_ALL", "action_unload_cargo", func() -> void: _run(TransferCargoCommand.new(ship.id, good, -ship.tons_of(good))))
		row.add_child(unload)
	var load_row := HBoxContainer.new()
	_actions.add_child(load_row)
	var goods := OptionButton.new()
	goods.focus_mode = Control.FOCUS_NONE
	goods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var economy := _simulation.world.economy(ship.at)
	for good_def: GoodDef in _simulation.data.goods:
		if economy.amount(good_def.id) >= 1.0:
			goods.add_icon_item(Icons.good(good_def.id), "%s (%s t)" % [tr(good_def.name_key), Fmt.integer(economy.amount(good_def.id))])
			goods.set_item_metadata(goods.item_count - 1, good_def.id)
	load_row.add_child(goods)
	var load_button := _button("SHIP_LOAD_STEP", "action_load_cargo", func() -> void:
		if goods.selected >= 0:
			var good: StringName = goods.get_item_metadata(goods.selected)
			_run(TransferCargoCommand.new(ship.id, good, STEP_T)))
	load_button.disabled = goods.item_count == 0
	load_row.add_child(load_button)


func _build_trader_actions(ship: Ship) -> void:
	var trader := _simulation.data.trader()
	if trader == null:
		return
	var head := HBoxContainer.new()
	head.add_child(UiKit.icon_rect(Icons.portrait("trader"), 48))
	head.add_child(UiKit.label("SHIP_TRADER_DEALS", &"DimLabel"))
	_actions.add_child(head)
	var goods: Array[StringName] = trader.sells.duplicate()
	for good: StringName in trader.buys:
		if not goods.has(good):
			goods.append(good)
	for good: StringName in goods:
		var row := HBoxContainer.new()
		_actions.add_child(row)
		var price := TraderState.price(_simulation.world.seed, _simulation.world.trader.tour, _simulation.data.good(good),
				_simulation.config.trader_price_variation)
		row.add_child(UiKit.icon_rect(Icons.good(good), 24))
		var label := Label.new()
		label.text = tr("TRADE_GOOD_PRICE") % [tr(_simulation.data.good(good).name_key), Fmt.integer(price)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if trader.sells.has(good):
			row.add_child(_button("TRADE_BUY_STEP", "action_buy", func() -> void: _run(TradeWithTraderCommand.new(ship.id, good, STEP_T))))
		if trader.buys.has(good) and ship.tons_of(good) > 0.0:
			row.add_child(_button("TRADE_SELL_STEP", "action_sell", func() -> void: _run(TradeWithTraderCommand.new(ship.id, good, -STEP_T))))


func _run(command: Command) -> void:
	var result := _simulation.execute(command)
	if not result.ok():
		_tool.refused.emit(result.reason)
	_actions_key = ""
	_refresh()


static func _button(text_key: String, icon_name: String, action: Callable) -> Button:
	return UiKit.button(text_key, icon_name, action, text_key + "_TIP")
