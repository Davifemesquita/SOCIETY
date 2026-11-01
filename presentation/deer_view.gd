class_name DeerView
extends Node3D
## Fase 235: os cervos na beira da mata. Numa rede de pontos de HERD_STEP células das ilhas temperadas, a célula de capim livre
## (sem árvore, prédio, estrada nem trilho, quase plana) mais perto do ponto que tenha mata a até EDGE_CELLS e nenhum prédio a até
## WILD_CELLS (longe das vilas, pela regra das focas da Fase 189), com a chance HERD_CHANCE, vira um grupo de duas a quatro corças,
## a primeira um veado de galhada (`herds`, `deer`). O corpo de pé (`body_mesh`) é parado; a cabeça com o pescoço (`head_mesh`,
## `stag_mesh` com a galhada) pasta baixada quase sempre e se ergue de tempos em tempos, cada um no seu ritmo, no tempo de jogo
## (para na pausa; `head_pitch`). Três MultiMesh; nada no save; refeito na obra, na demolição, na estrada, na derrubada de
## árvores e ao trocar de mundo.

const HERD_STEP := 14
const HERD_CHANCE := 0.35
const EDGE_CELLS := 3
const MAX_RELIEF_M := 0.8
## O pescoço (o pivô da cabeça, no alto do peito) e o quanto a cabeça baixa para pastar.
const NECK := Vector3(0.0, 1.0, -0.45)
const GRAZE_RAD := 1.7
const LOOK_EVERY_S := Vector2(7.0, 16.0)
const COAT := Color(0.52, 0.34, 0.2)
const COAT_DARK := Color(0.36, 0.23, 0.14)
const RUMP := Color(0.86, 0.8, 0.68)
const HOOF := Color(0.12, 0.1, 0.08)
const ANTLER := Color(0.62, 0.55, 0.42)

var _simulation: Simulation
var _bodies := MultiMeshInstance3D.new()
var _heads := MultiMeshInstance3D.new()
var _stags := MultiMeshInstance3D.new()
## Cada cervo (o pé no chão, a cabeça para −z), a semente e se tem galhada (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _seeds := PackedInt32Array()
var _antlered: Array[bool] = []
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	for pair: Array in [[_bodies, "DeerBodies", body_mesh()], [_heads, "DeerHeads", head_mesh()], [_stags, "StagHeads",
			stag_mesh()]]:
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


func deer_count() -> int:
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
	_antlered.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		for one: Array in deer(world, _simulation.data, island_id):
			var place: Transform3D = one[0]
			var seed: int = one[1]
			var stag: bool = one[2]
			places.append(place)
			_seeds.append(seed)
			_antlered.append(stag)
	var stags := 0
	for stag: bool in _antlered:
		if stag:
			stags += 1
	_bodies.multimesh.instance_count = places.size()
	_heads.multimesh.instance_count = places.size() - stags
	_stags.multimesh.instance_count = stags
	for i: int in places.size():
		_bodies.multimesh.set_instance_transform(i, places[i])
	advance(0.0)


## Anda o relógio dos cervos seconds de jogo e põe cada cabeça na altura da vez.
func advance(seconds: float) -> void:
	_time += seconds
	var hind := 0
	var stag := 0
	for i: int in places.size():
		var neck := places[i] * Transform3D(Basis(Vector3.RIGHT, -head_pitch(_seeds[i], _time)), NECK)
		if _antlered[i]:
			_stags.multimesh.set_instance_transform(stag, neck)
			stag += 1
		else:
			_heads.multimesh.set_instance_transform(hind, neck)
			hind += 1


## O quanto a cabeça do cervo de semente seed está baixada no instante time (rad): pastando quase sempre, erguendo e olhando em
## volta um pouco a cada volta, cada um com a duração dela.
static func head_pitch(seed_value: int, time: float) -> float:
	var span := lerpf(LOOK_EVERY_S.x, LOOK_EVERY_S.y, float(seed_value % 89) / 88.0)
	var phase := fposmod(time / span + float(seed_value % 23) / 23.0, 1.0)
	return GRAZE_RAD * (1.0 - smoothstep(0.6, 0.68, phase) * (1.0 - smoothstep(0.86, 0.94, phase)))


## O meio de cada grupo da ilha (a célula de capim na beira da mata). Vazio na ilha plana e nas tropicais.
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
	for y: int in range(EDGE_CELLS, grid.size.y - EDGE_CELLS, HERD_STEP):
		for x: int in range(EDGE_CELLS, grid.size.x - EDGE_CELLS, HERD_STEP):
			var pick := FireflyView.cell_hash(island_id, x, y, 235)
			if float(pick % 1000) / 1000.0 >= HERD_CHANCE:
				continue
			var reach := floori(HERD_STEP / 2.0)
			var best := Vector2i(-1, -1)
			for dy: int in range(-reach, reach + 1):
				for dx: int in range(-reach, reach + 1):
					var cell := Vector2i(x + dx, y + dy)
					if best.x >= 0 and absi(dx) + absi(dy) >= absi(best.x - x) + absi(best.y - y):
						continue
					if _meadow(grid, cell):
						best = cell
			if best.x < 0 or SealView._near(built, best):
				continue
			result.append(best)
	return result


