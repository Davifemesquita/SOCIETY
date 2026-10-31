class_name ChickenView
extends Node3D
## Fase 135: galinhas no quintal cercado das casas dos camponeses (a fileira da frente do lote, `TierDef.HouseTrim.YARD`).
## Numa casa a cada CHICKEN_EVERY (pelo id), HENS galinhas andam de um ponto a outro do quintal (`yards`, `pose`) e,
## paradas, ciscam: viram para um lado e para o outro e bicam o chão em rajadas. O primeiro bicho de um quintal a cada
## ROOSTER_EVERY é um galo, maior e ruivo. Os pontos saem do hash e do relógio da vista, no tempo de jogo (para na pausa);
## à noite somem (foram para o poleiro). Uma malha gerada aqui (`chicken_mesh`), com a plumagem tingida pela cor de cada
## galinha no `shaders/chicken.gdshader`. Nada no save; refeito na obra, na demolição, na subida de classe e ao trocar de
## mundo.

const CHICKEN_EVERY := 2
const HENS := 3
const ROOSTER_EVERY := 3
const MAX_CHICKENS := 240
## Folga entre as galinhas e a cerca (ou a parede da casa), em metros.
const YARD_MARGIN_M := 0.55
## Volta de cada galinha: parada ciscando a maior parte, andando até o ponto seguinte no fim.
const PERIOD_S := 7.0
const PERIOD_VARIATION := 0.4
const WALK_SPEED_M_S := 0.45
const STEP_BOB_M := 0.02
const STEP_HZ := 5.0
## Bicadas: rajadas de PECK_BURST_S a cada PECK_CYCLE_S, PECK_HZ bicadas por segundo, o corpo inclinando até PECK_TILT.
const PECK_CYCLE_S := 2.6
const PECK_BURST_S := 1.3
const PECK_HZ := 2.5
const PECK_TILT := 0.55
## Quanto a galinha parada vira para um lado e para o outro (rad).
const LOOK_RAD := 0.7
## A malha tem ~0,35 m de comprimento; desenhada SCALE vezes maior (no tamanho real, de onde a câmera fica, ela sumia).
const SCALE := 1.35
const ROOSTER_SCALE := 1.25
const NIGHT_HIDE := 0.5
## Plumagens das galinhas (sRGB) e a do galo.
const PLUMAGES: Array[Color] = [Color(0.96, 0.94, 0.9), Color(0.66, 0.4, 0.2), Color(0.86, 0.72, 0.48),
		Color(0.3, 0.26, 0.24)]
const ROOSTER := Color(0.64, 0.28, 0.12)
const COMB := Color(0.82, 0.12, 0.1)
const BEAK := Color(0.9, 0.68, 0.22)

var _simulation: Simulation
var _chickens := MultiMeshInstance3D.new()
## Por galinha: [quintal (o Array de `yards`), índice no quintal].
var _birds: Array[Array] = []
var _time: float = 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/chicken.gdshader") as Shader
	_chickens.name = "Chickens"
	_chickens.multimesh = MultiMesh.new()
	_chickens.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_chickens.multimesh.use_custom_data = true
	_chickens.multimesh.mesh = chicken_mesh()
	_chickens.material_override = material
	_chickens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_chickens)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func chicken_count() -> int:
	return _chickens.multimesh.instance_count


func chicken_transform(index: int) -> Transform3D:
	return _chickens.multimesh.get_instance_transform(index)


func is_showing() -> bool:
	return _chickens.visible


## Anda o relógio das galinhas à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_walk()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty:
		rebuild()
	var clock := GameClock.clock
	_chickens.visible = DayClock.night_factor(_simulation.config, clock.hour()) < NIGHT_HIDE
	if not _chickens.visible:
		return
	var step := delta * clock.speed_multiplier()
	if step > 0.0:
		advance(step)


