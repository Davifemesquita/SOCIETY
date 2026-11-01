class_name QuayBenchView
extends Node3D
## Fase 198: os bancos no cais. Nos lanços do cais de pedra dos entrepostos (Fase 106) do resto BENCH_REST de BENCH_EVERY
## (entre os cabeços, que ficam no resto 1 de HarborView.SEA_WALL_BOLLARD_EVERY), fora da frente do entreposto, um banco de
## praça (`DecorationView._bench`: pés de ferro, assento e encosto de tábuas) BENCH_IN_M para dentro da beira, de costas para a
## cidade e virado para o mar (`benches`). Fica de fora o banco que cairia a menos de CLEAR_M de um lampião (Fase 146), de uma
## cisterna (Fase 127), de um mastro (Fase 147) ou do alto de uma escada (Fase 194), e o que a terra de trás cobriria. Um
## MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de mundo.

const BENCH_EVERY := 3
const BENCH_REST := 0
const BENCH_IN_M := 1.55
const CLEAR_M := 1.8
const BURIED_M := 0.08

var _simulation: Simulation
var _benches := MultiMeshInstance3D.new()
## Os lugares dos bancos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	_benches.name = "QuayBenches"
	_benches.multimesh = MultiMesh.new()
	_benches.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_benches.multimesh.mesh = bench_mesh()
	_benches.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_benches.material_override = material
	add_child(_benches)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func bench_count() -> int:
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
	for id: int in world.building_ids():
		var record := world.building(id)
		if _simulation.def_of(record).is_trading_post:
			places.append_array(benches(_simulation, record))
	_benches.multimesh.instance_count = places.size()
	for i: int in places.size():
		_benches.multimesh.set_instance_transform(i, places[i])


## Os bancos do cais do entreposto: o pé no alto da plataforma, a frente (−z) para o mar.
static func benches(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var segments := HarborView.stone_quay(simulation, record)
	if segments.is_empty():
		return result
	var others: Array[Vector3] = QuayRailView.lamps(simulation, record)
	for place: Transform3D in HarborView.cistern_places(simulation, record):
		others.append(place.origin)
	others.append_array(QuayMastView.masts(simulation, record))
	for frame: Transform3D in QuayStairsView.flights(simulation, record):
		others.append(frame.origin)
	for i: int in segments.size():
		if i % BENCH_EVERY != BENCH_REST or QuayRailView._in_front(simulation, record, segments[i]):
			continue
		var segment: Array = segments[i]
		var front: Vector3 = segment[0]
		var outward: Vector3 = segment[1]
		var along := Vector3(-outward.z, 0.0, outward.x)
		var point := front - outward * BENCH_IN_M
		if simulation.world.surface_height(point.x, point.z) > front.y + BURIED_M:
			continue
		var near := false
		for other: Vector3 in others:
			if Vector2(other.x - point.x, other.z - point.z).length() < CLEAR_M:
				near = true
				break
		if near:
			continue
		result.append(Transform3D(Basis(along, Vector3.UP, -outward), point))
	return result


## O banco com o pé no zero, o assento virado para −z e o encosto em +z.
static func bench_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	DecorationView._bench(tool, Vector3.ZERO, false)
	tool.generate_normals()
	return tool.commit()
