class_name RouteWindow
extends PanelContainer
## Rotas comerciais (seção 6 e 10): a lista de rotas, as paradas da escolhida (ilha ou posto do
## comerciante) com as ordens de carga de cada uma, os navios que fazem a rota e o mapa do
## arquipélago. Cada mudança vira um EditRouteCommand; a janela guarda uma cópia das paradas para
## não refazer os campos enquanto o jogador digita.

const MAX_TONS := 200
const MAP_REFRESH_SECONDS := 0.5

var map := ArchipelagoMap.new()

var _simulation: Simulation
var _tool: BuildTool
var _routes := ItemList.new()
var _stops := VBoxContainer.new()
var _ships := VBoxContainer.new()
var _editor := VBoxContainer.new()
var _route_id: int = 0
var _working: Array[TradeRoute.Stop] = []
var _map_left: float = 0.0


func setup(simulation: Simulation, tool: BuildTool) -> void:
	_simulation = simulation
	_tool = tool
	visible = false
	add_theme_stylebox_override(&"panel", UiStyle.panel())
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "ROUTES_TITLE"
	title.add_theme_font_size_override(&"font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_button("STATS_CLOSE", func() -> void: visible = false))
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 14)
	column.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 160
	body.add_child(left)
	_routes.custom_minimum_size = Vector2(160, 220)
	_routes.focus_mode = Control.FOCUS_NONE
	_routes.item_selected.connect(func(index: int) -> void:
		var picked: int = _routes.get_item_metadata(index)
		select_route(picked))
	left.add_child(_routes)
	var new_route := _button("ROUTES_NEW", create_route)
	new_route.name = "NewRoute"
	left.add_child(new_route)
	left.add_child(_button("ROUTES_DELETE", func() -> void:
		if _route_id != 0:
			_simulation.execute(DeleteRouteCommand.new(_route_id))))
	_editor.custom_minimum_size.x = 470
	body.add_child(_editor)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(_stops)
	_stops.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.add_child(scroll)
	var add_stop := _button("ROUTES_ADD_STOP", add_stop_to_route)
	add_stop.name = "AddStop"
	_editor.add_child(add_stop)
	var ships_title := Label.new()
	ships_title.text = "ROUTES_SHIPS"
	ships_title.modulate = Color(1, 1, 1, 0.6)
	_editor.add_child(ships_title)
	_editor.add_child(_ships)
	map.setup(simulation)
	body.add_child(map)
	EventBus.routes_changed.connect(_on_routes_changed)
	EventBus.ships_changed.connect(_fill_ships)
	EventBus.world_replaced.connect(func() -> void:
		_route_id = 0
		_on_routes_changed())
	_on_routes_changed()


func toggle() -> void:
	visible = not visible
	if visible:
		_on_routes_changed()


func _process(delta: float) -> void:
	if not visible:
		return
	_map_left -= delta
	if _map_left <= 0.0:
		_map_left = MAP_REFRESH_SECONDS
		map.queue_redraw()


func create_route() -> void:
	var result := _simulation.execute(CreateRouteCommand.new())
	select_route(result.created_id)


func select_route(route_id: int) -> void:
	_route_id = route_id
	map.route_id = route_id
	var route: TradeRoute = _simulation.world.routes.get(route_id)
	_working.clear()
	if route != null:
		for stop: TradeRoute.Stop in route.stops:
			_working.append(stop.duplicate())
	_fill_list()
	_build_stops()
	_fill_ships()
	map.queue_redraw()


## Parada nova: a ilha principal, ou a próxima ilha com entreposto depois da última parada.
func add_stop_to_route() -> void:
	if _route_id == 0:
		return
	var colonized := _simulation.world.colonized_islands(_simulation.data)
	var target := colonized[0] if not colonized.is_empty() else 0
	if not _working.is_empty():
		var last := colonized.find(_working[_working.size() - 1].target)
		target = colonized[(last + 1) % colonized.size()] if not colonized.is_empty() else 0
	_working.append(TradeRoute.Stop.new(target))
	_commit()
	_build_stops()


## Paradas da janela: alvo e ordens; o que mudou vai para a simulação.
func stops() -> Array[TradeRoute.Stop]:
	return _working


func _commit() -> void:
	if _route_id == 0:
		return
	var result := _simulation.execute(EditRouteCommand.new(_route_id, _working))
	if not result.ok():
		_tool.refused.emit(result.reason)
	map.queue_redraw()


func _on_routes_changed() -> void:
	if not _simulation.world.routes.has(_route_id):
		_route_id = 0
		_working.clear()
		map.route_id = 0
		_build_stops()
	_fill_list()
	_fill_ships()


