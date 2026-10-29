class_name ChimneySmokeView
extends Node3D
## Fase 100: a fumacinha das chaminés das casas. Cada casa com chaminé (BuildingKit.chimney_top) solta PUFFS baforadas
## desencontradas, todas num MultiMesh só; o shader (shaders/chimney_smoke.gdshader) as faz subir, crescer e deitar com o
## vento na placa de vídeo. Só sai fumaça de casa com morador, e mais de manhã e à noite (o fogão aceso). Só lê o estado;
## nenhuma regra aqui.

const SHADER := preload("res://shaders/chimney_smoke.gdshader")
const PUFFS := 7
const REFRESH_SECONDS := 1.0
## A fumaça de fundo durante o dia e os picos do fogão (hora do meio e meia largura, em horas).
const BASE_AMOUNT := 0.35
const MORNING_HOUR := 7.0
const MORNING_HALF_H := 2.0
const EVENING_HOUR := 19.0
const EVENING_HALF_H := 2.5
## O quanto a fumaça escurece no meio da noite (sem luz própria).
const NIGHT_BRIGHTNESS := 0.22
const FADE_BEGIN_M := 160.0
const FADE_END_M := 260.0

var _simulation: Simulation
var _instance := MultiMeshInstance3D.new()
var _material := ShaderMaterial.new()
## Casa → a boca da chaminé no mundo e se está acesa (com morador).
var _tops: Dictionary[int, Vector3] = {}
var _lit: Dictionary[int, bool] = {}
var _order: Array[int] = []
var _dirty := true
var _refresh_left: float = 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_material.shader = SHADER
	_material.set_shader_parameter(&"fade_begin_m", FADE_BEGIN_M)
	_material.set_shader_parameter(&"fade_end_m", FADE_END_M)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	_instance.multimesh = multimesh
	_instance.material_override = _material
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_instance.name = "Puffs"
	add_child(_instance)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	var scale := preset.visibility_scale if preset != null else 1.0
	_material.set_shader_parameter(&"fade_begin_m", FADE_BEGIN_M * scale)
	_material.set_shader_parameter(&"fade_end_m", FADE_END_M * scale)
	# sem partículas no nível (o baixo), sem fumaça
	_instance.visible = preset == null or preset.particles_ratio > 0.0


func chimney_count() -> int:
	return _tops.size()


func lit_count() -> int:
	return _lit.values().count(true)


## A boca da chaminé da casa no mundo, ou null.
func top_of(building_id: int) -> Variant:
	return _tops.get(building_id)


## Quanto da fumaça aparece na hora: o fundo do dia e os picos da manhã e da noite (liso, sem degrau na meia-noite).
static func amount_at(hour: float) -> float:
	var peak := maxf(_bump(hour, MORNING_HOUR, MORNING_HALF_H), _bump(hour, EVENING_HOUR, EVENING_HALF_H))
	return BASE_AMOUNT + (1.0 - BASE_AMOUNT) * peak


static func _bump(hour: float, center: float, half: float) -> float:
	var apart := absf(fposmod(hour - center + 12.0, 24.0) - 12.0)
	return smoothstep(half, 0.0, apart)


## A boca da chaminé de uma casa no mundo (o mesmo assento e giro do modelo na BuildingView), ou null.
static func chimney_world(simulation: Simulation, record: BuildingRecord) -> Variant:
	if not record.is_house():
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	var top: Variant = BuildingKit.chimney_top(spec)
	if top == null:
		return null
	var def := simulation.def_of(record)
	var center := BuildingKit.seat(grid, Footprint.rect(record.origin, def.size, record.rotation))
	var place := Transform3D(Basis(Vector3.UP, -PI * 0.5 * posmod(record.rotation, 4)), center)
	var local: Vector3 = top
	return place * local


func rebuild() -> void:
	_tops.clear()
	_lit.clear()
	for building_id: int in _simulation.world.building_ids():
		var record := _simulation.world.building(building_id)
		var top: Variant = chimney_world(_simulation, record)
		if top != null:
			_tops[building_id] = top
			_lit[building_id] = record.residents > 0.0
	_write()
	_dirty = false


func _mark(_building_id: int) -> void:
	_dirty = true


func _write() -> void:
	_order = _tops.keys()
	var multimesh := _instance.multimesh
	multimesh.instance_count = _order.size() * PUFFS
	for i: int in _order.size():
		var building_id := _order[i]
		var seed := float(absi(hash(building_id)) % 1000) / 1000.0
		for k: int in PUFFS:
			var index := i * PUFFS + k
			multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, _tops[building_id]))
			multimesh.set_instance_custom_data(index, Color(float(k) / PUFFS + seed, seed, 1.0 if _lit[building_id] else 0.0, 0.0))
	# o MultiMesh cobre o arquipélago todo (a caixa calculada percorreria as instâncias)
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


func _refresh_lit() -> void:
	var multimesh := _instance.multimesh
	for i: int in _order.size():
		var building_id := _order[i]
		var record := _simulation.world.building(building_id)
		var lit := record != null and record.residents > 0.0
		if lit == _lit[building_id]:
			continue
		_lit[building_id] = lit
		for k: int in PUFFS:
			var data := multimesh.get_instance_custom_data(i * PUFFS + k)
			data.b = 1.0 if lit else 0.0
			multimesh.set_instance_custom_data(i * PUFFS + k, data)


func _process(delta: float) -> void:
	if _simulation == null:
		return
	if _dirty:
		rebuild()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh_lit()
	var hour := GameClock.clock.hour()
	_material.set_shader_parameter(&"amount", amount_at(hour))
	var night := DayClock.night_factor(_simulation.config, hour)
	_material.set_shader_parameter(&"brightness", lerpf(1.0, NIGHT_BRIGHTNESS, night))
