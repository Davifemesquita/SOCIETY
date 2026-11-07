class_name AvenueView
extends Node3D
## Fase 113: a alameda. Ao longo das ruas calçadas, a cada AVENUE_EVERY células (pelo desenho da grade, sem sorteio), a
## célula livre dos dois lados da rua (terra sem prédio, estrada, trilho, árvore nem água, quase plana) ganha uma árvore
## plantada — a faia da Fase 22 reduzida a TREE_SCALE, no meio da célula, com o material da folhagem (balança com o vento).
## O recheio deixa essas células limpas (`ScatterView.island_context`). Nada no save; refeito na obra, na demolição e na
## estrada. Fase 164: cada árvore ganha a caldeira — o anel quadrado de pedra do meio-fio em volta do pé, com a terra escura
## dentro e a grade de ferro por cima (`pit_mesh`), num MultiMesh com o mesmo lugar e giro da árvore (sem a escala dela).

const AVENUE_EVERY := 3
const TREE_SCALE := 0.5
const MAX_RELIEF_M := 0.8
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Fase 164: a caldeira — o lado de fora do anel, a largura e a altura das pedras, a terra e a grade.
const PIT_M := 1.3
const CURB_M := 0.16
const CURB_UP_M := 0.1
const PIT_STONE := Color(0.5, 0.49, 0.46)
const PIT_SOIL := Color(0.2, 0.15, 0.1)
const PIT_IRON := Color(0.16, 0.17, 0.17)

var _simulation: Simulation
var _trees := MultiMeshInstance3D.new()
var _pits := MultiMeshInstance3D.new()
## Os lugares das caldeiras (testes: sem tela o MultiMesh devolve transformações zeradas).
var pit_places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var mesh := TreeModel.mesh(TreeModel.Species.BEECH, 0)
	_trees.name = "AvenueTrees"
	_trees.multimesh = MultiMesh.new()
	_trees.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_trees.multimesh.mesh = mesh
	_trees.material_override = mesh.surface_get_material(0)
	add_child(_trees)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_pits.name = "TreePits"
	_pits.multimesh = MultiMesh.new()
	_pits.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pits.multimesh.mesh = pit_mesh()
	_pits.material_override = material
	_pits.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pits)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func tree_count() -> int:
	return _trees.multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func rebuild() -> void:
	_dirty = false
	var places: Array[Transform3D] = []
	pit_places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for cell: Vector2i in cells(world, island_id):
			var spot := grid.cell_world(cell)
			var turn := float(absi(hash([island_id, cell])) % 360) * PI / 180.0
			var foot := Vector3(spot.x, grid.height_at(spot.x, spot.z), spot.z)
			places.append(Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * TREE_SCALE), foot))
			# a caldeira alinhada com a grade (a rua), não com o giro da árvore
			pit_places.append(Transform3D(Basis.IDENTITY, foot))
	var multimesh := _trees.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	var pits := _pits.multimesh
	pits.instance_count = pit_places.size()
	for i: int in pit_places.size():
		pits.set_instance_transform(i, pit_places[i])
	pits.custom_aabb = WorldBounds.of(_simulation.config)


## Fase 164: a caldeira, com o meio no pé da árvore: as quatro pedras do anel quadrado de PIT_M (um pouco enterradas, para
## acompanhar o chão torto), a terra escura no meio e a grade de ferro em barras cruzadas com o furo do tronco.
static func pit_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := PIT_M * 0.5
	var sink := 0.08
	var middle := (CURB_UP_M - sink) * 0.5
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(0.0, middle, side * (half - CURB_M * 0.5)),
				Vector3(half, (CURB_UP_M + sink) * 0.5, CURB_M * 0.5), PIT_STONE)
		VertexShapes.box(tool, Vector3(side * (half - CURB_M * 0.5), middle, 0.0),
				Vector3(CURB_M * 0.5, (CURB_UP_M + sink) * 0.5, half - CURB_M), PIT_STONE.darkened(0.06))
	var inner := half - CURB_M
	VertexShapes.box(tool, Vector3(0.0, 0.0, 0.0), Vector3(inner, 0.03, inner), PIT_SOIL)
	# a grade: barras de ferro de través nos dois sentidos, fora do furo do tronco
	var top := 0.05
	for k: int in 5:
		var at := -inner + (k + 0.5) * inner * 2.0 / 5.0
		if absf(at) < 0.12:
			continue
		VertexShapes.box(tool, Vector3(at, top, 0.0), Vector3(0.012, 0.012, inner), PIT_IRON)
		VertexShapes.box(tool, Vector3(0.0, top, at), Vector3(inner, 0.012, 0.012), PIT_IRON)
	tool.generate_normals()
	return tool.commit()


## As células da alameda na ilha: as livres encostadas (pelos lados) numa célula de paralelepípedo da vez
## (posmod(x + y, AVENUE_EVERY) = 0), de terra, sem árvore e quase planas.
static func cells(world: WorldState, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var width := grid.size.x
	var flat := grid.corner_heights.is_empty()
	var roads := grid.roads
	var rails := grid.rails
	var trees := grid.trees
	# só as células calçadas (o find anda no array em C++: a ilha inteira a cada obra custaria dezenas de ms)
	var at := roads.find(IslandGrid.Road.PAVED)
	while at >= 0:
		var x := at % width
		var y := at / width
		at = roads.find(IslandGrid.Road.PAVED, at + 1)
		if posmod(x + y, AVENUE_EVERY) != 0:
			continue
		for side: Vector2i in SIDES:
			var cell := Vector2i(x, y) + side
			if not grid.in_bounds(cell):
				continue
			var index := grid.index(cell)
			# (a ilha plana dos testes e dos saves antigos vem sem as camadas de chão, trilho e árvores)
			if grid.ground_at(cell) != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
					or grid.roads[index] != IslandGrid.Road.NONE or (index < rails.size() and rails[index] != 0) \
					or (index < trees.size() and trees[index] > 0):
				continue
			if not flat:
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
			result[cell] = true
	return result


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
