class_name BatView
extends Node3D
## Fase 229: os morcegos ao anoitecer. Em volta da torre de cada igreja (`SwallowView.towers`, as mesmas das andorinhas da Fase
## 218), um bando de FLOCK morcegos esvoaçando do anoitecer à madrugada, cada um em voltas tortas em volta da sineira — o raio e a
## altura mudando, e o zigue-zague das viradas bruscas atrás dos insetos (`pose`) —, batendo as asas sem parar (`beat`). A malha
## é gerada aqui (`bat_mesh`: o corpo escuro, as orelhas e as asas de membrana com a borda de trás recortada) e a asa bate pelo
## mesmo `shaders/bird.gdshader` dos pássaros. No tempo de jogo (para na pausa); aparecem só com a noite (o contrário das
## andorinhas). Só apresentação; nada no save.

const FLOCK := 6
const RADIUS_M := Vector2(3.5, 8.0)
const HEIGHT_M := Vector2(-4.0, 3.0)
const SPEED_M_S := Vector2(5.0, 8.0)
## O zigue-zague: quanto o raio e a altura tremem e quão depressa.
const ZIG_M := 1.4
const ZIG_HZ := 1.7
const BANK := 0.5
## A malha tem ~0,4 m de envergadura; desenhada SCALE vezes maior (no tamanho real, de onde a câmera fica, ela sumia).
const SCALE := 2.4
const BEAT_HZ := 7.0
const WING_BEAT := 0.75
## Aparecem a partir deste quanto de noite.
const NIGHT_SHOW := 0.35
const BODY := Color(0.16, 0.12, 0.1)
const WING := Color(0.22, 0.17, 0.14)

var _simulation: Simulation
var _bats := MultiMeshInstance3D.new()
var _towers: Array[Vector3] = []
var _time: float = 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/bird.gdshader") as Shader
	_bats.name = "Bats"
	_bats.multimesh = MultiMesh.new()
	_bats.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_bats.multimesh.use_custom_data = true
	_bats.multimesh.mesh = bat_mesh()
	_bats.material_override = material
	_bats.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bats)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func bat_count() -> int:
	return _bats.multimesh.instance_count


func bat_transform(index: int) -> Transform3D:
	return _bats.multimesh.get_instance_transform(index)


func is_showing() -> bool:
	return _bats.visible


## Anda o relógio à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_fly()


## Mostra ou esconde pelo quanto de noite (testes e capturas; no jogo o _process faz isso pela hora).
func show_for_night(night: float) -> void:
	_bats.visible = not _towers.is_empty() and night >= NIGHT_SHOW


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _simulation == null:
		return
	if _dirty:
		rebuild()
	var clock := GameClock.clock
	show_for_night(DayClock.night_factor(_simulation.config, clock.hour()))
	if not _bats.visible:
		return
	_time += delta * clock.speed_multiplier()
	_fly()


func rebuild() -> void:
	_dirty = false
	_towers = SwallowView.towers(_simulation)
	_bats.multimesh.instance_count = _towers.size() * FLOCK
	_bats.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_fly()


func _fly() -> void:
	var multimesh := _bats.multimesh
	for t: int in _towers.size():
		for k: int in FLOCK:
			var seed_value := t * 2.71 + k * 1.37 + 0.11
			var i := t * FLOCK + k
			multimesh.set_instance_transform(i, pose(_towers[t], seed_value, _time))
			multimesh.set_instance_custom_data(i, Color(beat(seed_value, _time), 0.0, 0.0, 0.0))


## Onde o morcego está: numa volta em torno da sineira com o raio, a altura, o sentido e a velocidade da semente, o raio e a
## altura tremendo em zigue-zague, de frente para onde vai e inclinado para dentro da volta.
static func pose(tower: Vector3, seed_value: float, time: float) -> Transform3D:
	var at := _point(seed_value, time)
	var ahead := _point(seed_value, time + 0.05)
	var forward := (ahead - at).normalized()
	var turn := 1.0 if fposmod(seed_value * 3.0, 2.0) < 1.0 else -1.0
	var flat := Vector3(forward.x, 0.0, forward.z)
	var basis := Basis.looking_at(forward if flat.length_squared() > 1e-4 else Vector3.FORWARD, Vector3.UP) \
			* Basis(Vector3.FORWARD, -BANK * turn)
	return Transform3D(basis.scaled_local(Vector3.ONE * SCALE), tower + at)


