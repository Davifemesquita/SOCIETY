class_name LinenView
extends Node3D
## Fase 223: os lençóis no hospital. Em cada hospital, nas duas células do meio de um lado — o de −X do modelo, depois o de +X e
## por fim o de trás —, pelo `SideYard` e fora dos pátios de lado de antes (`sites`): dois varais compridos em postes de madeira
## ao longo da parede, cada um com SHEETS lençóis brancos pendurados, enfunados de leve (a borda de baixo ondulando), e o cesto
## de vime no chão (`linen_mesh`, no meio das duas células; o material sem descarte de face: o lençol é uma folha só). O
## recheio e as bombas deixam as células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na
## estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"hospital"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.PLUS_X, SideYard.BACK]
## Os varais: a ponta em x, a distância da parede de cada um e a altura do arame.
const LINE_X := 1.85
const LINES_Z: Array[float] = [-0.45, 0.35]
const LINE_M := 1.85
const SHEETS := 4
const SHEET_W_M := 0.78
const SHEET_H_M := 1.15
const BILLOW_M := 0.07
const STEPS := 6
const WHITE := Color(0.93, 0.93, 0.9)
const SHADE := Color(0.8, 0.8, 0.79)
const POST := Color(0.42, 0.32, 0.22)
const WIRE := Color(0.3, 0.3, 0.3)
const WICKER := Color(0.6, 0.48, 0.3)

var _simulation: Simulation
var _lines := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_lines.name = "Linen"
	_lines.multimesh = MultiMesh.new()
	_lines.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_lines.multimesh.mesh = linen_mesh()
	_lines.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_lines.material_override = material
	add_child(_lines)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func linen_count() -> int:
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
			places.append(SideYard.place(grid, pair, side))
	_lines.multimesh.instance_count = places.size()
	for i: int in places.size():
		_lines.multimesh.set_instance_transform(i, places[i])


## Os varais da ilha: id do hospital → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora dos pátios
## de lado de antes.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "linen/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in BarrelRackView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in FirePumpView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in PlaygroundView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in CoalHeapView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in PlankStackView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos varais da ilha (o recheio e as bombas as deixam limpas) → o id do hospital.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## Os varais com o meio entre as duas células na origem (o pé no chão), a parede do hospital em −z (a uma meia célula).
static func linen_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for line: int in LINES_Z.size():
		var z: float = LINES_Z[line]
		for end: float in [-LINE_X, LINE_X]:
			VertexShapes.strut(tool, Vector3(end, 0.0, z), Vector3(end, LINE_M + 0.12, z), 0.04, 0.04, POST)
			VertexShapes.strut(tool, Vector3(end, LINE_M, z - 0.12), Vector3(end, LINE_M, z + 0.12), 0.025, 0.025, POST)
		VertexShapes.strut(tool, Vector3(-LINE_X, LINE_M, z), Vector3(LINE_X, LINE_M, z), 0.006, 0.006, WIRE)
		var span := (LINE_X * 2.0 - 0.3) / SHEETS
		for k: int in SHEETS:
			var x0 := -LINE_X + 0.15 + k * span + (span - SHEET_W_M) * 0.5
			_sheet(tool, Vector3(x0, LINE_M, z), float(k + line * SHEETS))
	# o cesto de vime no chão, junto do primeiro poste
	var basket := Vector3(-LINE_X + 0.45, 0.0, 0.72)
	VertexShapes.cylinder(tool, basket, basket + Vector3(0.0, 0.3, 0.0), 0.22, WICKER, 12)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.18, 0.06, 0.18)), basket + Vector3(0.0, 0.3, 0.0)),
			WHITE)
	tool.generate_normals()
	return tool.commit()


## Um lençol pendurado pela borda de cima em top (do canto de −x): a folha em STEPS faixas descendo, enfunada para +z no meio e com
## a borda de baixo ondulando pela fase; as faixas de baixo um pouco mais escuras (a dobra).
static func _sheet(tool: SurfaceTool, top: Vector3, phase: float) -> void:
	for row: int in STEPS:
		var t0 := float(row) / STEPS
		var t1 := float(row + 1) / STEPS
		for col: int in 3:
			var u0 := float(col) / 3.0
			var u1 := float(col + 1) / 3.0
			var a := _sheet_point(top, u0, t0, phase)
			var b := _sheet_point(top, u1, t0, phase)
			var c := _sheet_point(top, u1, t1, phase)
			var d := _sheet_point(top, u0, t1, phase)
			VertexShapes.quad(tool, a, b, c, d, WHITE.lerp(SHADE, t1 * 0.5))


static func _sheet_point(top: Vector3, u: float, t: float, phase: float) -> Vector3:
	var billow := sin(PI * u) * sin(PI * t * 0.9) * BILLOW_M
	var hem := sin(u * TAU + phase * 1.7) * 0.04 * t
	return top + Vector3(u * SHEET_W_M, -t * SHEET_H_M + hem, billow + 0.012 * sin(phase))
