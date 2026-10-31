class_name HawkView
extends Node3D
## Fase 121: o gavião sobre a cidade. Cada ilha com pelo menos MIN_HOUSES casas ganha um gavião (e mais um a cada
## HOUSES_PER_HAWK casas, até MAX_PER_ISLAND), planando em círculos largos e altos sobre o meio das casas dela (`centers`),
## cada um no seu raio, altura e sentido, subindo e descendo devagar e derivando (`pose`); bate a asa só de vez em quando
## e plana o resto com as asas um pouco erguidas (`beat`). A malha é gerada aqui (`hawk_mesh`: asas largas com as penas
## da ponta abertas e a cauda em leque) e a asa bate pelo mesmo `shaders/bird.gdshader` dos outros pássaros. No tempo de
## jogo (para na pausa); some à noite. Só apresentação; nada no save.

const MIN_HOUSES := 6
const HOUSES_PER_HAWK := 40
const MAX_PER_ISLAND := 3
const RADIUS_M := Vector2(26.0, 46.0)
const HEIGHT_M := Vector2(26.0, 40.0)
const SPEED_M_S := 7.0
const BOB_M := 2.5
const DRIFT_M := 10.0
const BANK := 0.35
## A malha tem ~1,6 m de envergadura; desenhada SCALE vezes maior (no tamanho real, de onde a câmera fica, ela sumia).
const SCALE := 1.8
## A batida: umas batidas em FLAP de cada ciclo de CYCLE_S, e o planeio com as asas a GLIDE no resto.
const CYCLE_S := 14.0
const FLAP := 0.12
const BEAT_HZ := 1.6
const WING_BEAT := 0.45
const GLIDE := 0.12
const NIGHT_HIDE := 0.5
const BODY := Color(0.42, 0.3, 0.2)
const WING := Color(0.36, 0.26, 0.18)
const WING_TIP := Color(0.16, 0.12, 0.1)
const TAIL := Color(0.62, 0.42, 0.26)
const HEAD := Color(0.86, 0.82, 0.74)

