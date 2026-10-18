class_name BirdView
extends Node3D
## Pássaros (Fase 14): bandos de pombos nas ruas e de estorninhos sobre os campos, em dois MultiMesh
## (pousado, de corpo e cabeça, e voando, com as asas; cor por instância; cada pássaro tem uma instância nos
## dois, e a do que ele não está fazendo fica encolhida a zero). O pombo cisca no chão da rua e, uma vez por ciclo do bando, levanta voo, dá uma volta e
## pousa de novo; o estorninho circula sobre o campo que tem dono, o bando inteiro derivando devagar. Os
## lugares saem do desenho da grade (sem sorteio), refeitos quando estrada ou prédio muda; o voo é contado
## aqui a cada quadro, no tempo de jogo (para na pausa). À noite os pássaros somem (foram dormir). Só lê o
## mundo.
## Fase 20: a asa bate de verdade. A malha do voo marca as asas (UV.x = 1) e o `shaders/bird.gdshader` as gira
## em volta do corpo pelo ângulo que `wing_beat` dá a cada quadro (em INSTANCE_CUSTOM.r); o pombo bate rápido
## na subida e plana na descida, o estorninho bate em rajadas. O corpo não balança mais de lado.
## Fase 21: a gaivota dos portos (desenhada no ShipView) usa a malha e a batida daqui: `gull_mesh` e `gull_beat`.

enum Kind { PIGEON, STARLING }

## Pombos: um bando na célula de estrada em que posmod(7x + 13y, PIGEON_EVERY) = 0.
const PIGEON_EVERY := 19
const PIGEONS_PER_FLOCK := 5
## Ciclo do bando (s, o de cada um sai do índice) e quanto dele é voo.
const PIGEON_CYCLE_S := Vector2(18.0, 34.0)
const PIGEON_FLIGHT_S := 5.0
## Volta do voo: raio e altura no meio dela (m).
const PIGEON_FLIGHT_M := Vector2(4.0, 5.0)
## No chão: o bando se espalha até este raio em volta do meio da célula.
const PIGEON_SPREAD_M := 0.8
const PIGEON_COLOR := Color(0.55, 0.57, 0.62)

## Estorninhos: um bando sobre cada FIELD_FLOCK_EVERY-ésimo campo com dono (pelo id).
const FIELD_FLOCK_EVERY := 3
const STARLINGS_PER_FLOCK := 9
const STARLING_RADIUS_M := Vector2(3.0, 9.0)
const STARLING_HEIGHT_M := Vector2(4.0, 9.0)
const STARLING_SPEED := 0.6
const STARLING_DRIFT_M := 3.0
const STARLING_COLOR := Color(0.16, 0.15, 0.17)

## Teto de pássaros no mundo (o orçamento do assets/TODO_ASSETS.md).
const MAX_BIRDS := 200
## Acima desta noite (DayClock.night_factor) não há pássaro.
const NIGHT_HIDE := 0.5
## Batida da asa: o ângulo máximo (para cima e para baixo do plano) e as batidas por segundo.
const WING_BEAT := 0.75
const PIGEON_BEAT_HZ := 3.5
const STARLING_BEAT_HZ := 4.5
## O estorninho bate por FLAP_BURST da rajada e plana o resto (rajada de STARLING_BURST_S).
const STARLING_BURST_S := 2.5
const FLAP_BURST := 0.55
## Ângulo da asa planando (um pouco erguida, em V).
const GLIDE := 0.15
## Gaivota (Fase 21, no ShipView): plana quase sempre e bate devagar por GULL_FLAP do ciclo de GULL_CYCLE_S;
## a asa planando fica no GULL_GLIDE, mais aberta que a do pombo.
const GULL_BEAT_HZ := 2.2
const GULL_WING_BEAT := 0.55
const GULL_CYCLE_S := 7.0
const GULL_FLAP := 0.3
const GULL_GLIDE := 0.08

var _simulation: Simulation
var _birds := MultiMeshInstance3D.new()
var _perched := MultiMeshInstance3D.new()
## Por bando: [Kind, centro no mundo, semente].
var _flocks: Array[Array] = []
var _time: float = 0.0
var _dirty: bool = false


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/bird.gdshader") as Shader
	for part: Array in [[_birds, "Birds", bird_mesh()], [_perched, "Perched", perched_mesh()]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = true
		layer.multimesh.use_custom_data = true
		layer.multimesh.mesh = part[2]
		layer.material_override = material
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(layer)
	set_quality(null)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _dirty = true)
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	var scale := preset.visibility_scale if preset != null else 1.0
	_birds.visibility_range_end = _simulation.config.building_detail_range_m * scale
	_perched.visibility_range_end = _birds.visibility_range_end


