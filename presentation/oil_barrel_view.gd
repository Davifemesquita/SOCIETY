class_name OilBarrelView
extends Node3D
## Fase 228: os barris de petróleo. Em cada poço de petróleo (Fase 70), nas duas células do meio de um lado — o de −X do modelo,
## depois o de +X e por fim o de trás (a frente é o pátio do cavalo-de-pau da Fase 73) —, pelo `SideYard` (`sites`): os barris de
## madeira enegrecidos pelo óleo (o barril da Fase 221, mais escuro), cinco em pé em duas filas e dois deitados sobre os calços, e
## a mancha de óleo no chão (`barrels_mesh`, no meio das duas células). O recheio e as bombas deixam as células limpas (`cells`).
## Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"oil_well"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.PLUS_X, SideYard.BACK]
## O tom dos barris (a madeira do barril da Fase 221 escurecida) e a mancha de óleo.
const TONE := 0.5
const STAIN_RADIUS_M := Vector2(1.1, 0.7)
const STAIN := Color(0.05, 0.05, 0.05)
const CHOCK := Color(0.3, 0.23, 0.16)

var _simulation: Simulation
var _barrels := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.55
	_barrels.name = "OilBarrels"
	_barrels.multimesh = MultiMesh.new()
	_barrels.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_barrels.multimesh.mesh = barrels_mesh()
	_barrels.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_barrels.material_override = material
	add_child(_barrels)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func barrel_count() -> int:
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
	_barrels.multimesh.instance_count = places.size()
	for i: int in places.size():
		_barrels.multimesh.set_instance_transform(i, places[i])


## Os barris da ilha: id do poço → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`).
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "oil/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos barris da ilha (o recheio e as bombas as deixam limpas) → o id do poço.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## Os barris e a mancha com o meio entre as duas células na origem (o pé no chão), a parede do poço em −z (a uma meia célula).
static func barrels_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# a mancha de óleo no chão, de borda recortada, debaixo de tudo
	var sides := 16
	for s: int in sides:
		var a0 := TAU * s / sides
		var a1 := TAU * (s + 1) / sides
		var r0 := 1.0 + 0.15 * sin(a0 * 3.0 + 1.1)
		var r1 := 1.0 + 0.15 * sin(a1 * 3.0 + 1.1)
		var center := Vector3(-0.2, 0.012, -0.1)
		VertexShapes.tri(tool, center, center + Vector3(cos(a0) * STAIN_RADIUS_M.x * r0, 0.0, sin(a0) * STAIN_RADIUS_M.y * r0),
				center + Vector3(cos(a1) * STAIN_RADIUS_M.x * r1, 0.0, sin(a1) * STAIN_RADIUS_M.y * r1), STAIN)
	var pitch := (BarrelRackView.BARREL_R + BarrelRackView.BULGE) * 2.0 + 0.04
	# cinco em pé, três junto da parede e dois na frente nos vãos
	for k: int in 3:
		BarrelRackView._barrel(tool, Transform3D(Basis.IDENTITY, Vector3(-1.4 + k * pitch, 0.0, -0.6)), TONE * (0.9 + 0.1 * k))
	for k: int in 2:
		BarrelRackView._barrel(tool, Transform3D(Basis(Vector3.UP, 0.4), Vector3(-1.4 + pitch * 0.5 + k * pitch, 0.0, -0.6 + pitch
				* 0.87)), TONE * (1.0 - 0.08 * k))
	# dois deitados sobre os calços, o fundo para fora
	var lying := Basis(Vector3.RIGHT, PI * 0.5)
	for dz: float in [-0.25, 0.25]:
		VertexShapes.box(tool, Vector3(1.05, 0.05, -0.55 + dz), Vector3(0.75, 0.05, 0.05), CHOCK)
	for k: int in 2:
		var y := 0.1 + BarrelRackView.BARREL_R + BarrelRackView.BULGE * 0.6
		BarrelRackView._barrel(tool, Transform3D(lying, Vector3(0.7 + k * pitch, y, -0.55 - BarrelRackView.BARREL_L * 0.5)),
				TONE * (0.95 - 0.05 * k))
	tool.generate_normals()
	return tool.commit()
