class_name RouteWindow
extends PanelContainer
## Rotas comerciais (seção 6 e 10): a lista de rotas, as paradas da escolhida (ilha ou posto do
## comerciante) com as ordens de carga de cada uma, os navios que fazem a rota e o mapa do
## arquipélago. Cada mudança vira um EditRouteCommand; a janela guarda uma cópia das paradas para
## não refazer os campos enquanto o jogador digita. Fase 47: duplicar a rota (os comandos que já existem), Shift ao
## pôr uma ordem enche a vaga do navio, o mouse sobre uma rota da lista a destaca no mapa, e o filtro por ilha fica
## guardado nas opções (Settings.route_filter). Nome e grupo da rota pedem campo novo no save: ficam para a Fase 49.

const MAX_TONS := 200
const MAP_REFRESH_SECONDS := 0.5

var map := ArchipelagoMap.new()

var _simulation: Simulation
var _tool: BuildTool
var _routes := ItemList.new()
var _filter := OptionButton.new()
## Fase 49: nome e grupo da rota escolhida.
var _name := LineEdit.new()
var _group := LineEdit.new()
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
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	column.add_child(UiKit.header("ROUTES_TITLE", func() -> void: visible = false))
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 14)
	column.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 160
	body.add_child(left)
	_filter.name = "RouteFilter"
	_filter.focus_mode = Control.FOCUS_NONE
	_filter.tooltip_text = "ROUTES_FILTER_TIP"
	_filter.item_selected.connect(func(index: int) -> void:
		Settings.route_filter = _filter.get_item_id(index) - 1
		Settings.save()
		_fill_list())
	left.add_child(_filter)
	_routes.custom_minimum_size = Vector2(160, 220)
	_routes.focus_mode = Control.FOCUS_NONE
	_routes.fixed_icon_size = Vector2i(24, 24)
	_routes.item_selected.connect(func(index: int) -> void:
		var picked: int = _routes.get_item_metadata(index)
		select_route(picked))
	# o mouse sobre uma rota da lista a destaca no mapa (sem escolher)
	_routes.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var motion: InputEventMouseMotion = event
			hover_route(route_at(motion.position)))
	_routes.mouse_exited.connect(func() -> void: hover_route(0))
	left.add_child(_routes)
	var new_route := _button("ROUTES_NEW", "action_add", create_route)
	new_route.name = "NewRoute"
	left.add_child(new_route)
	var copy_route := _button("ROUTES_DUPLICATE", "action_copy", duplicate_route)
	copy_route.name = "DuplicateRoute"
	left.add_child(copy_route)
	left.add_child(_button("ROUTES_DELETE", "action_delete", func() -> void:
		if _route_id != 0:
			_simulation.execute(DeleteRouteCommand.new(_route_id))))
	_editor.custom_minimum_size.x = 470
	body.add_child(_editor)
	var naming := HBoxContainer.new()
	naming.add_theme_constant_override(&"separation", 6)
	_editor.add_child(naming)
	for pair: Array in [[_name, "RouteName", "ROUTES_NAME"], [_group, "RouteGroup", "ROUTES_GROUP"]]:
		var field: LineEdit = pair[0]
		var field_name: String = pair[1]
		var key: String = pair[2]
		field.name = field_name
		field.placeholder_text = key
		field.tooltip_text = key + "_TIP"
		field.max_length = RenameRouteCommand.MAX_LENGTH
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		field.text_submitted.connect(func(_text: String) -> void: rename_route(_name.text, _group.text))
		field.focus_exited.connect(func() -> void: rename_route(_name.text, _group.text))
		naming.add_child(field)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(_stops)
	_stops.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.add_child(scroll)
	var add_stop := _button("ROUTES_ADD_STOP", "action_add", add_stop_to_route)
	add_stop.name = "AddStop"
	_editor.add_child(add_stop)
	_editor.add_child(UiKit.label("ROUTES_SHIPS", &"DimLabel"))
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


## Nome e grupo da rota escolhida (Fase 49); sem mudança, nada.
func rename_route(route_name: String, route_group: String) -> void:
	var route: TradeRoute = _simulation.world.routes.get(_route_id)
	if route == null or (route.name == route_name.strip_edges() and route.group == route_group.strip_edges()):
		return
	_simulation.execute(RenameRouteCommand.new(_route_id, route_name, route_group))


## O que a lista mostra: o nome dado (ou "Rota N"), com o grupo na frente.
static func display_name(route: TradeRoute) -> String:
	var shown := route.name if route.name != "" else TranslationServer.translate("ROUTE_NAME") % route.id
	return ("[%s] %s" % [route.group, shown]) if route.group != "" else shown


## As rotas na ordem da lista: por grupo (sem grupo por último) e depois por id.
static func ordered(world: WorldState) -> Array[int]:
	var ids := world.route_ids()
	ids.sort_custom(func(a: int, b: int) -> bool:
		var group_a := world.routes[a].group
		var group_b := world.routes[b].group
		if group_a != group_b:
			return group_b == "" or (group_a != "" and group_a < group_b)
		return a < b)
	return ids


