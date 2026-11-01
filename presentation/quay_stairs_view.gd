class_name QuayStairsView
extends Node3D
## Fase 194: a escada do cais. Em cada entreposto com cais de pedra (Fase 106), de cada lado, no lanço que fica STAIR_CLEAR_M
## além da largura do prédio (depois da cisterna da Fase 127) e que tem o lanço seguinte (a escada corre ao longo dele), um
## lance de degraus de pedra encostado no paredão, do lado do mar, descendo do alto do cais até dentro da água, afastando-se do
## prédio (`flights`, `step_places`), e a argola de ferro presa no paredão logo depois do último degrau (`ring_mesh`). Os degraus
## são caixas na pedra das paredes do cais; dois MultiMesh; nada no save; refeito na obra, na demolição, na estrada e ao trocar
## de mundo.

const STAIR_CLEAR_M := 4.5
const STEP_RISE_M := 0.22
const STEP_RUN_M := 0.32
const WIDTH_M := 0.95
const BELOW_WATER_M := 0.4
const IRON := Color(0.14, 0.14, 0.15)

var _simulation: Simulation
var _steps := MultiMeshInstance3D.new()
var _rings := MultiMeshInstance3D.new()
## O alto de cada lance (o x desce ao longo do paredão, o z sai para o mar) e os degraus (testes: sem tela o MultiMesh devolve
## transformações zeradas).
var places: Array[Transform3D] = []
var steps: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_steps.name = "QuayStairs"
	_steps.multimesh = MultiMesh.new()
	_steps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_steps.multimesh.mesh = BoxMesh.new()
	_steps.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_steps.material_override = BuildingMaterials.walls()
	BuildingMaterials.dress(_steps, BuildingMaterials.Wall.STONE, HarborView.STONE_COLOR, 0.0)
	add_child(_steps)
	var iron := StandardMaterial3D.new()
	iron.vertex_color_use_as_albedo = true
	iron.vertex_color_is_srgb = true
	iron.metallic = 0.6
	iron.roughness = 0.5
	_rings.name = "QuayRings"
	_rings.multimesh = MultiMesh.new()
	_rings.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_rings.multimesh.mesh = ring_mesh()
	_rings.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_rings.material_override = iron
	add_child(_rings)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func flight_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	steps.clear()
	var rings: Array[Transform3D] = []
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if not _simulation.def_of(record).is_trading_post:
			continue
		for frame: Transform3D in flights(_simulation, record):
			places.append(frame)
			var flight := step_places(frame)
			steps.append_array(flight)
			# a argola no paredão logo depois do último degrau, um pouco acima da água
			rings.append(frame * Transform3D(Basis.IDENTITY, Vector3(flight.size() * STEP_RUN_M + 0.35,
					-frame.origin.y + 0.55, 0.02)))
	for pair: Array in [[_steps, steps], [_rings, rings]]:
		var layer: MultiMeshInstance3D = pair[0]
		var list: Array[Transform3D] = pair[1]
		layer.multimesh.instance_count = list.size()
		for i: int in list.size():
			layer.multimesh.set_instance_transform(i, list[i])


## O alto de cada lance do entreposto (mundo): na beira do cais, no lanço que passa STAIR_CLEAR_M da largura do prédio, com o x
## para longe do prédio ao longo do paredão e o z para o mar. Sem cais de pedra daquele lado (ou curto demais), nada.
static func flights(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var segments := HarborView.stone_quay(simulation, record)
	if segments.is_empty():
		return result
	var plan := HarborView.walkway(simulation, record)
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	for side: float in [-1.0, 1.0]:
		var along := across * side
		for k: int in segments.size():
			var front: Vector3 = segments[k][0]
			var t := (front - start).dot(across) * side
			if t < width * 0.5 + STAIR_CLEAR_M:
				continue
			# o lanço seguinte do mesmo lado (a escada corre ao longo dele)
			var next_found := false
			for other: Array in segments:
				var next_front: Vector3 = other[0]
				if absf((next_front - start).dot(across) * side - (t + HarborView.STONE_QUAY_STEP_M)) < 0.01:
					next_found = true
			if not next_found:
				break
			var outward: Vector3 = segments[k][1]
			result.append(Transform3D(Basis(along, Vector3.UP, outward), front))
			break
	return result


## Os degraus do lance de alto frame (mundo): caixas de STEP_RUN_M de piso descendo STEP_RISE_M cada uma até abaixo da água,
## da face do paredão até WIDTH_M para o mar.
static func step_places(frame: Transform3D) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var top := frame.origin.y
	var count := ceili((top + BELOW_WATER_M * 0.5) / STEP_RISE_M)
	for i: int in count:
		var high := -(i + 1) * STEP_RISE_M
		var low := -top - BELOW_WATER_M
		if high <= low:
			break
		var size := Vector3(STEP_RUN_M, high - low, WIDTH_M)
		var center := Vector3((i + 0.5) * STEP_RUN_M, (high + low) * 0.5, WIDTH_M * 0.5)
		result.append(frame * Transform3D(Basis.from_scale(size), center))
	return result


## A argola de ferro no plano xy (presa na parede em z = 0): o anel de doze gomos pendurado na chapinha.
static func ring_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.06, 0.01), Vector3(0.05, 0.05, 0.01), IRON)
	var radius := 0.11
	for k: int in 12:
		var a0 := TAU * k / 12.0 - PI * 0.5
		var a1 := TAU * (k + 1) / 12.0 - PI * 0.5
		var p0 := Vector3(cos(a0) * radius, sin(a0) * radius - radius * 0.2, 0.04)
		var p1 := Vector3(cos(a1) * radius, sin(a1) * radius - radius * 0.2, 0.04)
		VertexShapes.strut(tool, p0, p1, 0.014, 0.014, IRON)
	tool.generate_normals()
	return tool.commit()