func bird_count() -> int:
	return _birds.multimesh.instance_count


func flock_count(kind: int) -> int:
	return _flocks.filter(func(flock: Array) -> bool: return flock[0] == kind).size()


## Meio do bando i, no mundo (capturas).
func flock_center(index: int) -> Vector3:
	return _flocks[index][1]


## Lugar do pássaro index, pousado ou voando.
func bird_transform(index: int) -> Transform3D:
	var flying := _birds.multimesh.get_instance_transform(index)
	return flying if flying.basis.determinant() != 0.0 else _perched.multimesh.get_instance_transform(index)


## O ângulo da asa do pássaro index agora (0 no pousado).
func wing_angle(index: int) -> float:
	return _birds.multimesh.get_instance_custom_data(index).r


## Pássaros pousados agora.
func perched_count() -> int:
	var count := 0
	for index: int in _perched.multimesh.instance_count:
		if _perched.multimesh.get_instance_transform(index).basis.determinant() != 0.0:
			count += 1
	return count


func is_showing() -> bool:
	return _birds.visible


func time() -> float:
	return _time


## Anda o relógio dos pássaros à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_fly()


func _process(delta: float) -> void:
	if _dirty:
		rebuild()
	var clock := GameClock.clock
	_birds.visible = DayClock.night_factor(_simulation.config, clock.hour()) < NIGHT_HIDE
	_perched.visible = _birds.visible
	if not _birds.visible:
		return
	_time += delta * clock.speed_multiplier()
	_fly()


## Refaz os bandos: pombos nas ruas e estorninhos sobre os campos, até MAX_BIRDS.
func rebuild() -> void:
	_dirty = false
	_flocks.clear()
	var world := _simulation.world
	var total := 0
	var lift := RoadView.LIFT_M + RoadView.THICKNESS_M
	for grid: IslandGrid in world.islands:
		for cell: Vector2i in pigeon_sites(grid):
			if total + PIGEONS_PER_FLOCK > MAX_BIRDS:
				break
			_flocks.append([Kind.PIGEON, grid.surface_world(cell) + Vector3(0.0, lift, 0.0), _flocks.size() * 0.618])
			total += PIGEONS_PER_FLOCK
	var derived := _simulation.derived_state()
	for building_id: int in world.building_ids():
		if total + STARLINGS_PER_FLOCK > MAX_BIRDS:
			break
		if posmod(building_id, FIELD_FLOCK_EVERY) != 0 or not derived.module_owner.has(building_id):
			continue
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if def.id != &"field":
			continue
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		_flocks.append([Kind.STARLING, world.island(record.island_id).rect_world(area), _flocks.size() * 0.618])
		total += STARLINGS_PER_FLOCK
	_birds.multimesh.instance_count = total
	_perched.multimesh.instance_count = total
	var index := 0
	for flock: Array in _flocks:
		var color := PIGEON_COLOR if flock[0] == Kind.PIGEON else STARLING_COLOR
		for i: int in (PIGEONS_PER_FLOCK if flock[0] == Kind.PIGEON else STARLINGS_PER_FLOCK):
			_birds.multimesh.set_instance_color(index, color)
			_perched.multimesh.set_instance_color(index, color)
			index += 1
	_fly()


func _fly() -> void:
	var flying := _birds.multimesh
	var perched := _perched.multimesh
	var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
	var index := 0
	for flock: Array in _flocks:
		var center: Vector3 = flock[1]
		var seed_value: float = flock[2]
		if flock[0] == Kind.PIGEON:
			var flight := pigeon_flight(seed_value, _time)
			var on_ground := flight < 0.0
			for i: int in PIGEONS_PER_FLOCK:
				var pose := pigeon_pose(center, i, seed_value, _time)
				flying.set_instance_transform(index, hidden if on_ground else pose)
				perched.set_instance_transform(index, pose if on_ground else hidden)
				var beat := 0.0 if on_ground else wing_beat(Kind.PIGEON, i, seed_value, _time, flight)
				flying.set_instance_custom_data(index, Color(beat, 0.0, 0.0, 0.0))
				index += 1
		else:
			for i: int in STARLINGS_PER_FLOCK:
				flying.set_instance_transform(index, starling_pose(center, i, seed_value, _time))
				perched.set_instance_transform(index, hidden)
				flying.set_instance_custom_data(index, Color(wing_beat(Kind.STARLING, i, seed_value, _time, 0.0), 0.0, 0.0, 0.0))
				index += 1


## Células de estrada da ilha com bando de pombos.
static func pigeon_sites(grid: IslandGrid) -> Array[Vector2i]:
	var sites: Array[Vector2i] = []
	for cell: Vector2i in grid.road_cells():
		if posmod(cell.x * 7 + cell.y * 13, PIGEON_EVERY) == 0:
			sites.append(cell)
	return sites


