class_name BeachBoatView
extends Node3D
## Fase 183: o barco na areia. Junto de cada cabana de pesca, na célula de terra livre a até REACH células dela que encosta no
## mar pelo lado (a praia: baixa e quase plana, fora das redes da Fase 139, do largo e da alameda), com as duas vizinhas ao
## longo da costa também livres (o barco é mais comprido que a célula), a mais perto da cabana (`sites`): o bote do porto
## (`HarborView.boat_mesh`) virado de borco ao longo da costa, com uma ponta apoiada mais alta (`boat_place`), e os dois remos
## deitados na areia do lado de terra (`oar_places`, `RowboatView.oar_mesh`). O recheio deixa as três células limpas. Dois
## MultiMesh; nada no save; refeito na obra, na demolição, na estrada, nas árvores e ao trocar de mundo.

const REACH := 3
const MAX_RELIEF_M := 0.8
const MAX_HEIGHT_M := 2.2
## Quanto a ponta apoiada levanta o casco (rad) e quanto ele afunda na areia.
const TILT := 0.09
const SINK_M := 0.04
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## A altura da borda do casco acima da quilha (feita uma vez: montar o casco custa).
static var _boat_top := -1.0

var _simulation: Simulation
var _boats := MultiMeshInstance3D.new()
var _oars := MultiMeshInstance3D.new()
## Os lugares dos barcos e dos remos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var oar_places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var wood := StandardMaterial3D.new()
	wood.albedo_color = HarborView.BOAT_COLOR
	wood.roughness = 0.8
	wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	var painted := StandardMaterial3D.new()
	painted.vertex_color_use_as_albedo = true
	painted.vertex_color_is_srgb = true
	painted.roughness = 0.85
	for part: Array in [[_boats, "BeachBoats", HarborView.boat_mesh(), wood], [_oars, "BeachOars", RowboatView.oar_mesh(),
			painted]]:
		var layer: MultiMeshInstance3D = part[0]
		var label: String = part[1]
		var mesh: ArrayMesh = part[2]
		var material: Material = part[3]
		layer.name = label
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = mesh
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = material
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_area)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func boat_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _mark_area(_island_id: int, _area: Rect2i) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	oar_places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := sites(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var sea := found[cell]
			places.append(boat_place(grid, cell, sea))
			oar_places.append_array(oar_places_of(grid, cell, sea))
	for pair: Array in [[_boats, places], [_oars, oar_places]]:
		var layer: MultiMeshInstance3D = pair[0]
		var list: Array[Transform3D] = pair[1]
		layer.multimesh.instance_count = list.size()
		for i: int in list.size():
			layer.multimesh.set_instance_transform(i, list[i])


## A célula do barco de cada cabana de pesca da ilha → o lado dela que dá para o mar. Vazio na ilha plana.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == &"fishery":
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	taken.merge(ForecourtView.cells(world, data, island_id))
	taken.merge(AvenueView.cells(world, island_id))
	taken.merge(FishNetView.cells(world, data, island_id))
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var center := grid.rect_world(area)
		var best := Vector2i(-1, -1)
		var best_side := Vector2i.ZERO
		var best_m := INF
		var ring := area.grow(REACH)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				if area.has_point(cell) or not grid.in_bounds(cell):
					continue
				var sea := _sea_side(grid, cell)
				if sea == Vector2i.ZERO:
					continue
				var along := Vector2i(-sea.y, sea.x)
				if not (_free(grid, cell, taken, result) and _free(grid, cell + along, taken, result)
						and _free(grid, cell - along, taken, result)):
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M or corners.y > MAX_HEIGHT_M:
					continue
				var meters := grid.cell_world(cell).distance_squared_to(center)
				if meters < best_m:
					best_m = meters
					best = cell
					best_side = sea
		if best.x >= 0:
			result[best] = best_side
	return result


## As células que o barco ocupa (a dele e as duas vizinhas ao longo da costa): o recheio as deixa limpas.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	var found := sites(world, data, island_id)
	for cell: Vector2i in found:
		var along := Vector2i(-found[cell].y, found[cell].x)
		for step: Vector2i in [Vector2i.ZERO, along, -along]:
			result[cell + step] = true
	return result


static func _sea_side(grid: IslandGrid, cell: Vector2i) -> Vector2i:
	for side: Vector2i in SIDES:
		var next := cell + side
		if grid.in_bounds(next) and grid.ground_at(next) == IslandGrid.Ground.SEA:
			return side
	return Vector2i.ZERO


static func _free(grid: IslandGrid, cell: Vector2i, taken: Dictionary[Vector2i, bool],
		result: Dictionary[Vector2i, Vector2i]) -> bool:
	if not grid.in_bounds(cell) or taken.has(cell) or result.has(cell):
		return false
	var index := grid.index(cell)
	return grid.ground[index] == IslandGrid.Ground.LAND and grid.occupancy[index] == 0 \
			and grid.roads[index] == IslandGrid.Road.NONE and grid.rails[index] == 0 and grid.trees[index] == 0


## O barco virado de borco na célula: o comprimento (z do casco) ao longo da costa, a quilha para cima, a borda na areia e uma
## ponta um pouco mais alta.
static func boat_place(grid: IslandGrid, cell: Vector2i, sea: Vector2i) -> Transform3D:
	var middle := grid.cell_world(cell)
	var along := Vector3(-sea.y, 0.0, sea.x)
	var down := Vector3.DOWN
	var basis := Basis(down.cross(along), down, along) * Basis(Vector3.RIGHT, TILT)
	if _boat_top < 0.0:
		_boat_top = HarborView.boat_mesh().get_aabb().end.y
	var top := _boat_top
	var ground := TerrainDetail.shown_at(grid, middle.x, middle.z)
	return Transform3D(basis, Vector3(middle.x, ground + top - SINK_M + sin(TILT) * HarborView.BOAT_LENGTH_M * 0.25,
			middle.z))


## Os dois remos deitados na areia do lado de terra do barco, quase paralelos a ele.
static func oar_places_of(grid: IslandGrid, cell: Vector2i, sea: Vector2i) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var middle := grid.cell_world(cell)
	var along := Vector3(-sea.y, 0.0, sea.x)
	var land := -Vector3(sea.x, 0.0, sea.y)
	for k: int in 2:
		var at := middle + land * (0.75 + k * 0.22) + along * (k * 0.4 - 1.2)
		at.y = TerrainDetail.shown_at(grid, at.x, at.z) + 0.03
		var yaw := atan2(-along.z, along.x) + (0.08 if k == 0 else -0.12)
		result.append(Transform3D(Basis(Vector3.UP, yaw), at))
	return result
