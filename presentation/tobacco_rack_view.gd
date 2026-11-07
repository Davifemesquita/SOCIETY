class_name TobaccoRackView
extends Node3D
## Fase 242: o tabaco secando. Em cada plantação de tabaco, nas duas células do meio de um lado — o de −X do modelo, depois o de
## trás e por fim o de +X —, pelo `SideYard` (`sites`): o varal de varas — dois cavaletes de dois esteios com a travessa e a
## escora nas pontas e três varas compridas por cima — com as réstias de folhas de tabaco penduradas, a vara da frente
## ainda verde-amarela, a do meio dourada e a de trás já curada, castanha, e o cesto de folhas no chão (`rack_mesh`, no meio das
## duas células). O recheio e as bombas deixam as células limpas (`cells`). Um MultiMesh (as folhas dos dois lados); nada no save;
## refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"tobacco_plantation"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.BACK, SideYard.PLUS_X]
## O varal: a meia largura (ao longo de x), a altura das varas, o z de cada vara e quantas réstias e folhas por réstia.
const HALF_X := 1.7
const POLE_M := 1.75
const POLES_Z: Array[float] = [0.45, 0.0, -0.45]
const STRINGS := 9
const LEAVES := 3
const WOOD := Color(0.42, 0.32, 0.21)
const LEAF_COLORS: Array[Color] = [Color(0.62, 0.62, 0.22), Color(0.72, 0.52, 0.18), Color(0.45, 0.28, 0.12)]
const WICKER := Color(0.6, 0.48, 0.3)

var _simulation: Simulation
var _racks := MultiMeshInstance3D.new()
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
	_racks.name = "TobaccoRacks"
	_racks.multimesh = MultiMesh.new()
	_racks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_racks.multimesh.mesh = rack_mesh()
	_racks.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_racks.material_override = material
	add_child(_racks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rack_count() -> int:
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
	_racks.multimesh.instance_count = places.size()
	for i: int in places.size():
		_racks.multimesh.set_instance_transform(i, places[i])


## Os varais da ilha: id da plantação → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`).
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "tobacco_rack/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos varais da ilha (o recheio e as bombas as deixam limpas) → o id da plantação.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## O varal com o meio entre as duas células na origem (o pé no chão), a parede da plantação em −z (a uma meia célula): os
## cavaletes nas pontas, as três varas ao longo de x e as réstias penduradas, cada folha uma lâmina fina girada um pouco, e
## o cesto de folhas no chão.
static func rack_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var x := side * HALF_X
		for end: float in [-1.0, 1.0]:
			VertexShapes.strut(tool, Vector3(x, -0.04, end * 0.6), Vector3(x, POLE_M + 0.1, end * 0.6), 0.035, 0.035, WOOD)
		VertexShapes.strut(tool, Vector3(x, POLE_M - 0.05, -0.7), Vector3(x, POLE_M - 0.05, 0.7), 0.03, 0.03, WOOD)
		VertexShapes.strut(tool, Vector3(x, 0.3, -0.6), Vector3(x, POLE_M - 0.1, 0.6), 0.02, 0.02, WOOD)
	for p: int in POLES_Z.size():
		var z: float = POLES_Z[p]
		VertexShapes.strut(tool, Vector3(-HALF_X - 0.15, POLE_M, z), Vector3(HALF_X + 0.15, POLE_M, z), 0.03, 0.03, WOOD)
		for s: int in STRINGS:
			var x := -HALF_X + 0.2 + (HALF_X * 2.0 - 0.4) * s / (STRINGS - 1)
			for leaf: int in LEAVES:
				var y := POLE_M - 0.15 - leaf * 0.22
				var turn := 0.5 * float(posmod(s * 7 + leaf * 3 + p, 5) - 2)
				var color: Color = LEAF_COLORS[p].lerp(LEAF_COLORS[mini(p + 1, 2)], 0.15 * leaf)
				VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, turn) * Basis(Vector3.BACK, 0.12 * (leaf - 1)),
						Vector3(x, y, z)), Vector3(0.07, 0.13, 0.006), color)
	# o cesto de folhas no chão, num canto da frente
	var basket := Vector3(HALF_X - 0.25, 0.0, 0.7)
	VertexShapes.cylinder(tool, basket, basket + Vector3(0.0, 0.3, 0.0), 0.2, WICKER, 8)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.19, 0.09, 0.19)), basket + Vector3(0.0, 0.31, 0.0)),
			LEAF_COLORS[0])
	tool.generate_normals()
	return tool.commit()
