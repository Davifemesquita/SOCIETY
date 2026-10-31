class_name ClockView
extends Node3D
## Fase 145: o relógio da igreja. Na torre do campanário (Fase 18) de cada prédio de `Silhouette.BELFRY`, um mostrador em
## cada uma das duas faces de fora (a da frente e a do lado), no fuste, entre o beiral e a sineira (`dials`): o disco
## claro, aceso à noite pelo `shaders/night_glow.gdshader` (o vidro dos postes, com o creme de dia), a moldura de pedra, o
## aro e as doze marcas de ferro (`face_mesh`, `frame_mesh`), e os dois ponteiros marcando a hora do jogo
## (`hand_angles`, pelo `GameClock`: param na pausa), refeitos a cada quadro. Só apresentação; nada no save; refeito na
## obra, na demolição e ao trocar de mundo.

const RADIUS_M := 0.72
## O meio do mostrador fica nesta fração do fuste acima do beiral.
const HEIGHT_SHARE := 0.55
const SURROUND_M := 0.16
const OUT_M := 0.03
const HOUR_HAND_M := 0.38
const MINUTE_HAND_M := 0.58
const FACE_DAY := Color(0.93, 0.9, 0.82)
const FACE_NIGHT := Color(1.0, 0.86, 0.55)
const STONE := Color(0.7, 0.68, 0.63)
const IRON := Color(0.12, 0.12, 0.13)
const SIDES := 24

