class_name YardWallView
extends Node3D
## Fase 304: o muro dos quintais. Atrás das casas de TIERS nas ilhas temperadas, quando a fileira de células de trás do lote está
## toda livre (terra sem prédio nem estrada), o quintal se fecha: uma divisa no fim dessa fileira e uma de cada lado, da quina de
## trás da casa até ela (`segments`). A divisa dos lados entre duas casas vizinhas sai uma vez só (a chave é o segmento). Pelo hash
## da casa, mureta de pedra seca (`wall_mesh`: pedras de altura e tom sorteados, a capa de pedras deitadas) ou cerca de tábuas
## (`fence_mesh`: esteios, duas travessas e tábuas de pé). Uma malha só para o arquipélago, no relevo; nada no save; refeita na
## obra, na demolição, na subida de classe, na estrada e ao trocar de mundo.

const TIERS: Array[StringName] = [&"peasants", &"workers", &"artisans"]
## Quanto o fundo fica para dentro do fim da fileira (os lados ficam na divisa do lote).
const INSET_M := 0.2
## A mureta: a altura, a largura e o comprimento médio de cada pedra.
const WALL_HEIGHT_M := 0.6
const WALL_WIDTH_M := 0.4
const STONE_M := 0.42
const STONE_COLOR := Color(0.55, 0.53, 0.49)
## A cerca: a altura, o passo dos esteios, a largura das tábuas e a madeira.
const FENCE_HEIGHT_M := 1.05
const POST_STEP_M := 1.5
const BOARD_M := 0.16
const WOOD := Color(0.43, 0.35, 0.26)

enum Kind { WALL, FENCE }

var _simulation: Simulation
var _walls := MeshInstance3D.new()
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.92
	_walls.name = "YardWalls"
	_walls.material_override = material
	add_child(_walls)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func segment_count() -> int:
	return _count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_count = 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for item: Array in segments(world, _simulation.data, island_id):
			var from: Vector2 = item[0]
			var to: Vector2 = item[1]
			var kind: int = item[2]
			if kind == Kind.WALL:
				wall_mesh(tool, grid, from, to)
			else:
				fence_mesh(tool, grid, from, to)
			_count += 1
	if _count == 0:
		_walls.mesh = null
		return
	tool.generate_normals()
	_walls.mesh = tool.commit()