## Duplica a rota escolhida (Fase 47): uma rota nova com cópias das paradas e das ordens (sem os navios).
func duplicate_route() -> void:
	var route: TradeRoute = _simulation.world.routes.get(_route_id)
	if route == null:
		return
	var copies: Array[TradeRoute.Stop] = []
	for stop: TradeRoute.Stop in route.stops:
		copies.append(stop.duplicate())
	var created := _simulation.execute(CreateRouteCommand.new()).created_id
	_simulation.execute(EditRouteCommand.new(created, copies))
	select_route(created)


## A rota sob o ponto da lista (0 se nenhuma).
func route_at(point: Vector2) -> int:
	var index := _routes.get_item_at_position(point, true)
	if index < 0:
		return 0
	var route_id: int = _routes.get_item_metadata(index)
	return route_id


func hover_route(route_id: int) -> void:
	if map.hover_route_id != route_id:
		map.hover_route_id = route_id
		map.queue_redraw()


## Toneladas de uma vaga cheia: a menor vaga dos navios da rota (cabe em todos), ou a do navio mercante.
func slot_tons() -> int:
	var tons := 0
	for ship: Ship in _simulation.world.player_ships():
		if ship.route_id == _route_id and _route_id != 0:
			var capacity := _simulation.data.ship(ship.def_id).slot_capacity_t
			tons = capacity if tons == 0 else mini(tons, capacity)
	if tons == 0:
		var merchant := _simulation.data.ship(&"merchant_ship")
		tons = merchant.slot_capacity_t if merchant != null else 50
	return clampi(tons, 1, MAX_TONS)


## Uma ordem nova na parada; "full" (Shift no botão) enche a vaga do navio.
func add_order(stop: TradeRoute.Stop, full: bool) -> void:
	stop.orders.append(TradeRoute.Order.new(_simulation.data.goods[0].id, true, slot_tons() if full else 50))
	_commit()
	_build_stops()


func select_route(route_id: int) -> void:
	_route_id = route_id
	map.route_id = route_id
	var route: TradeRoute = _simulation.world.routes.get(route_id)
	_working.clear()
	_name.text = route.name if route != null else ""
	_group.text = route.group if route != null else ""
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
	_fill_filter()
	_routes.clear()
	for route_id: int in ordered(_simulation.world):
		if not passes_filter(_simulation.world.routes[route_id], Settings.route_filter):
			continue
		var index := _routes.add_item(display_name(_simulation.world.routes[route_id]), Icons.action("routes"))
		_routes.set_item_metadata(index, route_id)
		if route_id == _route_id:
			_routes.select(index)
	_editor.visible = _route_id != 0


## O filtro da lista: todas as ilhas (-1) ou a rota passa pela ilha.
static func passes_filter(route: TradeRoute, island_id: int) -> bool:
	if island_id < 0:
		return true
	for stop: TradeRoute.Stop in route.stops:
		if stop.target == island_id:
			return true
	return false


## "Todas" e as ilhas com entreposto (o id do item é a ilha + 1); a escolha guardada fica marcada.
func _fill_filter() -> void:
	_filter.clear()
	_filter.add_item(tr("ROUTES_FILTER_ALL"), 0)
	for island_id: int in _simulation.world.islands.size():
		if _simulation.world.has_trading_post(island_id, _simulation.data) or island_id == Settings.route_filter:
			_filter.add_item(Fmt.place(island_id), island_id + 1)
	var at := _filter.get_item_index(Settings.route_filter + 1)
	_filter.select(at if at >= 0 else 0)


func _build_stops() -> void:
	# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
	UiKit.clear(_stops)
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
	row.add_child(_icon_button("action_delete", "ROUTES_REMOVE", func() -> void:
		_working.remove_at(_working.find(stop))
		_commit()
		_build_stops()))
	for order: TradeRoute.Order in stop.orders:
		box.add_child(_order_row(stop, order))
	var order_button := _button("ROUTES_ADD_ORDER", "action_add", func() -> void:
		add_order(stop, Input.is_key_pressed(KEY_SHIFT)))
	order_button.name = "AddOrder"
	box.add_child(order_button)
	box.add_child(HSeparator.new())
	return box


func _order_row(stop: TradeRoute.Stop, order: TradeRoute.Order) -> Control:
	var row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 24
	row.add_child(spacer)
	var action := OptionButton.new()
	action.focus_mode = Control.FOCUS_NONE
	action.add_icon_item(Icons.action("load_cargo"), tr("ROUTES_LOAD"))
	action.add_icon_item(Icons.action("unload_cargo"), tr("ROUTES_UNLOAD"))
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
		good.add_icon_item(Icons.good(def.id), tr(def.name_key))
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
	row.add_child(_icon_button("action_remove", "ROUTES_REMOVE_ORDER", func() -> void:
		stop.orders.erase(order)
		_commit()
		_build_stops()))
	return row


## Uma caixa por navio do jogador: marcada, ele faz esta rota.
func _fill_ships() -> void:
	# fora da árvore já: o nome fica livre para o filho novo de mesmo nome
	UiKit.clear(_ships)
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


static func _button(text_key: String, icon_name: String, action: Callable) -> Button:
	return UiKit.button(text_key, icon_name, action, text_key + "_TIP")


static func _icon_button(icon_name: String, tooltip_key: String, action: Callable) -> Button:
	return UiKit.icon_button(icon_name, tooltip_key, action)
