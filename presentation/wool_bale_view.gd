class_name WoolBaleView
extends Node3D
## Fase 226: os fardos de lã. Em cada fazenda de ovelhas, nas duas células do meio de um lado — o de −X do modelo, depois o de
## trás e por fim o de +X (as medas da Fase 166 preferem o +X) —, pelo `SideYard` e fora das medas, do silo e da carroça de feno
## (`sites`): os fardos de juta amarrados com duas cordas, três embaixo e um em cima, o cepo de tosquia com a tesoura e o monte de
## velo solto ao lado (`bale_mesh`, no meio das duas células). O recheio e as bombas deixam as células limpas (`cells`). Um
## MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"sheep_farm"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.BACK, SideYard.PLUS_X]
## O fardo: as meias medidas e quantos ficam embaixo.
const BALE_HALF := Vector3(0.42, 0.36, 0.34)
const BOTTOM := 3
const JUTE := Color(0.7, 0.6, 0.42)
const ROPE := Color(0.42, 0.33, 0.22)
const FLEECE := Color(0.9, 0.87, 0.78)
const BLOCK := Color(0.45, 0.35, 0.25)
const IRON := Color(0.5, 0.5, 0.52)

var _simulation: Simulation
var _bales := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_bales.name = "WoolBales"
	_bales.multimesh = MultiMesh.new()
	_bales.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_bales.multimesh.mesh = bale_mesh()
	_bales.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_bales.material_override = material
	add_child(_bales)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func bale_count() -> int:
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
	_bales.multimesh.instance_count = places.size()
	for i: int in places.size():
		_bales.multimesh.set_instance_transform(i, places[i])


## Os fardos da ilha: id da fazenda → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora das medas,
## do silo e da carroça de feno.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "wool/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in HaystackView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in FarmSiloView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in HayWagonView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos fardos da ilha (o recheio e as bombas as deixam limpas) → o id da fazenda.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## Os fardos, o cepo e o velo com o meio entre as duas células na origem (o pé no chão), a parede da fazenda em −z (a uma meia
## célula): os fardos encostados na parede na metade de −x, o cepo e o velo na de +x.
static func bale_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_z := -1.0 + BALE_HALF.z + 0.06
	for k: int in BOTTOM:
		var at := Vector3(-1.45 + k * (BALE_HALF.x * 2.0 + 0.04), BALE_HALF.y, wall_z + 0.05 * (k % 2))
		_bale(tool, Transform3D(Basis(Vector3.UP, 0.06 * (k - 1)), at))
	_bale(tool, Transform3D(Basis(Vector3.UP, -0.1), Vector3(-1.0, BALE_HALF.y * 3.0 - 0.03, wall_z + 0.02)))
	# o cepo de tosquia, a tesoura de duas lâminas em cima e o velo solto ao lado
	var block := Vector3(0.95, 0.0, -0.1)
	VertexShapes.cylinder(tool, block, block + Vector3(0.0, 0.45, 0.0), 0.2, BLOCK, 10)
	var top := block + Vector3(0.0, 0.46, 0.0)
	for side: float in [-1.0, 1.0]:
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, 0.5 + side * 0.08), top + Vector3(0.0, 0.01, 0.0)),
				Vector3(0.16, 0.006, 0.02), IRON)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.4, 0.14, 0.32)), Vector3(1.45, 0.1, 0.35)), FLEECE)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.22, 0.1, 0.2)), Vector3(1.2, 0.2, 0.4)), FLEECE)
	tool.generate_normals()
	return tool.commit()


## Um fardo de juta com o meio em place: o corpo estufado como um saco cheio (o blob esticado, com um miolo de caixa para as
## quinas não ficarem ocas) e as duas cordas amarradas em volta.
static func _bale(tool: SurfaceTool, place: Transform3D) -> void:
	VertexShapes.oriented_box(tool, place, BALE_HALF * Vector3(0.8, 0.7, 0.8), JUTE * 0.9)
	PerchedGullView._blob(tool, place * Transform3D(Basis.from_scale(BALE_HALF * Vector3(1.12, 1.04, 1.12)), Vector3.ZERO), JUTE)
	# as cordas: duas voltas em volta do saco, no corte dele naquele x, um pouco por fora
	var shape := BALE_HALF * Vector3(1.12, 1.04, 1.12)
	for dx: float in [-shape.x * 0.45, shape.x * 0.45]:
		var cut := sqrt(1.0 - pow(dx / shape.x, 2.0)) * 1.04
		for s: int in 10:
			var a0 := TAU * s / 10.0
			var a1 := TAU * (s + 1) / 10.0
			VertexShapes.strut(tool, place * Vector3(dx, sin(a0) * shape.y * cut, cos(a0) * shape.z * cut),
					place * Vector3(dx, sin(a1) * shape.y * cut, cos(a1) * shape.z * cut), 0.018, 0.018, ROPE)
