class_name WellView
extends Node3D
## Fase 201: o poço da vila. Junto de uma casa dos camponeses a cada WELL_EVERY pelo id (resto WELL_REST; as da bomba d'água da
## Fase 132 ficam de fora), na célula livre encostada nela que dá para a rua e fica mais perto da porta, fora do que as outras
## peças já tomam e das bombas (`cells`, pela mesma busca da bomba: `WaterPumpView.beside_street`), o poço de pedra redondo com
## a água escura lá no fundo, os dois esteios com o telhadinho de duas águas, o sarilho com a manivela e o balde pendurado na
## corda (`well_mesh`), com o sarilho de través para a rua. O recheio deixa a célula limpa (`ScatterView.island_context`). Só a
## ilha com relevo; um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, na derrubada de árvores, na subida de
## classe e ao trocar de mundo.

const TIERS: Array[StringName] = [&"peasants"]
const WELL_EVERY := 5
const WELL_REST := 3
const SIDES := 16
## O bocal: o raio de fora e o de dentro, a altura e o fundo da água abaixo da borda.
const OUTER_M := 0.6
const INNER_M := 0.44
const RIM_M := 0.78
const WATER_DOWN_M := 0.55
const POST_X_M := 0.66
const WINDLASS_M := 1.42
const RIDGE_M := 2.12
const EAVE_M := 1.74
const STONE := Color(0.46, 0.44, 0.41)
const STONE_DARK := Color(0.38, 0.37, 0.35)
const STONE_TONES: Array[Color] = [Color(0.52, 0.5, 0.46), Color(0.34, 0.33, 0.31), Color(0.6, 0.57, 0.52),
		Color(0.42, 0.39, 0.35)]
const WATER := Color(0.08, 0.13, 0.15)
const WOOD := Color(0.42, 0.31, 0.2)
const ROOF := Color(0.33, 0.25, 0.18)
const ROPE := Color(0.72, 0.64, 0.46)
const IRON := Color(0.16, 0.16, 0.17)

var _simulation: Simulation
var _wells := MultiMeshInstance3D.new()
## Os lugares dos poços (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_wells.name = "Wells"
	_wells.multimesh = MultiMesh.new()
	_wells.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_wells.multimesh.mesh = well_mesh()
	_wells.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_wells.material_override = material
	add_child(_wells)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func well_count() -> int:
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
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var toward: Vector2i = found[cell]
			var x := grid.origin_m.x + (cell.x + 0.5) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + 0.5) * grid.cell_size
			# a frente (−Z da malha, o sarilho de través) para a rua
			places.append(Transform3D(Basis.looking_at(Vector3(toward.x, 0.0, toward.y), Vector3.UP),
					Vector3(x, grid.height_at(x, z), z)))
	_wells.multimesh.instance_count = places.size()
	for i: int in places.size():
		_wells.multimesh.set_instance_transform(i, places[i])


## As células dos poços na ilha → o lado da rua. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		var none: Dictionary[Vector2i, Vector2i] = {}
		return none
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.is_house() and TIERS.has(record.tier) \
				and posmod(id, WELL_EVERY) == WELL_REST and posmod(id, WaterPumpView.PUMP_EVERY) != 0:
			ids.append(id)
	ids.sort()
	var taken := WaterPumpView.taken_cells(world, data, island_id)
	for cell: Vector2i in WaterPumpView.cells(world, data, island_id):
		taken[cell] = true
	return WaterPumpView.beside_street(world, data, island_id, ids, taken)


