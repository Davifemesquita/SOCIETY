class_name GraveyardView
extends Node3D
## Fase 195: o cemitério da igreja. Atrás de cada igreja, além do anel do largo calçado (Fase 109), ROWS fileiras de células
## da largura dela mais SIDE_CELLS de cada lado; cada célula livre (terra sem prédio, estrada, trilho nem árvore, quase plana,
## fora da alameda e das mesas da taverna) ganha GRAVES_PER_CELL covas lado a lado: a lápide no fundo, virada para a igreja, e
## o montinho de grama ou a moldura de pedra na frente (`cells`, `graves`). A pedra é lápide de topo redondo, cruz ou
## obelisco, pelo hash da cova, e umas tombam um pouco. Um muro baixo de pedra corre pelas bordas, aberto no portão (a célula
## do meio da primeira fileira, do lado da igreja), com dois pilares (`walls`). O recheio deixa as células limpas
## (`ScatterView.island_context`), e as bombas d'água também. Só a ilha com relevo; nada no save; refeito na obra, na
## demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

enum Stone { SLAB, CROSS, OBELISK }

const ROWS := 3
## As fileiras entre a igreja e o cemitério: a primeira é a do largo.
const GAP_ROWS := 1
const SIDE_CELLS := 1
const MAX_RELIEF_M := 0.6
const GRAVES_PER_CELL := 2
## Onde a lápide fica no fundo da célula (do meio para longe da igreja).
const HEAD_BACK_M := 0.62
const MAX_TILT_RAD := 0.09
const TILT_SHARE := 0.3
const WALL_HEIGHT_M := 0.62
const WALL_THICK_M := 0.3
const WALL_INSET_M := 0.16
const WALL_FOOT_M := 0.35
const PILLAR_M := 0.42
const PILLAR_HEIGHT_M := 1.05
const STONE := Color(0.56, 0.56, 0.54)
const MOSS := Color(0.44, 0.47, 0.38)
const GRASS := Color(0.24, 0.31, 0.15)
const GRAVEL := Color(0.6, 0.59, 0.55)
## O tom de cada pedra (multiplica a cor): nova, gasta, com limo, amarelada.
const TONES: Array[Color] = [Color(1.0, 1.0, 1.0), Color(0.84, 0.84, 0.83), Color(0.8, 0.85, 0.74), Color(0.97, 0.93, 0.84)]
const SALT := 195

var _simulation: Simulation
var _stones: Array[MultiMeshInstance3D] = []
var _walls := MultiMeshInstance3D.new()
## As covas por tipo de pedra ([lugar, tom]) e os pedaços de muro (testes: sem tela o MultiMesh devolve transformações zeradas).
var graves: Array[Array] = [[], [], []]
var wall_places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.92
	for kind: int in Stone.values():
		var layer := MultiMeshInstance3D.new()
		layer.name = "Graves%d" % kind
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = true
		layer.multimesh.mesh = stone_mesh(kind)
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = material
		add_child(layer)
		_stones.append(layer)
	_walls.name = "GraveyardWalls"
	_walls.multimesh = MultiMesh.new()
	_walls.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_walls.multimesh.mesh = BoxMesh.new()
	_walls.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_walls.material_override = BuildingMaterials.walls()
	BuildingMaterials.dress(_walls, BuildingMaterials.Wall.STONE, HarborView.STONE_COLOR, 0.0)
	add_child(_walls)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func grave_count() -> int:
	var total := 0
	for list: Array in graves:
		total += list.size()
	return total


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	graves = [[], [], []]
	wall_places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var plan := layout(world, _simulation.data, island_id)
		var cells_of: Dictionary[Vector2i, Vector2i] = plan[0]
		var gates: Dictionary[Vector2i, bool] = plan[1]
		for cell: Vector2i in cells_of:
			for grave: Array in graves_of(grid, island_id, cell, cells_of[cell]):
				var kind: int = grave[0]
				graves[kind].append([grave[1], grave[2]])
		wall_places.append_array(walls(grid, cells_of, gates))
	for kind: int in Stone.values():
		var multimesh := _stones[kind].multimesh
		var list: Array = graves[kind]
		multimesh.instance_count = list.size()
		for i: int in list.size():
			var grave: Array = list[i]
			var place: Transform3D = grave[0]
			var tone: Color = grave[1]
			multimesh.set_instance_transform(i, place)
			multimesh.set_instance_color(i, tone)
	_walls.multimesh.instance_count = wall_places.size()
	for i: int in wall_places.size():
		_walls.multimesh.set_instance_transform(i, wall_places[i])


