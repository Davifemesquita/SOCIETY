class_name HorseTroughView
extends Node3D
## Fase 206: o bebedouro de cavalos. Junto de cada taverna, na célula livre encostada nela pelo lado (sem os cantos) mais perto da
## porta, fora das células que as outras peças já tomam (as mesas da Fase 116 entre elas: elas pegam as células da frente) e do
## carrinho de feira (`cells`), o cocho comprido de pedra com a água, a coluna da bica de ferro numa ponta e a argola de amarrar
## na outra (`trough_mesh`), de comprido ao longo da parede, com a frente para longe dela. A bomba e o poço desviam dele
## (`WaterPumpView.street_pieces`), e o recheio deixa a célula limpa. Só a ilha com relevo; a célula fica na memória das buscas
## junto da rua; um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de
## mundo.

const TAVERNS: Array[StringName] = [&"tavern"]
const MAX_RELIEF_M := 0.6
## O cocho: o comprimento, a largura, a altura da borda e a água abaixo dela.
const LENGTH_M := 1.5
const WIDTH_M := 0.55
const RIM_M := 0.52
const WATER_DOWN_M := 0.08
const WALL_M := 0.08
const STONE := Color(0.44, 0.42, 0.39)
const STONE_DARK := Color(0.33, 0.32, 0.3)
const WATER := Color(0.12, 0.2, 0.22)
const IRON := Color(0.15, 0.17, 0.16)

var _simulation: Simulation
var _troughs := MultiMeshInstance3D.new()
## Os lugares dos bebedouros (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	_troughs.name = "HorseTroughs"
	_troughs.multimesh = MultiMesh.new()
	_troughs.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_troughs.multimesh.mesh = trough_mesh()
	_troughs.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_troughs.material_override = material
	add_child(_troughs)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func trough_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var away: Vector2i = found[cell]
			var x := grid.origin_m.x + (cell.x + 0.5) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + 0.5) * grid.cell_size
			# de comprido ao longo da parede da taverna: a frente (−z da malha) para longe dela
			places.append(Transform3D(Basis.looking_at(Vector3(away.x, 0.0, away.y), Vector3.UP),
					Vector3(x, grid.height_at(x, z), z)))
	_troughs.multimesh.instance_count = places.size()
	for i: int in places.size():
		_troughs.multimesh.set_instance_transform(i, places[i])


## As células dos bebedouros na ilha → o lado que se afasta da taverna (guardadas na memória da bomba enquanto o mundo não muda).
## Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var found: Dictionary[Vector2i, Vector2i] = WaterPumpView.remembered(world, "troughs/%d" % island_id,
			func() -> Dictionary[Vector2i, Vector2i]: return _cells_now(world, data, island_id))
	var copy: Dictionary[Vector2i, Vector2i] = {}
	copy.merge(found)
	return copy


## Para cada taverna, a célula livre encostada nela pelo lado (sem os cantos), fora das tomadas (as mesas entre elas) e do
## carrinho, quase plana, mais perto da porta.
static func _cells_now(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id in TAVERNS:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken := WaterPumpView.taken_cells(world, data, island_id)
	for cell: Vector2i in MarketCartView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var door := Vector2(Footprint.entrance_cell(record.origin, def.size, record.rotation)) + Vector2(0.5, 0.5)
		var best := Vector2i(-1, -1)
		var best_away := Vector2i.ZERO
		var best_m := INF
		var ring := area.grow(1)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				var beside_x := x < area.position.x or x >= area.end.x
				var beside_y := y < area.position.y or y >= area.end.y
				# só pelo lado: no canto não há parede para encostar
				if beside_x == beside_y or not grid.in_bounds(cell) or taken.has(cell) or result.has(cell):
					continue
				var index := grid.index(cell)
				if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
						or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				var meters := (Vector2(cell) + Vector2(0.5, 0.5)).distance_squared_to(door)
				if meters < best_m:
					best_m = meters
					best = cell
					best_away = Vector2i(signi(x - area.position.x) if beside_x else 0, signi(y - area.position.y) if beside_y else 0)
		if best_m < INF:
			result[best] = best_away
	return result


## O bebedouro com o pé no zero, de comprido em x e a frente para −z: o cocho de pedra (o fundo, as quatro paredes e a borda
## mais escura), a água, a coluna da bica numa ponta com o cano de ferro saindo por cima da água e a argola na outra.
static func trough_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := Vector3(LENGTH_M * 0.5, RIM_M * 0.5, WIDTH_M * 0.5)
	VertexShapes.box(tool, Vector3(0.0, 0.06, 0.0), Vector3(half.x, 0.06, half.z), STONE_DARK)
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(0.0, half.y, side * (half.z - WALL_M * 0.5)), Vector3(half.x, half.y, WALL_M * 0.5), STONE)
		VertexShapes.box(tool, Vector3(side * (half.x - WALL_M * 0.5), half.y, 0.0), Vector3(WALL_M * 0.5, half.y, half.z), STONE)
		VertexShapes.box(tool, Vector3(0.0, RIM_M + 0.02, side * (half.z - WALL_M * 0.5)),
				Vector3(half.x + 0.02, 0.02, WALL_M * 0.6), STONE_DARK)
	VertexShapes.box(tool, Vector3(0.0, RIM_M - WATER_DOWN_M, 0.0), Vector3(half.x - WALL_M, 0.005, half.z - WALL_M), WATER)
	# a coluna da bica na ponta de +x, por fora do cocho, com o cano curvo sobre a água
	var column := Vector3(half.x + 0.16, 0.0, 0.0)
	VertexShapes.box(tool, column + Vector3(0.0, 0.55, 0.0), Vector3(0.13, 0.55, 0.13), STONE)
	VertexShapes.box(tool, column + Vector3(0.0, 1.14, 0.0), Vector3(0.16, 0.04, 0.16), STONE_DARK)
	VertexShapes.strut(tool, column + Vector3(-0.1, 0.85, 0.0), column + Vector3(-0.32, 0.82, 0.0), 0.025, 0.025, IRON)
	VertexShapes.strut(tool, column + Vector3(-0.32, 0.82, 0.0), column + Vector3(-0.36, 0.7, 0.0), 0.025, 0.025, IRON)
	# a argola de amarrar na ponta de −x, no alto da parede
	var ring_at := Vector3(-half.x - 0.01, RIM_M - 0.12, 0.0)
	for k: int in 8:
		var a0 := TAU * k / 8.0
		var a1 := TAU * (k + 1) / 8.0
		VertexShapes.strut(tool, ring_at + Vector3(0.0, sin(a0), cos(a0)) * 0.07, ring_at + Vector3(0.0, sin(a1), cos(a1)) * 0.07,
				0.01, 0.01, IRON)
	tool.generate_normals()
	return tool.commit()
