class_name SealView
extends Node3D
## Fase 189: as focas nas pedras. Numa rede de pontos de COLONY_STEP células da costa das ilhas temperadas, a célula de terra
## baixa (LOW_M) e quase plana que encosta no mar pelo lado, sem prédio, estrada nem árvore e sem prédio a até WILD_CELLS
## células (longe das vilas), com a chance COLONY_CHANCE, vira um grupo de duas a quatro focas deitadas na beira, viradas mais
## ou menos para o mar (`colonies`, `seals`). O corpo malhado deitado (`body_mesh`) é parado; a cabeça (`head_mesh`) ergue de
## tempos em tempos, cada foca no seu ritmo, no tempo de jogo (para na pausa; `head_lift`). Dois MultiMesh; nada no save;
## refeito na obra, na demolição, na estrada e ao trocar de mundo.

const COLONY_STEP := 9
const COLONY_CHANCE := 0.3
const WILD_CELLS := 10
const LOW_M := 1.6
const MAX_RELIEF_M := 0.7
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## A foca: o comprimento do corpo, onde fica o pescoço (o pivô da cabeça) e quanto a cabeça ergue.
const BODY_M := 1.7
const NECK := Vector3(0.0, 0.26, -0.62)
const LIFT_RAD := 0.75
const LIFT_EVERY_S := Vector2(5.0, 12.0)
const COAT := Color(0.35, 0.33, 0.3)
const COAT_DARK := Color(0.22, 0.21, 0.19)
const BELLY := Color(0.62, 0.58, 0.5)
const NOSE := Color(0.06, 0.06, 0.06)

var _simulation: Simulation
var _bodies := MultiMeshInstance3D.new()
var _heads := MultiMeshInstance3D.new()
## Cada foca (o pé do corpo no chão, virada com a cabeça para −z) e a semente dela (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _seeds := PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.55
	for pair: Array in [[_bodies, "SealBodies", body_mesh()], [_heads, "SealHeads", head_mesh()]]:
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


func seal_count() -> int:
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
	_seeds.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		for seal: Array in seals(world, _simulation.data, island_id):
			var place: Transform3D = seal[0]
			var seed: int = seal[1]
			places.append(place)
			_seeds.append(seed)
	_bodies.multimesh.instance_count = places.size()
	_heads.multimesh.instance_count = places.size()
	for i: int in places.size():
		_bodies.multimesh.set_instance_transform(i, places[i])
	advance(0.0)


## Anda o relógio das focas seconds de jogo e põe cada cabeça na altura da vez.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in places.size():
		var neck := Transform3D(Basis(Vector3.RIGHT, head_lift(_seeds[i], _time)), NECK)
		_heads.multimesh.set_instance_transform(i, places[i] * neck)


## Quanto a cabeça da foca de semente seed está erguida no instante time (rad): deitada quase sempre, erguendo e baixando
## devagar uma vez por volta, cada uma com a duração dela.
static func head_lift(seed_value: int, time: float) -> float:
	var span := lerpf(LIFT_EVERY_S.x, LIFT_EVERY_S.y, float(seed_value % 89) / 88.0)
	var phase := fposmod(time / span + float(seed_value % 17) / 17.0, 1.0)
	return LIFT_RAD * smoothstep(0.55, 0.65, phase) * (1.0 - smoothstep(0.85, 0.95, phase))


