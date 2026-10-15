class_name ArchipelagoMap
extends Control
## Mapa do arquipélago na janela de rotas (seção 10), no estilo de carta náutica do século XIX:
## papel, mar com faixa mais escura junto à costa, terra em sépia com o litoral a tinta, rosa dos
## ventos e moldura. Por cima: o número das ilhas, os portos (âncora), o posto do comerciante, a
## rota escolhida (tracejada) e os navios. As ilhas das rivais (Fase 11) ganham um círculo na cor
## delas, e os navios delas também. Só desenha; a terra sai da carta náutica.

const SEA := Color("cdd5c4")
const SEA_SHALLOW := Color("b9c6b4")
const LAND := Color("dcc391")
const COAST := Color("4a3020")
const ROUTE := Color("8e2a1e")
const SHIP := Color("2e2116")
const TRADER := Color("8e2a1e")
const FRAME := 10.0

## Rota destacada (0 = nenhuma).
var route_id: int = 0

var _simulation: Simulation
var _texture: ImageTexture
var _chart: SeaChart


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	custom_minimum_size = Vector2(340, 340)
	tooltip_text = "ROUTES_MAP_TIP"
	EventBus.world_replaced.connect(func() -> void: _texture = null)


func _draw() -> void:
	var harbors := _simulation.harbors()
	if _texture == null or _chart != harbors.chart:
		_chart = harbors.chart
		_texture = _bake(_chart)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.PAPER_DARK)
	var area := _area()
	draw_texture_rect(_texture, area, false)
	draw_rect(area.grow(2.0), COAST, false, 2.0)
	draw_rect(area.grow(6.0), UiPalette.GOLD, false, 3.0)
	_compass(area.position + Vector2(area.size.x - 30.0, 30.0), 20.0)
	var font := get_theme_default_font()
	for island_id: int in _simulation.world.islands.size():
		var center := _to_map(_simulation.world.island(island_id).world_rect().get_center(), area)
		var name := str(island_id + 1)
		var rival := _simulation.world.rivals_state.owner_of(island_id)
		if rival != null:
			draw_arc(center, 15.0, 0.0, TAU, 32, rival.def.color, 3.0)
		draw_string_outline(font, center + Vector2(-5, 6), name, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 4, UiPalette.PAPER)
		draw_string(font, center + Vector2(-5, 6), name, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, UiPalette.INK)
		if _simulation.world.has_trading_post(island_id, _simulation.data):
			_icon(Icons.get_icon("notice_ship_arrived"), _to_map(harbors.roadstead(island_id), area), 18.0)
	_icon(Icons.get_icon("notice_trader"), _to_map(harbors.trader_post, area), 22.0)
	var route: TradeRoute = _simulation.world.routes.get(route_id)
	if route != null and route.stops.size() > 1:
		var points := PackedVector2Array()
		for stop: TradeRoute.Stop in route.stops:
			points.append(_to_map(harbors.target_point(stop.target), area))
		points.append(points[0])
		for i: int in points.size() - 1:
			draw_dashed_line(points[i], points[i + 1], ROUTE, 2.5, 7.0)
	for ship: Ship in _simulation.world.ships.values():
		if ship.is_placed():
			var at := _to_map(ship.position, area)
			var on_route := route_id != 0 and ship.route_id == route_id
			var radius := 5.0 if on_route else 3.5
			draw_circle(at, radius + 1.5, UiPalette.PAPER)
			var color := SHIP if ship.owner == Ship.Owner.PLAYER else TRADER
			var owner_rival := _simulation.world.rivals_state.by_ship(ship.id)
			if owner_rival != null:
				color = owner_rival.def.color
			draw_circle(at, radius, color)


func _icon(texture: Texture2D, center: Vector2, side: float) -> void:
	draw_texture_rect(texture, Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)), false)


## Rosa dos ventos simples: quatro pontas a tinta, a do norte em vermelho.
func _compass(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.55, UiPalette.PAPER)
	draw_arc(center, radius * 0.55, 0.0, TAU, 24, COAST, 1.5)
	for i: int in 4:
		var direction := Vector2.UP.rotated(i * PI * 0.5)
		var side := direction.orthogonal() * radius * 0.2
		var tip := center + direction * radius
		draw_colored_polygon(PackedVector2Array([tip, center + side, center - side]), ROUTE if i == 0 else COAST)
	draw_string(get_theme_default_font(), center + Vector2(-5, -radius - 4), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COAST)


## Retângulo do mapa dentro do controle, mantendo a proporção da carta, com a moldura em volta.
func _area() -> Rect2:
	var chart_size := Vector2(_chart.size)
	var room := size - Vector2(FRAME, FRAME) * 2.0
	var scale_factor := minf(room.x / chart_size.x, room.y / chart_size.y)
	var drawn := chart_size * scale_factor
	return Rect2((size - drawn) * 0.5, drawn)


func _to_map(point: Vector2, area: Rect2) -> Vector2:
	return area.position + (point - _chart.origin_m) / (Vector2(_chart.size) * _chart.cell_m) * area.size


## Terra em sépia (mais escura longe do mar), litoral a tinta e o mar mais escuro junto à costa.
static func _bake(chart: SeaChart) -> ImageTexture:
	var width := chart.size.x
	var height := chart.size.y
	var distance := PackedInt32Array()
	distance.resize(width * height)
	distance.fill(-1)
	var queue := PackedInt32Array()
	for i: int in distance.size():
		if chart.navigable[i] == 0:
			distance[i] = 0
			queue.append(i)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var x := index % width
		for next: int in [index - 1 if x > 0 else -1, index + 1 if x < width - 1 else -1, index - width, index + width]:
			if next >= 0 and next < distance.size() and distance[next] == -1 and distance[index] < 4:
				distance[next] = distance[index] + 1
				queue.append(next)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	for y: int in height:
		for x: int in width:
			var i := y * width + x
			var color := SEA
			if chart.navigable[i] == 0:
				color = COAST if _touches_sea(chart, x, y) else LAND
			elif distance[i] >= 0 and distance[i] <= 3:
				color = SEA_SHALLOW
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func _touches_sea(chart: SeaChart, x: int, y: int) -> bool:
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var cell := Vector2i(x, y) + offset
		if cell.x >= 0 and cell.y >= 0 and cell.x < chart.size.x and cell.y < chart.size.y \
				and chart.navigable[cell.y * chart.size.x + cell.x] == 1:
			return true
	return false
