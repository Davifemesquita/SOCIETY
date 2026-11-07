class_name HayWagonView
extends Node3D
## Fase 193: a carroça de feno parada. Ao lado das medas de feno da Fase 166 (uma fazenda a cada WAGON_EVERY pelo id), na célula
## livre e quase plana vizinha da delas pelo lado, fora do lote da fazenda e das outras peças de célula (`cells`), a carroça das
## estradas (`CartView.model_mesh`) sem o cavalo, tombada para a frente com os varais no chão (`wagon_place`), e a carga de feno
## alta e desarrumada sobre a caçamba (`load_mesh`). O recheio deixa a célula limpa. Só a ilha com relevo; dois MultiMesh; nada
## no save; refeito na obra, na demolição, na estrada e ao trocar de mundo.

const WAGON_EVERY := 2
const WAGON_REST := 1
const MAX_RELIEF_M := 0.7
## Quanto a carroça tomba para a frente (os varais no chão) e a carga de feno sobre a caçamba.
const TILT := 0.13
const LOAD_FOOT_M := CartView.CANVAS_FOOT_M
const LOAD_M := 0.85
const LOAD_HALF_X := 0.58
const LOAD_FRONT_Z := CartView.CANVAS_CENTER_Z - CartView.CANVAS_HALF_M
const LOAD_BACK_Z := CartView.CANVAS_CENTER_Z + CartView.CANVAS_HALF_M
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

var _simulation: Simulation
var _wagons := MultiMeshInstance3D.new()
var _loads := MultiMeshInstance3D.new()
## Os lugares das carroças (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var hay := StandardMaterial3D.new()
	hay.vertex_color_use_as_albedo = true
	hay.vertex_color_is_srgb = true
	hay.roughness = 0.95
	_wagons.name = "HayWagons"
	_wagons.multimesh = MultiMesh.new()
	_wagons.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_wagons.multimesh.mesh = CartView.model_mesh()
	_wagons.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	add_child(_wagons)
	_loads.name = "HayLoads"
	_loads.multimesh = MultiMesh.new()
	_loads.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_loads.multimesh.mesh = load_mesh()
	_loads.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_loads.material_override = hay
	add_child(_loads)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func wagon_count() -> int:
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
			places.append(wagon_place(grid, cell, found[cell]))
	# a carroça só sem o modelo (ele falta no kit) fica sem desenho: a carga também
	var count := places.size() if _wagons.multimesh.mesh != null else 0
	_wagons.multimesh.instance_count = count
	_loads.multimesh.instance_count = count
	for i: int in count:
		_wagons.multimesh.set_instance_transform(i, places[i])
		_loads.multimesh.set_instance_transform(i, places[i])


## A célula da carroça de cada fazenda com medas do resto certo → o id da fazenda. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var stacks := HaystackView.cells(world, data, island_id)
	if stacks.is_empty():
		return result
	var taken: Dictionary[Vector2i, bool] = {}
	for source: Dictionary in [stacks, FarmSiloView.cells(world, data, island_id), BeehiveView.cells(world, data, island_id),
			KitchenGardenView.cells(world, data, island_id), RainBarrelView.cells(world, data, island_id)]:
		for cell: Vector2i in source:
			taken[cell] = true
	taken.merge(ForecourtView.cells(world, data, island_id))
	taken.merge(AvenueView.cells(world, island_id))
	for stack: Vector2i in stacks:
		var farm_id: int = stacks[stack]
		if posmod(farm_id, WAGON_EVERY) != WAGON_REST:
			continue
		var farm := world.building(farm_id)
		var area := Footprint.rect(farm.origin, data.building(farm.def_id).size, farm.rotation)
		for side: Vector2i in SIDES:
			var cell := stack + side
			if area.has_point(cell) or not grid.in_bounds(cell) or taken.has(cell) or result.has(cell):
				continue
			var index := grid.index(cell)
			if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
					or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
				continue
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			if corners.y - corners.x > MAX_RELIEF_M:
				continue
			result[cell] = farm_id
			break
	return result


## A carroça na célula (mundo): girada pelo id da fazenda, tombada para a frente com os varais no chão, na altura do chão (a
## malha do modelo tem a base HEIGHT_M abaixo da origem, como na CartView).
static func wagon_place(grid: IslandGrid, cell: Vector2i, farm_id: int) -> Transform3D:
	var middle := grid.cell_world(cell)
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	var turn := float(posmod(farm_id * 67, 360)) * PI / 180.0
	var basis := Basis(Vector3.UP, turn) * Basis(Vector3.RIGHT, -TILT)
	return Transform3D(basis, Vector3(middle.x, corners.x + CartView.HEIGHT_M - 0.05, middle.z))


## A carga de feno no referencial da carroça: um monte em camadas sobre a caçamba, mais largo em cima e torto, com os fiapos
## soltos nas pontas.
static func load_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := LOAD_BACK_Z - LOAD_FRONT_Z
	var middle_z := (LOAD_FRONT_Z + LOAD_BACK_Z) * 0.5
	for layer: int in 3:
		var y := LOAD_FOOT_M + LOAD_M * (layer + 0.5) / 3.0
		var widen := 1.0 + 0.12 * layer - (0.18 if layer == 2 else 0.0)
		var shift := Vector3(0.04 * (layer - 1), 0.0, 0.05 * (1 - layer))
		var color := HaystackView.HAY if layer < 2 else HaystackView.HAY_SUN
		# a camada é uma bola achatada (o feno solto não tem quina)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(LOAD_HALF_X * widen * 1.08, LOAD_M / 5.0 + 0.04,
				length * 0.55 * (1.0 - 0.06 * layer))), Vector3(0.0, y, middle_z) + shift), color)
	for k: int in 8:
		var x := (k % 4 - 1.5) * 0.3
		var z := LOAD_FRONT_Z if k < 4 else LOAD_BACK_Z
		var outward := -1.0 if k < 4 else 1.0
		VertexShapes.strut(tool, Vector3(x, LOAD_FOOT_M + 0.3 + 0.1 * (k % 3), z),
				Vector3(x * 1.1, LOAD_FOOT_M + 0.15 + 0.1 * (k % 2), z + outward * 0.18), 0.012, 0.012, HaystackView.HAY_FOOT)
	tool.generate_normals()
	return tool.commit()
