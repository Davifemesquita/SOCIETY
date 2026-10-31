class_name WaterPumpView
extends Node3D
## Fase 132: a bomba d'água dos bairros. Junto de uma casa a cada PUMP_EVERY (pelo id), na célula livre encostada nela que
## dá para a rua e fica mais perto da porta (sem prédio, estrada, trilho, árvore, largo, alameda, mesa nem silo, e quase
## plana), uma bomba de ferro fundido com a alavanca, a bica, a laje de pedra com o ralo e dois baldes de madeira
## (`cells`, `pump_mesh`), virada para a rua. O recheio deixa a célula limpa (`ScatterView.island_context`). Só a ilha com
## relevo; nada no save; refeito na obra, na demolição, na estrada e ao trocar de mundo.

const PUMP_EVERY := 6
const MAX_RELIEF_M := 0.6
const IRON := Color(0.13, 0.16, 0.14)
const STONE := Color(0.58, 0.56, 0.52)
const WOOD := Color(0.45, 0.33, 0.21)
const HOOP := Color(0.25, 0.25, 0.26)
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _pumps := MultiMeshInstance3D.new()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	material.metallic = 0.2
	var mesh := pump_mesh()
	mesh.surface_set_material(0, material)
	_pumps.name = "Pumps"
	_pumps.multimesh = MultiMesh.new()
	_pumps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pumps.multimesh.mesh = mesh
	add_child(_pumps)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pump_count() -> int:
	return _pumps.multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places: Array[Transform3D] = []
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var toward: Vector2i = found[cell]
			var x := grid.origin_m.x + (cell.x + 0.5) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + 0.5) * grid.cell_size
			# a bica (−Z da malha) virada para a rua
			var basis := Basis.looking_at(Vector3(toward.x, 0.0, toward.y), Vector3.UP)
			places.append(Transform3D(basis, Vector3(x, grid.height_at(x, z), z)))
	var multimesh := _pumps.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As células das bombas na ilha → o lado da rua (para onde a bica vira): para uma casa a cada PUMP_EVERY, a célula livre
## encostada nela, com estrada num dos lados, mais perto da porta. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.is_house() and posmod(id, PUMP_EVERY) == 0:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	taken.merge(ForecourtView.cells(world, data, island_id))
	taken.merge(AvenueView.cells(world, island_id))
	for cell: Vector2i in TavernGardenView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in FarmSiloView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var door := Vector2(Footprint.entrance_cell(record.origin, def.size, record.rotation)) + Vector2(0.5, 0.5)
		var best := Vector2i(-1, -1)
		var best_side := Vector2i.ZERO
		var best_m := INF
		var ring := area.grow(1)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				if area.has_point(cell) or not grid.in_bounds(cell) or taken.has(cell) or result.has(cell):
					continue
				var index := grid.index(cell)
				if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
						or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
					continue
				var street := Vector2i.ZERO
				for side: Vector2i in SIDES:
					if grid.has_road(cell + side):
						street = side
						break
				if street == Vector2i.ZERO:
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				var meters := (Vector2(cell) + Vector2(0.5, 0.5)).distance_squared_to(door)
				if meters < best_m:
					best_m = meters
					best = cell
					best_side = street
		if best_m < INF:
			result[best] = best_side
	return result


## A bomba de frente para −Z: a laje de pedra com o ralo, o corpo de ferro com o capitel e a tampa, a bica para a frente, a
## alavanca para trás e dois baldes de aduelas com os arcos.
static func pump_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.05, -0.15), Vector3(0.55, 0.05, 0.6), STONE)
	VertexShapes.box(tool, Vector3(0.0, 0.105, -0.45), Vector3(0.18, 0.005, 0.12), Color(0.2, 0.2, 0.2))
	VertexShapes.cylinder(tool, Vector3(0.0, 0.1, 0.1), Vector3(0.0, 1.05, 0.1), 0.085, IRON, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.1, 0.1), Vector3(0.0, 0.22, 0.1), 0.12, IRON, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, 1.05, 0.1), Vector3(0.0, 1.12, 0.1), 0.11, IRON, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, 1.12, 0.1), Vector3(0.0, 1.2, 0.1), 0.05, IRON, 8)
	# a bica: sai do corpo para a frente e desce na ponta
	VertexShapes.strut(tool, Vector3(0.0, 0.78, 0.05), Vector3(0.0, 0.78, -0.22), 0.035, 0.035, IRON)
	VertexShapes.strut(tool, Vector3(0.0, 0.8, -0.22), Vector3(0.0, 0.7, -0.25), 0.035, 0.035, IRON)
	# a alavanca: o pivô no alto e o braço descendo para trás
	VertexShapes.strut(tool, Vector3(0.0, 1.08, 0.15), Vector3(0.0, 1.22, 0.5), 0.025, 0.025, IRON)
	VertexShapes.strut(tool, Vector3(0.0, 1.22, 0.5), Vector3(0.0, 1.0, 0.72), 0.022, 0.022, IRON)
	# dois baldes, um debaixo da bica e outro ao lado
	for bucket: Vector3 in [Vector3(0.0, 0.1, -0.35), Vector3(0.32, 0.1, -0.05)]:
		VertexShapes.cylinder(tool, bucket, bucket + Vector3(0.0, 0.3, 0.0), 0.13, WOOD, 10)
		for h: float in [0.07, 0.23]:
			VertexShapes.cylinder(tool, bucket + Vector3(0.0, h, 0.0), bucket + Vector3(0.0, h + 0.025, 0.0), 0.135, HOOP, 10)
	tool.generate_normals()
	return tool.commit()