var _simulation: Simulation
var _faces := MultiMeshInstance3D.new()
var _frames := MultiMeshInstance3D.new()
var _hours := MultiMeshInstance3D.new()
var _minutes := MultiMeshInstance3D.new()
var _dials: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var glow := ShaderMaterial.new()
	glow.shader = load("res://shaders/night_glow.gdshader") as Shader
	glow.set_shader_parameter(&"day_color", FACE_DAY)
	glow.set_shader_parameter(&"glass_energy", 1.4)
	var painted := StandardMaterial3D.new()
	painted.vertex_color_use_as_albedo = true
	painted.vertex_color_is_srgb = true
	painted.roughness = 0.7
	for part: Array in [[_faces, "Faces", face_mesh(), glow], [_frames, "Frames", frame_mesh(), painted],
			[_hours, "HourHands", hand_mesh(HOUR_HAND_M, 0.05), painted],
			[_minutes, "MinuteHands", hand_mesh(MINUTE_HAND_M, 0.032), painted]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = part[2]
		var material: Material = part[3]
		layer.material_override = material
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(layer)
	_faces.multimesh.use_colors = true
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func dial_count() -> int:
	return _dials.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	if not _dials.is_empty():
		set_hour(GameClock.clock.hour())


func rebuild() -> void:
	_dirty = false
	_dials.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if _simulation.def_of(record).silhouette == BuildingDef.Silhouette.BELFRY:
			_dials.append_array(dials(_simulation, record))
	for layer: MultiMeshInstance3D in [_faces, _frames, _hours, _minutes]:
		layer.multimesh.instance_count = _dials.size()
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	for i: int in _dials.size():
		_faces.multimesh.set_instance_transform(i, _dials[i])
		_faces.multimesh.set_instance_color(i, Color(FACE_NIGHT, 0.0))
		_frames.multimesh.set_instance_transform(i, _dials[i])
	set_hour(GameClock.clock.hour() if GameClock.clock != null else 12.0)


## Põe os ponteiros de todos os mostradores na hora dada.
func set_hour(hour: float) -> void:
	var angles := hand_angles(hour)
	var hour_turn := Basis(Vector3.BACK, -angles.x)
	var minute_turn := Basis(Vector3.BACK, -angles.y)
	for i: int in _dials.size():
		var dial := _dials[i]
		_hours.multimesh.set_instance_transform(i, Transform3D(dial.basis * hour_turn, dial.origin + dial.basis.z * 0.02))
		_minutes.multimesh.set_instance_transform(i, Transform3D(dial.basis * minute_turn, dial.origin + dial.basis.z * 0.035))


## Os mostradores da torre do prédio (mundo, com o +Z para fora da face e o meio do disco na origem): o da face da frente e
## o da face do lado, ou nenhum sem o modelo do kit.
static func dials(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return result
	var def := simulation.def_of(record)
	# o mesmo lugar do modelo, com o desvio de giro da variação (sem ele a parede passava na frente do mostrador)
	var place := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var center := BuildingKit.belfry_center(spec)
	var height := spec.height_m + BuildingKit.BELFRY_SHAFT_M * HEIGHT_SHARE
	var half := BuildingKit.BELFRY_SIDE_M * 0.5
	for normal: Vector3 in [Vector3(0.0, 0.0, -1.0), Vector3(-1.0, 0.0, 0.0)]:
		var at := center + normal * (half + OUT_M) + Vector3(0.0, height, 0.0)
		result.append(place * Transform3D(Basis.looking_at(-normal, Vector3.UP), at))
	return result


## Os ângulos dos ponteiros (rad, das doze horas no sentido do relógio): [horas, minutos].
static func hand_angles(hour: float) -> Vector2:
	var clock := fposmod(hour, 12.0)
	return Vector2(clock / 12.0 * TAU, fposmod(hour, 1.0) * TAU)


## O disco do mostrador, de frente para +Z, no zero.
static func face_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in SIDES:
		var a0 := TAU * k / SIDES
		var a1 := TAU * (k + 1) / SIDES
		VertexShapes.tri(tool, Vector3.ZERO, Vector3(cos(a1), sin(a1), 0.0) * RADIUS_M,
				Vector3(cos(a0), sin(a0), 0.0) * RADIUS_M, Color.WHITE)
	tool.generate_normals()
	return tool.commit()


## A moldura: o anel de pedra em volta do disco, o aro de ferro na borda dele e as doze marcas (a das doze maior).
static func frame_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer := RADIUS_M + SURROUND_M
	for k: int in SIDES:
		var a0 := TAU * k / SIDES
		var a1 := TAU * (k + 1) / SIDES
		var d0 := Vector3(cos(a0), sin(a0), 0.0)
		var d1 := Vector3(cos(a1), sin(a1), 0.0)
		var front := Vector3(0.0, 0.0, 0.05)
		VertexShapes.quad(tool, d0 * RADIUS_M + front, d1 * RADIUS_M + front, d1 * outer + front, d0 * outer + front, STONE)
		VertexShapes.quad(tool, d0 * outer, d0 * outer + front, d1 * outer + front, d1 * outer, STONE.darkened(0.15))
		VertexShapes.quad(tool, d0 * RADIUS_M * 0.95 + Vector3(0.0, 0.0, 0.01), d1 * RADIUS_M * 0.95 + Vector3(0.0, 0.0, 0.01),
				d1 * RADIUS_M + Vector3(0.0, 0.0, 0.01), d0 * RADIUS_M + Vector3(0.0, 0.0, 0.01), IRON)
	for k: int in 12:
		var angle := PI * 0.5 - TAU * k / 12.0
		var direction := Vector3(cos(angle), sin(angle), 0.0)
		var size := Vector3(0.035, 0.11, 0.008) if k == 0 else Vector3(0.022, 0.07, 0.008)
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.BACK, angle - PI * 0.5),
				direction * RADIUS_M * 0.82 + Vector3(0.0, 0.0, 0.012)), size, IRON)
	tool.generate_normals()
	return tool.commit()


## Um ponteiro apontando para +Y (as doze horas), do eixo até length, com um rabicho para trás e o pino no meio.
static func hand_mesh(length: float, width: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, (length - 0.1) * 0.5, 0.0), Vector3(width * 0.5, (length + 0.1) * 0.5, 0.006), IRON)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.BACK, PI * 0.25), Vector3(0.0, length * 0.92, 0.0)),
			Vector3(width * 0.7, width * 0.7, 0.006), IRON)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.0, -0.01), Vector3(0.0, 0.0, 0.012), 0.04, IRON, 8)
	tool.generate_normals()
	return tool.commit()
