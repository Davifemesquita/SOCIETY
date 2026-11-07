class_name SwallowView
extends Node3D
## Fase 218: as andorinhas no campanário. Em volta da torre de cada igreja (o campanário da Fase 18, `towers`), um bando de
## FLOCK andorinhas dando voltas rápidas, cada uma na sua elipse inclinada em volta da sineira, no seu raio, altura, sentido e
## velocidade, subindo e descendo em oito (`pose`), inclinada para dentro da volta; batem as asas em rajadas curtas e planam
## entre elas (`beat`). A malha é gerada aqui (`swallow_mesh`: costas azul-escuras, peito claro, a garganta ruiva, as asas
## compridas em foice e a cauda em forquilha) e a asa bate pelo mesmo `shaders/bird.gdshader` dos outros pássaros. No tempo de
## jogo (para na pausa); somem à noite. Só apresentação; nada no save.

const FLOCK := 10
const RADIUS_M := Vector2(4.5, 11.0)
## A altura da volta em relação ao meio da sineira.
const HEIGHT_M := Vector2(-3.0, 5.0)
const SPEED_M_S := Vector2(8.0, 12.0)
const WAVE_M := 1.6
const TILT := 0.35
const BANK := 0.6
## A malha tem ~0,34 m de envergadura; desenhada SCALE vezes maior (no tamanho real, de onde a câmera fica, ela sumia).
const SCALE := 2.6
## A batida: rajadas de FLAP de cada ciclo de CYCLE_S, e o planeio com as asas a GLIDE no resto.
const CYCLE_S := 1.8
const FLAP := 0.45
const BEAT_HZ := 6.5
const WING_BEAT := 0.55
const GLIDE := 0.05
const NIGHT_HIDE := 0.5
const BACK := Color(0.1, 0.12, 0.22)
const WING := Color(0.08, 0.09, 0.16)
const BELLY := Color(0.88, 0.84, 0.76)
const THROAT := Color(0.62, 0.26, 0.16)

var _simulation: Simulation
var _birds := MultiMeshInstance3D.new()
## O meio da sineira de cada torre, no mundo.
var _towers: Array[Vector3] = []
var _time: float = 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/bird.gdshader") as Shader
	_birds.name = "Swallows"
	_birds.multimesh = MultiMesh.new()
	_birds.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_birds.multimesh.use_custom_data = true
	_birds.multimesh.mesh = swallow_mesh()
	_birds.material_override = material
	_birds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_birds)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func swallow_count() -> int:
	return _birds.multimesh.instance_count


func swallow_transform(index: int) -> Transform3D:
	return _birds.multimesh.get_instance_transform(index)


func tower_count() -> int:
	return _towers.size()


func is_showing() -> bool:
	return _birds.visible


## Anda o relógio à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_fly()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _simulation == null:
		return
	if _dirty:
		rebuild()
	var clock := GameClock.clock
	_birds.visible = not _towers.is_empty() and DayClock.night_factor(_simulation.config, clock.hour()) < NIGHT_HIDE
	if not _birds.visible:
		return
	_time += delta * clock.speed_multiplier()
	_fly()


func rebuild() -> void:
	_dirty = false
	_towers = towers(_simulation)
	_birds.multimesh.instance_count = _towers.size() * FLOCK
	_birds.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_fly()


func _fly() -> void:
	var multimesh := _birds.multimesh
	for t: int in _towers.size():
		for k: int in FLOCK:
			var seed_value := t * 3.17 + k * 1.618 + 0.37
			var i := t * FLOCK + k
			multimesh.set_instance_transform(i, pose(_towers[t], seed_value, _time))
			multimesh.set_instance_custom_data(i, Color(beat(seed_value, _time), 0.0, 0.0, 0.0))


## O meio da sineira de cada prédio com campanário, no mundo (no lugar do modelo, com o desvio da variação), pela ordem dos ids.
static func towers(simulation: Simulation) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var world := simulation.world
	var ids := world.building_ids()
	ids.sort()
	for id: int in ids:
		var record := world.building(id)
		var def := simulation.def_of(record)
		if def.silhouette != BuildingDef.Silhouette.BELFRY:
			continue
		var grid := world.island(record.island_id)
		var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
		if spec == null:
			continue
		var place := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
		var height := spec.height_m + BuildingKit.BELFRY_SHAFT_M + BuildingKit.BELFRY_OPEN_M * 0.5
		result.append(place * (BuildingKit.belfry_center(spec) + Vector3(0.0, height, 0.0)))
	return result


