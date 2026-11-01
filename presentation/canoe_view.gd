class_name CanoeView
extends Node3D
## Fase 254: as canoas na margem do rio. Numa rede de pontos de CANOE_STEP células das ilhas com relevo, a célula de terra livre
## (sem árvore, prédio, estrada nem trilho) encostada pelo lado num rio e baixa (até MAX_HEIGHT_M) mais perto do ponto, sem prédio a
## até WILD_CELLS (longe das vilas, pela regra das focas da Fase 189), com a chance CANOE_CHANCE (`banks`): a canoa escavada
## puxada para a margem, de comprido ao longo dela, com o remo e o banco dentro (`canoe_mesh`, `place_of`). Um MultiMesh; nada no
## save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

const CANOE_STEP := 13
const CANOE_CHANCE := 0.55
const MAX_HEIGHT_M := 2.6
## Quanto a canoa sai do meio da célula para o lado do rio e as seções do casco ao longo de z: [z, meia boca em cima, meia boca no
## fundo, altura da borda].
const TOWARD_RIVER := 0.25
const SECTIONS: Array = [[-1.6, 0.0, 0.0, 0.42], [-1.15, 0.22, 0.09, 0.35], [0.0, 0.31, 0.15, 0.32], [1.15, 0.22, 0.09, 0.35],
		[1.6, 0.0, 0.0, 0.42]]
const HULL := Color(0.4, 0.28, 0.18)
const HULL_DARK := Color(0.28, 0.2, 0.13)
const PADDLE := Color(0.56, 0.44, 0.3)

var _simulation: Simulation
var _canoes := MultiMeshInstance3D.new()
## Os lugares das canoas (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_canoes.name = "Canoes"
	_canoes.multimesh = MultiMesh.new()
	_canoes.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_canoes.multimesh.mesh = canoe_mesh()
	_canoes.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_canoes.material_override = material
	add_child(_canoes)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_trees)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func canoe_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _mark_trees(_island_id: int, _area: Rect2i) -> void:
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
		for bank: Array in banks(world, _simulation.data, island_id):
			var cell: Vector2i = bank[0]
			var river: Vector2i = bank[1]
			places.append(place_of(grid, cell, river))
	_canoes.multimesh.instance_count = places.size()
	for i: int in places.size():
		_canoes.multimesh.set_instance_transform(i, places[i])


