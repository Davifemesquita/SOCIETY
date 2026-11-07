class_name DovecoteView
extends Node3D
## Fase 191: o pombal. Numa fazenda de FARMS a cada DOVECOTE_EVERY pelo id, na célula livre e quase plana logo depois do canto
## da frente de +X do lote, na diagonal (fora do caminho da porta, das medas, do silo e das colmeias), o poste com a casinha de
## pombos de tábua — as fileiras de buracos com o poleiro, o telhado de quatro águas — (`spot`, `dovecote_mesh`) e PIGEONS
## pombos pousados no telhadinho e no poleiro (o pombo pousado da `BirdView`), virando de tempos em tempos como as gaivotas do
## cais (o relógio para na pausa). Só a ilha com relevo; dois MultiMesh; nada no save; refeito na obra, na demolição, na
## estrada e ao trocar de mundo.

const FARMS: Array[StringName] = [&"sheep_farm", &"pig_farm", &"wheat_farm", &"potato_farm"]
const DOVECOTE_EVERY := 2
const DOVECOTE_REST := 0
const MAX_RELIEF_M := 0.8
## O pombal: a altura do poste, a casinha e o telhado.
const POLE_M := 2.6
const HOUSE_HALF := Vector3(0.38, 0.32, 0.38)
const ROOF_M := 0.42
const PIGEONS := 4
const WOOD := Color(0.62, 0.55, 0.45)
const WOOD_DARK := Color(0.4, 0.32, 0.24)
const HOLE := Color(0.06, 0.05, 0.04)
const ROOF := Color(0.45, 0.24, 0.18)
## Onde cada pombo pousa, no referencial do pombal (o alto do telhado e o poleiro da frente e do lado).
const PERCHES: Array[Vector3] = [Vector3(0.0, POLE_M + HOUSE_HALF.y * 2.0 + ROOF_M, 0.0),
		Vector3(-0.15, POLE_M + HOUSE_HALF.y * 0.62, -HOUSE_HALF.z - 0.09),
		Vector3(0.18, POLE_M + HOUSE_HALF.y * 0.62, -HOUSE_HALF.z - 0.09),
		Vector3(HOUSE_HALF.x + 0.09, POLE_M + HOUSE_HALF.y * 0.62, 0.1)]

var _simulation: Simulation
var _dovecotes := MultiMeshInstance3D.new()
var _pigeons := MultiMeshInstance3D.new()
## Os pés dos pombais e os poleiros dos pombos, com as sementes (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var perches: Array[Vector3] = []
var _seeds := PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	# o beiral do telhadinho é visto por baixo
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for pair: Array in [[_dovecotes, "Dovecotes", dovecote_mesh()], [_pigeons, "DovecotePigeons", BirdView.perched_mesh()]]:
		var layer: MultiMeshInstance3D = pair[0]
		var label: String = pair[1]
		var mesh: ArrayMesh = pair[2]
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
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func dovecote_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	advance(delta * GameClock.clock.speed_multiplier())


func rebuild() -> void:
	_dirty = false
	places.clear()
	perches.clear()
	_seeds.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Transform3D:
			var place: Transform3D = found
			places.append(place)
			for k: int in PIGEONS:
				perches.append(place * PERCHES[k])
				_seeds.append(FireflyView.cell_hash(id, k, 0, 191))
	_dovecotes.multimesh.instance_count = places.size()
	for i: int in places.size():
		_dovecotes.multimesh.set_instance_transform(i, places[i])
	_pigeons.multimesh.instance_count = perches.size()
	advance(0.0)


## Anda o relógio dos pombos seconds de jogo e põe cada um virado para o lado da vez dele.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in perches.size():
		var heading := PerchedGullView.heading_at(_seeds[i], _time)
		_pigeons.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, heading), perches[i]))


## O pé do pombal da fazenda (mundo) ou null: só nas fazendas de FARMS do resto certo, na ilha com relevo, com a célula do
## canto livre e quase plana.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or record.def_id not in FARMS or posmod(record.id, DOVECOTE_EVERY) != DOVECOTE_REST:
		return null
	var grid := simulation.world.island(record.island_id)
	if grid == null or grid.flat:
		return null
	var def := simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var front := Footprint.front_direction(record.rotation)
	var right := Vector2i(-front.y, front.x)
	# o canto da frente do lado +X: a célula na diagonal, fora do lote
	var middle := area.position + area.size / 2
	var reach := Vector2i(area.size.x / 2 + 1, area.size.y / 2 + 1)
	var cell := middle + Vector2i(front.x * reach.x + right.x * reach.x, front.y * reach.y + right.y * reach.y)
	if not grid.in_bounds(cell):
		return null
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
			or grid.rails[index] != 0 or grid.trees[index] > 0:
		return null
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	if corners.y - corners.x > MAX_RELIEF_M:
		return null
	var at := grid.cell_world(cell)
	# a frente da casinha (−z) para o lado da frente da fazenda
	var facing := atan2(-float(front.x), -float(front.y))
	return Transform3D(Basis(Vector3.UP, facing), Vector3(at.x, corners.x - 0.05, at.z))


## O pombal com o pé no zero e a frente para −z: o poste com as escoras, a casinha de tábua com as três fileiras de buracos e
## o poleiro na frente e no lado, e o telhado de quatro águas com a beira saindo.
static func dovecote_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, POLE_M * 0.5, 0.0), Vector3(0.07, POLE_M * 0.5, 0.07), WOOD_DARK)
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		VertexShapes.strut(tool, side * 0.45, Vector3(0.0, 0.6, 0.0) + side * 0.05, 0.03, 0.03,
				WOOD_DARK)
	var center := Vector3(0.0, POLE_M + HOUSE_HALF.y, 0.0)
	VertexShapes.box(tool, center, HOUSE_HALF, WOOD)
	# as bocas: duas fileiras na frente e no lado de +x, com o poleiro embaixo de cada fileira
	for row: int in 2:
		var y := POLE_M + HOUSE_HALF.y * (0.75 + row * 0.75)
		for col: int in 3:
			var t := (col - 1) * 0.22
			VertexShapes.box(tool, Vector3(t, y, -HOUSE_HALF.z - 0.005), Vector3(0.05, 0.06, 0.01), HOLE)
			VertexShapes.box(tool, Vector3(HOUSE_HALF.x + 0.005, y, t), Vector3(0.01, 0.06, 0.05), HOLE)
		VertexShapes.box(tool, Vector3(0.0, y - 0.1, -HOUSE_HALF.z - 0.06), Vector3(HOUSE_HALF.x * 0.95, 0.015, 0.06),
				WOOD_DARK)
		VertexShapes.box(tool, Vector3(HOUSE_HALF.x + 0.06, y - 0.1, 0.0), Vector3(0.06, 0.015, HOUSE_HALF.z * 0.95),
				WOOD_DARK)
	# o telhado de quatro águas, com a beira saindo 0,12 m
	var eave := POLE_M + HOUSE_HALF.y * 2.0
	var top := Vector3(0.0, eave + ROOF_M, 0.0)
	var reach := HOUSE_HALF.x + 0.12
	var corners: Array[Vector3] = [Vector3(-reach, eave, -reach), Vector3(reach, eave, -reach), Vector3(reach, eave, reach),
			Vector3(-reach, eave, reach)]
	for k: int in 4:
		VertexShapes.tri(tool, corners[k], top, corners[(k + 1) % 4], ROOF)
		VertexShapes.tri(tool, corners[k], corners[(k + 1) % 4], top - Vector3(0.0, ROOF_M + 0.02, 0.0), ROOF)
	tool.generate_normals()
	return tool.commit()
