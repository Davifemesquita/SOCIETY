class_name PotatoBasketView
extends Node3D
## Fase 253: os cestos de batata. Em cada fazenda de batata, nas duas células do meio de um lado — o de +X do modelo, depois o de
## trás e por fim o de −X (as colmeias da Fase 190 preferem o −X, e o silo da Fase 117 fica atrás) —, pelo `SideYard` e fora das
## colmeias e do silo (`sites`): os cestos de vime cheios de batata recém-colhida, um tombado com as batatas rolando para o chão,
## dois sacos cheios e o forcado de três dentes encostado (`basket_mesh`, no meio das duas células). O recheio e as bombas deixam as
## células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"potato_farm"]
const ORDER: Array[Vector2i] = [SideYard.PLUS_X, SideYard.BACK, SideYard.MINUS_X]
## O cesto: o raio da boca, o do fundo e a altura.
const BASKET_TOP := 0.26
const BASKET_BOTTOM := 0.19
const BASKET_M := 0.34
const WICKER := Color(0.72, 0.6, 0.38)
const WICKER_DARK := Color(0.56, 0.45, 0.28)
const POTATO := Color(0.74, 0.6, 0.38)
const POTATO_DARK := Color(0.55, 0.42, 0.26)
const JUTE := Color(0.64, 0.54, 0.36)
const WOOD := Color(0.44, 0.33, 0.22)
const IRON := Color(0.3, 0.3, 0.32)

var _simulation: Simulation
var _baskets := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_baskets.name = "PotatoBaskets"
	_baskets.multimesh = MultiMesh.new()
	_baskets.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_baskets.multimesh.mesh = basket_mesh()
	_baskets.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_baskets.material_override = material
	add_child(_baskets)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func basket_count() -> int:
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
	_baskets.multimesh.instance_count = places.size()
	for i: int in places.size():
		_baskets.multimesh.set_instance_transform(i, places[i])


## Os pátios da ilha: id da fazenda → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora das colmeias
## e do silo.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "potato_baskets/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in BeehiveView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in FarmSiloView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos pátios da ilha (o recheio e as bombas as deixam limpas) → o id da fazenda.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## Os cestos com o meio entre as duas células na origem (o pé no chão), a parede da fazenda em −z (a uma meia célula): três cestos
## cheios encostados na parede, um quarto tombado na frente com as batatas rolando, os dois sacos e o forcado encostado.
static func basket_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in 3:
		_basket(tool, Transform3D(Basis.IDENTITY, Vector3(-1.3 + k * 0.6, 0.0, -0.6 + 0.06 * (k % 2))), true)
	# o cesto tombado de lado, a boca para +z, e as batatas rolando dele
	var lying := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.45, BASKET_TOP, -0.15))
	_basket(tool, lying, false)
	for k: int in 6:
		var at := Vector3(0.38 + 0.11 * float(posmod(k * 5, 7) - 3), 0.04, 0.25 + 0.09 * k)
		_potato(tool, at, k)
	# os dois sacos cheios e o forcado encostado na parede
	for k: int in 2:
		PerchedGullView._blob(tool, Transform3D(Basis(Vector3.UP, 0.5 * k).scaled(Vector3(0.22, 0.27, 0.19)), Vector3(1.2 + 0.4 * k,
				0.26, -0.55)), JUTE.darkened(0.05 * k))
	var foot := Vector3(1.75, 0.0, -0.3)
	var top := Vector3(1.85, 1.4, -0.9)
	VertexShapes.strut(tool, foot + (top - foot) * 0.2, top, 0.018, 0.018, WOOD)
	var head := foot + (top - foot) * 0.2
	VertexShapes.box(tool, head, Vector3(0.1, 0.012, 0.012), IRON)
	for t: float in [-0.08, 0.0, 0.08]:
		VertexShapes.strut(tool, head + Vector3(t, 0.0, 0.0), foot + Vector3(t, 0.0, 0.0), 0.008, 0.008, IRON)
	tool.generate_normals()
	return tool.commit()


## Um cesto de vime com o pé no zero de place: as aduelas de vime afunilando para baixo, a borda escura e, se cheio, o monte de
## batatas por cima.
static func _basket(tool: SurfaceTool, place: Transform3D, full: bool) -> void:
	var sides := 8
	for k: int in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var b0 := Vector3(cos(a0) * BASKET_BOTTOM, 0.0, sin(a0) * BASKET_BOTTOM)
		var b1 := Vector3(cos(a1) * BASKET_BOTTOM, 0.0, sin(a1) * BASKET_BOTTOM)
		var t0 := Vector3(cos(a0) * BASKET_TOP, BASKET_M, sin(a0) * BASKET_TOP)
		var t1 := Vector3(cos(a1) * BASKET_TOP, BASKET_M, sin(a1) * BASKET_TOP)
		VertexShapes.quad(tool, place * t1, place * t0, place * b0, place * b1, WICKER if k % 2 == 0 else WICKER_DARK)
		VertexShapes.quad(tool, place * t0, place * t1, place * b1, place * b0, WICKER_DARK)
	VertexShapes.cylinder(tool, place * Vector3(0.0, BASKET_M - 0.02, 0.0), place * Vector3(0.0, BASKET_M + 0.02, 0.0),
			BASKET_TOP + 0.015, WICKER_DARK, sides)
	VertexShapes.cylinder(tool, place * Vector3.ZERO, place * Vector3(0.0, 0.02, 0.0), BASKET_BOTTOM, WICKER_DARK, sides)
	if full:
		# o monte baixo e as batatas soltas por cima dele, numa roda e uma no meio
		PerchedGullView._blob(tool, place * Transform3D(Basis.from_scale(Vector3(BASKET_TOP * 0.92, 0.05, BASKET_TOP * 0.92)),
				Vector3(0.0, BASKET_M, 0.0)), POTATO_DARK)
		for k: int in 6:
			var angle := TAU * k / 6.0 + 0.3
			_potato(tool, place * Vector3(0.15 * cos(angle), BASKET_M + 0.04, 0.15 * sin(angle)), k)
		_potato(tool, place * Vector3(0.0, BASKET_M + 0.08, 0.0), 7)


## Uma batata no ponto at: um bolo pequeno achatado, de tamanho e tom pelo número dela.
static func _potato(tool: SurfaceTool, at: Vector3, k: int) -> void:
	var size := Vector3(0.055, 0.04, 0.045) * (0.85 + 0.1 * (k % 3))
	PerchedGullView._blob(tool, Transform3D(Basis(Vector3.UP, 0.7 * k).scaled(size), at), POTATO if k % 2 == 0 else POTATO_DARK)