## O poço com o pé no zero e a frente para −z: o bocal de pedra em anel com a borda e a água no fundo, os dois esteios em ±x,
## o telhado de duas águas com a cumeeira em x, o sarilho de um esteio ao outro com a manivela em +x, a corda e o balde.
static func well_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ring(tool, INNER_M, OUTER_M, 0.0, RIM_M, STONE, 4)
	# a borda de pedra mais larga em cima e a água lá no fundo
	_ring(tool, INNER_M - 0.02, OUTER_M + 0.05, RIM_M, RIM_M + 0.08, STONE_DARK)
	VertexShapes.cylinder(tool, Vector3(0.0, RIM_M - WATER_DOWN_M - 0.05, 0.0), Vector3(0.0, RIM_M - WATER_DOWN_M, 0.0),
			INNER_M - 0.005, WATER, SIDES)
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(side * POST_X_M, (RIM_M + EAVE_M) * 0.5, 0.0),
				Vector3(0.06, (EAVE_M - RIM_M) * 0.5 + 0.06, 0.06), WOOD)
	# o telhado: duas tábuas largas da cumeeira ao beiral, com a cumeeira por cima
	var run := 0.82
	var rise := RIDGE_M - EAVE_M
	var slope := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	for side: float in [-1.0, 1.0]:
		var basis := Basis(Vector3.RIGHT, side * angle)
		var middle := Vector3(0.0, RIDGE_M - rise * 0.5 + 0.02, side * run * 0.5)
		VertexShapes.oriented_box(tool, Transform3D(basis, middle), Vector3(POST_X_M + 0.18, 0.025, slope * 0.5), ROOF)
	VertexShapes.box(tool, Vector3(0.0, RIDGE_M + 0.03, 0.0), Vector3(POST_X_M + 0.2, 0.035, 0.04), WOOD)
	# o sarilho, a manivela, a corda e o balde
	VertexShapes.cylinder(tool, Vector3(-POST_X_M, WINDLASS_M, 0.0), Vector3(POST_X_M, WINDLASS_M, 0.0), 0.07, WOOD, 10)
	VertexShapes.strut(tool, Vector3(POST_X_M + 0.06, WINDLASS_M, 0.0), Vector3(POST_X_M + 0.06, WINDLASS_M - 0.22, 0.0),
			0.015, 0.015, IRON)
	VertexShapes.strut(tool, Vector3(POST_X_M + 0.06, WINDLASS_M - 0.22, 0.0), Vector3(POST_X_M + 0.2, WINDLASS_M - 0.22,
			0.0), 0.015, 0.015, IRON)
	VertexShapes.strut(tool, Vector3(0.0, WINDLASS_M - 0.07, 0.0), Vector3(0.0, RIM_M + 0.32, 0.0), 0.008, 0.008, ROPE)
	VertexShapes.cylinder(tool, Vector3(0.0, RIM_M + 0.1, 0.0), Vector3(0.0, RIM_M + 0.32, 0.0), 0.12, WOOD, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, RIM_M + 0.26, 0.0), Vector3(0.0, RIM_M + 0.28, 0.0), 0.125, IRON, 10)
	tool.generate_normals()
	return tool.commit()


## Um anel de pedra do raio inner ao outer, de bottom a top: a parede de fora, a de dentro e o topo (na mesma conta de
## VertexShapes.cylinder, virados para fora). Com courses, a parede de fora vira fiadas de blocos desencontrados, cada bloco
## num dos STONE_TONES (o bloco tem dois lados do polígono).
static func _ring(tool: SurfaceTool, inner: float, outer: float, bottom: float, top: float, color: Color,
		courses: int = 1) -> void:
	for i: int in SIDES:
		var a0 := TAU * i / SIDES
		var a1 := TAU * (i + 1) / SIDES
		var p := Vector3(-sin(a0), 0.0, -cos(a0))
		var q := Vector3(-sin(a1), 0.0, -cos(a1))
		var low := Vector3(0.0, bottom, 0.0)
		var high := Vector3(0.0, top, 0.0)
		for row: int in courses:
			var y0 := Vector3(0.0, lerpf(bottom, top, float(row) / courses), 0.0)
			var y1 := Vector3(0.0, lerpf(bottom, top, float(row + 1) / courses), 0.0)
			var tone := color if courses == 1 else STONE_TONES[posmod((i + row % 2) / 2 * 7 + row * 3, STONE_TONES.size())]
			VertexShapes.quad(tool, y0 + p * outer, y1 + p * outer, y1 + q * outer, y0 + q * outer, tone)
		VertexShapes.quad(tool, low + q * inner, high + q * inner, high + p * inner, low + p * inner, color)
		VertexShapes.quad(tool, high + p * inner, high + q * inner, high + q * outer, high + p * outer, color)
