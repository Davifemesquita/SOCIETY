class_name WireBirdView
extends Node3D
## Fase 273: as andorinhas no fio. Nos fios que a PowerLineView estica entre os postes (Fase 120), um vão a cada SPAN_EVERY, uma
## fila de andorinhas pousadas perto do meio do fio, a GAP_M uma da outra, até BIRDS_PER_SPAN, de lado para o fio e viradas para
## um lado ou para o outro de tempos em tempos (`perches`, `PerchedGullView.heading_at`); somem à noite. `swallow_mesh`: as costas
## azul-escuras, a barriga branca, a garganta ferrugem e a cauda em forquilha. Um MultiMesh sem sombra; nada no save; refeito
## quando a PowerLineView refaz os fios.

const SPAN_EVERY := 2
const BIRDS_PER_SPAN := 5
const GAP_M := 0.32
const SIZE := 1.4
const NIGHT_HIDE := 0.5
const SALT := 273
const BACK := Color(0.1, 0.13, 0.24)
const BELLY := Color(0.92, 0.9, 0.86)
const THROAT := Color(0.62, 0.3, 0.18)
const FEET := Color(0.15, 0.13, 0.12)

var _lines: PowerLineView
var _config: GameConfig
var _birds := MultiMeshInstance3D.new()
## O pé de cada andorinha, o lado do fio (ângulo em y) e a semente dela (testes: sem tela o MultiMesh devolve zeros).
var spots: Array[Vector3] = []
var sides := PackedFloat32Array()
var headings := PackedFloat32Array()
var _seeds := PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(lines: PowerLineView, config: GameConfig) -> void:
	_lines = lines
	_config = config
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	_birds.name = "WireBirds"
	_birds.multimesh = MultiMesh.new()
	_birds.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_birds.multimesh.mesh = swallow_mesh()
	_birds.multimesh.custom_aabb = WorldBounds.of(config)
	_birds.material_override = material
	_birds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_birds)
	lines.rebuilt.connect(func() -> void: _dirty = true)


func bird_count() -> int:
	return spots.size()


func _process(delta: float) -> void:
	if _dirty and _lines != null:
		rebuild()
	var clock := GameClock.clock
	_birds.visible = DayClock.night_factor(_config, clock.hour()) < NIGHT_HIDE
	advance(delta * clock.speed_multiplier())


func rebuild() -> void:
	_dirty = false
	spots.clear()
	sides.clear()
	_seeds.clear()
	var spans := _lines.spans()
	for s: int in spans.size():
		for perch: Array in perches(spans[s], s):
			var at: Vector3 = perch[0]
			var side: float = perch[1]
			spots.append(at)
			sides.append(side)
			_seeds.append(absi(hash(Vector3i(roundi(at.x * 10.0), roundi(at.z * 10.0), SALT))))
	headings.resize(spots.size())
	_birds.multimesh.instance_count = spots.size()
	advance(0.0)


## Os pousos de um fio (a curva dele, do HarborView.rope_span) e o número dele na lista: [o ponto no alto do fio, o ângulo em y
## de lado para ele]. Nenhum se o fio não é da vez; senão até BIRDS_PER_SPAN a GAP_M uma da outra, centrados no meio da curva.
static func perches(curve: PackedVector3Array, number: int) -> Array[Array]:
	var result: Array[Array] = []
	if posmod(number, SPAN_EVERY) != 0 or curve.size() < 2:
		return result
	var length := 0.0
	for k: int in curve.size() - 1:
		length += curve[k].distance_to(curve[k + 1])
	var count := mini(BIRDS_PER_SPAN, floori(length * 0.5 / GAP_M))
	var along := curve[curve.size() - 1] - curve[0]
	along.y = 0.0
	if along.length() < 0.01:
		return result
	var side := atan2(-along.z, along.x)
	for b: int in count:
		var at := _point_at(curve, length * 0.5 + (b - (count - 1) * 0.5) * GAP_M)
		result.append([at + Vector3(0.0, PowerLineView.WIRE_RADIUS_M, 0.0), side])
	return result


## O ponto da curva a distance metros do começo, andando pelos lances.
static func _point_at(curve: PackedVector3Array, distance: float) -> Vector3:
	var walked := 0.0
	for k: int in curve.size() - 1:
		var step := curve[k].distance_to(curve[k + 1])
		if walked + step >= distance:
			return curve[k].lerp(curve[k + 1], (distance - walked) / maxf(step, 0.0001))
		walked += step
	return curve[curve.size() - 1]


## Anda o relógio das andorinhas seconds de jogo: cada uma de lado para o fio, olhando para um lado ou para o outro.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in spots.size():
		var flip := PI if PerchedGullView.heading_at(_seeds[i], _time) > PI else 0.0
		headings[i] = sides[i] + flip
		_birds.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, headings[i]).scaled(Vector3.ONE * SIZE),
				spots[i]))


## A andorinha pousada, de frente para −Z, com os pés em y = 0 (cerca de 17 cm): o corpo com as costas azul-escuras e a barriga
## branca, a garganta ferrugem, a cabeça escura com o bico curto, as asas compridas dobradas passando da cauda e a cauda em forquilha.
static func swallow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ball := CropView._sphere(1.0)
	RoofPigeonView._ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.028, 0.03, 0.05)), Vector3(0.0, 0.035, 0.0)), BELLY)
	RoofPigeonView._ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.03, 0.022, 0.055)), Vector3(0.0, 0.05, 0.005)), BACK)
	RoofPigeonView._ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.02, 0.018, 0.02)), Vector3(0.0, 0.04, -0.04)), THROAT)
	RoofPigeonView._ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.022, 0.022, 0.024)), Vector3(0.0, 0.065, -0.042)), BACK)
	VertexShapes.strut(tool, Vector3(0.0, 0.064, -0.064), Vector3(0.0, 0.062, -0.074), 0.005, 0.002, FEET)
	for side: float in [-1.0, 1.0]:
		# a asa dobrada, comprida e fina, passando da cauda
		RoofPigeonView._ball(tool, ball, Transform3D(Basis(Vector3.RIGHT, -0.12).scaled(Vector3(0.012, 0.012, 0.07)),
				Vector3(side * 0.025, 0.05, 0.05)), BACK)
		# a ponta da cauda em forquilha
		VertexShapes.tri(tool, Vector3(0.0, 0.04, 0.06), Vector3(side * 0.012, 0.04, 0.065), Vector3(side * 0.02, 0.03, 0.13),
				BACK)
		VertexShapes.tri(tool, Vector3(side * 0.012, 0.04, 0.065), Vector3(0.0, 0.04, 0.06), Vector3(side * 0.02, 0.03, 0.13),
				BACK)
		VertexShapes.strut(tool, Vector3(side * 0.008, 0.0, 0.0), Vector3(side * 0.008, 0.012, 0.0), 0.003, 0.003, FEET)
	tool.generate_normals()
	return tool.commit()
