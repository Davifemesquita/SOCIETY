class_name ButterflyView
extends Node3D
## Fase 180: as borboletas. Numa rede de pontos de GROUP_STEP células, o ponto em terra sem árvore, prédio, estrada nem trilho
## vira um grupo de borboletas: nas ilhas temperadas, só se ele cai num canteiro de papoulas (`ScatterView.poppy_patch`); nas
## tropicais, no capim aberto com a chance TROPICAL_CHANCE (`groups`). Cada grupo tem PER_GROUP borboletas de espécies sorteadas
## (branca, amarela, laranja, azul) a GROUP_HEIGHT_M do chão; o `shaders/butterfly.gdshader` as faz esvoaçar e bater as asas no
## tempo visual. Um MultiMesh do arquipélago, escondido à noite; nada no save; refeito (só quando à vista) na obra, na demolição,
## na estrada, nas árvores e ao trocar de mundo.

const GROUP_STEP := 5
const PER_GROUP := 3
const TROPICAL_CHANCE := 0.08
const GROUP_HEIGHT_M := 0.7
## A borboleta (maior que a de verdade, para se ver da câmera do jogo): a meia envergadura e o comprimento da asa
## e do corpo.
const SPAN_M := 0.22
const WING_M := 0.18
const BODY_M := 0.14
## Até quanto da noite (DayClock.night_factor) elas aparecem.
const HIDE_AT := 0.3

var _simulation: Simulation
var _flock := MultiMeshInstance3D.new()
## Onde fica cada borboleta (o meio da volta dela) e a espécie (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Vector3] = []
var kinds: PackedInt32Array = PackedInt32Array()
## Os grupos de cada ilha (refeitos só na ilha que mudou: IslandDirty).
var _by_island: Dictionary[int, Array] = {}
var _changes := IslandDirty.new()


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/butterfly.gdshader") as Shader
	_flock.name = "Butterflies"
	_flock.multimesh = MultiMesh.new()
	_flock.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_flock.multimesh.use_custom_data = true
	_flock.multimesh.mesh = butterfly_mesh()
	_flock.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_flock.material_override = material
	_flock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flock.visible = false
	add_child(_flock)
	EventBus.building_placed.connect(_mark_building)
	EventBus.building_removed.connect(_mark_building)
	EventBus.roads_changed.connect(_mark_island)
	EventBus.trees_changed.connect(_mark_area)
	EventBus.world_replaced.connect(_on_world_replaced)


func butterfly_count() -> int:
	return places.size()


func _mark_building(building_id: int) -> void:
	_changes.mark_building(_simulation.world, building_id)


func _mark_island(island_id: int) -> void:
	_changes.mark_island(island_id)


func _mark_area(island_id: int, _area: Rect2i) -> void:
	_changes.mark_island(island_id)


func _on_world_replaced() -> void:
	_by_island.clear()
	_changes.mark_all()


func _process(_delta: float) -> void:
	if _simulation == null:
		return
	var night := DayClock.night_factor(_simulation.config, GameClock.clock.hour())
	_flock.visible = night < HIDE_AT
	if _flock.visible and _changes.pending():
		rebuild()


func rebuild() -> void:
	places.clear()
	kinds.clear()
	var world := _simulation.world
	for island_id: int in _changes.take(world):
		_by_island[island_id] = groups(world, _simulation.data, island_id)
	for island_id: int in world.islands.size():
		if not _by_island.has(island_id):
			continue
		var centers: Array[Vector3] = _by_island[island_id]
		for center: Vector3 in centers:
			for k: int in PER_GROUP:
				places.append(center)
				kinds.append(FireflyView.cell_hash(roundi(center.x * 10.0), roundi(center.z * 10.0), k, 180) % 4)
	var multimesh := _flock.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, places[i]))
		var seed := FireflyView.cell_hash(i, 0, 0, 1801)
		multimesh.set_instance_custom_data(i, Color(float(seed % 997) / 997.0, float(seed / 997 % 991) / 991.0,
				float(seed / 997 / 991 % 13) / 13.0, kinds[i] / 4.0))


