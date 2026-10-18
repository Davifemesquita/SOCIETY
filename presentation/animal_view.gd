class_name AnimalView
extends Node3D
## Animais da cidade viva (seção 9, Fase 13): ovelhas e porcos nos pastos das fazendas deles e um cão na
## porta de parte das casas. Os bichos do Farm Animals Pack da Quaternius (CC0) gravados em VAT por
## tools/bake_animals.gd, animados pelo shaders/animal_vat.gdshader (o tempo é o visual_time dos
## pedestres: param na pausa). Só lê o mundo; refeito quando um prédio entra ou sai.
## O cavalo da carroça usa as mesmas peças (layer, place), pela CartView.
## Fase 19: os bichos andam. O pacote só traz a animação parada (e o pulo), então a caminhada é no código:
## cada bicho pasta um tempo, vira e anda devagar até outro ponto do seu quarto do pasto (o cão, de um lado para o
## outro ao longo da frente da casa), balançando no passo. O caminho sai do hash do bicho e do tempo visual
## (o mesmo depois de carregar; para na pausa).

const SHADER := preload("res://shaders/animal_vat.gdshader")
const MODEL_DIR := "res://assets/vat/"
## Comprimento de cada bicho no mundo (do focinho ao rabo).
const LENGTH_M := {&"sheep": 1.3, &"pig": 1.2, &"dog": 0.65, &"horse": 2.3}
## Qual bicho cada fazenda põe no pasto dela.
const PASTURE_ANIMAL := {&"sheep_farm": &"sheep", &"pig_farm": &"pig"}
const PER_PASTURE := 4
## Folga dos bichos até a borda do pasto.
const PASTURE_MARGIN_M := 1.0
## Um cão a cada DOG_EVERY casas (pelo id), deitado ao lado da porta.
const DOG_EVERY := 5
const DOG_SIDE_M := 1.1
## Variação de tom e de ritmo da animação entre os bichos.
const SHADE_VARIATION := 0.12
## Caminhada (Fase 19): a cada WANDER_PERIOD_S (± a variação) o bicho escolhe outro ponto; anda a
## WALK_SPEED_M_S, gasta TURN_S virando no começo, sobe e desce STEP_BOB_M a STEP_HZ passos por segundo.
const WANDER_PERIOD_S := 14.0
const PERIOD_VARIATION := 0.35
const WALK_SPEED_M_S := {&"sheep": 0.55, &"pig": 0.5, &"dog": 0.9}
const TURN_S := 0.7
const STEP_BOB_M := 0.035
const STEP_HZ := 2.2
## Folga entre os quartos do pasto (cada bicho anda no seu).
const QUARTER_GAP_M := 0.3
## Quanto o cão anda de cada lado do lugar dele, ao longo da frente da casa.
const DOG_PACE_M := 0.7

var _simulation: Simulation
var _layers: Dictionary[StringName, MultiMeshInstance3D] = {}
var _counts: Dictionary[StringName, int] = {}
var _range_m: float = 260.0
var _dirty: bool = false
## Por bicho que anda: [bicho, índice na camada, semente, ilha, canto baixo (x, z), canto alto (x, z)] e, no
## cão, o giro de descanso (olhando para a rua).
var _walkers: Array[Array] = []
var _time: float = 0.0

static var _models: Dictionary[StringName, VatModel] = {}
static var _scales: Dictionary[StringName, float] = {}


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	for animal: StringName in [&"sheep", &"pig", &"dog"]:
		var layer := AnimalView.layer(animal)
		if layer == null:
			continue
		layer.name = String(animal).capitalize()
		add_child(layer)
		_layers[animal] = layer
	_apply_range()
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	_apply_range()


func animal_count(animal: StringName = &"") -> int:
	if animal != &"":
		return _counts.get(animal, 0)
	var total := 0
	for kind: StringName in _counts:
		total += _counts[kind]
	return total


func _process(delta: float) -> void:
	if _dirty:
		rebuild()
	var step := delta * GameClock.clock.speed_multiplier()
	if step > 0.0:
		advance(step)


## Anda o relógio dos bichos e leva cada um ao lugar dele nesse instante.
func advance(seconds: float) -> void:
	_time += seconds
	for walker: Array in _walkers:
		var animal: StringName = walker[0]
		var index: int = walker[1]
		var multimesh := _layers[animal].multimesh
		var where := wander(walker, _time)
		multimesh.set_instance_transform(index, Transform3D(where.basis.scaled_local(Vector3.ONE * scale_of(animal)),
				where.origin))


## Lugar do bicho i da camada (mundo, com a escala).
func animal_transform(animal: StringName, index: int) -> Transform3D:
	return _layers[animal].multimesh.get_instance_transform(index)


