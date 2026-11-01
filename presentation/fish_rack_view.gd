class_name FishRackView
extends Node3D
## Fase 202: o secadouro de peixe. Ao lado de cada cabana de pesca das ilhas temperadas, na célula livre encostada nela mais
## perto da metade do lado da terra (o contrário das redes da Fase 139; `sites`: de terra, sem prédio, estrada, trilho nem
## árvore, fora do largo, da alameda, das redes e do barco virado da Fase 183, e quase plana), o secadouro: dois pares de varas
## cruzadas em X segurando a vara de cima e uma mais baixa, com os peixes abertos pendurados aos pares de um lado e do outro
## (`rack_mesh`), a vara de través do mar. O recheio e as bombas deixam a célula limpa. Um MultiMesh; nada no save; refeito na
## obra, na demolição, na estrada, no trilho, na derrubada de árvores e ao trocar de mundo.

const MAX_RELIEF_M := 0.8
## As varas: o comprimento, a altura da de cima e a da de baixo, e a abertura das pernas em X.
const LENGTH_M := 1.7
const TOP_M := 1.55
const LOW_M := 1.0
const SPREAD_M := 0.38
const FISH_PAIRS := 7
const LOW_PAIRS := 5
const POLE := Color(0.4, 0.31, 0.21)
const FISH := Color(0.66, 0.58, 0.44)
const FISH_DARK := Color(0.42, 0.36, 0.28)

var _simulation: Simulation
var _racks := MultiMeshInstance3D.new()
## Os lugares dos secadouros (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_racks.name = "FishRacks"
	_racks.multimesh = MultiMesh.new()
	_racks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_racks.multimesh.mesh = rack_mesh()
	_racks.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_racks.material_override = material
	add_child(_racks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rack_count() -> int:
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
		var found := sites(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var out: Vector3 = found[cell]
			var across := Vector3(-out.z, 0.0, out.x)
			var at := grid.cell_world(cell)
			at.y = grid.height_at(at.x, at.z)
			# a vara (o x da malha) de través do mar
			places.append(Transform3D(Basis(across, Vector3.UP, across.cross(Vector3.UP)), at))
	_racks.multimesh.instance_count = places.size()
	for i: int in places.size():
		_racks.multimesh.set_instance_transform(i, places[i])


## As células dos secadouros da ilha → o lado do mar da cabana. Vazio nas ilhas tropicais.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector3]:
	var result: Dictionary[Vector2i, Vector3] = {}
	var grid := world.island(island_id)
	if grid == null or world.is_tropical(island_id, data):
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
	if not grid.flat:
		taken.merge(ForecourtView.cells(world, data, island_id))
		taken.merge(AvenueView.cells(world, island_id))
	taken.merge(FishNetView.cells(world, data, island_id))
	for cell: Vector2i in BeachBoatView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var center := grid.rect_world(area)
		var out := HarborView.seaward(world, center, area, grid.cell_size, record.rotation)
		var across := Vector3(-out.z, 0.0, out.x)
		var reach := (area.size.x if out.x != 0.0 else area.size.y) * grid.cell_size * 0.5
		var width := (area.size.y if out.x != 0.0 else area.size.x) * grid.cell_size * 0.5
		var goals: Array[Vector3] = [center - out * reach * 0.5 + across * (width + grid.cell_size * 0.5),
				center - out * reach * 0.5 - across * (width + grid.cell_size * 0.5)]
		var best := Vector2i(-1, -1)
		var best_m := INF
		var ring := area.grow(1)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				if area.has_point(cell) or not grid.in_bounds(cell) or taken.has(cell) or result.has(cell):
					continue
				var index := grid.index(cell)
				# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
				if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
						or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				var at := grid.cell_world(cell)
				var meters := minf(at.distance_squared_to(goals[0]), at.distance_squared_to(goals[1]))
				if meters < best_m:
					best_m = meters
					best = cell
		if best_m < INF:
			result[best] = out
	return result


## As células dos secadouros da ilha (o recheio e as bombas as deixam limpas).
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in sites(world, data, island_id):
		result[cell] = true
	return result


## O secadouro com o pé no zero e as varas ao longo de x: em cada ponta duas varas cruzadas em X, a vara de cima no cruzamento e
## a de baixo entre as pernas, e os peixes abertos pendurados aos pares, um de cada lado da vara, com o rabo mais escuro.
static func rack_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LENGTH_M * 0.5
	for end: float in [-half + 0.08, half - 0.08]:
		for side: float in [-1.0, 1.0]:
			VertexShapes.strut(tool, Vector3(end, 0.0, side * SPREAD_M), Vector3(end, TOP_M + 0.15, -side * 0.08), 0.03,
					0.03, POLE)
	VertexShapes.strut(tool, Vector3(-half - 0.05, TOP_M, 0.0), Vector3(half + 0.05, TOP_M, 0.0), 0.035, 0.035, POLE)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(-half, LOW_M, side * 0.2), Vector3(half, LOW_M, side * 0.2), 0.025, 0.025, POLE)
	_fish_row(tool, TOP_M, 0.0, FISH_PAIRS, half - 0.2)
	for side: float in [-1.0, 1.0]:
		_fish_row(tool, LOW_M, side * 0.2, LOW_PAIRS, half - 0.25)
	tool.generate_normals()
	return tool.commit()


## Uma fileira de pares de peixes pendurados na vara da altura y e do z dado, de −half a +half, cada um caindo do lado dele da
## vara, de cabeça para baixo (`_fish`).
static func _fish_row(tool: SurfaceTool, y: float, z: float, pairs: int, half: float) -> void:
	for k: int in pairs:
		var x := lerpf(-half, half, float(k) / maxf(pairs - 1, 1))
		for side: float in [-1.0, 1.0]:
			_fish(tool, Transform3D(Basis(Vector3.RIGHT, side * 0.22), Vector3(x, y, z + side * 0.03)), k % 2 == 0)


## Um peixe aberto e seco pendurado pelo rabo em place (o y para cima, a cabeça em −y): o rabo em V no alto, o corpo chato
## alargando até o meio e afinando até a cabeça, mais escura; os dois lados (é uma lâmina).
static func _fish(tool: SurfaceTool, place: Transform3D, pale: bool) -> void:
	var body := FISH if pale else FISH.darkened(0.08)
	var outline: Array[Vector2] = [Vector2(0.0, -0.04), Vector2(0.035, -0.07), Vector2(0.075, -0.2), Vector2(0.06, -0.3),
			Vector2(0.03, -0.36), Vector2(-0.03, -0.36), Vector2(-0.06, -0.3), Vector2(-0.075, -0.2), Vector2(-0.035, -0.07)]
	var middle := Vector2(0.0, -0.2)
	for i: int in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var color := FISH_DARK if a.y < -0.29 and b.y < -0.29 else body
		_flat(tool, place, middle, a, b, color)
	# o rabo em V, mais escuro
	_flat(tool, place, Vector2(0.0, -0.04), Vector2(0.06, 0.03), Vector2(0.01, -0.01), FISH_DARK)
	_flat(tool, place, Vector2(0.0, -0.04), Vector2(-0.01, -0.01), Vector2(-0.06, 0.03), FISH_DARK)


## Um triângulo chato no plano xy de place, dos dois lados.
static func _flat(tool: SurfaceTool, place: Transform3D, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var pa := place * Vector3(a.x, a.y, 0.0)
	var pb := place * Vector3(b.x, b.y, 0.0)
	var pc := place * Vector3(c.x, c.y, 0.0)
	VertexShapes.tri(tool, pa, pb, pc, color)
	VertexShapes.tri(tool, pa, pc, pb, color)
