class_name ForecourtView
extends Node3D
## Fase 109: o largo calçado. Em volta da igreja, do teatro, da universidade, da prefeitura, do museu e da escola
## (PLAZA_SERVICES), cada célula livre encostada no prédio (sem prédio, estrada, trilho nem árvore, quase plana) ganha
## SLABS × SLABS lajes de pedra em tons, assentadas no relevo (`cells`, `slabs`). O recheio da Fase 41 deixa essas células
## limpas (`ScatterView.island_context`). Só a ilha com relevo; nada no save; refeito na obra, na demolição, na estrada,
## na derrubada de árvores e ao trocar de mundo.

const PLAZA_SERVICES: Array[StringName] = [&"church", &"theater", &"university", &"town_hall", &"museum", &"school"]
const SLABS := 2
const SLAB_GAP_M := 0.05
const SLAB_THICK_M := 0.1
const SLAB_LIFT_M := 0.03
## O desnível máximo entre os cantos da célula para ela virar laje (encosta fica grama).
const MAX_RELIEF_M := 0.6
const STONE_TONES: Array[Color] = [Color(0.66, 0.64, 0.6), Color(0.6, 0.58, 0.54), Color(0.72, 0.7, 0.65),
		Color(0.56, 0.55, 0.52)]

var _simulation: Simulation
var _slabs := MultiMeshInstance3D.new()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var slab := BoxMesh.new()
	slab.size = Vector3.ONE
	var stone := StandardMaterial3D.new()
	stone.vertex_color_use_as_albedo = true
	stone.vertex_color_is_srgb = true
	stone.roughness = 0.9
	slab.material = stone
	_slabs.name = "Slabs"
	_slabs.multimesh = MultiMesh.new()
	_slabs.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_slabs.multimesh.use_colors = true
	_slabs.multimesh.mesh = slab
	add_child(_slabs)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func slab_count() -> int:
	return _slabs.multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func rebuild() -> void:
	_dirty = false
	var places: Array[Transform3D] = []
	var colors: Array[Color] = []
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for cell: Vector2i in cells(world, _simulation.data, island_id):
			for slab: Array in slabs(grid, cell):
				places.append(slab[0])
				colors.append(slab[1])
	var multimesh := _slabs.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
		multimesh.set_instance_color(i, colors[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As células do largo na ilha: em volta de cada serviço de PLAZA_SERVICES, as livres encostadas nele (lados e cantos),
## de terra, sem árvore e quase planas. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id or record.def_id not in PLAZA_SERVICES:
			continue
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var ring := area.grow(1)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				if area.has_point(cell) or not grid.in_bounds(cell):
					continue
				var index := grid.index(cell)
				if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
						or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				result[cell] = true
	return result


## As lajes de uma célula: [lugar, cor], SLABS × SLABS, cada uma na altura do chão no meio dela, num tom pela posição.
static func slabs(grid: IslandGrid, cell: Vector2i) -> Array[Array]:
	var result: Array[Array] = []
	var size := grid.cell_size / SLABS
	for j: int in SLABS:
		for i: int in SLABS:
			var x := grid.origin_m.x + (cell.x + (i + 0.5) / SLABS) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + (j + 0.5) / SLABS) * grid.cell_size
			var y := grid.height_at(x, z) + SLAB_LIFT_M - SLAB_THICK_M * 0.5
			var basis := Basis.from_scale(Vector3(size - SLAB_GAP_M, SLAB_THICK_M, size - SLAB_GAP_M))
			var tone := STONE_TONES[absi(hash([cell, i, j])) % STONE_TONES.size()]
			result.append([Transform3D(basis, Vector3(x, y, z)), tone])
	return result


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