## Se a célula é capim livre na beira da mata: terra sem árvore, prédio, estrada nem trilho, quase plana, com árvore a até
## EDGE_CELLS.
static func _meadow(grid: IslandGrid, cell: Vector2i) -> bool:
	if cell.x < EDGE_CELLS or cell.y < EDGE_CELLS or cell.x >= grid.size.x - EDGE_CELLS or cell.y >= grid.size.y - EDGE_CELLS:
		return false
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
			or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0:
		return false
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	if corners.y - corners.x > MAX_RELIEF_M or corners.x < 0.5:
		return false
	for dy: int in range(-EDGE_CELLS, EDGE_CELLS + 1):
		for dx: int in range(-EDGE_CELLS, EDGE_CELLS + 1):
			if grid.trees[index + dy * grid.size.x + dx] > 0:
				return true
	return false


## Os cervos da ilha: [lugar (o pé no chão, a cabeça para −z), semente, se tem galhada (o primeiro de cada grupo)].
static func deer(world: WorldState, data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	for cell: Vector2i in herds(world, data, island_id):
		var seed := FireflyView.cell_hash(island_id, cell.x, cell.y, 2351)
		var count := 2 + seed % 3
		var middle := grid.cell_world(cell)
		for k: int in count:
			var angle := TAU * k / count + float(seed % 360) * PI / 180.0
			var at := middle + Vector3(cos(angle), 0.0, sin(angle)) * (0.9 + 0.6 * float((seed >> (k * 2)) % 3))
			at.y = grid.height_at(at.x, at.z)
			var heading := float((seed >> (k * 4)) % 360) * PI / 180.0
			result.append([Transform3D(Basis(Vector3.UP, heading), at), seed + k * 7919, k == 0])
	return result


## O corpo de pé com o pé no zero e o peito para −z: o tronco, a anca com o espelho claro e o rabo curto, as quatro pernas finas
## com os cascos.
static func body_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.2, 0.24, 0.55)), Vector3(0.0, 0.92, 0.0)), COAT)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.17, 0.2, 0.16)), Vector3(0.0, 0.94, 0.46)), RUMP)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.05, 0.06, 0.05)), Vector3(0.0, 1.06, 0.6)), COAT_DARK)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var hip := Vector3(sx * 0.11, 0.84, sz * 0.36)
			var knee := hip + Vector3(0.0, -0.4, sz * 0.04)
			var foot := Vector3(sx * 0.11, 0.04, sz * 0.36 - 0.02)
			VertexShapes.strut(tool, hip, knee, 0.035, 0.035, COAT)
			VertexShapes.strut(tool, knee, foot, 0.022, 0.022, COAT_DARK)
			VertexShapes.box(tool, foot - Vector3(0.0, 0.02, 0.0), Vector3(0.025, 0.025, 0.03), HOOF)
	tool.generate_normals()
	return tool.commit()


## A cabeça com o pivô no pescoço e o focinho para −z (erguida): o pescoço subindo para a frente, a cabeça afilada, as orelhas e o
## focinho escuro.
static func head_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_head(tool)
	tool.generate_normals()
	return tool.commit()


## A cabeça do veado: a mesma, com a galhada de duas hastes ramificadas.
static func stag_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_head(tool)
	for side: float in [-1.0, 1.0]:
		var base := Vector3(side * 0.05, 0.68, -0.36)
		var beam := base + Vector3(side * 0.16, 0.3, 0.08)
		var top := beam + Vector3(side * 0.06, 0.22, 0.06)
		VertexShapes.strut(tool, base, beam, 0.014, 0.014, ANTLER)
		VertexShapes.strut(tool, beam, top, 0.011, 0.011, ANTLER)
		VertexShapes.strut(tool, base + (beam - base) * 0.35, base + (beam - base) * 0.35 + Vector3(side * 0.02, 0.12, -0.1),
				0.01, 0.01, ANTLER)
		VertexShapes.strut(tool, beam, beam + Vector3(-side * 0.04, 0.12, -0.08), 0.009, 0.009, ANTLER)
	tool.generate_normals()
	return tool.commit()


static func _head(tool: SurfaceTool) -> void:
	VertexShapes.strut(tool, Vector3(0.0, -0.02, 0.06), Vector3(0.0, 0.55, -0.3), 0.075, 0.09, COAT)
	PerchedGullView._blob(tool, Transform3D(Basis(Vector3.RIGHT, 0.5).scaled(Vector3(0.08, 0.08, 0.17)), Vector3(0.0, 0.6,
			-0.42)), COAT)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.035, 0.03, 0.04)), Vector3(0.0, 0.53, -0.57)), HOOF)
	for side: float in [-1.0, 1.0]:
		VertexShapes.tri(tool, Vector3(side * 0.05, 0.66, -0.36), Vector3(side * 0.16, 0.76, -0.32), Vector3(side * 0.07, 0.66,
				-0.3), COAT_DARK)
		VertexShapes.tri(tool, Vector3(side * 0.05, 0.66, -0.36), Vector3(side * 0.07, 0.66, -0.3), Vector3(side * 0.16, 0.76,
				-0.32), COAT_DARK)
