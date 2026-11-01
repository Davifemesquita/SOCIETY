class_name PlankStackView
extends Node3D
## Fase 215: as tábuas secando na serraria. Em cada serraria, nas duas células do meio de um lado — o de −X do modelo, oposto à
## roda d'água da Fase 13 (que fica em +X), e, se ele não der, o de trás —, de terra, sem prédio, estrada, trilho nem árvore,
## fora do largo e da alameda, e quase planas (`sites`): uma pilha de tábuas por célula, em camadas com os tabiques de través
## entre elas para o ar passar, sobre três dormentes, com três tábuas velhas por cima contra a chuva, e uma pilha mais baixa na
## frente (`stack_mesh`). O recheio e as bombas deixam as células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra,
## na demolição, na estrada, no trilho e ao trocar de mundo.

const SAWMILL := &"sawmill"
const MAX_RELIEF_M := 0.8
## A pilha grande: o comprimento das tábuas (ao longo da parede), as tábuas por camada, as camadas e as medidas da tábua.
const LENGTH_M := 1.8
const BOARDS := 5
const LAYERS := 14
const BOARD_W_M := 0.16
const BOARD_T_M := 0.025
const GAP_M := 0.025
const STICK_M := 0.03
const SLEEPER_M := 0.12
const FRESH := Color(0.74, 0.6, 0.42)
const STICK := Color(0.5, 0.38, 0.25)
const SLEEPER := Color(0.32, 0.26, 0.2)
const WEATHERED := Color(0.4, 0.36, 0.31)

var _simulation: Simulation
var _stacks := MultiMeshInstance3D.new()
## Os lugares (o meio da célula no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_stacks.name = "PlankStacks"
	_stacks.multimesh = MultiMesh.new()
	_stacks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_stacks.multimesh.mesh = stack_mesh()
	_stacks.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_stacks.material_override = material
	add_child(_stacks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func stack_count() -> int:
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
		for id: int in found:
			var site: Array = found[id]
			var pair: Array[Vector2i] = site[0]
			var side: Vector2i = site[1]
			# o x ao longo da parede, o +z para fora dela (base de mão direita: x = cima × fora)
			var x := Vector3(side.y, 0.0, -side.x)
			var z := Vector3(side.x, 0.0, side.y)
			for cell: Vector2i in pair:
				var at := grid.cell_world(cell)
				at.y = BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE)).x
				places.append(Transform3D(Basis(x, Vector3.UP, z), at))
	_stacks.multimesh.instance_count = places.size()
	for i: int in places.size():
		_stacks.multimesh.set_instance_transform(i, places[i])


## As pilhas da ilha: id da serraria → [as duas células, o lado da área para onde elas ficam].
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == SAWMILL:
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
		var model := BuildingView.model_place(grid, record, area)
		# o +X do modelo (a roda d'água) e o +Z (os fundos), na grade
		var wheel := Vector2i(roundi(model.basis.x.x), roundi(model.basis.x.z))
		var back := Vector2i(roundi(model.basis.z.x), roundi(model.basis.z.z))
		for side: Vector2i in [-wheel, back]:
			var pair := _pair(area, side)
			var free := true
			for cell: Vector2i in pair:
				if not _free(grid, cell, taken):
					free = false
					break
			if not free:
				continue
			for cell: Vector2i in pair:
				taken[cell] = true
			result[id] = [pair, side]
			break
	return result


## As duas células do meio do lado side, encostadas na área.
static func _pair(area: Rect2i, side: Vector2i) -> Array[Vector2i]:
	var middle := area.position + area.size / 2
	if side.x > 0:
		return [Vector2i(area.end.x, middle.y - 1), Vector2i(area.end.x, middle.y)]
	if side.x < 0:
		return [Vector2i(area.position.x - 1, middle.y - 1), Vector2i(area.position.x - 1, middle.y)]
	if side.y > 0:
		return [Vector2i(middle.x - 1, area.end.y), Vector2i(middle.x, area.end.y)]
	return [Vector2i(middle.x - 1, area.position.y - 1), Vector2i(middle.x, area.position.y - 1)]


static func _free(grid: IslandGrid, cell: Vector2i, taken: Dictionary[Vector2i, bool]) -> bool:
	if not grid.in_bounds(cell) or taken.has(cell):
		return false
	var index := grid.index(cell)
	# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
	if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
			or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
		return false
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	return corners.y - corners.x <= MAX_RELIEF_M


## As células das pilhas da ilha (o recheio e as bombas as deixam limpas) → o id da serraria.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var found := sites(world, data, island_id)
	for sawmill_id: int in found:
		var site: Array = found[sawmill_id]
		var pair: Array[Vector2i] = site[0]
		for cell: Vector2i in pair:
			result[cell] = sawmill_id
	return result


## As pilhas com o meio da célula na origem (o pé no chão), a parede da serraria em −z (a uma meia célula): a grande encostada
## na parede, as tábuas ao longo de x, e a baixa na frente.
static func stack_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_stack(tool, Vector3(0.0, 0.0, -0.95 + _width(BOARDS) * 0.5), LENGTH_M, BOARDS, LAYERS, true)
	_stack(tool, Vector3(0.1, 0.0, 0.5), LENGTH_M * 0.75, 3, 5, false)
	tool.generate_normals()
	return tool.commit()


static func _width(boards: int) -> float:
	return boards * BOARD_W_M + (boards - 1) * GAP_M


## Uma pilha com o meio do pé em center: três dormentes de través, as camadas de tábuas ao longo de x com os tabiques de
## través entre elas (sobre cada dormente) e, se covered, três tábuas velhas inclinadas por cima.
static func _stack(tool: SurfaceTool, center: Vector3, length: float, boards: int, layers: int, covered: bool) -> void:
	var width := _width(boards)
	var sticks: Array[float] = [-length * 0.5 + 0.12, 0.0, length * 0.5 - 0.12]
	for x: float in sticks:
		VertexShapes.box(tool, center + Vector3(x, SLEEPER_M * 0.5, 0.0), Vector3(0.05, SLEEPER_M * 0.5, width * 0.5 + 0.06),
				SLEEPER)
	var y := SLEEPER_M
	for layer: int in layers:
		for board: int in boards:
			var z := -width * 0.5 + BOARD_W_M * 0.5 + board * (BOARD_W_M + GAP_M)
			# um tom por tábua, pelo lugar dela (sem sorteio)
			var tone := 0.9 + 0.16 * fposmod(sin(float(layer * 7 + board * 13) * 12.9898) * 43758.5453, 1.0)
			VertexShapes.box(tool, center + Vector3(0.0, y + BOARD_T_M * 0.5, z), Vector3(length * 0.5, BOARD_T_M * 0.5,
					BOARD_W_M * 0.5), FRESH * tone)
		y += BOARD_T_M
		if layer == layers - 1:
			break
		for x: float in sticks:
			VertexShapes.box(tool, center + Vector3(x, y + STICK_M * 0.5, 0.0), Vector3(0.02, STICK_M * 0.5, width * 0.5),
					STICK)
		y += STICK_M
	if not covered:
		return
	# as três tábuas velhas da cobertura, caindo para fora da parede, cada uma num tom
	for k: int in 3:
		var z := -width / 3.0 + k * width / 3.0
		var place := Transform3D(Basis(Vector3.RIGHT, 0.12), center + Vector3(0.0, y + 0.06 + (1 - k) * 0.04, z))
		VertexShapes.oriented_box(tool, place, Vector3(length * 0.5 + 0.08, 0.012, width / 6.0 + 0.012),
				WEATHERED * (0.92 + 0.08 * k))
