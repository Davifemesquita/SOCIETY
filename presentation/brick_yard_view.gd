class_name BrickYardView
extends Node3D
## Fase 159: o pátio de tijolos da olaria. Em três células em fila encostadas no meio de um lado de cada olaria (o de −X da
## frente, o de trás ou o de +X, que fica por último porque a boca do forno da Fase 137 se abre nele; o primeiro em que as
## três são de terra, sem prédio, estrada, trilho nem árvore, fora do largo e da alameda, e quase planas: `sites`), duas
## fileiras de tijolos crus secando, empilhados em grade (as fiadas alternando de través e ao comprido, com o vão entre os
## tijolos) com duas tábuas estreitas em telhado na cumeeira, e na ponta o monte de barro escavado (`yard_mesh`). O recheio, os silos e as bombas deixam as células limpas (`cells`). Uma malha só para o
## arquipélago; nada no save; refeita na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const BRICKWORKS := &"brickworks"
const MAX_RELIEF_M := 0.8
## As fileiras: o comprimento (quase as três células), a largura, as fiadas e o tijolo cru (comprimento, altura, espessura).
const ROW_LENGTH_M := 4.6
const ROW_WIDTH_M := 0.46
const ROW_SPACING_M := 0.95
const COURSES := 9
const BRICK := Vector3(0.46, 0.09, 0.07)
const BRICK_GAP_M := 0.05
const RAW_CLAY := Color(0.62, 0.4, 0.3)
const DRY_CLAY := Color(0.8, 0.57, 0.42)
const BOARD := Color(0.3, 0.26, 0.22)
const CLAY_HEAP := Color(0.58, 0.31, 0.21)
const HEAP_RADIUS_M := 0.75
const HEAP_HEIGHT_M := 0.7

var _simulation: Simulation
var _yards := MeshInstance3D.new()
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_yards.name = "BrickYards"
	_yards.material_override = material
	add_child(_yards)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func yard_count() -> int:
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
		var found := sites(world, _simulation.data, island_id)
		for id: int in found:
			var site: Array = found[id]
			var middle_cell: Vector2i = site[0]
			var side: Vector2i = site[1]
			var along := Vector2i(side.y, side.x)
			var corners := BuildingKit.corner_range(grid, Rect2i((middle_cell - along).min(middle_cell + along),
					Vector2i.ONE + along.abs() * 2))
			var middle := grid.cell_world(middle_cell)
			# o x do pátio ao longo da parede, o +Z para fora dela (base de mão direita: x = cima × fora)
			var x := Vector3(side.y, 0.0, -side.x)
			var z := Vector3(side.x, 0.0, side.y)
			yard_mesh(tool, Transform3D(Basis(x, Vector3.UP, z), Vector3(middle.x, corners.x, middle.z)))
			_count += 1
	if _count == 0:
		_yards.mesh = null
		return
	tool.generate_normals()
	_yards.mesh = tool.commit()


## Os pátios da ilha: id da olaria → [a célula do meio da fila, o lado da área para onde ela fica]. As três células são a do
## meio e as duas vizinhas ao longo da parede.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == BRICKWORKS:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	if not grid.flat:
		taken.merge(ForecourtView.cells(world, data, island_id))
		taken.merge(AvenueView.cells(world, island_id))
	for id: int in ids:
		var record := world.buildings[id]
		var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var right := Vector2i(-front.y, front.x)
		# o lado de +X da frente fica por último: é onde a boca do forno da Fase 137 se abre
		for side: Vector2i in [-right, -front, right]:
			var middle := SpoilTipView._beside(area, side)
			var along := Vector2i(side.y, side.x)
			var cells: Array[Vector2i] = [middle - along, middle, middle + along]
			var free := true
			for cell: Vector2i in cells:
				if not grid.in_bounds(cell) or taken.has(cell):
					free = false
					break
				var index := grid.index(cell)
				# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
				if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
						or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
					free = false
					break
			if not free:
				continue
			var corners := BuildingKit.corner_range(grid, Rect2i((middle - along).min(middle + along),
					Vector2i.ONE + along.abs() * 2))
			if corners.y - corners.x > MAX_RELIEF_M:
				continue
			for cell: Vector2i in cells:
				taken[cell] = true
			result[id] = [middle, side]
			break
	return result