func rebuild() -> void:
	_dirty = false
	_birds.clear()
	for yard: Array in yards(_simulation):
		for i: int in HENS:
			if _birds.size() >= MAX_CHICKENS:
				break
			_birds.append([yard, i])
	var multimesh := _chickens.multimesh
	multimesh.instance_count = _birds.size()
	for index: int in _birds.size():
		var yard: Array = _birds[index][0]
		var i: int = _birds[index][1]
		multimesh.set_instance_custom_data(index, plumage(yard, i))
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_walk()


func _walk() -> void:
	var multimesh := _chickens.multimesh
	var world := _simulation.world
	for index: int in _birds.size():
		var yard: Array = _birds[index][0]
		var i: int = _birds[index][1]
		var island_id: int = yard[0]
		multimesh.set_instance_transform(index, pose(world.island(island_id), yard, i, _time))


## Os quintais com galinhas: [ilha, canto baixo e canto alto no mundo (x, z), semente, tem galo]. O quintal é a fileira
## da frente do lote das casas de classe com quintal cercado, menos YARD_MARGIN_M de cada lado.
static func yards(simulation: Simulation) -> Array[Array]:
	var result: Array[Array] = []
	var world := simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if not record.is_house() or posmod(id, CHICKEN_EVERY) != 0:
			continue
		var tier := simulation.data.tier(record.tier)
		if tier == null or tier.house_trim != TierDef.HouseTrim.YARD:
			continue
		var def := simulation.def_of(record)
		if mini(def.size.x, def.size.y) < 3:
			continue
		var row := yard_row(record.origin, def.size, record.rotation)
		var grid := world.island(record.island_id)
		var low := grid.origin_m + Vector2(row.position) * grid.cell_size + Vector2.ONE * YARD_MARGIN_M
		var high := grid.origin_m + Vector2(row.end) * grid.cell_size - Vector2.ONE * YARD_MARGIN_M
		result.append([record.island_id, low, high, absi(hash([id, &"chicken"])), posmod(id / CHICKEN_EVERY, ROOSTER_EVERY) == 0])
	return result


## A fileira da frente do lote (as células logo atrás das da frente, de fora): o quintal cercado.
static func yard_row(origin: Vector2i, size: Vector2i, rotation: int) -> Rect2i:
	var front := Footprint.front_direction(rotation)
	var row := Rect2i()
	var first := true
	for cell: Vector2i in Footprint.front_cells(origin, size, rotation):
		var inside := Rect2i(cell - front, Vector2i.ONE)
		row = inside if first else row.merge(inside)
		first = false
	return row


## O trecho do quintal da galinha i: o quintal partido em HENS ao comprido (x, z no mundo).
static func patch(yard: Array, i: int) -> Rect2:
	var low: Vector2 = yard[1]
	var high: Vector2 = yard[2]
	var size := high - low
	if size.x >= size.y:
		var step := size.x / HENS
		return Rect2(Vector2(low.x + step * i, low.y), Vector2(step, size.y))
	var step_z := size.y / HENS
	return Rect2(Vector2(low.x, low.y + step_z * i), Vector2(size.x, step_z))


## A cor (sRGB) da galinha i do quintal, no INSTANCE_CUSTOM.
static func plumage(yard: Array, i: int) -> Color:
	var rooster: bool = yard[4]
	if i == 0 and rooster:
		return ROOSTER
	var seed_value: int = yard[3]
	return PLUMAGES[posmod(seed_value / 7 + i * 3, PLUMAGES.size())]


