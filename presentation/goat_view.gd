class_name GoatView
extends Node3D
## Fase 251: as cabras nas encostas. Numa rede de pontos de HERD_STEP células das ilhas temperadas, a célula de encosta íngreme
## (terra sem árvore, prédio, estrada nem trilho, com desnível de MIN_RELIEF_M ou mais entre os cantos) mais perto do ponto e sem
## prédio a até WILD_CELLS (longe das vilas, pela regra das focas da Fase 189), com a chance HERD_CHANCE, vira um grupo de duas a
## quatro cabras malhadas, a primeira de pé numa pedra (`herds`, `goats`). O corpo de pé (`body_mesh`: o tronco, as manchas, as
## pernas e o rabo curto) é parado; a cabeça (`head_mesh`: os chifres para trás, as orelhas e a barbicha) pasta baixada quase
## sempre e se ergue de tempos em tempos, cada uma no seu ritmo, no tempo de jogo (para na pausa; `head_pitch`). A pedra é a
## `rock_mesh`. Três MultiMesh; nada no save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de
## mundo.

const HERD_STEP := 12
const HERD_CHANCE := 0.4
const MIN_RELIEF_M := 1.0
## O alto da pedra da primeira cabra, o pescoço (o pivô da cabeça) e o quanto ela baixa para pastar.
const ROCK_M := 0.4
const NECK := Vector3(0.0, 0.62, -0.32)
const GRAZE_RAD := 1.4
const LOOK_EVERY_S := Vector2(6.0, 14.0)
const COAT := Color(0.86, 0.83, 0.76)
const PATCH := Color(0.42, 0.3, 0.2)
const HORN := Color(0.5, 0.45, 0.36)
const HOOF := Color(0.14, 0.12, 0.1)
const STONE := Color(0.52, 0.5, 0.46)

var _simulation: Simulation
var _bodies := MultiMeshInstance3D.new()
var _heads := MultiMeshInstance3D.new()
var _rocks := MultiMeshInstance3D.new()
## Cada cabra (o pé no chão ou na pedra, a cabeça para −z) e a semente (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
## A pedra de cada grupo (o pé no chão).
var rock_places: Array[Transform3D] = []
var _seeds := PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	for pair: Array in [[_bodies, "GoatBodies", body_mesh()], [_heads, "GoatHeads", head_mesh()], [_rocks, "GoatRocks",
			rock_mesh()]]:
		var layer: MultiMeshInstance3D = pair[0]
		layer.name = pair[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = pair[2]
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = material
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_trees)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func goat_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _mark_trees(_island_id: int, _area: Rect2i) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	advance(delta * GameClock.clock.speed_multiplier())


func rebuild() -> void:
	_dirty = false
	places.clear()
	rock_places.clear()
	_seeds.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		for one: Array in goats(world, _simulation.data, island_id):
			var place: Transform3D = one[0]
			var seed: int = one[1]
			var on_rock: bool = one[2]
			places.append(place)
			_seeds.append(seed)
			if on_rock:
				rock_places.append(Transform3D(place.basis, place.origin - Vector3(0.0, ROCK_M, 0.0)))
	_bodies.multimesh.instance_count = places.size()
	_heads.multimesh.instance_count = places.size()
	_rocks.multimesh.instance_count = rock_places.size()
	for i: int in places.size():
		_bodies.multimesh.set_instance_transform(i, places[i])
	for i: int in rock_places.size():
		_rocks.multimesh.set_instance_transform(i, rock_places[i])
	advance(0.0)


## Anda o relógio das cabras seconds de jogo e põe cada cabeça na altura da vez.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in places.size():
		_heads.multimesh.set_instance_transform(i, places[i] * Transform3D(Basis(Vector3.RIGHT, -head_pitch(_seeds[i], _time)),
				NECK))


## O quanto a cabeça da cabra de semente seed está baixada no instante time (rad): pastando quase sempre, erguendo e olhando em
## volta um pouco a cada volta, cada uma com a duração dela.
static func head_pitch(seed_value: int, time: float) -> float:
	var span := lerpf(LOOK_EVERY_S.x, LOOK_EVERY_S.y, float(seed_value % 83) / 82.0)
	var phase := fposmod(time / span + float(seed_value % 29) / 29.0, 1.0)
	return GRAZE_RAD * (1.0 - smoothstep(0.62, 0.7, phase) * (1.0 - smoothstep(0.88, 0.96, phase)))