var _simulation: Simulation
var _hawks := MultiMeshInstance3D.new()
## Por gavião: [meio no mundo, semente].
var _centers: Array[Array] = []
var _time: float = 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/bird.gdshader") as Shader
	_hawks.name = "Hawks"
	_hawks.multimesh = MultiMesh.new()
	_hawks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_hawks.multimesh.use_custom_data = true
	_hawks.multimesh.mesh = hawk_mesh()
	_hawks.material_override = material
	add_child(_hawks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func hawk_count() -> int:
	return _hawks.multimesh.instance_count


func hawk_transform(index: int) -> Transform3D:
	return _hawks.multimesh.get_instance_transform(index)


func is_showing() -> bool:
	return _hawks.visible


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
	_hawks.visible = DayClock.night_factor(_simulation.config, clock.hour()) < NIGHT_HIDE
	if not _hawks.visible:
		return
	_time += delta * clock.speed_multiplier()
	_fly()


func rebuild() -> void:
	_dirty = false
	_centers = centers(_simulation.world)
	_hawks.multimesh.instance_count = _centers.size()
	_hawks.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_fly()


func _fly() -> void:
	var multimesh := _hawks.multimesh
	for i: int in _centers.size():
		var center: Vector3 = _centers[i][0]
		var seed_value: float = _centers[i][1]
		multimesh.set_instance_transform(i, pose(center, seed_value, _time))
		multimesh.set_instance_custom_data(i, Color(beat(seed_value, _time), 0.0, 0.0, 0.0))


## Os gaviões: [meio das casas da ilha no chão, semente], um por ilha com MIN_HOUSES casas e mais um a cada
## HOUSES_PER_HAWK, até MAX_PER_ISLAND.
static func centers(world: WorldState) -> Array[Array]:
	var result: Array[Array] = []
	var sums: Dictionary[int, Vector3] = {}
	var counts: Dictionary[int, int] = {}
	for id: int in world.buildings:
		var record := world.buildings[id]
		if not record.is_house():
			continue
		var grid := world.island(record.island_id)
		var at := grid.cell_world(record.origin)
		sums[record.island_id] = sums.get(record.island_id, Vector3.ZERO) + at
		counts[record.island_id] = counts.get(record.island_id, 0) + 1
	var islands := counts.keys()
	islands.sort()
	for island_id: int in islands:
		var count: int = counts[island_id]
		if count < MIN_HOUSES:
			continue
		var middle: Vector3 = sums[island_id] / count
		middle.y = maxf(world.surface_height(middle.x, middle.z), 0.0)
		var hawks := mini(1 + count / HOUSES_PER_HAWK, MAX_PER_ISLAND)
		for k: int in hawks:
			result.append([middle, island_id * 7.31 + k * 2.17 + 0.5])
	return result


## Onde o gavião está: num círculo de raio e altura da semente em volta do meio (que deriva DRIFT_M), no sentido da
## semente, subindo e descendo BOB_M, de frente para onde vai e inclinado para dentro da volta.
static func pose(center: Vector3, seed_value: float, time: float) -> Transform3D:
	var radius := lerpf(RADIUS_M.x, RADIUS_M.y, fposmod(seed_value * 0.618, 1.0))
	var height := lerpf(HEIGHT_M.x, HEIGHT_M.y, fposmod(seed_value * 1.37, 1.0))
	var turn := 1.0 if fposmod(seed_value * 3.0, 2.0) < 1.0 else -1.0
	var angle := time * SPEED_M_S / radius * turn + seed_value * TAU
	var drift := Vector3(sin(time * 0.013 + seed_value), 0.0, cos(time * 0.011 + seed_value * 1.7)) * DRIFT_M
	var offset := drift + Vector3(cos(angle) * radius, height + sin(time * 0.21 + seed_value) * BOB_M, sin(angle) * radius)
	var forward := Vector3(-sin(angle), 0.0, cos(angle)) * turn
	var basis := Basis.looking_at(forward, Vector3.UP) * Basis(Vector3.FORWARD, -BANK * turn)
	return Transform3D(basis.scaled_local(Vector3.ONE * SCALE), center + offset)


## O ângulo da asa (rad, + para cima): umas batidas no começo de cada ciclo e o planeio no resto.
static func beat(seed_value: float, time: float) -> float:
	var cycle := fposmod(time / CYCLE_S + seed_value * 0.29, 1.0)
	if cycle > FLAP:
		return GLIDE
	return sin(time * TAU * BEAT_HZ + seed_value) * WING_BEAT + GLIDE


## O gavião voando, de frente para −Z: o corpo, a cabeça clara, a cauda em leque e as asas largas e retas, com o
## cotovelo (UV.x = 0,5) e as penas da ponta abertas em dedos escuros (UV.x = 1). Envergadura de ~1,6 m.
static func hawk_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tri(tool, [Vector3(0.0, 0.03, -0.32), Vector3(0.05, 0.0, -0.18), Vector3(-0.05, 0.0, -0.18)], HEAD, 0.0)
	for side: float in [-1.0, 1.0]:
		# o corpo em dois losangos, por cima e por baixo
		_tri(tool, [Vector3(0.0, 0.0, -0.2), Vector3(side * 0.07, 0.0, 0.0), Vector3(0.0, 0.05, 0.05)], BODY, 0.0)
		_tri(tool, [Vector3(0.0, 0.05, 0.05), Vector3(side * 0.07, 0.0, 0.0), Vector3(0.0, 0.0, 0.22)], BODY, 0.0)
		_tri(tool, [Vector3(0.0, 0.0, -0.2), Vector3(0.0, -0.04, 0.05), Vector3(side * 0.07, 0.0, 0.0)], BODY, 0.0)
		# a cauda em leque
		_tri(tool, [Vector3(0.0, 0.01, 0.18), Vector3(side * 0.12, 0.01, 0.42), Vector3(0.0, 0.01, 0.44)], TAIL, 0.0)
		# o braço: do ombro ao cotovelo, largo
		var shoulder_front := Vector3(0.0, 0.03, -0.1)
		var shoulder_back := Vector3(0.0, 0.03, 0.12)
		var elbow_front := Vector3(side * 0.42, 0.04, -0.12)
		var elbow_back := Vector3(side * 0.42, 0.04, 0.14)
		_wing(tool, [shoulder_front, elbow_front, shoulder_back], [0.0, 0.5, 0.0], WING)
		_wing(tool, [shoulder_back, elbow_front, elbow_back], [0.0, 0.5, 0.5], WING)
		# a mão: as penas da ponta abertas em quatro dedos
		for k: int in 4:
			var z0 := -0.12 + 0.065 * k
			var z1 := z0 + 0.065
			var reach := 0.8 - 0.05 * absf(k - 1.2)
			var finger := Vector3(side * reach, 0.05, (z0 + z1) * 0.5 + 0.02 * k)
			_wing(tool, [Vector3(side * 0.42, 0.04, z0), finger, Vector3(side * 0.42, 0.04, z1)], [0.5, 1.0, 0.5], WING_TIP)
	tool.generate_normals()
	return tool.commit()


## Triângulo do corpo (sem batida), visto dos dois lados pelo cull_disabled do shader.
static func _tri(tool: SurfaceTool, points: Array, color: Color, uv: float) -> void:
	for point: Vector3 in points:
		tool.set_color(color)
		tool.set_uv(Vector2(uv, 0.0))
		tool.add_vertex(point)


## Triângulo da asa, com a fração da batida de cada vértice (UV.x).
static func _wing(tool: SurfaceTool, points: Array, uvs: Array, color: Color) -> void:
	for k: int in 3:
		var point: Vector3 = points[k]
		var uv: float = uvs[k]
		tool.set_color(color)
		tool.set_uv(Vector2(uv, 0.0))
		tool.add_vertex(point)