## Onde o bando está no voo (0..1), ou -1 com ele no chão. Cada bando tem o ciclo e a fase dele.
static func pigeon_flight(seed_value: float, time: float) -> float:
	var period := lerpf(PIGEON_CYCLE_S.x, PIGEON_CYCLE_S.y, fposmod(seed_value * 0.37, 1.0))
	var t := fposmod(time + seed_value * period, period)
	var start := period - PIGEON_FLIGHT_S
	return (t - start) / PIGEON_FLIGHT_S if t >= start else -1.0


## O pombo i do bando: no chão, ciscando em volta do meio da célula (a malha pousada); no voo, a volta que
## sobe e desce, batendo as asas.
static func pigeon_pose(center: Vector3, i: int, seed_value: float, time: float) -> Transform3D:
	var spot_angle := seed_value * 5.0 + i * 2.4
	var spot := Vector3(cos(spot_angle), 0.0, sin(spot_angle)) * PIGEON_SPREAD_M * (0.4 + 0.6 * fposmod(i * 0.618, 1.0))
	var flight := pigeon_flight(seed_value, time)
	if flight < 0.0:
		var yaw := spot_angle + sin(time * 0.7 + i) * 1.2
		var peck := maxf(sin(time * 4.0 + i * 1.7), 0.0) * 0.25
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -peck)
		return Transform3D(basis, center + spot + Vector3(0.0, 0.05, 0.0))
	var lift := sin(PI * flight)
	var angle := flight * TAU + spot_angle
	var radius := PIGEON_FLIGHT_M.x * lift
	var offset := spot + Vector3(cos(angle) * radius, PIGEON_FLIGHT_M.y * lift + 0.05, sin(angle) * radius)
	var forward := Vector3(-sin(angle), 0.0, cos(angle))
	# inclina um pouco para dentro da volta
	return Transform3D(Basis.looking_at(forward, Vector3.UP) * Basis(Vector3.FORWARD, -0.25 * lift), center + offset)


## O estorninho i: um círculo próprio (raio, altura e sentido pelo índice) em volta do meio do bando, que
## deriva devagar sobre o campo.
static func starling_pose(center: Vector3, i: int, seed_value: float, time: float) -> Transform3D:
	var own := seed_value + i * 1.618
	var radius := lerpf(STARLING_RADIUS_M.x, STARLING_RADIUS_M.y, fposmod(own, 1.0))
	var height := lerpf(STARLING_HEIGHT_M.x, STARLING_HEIGHT_M.y, fposmod(own * 2.3, 1.0))
	var turn := 1.0 if i % 2 == 0 else -1.0
	var angle := time * STARLING_SPEED * turn * (6.0 / radius) + own * TAU
	var drift := Vector3(sin(time * 0.2 + seed_value), 0.0, cos(time * 0.17 + seed_value)) * STARLING_DRIFT_M
	var offset := drift + Vector3(cos(angle) * radius, height + sin(time * 1.1 + own) * 0.8, sin(angle) * radius)
	var forward := Vector3(-sin(angle), 0.0, cos(angle)) * turn
	return Transform3D(Basis.looking_at(forward, Vector3.UP) * Basis(Vector3.FORWARD, -0.2 * turn), center + offset)


## O ângulo da asa (rad, + para cima). Pombo: bate na primeira metade do voo (subindo) e plana na segunda,
## até a batida curta antes de pousar. Estorninho: rajadas de batida e planeio, cada um na sua fase.
static func wing_beat(kind: int, i: int, seed_value: float, time: float, flight: float) -> float:
	var phase := seed_value * 3.1 + i * 1.3
	if kind == Kind.PIGEON:
		if flight > 0.5 and flight < 0.9:
			return GLIDE
		return sin(time * TAU * PIGEON_BEAT_HZ + phase) * WING_BEAT
	var burst := fposmod(time / STARLING_BURST_S + phase * 0.37, 1.0)
	if burst > FLAP_BURST:
		return GLIDE
	return sin(time * TAU * STARLING_BEAT_HZ + phase) * WING_BEAT


## O ângulo da asa da gaivota i (rad, + para cima): umas batidas lentas no começo do ciclo dela e o planeio
## no resto.
static func gull_beat(i: int, time: float) -> float:
	var phase := i * 2.17
	var cycle := fposmod(time / GULL_CYCLE_S + phase * 0.31, 1.0)
	if cycle > GULL_FLAP:
		return GULL_GLIDE
	return sin(time * TAU * GULL_BEAT_HZ + phase) * GULL_WING_BEAT


