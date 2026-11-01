class_name PlaygroundView
extends Node3D
## Fase 219: o balanço e a gangorra na escola. Em cada escola, nas duas células do meio de um lado — o de −X do modelo, depois o
## de +X e por fim o de trás (a frente é a da estrada) —, livres pela regra das tábuas da Fase 215 (`sites`, pelo `SideYard`):
## o balanço de madeira em cavalete, com dois assentos de tábua pendurados por cordas, e a gangorra pintada sobre o pé,
## inclinada, com as alças (`playground_mesh`, no meio das duas células). O recheio e as bombas deixam as células limpas
## (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"school"]
## O lado de −X do modelo, depois o de +X e por fim o de trás (a frente é a da estrada).
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.PLUS_X, SideYard.BACK]
## O balanço: as duas pernas de cada cavalete em x, a altura da trave, o afastamento dos pés em z e a altura do assento.
const SWING_X := Vector2(-1.75, -0.15)
const BEAM_M := 2.2
const SPLAY_M := 0.65
const SEAT_M := 0.45
## A gangorra: o pé no meio, o comprimento da tábua e a inclinação.
const SEESAW_X := 1.05
const SEESAW_Z := 0.1
const PLANK_M := 1.6
const PIVOT_M := 0.3
const TILT := 0.36
const WOOD := Color(0.56, 0.42, 0.28)
const WOOD_DARK := Color(0.4, 0.3, 0.2)
const ROPE := Color(0.72, 0.64, 0.48)
const PAINT := Color(0.24, 0.42, 0.3)
const IRON := Color(0.22, 0.22, 0.24)

var _simulation: Simulation
var _yards := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_yards.name = "Playgrounds"
	_yards.multimesh = MultiMesh.new()
	_yards.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_yards.multimesh.mesh = playground_mesh()
	_yards.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_yards.material_override = material
	add_child(_yards)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func playground_count() -> int:
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
	_yards.multimesh.instance_count = places.size()
	for i: int in places.size():
		_yards.multimesh.set_instance_transform(i, places[i])


## Os pátios da ilha: id da escola → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora das tábuas
## e do carvão de um vizinho encostado.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in PlankStackView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in CoalHeapView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos pátios da ilha (o recheio e as bombas as deixam limpas) → o id da escola.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## O balanço e a gangorra com o meio entre as duas células na origem (o pé no chão), a parede da escola em −z (a uma meia
## célula): o balanço na metade de −x, a gangorra na de +x.
static func playground_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# o balanço: dois cavaletes em A, a trave por cima e dois assentos nas cordas
	for x: float in [SWING_X.x, SWING_X.y]:
		var top := Vector3(x, BEAM_M, 0.0)
		for dz: float in [-SPLAY_M, SPLAY_M]:
			VertexShapes.strut(tool, Vector3(x, 0.0, dz), top, 0.045, 0.045, WOOD)
		VertexShapes.strut(tool, Vector3(x, 0.7, -SPLAY_M * 0.68), Vector3(x, 0.7, SPLAY_M * 0.68), 0.03, 0.03, WOOD_DARK)
	VertexShapes.strut(tool, Vector3(SWING_X.x - 0.1, BEAM_M, 0.0), Vector3(SWING_X.y + 0.1, BEAM_M, 0.0), 0.055, 0.055,
			WOOD_DARK)
	var span := SWING_X.y - SWING_X.x
	for k: int in 2:
		var middle := SWING_X.x + span * (0.27 + 0.46 * k)
		# o segundo assento um pouco levado para fora, como se alguém tivesse acabado de descer
		var swing := 0.0 if k == 0 else 0.22
		var seat := Vector3(middle, BEAM_M - (BEAM_M - SEAT_M) * cos(swing), (BEAM_M - SEAT_M) * sin(swing))
		for dx: float in [-0.2, 0.2]:
			VertexShapes.strut(tool, Vector3(middle + dx, BEAM_M - 0.05, 0.0), seat + Vector3(dx, 0.02, 0.0), 0.008, 0.008,
					ROPE)
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, swing), seat), Vector3(0.24, 0.02, 0.1), WOOD)
	# a gangorra: o pé em cavalete, o eixo de ferro, a tábua pintada inclinada e as alças
	var pivot := Vector3(SEESAW_X, PIVOT_M, SEESAW_Z)
	for dz: float in [-0.12, 0.12]:
		VertexShapes.strut(tool, Vector3(SEESAW_X - 0.18, 0.0, SEESAW_Z + dz), pivot + Vector3(0.0, 0.0, dz), 0.035, 0.035,
				WOOD_DARK)
		VertexShapes.strut(tool, Vector3(SEESAW_X + 0.18, 0.0, SEESAW_Z + dz), pivot + Vector3(0.0, 0.0, dz), 0.035, 0.035,
				WOOD_DARK)
	VertexShapes.strut(tool, pivot + Vector3(0.0, 0.0, -0.16), pivot + Vector3(0.0, 0.0, 0.16), 0.02, 0.02, IRON)
	var plank := Basis(Vector3.BACK, TILT)
	VertexShapes.oriented_box(tool, Transform3D(plank, pivot + plank * Vector3(0.0, 0.05, 0.0)), Vector3(PLANK_M * 0.5, 0.025,
			0.11), PAINT)
	for end: float in [-1.0, 1.0]:
		var grip := pivot + plank * Vector3(end * (PLANK_M * 0.5 - 0.22), 0.07, 0.0)
		VertexShapes.strut(tool, grip, grip + plank * Vector3(0.0, 0.2, 0.0), 0.012, 0.012, IRON)
		VertexShapes.strut(tool, grip + plank * Vector3(0.0, 0.2, -0.09), grip + plank * Vector3(0.0, 0.2, 0.09), 0.012, 0.012,
				IRON)
	tool.generate_normals()
	return tool.commit()
