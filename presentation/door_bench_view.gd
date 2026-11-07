class_name DoorBenchView
extends Node3D
## Fase 174: o banco na porta. Numa casa de camponeses a cada BENCH_EVERY pelo id, dentro do quintal cercado da frente
## (`TierDef.HouseTrim.YARD`, Fase 13), o banco de tábua encostado na parede da frente, ao lado da porta e além dos vasos da
## Fase 15 (`spot`): o assento de uma tábua grossa sobre dois pés em cavalete (`bench_mesh`). No lugar do modelo da casa (com o
## desvio da variação, `BuildingView.model_place`); um MultiMesh; nada no save; refeito na obra, na demolição, na subida de classe
## e ao trocar de mundo.

const BENCH_EVERY := 3
const BENCH_REST := 2
## O meio do banco fica tanto ao lado da porta (passa dos vasos, a POT_SIDE_M) e tanto para fora da parede.
const SIDE_M := 1.6
const OUT_M := 0.28
const LENGTH_M := 1.1
const SEAT_M := 0.42
const WOOD := Color(0.5, 0.37, 0.24)
const WOOD_DARK := Color(0.38, 0.28, 0.18)

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
	material.roughness = 0.85
	_benches.name = "DoorBenches"
	_benches.multimesh = MultiMesh.new()
	_benches.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_benches.multimesh.mesh = bench_mesh()
	_benches.material_override = material
	add_child(_benches)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
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
	for id: int in _simulation.world.building_ids():
		var found: Variant = spot(_simulation, _simulation.world.building(id))
		if found is Transform3D:
			places.append(found)
	_benches.multimesh.instance_count = places.size()
	for i: int in places.size():
		_benches.multimesh.set_instance_transform(i, places[i])
	_benches.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## Onde fica o banco da casa (mundo: o pé no chão, o x ao longo da parede, o +Z para longe dela) ou null: só nas casas de
## camponeses do resto certo, com o quintal cercado na frente.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or posmod(record.id, BENCH_EVERY) != BENCH_REST:
		return null
	var tier := simulation.data.tier(record.tier)
	if tier == null or tier.house_trim != TierDef.HouseTrim.YARD:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null or spec.court_rows == 0:
		return null
	var hall := spec.hall()
	var door := BuildingKit._wall_point(hall, 0, hall.door_index, 0)
	# do lado da porta que tem mais parede; a face da frente tem a normal −Z
	var side := 1.0 if hall.door_index < hall.cells.x / 2 else -1.0
	var local := spec.hall_offset() + Vector3(door.x + side * SIDE_M, 0.0, door.z - OUT_M)
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	# o banco de costas para a parede: o x dele ao longo dela e o +Z para a rua (−Z do modelo)
	var place := model * Transform3D(Basis(Vector3.LEFT, Vector3.UP, Vector3.FORWARD), local)
	place.origin.y = maxf(grid.height_at(place.origin.x, place.origin.z), model.origin.y - 0.6)
	return place


## O banco com o pé no zero, ao longo de x: o assento de tábua grossa e dois pés em cavalete com a travessa.
static func bench_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, SEAT_M, 0.0), Vector3(LENGTH_M * 0.5, 0.03, 0.15), WOOD)
	for end: float in [-1.0, 1.0]:
		var x := end * (LENGTH_M * 0.5 - 0.12)
		for lean: float in [-1.0, 1.0]:
			VertexShapes.strut(tool, Vector3(x, 0.0, lean * 0.14), Vector3(x, SEAT_M - 0.03, lean * 0.05), 0.022, 0.022,
					WOOD_DARK)
	VertexShapes.box(tool, Vector3(0.0, SEAT_M * 0.4, 0.0), Vector3(LENGTH_M * 0.5 - 0.12, 0.018, 0.018), WOOD_DARK)
	tool.generate_normals()
	return tool.commit()