## As células do cemitério na ilha: célula → o lado que se afasta da igreja. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var plan := layout(world, data, island_id)
	var result: Dictionary[Vector2i, Vector2i] = plan[0]
	return result


## [células → lado que se afasta da igreja, portões]: atrás de cada igreja, além do largo, ROWS fileiras da largura dela mais
## SIDE_CELLS de cada lado, só as livres e quase planas; o portão é a célula do meio da primeira fileira.
static func layout(world: WorldState, data: GameData, island_id: int) -> Array:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var gates: Dictionary[Vector2i, bool] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return [result, gates]
	var churches: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == &"church":
			churches.append(id)
	if churches.is_empty():
		return [result, gates]
	churches.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	taken.merge(AvenueView.cells(world, island_id))
	for cell: Vector2i in TavernGardenView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in churches:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var back := -Footprint.front_direction(record.rotation)
		# a fileira logo atrás da parede de trás (a frente do prédio girado meia volta), esticada dos dois lados
		var row := Footprint.front_cells(record.origin, def.size, record.rotation + 2)
		var step := row[1] - row[0]
		for t: int in range(1, SIDE_CELLS + 1):
			row.push_front(row[0] - step)
			row.append(row[row.size() - 1] + step)
		var middle := row[row.size() / 2]
		for k: int in range(GAP_ROWS, GAP_ROWS + ROWS):
			for base: Vector2i in row:
				var cell := base + back * k
				if result.has(cell) or taken.has(cell) or not grid.in_bounds(cell):
					continue
				var index := grid.index(cell)
				if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
						or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				result[cell] = back
				if k == GAP_ROWS and base == middle:
					gates[cell] = true
	return [result, gates]


## As covas de uma célula: [tipo de pedra, lugar, tom]. A lápide no fundo (HEAD_BACK_M para longe da igreja), lado a lado pela
## largura, na altura do chão; o z do lugar se afasta da igreja (a frente da malha olha para ela).
static func graves_of(grid: IslandGrid, island_id: int, cell: Vector2i, back: Vector2i) -> Array[Array]:
	var result: Array[Array] = []
	var away := Vector3(back.x, 0.0, back.y)
	var across := Vector3.UP.cross(away)
	var center := grid.cell_world(cell)
	var width := grid.cell_size / GRAVES_PER_CELL
	for i: int in GRAVES_PER_CELL:
		var h := FireflyView.cell_hash(island_id, cell.x * GRAVES_PER_CELL + i, cell.y, SALT)
		var kind := h % 3
		var point := center + across * ((i + 0.5) * width - grid.cell_size * 0.5) + away * HEAD_BACK_M
		point.y = grid.height_at(point.x, point.z)
		var basis := Basis(across, Vector3.UP, away)
		if float((h >> 8) % 1000) / 1000.0 < TILT_SHARE:
			# a pedra velha tomba um pouco, para a frente ou de lado
			var lean := MAX_TILT_RAD * (0.4 + 0.6 * float((h >> 18) % 100) / 100.0)
			basis = basis * Basis(Vector3.RIGHT if (h >> 4) % 2 == 0 else Vector3.BACK, lean * (1.0 if (h >> 5) % 2 == 0 else -1.0))
		basis = basis.rotated(Vector3.UP, (float((h >> 12) % 100) / 100.0 - 0.5) * 0.08)
		result.append([kind, Transform3D(basis, point), TONES[(h >> 22) % TONES.size()]])
	return result


## Os pedaços do muro: um por lado de célula do cemitério que não dá para outra célula dele, recuado WALL_INSET_M para dentro;
## no portão o lado da igreja fica aberto, com um pilar em cada ponta.
static func walls(grid: IslandGrid, cells_of: Dictionary[Vector2i, Vector2i], gates: Dictionary[Vector2i, bool]) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var size := grid.cell_size
	for cell: Vector2i in cells_of:
		var center := grid.cell_world(cell)
		for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if cells_of.has(cell + side):
				continue
			var normal := Vector3(side.x, 0.0, side.y)
			var along := Vector3.UP.cross(normal)
			var middle := center + normal * (size * 0.5 - WALL_INSET_M)
			if gates.has(cell) and side == -cells_of[cell]:
				for end: float in [-1.0, 1.0]:
					var foot := middle + along * end * (size * 0.5 - PILLAR_M * 0.5)
					result.append(_block(grid, foot, along, PILLAR_M, PILLAR_M, PILLAR_HEIGHT_M))
				continue
			result.append(_block(grid, middle, along, size, WALL_THICK_M, WALL_HEIGHT_M))
	return result


