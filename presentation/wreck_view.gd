class_name WreckView
extends Node3D
## Fase 268: o casco naufragado. Numa rede de pontos de WRECK_STEP células da costa das ilhas temperadas, pela regra da costa das
## focas da Fase 189 (`SealView._shore`: terra baixa e quase plana encostada no mar, livre, longe das vilas), com a chance
## WRECK_CHANCE e no máximo MAX_PER_ISLAND por ilha (`sites`): o casco velho de um navio encalhado na areia, de comprido ao longo da
## costa e adernado, só a quilha, a roda de proa, o cadaste e as cavernas, umas quebradas, com um pedaço do costado e o mastro
## partido caído (`wreck_mesh`, `place_of`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada e ao trocar de
## mundo.

const WRECK_STEP := 21
const WRECK_CHANCE := 0.5
const MAX_PER_ISLAND := 2
const SALT := 268
## O comprimento do casco, a meia boca e a altura das cavernas, e quanto ele aderna e afunda na areia.
const LENGTH_M := 9.0
const BEAM_M := 1.5
const DEPTH_M := 1.4
const HEEL_RAD := 0.28
const SINK_M := 0.15
const RIBS := 9
const TIMBER := Color(0.36, 0.31, 0.25)
const TIMBER_DARK := Color(0.24, 0.21, 0.17)
const TIMBER_BLEACHED := Color(0.55, 0.51, 0.45)

