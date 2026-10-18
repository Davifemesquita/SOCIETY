class_name ArchipelagoMap
extends Control
## Mapa do arquipélago na janela de rotas (seção 10), no estilo de carta náutica do século XIX:
## papel, mar com faixa mais escura junto à costa, terra em sépia com o litoral a tinta, rosa dos
## ventos e moldura. Por cima: o número das ilhas, os portos (âncora), o posto do comerciante, a
## rota escolhida (tracejada) e os navios. As ilhas das rivais (Fase 11) ganham um círculo na cor
## delas, e os navios delas também. Só desenha; a terra sai da carta náutica. Fase 20: a terra e o mar em
## traço de gravura (`engrave`). Fase 21: o papel envelhecido por cima (`grain`, do `PaperGrain`).

const SEA := Color("cdd5c4")
const SEA_SHALLOW := Color("b9c6b4")
const LAND := Color("dcc391")
const COAST := Color("4a3020")
const ROUTE := Color("8e2a1e")
const SHIP := Color("2e2116")
const TRADER := Color("8e2a1e")
const FRAME := 10.0
## Gravura (Fase 20): pixels por célula da carta, a tinta do litoral (meia largura, px), as linhas d'água
## (células da costa), a faixa rasa, e a hachura da terra (alcance em células, período e tinta em px).
const ENGRAVE_SCALE := 3
const COAST_INK_PX := 1.6
const WATERLINES: Array[float] = [1.6, 3.6, 6.2, 9.6]
const SHALLOW_CELLS := 3.0
const HATCH_REACH := 6.0
const HATCH_PX := 9.0
const HATCH_INK_PX := 3.0
## Meia largura da linha d'água (px da carta gravada): uma célula inteira, para aparecer no mapa pequeno.
const WATERLINE_INK_PX := 1.5
## Grão do papel (Fase 21): o lado da camada (px, perto do tamanho do mapa na tela) e a semente.
const GRAIN_PX := 512
const GRAIN_SEED := 1840

## Rota destacada (0 = nenhuma).
var route_id: int = 0

var _simulation: Simulation
var _texture: ImageTexture
var _chart: SeaChart

## O grão do papel por cima da carta (Fase 21): o mesmo para todo mapa, feito uma vez.
static var _grain: ImageTexture


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
	draw_texture_rect(grain(), area, false)
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


## A carta gravada (Fase 20), em ENGRAVE_SCALE pixels por célula da carta náutica: a distância com sinal até o
## litoral (`coast_distance`, em células; + no mar) dá o litoral a tinta, as linhas d'água em volta da costa
## (WATERLINES, cada uma mais fraca), o mar mais escuro junto dela e a hachura em diagonal na terra perto do
## mar, sumindo para dentro.
## O grão do papel da carta (vergê, ferrugem e a borda gasta), em GRAIN_PX × GRAIN_PX.
static func grain() -> ImageTexture:
	if _grain == null:
		_grain = ImageTexture.create_from_image(PaperGrain.overlay(GRAIN_PX, GRAIN_SEED))
	return _grain


static func _bake(chart: SeaChart) -> ImageTexture:
	return ImageTexture.create_from_image(engrave(chart))


static func engrave(chart: SeaChart) -> Image:
	var field := coast_distance(chart)
	var width := chart.size.x * ENGRAVE_SCALE
	var height := chart.size.y * ENGRAVE_SCALE
	var data := PackedByteArray()
	data.resize(width * height * 3)
	var pixel_cells := 1.0 / ENGRAVE_SCALE
	for y: int in height:
		for x: int in width:
			var at := Vector2((x + 0.5) * pixel_cells - 0.5, (y + 0.5) * pixel_cells - 0.5)
			var signed := _sample(field, chart.size, at)
			var color: Color
			if signed < 0.0:
				color = LAND
				var depth := -signed
				if depth < HATCH_REACH and fposmod(float(x + y), HATCH_PX) < HATCH_INK_PX:
					color = color.lerp(COAST, 0.5 * (1.0 - depth / HATCH_REACH))
			else:
				color = SEA_SHALLOW if signed < SHALLOW_CELLS else SEA
				for k: int in WATERLINES.size():
					if absf(signed - WATERLINES[k]) * ENGRAVE_SCALE < WATERLINE_INK_PX:
						color = color.lerp(COAST, 0.55 * (1.0 - float(k) / WATERLINES.size()))
			if absf(signed) * ENGRAVE_SCALE < COAST_INK_PX:
				color = COAST
			var i := (y * width + x) * 3
			data[i] = color.r8
			data[i + 1] = color.g8
			data[i + 2] = color.b8
	return Image.create_from_data(width, height, false, Image.FORMAT_RGB8, data)


## Distância de cada célula até o litoral, em células, pelo chanfro de duas passadas (vizinho 1, diagonal √2):
## no mar, + a distância até a terra; na terra, − a distância até o mar; o litoral (entre as duas) fica no zero.
static func coast_distance(chart: SeaChart) -> PackedFloat32Array:
	var width := chart.size.x
	var height := chart.size.y
	var to_land := _chamfer(chart, 0)
	var to_sea := _chamfer(chart, 1)
	var field := PackedFloat32Array()
	field.resize(width * height)
	for i: int in field.size():
		field[i] = to_land[i] - 0.5 if chart.navigable[i] == 1 else 0.5 - to_sea[i]
	return field


## Distância (chanfro) de cada célula até a célula mais perto com navigable == target.
static func _chamfer(chart: SeaChart, target: int) -> PackedFloat32Array:
	var width := chart.size.x
	var height := chart.size.y
	var far := float(width + height)
	var distance := PackedFloat32Array()
	distance.resize(width * height)
	for i: int in distance.size():
		distance[i] = 0.0 if chart.navigable[i] == target else far
	var diagonal := sqrt(2.0)
	for y: int in height:
		for x: int in width:
			var i := y * width + x
			var best := distance[i]
			if x > 0:
				best = minf(best, distance[i - 1] + 1.0)
			if y > 0:
				best = minf(best, distance[i - width] + 1.0)
				if x > 0:
					best = minf(best, distance[i - width - 1] + diagonal)
				if x < width - 1:
					best = minf(best, distance[i - width + 1] + diagonal)
			distance[i] = best
	for y: int in range(height - 1, -1, -1):
		for x: int in range(width - 1, -1, -1):
			var i := y * width + x
			var best := distance[i]
			if x < width - 1:
				best = minf(best, distance[i + 1] + 1.0)
			if y < height - 1:
				best = minf(best, distance[i + width] + 1.0)
				if x < width - 1:
					best = minf(best, distance[i + width + 1] + diagonal)
				if x > 0:
					best = minf(best, distance[i + width - 1] + diagonal)
			distance[i] = best
	return distance


## O campo no ponto (em células, centro da célula 0 em 0), interpolado entre as quatro células em volta.
static func _sample(field: PackedFloat32Array, size: Vector2i, at: Vector2) -> float:
	var clamped := at.clamp(Vector2.ZERO, Vector2(size - Vector2i.ONE))
	var x0 := mini(int(clamped.x), size.x - 1)
	var y0 := mini(int(clamped.y), size.y - 1)
	var x1 := mini(x0 + 1, size.x - 1)
	var y1 := mini(y0 + 1, size.y - 1)
	var f := clamped - Vector2(x0, y0)
	var top := lerpf(field[y0 * size.x + x0], field[y0 * size.x + x1], f.x)
	var bottom := lerpf(field[y1 * size.x + x0], field[y1 * size.x + x1], f.x)
	return lerpf(top, bottom, f.y)
