class_name CormorantView
extends Node3D
## Fase 231: os cormorões nas estacas. No alto da estaca do meio de um a cada PERCH_EVERY feixes de atracação da Fase 186 (na
## ordem deles, o primeiro sempre, `perches`), um cormorão de pé com as asas abertas secando ao sol, virado pelo lugar: o corpo
## escuro em pé, o pescoço em S com a cabeça e o bico de gancho, a cauda dura apoiada e as asas abertas para os lados
## (`cormorant_mesh`, desenhado SCALE vezes maior). Um MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de
## mundo; some à noite como os outros pássaros de dia.

const PERCH_EVERY := 2
const SCALE := 1.6
## O quanto o cormorão assenta no alto da estaca (o corpo da malha fica acima dos pés).
const SIT_M := 0.14
const NIGHT_HIDE := 0.5
const BODY := Color(0.08, 0.09, 0.08)
const WING := Color(0.12, 0.13, 0.11)
const THROAT := Color(0.78, 0.66, 0.3)
const BEAK := Color(0.32, 0.3, 0.26)

var _simulation: Simulation
var _birds := MultiMeshInstance3D.new()
## Os lugares (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_birds.name = "Cormorants"
	_birds.multimesh = MultiMesh.new()
	_birds.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_birds.multimesh.mesh = cormorant_mesh()
	_birds.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_birds.material_override = material
	_birds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_birds)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func cormorant_count() -> int:
	return places.size()


func is_showing() -> bool:
	return _birds.visible


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _simulation == null:
		return
	if _dirty:
		rebuild()
	_birds.visible = DayClock.night_factor(_simulation.config, GameClock.clock.hour()) < NIGHT_HIDE


func rebuild() -> void:
	_dirty = false
	places.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		places.append_array(perches(world, record, _simulation.def_of(record), _simulation.config.cell_size_m))
	_birds.multimesh.instance_count = places.size()
	for i: int in places.size():
		_birds.multimesh.set_instance_transform(i, places[i])


## Os cormorões de um entreposto ou píer: no alto da estaca do meio de um a cada PERCH_EVERY feixes, virados pelo lugar.
static func perches(world: WorldState, record: BuildingRecord, def: BuildingDef, cell_size: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var clusters := MooringPileView.spots(world, record, def, cell_size)
	for k: int in clusters.size():
		# um feixe sim, um não, na ordem dos feixes (o primeiro sempre)
		if k % PERCH_EVERY != 0:
			continue
		var cluster := clusters[k]
		var key := roundi(cluster.origin.x * 3.0) * 31 + roundi(cluster.origin.z * 3.0) * 17
		var turn := float(posmod(key * 7, 360)) * PI / 180.0
		var top := cluster * Vector3(0.0, MooringPileView.TOPS_M[0], 0.0) - Vector3(0.0, SIT_M, 0.0)
		result.append(Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * SCALE), top))
	return result


## O cormorão de pé, de frente para −Z, com os pés em y = 0 (cerca de 0,8 m de altura): o corpo inclinado, a cauda dura para trás
## e para baixo, o pescoço em S até a cabeça com a garganta clara e o bico de gancho, e as duas asas abertas para os lados,
## largas, com as penas da ponta.
static func cormorant_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis(Vector3.RIGHT, 0.35).scaled(Vector3(0.11, 0.2, 0.12)), Vector3(0.0, 0.3,
			0.03)), BODY)
	# a cauda dura, apoiada para trás
	VertexShapes.quad(tool, Vector3(-0.06, 0.16, 0.12), Vector3(0.06, 0.16, 0.12), Vector3(0.07, 0.02, 0.3),
			Vector3(-0.07, 0.02, 0.3), BODY)
	# o pescoço em S e a cabeça
	var neck: Array[Vector3] = [Vector3(0.0, 0.42, -0.04), Vector3(0.0, 0.54, -0.02), Vector3(0.0, 0.64, -0.07),
			Vector3(0.0, 0.7, -0.12)]
	for k: int in neck.size() - 1:
		VertexShapes.strut(tool, neck[k], neck[k + 1], 0.035, 0.035, BODY)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.045, 0.045, 0.06)), Vector3(0.0, 0.72, -0.13)), BODY)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.03, 0.025, 0.03)), Vector3(0.0, 0.69, -0.16)), THROAT)
	VertexShapes.strut(tool, Vector3(0.0, 0.72, -0.17), Vector3(0.0, 0.705, -0.27), 0.01, 0.008, BEAK)
	VertexShapes.strut(tool, Vector3(0.0, 0.705, -0.27), Vector3(0.0, 0.69, -0.28), 0.008, 0.006, BEAK)
	# as asas abertas: do ombro para o lado e um pouco para cima, largas, com a borda de trás em dentes
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * 0.08, 0.44, 0.0)
		var wrist := Vector3(side * 0.34, 0.52, 0.04)
		var tip := Vector3(side * 0.5, 0.42, 0.1)
		var trail: Array[Vector3] = [Vector3(side * 0.12, 0.24, 0.1), Vector3(side * 0.24, 0.26, 0.12),
				Vector3(side * 0.36, 0.27, 0.14), Vector3(side * 0.46, 0.32, 0.14)]
		VertexShapes.tri(tool, shoulder, wrist, trail[0], WING)
		VertexShapes.tri(tool, trail[0], wrist, trail[1], WING)
		VertexShapes.tri(tool, trail[1], wrist, trail[2], WING)
		VertexShapes.tri(tool, trail[2], wrist, tip, WING)
		VertexShapes.tri(tool, trail[2], tip, trail[3], WING)
	tool.generate_normals()
	return tool.commit()