## As divisas dos quintais da ilha: [de, até (x e z do mundo), Kind], cada segmento uma vez.
static func segments(world: WorldState, data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	if grid == null or world.is_tropical(island_id, data):
		return result
	var seen: Dictionary[String, bool] = {}
	var ids := world.buildings.keys()
	ids.sort()
	for id: int in ids:
		var record := world.buildings[id]
		if record.island_id != island_id or not record.is_house() or not TIERS.has(record.tier):
			continue
		var lines := yard_lines(grid, data, record)
		var kind := Kind.WALL if posmod(BuildingView.house_hash(id) / 13, 2) == 0 else Kind.FENCE
		for line: Array in lines:
			var from: Vector2 = line[0]
			var to: Vector2 = line[1]
			var key := _key(from, to)
			if seen.has(key):
				continue
			seen[key] = true
			result.append([from, to, kind])
	return result


## As três divisas do quintal da casa (o fundo e os dois lados) em x e z do mundo, ou nada se a fileira de trás não está livre.
static func yard_lines(grid: IslandGrid, data: GameData, record: BuildingRecord) -> Array[Array]:
	var lines: Array[Array] = []
	var def := data.building(record.def_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var back := -Footprint.front_direction(record.rotation)
	var behind: Array[Vector2i] = []
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y) + back
			if area.has_point(cell):
				continue
			if not grid.in_bounds(cell) or not grid.is_land(cell) or grid.building_at(cell) != 0 or grid.has_road(cell):
				return lines
			behind.append(cell)
	if behind.is_empty():
		return lines
	var size := grid.cell_size
	var out := Vector2(back)
	var along := Vector2(-out.y, out.x)
	var low := behind[0]
	var high := behind[0]
	for cell: Vector2i in behind:
		if Vector2(cell).dot(along) < Vector2(low).dot(along):
			low = cell
		if Vector2(cell).dot(along) > Vector2(high).dot(along):
			high = cell
	# os lados na divisa exata do lote: entre duas casas vizinhas é o mesmo segmento
	var first := _center(grid, low) - along * (size * 0.5)
	var last := _center(grid, high) + along * (size * 0.5)
	var far := out * (size * 0.5 - INSET_M)
	var near := -out * (size * 0.5)
	lines.append([first + far, last + far])
	lines.append([first + near, first + far])
	lines.append([last + near, last + far])
	return lines


static func _center(grid: IslandGrid, cell: Vector2i) -> Vector2:
	var at := grid.cell_world(cell)
	return Vector2(at.x, at.z)


static func _key(from: Vector2, to: Vector2) -> String:
	var a := Vector2i((from * 10.0).round())
	var b := Vector2i((to * 10.0).round())
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var swap := a
		a = b
		b = swap
	return "%d,%d,%d,%d" % [a.x, a.y, b.x, b.y]


static func _place(grid: IslandGrid, at: Vector2, along: Vector2) -> Transform3D:
	var x := Vector3(along.x, 0.0, along.y)
	return Transform3D(Basis(x, Vector3.UP, x.cross(Vector3.UP)), Vector3(at.x, grid.height_at(at.x, at.y), at.y))


## A mureta de pedra seca de from a to: pedras em duas fiadas, de comprimento, altura e tom sorteados pela posição, e a capa.
static func wall_mesh(tool: SurfaceTool, grid: IslandGrid, from: Vector2, to: Vector2) -> void:
	var length := from.distance_to(to)
	if length < 0.1:
		return
	var along := (to - from) / length
	var stones := maxi(1, roundi(length / STONE_M))
	var step := length / stones
	for k: int in stones:
		var at := from + along * (step * (k + 0.5))
		var place := _place(grid, at, along)
		var noise := absi(hash(Vector2i((at * 10.0).round())))
		var tone := 0.85 + float(noise % 100) / 100.0 * 0.3
		var rise := WALL_HEIGHT_M * (0.85 + float(noise / 100 % 100) / 100.0 * 0.3)
		VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, rise * 0.5 - 0.1, 0.0)),
				Vector3(step * 0.47, rise * 0.5 + 0.1, WALL_WIDTH_M * 0.5), STONE_COLOR * tone)
		# a capa: uma pedra deitada por cima, um pouco mais larga
		VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, rise + 0.04, 0.0)),
				Vector3(step * 0.45, 0.05, WALL_WIDTH_M * 0.55), STONE_COLOR * (tone * 0.9))


## A cerca de tábuas de from a to: os esteios a cada POST_STEP_M, duas travessas e as tábuas de pé com uma fresta.
static func fence_mesh(tool: SurfaceTool, grid: IslandGrid, from: Vector2, to: Vector2) -> void:
	var length := from.distance_to(to)
	if length < 0.1:
		return
	var along := (to - from) / length
	var posts := maxi(1, ceili(length / POST_STEP_M))
	for k: int in posts + 1:
		var at := from + along * (length * k / posts)
		VertexShapes.oriented_box(tool, _place(grid, at, along) * Transform3D(Basis.IDENTITY, Vector3(0.0, FENCE_HEIGHT_M * 0.5, 0.0)),
				Vector3(0.06, FENCE_HEIGHT_M * 0.5 + 0.08, 0.06), WOOD * 0.8)
	var boards := maxi(1, floori(length / BOARD_M))
	var step := length / boards
	for k: int in boards:
		var at := from + along * (step * (k + 0.5))
		var place := _place(grid, at, along)
		var noise := absi(hash(Vector2i((at * 10.0).round())))
		var top := FENCE_HEIGHT_M * (0.94 + float(noise % 100) / 100.0 * 0.1)
		VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, top * 0.5 - 0.05, 0.05)),
				Vector3(step * 0.43, top * 0.5 + 0.05, 0.012), WOOD * (0.85 + float(noise / 100 % 100) / 100.0 * 0.3))
		for rail: float in [0.25, 0.8]:
			VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, FENCE_HEIGHT_M * rail, 0.0)),
					Vector3(step * 0.5, 0.04, 0.025), WOOD * 0.75)