## Gaivota voando, de frente para −Z: corpo branco e a asa longa e estreita, dobrada no cotovelo (UV.x = 0,5:
## o shader a gira pela metade do ângulo, e a ponta, UV.x = 1, pelo ângulo inteiro), com a ponta preta.
static func gull_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_uv(Vector2.ZERO)
	_add_lump(tool, Vector3(0.0, 0.0, -0.24), Vector3(0.0, 0.02, 0.22), 0.06, Vector2(0.07, -0.05), Color(0.96, 0.96, 0.95))
	var white := Color(0.96, 0.96, 0.95)
	var grey := Color(0.72, 0.74, 0.78)
	var black := Color(0.12, 0.12, 0.13)
	for direction: float in [-1.0, 1.0]:
		var front := Vector3(0.0, 0.03, -0.1)
		var back := Vector3(0.0, 0.03, 0.08)
		var elbow_front := Vector3(direction * 0.32, 0.06, -0.08)
		var elbow_back := Vector3(direction * 0.32, 0.06, 0.06)
		var tip := Vector3(direction * 0.68, 0.04, 0.12)
		var tip_mark := Vector3(direction * 0.55, 0.05, 0.02)
		# braço: do ombro ao cotovelo, cinza por cima
		for triangle: Array in [[front, elbow_front, back], [back, elbow_front, elbow_back]]:
			for vertex: Vector3 in triangle:
				tool.set_color(white if vertex.x == 0.0 else grey)
				tool.set_uv(Vector2(0.0 if vertex.x == 0.0 else 0.5, 0.0))
				tool.add_vertex(vertex)
		# mão: do cotovelo à ponta, puxada para trás, com a ponta preta
		for triangle: Array in [[elbow_front, tip_mark, elbow_back], [elbow_back, tip_mark, tip], [tip_mark, elbow_front, tip]]:
			for vertex: Vector3 in triangle:
				var outer := absf(vertex.x) > 0.5
				tool.set_color(black if outer else grey)
				tool.set_uv(Vector2(1.0 if absf(vertex.x) > 0.6 else (0.85 if outer else 0.5), 0.0))
				tool.add_vertex(vertex)
	tool.generate_normals()
	return tool.commit()


## Pássaro voando, de frente para −Z: corpo de oito faces e duas asas, um pouco mais claras; a ponta da asa
## leva UV.x = 1 (o shader a gira).
static func bird_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_uv(Vector2.ZERO)
	_add_lump(tool, Vector3(0.0, 0.0, -0.18), Vector3(0.0, 0.02, 0.16), 0.07, Vector2(0.07, -0.05), Color(0.9, 0.9, 0.9))
	tool.set_color(Color.WHITE)
	# asa: a raiz no ombro (UV.x = 0, fica com o corpo) e a ponta (UV.x = 1, gira no shader)
	for direction: float in [-1.0, 1.0]:
		tool.set_uv(Vector2.ZERO)
		tool.add_vertex(Vector3(0.0, 0.03, -0.08))
		tool.set_uv(Vector2(1.0, 0.0))
		tool.add_vertex(Vector3(direction * 0.34, 0.06, 0.02))
		tool.set_uv(Vector2.ZERO)
		tool.add_vertex(Vector3(0.0, 0.03, 0.08))
	tool.generate_normals()
	return tool.commit()


## Pombo pousado, de frente para −Z: corpo cheio, mais largo, com o rabo um pouco erguido, e a cabeça em cima
## da frente, mais escura.
static func perched_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_lump(tool, Vector3(0.0, 0.02, -0.12), Vector3(0.0, 0.06, 0.17), 0.08, Vector2(0.1, -0.05), Color(0.9, 0.9, 0.9))
	_add_lump(tool, Vector3(0.0, 0.11, -0.2), Vector3(0.0, 0.11, -0.09), 0.035, Vector2(0.15, 0.07), Color(0.7, 0.72, 0.75))
	tool.generate_normals()
	return tool.commit()


## Um volume de oito faces de nose a tail, com a meia largura dada e a altura de cima e de baixo (height.x,
## height.y) no meio.
static func _add_lump(tool: SurfaceTool, nose: Vector3, tail: Vector3, half_width: float, height: Vector2,
		color: Color) -> void:
	var middle := nose.lerp(tail, 0.45)
	var top := Vector3(middle.x, height.x, middle.z)
	var bottom := Vector3(middle.x, height.y, middle.z)
	tool.set_color(color)
	for side: Vector3 in [middle + Vector3(-half_width, 0.0, 0.0), middle + Vector3(half_width, 0.0, 0.0)]:
		for cap: Vector3 in [top, bottom]:
			for triangle: Array in [[nose, side, cap], [side, tail, cap]]:
				for vertex: Vector3 in triangle:
					tool.add_vertex(vertex)
