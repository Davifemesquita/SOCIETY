class_name QuayRailView
extends Node3D
## Fase 146: a grade e os lampiões do cais de pedra (Fase 106). Ao longo da beira de cada lanço do cais de pedra dos
## entrepostos, RAIL_IN_M para dentro, uma grade de ferro de dois corrimãos com um balaústre a cada POST_STEP_M (`rails`),
## aberta nos lanços dos cabeços (é por ali que se amarra); e, num lanço a cada LAMP_EVERY (nunca nos dos cabeços), um
## lampião a gás, o poste de ferro fundido dos postes da rua (`LampView.post_mesh`) com o vidro aceso à noite
## (`LampView.glass_mesh`) (`lamps`). A grade é uma malha só para o arquipélago; os lampiões, dois MultiMesh. Só
## apresentação; nada no save; refeito na obra, na demolição e ao trocar de mundo.

const RAIL_IN_M := 0.3
const RAIL_M := 1.0
const POST_STEP_M := 0.5
const LAMP_EVERY := 6
## O lampião fica neste lanço do ciclo (nunca o dos cabeços, que é o resto 1 de SEA_WALL_BOLLARD_EVERY) e tanto para dentro.
const LAMP_REST := 2
const LAMP_IN_M := 0.7
const IRON := Color(0.13, 0.15, 0.14)

var _simulation: Simulation
var _rails := MeshInstance3D.new()
var _posts := MultiMeshInstance3D.new()
var _glass := MultiMeshInstance3D.new()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var iron := StandardMaterial3D.new()
	iron.vertex_color_use_as_albedo = true
	iron.vertex_color_is_srgb = true
	iron.roughness = 0.5
	iron.metallic = 0.4
	_rails.name = "QuayRails"
	_rails.material_override = iron
	add_child(_rails)
	for part: Array in [[_posts, "QuayLamps", LampView.post_mesh()], [_glass, "QuayGlass", LampView.glass_mesh()]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = layer == _glass
		layer.multimesh.mesh = part[2]
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func lamp_count() -> int:
	return _posts.multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spans := 0
	var lamp_places: Array[Vector3] = []
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if not _simulation.def_of(record).is_trading_post:
			continue
		for span: Array in rails(_simulation, record):
			var a: Vector3 = span[0]
			var b: Vector3 = span[1]
			_rail(tool, a, b)
			spans += 1
		lamp_places.append_array(lamps(_simulation, record))
	if spans == 0:
		_rails.mesh = null
	else:
		tool.generate_normals()
		_rails.mesh = tool.commit()
	for layer: MultiMeshInstance3D in [_posts, _glass]:
		layer.multimesh.instance_count = lamp_places.size()
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	for i: int in lamp_places.size():
		var place := Transform3D(Basis.IDENTITY, lamp_places[i])
		_posts.multimesh.set_instance_transform(i, place)
		_glass.multimesh.set_instance_transform(i, place)
		_glass.multimesh.set_instance_color(i, Color(LampView.LAMP_COLOR, 0.0))


## Os trechos da grade do cais de pedra do entreposto: [de, até] no alto do capeamento, RAIL_IN_M para dentro da beira; os
## lanços dos cabeços e os da frente do prédio (o cais de tábuas, onde os barcos encostam) ficam abertos.
static func rails(simulation: Simulation, record: BuildingRecord) -> Array[Array]:
	var result: Array[Array] = []
	var segments := HarborView.stone_quay(simulation, record)
	for i: int in segments.size():
		if i % HarborView.SEA_WALL_BOLLARD_EVERY == 1 or _in_front(simulation, record, segments[i]):
			continue
		var segment: Array = segments[i]
		var front: Vector3 = segment[0]
		var outward: Vector3 = segment[1]
		var length: float = segment[2]
		var along := Vector3(-outward.z, 0.0, outward.x)
		var line := front - outward * RAIL_IN_M + Vector3(0.0, HarborView.COPING_M.x, 0.0)
		result.append([line - along * length * 0.5, line + along * length * 0.5])
	return result


## Os pés dos lampiões do cais de pedra do entreposto (no alto do capeamento): num lanço a cada LAMP_EVERY, no resto
## LAMP_REST, fora da frente do prédio.
static func lamps(simulation: Simulation, record: BuildingRecord) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var segments := HarborView.stone_quay(simulation, record)
	for i: int in segments.size():
		if i % LAMP_EVERY != LAMP_REST or _in_front(simulation, record, segments[i]):
			continue
		var segment: Array = segments[i]
		var front: Vector3 = segment[0]
		var outward: Vector3 = segment[1]
		result.append(front - outward * LAMP_IN_M + Vector3(0.0, HarborView.COPING_M.x, 0.0))
	return result


## O lanço fica diante do prédio (na largura dele e mais um lanço de folga): ali é o cais de tábuas.
static func _in_front(simulation: Simulation, record: BuildingRecord, segment: Array) -> bool:
	var plan := HarborView.walkway(simulation, record)
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	var front: Vector3 = segment[0]
	return absf((front - start).dot(across)) < width * 0.5 + HarborView.STONE_QUAY_STEP_M


## Um trecho da grade de a até b (no chão): os balaústres a cada POST_STEP_M, o corrimão no alto e a travessa embaixo.
static func _rail(tool: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var count := maxi(1, roundi(a.distance_to(b) / POST_STEP_M))
	for k: int in count + 1:
		var at := a.lerp(b, float(k) / count)
		VertexShapes.strut(tool, at, at + Vector3(0.0, RAIL_M, 0.0), 0.018, 0.018, IRON)
	VertexShapes.strut(tool, a + Vector3(0.0, RAIL_M, 0.0), b + Vector3(0.0, RAIL_M, 0.0), 0.03, 0.022, IRON)
	VertexShapes.strut(tool, a + Vector3(0.0, 0.12, 0.0), b + Vector3(0.0, 0.12, 0.0), 0.02, 0.02, IRON)
