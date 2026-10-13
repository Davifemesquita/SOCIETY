class_name ArchipelagoMap
extends Control
## Mapa do arquipélago na janela de rotas (seção 10): a terra da carta náutica num pixel por
## célula, os portos, o posto do comerciante, a rota escolhida e os navios. Só desenha.

const SEA := Color(0.16, 0.3, 0.42)
const LAND := Color(0.42, 0.5, 0.3)
const PORT := Color(0.95, 0.85, 0.5)
const TRADER := Color(0.85, 0.3, 0.25)
const ROUTE := Color(1.0, 0.9, 0.4, 0.9)
const SHIP := Color(1.0, 1.0, 1.0)

## Rota destacada (0 = nenhuma).
var route_id: int = 0

var _simulation: Simulation
var _texture: ImageTexture
var _chart: SeaChart


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	custom_minimum_size = Vector2(300, 300)
	EventBus.world_replaced.connect(func() -> void: _texture = null)


func _draw() -> void:
	var harbors := _simulation.harbors()
	if _texture == null or _chart != harbors.chart:
		_chart = harbors.chart
		_texture = _bake(_chart)
	var area := _area()
	draw_texture_rect(_texture, area, false)
	for island_id: int in _simulation.world.islands.size():
		var center := _to_map(_simulation.world.island(island_id).world_rect().get_center(), area)
		draw_string(get_theme_default_font(), center + Vector2(-4, 5), str(island_id + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		if _simulation.world.has_trading_post(island_id, _simulation.data):
			draw_circle(_to_map(harbors.roadstead(island_id), area), 4.0, PORT)
	draw_circle(_to_map(harbors.trader_post, area), 5.0, TRADER)
	var route: TradeRoute = _simulation.world.routes.get(route_id)
	if route != null and route.stops.size() > 1:
		var points := PackedVector2Array()
		for stop: TradeRoute.Stop in route.stops:
			points.append(_to_map(harbors.target_point(stop.target), area))
		points.append(points[0])
		draw_polyline(points, ROUTE, 2.0)
	for ship: Ship in _simulation.world.ships.values():
		if ship.is_placed():
			var color := SHIP if ship.owner == Ship.Owner.PLAYER else TRADER
			draw_circle(_to_map(ship.position, area), 3.0 if ship.route_id != route_id or route_id == 0 else 4.5, color)


## Retângulo do mapa dentro do controle, mantendo a proporção da carta.
func _area() -> Rect2:
	var chart_size := Vector2(_chart.size)
	var scale_factor := minf(size.x / chart_size.x, size.y / chart_size.y)
	var drawn := chart_size * scale_factor
	return Rect2((size - drawn) * 0.5, drawn)


func _to_map(point: Vector2, area: Rect2) -> Vector2:
	return area.position + (point - _chart.origin_m) / (Vector2(_chart.size) * _chart.cell_m) * area.size


static func _bake(chart: SeaChart) -> ImageTexture:
	var image := Image.create(chart.size.x, chart.size.y, false, Image.FORMAT_RGB8)
	for y: int in chart.size.y:
		for x: int in chart.size.x:
			image.set_pixel(x, y, SEA if chart.navigable[y * chart.size.x + x] == 1 else LAND)
	return ImageTexture.create_from_image(image)
