class_name Harbors
extends RefCounted
## Onde os navios param, sobre a carta náutica: o ponto de atracação de cada entreposto e píer
## (a água navegável mais perto dele), o ancoradouro de cada ilha (onde se espera vaga, um pouco
## mais para o mar) e o posto do comerciante no mar aberto. As vagas de cada ilha saem do
## DerivedState (entrepostos e píeres ligados); os pontos são refeitos quando ele muda. Fora do
## save.

## Distância entre a plataforma do comerciante e o lugar de ancorar de cada lado dela.
const TRADER_ANCHOR_M := 24.0

var chart: SeaChart
## Posto do comerciante neutro: o canto da carta mais longe da ilha principal.
var trader_post := Vector2(NAN, NAN)

var _world: WorldState
var _config: GameConfig
var _version: int = -1
## ilha → vagas (ids de entreposto e píer com ponto de atracação), em ordem de id
var _berths: Dictionary[int, Array] = {}
var _berth_points: Dictionary[int, Vector2] = {}
var _roadsteads: Dictionary[int, Vector2] = {}
var _anchors: Dictionary[int, Vector2] = {}
## Onde ancoram, no posto do comerciante, os navios do jogador e o dele.
var _trader_anchors: Dictionary[int, Vector2] = {}


func _init(world: WorldState, config: GameConfig) -> void:
	_world = world
	_config = config
	chart = SeaChart.new(world, config)
	trader_post = _find_trader_post()
	for owner: int in [Ship.Owner.PLAYER, Ship.Owner.TRADER]:
		var side := Vector2(0.0, TRADER_ANCHOR_M if owner == Ship.Owner.TRADER else -TRADER_ANCHOR_M)
		var cell := chart.nearest_navigable(trader_post + side)
		_trader_anchors[owner] = chart.center_of(cell) if cell.x >= 0 else trader_post


## Refaz as vagas e os pontos quando prédios ou estradas mudaram.
func refresh(world: WorldState, data: GameData, derived: DerivedState) -> void:
	if derived.version == _version:
		return
	_version = derived.version
	_berths.clear()
	_berth_points.clear()
	_roadsteads.clear()
	for island_id: int in derived.berths:
		var list: Array[int] = []
		var candidates: Array = derived.berths[island_id]
		for building_id: int in candidates:
			var record := world.building(building_id)
			var def := data.building(record.def_id)
			var area := Footprint.rect(record.origin, def.size, record.rotation)
			var center := _rect_center(world.island(island_id), area)
			var reach := _config.berth_search_m + Vector2(def.size).length() * _config.cell_size_m * 0.5
			var cell := chart.nearest_navigable(center, reach)
			if cell.x < 0:
				continue
			var point := chart.center_of(cell)
			_berth_points[building_id] = point
			if list.is_empty():
				# o ancoradouro fica além do primeiro cais, para o lado do mar
				var outward := (point - center).normalized()
				var road_cell := chart.nearest_navigable(point + outward * _config.berth_search_m * 0.5)
				_roadsteads[island_id] = chart.center_of(road_cell) if road_cell.x >= 0 else point
			list.append(building_id)
		if not list.is_empty():
			_berths[island_id] = list


func cast_off_seconds() -> float:
	return _config.ship_cast_off_seconds


## Vagas da ilha (entreposto e píeres em funcionamento), ou vazio.
func berths(island_id: int) -> Array:
	return _berths.get(island_id, [])


func berth_point(building_id: int) -> Vector2:
	return _berth_points.get(building_id, Vector2(NAN, NAN))


## Onde o navio vai ao chegar na ilha: o ancoradouro do porto, ou, sem porto, o mar mais perto
## do litoral norte (colonização).
func roadstead(island_id: int) -> Vector2:
	if _roadsteads.has(island_id):
		return _roadsteads[island_id]
	return anchor(island_id)


## Ponto de chegada de um destino: ilha ou posto do comerciante. No posto, o navio do comerciante
## fica de um lado da plataforma e os do jogador do outro.
func target_point(target: int, owner: Ship.Owner = Ship.Owner.PLAYER) -> Vector2:
	if target != Ship.TRADER_POST:
		return roadstead(target)
	return _trader_anchors[owner]


## Mar navegável mais perto do meio da borda norte da ilha.
func anchor(island_id: int) -> Vector2:
	if not _anchors.has(island_id):
		var rect := _world.island(island_id).world_rect()
		var cell := chart.nearest_navigable(Vector2(rect.get_center().x, rect.position.y))
		_anchors[island_id] = chart.center_of(cell) if cell.x >= 0 else Vector2(rect.get_center().x, rect.position.y)
	return _anchors[island_id]


func _find_trader_post() -> Vector2:
	var main := _world.island(Simulation.MAIN_ISLAND).world_rect().get_center()
	var inset := _config.sea_margin_m * 0.5
	var low := chart.origin_m + Vector2(inset, inset)
	var high := chart.origin_m + Vector2(chart.size) * chart.cell_m - Vector2(inset, inset)
	var best := low
	for corner: Vector2 in [low, Vector2(high.x, low.y), Vector2(low.x, high.y), high]:
		if corner.distance_squared_to(main) > best.distance_squared_to(main) + 0.001:
			best = corner
	var cell := chart.nearest_navigable(best)
	return chart.center_of(cell) if cell.x >= 0 else best


static func _rect_center(grid: IslandGrid, area: Rect2i) -> Vector2:
	var point := grid.rect_world(area)
	return Vector2(point.x, point.z)