## O meio de cada grupo de borboletas da ilha (mundo, GROUP_HEIGHT_M acima do chão). Vazio na ilha plana.
static func groups(world: WorldState, data: GameData, island_id: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var tropical := world.is_tropical(island_id, data)
	var width := grid.size.x
	# os arrays da grade em variáveis locais: o laço passa por milhares de pontos
	var ground := grid.ground
	var trees := grid.trees
	var occupancy := grid.occupancy
	var roads := grid.roads
	var rails := grid.rails
	for y: int in range(1, grid.size.y - 1, GROUP_STEP):
		for x: int in range(1, width - 1, GROUP_STEP):
			var pick := FireflyView.cell_hash(island_id, x, y, 1802)
			var cell := Vector2i(x + pick % 3 - 1, y + pick / 3 % 3 - 1)
			var index := cell.y * width + cell.x
			if ground[index] != IslandGrid.Ground.LAND or trees[index] > 0 or occupancy[index] != 0 \
					or roads[index] != IslandGrid.Road.NONE or rails[index] != 0:
				continue
			if tropical:
				if float(pick / 9 % 1000) / 1000.0 >= TROPICAL_CHANCE:
					continue
			elif not ScatterView.poppy_patch(island_id, cell):
				continue
			var at := grid.cell_world(cell)
			result.append(Vector3(at.x, grid.height_at(at.x, at.z) + GROUP_HEIGHT_M, at.z))
	return result


## A borboleta de asas abertas no plano xz, o corpo ao longo de z: o corpo fino no meio e, de cada lado, a asa da frente maior
## e a de trás menor. O UV.x é a distância do corpo até a ponta (o shader escurece a borda e dobra a asa por ela).
static func butterfly_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# o corpo: uma fita fina ao longo de z
	_vertex(tool, Vector3(-0.006, 0.002, -BODY_M * 0.5), 0.0)
	_vertex(tool, Vector3(0.006, 0.002, -BODY_M * 0.5), 0.0)
	_vertex(tool, Vector3(0.006, 0.002, BODY_M * 0.5), 0.0)
	_vertex(tool, Vector3(-0.006, 0.002, -BODY_M * 0.5), 0.0)
	_vertex(tool, Vector3(0.006, 0.002, BODY_M * 0.5), 0.0)
	_vertex(tool, Vector3(-0.006, 0.002, BODY_M * 0.5), 0.0)
	for side: float in [-1.0, 1.0]:
		var root := 0.015 * side
		# a asa da frente (para −z) e a de trás, cada uma um quadrilátero do corpo até a ponta
		for wing: Array in [[-0.02, Vector3(SPAN_M * side, 0.0, -WING_M), Vector3(SPAN_M * 0.85 * side, 0.0, 0.0), 0.0],
				[0.0, Vector3(SPAN_M * 0.55 * side, 0.0, 0.0), Vector3(SPAN_M * 0.75 * side, 0.0, WING_M * 0.85), 0.02]]:
			var front_z: float = wing[0]
			var outer: Vector3 = wing[1]
			var inner: Vector3 = wing[2]
			var back_z: float = wing[3]
			var front := Vector3(root, 0.0, front_z)
			var back := Vector3(root, 0.0, back_z)
			for corner: Array in [[front, 0.0], [outer, 1.0], [inner, 1.0], [front, 0.0], [inner, 1.0], [back, 0.0]]:
				var point: Vector3 = corner[0]
				var out: float = corner[1]
				_vertex(tool, point, out)
	return tool.commit()


static func _vertex(tool: SurfaceTool, point: Vector3, out: float) -> void:
	tool.set_uv(Vector2(out, 0.0))
	tool.set_normal(Vector3.UP)
	tool.add_vertex(point)