## O meio de cada grupo da ilha (a célula de encosta). Vazio na ilha plana e nas tropicais.
static func herds(world: WorldState, data: GameData, island_id: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat or world.is_tropical(island_id, data):
		return result
	var built: Dictionary[Vector2i, bool] = {}
	for id: int in world.buildings:
		var record := world.building(id)
		if record.island_id == island_id:
			built[Vector2i(floori(record.origin.x / float(SealView.WILD_CELLS)),
					floori(record.origin.y / float(SealView.WILD_CELLS)))] = true
	for y: int in range(1, grid.size.y - 1, HERD_STEP):
		for x: int in range(1, grid.size.x - 1, HERD_STEP):
			var pick := FireflyView.cell_hash(island_id, x, y, 251)
			if float(pick % 1000) / 1000.0 >= HERD_CHANCE:
				continue
			var reach := floori(HERD_STEP / 2.0)
			var best := Vector2i(-1, -1)
			for dy: int in range(-reach, reach + 1):
				for dx: int in range(-reach, reach + 1):
					var cell := Vector2i(x + dx, y + dy)
					if best.x >= 0 and absi(dx) + absi(dy) >= absi(best.x - x) + absi(best.y - y):
						continue
					if _slope(grid, cell):
						best = cell
			if best.x < 0 or SealView._near(built, best):
				continue
			result.append(best)
	return result


## Se a célula é encosta livre: terra sem árvore, prédio, estrada nem trilho, com desnível de MIN_RELIEF_M ou mais.
static func _slope(grid: IslandGrid, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell):
		return false
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
			or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0:
		return false
	return ScatterView.cell_relief(grid, cell) >= MIN_RELIEF_M


## As cabras da ilha: [lugar (o pé no chão, ou ROCK_M acima na pedra, a cabeça para −z), semente, se está na pedra (a primeira)].
static func goats(world: WorldState, data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	for cell: Vector2i in herds(world, data, island_id):
		var seed := FireflyView.cell_hash(island_id, cell.x, cell.y, 2511)
		var count := 2 + seed % 3
		var middle := grid.cell_world(cell)
		for k: int in count:
			var angle := TAU * k / count + float(seed % 360) * PI / 180.0
			var at := middle + Vector3(cos(angle), 0.0, sin(angle)) * (0.0 if k == 0 else 0.9 + 0.4 * float((seed >> (k * 2)) % 3))
			at.y = TerrainDetail.shown_at(grid, at.x, at.z) + (ROCK_M if k == 0 else 0.0)
			var heading := float((seed >> (k * 4)) % 360) * PI / 180.0
			result.append([Transform3D(Basis(Vector3.UP, heading), at), seed + k * 7919, k == 0])
	return result


## O corpo de pé com o pé no zero e o peito para −z: o tronco claro com as manchas castanhas, as quatro pernas com os cascos e o
## rabo curto erguido.
static func body_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.15, 0.17, 0.36)), Vector3(0.0, 0.58, 0.0)), COAT)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.155, 0.12, 0.14)), Vector3(0.0, 0.62, 0.14)), PATCH)
	VertexShapes.strut(tool, Vector3(0.0, 0.68, 0.33), Vector3(0.0, 0.78, 0.38), 0.025, 0.02, COAT)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var hip := Vector3(sx * 0.08, 0.5, sz * 0.24)
			var foot := Vector3(sx * 0.08, 0.04, sz * 0.24)
			VertexShapes.strut(tool, hip, foot, 0.025, 0.025, PATCH if sz > 0.0 else COAT)
			VertexShapes.box(tool, foot - Vector3(0.0, 0.02, 0.0), Vector3(0.022, 0.022, 0.025), HOOF)
	tool.generate_normals()
	return tool.commit()


## A cabeça com o pivô no pescoço e o focinho para −z (erguida): o pescoço, a cabeça comprida, os dois chifres curvos para trás,
## as orelhas de lado e a barbicha.
static func head_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.strut(tool, Vector3(0.0, -0.04, 0.05), Vector3(0.0, 0.22, -0.12), 0.06, 0.07, COAT)
	PerchedGullView._blob(tool, Transform3D(Basis(Vector3.RIGHT, 0.6).scaled(Vector3(0.06, 0.06, 0.13)), Vector3(0.0, 0.26,
			-0.2)), COAT)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.03, 0.31, -0.16), Vector3(side * 0.05, 0.42, -0.08), 0.012, 0.012, HORN)
		VertexShapes.strut(tool, Vector3(side * 0.05, 0.42, -0.08), Vector3(side * 0.06, 0.4, 0.02), 0.01, 0.01, HORN)
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.BACK, side * 0.5), Vector3(side * 0.08, 0.28, -0.14)),
				Vector3(0.045, 0.015, 0.025), PATCH)
	VertexShapes.strut(tool, Vector3(0.0, 0.18, -0.29), Vector3(0.0, 0.09, -0.27), 0.012, 0.01, PATCH)
	tool.generate_normals()
	return tool.commit()


## A pedra com o pé no zero e o alto em ROCK_M: dois blocos tortos de cantos gastos.
static func rock_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.BACK, 0.08), Vector3(0.0,
			ROCK_M * 0.5 - 0.04, 0.0)), Vector3(0.42, ROCK_M * 0.5 + 0.04, 0.36), STONE)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, -0.3) * Basis(Vector3.RIGHT, 0.12), Vector3(0.28, 0.12, 0.3)),
			Vector3(0.3, 0.16, 0.26), STONE.darkened(0.12))
	tool.generate_normals()
	return tool.commit()