## Onde está a galinha i do quintal no instante time: parada no ponto da volta k ciscando, depois andando até o da volta
## k + 1, sempre no trecho dela do quintal (`patch`: juntas, uma atravessava a outra). Os pontos e a duração de cada volta
## saem do hash.
static func pose(grid: IslandGrid, yard: Array, i: int, time: float) -> Transform3D:
	var own := patch(yard, i)
	var low := own.position
	var high := own.end
	var seed_value := absi(hash([yard[3], i]))
	var phase := float(seed_value % 997) / 997.0 * PERIOD_S
	var period := PERIOD_S * (1.0 + PERIOD_VARIATION * (float(seed_value / 997 % 1000) / 1000.0 - 0.5))
	var k := floori((time + phase) / period)
	var into := time + phase - k * period
	var here := AnimalView._waypoint(seed_value, k, low, high)
	var there := AnimalView._waypoint(seed_value, k + 1, low, high)
	var before := AnimalView._waypoint(seed_value, k - 1, low, high)
	var walk_s := minf(here.distance_to(there) / WALK_SPEED_M_S, period * 0.45)
	var start := period - walk_s
	var facing := AnimalView._heading(before, here)
	var point := here
	var bob := 0.0
	var tilt := 0.0
	if into < start:
		# parada: olha para um lado e para o outro e bica o chão em rajadas
		facing += sin(into * 0.8 + float(seed_value % 13)) * LOOK_RAD
		if fposmod(into + float(seed_value % 7) * 0.37, PECK_CYCLE_S) < PECK_BURST_S:
			tilt = maxf(sin(into * TAU * PECK_HZ), 0.0) * PECK_TILT
	else:
		var walked := clampf((into - start) / maxf(walk_s, 0.001), 0.0, 1.0)
		facing = lerp_angle(facing, AnimalView._heading(here, there), clampf(walked * 4.0, 0.0, 1.0))
		point = here.lerp(there, smoothstep(0.0, 1.0, walked))
		bob = absf(sin(time * STEP_HZ * PI)) * STEP_BOB_M
	var rooster: bool = yard[4]
	var scale := SCALE * (ROOSTER_SCALE if i == 0 and rooster else 1.0)
	var basis := Basis(Vector3.UP, facing) * Basis(Vector3.RIGHT, -tilt)
	return Transform3D(basis.scaled_local(Vector3.ONE * scale), Vector3(point.x, grid.height_at(point.x, point.y) + bob,
			point.y))


## Galinha de frente para −Z, com os pés no zero: o corpo cheio, o pescoço e a cabeça, o rabo erguido (a plumagem,
## UV.x = 1) e a crista, a barbela, o bico e as pernas (UV.x = 0).
static func chicken_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_uv(Vector2(1.0, 0.0))
	BirdView._add_lump(tool, Vector3(0.0, 0.2, -0.13), Vector3(0.0, 0.24, 0.12), 0.085, Vector2(0.31, 0.09), Color.WHITE)
	VertexShapes.strut(tool, Vector3(0.0, 0.22, -0.08), Vector3(0.0, 0.34, -0.12), 0.035, 0.035, Color.WHITE)
	BirdView._add_lump(tool, Vector3(0.0, 0.35, -0.18), Vector3(0.0, 0.36, -0.08), 0.042, Vector2(0.41, 0.3), Color.WHITE)
	VertexShapes.strut(tool, Vector3(0.0, 0.23, 0.08), Vector3(0.0, 0.34, 0.15), 0.035, 0.016, Color(0.88, 0.88, 0.88))
	tool.set_uv(Vector2.ZERO)
	VertexShapes.box(tool, Vector3(0.0, 0.43, -0.13), Vector3(0.012, 0.035, 0.04), COMB)
	VertexShapes.box(tool, Vector3(0.0, 0.31, -0.175), Vector3(0.01, 0.025, 0.012), COMB)
	VertexShapes.strut(tool, Vector3(0.0, 0.355, -0.175), Vector3(0.0, 0.345, -0.215), 0.014, 0.011, BEAK)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.035, 0.11, 0.0), Vector3(side * 0.035, 0.0, 0.0), 0.011, 0.011, BEAK)
		VertexShapes.box(tool, Vector3(side * 0.035, 0.006, -0.025), Vector3(0.02, 0.006, 0.035), BEAK)
	tool.generate_normals()
	return tool.commit()