## O meio de cada grupo de focas da ilha (a célula da beira) → o lado dela que dá para o mar. Vazio na ilha plana e nas
## tropicais.
static func colonies(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat or world.is_tropical(island_id, data):
		return result
	# os prédios da ilha em blocos de WILD_CELLS (perto de um bloco com prédio = perto da vila)
	var built: Dictionary[Vector2i, bool] = {}
	for id: int in world.buildings:
		var record := world.building(id)
		if record.island_id == island_id:
			built[Vector2i(floori(record.origin.x / float(WILD_CELLS)), floori(record.origin.y / float(WILD_CELLS)))] = true
	for y: int in range(1, grid.size.y - 1, COLONY_STEP):
		for x: int in range(1, grid.size.x - 1, COLONY_STEP):
			var pick := FireflyView.cell_hash(island_id, x, y, 189)
			if float(pick % 1000) / 1000.0 >= COLONY_CHANCE:
				continue
			# a célula da costa mais perto do ponto, a até meio passo dele
			var best := Vector2i(-1, -1)
			var best_side := Vector2i.ZERO
			var reach := floori(COLONY_STEP / 2.0)
			for dy: int in range(-reach, reach + 1):
				for dx: int in range(-reach, reach + 1):
					var cell := Vector2i(x + dx, y + dy)
					if best.x >= 0 and absi(dx) + absi(dy) >= absi(best.x - x) + absi(best.y - y):
						continue
					var side := _shore(grid, cell)
					if side != Vector2i.ZERO:
						best = cell
						best_side = side
			if best.x < 0 or _near(built, best):
				continue
			result[best] = best_side
	return result


## As focas da ilha: [lugar (o pé no chão, a cabeça para −z, mais ou menos para o mar), semente].
static func seals(world: WorldState, data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	var found := colonies(world, data, island_id)
	for cell: Vector2i in found:
		var sea := Vector3(found[cell].x, 0.0, found[cell].y)
		var along := Vector3(-sea.z, 0.0, sea.x)
		var middle := grid.cell_world(cell)
		var seed := FireflyView.cell_hash(island_id, cell.x, cell.y, 1891)
		var count := 2 + seed % 3
		for k: int in count:
			var at := middle + along * ((k - (count - 1) * 0.5) * 1.1) + sea * (0.35 + 0.25 * (k % 2))
			at.y = grid.height_at(at.x, at.z)
			# a cabeça (−z) para o mar, torta à toa
			var heading := atan2(-sea.x, -sea.z) + (float((seed >> (k * 3)) % 7) - 3.0) * 0.18
			result.append([Transform3D(Basis(Vector3.UP, heading), at), seed + k * 7919])
	return result


static func _shore(grid: IslandGrid, cell: Vector2i) -> Vector2i:
	if not grid.in_bounds(cell):
		return Vector2i.ZERO
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 or grid.trees[index] > 0 \
			or grid.roads[index] != IslandGrid.Road.NONE:
		return Vector2i.ZERO
	var sea := Vector2i.ZERO
	for side: Vector2i in SIDES:
		var next := cell + side
		if grid.in_bounds(next) and grid.ground_at(next) == IslandGrid.Ground.SEA:
			sea = side
			break
	if sea == Vector2i.ZERO:
		return sea
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	if corners.y > LOW_M or corners.y - corners.x > MAX_RELIEF_M:
		return Vector2i.ZERO
	return sea


static func _near(built: Dictionary[Vector2i, bool], cell: Vector2i) -> bool:
	var block := Vector2i(floori(cell.x / float(WILD_CELLS)), floori(cell.y / float(WILD_CELLS)))
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if built.has(block + Vector2i(dx, dy)):
				return true
	return false


## O corpo deitado com o pé no zero e a cabeça para −z: o tronco gordo afinando para a cauda, a barriga clara, as manchas
## escuras e as nadadeiras de trás e da frente.
static func body_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.32, 0.24, 0.55)), Vector3(0.0, 0.22, -0.2)), COAT)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.24, 0.18, 0.4)), Vector3(0.0, 0.17, 0.35)), COAT)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.28, 0.08, 0.5)), Vector3(0.0, 0.07, -0.1)), BELLY)
	for spot: Vector3 in [Vector3(0.18, 0.33, -0.3), Vector3(-0.2, 0.3, -0.05), Vector3(0.12, 0.28, 0.25),
			Vector3(-0.1, 0.38, -0.45)]:
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.07, 0.04, 0.09)), spot), COAT_DARK)
	# as nadadeiras de trás em leque e as da frente encostadas no corpo
	for side: float in [-1.0, 1.0]:
		VertexShapes.tri(tool, Vector3(0.0, 0.1, BODY_M * 0.42), Vector3(side * 0.22, 0.04, BODY_M * 0.62),
				Vector3(side * 0.04, 0.04, BODY_M * 0.66), COAT_DARK)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.05, 0.03, 0.16)), Vector3(side * 0.3, 0.05,
				-0.3)), COAT_DARK)
	tool.generate_normals()
	return tool.commit()


## A cabeça com o pivô no pescoço e o focinho para −z: a cabeça redonda, o focinho, o nariz e os olhos escuros.
static func head_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.17, 0.15, 0.2)), Vector3(0.0, 0.06, -0.12)), COAT)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.1, 0.08, 0.1)), Vector3(0.0, 0.03, -0.28)), COAT)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.035, 0.025, 0.02)), Vector3(0.0, 0.05, -0.37)), NOSE)
	for side: float in [-1.0, 1.0]:
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.025, 0.025, 0.02)), Vector3(side * 0.08, 0.12,
				-0.25)), NOSE)
	tool.generate_normals()
	return tool.commit()