## Uma caixa do muro com o meio da base em point (no chão), comprida ao longo de along, enterrada WALL_FOOT_M.
static func _block(grid: IslandGrid, point: Vector3, along: Vector3, length: float, thick: float, height: float) -> Transform3D:
	var ground := grid.height_at(point.x, point.z)
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP)) * Basis.from_scale(Vector3(length, height + WALL_FOOT_M, thick))
	return Transform3D(basis, Vector3(point.x, ground + (height - WALL_FOOT_M) * 0.5, point.z))


## A cova com a lápide na origem (no chão), a frente da pedra para −Z, e o montinho ou a moldura para −Z, na direção da igreja.
static func stone_mesh(kind: int) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		Stone.SLAB:
			VertexShapes.box(tool, Vector3(0.0, 0.04, 0.0), Vector3(0.33, 0.08, 0.11), STONE)
			VertexShapes.box(tool, Vector3(0.0, 0.33, 0.0), Vector3(0.26, 0.27, 0.055), STONE)
			VertexShapes.cylinder(tool, Vector3(0.0, 0.6, -0.055), Vector3(0.0, 0.6, 0.055), 0.26, STONE, 12)
			# o limo na base
			VertexShapes.box(tool, Vector3(0.0, 0.1, -0.058), Vector3(0.24, 0.035, 0.003), MOSS)
		Stone.CROSS:
			VertexShapes.box(tool, Vector3(0.0, 0.06, 0.0), Vector3(0.24, 0.1, 0.18), STONE)
			VertexShapes.box(tool, Vector3(0.0, 0.2, 0.0), Vector3(0.16, 0.06, 0.12), STONE)
			VertexShapes.box(tool, Vector3(0.0, 0.7, 0.0), Vector3(0.055, 0.46, 0.055), STONE)
			VertexShapes.box(tool, Vector3(0.0, 0.86, 0.0), Vector3(0.24, 0.055, 0.055), STONE)
		Stone.OBELISK:
			VertexShapes.box(tool, Vector3(0.0, 0.1, 0.0), Vector3(0.22, 0.14, 0.22), STONE)
			VertexShapes.box(tool, Vector3(0.0, 0.27, 0.0), Vector3(0.17, 0.04, 0.17), STONE)
			_needle(tool, 0.31, 1.28, 0.12, 0.07)
	if kind == Stone.OBELISK:
		# a moldura de pedra com o cascalho dentro
		VertexShapes.box(tool, Vector3(0.0, 0.02, -0.72), Vector3(0.28, 0.03, 0.48), GRAVEL)
		for x: float in [-0.31, 0.31]:
			VertexShapes.box(tool, Vector3(x, 0.03, -0.72), Vector3(0.04, 0.06, 0.52), STONE)
		VertexShapes.box(tool, Vector3(0.0, 0.03, -1.22), Vector3(0.35, 0.06, 0.04), STONE)
	else:
		# o montinho de grama
		VertexShapes.box(tool, Vector3(0.0, 0.0, -0.72), Vector3(0.27, 0.09, 0.5), GRASS)
		VertexShapes.box(tool, Vector3(0.0, 0.09, -0.72), Vector3(0.2, 0.04, 0.42), GRASS.darkened(0.08))
	tool.generate_normals()
	return tool.commit()


## O fuste afinando do obelisco, de bottom a top, com a ponta em pirâmide.
static func _needle(tool: SurfaceTool, bottom: float, top: float, low: float, high: float) -> void:
	var corners: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var tip := Vector3(0.0, top + high * 1.6, 0.0)
	for k: int in 4:
		var a := corners[k]
		var b := corners[(k + 1) % 4]
		var a0 := Vector3(a.x * low, bottom, a.y * low)
		var b0 := Vector3(b.x * low, bottom, b.y * low)
		var a1 := Vector3(a.x * high, top, a.y * high)
		var b1 := Vector3(b.x * high, top, b.y * high)
		VertexShapes.quad(tool, a0, b0, b1, a1, STONE)
		VertexShapes.tri(tool, a1, b1, tip, STONE)