## Onde a andorinha está: numa elipse inclinada em volta da sineira, com o raio, a altura, o sentido, a velocidade e o giro da
## semente, subindo e descendo WAVE_M em oito (duas ondas por volta), de frente para onde vai e inclinada para dentro da volta.
static func pose(tower: Vector3, seed_value: float, time: float) -> Transform3D:
	var radius := lerpf(RADIUS_M.x, RADIUS_M.y, fposmod(seed_value * 0.618, 1.0))
	var height := lerpf(HEIGHT_M.x, HEIGHT_M.y, fposmod(seed_value * 1.37, 1.0))
	var speed := lerpf(SPEED_M_S.x, SPEED_M_S.y, fposmod(seed_value * 2.71, 1.0))
	var turn := 1.0 if fposmod(seed_value * 3.0, 2.0) < 1.0 else -1.0
	var squash := 0.65 + 0.35 * fposmod(seed_value * 0.91, 1.0)
	var spin := fposmod(seed_value * 5.3, TAU)
	var angle := time * speed / radius * turn + seed_value * TAU
	var at := _orbit(radius, squash, spin, height, seed_value, angle)
	var ahead := _orbit(radius, squash, spin, height, seed_value, angle + 0.05 * turn)
	var forward := (ahead - at).normalized()
	var flat := Vector3(forward.x, 0.0, forward.z)
	var basis := Basis.looking_at(forward if flat.length_squared() > 1e-4 else Vector3.FORWARD, Vector3.UP) \
			* Basis(Vector3.FORWARD, -BANK * turn)
	return Transform3D(basis.scaled_local(Vector3.ONE * SCALE), tower + at)


## O ponto da elipse no ângulo: raio em x, raio × squash em z, girada por spin, inclinada TILT no plano e com a onda em oito.
static func _orbit(radius: float, squash: float, spin: float, height: float, seed_value: float, angle: float) -> Vector3:
	var local := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius * squash)
	local.y = height + sin(angle * 2.0 + seed_value) * WAVE_M + cos(angle) * radius * TILT * (fposmod(seed_value, 1.0) - 0.5)
	return Basis(Vector3.UP, spin) * local


## O ângulo da asa (rad, + para cima): rajadas de batidas no começo de cada ciclo e o planeio no resto.
static func beat(seed_value: float, time: float) -> float:
	var cycle := fposmod(time / CYCLE_S + seed_value * 0.29, 1.0)
	if cycle > FLAP:
		return GLIDE
	return sin(time * TAU * BEAT_HZ + seed_value) * WING_BEAT + GLIDE


## A andorinha voando, de frente para −Z: o corpo com as costas escuras e o peito claro, a garganta ruiva, as asas compridas
## em foice (o cotovelo com UV.x = 0,5, a ponta com UV.x = 1) e a cauda em forquilha. Envergadura de ~0,34 m.
static func swallow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	HawkView._tri(tool, [Vector3(0.0, 0.012, -0.075), Vector3(0.016, 0.0, -0.045), Vector3(-0.016, 0.0, -0.045)], THROAT, 0.0)
	for side: float in [-1.0, 1.0]:
		# o corpo: as costas por cima e o peito por baixo
		HawkView._tri(tool, [Vector3(0.0, 0.012, -0.05), Vector3(side * 0.018, 0.0, 0.0), Vector3(0.0, 0.014, 0.04)], BACK,
				0.0)
		HawkView._tri(tool, [Vector3(0.0, 0.014, 0.04), Vector3(side * 0.018, 0.0, 0.0), Vector3(0.0, 0.004, 0.07)], BACK,
				0.0)
		HawkView._tri(tool, [Vector3(0.0, 0.0, -0.05), Vector3(0.0, -0.012, 0.03), Vector3(side * 0.018, 0.0, 0.0)], BELLY,
				0.0)
		# a cauda em forquilha: a ponta longa de cada lado
		HawkView._tri(tool, [Vector3(0.0, 0.004, 0.06), Vector3(side * 0.03, 0.004, 0.16), Vector3(side * 0.01, 0.004, 0.08)],
				BACK, 0.0)
		# a asa em foice: do ombro ao cotovelo e do cotovelo à ponta, puxada para trás
		var shoulder_front := Vector3(0.0, 0.01, -0.025)
		var shoulder_back := Vector3(0.0, 0.01, 0.02)
		var elbow_front := Vector3(side * 0.07, 0.012, -0.02)
		var elbow_back := Vector3(side * 0.07, 0.012, 0.02)
		var tip := Vector3(side * 0.17, 0.014, 0.07)
		HawkView._wing(tool, [shoulder_front, elbow_front, shoulder_back], [0.0, 0.5, 0.0], WING)
		HawkView._wing(tool, [shoulder_back, elbow_front, elbow_back], [0.0, 0.5, 0.5], WING)
		HawkView._wing(tool, [elbow_front, tip, elbow_back], [0.5, 1.0, 0.5], WING)
	tool.generate_normals()
	return tool.commit()