func _fill_list() -> void:
	_routes.clear()
	for route_id: int in _simulation.world.route_ids():
		var index := _routes.add_item(tr("ROUTE_NAME") % route_id)
		_routes.set_item_metadata(index, route_id)
		if route_id == _route_id:
			_routes.select(index)
	_editor.visible = _route_id != 0


func _build_stops() -> void:
	for child: Node in _stops.get_children():
		# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
		child.get_parent().remove_child(child)
		child.queue_free()
	for index: int in _working.size():
		_stops.add_child(_stop_box(index))


func _stop_box(index: int) -> Control:
	var stop := _working[index]
	var box := VBoxContainer.new()
	box.name = "Stop%d" % index
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := Label.new()
	label.text = tr("ROUTES_STOP") % (index + 1)
	row.add_child(label)
	var target := OptionButton.new()
	target.name = "Target"
	target.focus_mode = Control.FOCUS_NONE
	target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for island_id: int in _simulation.world.islands.size():
		var suffix := "" if _simulation.world.has_trading_post(island_id, _simulation.data) else " — " + tr("ROUTES_NO_PORT")
		target.add_item(Fmt.place(island_id) + suffix, island_id)
	target.add_item(Fmt.place(Ship.TRADER_POST), target.item_count)
	target.set_item_metadata(target.item_count - 1, Ship.TRADER_POST)
	for item: int in target.item_count - 1:
		target.set_item_metadata(item, item)
	for item: int in target.item_count:
		var value: int = target.get_item_metadata(item)
		if value == stop.target:
			target.select(item)
	target.item_selected.connect(func(item: int) -> void:
		stop.target = target.get_item_metadata(item)
		_commit())
	row.add_child(target)
	row.add_child(_button("ROUTES_REMOVE", func() -> void:
		_working.remove_at(_working.find(stop))
		_commit()
		_build_stops()))
	for order: TradeRoute.Order in stop.orders:
		box.add_child(_order_row(stop, order))
	var add_order := _button("ROUTES_ADD_ORDER", func() -> void:
		stop.orders.append(TradeRoute.Order.new(_simulation.data.goods[0].id, true, 50))
		_commit()
		_build_stops())
	add_order.name = "AddOrder"
	box.add_child(add_order)
	box.add_child(HSeparator.new())
	return box


func _order_row(stop: TradeRoute.Stop, order: TradeRoute.Order) -> Control:
	var row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 24
	row.add_child(spacer)
	var action := OptionButton.new()
	action.focus_mode = Control.FOCUS_NONE
	action.add_item(tr("ROUTES_LOAD"))
	action.add_item(tr("ROUTES_UNLOAD"))
	action.select(0 if order.is_load else 1)
	action.item_selected.connect(func(item: int) -> void:
		order.is_load = item == 0
		_commit())
	row.add_child(action)
	var good := OptionButton.new()
	good.focus_mode = Control.FOCUS_NONE
	good.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index: int in _simulation.data.goods.size():
		var def := _simulation.data.goods[index]
		good.add_item(tr(def.name_key))
		good.set_item_metadata(index, def.id)
		if def.id == order.good:
			good.select(index)
	good.item_selected.connect(func(item: int) -> void:
		order.good = good.get_item_metadata(item)
		_commit())
	row.add_child(good)
	var tons := SpinBox.new()
	tons.min_value = 1
	tons.max_value = MAX_TONS
	# passo de 1 (senão 50 vira 51 a partir do mínimo 1); as setas andam de 5 em 5
	tons.step = 1
	tons.custom_arrow_step = 5
	tons.value = order.tons
	tons.suffix = "t"
	tons.value_changed.connect(func(value: float) -> void:
		order.tons = roundi(value)
		_commit())
	row.add_child(tons)
	row.add_child(_button("ROUTES_REMOVE_ORDER", func() -> void:
		stop.orders.erase(order)
		_commit()
		_build_stops()))
	return row


## Uma caixa por navio do jogador: marcada, ele faz esta rota.
func _fill_ships() -> void:
	for child: Node in _ships.get_children():
		# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
		child.get_parent().remove_child(child)
		child.queue_free()
	if _route_id == 0:
		return
	for ship: Ship in _simulation.world.player_ships():
		var check := CheckBox.new()
		check.focus_mode = Control.FOCUS_NONE
		var other := "" if ship.route_id == 0 or ship.route_id == _route_id else " (" + tr("ROUTE_NAME") % ship.route_id + ")"
		check.text = tr("SHIP_TITLE") % [tr(_simulation.data.ship(ship.def_id).name_key), ship.id] + other
		check.button_pressed = ship.route_id == _route_id
		var ship_id := ship.id
		check.toggled.connect(func(on: bool) -> void:
			_simulation.execute(SetShipRouteCommand.new(ship_id, _route_id if on else 0)))
		_ships.add_child(check)


static func _button(text_key: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_key
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
