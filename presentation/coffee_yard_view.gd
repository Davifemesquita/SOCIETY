class_name CoffeeYardView
extends Node3D
## Fase 241: o terreiro de café. Em cada cafezal, nas duas células do meio de um lado — o de −X do modelo, depois o de trás e por
## fim o de +X —, pelo `SideYard` (`sites`): o terreiro de chão batido caiado com a mureta baixa em volta, o café espalhado secando
## ao sol numa camada fina com os sulcos do rodo (os grãos vermelhos de um lado, os já secos, castanhos, do outro), o rodo deitado
## junto do montinho que ele junta e dois sacos cheios no canto (`yard_mesh`, no meio das duas células). O recheio e as bombas
## deixam as células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao
## trocar de mundo.

const KINDS: Array[StringName] = [&"coffee_plantation"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.BACK, SideYard.PLUS_X]
## O terreiro: as meias medidas do chão, a altura da mureta e quantos sulcos do rodo em cada metade.
const YARD_HALF := Vector2(1.85, 0.9)
const CURB_M := 0.12
const ROWS := 6
const FLOOR := Color(0.78, 0.74, 0.66)
const CURB := Color(0.7, 0.66, 0.58)
const CHERRY := Color(0.55, 0.13, 0.08)
const DRIED := Color(0.36, 0.22, 0.13)
const WOOD := Color(0.48, 0.36, 0.24)
const JUTE := Color(0.66, 0.56, 0.38)

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
	material.roughness = 0.95
	_yards.name = "CoffeeYards"
	_yards.multimesh = MultiMesh.new()
	_yards.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_yards.multimesh.mesh = yard_mesh()
	_yards.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_yards.material_override = material
	add_child(_yards)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func yard_count() -> int:
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


## Os terreiros da ilha: id do cafezal → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`).
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "coffee_yard/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos terreiros da ilha (o recheio e as bombas as deixam limpas) → o id do cafezal.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## O terreiro com o meio entre as duas células na origem (o pé no chão), a parede do cafezal em −z (a uma meia célula): o chão
## batido com a mureta, a camada de café com os sulcos ao longo de x (a metade de −x vermelha, a de +x seca), o montinho, o rodo e
## os sacos no canto.
static func yard_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.025, 0.0), Vector3(YARD_HALF.x, 0.025, YARD_HALF.y), FLOOR)
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(side * (YARD_HALF.x - 0.05), CURB_M * 0.5, 0.0), Vector3(0.05, CURB_M * 0.5,
				YARD_HALF.y), CURB)
		VertexShapes.box(tool, Vector3(0.0, CURB_M * 0.5, side * (YARD_HALF.y - 0.05)), Vector3(YARD_HALF.x - 0.1,
				CURB_M * 0.5, 0.05), CURB)
	# o café espalhado: a camada fina cobrindo o chão (a metade de −x ainda vermelha) e os sulcos do rodo por cima, mais escuros
	var inner := YARD_HALF - Vector2(0.15, 0.15)
	for half: float in [-1.0, 1.0]:
		var color := CHERRY if half < 0.0 else DRIED
		var middle := half * inner.x * 0.5
		VertexShapes.box(tool, Vector3(middle, 0.06, 0.0), Vector3(inner.x * 0.5 - 0.02, 0.012, inner.y), color)
		for k: int in ROWS:
			var z := -inner.y + inner.y * 2.0 * (k + 0.5) / ROWS
			var wobble := 0.04 * float(posmod(k * 3 + int(half), 5) - 2)
			VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, wobble), Vector3(middle, 0.078, z)),
					Vector3(inner.x * 0.5 - 0.08, 0.01, 0.035), color.darkened(0.28))
	# o montinho de café seco que o rodo está juntando
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.34, 0.12, 0.28)), Vector3(0.55, 0.07, 0.42)), DRIED)
	# o rodo: o cabo deitado na mureta e a tábua no chão de café
	var blade := Vector3(-0.1, 0.09, 0.62)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, 0.25), blade), Vector3(0.05, 0.04, 0.32), WOOD)
	VertexShapes.strut(tool, blade + Vector3(0.05, 0.03, 0.0), blade + Vector3(1.3, 0.1, 0.12), 0.02, 0.02, WOOD)
	# os dois sacos cheios no canto de +x, encostados na mureta
	for k: int in 2:
		var at := Vector3(YARD_HALF.x - 0.3 - k * 0.42, 0.27, -YARD_HALF.y + 0.35)
		PerchedGullView._blob(tool, Transform3D(Basis(Vector3.UP, 0.3 * k).scaled(Vector3(0.2, 0.26, 0.17)), at), JUTE)
	tool.generate_normals()
	return tool.commit()
