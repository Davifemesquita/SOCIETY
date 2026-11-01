class_name KennelView
extends Node3D
## Fase 197: a casinha do cão. Nas casas que têm cão na porta (AnimalView.DOG_EVERY pelo id), encostada no lado de −X do lote,
## na fileira da frente, com a porta virada para a rua como a da casa: a casinha de tábuas com o telhado de duas águas, a porta
## em arco e a tigela de água na frente (`kennel_mesh`). Só se a célula do lado onde ela fica está livre (terra sem prédio,
## estrada, trilho nem árvore, quase plana): a célula sai só do lote (`_cell`), para o recheio e as bombas d'água a deixarem
## limpa (`cells`). No lugar do modelo da casa (com o desvio da variação, `BuildingView.model_place`); um MultiMesh; nada no
## save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

## A casinha: a distância do meio dela até a parede de −X e da frente do lote até o meio dela.
const FROM_WALL_M := 0.55
const FROM_FRONT_M := 1.0
const MAX_RELIEF_M := 0.8
const WIDTH_M := 0.72
const DEPTH_M := 0.92
const WALL_M := 0.56
const RIDGE_M := 0.95
const EAVE_OUT_M := 0.1
const PLANK := Color(0.55, 0.4, 0.25)
const PLANK_DARK := Color(0.4, 0.29, 0.18)
const ROOF := Color(0.47, 0.22, 0.15)
const HOLE := Color(0.04, 0.03, 0.03)
const TIN := Color(0.55, 0.56, 0.58)
const WATER := Color(0.22, 0.32, 0.38)

var _simulation: Simulation
var _kennels := MultiMeshInstance3D.new()
## Os lugares das casinhas (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_kennels.name = "Kennels"
	_kennels.multimesh = MultiMesh.new()
	_kennels.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_kennels.multimesh.mesh = kennel_mesh()
	_kennels.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_kennels.material_override = material
	add_child(_kennels)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func kennel_count() -> int:
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
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Transform3D:
			var place: Transform3D = found
			places.append(place)
	_kennels.multimesh.instance_count = places.size()
	for i: int in places.size():
		_kennels.multimesh.set_instance_transform(i, places[i])


## O lugar da casinha da casa (o pé no chão, a porta para −z, para a frente da casa), ou null.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	var found: Variant = _cell(simulation.world, simulation.data, record)
	if found == null:
		return null
	var grid := simulation.world.island(record.island_id)
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var point := model * _local(grid, def)
	point.y = grid.height_at(point.x, point.z)
	return Transform3D(model.basis, point)


## O meio da casinha no referencial do modelo da casa: fora da parede de −X, perto da frente.
static func _local(grid: IslandGrid, def: BuildingDef) -> Vector3:
	var half := Vector2(def.size) * grid.cell_size * 0.5
	return Vector3(-half.x - FROM_WALL_M, 0.0, -half.y + FROM_FRONT_M)


## A célula da casinha, só pelo lote, ou null: casa com cão e a célula do lado livre e quase plana.
static func _cell(world: WorldState, data: GameData, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or record.id % AnimalView.DOG_EVERY != 0:
		return null
	var grid := world.island(record.island_id)
	var def := data.building(record.def_id)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var cell := grid.world_to_cell(model * _local(grid, def))
	if not grid.in_bounds(cell) or grid.building_at(cell) != 0 or grid.has_road(cell) or grid.has_rail(cell) \
			or not grid.is_land(cell) or grid.trees_at(cell) > 0:
		return null
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	if corners.y - corners.x > MAX_RELIEF_M:
		return null
	return cell


## As células das casinhas da ilha → o id da casa.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	if world.island(island_id) == null:
		return result
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id:
			continue
		var found: Variant = _cell(world, data, record)
		if found is Vector2i:
			var cell: Vector2i = found
			result[cell] = id
	return result


## A casinha com o pé no zero e a porta para −z: o soalho, as paredes de tábuas com as frestas, o telhado de duas águas com o
## beiral, a empena da frente com a porta em arco e a de trás, e a tigela de lata com água na frente.
static func kennel_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_w := WIDTH_M * 0.5
	var half_d := DEPTH_M * 0.5
	VertexShapes.box(tool, Vector3(0.0, 0.03, 0.0), Vector3(half_w + 0.03, 0.03, half_d + 0.03), PLANK_DARK)
	VertexShapes.box(tool, Vector3(0.0, WALL_M * 0.5 + 0.03, 0.0), Vector3(half_w, WALL_M * 0.5, half_d), PLANK)
	# as frestas entre as tábuas, nos dois lados
	for side: float in [-1.0, 1.0]:
		for k: int in 3:
			var y := 0.03 + WALL_M * (k + 1) / 4.0
			VertexShapes.box(tool, Vector3(side * (half_w + 0.004), y, 0.0), Vector3(0.004, 0.006, half_d), PLANK_DARK)
	# as empenas (os dois lados de cada triângulo: a malha é fina e a câmera gira)
	var top := WALL_M + 0.03
	for z: float in [-half_d, half_d]:
		var a := Vector3(-half_w, top, z)
		var b := Vector3(half_w, top, z)
		var c := Vector3(0.0, RIDGE_M, z)
		VertexShapes.tri(tool, a, c, b, PLANK)
		VertexShapes.tri(tool, a, b, c, PLANK)
	# o telhado: duas tábuas largas da cumeeira ao beiral, passando um pouco das paredes
	var run := half_w + EAVE_OUT_M
	var rise := (RIDGE_M - top) * run / half_w
	var slope := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	for side: float in [-1.0, 1.0]:
		var middle := Vector3(side * run * 0.5, RIDGE_M + 0.02 - rise * 0.5, 0.0)
		var basis := Basis(Vector3.BACK, -side * angle)
		VertexShapes.oriented_box(tool, Transform3D(basis, middle), Vector3(slope * 0.5, 0.02, half_d + EAVE_OUT_M), ROOF)
	VertexShapes.box(tool, Vector3(0.0, RIDGE_M + 0.03, 0.0), Vector3(0.03, 0.03, half_d + EAVE_OUT_M), PLANK_DARK)
	# a porta em arco na frente
	VertexShapes.box(tool, Vector3(0.0, 0.2, -half_d - 0.006), Vector3(0.16, 0.17, 0.006), HOLE)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.37, -half_d - 0.012), Vector3(0.0, 0.37, -half_d), 0.16, HOLE, 12)
	# a tigela de lata com água, na frente ao lado da porta
	VertexShapes.cylinder(tool, Vector3(0.3, 0.0, -half_d - 0.32), Vector3(0.3, 0.07, -half_d - 0.32), 0.11, TIN, 12)
	VertexShapes.cylinder(tool, Vector3(0.3, 0.07, -half_d - 0.32), Vector3(0.3, 0.071, -half_d - 0.32), 0.09, WATER, 12)
	tool.generate_normals()
	return tool.commit()