## Onde o bicho está no instante time: parado no ponto da volta k pastando, depois vira e anda até o ponto da
## volta k + 1. Os pontos e a duração de cada volta vêm do hash (semente, k).
func wander(walker: Array, time: float) -> Transform3D:
	var animal: StringName = walker[0]
	var seed_value: int = walker[2]
	var low: Vector2 = walker[4]
	var high: Vector2 = walker[5]
	var island_id: int = walker[3]
	var grid := _simulation.world.island(island_id)
	# o cão começa a volta já descansado, olhando para a rua
	var resting := walker.size() > 6
	var phase := TURN_S * 1.5 if resting else float(seed_value % 997) / 997.0 * WANDER_PERIOD_S
	var period := WANDER_PERIOD_S * (1.0 + PERIOD_VARIATION * (float(seed_value / 997 % 1000) / 1000.0 - 0.5))
	var k := floori((time + phase) / period)
	var into := time + phase - k * period
	var here := _waypoint(seed_value, k, low, high)
	var there := _waypoint(seed_value, k + 1, low, high)
	var before := _waypoint(seed_value, k - 1, low, high)
	var speed: float = WALK_SPEED_M_S.get(animal, 0.5)
	var walk_s := minf(here.distance_to(there) / speed, period * 0.6)
	var start := period - walk_s - TURN_S
	var facing := _heading(before, here)
	if resting:
		var rest: float = walker[6]
		facing = lerp_angle(facing, rest, clampf(into / TURN_S, 0.0, 1.0))
	var point := here
	var bob := 0.0
	if into >= start:
		var turned := clampf((into - start) / TURN_S, 0.0, 1.0)
		facing = lerp_angle(facing, _heading(here, there), turned)
		var walked := clampf((into - start - TURN_S) / maxf(walk_s, 0.001), 0.0, 1.0)
		point = here.lerp(there, smoothstep(0.0, 1.0, walked))
		if walked > 0.0 and walked < 1.0:
			bob = absf(sin(time * STEP_HZ * PI)) * STEP_BOB_M
	var origin := Vector3(point.x, grid.height_at(point.x, point.y) + bob, point.y)
	return Transform3D(Basis(Vector3.UP, facing), origin)


## O ponto da volta k: sorteado dentro do retângulo (low, high) pelo hash.
static func _waypoint(seed_value: int, k: int, low: Vector2, high: Vector2) -> Vector2:
	var noise := hash([seed_value, k])
	var u := float(noise % 1000) / 1000.0
	var v := float(noise / 1000 % 1000) / 1000.0
	return Vector2(lerpf(low.x, high.x, u), lerpf(low.y, high.y, v))


## Giro em y que leva o −Z do modelo (a frente dele) de a para b.
static func _heading(a: Vector2, b: Vector2) -> float:
	var direction := b - a
	if direction.length_squared() < 0.0001:
		return 0.0
	return atan2(-direction.x, -direction.y)


## Refaz todos os bichos: os pastos pela fazenda dona deles e os cães pelas casas.
func rebuild() -> void:
	_dirty = false
	var world := _simulation.world
	var derived := _simulation.derived_state()
	var places: Dictionary[StringName, Array] = {}
	for animal: StringName in _layers:
		places[animal] = []
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if def.kind == BuildingDef.Kind.MODULE:
			var owner_id: int = derived.module_owner.get(building_id, 0)
			var farm := world.building(owner_id)
			var animal := &""
			if farm != null and PASTURE_ANIMAL.has(farm.def_id):
				animal = PASTURE_ANIMAL[farm.def_id]
			if places.has(animal):
				places[animal].append_array(_pasture(record, def, building_id))
		elif record.is_house() and building_id % DOG_EVERY == 0 and places.has(&"dog"):
			places[&"dog"].append(_dog(record, def))
	_counts.clear()
	_walkers.clear()
	for animal: StringName in _layers:
		var list: Array = places[animal]
		_counts[animal] = list.size()
		var multimesh := _layers[animal].multimesh
		if multimesh.instance_count < list.size():
			multimesh.instance_count = list.size() + 16
		multimesh.visible_instance_count = list.size()
		for i: int in list.size():
			var item: Array = list[i]
			var where: Transform3D = item[0]
			var seed_value: int = item[1]
			AnimalView.place(multimesh, i, animal, where, seed_value, &"idle")
			if item.size() > 2:
				var bounds: Array = item[2]
				_walkers.append([animal, i, seed_value] + bounds)
	# já no lugar do caminho (o sorteio de place é só o tom e o ritmo)
	advance(0.0)