## As três células de cada pátio da ilha (o recheio, os silos e as bombas as deixam limpas) → o id da olaria.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var found := sites(world, data, island_id)
	for brickworks_id: int in found:
		var site: Array = found[brickworks_id]
		var middle: Vector2i = site[0]
		var side: Vector2i = site[1]
		var along := Vector2i(side.y, side.x)
		for cell: Vector2i in [middle - along, middle, middle + along]:
			result[cell] = brickworks_id
	return result


## O pátio no referencial place (x ao longo da parede, +Z para fora dela, o pé no chão): as duas fileiras de tijolos crus em
## grade com o telhado de tábuas, a de dentro mais seca (mais clara), e o monte de barro na ponta de +X.
static func yard_mesh(tool: SurfaceTool, place: Transform3D) -> void:
	for row: int in 2:
		var z := (row - 0.5) * ROW_SPACING_M
		var color := DRY_CLAY if row == 0 else RAW_CLAY
		_hack(tool, place, Vector3(-0.4, 0.0, z), color)
	_heap(tool, place * Vector3(ROW_LENGTH_M * 0.5 - 0.1, 0.0, 0.0))


## Uma fileira de tijolos crus com o meio do pé em at: as fiadas pares de través, separadas pelo vão; as ímpares em duas
## carreiras ao comprido; e as duas tábuas do telhado por cima, saindo um pouco dos lados.
static func _hack(tool: SurfaceTool, place: Transform3D, at: Vector3, color: Color) -> void:
	var length := ROW_LENGTH_M - 1.2
	var step := BRICK.z + BRICK_GAP_M
	var count := floori(length / step)
	for course: int in COURSES:
		var y := (course + 0.5) * BRICK.y
		if course % 2 == 0:
			for k: int in count:
				var x := -length * 0.5 + (k + 0.5) * step + (BRICK_GAP_M * 0.5 if course % 4 == 2 else 0.0)
				VertexShapes.oriented_box(tool, Transform3D(place.basis, place * (at + Vector3(x, y, 0.0))),
						Vector3(BRICK.z * 0.5, BRICK.y * 0.5, ROW_WIDTH_M * 0.5), color)
		else:
			for lane: float in [-1.0, 1.0]:
				VertexShapes.oriented_box(tool, Transform3D(place.basis, place * (at + Vector3(0.0, y,
						lane * (ROW_WIDTH_M * 0.5 - BRICK.z * 0.5)))), Vector3(length * 0.5, BRICK.y * 0.5, BRICK.z * 0.5), color)
	var top := COURSES * BRICK.y
	for lane: float in [-1.0, 1.0]:
		# duas tábuas estreitas em telhado na cumeeira (o tijolo fica à mostra dos lados)
		var slope := Basis(Vector3.RIGHT, lane * 0.35)
		VertexShapes.oriented_box(tool, Transform3D(place.basis * slope, place * (at + Vector3(0.0, top + 0.07,
				lane * 0.06))), Vector3(length * 0.5 + 0.1, 0.012, 0.075), BOARD)


## O monte de barro escavado: uma cúpula baixa e torta em anéis (HEAP_RINGS: a fração da altura e do raio de cada um), em pé
## no ponto foot.
const HEAP_RINGS: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(0.45, 0.85), Vector2(0.8, 0.55), Vector2(1.0, 0.0)]
const HEAP_SIDES := 12


static func _heap(tool: SurfaceTool, foot: Vector3) -> void:
	var rings: Array[PackedVector3Array] = []
	for ring: Vector2 in HEAP_RINGS:
		var points := PackedVector3Array()
		for i: int in HEAP_SIDES:
			var a := TAU * i / HEAP_SIDES
			var lump := HEAP_RADIUS_M * ring.y * (0.85 + 0.15 * sin(a * 3.0 + ring.x * 2.0))
			points.append(foot + Vector3(cos(a) * lump, ring.x * HEAP_HEIGHT_M, sin(a) * lump * 0.8))
		rings.append(points)
	for r: int in rings.size() - 1:
		var low := rings[r]
		var high := rings[r + 1]
		for i: int in HEAP_SIDES:
			var j := (i + 1) % HEAP_SIDES
			VertexShapes.quad(tool, low[i], low[j], high[j], high[i], CLAY_HEAP.darkened(0.08 * (r % 2)))
