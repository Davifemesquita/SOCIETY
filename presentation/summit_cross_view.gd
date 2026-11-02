class_name SummitCrossView
extends Node3D
## Fase 269: o cruzeiro no morro. Em cada ilha temperada com relevo, a célula de terra livre (sem árvore, prédio, estrada nem
## trilho) e quase plana (até MAX_RELIEF_M) mais alta da ilha, procurada a cada SEARCH_STEP células (`summit`): a cruz de pedra
## sobre o degrau, com o pedestal em dois socos e o musgo no pé (`cross_mesh`), virada para o meio da ilha. Um MultiMesh; nada no
## save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

const SEARCH_STEP := 2
const MAX_RELIEF_M := 0.5
## A altura mínima do topo: ilha sem morro (o topo baixo, junto da praia) fica sem cruzeiro.
const MIN_HEIGHT_M := 6.0
const STONE := Color(0.72, 0.7, 0.65)
const STONE_DARK := Color(0.55, 0.53, 0.49)
const MOSS := Color(0.3, 0.42, 0.16)

var _simulation: Simulation
var _crosses := MultiMeshInstance3D.new()
## Os lugares dos cruzeiros (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.88
	_crosses.name = "SummitCrosses"
	_crosses.multimesh = MultiMesh.new()
	_crosses.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_crosses.multimesh.mesh = cross_mesh()
	_crosses.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_crosses.material_override = material
	add_child(_crosses)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_trees)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func cross_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _mark_trees(_island_id: int, _area: Rect2i) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var found: Variant = summit(world, _simulation.data, island_id)
		if found is Vector2i:
			var cell: Vector2i = found
			places.append(place_of(world.island(island_id), cell))
	_crosses.multimesh.instance_count = places.size()
	for i: int in places.size():
		_crosses.multimesh.set_instance_transform(i, places[i])


## A célula do cruzeiro na ilha: a livre e quase plana mais alta, acima de MIN_HEIGHT_M; null se nenhuma serve (as tropicais, a
## ilha plana e a ilha sem morro). No empate, a primeira numa varredura em linhas.
static func summit(world: WorldState, data: GameData, island_id: int) -> Variant:
	var grid := world.island(island_id)
	if grid == null or grid.flat or world.is_tropical(island_id, data):
		return null
	var best: Variant = null
	var best_height := MIN_HEIGHT_M
	for y: int in range(1, grid.size.y - 1, SEARCH_STEP):
		for x: int in range(1, grid.size.x - 1, SEARCH_STEP):
			var index := y * grid.size.x + x
			if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
					or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0:
				continue
			var cell := Vector2i(x, y)
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			if corners.y <= best_height or corners.y - corners.x > MAX_RELIEF_M:
				continue
			best_height = corners.y
			best = cell
	return best


## O lugar do cruzeiro: no meio da célula, no chão mais baixo dela (o degrau tapa o resto), a frente (−z) para o meio da ilha.
static func place_of(grid: IslandGrid, cell: Vector2i) -> Transform3D:
	var at := grid.cell_world(cell)
	at.y = BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE)).x
	var middle := grid.cell_world(grid.size / 2)
	var toward := Vector2(middle.x - at.x, middle.z - at.z)
	var heading := atan2(-toward.x, -toward.y) if toward.length() > 0.01 else 0.0
	return Transform3D(Basis(Vector3.UP, heading), at)


## O cruzeiro com o pé em y = 0 (cerca de 3,2 m): o degrau largo, o pedestal em dois socos chanfrados, o fuste e a cruz de braços
## curtos com o florão no cruzamento, tudo em pedra clara, e o musgo no pé do degrau.
static func cross_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.12, 0.0), Vector3(0.75, 0.12, 0.75), STONE_DARK)
	VertexShapes.box(tool, Vector3(0.0, 0.36, 0.0), Vector3(0.48, 0.12, 0.48), STONE)
	VertexShapes.box(tool, Vector3(0.0, 0.62, 0.0), Vector3(0.3, 0.14, 0.3), STONE)
	VertexShapes.box(tool, Vector3(0.0, 0.79, 0.0), Vector3(0.24, 0.03, 0.24), STONE_DARK)
	# o fuste afinando e a cruz
	VertexShapes.strut(tool, Vector3(0.0, 0.82, 0.0), Vector3(0.0, 2.55, 0.0), 0.11, 0.09, STONE)
	VertexShapes.box(tool, Vector3(0.0, 2.85, 0.0), Vector3(0.08, 0.35, 0.08), STONE)
	VertexShapes.box(tool, Vector3(0.0, 2.85, 0.0), Vector3(0.38, 0.08, 0.08), STONE)
	VertexShapes.box(tool, Vector3(0.0, 2.85, 0.0), Vector3(0.12, 0.12, 0.1), STONE_DARK)
	# as pontas dos braços alargadas
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(side * 0.42, 2.85, 0.0), Vector3(0.04, 0.11, 0.09), STONE)
	VertexShapes.box(tool, Vector3(0.0, 3.22, 0.0), Vector3(0.11, 0.04, 0.09), STONE)
	# o musgo no pé do degrau, em almofadas
	for k: int in 5:
		var angle := TAU * k / 5.0 + 0.3
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.24, 0.06, 0.18)),
				Vector3(cos(angle) * 0.72, 0.04, sin(angle) * 0.72)), MOSS.darkened(0.06 * (k % 2)))
	tool.generate_normals()
	return tool.commit()
