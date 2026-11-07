class_name RabbitView
extends Node3D
## Fase 245: os coelhos no prado. Numa rede de pontos de WARREN_STEP células das ilhas temperadas, a célula de capim aberto (terra
## sem árvore, prédio, estrada nem trilho, quase plana, acima da praia) mais perto do ponto e sem prédio a até WILD_CELLS (longe
## das vilas, pela regra das focas da Fase 189), com a chance WARREN_CHANCE, vira uma toca de três a cinco coelhos espalhados em
## volta (`warrens`, `rabbits`). O coelho (`rabbit_mesh`: o corpo redondo, a cabeça, as orelhas compridas e o rabo branco) pasta
## agachado quase sempre e de tempos em tempos senta nas patas de trás com as orelhas em pé, cada um no seu ritmo, no tempo de
## jogo (para na pausa; `sit_up`). Um MultiMesh sem sombra; nada no save; refeito na obra, na demolição, na estrada, na derrubada
## de árvores e ao trocar de mundo.

const WARREN_STEP := 11
const WARREN_CHANCE := 0.3
const MAX_RELIEF_M := 0.6
## O quanto o coelho se ergue ao sentar (rad, em volta do pé de trás) e de quanto em quanto tempo.
const SIT_RAD := 0.85
const SIT_EVERY_S := Vector2(5.0, 12.0)
const FUR := Color(0.5, 0.4, 0.3)
const FUR_DARK := Color(0.36, 0.28, 0.2)
const TAIL := Color(0.92, 0.9, 0.86)
const EAR := Color(0.6, 0.46, 0.38)
const EYE := Color(0.08, 0.06, 0.05)

var _simulation: Simulation
var _rabbits := MultiMeshInstance3D.new()
## Cada coelho (o pé no chão, a cabeça para −z) e a semente (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _seeds := PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_rabbits.name = "Rabbits"
	_rabbits.multimesh = MultiMesh.new()
	_rabbits.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_rabbits.multimesh.mesh = rabbit_mesh()
	_rabbits.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_rabbits.material_override = material
	_rabbits.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rabbits)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_trees)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rabbit_count() -> int:
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
	_seeds.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		for one: Array in rabbits(world, _simulation.data, island_id):
			var place: Transform3D = one[0]
			var seed: int = one[1]
			places.append(place)
			_seeds.append(seed)
	_rabbits.multimesh.instance_count = places.size()
	advance(0.0)


## Anda o relógio dos coelhos seconds de jogo e põe cada um na pose da vez (sentado ou agachado).
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in places.size():
		_rabbits.multimesh.set_instance_transform(i, places[i] * Transform3D(Basis(Vector3.RIGHT, sit_up(_seeds[i], _time)),
				Vector3.ZERO))


## O quanto o coelho de semente seed está erguido no instante time (rad, em volta do pé de trás): agachado pastando quase sempre,
## sentado com as orelhas em pé um pouco a cada volta, cada um com a duração dela.
static func sit_up(seed_value: int, time: float) -> float:
	var span := lerpf(SIT_EVERY_S.x, SIT_EVERY_S.y, float(seed_value % 97) / 96.0)
	var phase := fposmod(time / span + float(seed_value % 31) / 31.0, 1.0)
	return SIT_RAD * smoothstep(0.7, 0.76, phase) * (1.0 - smoothstep(0.9, 0.96, phase))


## O meio de cada toca da ilha (a célula de capim aberto). Vazio na ilha plana e nas tropicais.
static func warrens(world: WorldState, data: GameData, island_id: int) -> Array[Vector2i]:
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
	for y: int in range(1, grid.size.y - 1, WARREN_STEP):
		for x: int in range(1, grid.size.x - 1, WARREN_STEP):
			var pick := FireflyView.cell_hash(island_id, x, y, 245)
			if float(pick % 1000) / 1000.0 >= WARREN_CHANCE:
				continue
			var reach := floori(WARREN_STEP / 2.0)
			var best := Vector2i(-1, -1)
			for dy: int in range(-reach, reach + 1):
				for dx: int in range(-reach, reach + 1):
					var cell := Vector2i(x + dx, y + dy)
					if best.x >= 0 and absi(dx) + absi(dy) >= absi(best.x - x) + absi(best.y - y):
						continue
					if _open(grid, cell):
						best = cell
			if best.x < 0 or SealView._near(built, best):
				continue
			result.append(best)
	return result


## Se a célula é capim aberto: terra sem árvore, prédio, estrada nem trilho, quase plana e acima da praia.
static func _open(grid: IslandGrid, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell):
		return false
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
			or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0:
		return false
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	return corners.y - corners.x <= MAX_RELIEF_M and corners.x >= 1.5


## Os coelhos da ilha: [lugar (o pé no chão, a cabeça para −z), semente].
static func rabbits(world: WorldState, data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	for cell: Vector2i in warrens(world, data, island_id):
		var seed := FireflyView.cell_hash(island_id, cell.x, cell.y, 2451)
		var count := 3 + seed % 3
		var middle := grid.cell_world(cell)
		for k: int in count:
			var angle := TAU * k / count + float(seed % 360) * PI / 180.0
			var at := middle + Vector3(cos(angle), 0.0, sin(angle)) * (0.5 + 0.35 * float((seed >> (k * 2)) % 4))
			at.y = TerrainDetail.shown_at(grid, at.x, at.z)
			var heading := float((seed >> (k * 3)) % 360) * PI / 180.0
			result.append([Transform3D(Basis(Vector3.UP, heading), at), seed + k * 7919])
	return result


## O coelho agachado com o pé de trás no zero e a cabeça para −z: o corpo redondo, a cabeça baixa na frente, as duas orelhas
## compridas em pé, pendendo para trás, os olhos escuros, o rabo branco e as patas.
static func rabbit_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.1, 0.09, 0.14)), Vector3(0.0, 0.1, -0.08)), FUR)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.065, 0.065, 0.075)), Vector3(0.0, 0.15, -0.23)), FUR)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.035, 0.035, 0.03)), Vector3(0.0, 0.13, 0.06)), TAIL)
	for side: float in [-1.0, 1.0]:
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, 0.5) * Basis(Vector3.BACK, side * 0.15),
				Vector3(side * 0.03, 0.265, -0.175)), Vector3(0.018, 0.075, 0.006), EAR)
		VertexShapes.box(tool, Vector3(side * 0.05, 0.17, -0.27), Vector3(0.008, 0.01, 0.008), EYE)
		VertexShapes.box(tool, Vector3(side * 0.05, 0.02, -0.17), Vector3(0.02, 0.02, 0.03), FUR_DARK)
		VertexShapes.box(tool, Vector3(side * 0.06, 0.025, 0.0), Vector3(0.025, 0.025, 0.06), FUR_DARK)
	tool.generate_normals()
	return tool.commit()