## As margens da ilha com canoa: [a célula de terra, o lado dela que dá para o rio]. Vazio na ilha plana.
static func banks(world: WorldState, _data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var built: Dictionary[Vector2i, bool] = {}
	for id: int in world.buildings:
		var record := world.building(id)
		if record.island_id == island_id:
			built[Vector2i(floori(record.origin.x / float(SealView.WILD_CELLS)),
					floori(record.origin.y / float(SealView.WILD_CELLS)))] = true
	# as margens saem das células de rio (poucas, achadas pelo find nativo): cada terra encostada nelas vai para o ponto da rede em
	# cuja vizinhança de meio passo ela cai, e fica a mais perto dele (no empate, a de menor dy e depois menor dx: a ordem de uma
	# varredura em linhas). Varrer a vizinhança de todo ponto custava ~160 ms a cada obra na semente 1840.
	var reach := floori(CANOE_STEP / 2.0)
	var width := grid.size.x
	var seen: Dictionary[int, bool] = {}
	var best: Dictionary[Vector2i, Array] = {}
	var at := grid.ground.find(IslandGrid.Ground.RIVER)
	while at >= 0:
		for step: int in [1, -1, width, -width]:
			var index := at + step
			if index < 0 or index >= grid.ground.size() or seen.has(index):
				continue
			seen[index] = true
			var cell := Vector2i(index % width, index / width)
			var river := _river_side(grid, cell)
			if river == Vector2i.ZERO:
				continue
			var point := Vector2i(1 + floori((cell.x - 1 + reach) / float(CANOE_STEP)) * CANOE_STEP,
					1 + floori((cell.y - 1 + reach) / float(CANOE_STEP)) * CANOE_STEP)
			if point.x >= grid.size.x - 1 or point.y >= grid.size.y - 1:
				continue
			var offset := cell - point
			var rank := Vector3i(absi(offset.x) + absi(offset.y), offset.y, offset.x)
			if best.has(point):
				var old: Vector3i = best[point][2]
				if old.x < rank.x or (old.x == rank.x and (old.y < rank.y or (old.y == rank.y and old.z <= rank.z))):
					continue
			best[point] = [cell, river, rank]
		at = grid.ground.find(IslandGrid.Ground.RIVER, at + 1)
	var points: Array[Vector2i] = []
	points.assign(best.keys())
	points.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for point: Vector2i in points:
		var pick := FireflyView.cell_hash(island_id, point.x, point.y, 254)
		if float(pick % 1000) / 1000.0 >= CANOE_CHANCE:
			continue
		var cell: Vector2i = best[point][0]
		if SealView._near(built, cell):
			continue
		result.append([cell, best[point][1]])
	return result


## O lado da célula que dá para o rio, se ela é margem livre e baixa; zero se não. O rio do lado vem antes da altura: quase
## nenhuma célula é margem, e a altura custa (o laço passa por dezenas de milhares de células a cada obra).
static func _river_side(grid: IslandGrid, cell: Vector2i) -> Vector2i:
	if cell.x < 1 or cell.y < 1 or cell.x >= grid.size.x - 1 or cell.y >= grid.size.y - 1:
		return Vector2i.ZERO
	var index := cell.y * grid.size.x + cell.x
	if grid.ground[index] != IslandGrid.Ground.LAND:
		return Vector2i.ZERO
	var side := Vector2i.ZERO
	if grid.ground[index + 1] == IslandGrid.Ground.RIVER:
		side = Vector2i(1, 0)
	elif grid.ground[index + grid.size.x] == IslandGrid.Ground.RIVER:
		side = Vector2i(0, 1)
	elif grid.ground[index - 1] == IslandGrid.Ground.RIVER:
		side = Vector2i(-1, 0)
	elif grid.ground[index - grid.size.x] == IslandGrid.Ground.RIVER:
		side = Vector2i(0, -1)
	if side == Vector2i.ZERO or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
			or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0:
		return Vector2i.ZERO
	var middle := grid.cell_world(cell)
	if grid.height_at(middle.x, middle.z) > MAX_HEIGHT_M:
		return Vector2i.ZERO
	return side


## O lugar da canoa na margem: um pouco para o lado do rio, de comprido ao longo da margem (o z da canoa), no chão, deitada com
## a inclinação dele.
static func place_of(grid: IslandGrid, cell: Vector2i, river: Vector2i) -> Transform3D:
	var middle := grid.cell_world(cell)
	var out := Vector3(river.x, 0.0, river.y)
	var at := middle + out * grid.cell_size * TOWARD_RIVER
	at.y = grid.height_at(at.x, at.z)
	var along := Vector3(-out.z, 0.0, out.x)
	var tip := at + along * 1.4
	var tail := at - along * 1.4
	var rise := grid.height_at(tip.x, tip.z) - grid.height_at(tail.x, tail.z)
	# o −z da canoa para −along (o z dela ao longo da margem)
	var heading := Basis.looking_at(-along)
	return Transform3D(heading * Basis(Vector3.RIGHT, -atan2(rise, 2.8)), at)


## A canoa escavada com a quilha em y = 0, de comprido em z: o casco em seções de través (pontas finas e altas), mais escuro por
## dentro, o banco de través e o remo deitado dentro.
static func canoe_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for section: Array in SECTIONS:
		var z: float = section[0]
		var top: float = section[1]
		var bottom: float = section[2]
		var rim: float = section[3]
		rings.append(PackedVector3Array([Vector3(-top, rim, z), Vector3(-bottom, 0.0, z), Vector3(bottom, 0.0, z),
				Vector3(top, rim, z)]))
	for i: int in rings.size() - 1:
		for k: int in 3:
			var a := rings[i][k]
			var b := rings[i][k + 1]
			var c := rings[i + 1][k + 1]
			var d := rings[i + 1][k]
			VertexShapes.tri(tool, a, b, c, HULL)
			VertexShapes.tri(tool, a, c, d, HULL)
	# o banco de través e o remo deitado no fundo
	VertexShapes.box(tool, Vector3(0.0, 0.22, 0.35), Vector3(0.27, 0.02, 0.07), HULL_DARK)
	VertexShapes.strut(tool, Vector3(0.06, 0.12, -0.9), Vector3(0.1, 0.18, 0.6), 0.018, 0.018, PADDLE)
	VertexShapes.oriented_box(tool, Transform3D(Basis.IDENTITY, Vector3(0.05, 0.1, -1.05)), Vector3(0.08, 0.01, 0.2), PADDLE)
	tool.generate_normals()
	return tool.commit()
