class_name ScaleView
extends Node3D
## Fase 250: a balança de carga no armazém. Em cada armazém, nas duas células do meio de um lado — o de −X do modelo, depois o de
## trás e por fim o de +X —, pelo `SideYard` (`sites`): a balança decimal de plataforma (o estrado de tábuas no chassi de ferro com
## as rodinhas, a coluna de trás com o travessão e o prato dos pesos pendurado, os pesos empilhados), um saco deitado em cima dela e
## os sacos de pé, amarrados, e os pesos soltos esperando ao lado (`scale_mesh`, `_sack`, no meio das duas células). O recheio e as
## bombas deixam as células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e
## ao trocar de mundo.

const KINDS: Array[StringName] = [&"warehouse"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.BACK, SideYard.PLUS_X]
## A balança: o meio em x, as meias medidas do estrado, a altura dele e a da coluna.
const SCALE_X := -0.6
const DECK_HALF := Vector2(0.45, 0.32)
const DECK_M := 0.22
const COLUMN_M := 1.15
const IRON := Color(0.22, 0.24, 0.24)
const PAINT := Color(0.24, 0.34, 0.26)
const WOOD := Color(0.5, 0.38, 0.25)
const BRASS := Color(0.72, 0.58, 0.28)
const JUTE := Color(0.66, 0.56, 0.38)

var _simulation: Simulation
var _scales := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	_scales.name = "Scales"
	_scales.multimesh = MultiMesh.new()
	_scales.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_scales.multimesh.mesh = scale_mesh()
	_scales.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_scales.material_override = material
	add_child(_scales)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func scale_count() -> int:
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
	_scales.multimesh.instance_count = places.size()
	for i: int in places.size():
		_scales.multimesh.set_instance_transform(i, places[i])


## As balanças da ilha: id do armazém → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`).
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "scale/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células das balanças da ilha (o recheio e as bombas as deixam limpas) → o id do armazém.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## A balança com o meio entre as duas células na origem (o pé no chão), a parede do armazém em −z (a uma meia célula): a balança na
## metade de −x, com a coluna do lado da parede, e os sacos e os pesos soltos na de +x.
static func scale_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at := Vector3(SCALE_X, 0.0, -0.15)
	# o chassi de ferro com as quatro rodinhas e o estrado de tábuas
	VertexShapes.box(tool, at + Vector3(0.0, DECK_M * 0.5, 0.0), Vector3(DECK_HALF.x, DECK_M * 0.5 - 0.03, DECK_HALF.y), PAINT)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var wheel := at + Vector3(sx * (DECK_HALF.x - 0.08), 0.05, sz * (DECK_HALF.y + 0.02))
			VertexShapes.cylinder(tool, wheel - Vector3(0.0, 0.0, 0.02), wheel + Vector3(0.0, 0.0, 0.02), 0.05, IRON, 6)
	for k: int in 5:
		var x := -DECK_HALF.x + 0.09 + k * (DECK_HALF.x * 2.0 - 0.18) / 4.0
		VertexShapes.box(tool, at + Vector3(x, DECK_M + 0.01, 0.0), Vector3(0.085, 0.015, DECK_HALF.y - 0.02), WOOD)
	# a coluna do lado da parede, o travessão em cima, o prato pendurado com os pesos e o fiel
	var column := at + Vector3(0.0, 0.0, -DECK_HALF.y + 0.06)
	VertexShapes.box(tool, column + Vector3(0.0, COLUMN_M * 0.5, 0.0), Vector3(0.05, COLUMN_M * 0.5, 0.05), PAINT)
	VertexShapes.box(tool, column + Vector3(0.18, COLUMN_M, 0.0), Vector3(0.32, 0.025, 0.025), IRON)
	var hook := column + Vector3(0.46, COLUMN_M - 0.02, 0.0)
	VertexShapes.strut(tool, hook, hook - Vector3(0.0, 0.3, 0.0), 0.008, 0.008, IRON)
	VertexShapes.cylinder(tool, hook - Vector3(0.0, 0.32, 0.0), hook - Vector3(0.0, 0.3, 0.0), 0.1, BRASS, 8)
	for k: int in 3:
		var radius := 0.06 - 0.012 * k
		VertexShapes.cylinder(tool, hook - Vector3(0.0, 0.3 - 0.04 * k, 0.0), hook - Vector3(0.0, 0.26 - 0.04 * k, 0.0), radius,
				IRON, 8)
	VertexShapes.box(tool, column + Vector3(-0.05, COLUMN_M + 0.08, 0.0), Vector3(0.01, 0.07, 0.01), BRASS)
	# um saco deitado em cima do estrado
	_sack(tool, Transform3D(Basis(Vector3.UP, 0.15) * Basis(Vector3.BACK, PI * 0.5), at + Vector3(0.3, DECK_M + 0.21, 0.05)),
			JUTE)
	# os sacos de pé esperando e os pesos soltos no chão
	for k: int in 3:
		_sack(tool, Transform3D(Basis(Vector3.UP, 0.4 * k), Vector3(0.55 + 0.4 * k, 0.0, -0.45 + 0.12 * (k % 2))),
				JUTE.darkened(0.06 * k))
	for k: int in 3:
		var weight := Vector3(0.7 + 0.2 * k, 0.0, 0.45)
		VertexShapes.cylinder(tool, weight, weight + Vector3(0.0, 0.08 - 0.015 * k, 0.0), 0.07 - 0.01 * k, IRON, 8)
	tool.generate_normals()
	return tool.commit()


## Um saco de pé com o fundo em place: o corpo estufado, mais largo embaixo, e a boca amarrada com o nó em cima.
static func _sack(tool: SurfaceTool, place: Transform3D, color: Color) -> void:
	PerchedGullView._blob(tool, place * Transform3D(Basis.from_scale(Vector3(0.19, 0.27, 0.16)), Vector3(0.0, 0.26, 0.0)), color)
	VertexShapes.cylinder(tool, place * Vector3(0.0, 0.48, 0.0), place * Vector3(0.0, 0.6, 0.0), 0.05, color.darkened(0.1), 6)
	VertexShapes.cylinder(tool, place * Vector3(0.0, 0.52, 0.0), place * Vector3(0.0, 0.55, 0.0), 0.065, color.darkened(0.35), 6)