## O ponto da volta no tempo, em relação à sineira.
static func _point(seed_value: float, time: float) -> Vector3:
	var radius := lerpf(RADIUS_M.x, RADIUS_M.y, fposmod(seed_value * 0.618, 1.0))
	var height := lerpf(HEIGHT_M.x, HEIGHT_M.y, fposmod(seed_value * 1.37, 1.0))
	var speed := lerpf(SPEED_M_S.x, SPEED_M_S.y, fposmod(seed_value * 2.71, 1.0))
	var turn := 1.0 if fposmod(seed_value * 3.0, 2.0) < 1.0 else -1.0
	var angle := time * speed / radius * turn + seed_value * TAU
	var zig := sin(time * TAU * ZIG_HZ + seed_value * 5.0) * sin(time * TAU * ZIG_HZ * 0.37 + seed_value)
	var r := radius + zig * ZIG_M
	var y := height + cos(time * TAU * ZIG_HZ * 0.8 + seed_value * 3.0) * ZIG_M * 0.6
	return Vector3(cos(angle) * r, y, sin(angle) * r)


## O ângulo da asa (rad, + para cima): bate sem parar.
static func beat(seed_value: float, time: float) -> float:
	return sin(time * TAU * BEAT_HZ + seed_value * 2.0) * WING_BEAT


## O morcego voando, de frente para −Z: o corpo e a cabeça com as duas orelhas, e cada asa de membrana em três dedos, do ombro
## (UV.x = 0) ao cotovelo (0,5) e à ponta (1), com a borda de trás recortada entre os dedos. Envergadura de ~0,4 m.
static func bat_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		HawkView._tri(tool, [Vector3(0.0, 0.012, -0.06), Vector3(side * 0.02, 0.0, 0.0), Vector3(0.0, 0.015, 0.05)], BODY, 0.0)
		HawkView._tri(tool, [Vector3(0.0, 0.0, -0.06), Vector3(0.0, -0.012, 0.04), Vector3(side * 0.02, 0.0, 0.0)], BODY, 0.0)
		# a orelha
		HawkView._tri(tool, [Vector3(side * 0.006, 0.014, -0.05), Vector3(side * 0.016, 0.04, -0.045),
				Vector3(side * 0.016, 0.012, -0.035)], BODY, 0.0)
		# a asa: o braço até o cotovelo, e a mão em três dedos com a membrana recortada entre eles
		var shoulder := Vector3(0.0, 0.01, -0.025)
		var hip := Vector3(0.0, 0.008, 0.04)
		var elbow := Vector3(side * 0.08, 0.014, -0.03)
		var fingers: Array[Vector3] = [Vector3(side * 0.2, 0.016, -0.02), Vector3(side * 0.17, 0.012, 0.05),
				Vector3(side * 0.1, 0.01, 0.075)]
		var scallops: Array[Vector3] = [Vector3(side * 0.15, 0.012, 0.02), Vector3(side * 0.11, 0.01, 0.055),
				Vector3(side * 0.05, 0.008, 0.06)]
		HawkView._wing(tool, [shoulder, elbow, hip], [0.0, 0.5, 0.0], WING)
		HawkView._wing(tool, [elbow, fingers[0], scallops[0]], [0.5, 1.0, 0.8], WING)
		HawkView._wing(tool, [elbow, scallops[0], fingers[1]], [0.5, 0.8, 0.9], WING)
		HawkView._wing(tool, [elbow, fingers[1], scallops[1]], [0.5, 0.9, 0.7], WING)
		HawkView._wing(tool, [elbow, scallops[1], fingers[2]], [0.5, 0.7, 0.6], WING)
		HawkView._wing(tool, [elbow, fingers[2], scallops[2]], [0.5, 0.6, 0.3], WING)
		HawkView._wing(tool, [elbow, scallops[2], hip], [0.5, 0.3, 0.0], WING)
	tool.generate_normals()
	return tool.commit()