var _simulation: Simulation
var _wrecks := MultiMeshInstance3D.new()
## Os lugares dos cascos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wrecks.name = "Wrecks"
	_wrecks.multimesh = MultiMesh.new()
	_wrecks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_wrecks.multimesh.mesh = wreck_mesh()
	_wrecks.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_wrecks.material_override = material
	add_child(_wrecks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func wreck_count() -> int:
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
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := sites(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			places.append(place_of(grid, cell, found[cell], FireflyView.cell_hash(island_id, cell.x, cell.y, SALT)))
	_wrecks.multimesh.instance_count = places.size()
	for i: int in places.size():
		_wrecks.multimesh.set_instance_transform(i, places[i])


## Os cascos da ilha: célula da costa → o lado dela que dá para o mar. Só nas temperadas com relevo, no máximo MAX_PER_ISLAND.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat or world.is_tropical(island_id, data):
		return result
	var built: Dictionary[Vector2i, bool] = {}
	for id: int in world.buildings:
		var record := world.building(id)
		if record.island_id == island_id:
			built[Vector2i(floori(record.origin.x / float(SealView.WILD_CELLS)),
					floori(record.origin.y / float(SealView.WILD_CELLS)))] = true
	var seals := SealView.colonies(world, data, island_id)
	var reach := floori(WRECK_STEP / 2.0)
	for y: int in range(1 + reach, grid.size.y - 1, WRECK_STEP):
		for x: int in range(1 + reach, grid.size.x - 1, WRECK_STEP):
			if result.size() >= MAX_PER_ISLAND:
				return result
			var pick := FireflyView.cell_hash(island_id, x, y, SALT)
			if float(pick % 1000) / 1000.0 >= WRECK_CHANCE:
				continue
			# a célula da costa mais perto do ponto, com as duas vizinhas ao longo da costa também livres (o casco é comprido)
			var best := Vector2i(-1, -1)
			var best_side := Vector2i.ZERO
			for dy: int in range(-reach, reach + 1, 2):
				for dx: int in range(-reach, reach + 1, 2):
					var cell := Vector2i(x + dx, y + dy)
					if best.x >= 0 and absi(dx) + absi(dy) >= absi(best.x - x) + absi(best.y - y):
						continue
					var side := SealView._shore(grid, cell)
					if side == Vector2i.ZERO or seals.has(cell):
						continue
					var along := Vector2i(-side.y, side.x)
					if SealView._shore(grid, cell + along) == Vector2i.ZERO or SealView._shore(grid, cell - along) == Vector2i.ZERO:
						continue
					best = cell
					best_side = side
			if best.x < 0 or SealView._near(built, best):
				continue
			result[best] = best_side
	return result


## O lugar do casco: na célula da costa, um pouco para o mar, de comprido ao longo dela (o x do casco), adernado para o lado do
## mar e afundado SINK_M na areia, a proa para um lado ou o outro pelo sorteio.
static func place_of(grid: IslandGrid, cell: Vector2i, sea: Vector2i, seed: int) -> Transform3D:
	var out := Vector3(sea.x, 0.0, sea.y)
	var along := Vector3(-out.z, 0.0, out.x) * (1.0 if seed % 2 == 0 else -1.0)
	var at := grid.cell_world(cell) + out * grid.cell_size * 0.2
	at.y = TerrainDetail.shown_at(grid, at.x, at.z) - SINK_M
	# o x do casco ao longo da costa, o z para o mar; adernado em volta do x, a borda do lado do mar mais baixa
	var heading := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	return Transform3D(heading * Basis(Vector3.RIGHT, -HEEL_RAD), at)


## O casco com a quilha em y = 0, de comprido em x (a proa em +x): a quilha, a roda de proa e o cadaste curvos, RIBS cavernas em
## U afinando para as pontas (umas quebradas, outras desbotadas pelo sol), duas fiadas do costado de um lado e o mastro partido
## caído de través.
static func wreck_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LENGTH_M * 0.5
	VertexShapes.strut(tool, Vector3(-half * 0.85, 0.0, 0.0), Vector3(half * 0.85, 0.0, 0.0), 0.13, 0.13, TIMBER_DARK)
	# a roda de proa e o cadaste, subindo curvos nas pontas
	var bow: Array[Vector3] = [Vector3(half * 0.85, 0.0, 0.0), Vector3(half * 0.97, 0.5, 0.0), Vector3(half, 1.2, 0.0),
			Vector3(half * 0.97, 1.75, 0.0)]
	var stern: Array[Vector3] = [Vector3(-half * 0.85, 0.0, 0.0), Vector3(-half * 0.92, 0.7, 0.0), Vector3(-half * 0.95, 1.5, 0.0)]
	for k: int in bow.size() - 1:
		VertexShapes.strut(tool, bow[k], bow[k + 1], 0.11, 0.11, TIMBER_DARK)
	for k: int in stern.size() - 1:
		VertexShapes.strut(tool, stern[k], stern[k + 1], 0.12, 0.12, TIMBER_DARK)
	# as cavernas: em U, mais estreitas e baixas nas pontas; a quarta e a sétima quebradas de um lado, a sexta desbotada
	for r: int in RIBS:
		var t := (r + 0.5) / RIBS
		var x := lerpf(-half * 0.78, half * 0.78, t)
		var width := BEAM_M * sin(PI * (0.15 + 0.7 * t))
		var height := DEPTH_M * (0.75 + 0.25 * sin(PI * t))
		var color := TIMBER_BLEACHED if r == 5 else TIMBER
		for side: float in [-1.0, 1.0]:
			if (r == 3 and side > 0.0) or (r == 6 and side < 0.0):
				# quebrada: só o primeiro lance, do pé
				_rib_side(tool, x, side, width, height, color, 1)
				continue
			_rib_side(tool, x, side, width, height, color, 3)
	# duas fiadas do costado ainda pregadas do lado de −z, no meio do casco
	for row: int in 2:
		var y := DEPTH_M * (0.35 + 0.22 * row)
		var z := -BEAM_M * (0.92 + 0.04 * row)
		VertexShapes.box(tool, Vector3(-0.4 + 0.5 * row, y, z), Vector3(half * (0.45 - 0.12 * row), 0.09, 0.03), TIMBER_DARK)
	# o mastro partido caído de través, a ponta para o lado do mar
	VertexShapes.strut(tool, Vector3(0.6, 0.35, 0.1), Vector3(1.3, 0.25, BEAM_M * 2.4), 0.12, 0.09, TIMBER)
	tool.generate_normals()
	return tool.commit()


## Um lado de uma caverna: do pé na quilha, abrindo para fora e subindo até a borda, em até três lances (a quebrada para antes).
static func _rib_side(tool: SurfaceTool, x: float, side: float, width: float, height: float, color: Color, lances: int) -> void:
	var points: Array[Vector3] = [Vector3(x, 0.05, 0.0), Vector3(x, height * 0.25, side * width * 0.75),
			Vector3(x, height * 0.6, side * width), Vector3(x, height, side * width * 1.04)]
	var last := points[0]
	for k: int in range(1, mini(lances + 1, points.size())):
		VertexShapes.strut(tool, last, points[k], 0.07, 0.07, color)
		last = points[k]