## Os bichos de um pasto: em células sorteadas pelo id, longe da borda, cada um virado para um lado.
func _pasture(record: BuildingRecord, def: BuildingDef, building_id: int) -> Array:
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var cell_size := _simulation.config.cell_size_m
	var result: Array = []
	for i: int in PER_PASTURE:
		var seed_value := hash([building_id, i])
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		var cell := area.position + Vector2i(random.randi_range(0, area.size.x - 1), random.randi_range(0, area.size.y - 1))
		var spread := cell_size * 0.5 - PASTURE_MARGIN_M * 0.5
		var point := grid.surface_world(cell) + Vector3(random.randf_range(-spread, spread), 0.0,
				random.randf_range(-spread, spread))
		# preso dentro do pasto, com a folga
		var low := grid.surface_world(area.position) - Vector3(cell_size, 0.0, cell_size) * 0.5
		var high := low + Vector3(area.size.x, 0.0, area.size.y) * cell_size
		point.x = clampf(point.x, low.x + PASTURE_MARGIN_M, high.x - PASTURE_MARGIN_M)
		point.z = clampf(point.z, low.z + PASTURE_MARGIN_M, high.z - PASTURE_MARGIN_M)
		# cada bicho anda no seu quarto do pasto (os quatro juntos no meio se atravessavam)
		var inner_low := Vector2(low.x, low.z) + Vector2.ONE * PASTURE_MARGIN_M
		var quarter := (Vector2(high.x, high.z) - Vector2.ONE * PASTURE_MARGIN_M - inner_low) * 0.5
		var corner := inner_low + quarter * Vector2(i % 2, (i / 2) % 2)
		var gap := Vector2.ONE * minf(QUARTER_GAP_M, quarter.x * 0.4)
		var bounds := [record.island_id, corner + gap, corner + quarter - gap]
		result.append([Transform3D(Basis(Vector3.UP, random.randf() * TAU), point), seed_value, bounds])
	return result


## O cão da casa: ao lado da célula da entrada, encostado na frente, olhando para a rua.
func _dog(record: BuildingRecord, def: BuildingDef) -> Array:
	var grid := _simulation.world.island(record.island_id)
	var entrance := Footprint.entrance_cell(record.origin, def.size, record.rotation)
	var front := Footprint.front_direction(record.rotation)
	var out := Vector3(front.x, 0.0, front.y)
	var side := out.cross(Vector3.UP)
	var cell_size := _simulation.config.cell_size_m
	var point := grid.surface_world(entrance) - out * cell_size * 0.3 + side * DOG_SIDE_M
	# anda só ao longo da frente: a faixa vai de um lado ao outro, sem largura para fora
	var a := point - side * DOG_PACE_M
	var b := point + side * DOG_PACE_M
	# o modelo olha para −Z: o giro leva o −Z para fora da casa (e é para lá que ele olha descansando)
	var facing := Basis.looking_at(out, Vector3.UP)
	var bounds := [record.island_id, Vector2(minf(a.x, b.x), minf(a.z, b.z)), Vector2(maxf(a.x, b.x), maxf(a.z, b.z)),
			facing.get_euler().y]
	return [Transform3D(facing, point), hash([record.id, &"dog"]), bounds]


func _apply_range() -> void:
	for layer: MultiMeshInstance3D in _layers.values():
		layer.visibility_range_end = _range_m
		layer.visibility_range_end_margin = _range_m * 0.1
		layer.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


## O VatModel do bicho (null sem o arquivo: rode tools/bake_animals.gd).
static func model(animal: StringName) -> VatModel:
	if not _models.has(animal):
		var path := MODEL_DIR + "animal_%s.res" % animal
		_models[animal] = load(path) as VatModel if ResourceLoader.exists(path) else null
	return _models[animal]


## Escala que leva o comprimento do modelo ao LENGTH_M do bicho (pela malha de repouso, sem a folga
## da caixa de recorte).
static func scale_of(animal: StringName) -> float:
	if not _scales.has(animal):
		var vat := model(animal)
		var length := 1.0
		if vat != null:
			var vertices: PackedVector3Array = vat.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var low := INF
			var high := -INF
			for vertex: Vector3 in vertices:
				low = minf(low, vertex.z)
				high = maxf(high, vertex.z)
			length = maxf(high - low, 0.001)
		var target: float = LENGTH_M.get(animal, 1.0)
		_scales[animal] = target / length
	return _scales[animal]


## Uma camada de bichos (MultiMesh com o shader de VAT); null sem o modelo.
static func layer(animal: StringName) -> MultiMeshInstance3D:
	var vat := model(animal)
	if vat == null:
		return null
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"vat_positions", vat.positions)
	material.set_shader_parameter(&"vat_normals", vat.normals)
	var clips := vat.clip_uniforms()
	while clips.size() < 4:
		clips.append(Vector4.ZERO)
	material.set_shader_parameter(&"clips", clips)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = vat.mesh
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	return instance


## Põe o bicho i da camada em where (a base no chão, o −Z para a frente), na animação clip, com o tom e a
## fase sorteados por seed_value.
static func place(multimesh: MultiMesh, index: int, animal: StringName, where: Transform3D, seed_value: int,
		clip: StringName) -> void:
	var vat := model(animal)
	var scaled := Transform3D(where.basis.scaled_local(Vector3.ONE * scale_of(animal)), where.origin)
	multimesh.set_instance_transform(index, scaled)
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var shade := 1.0 - random.randf() * SHADE_VARIATION
	multimesh.set_instance_color(index, Color(shade, shade, shade))
	multimesh.set_instance_custom_data(index, Color(maxi(vat.clip_index(String(clip)), 0), random.randf(),
			random.randf_range(0.85, 1.15), 0.0))
