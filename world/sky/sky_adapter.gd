class_name SkyAdapter
extends Node3D
## Adaptador do céu (seção 13): a única peça do jogo que conhece o Sky3D. Recebe a hora do
## GameClock e a repassa ao Sky3D, cujo relógio próprio fica desligado. Sem o addon, ou com
## use_sky3d falso (testes que não testam o céu), um sol e um céu simples giram com a hora.
## O addon é carregado pelo caminho e usado só por set/get/call: trocá-lo mexe só aqui.

const SKY3D_SCRIPT := "res://addons/sky_3d/src/Sky3D.gd"
## Só repassa a hora ao Sky3D quando ela muda pelo menos isto (15 s de jogo): cada atualização
## refaz as contas do sol e da lua em GDScript.
const MIN_HOUR_STEP := 0.25 / 60.0
## Céu simples (sem Sky3D): cores de dia e de noite.
const DAY_TOP := Color(0.42, 0.58, 0.78)
const DAY_HORIZON := Color(0.8, 0.82, 0.8)
const NIGHT_TOP := Color(0.02, 0.03, 0.07)
const NIGHT_HORIZON := Color(0.06, 0.07, 0.11)
const SUN_ENERGY := 1.1
const MOON_ENERGY := 0.12
## O reflexo do céu muda com a hora: refazê-lo inteiro a cada mudança custava ~150 ms por quadro
## no Vulkan por software. Incremental espalha a conta por vários quadros, num cubo pequeno.
const RADIANCE_SIZE := Sky.RADIANCE_SIZE_128

var _config: GameConfig
var _sky3d: WorldEnvironment
var _environment: Environment
var _sun: DirectionalLight3D
var _simple_sky: ProceduralSkyMaterial
## Última hora repassada ao céu; negativa enquanto nenhuma foi.
var _hour: float = -1.0


func setup(config: GameConfig, use_sky3d: bool = true) -> void:
	_config = config
	if use_sky3d and ResourceLoader.exists(SKY3D_SCRIPT):
		_create_sky3d()
	else:
		_create_simple_sky()


func uses_sky3d() -> bool:
	return _sky3d != null


func sun() -> DirectionalLight3D:
	if _sky3d != null:
		var light: Variant = _sky3d.get(&"sun")
		return light if light is DirectionalLight3D else null
	return _sun


func environment() -> Environment:
	return _sky3d.environment if _sky3d != null else _environment


## Hora mostrada pelo céu agora (0 a 24).
func shown_hour() -> float:
	if _sky3d != null:
		var time: Variant = _sky3d.get(&"current_time")
		return time if time is float else -1.0
	return _hour


## Hora do jogo, de 0 a 24. Chamada a cada quadro; o céu só se refaz quando ela anda.
func set_hour(hour: float) -> void:
	var h := fposmod(hour, 24.0)
	var step := fposmod(h - _hour, 24.0)
	if _hour >= 0.0 and minf(step, 24.0 - step) < MIN_HOUR_STEP:
		return
	_hour = h
	if _sky3d != null:
		_sky3d.set(&"current_time", minf(h, 23.9998))
	else:
		_update_simple_sky(h)


func _create_sky3d() -> void:
	var script := load(SKY3D_SCRIPT) as GDScript
	var created: Variant = script.new()
	if not created is WorldEnvironment:
		_create_simple_sky()
		return
	_sky3d = created
	_sky3d.name = "Sky3D"
	add_child(_sky3d)
	_sky3d.set(&"game_time_enabled", false)
	var tod: Variant = _sky3d.get(&"tod")
	if tod is Node:
		var time_of_day: Node = tod
		time_of_day.set(&"latitude", deg_to_rad(_config.sky_latitude_deg))
		time_of_day.set(&"longitude", 0.0)
		time_of_day.set(&"utc", 0.0)
		time_of_day.set(&"year", _config.sky_year)
		time_of_day.set(&"month", _config.sky_month)
		time_of_day.set(&"day", _config.sky_day)
	_sky3d.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	_sky3d.environment.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	_sky3d.environment.sky.radiance_size = RADIANCE_SIZE
	_sky3d.environment.ambient_light_color = _config.ambient_fill_color
	_sky3d.set(&"ambient_energy", _config.ambient_fill_energy)
	_sky3d.set(&"sky_contribution", _config.sky_ambient_share_day)
	_sky3d.set(&"night_sky_contribution", _config.sky_ambient_share_night)
	_sky3d.set(&"moon_energy", _config.moon_light_energy)
	var dome: Variant = _sky3d.get(&"sky")
	if dome is Node:
		var sky_dome: Node = dome
		sky_dome.set(&"fog_density", _config.sky_fog_density)
		sky_dome.set(&"fog_start", _config.sky_fog_start_m)
	var sun_light := sun()
	if sun_light != null:
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_max_distance = _config.sun_shadow_distance_m
	var moon: Variant = _sky3d.get(&"moon")
	if moon is DirectionalLight3D:
		# duas sombras direcionais custam caro; a lua ilumina sem sombra
		var moon_light: DirectionalLight3D = moon
		moon_light.shadow_enabled = false


func _create_simple_sky() -> void:
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.0, 0.95, 0.86)
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = _config.sun_shadow_distance_m
	add_child(_sun)
	_simple_sky = ProceduralSkyMaterial.new()
	_simple_sky.ground_horizon_color = DAY_HORIZON
	var sky := Sky.new()
	sky.sky_material = _simple_sky
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky.radiance_size = RADIANCE_SIZE
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	_environment.fog_enabled = true
	_environment.fog_light_color = Color(0.78, 0.8, 0.82)
	_environment.fog_density = 0.00015
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)
	_update_simple_sky(_config.day_start_hour)


## Sol num arco do nascer ao pôr do sol; de noite, luz fraca e azulada (a lua).
func _update_simple_sky(hour: float) -> void:
	var night := DayClock.night_factor(_config, hour)
	var day_span := _config.sunset_hour - _config.sunrise_hour
	var progress := clampf((hour - _config.sunrise_hour) / day_span, 0.0, 1.0)
	var elevation := lerpf(8.0, 60.0, sin(progress * PI)) if night < 1.0 else 50.0
	_sun.rotation_degrees = Vector3(-elevation, lerpf(-100.0, 100.0, progress), 0.0)
	_sun.light_energy = lerpf(SUN_ENERGY, MOON_ENERGY, night)
	_sun.light_color = Color(1.0, 0.95, 0.86).lerp(Color(0.6, 0.7, 1.0), night)
	_simple_sky.sky_top_color = DAY_TOP.lerp(NIGHT_TOP, night)
	_simple_sky.sky_horizon_color = DAY_HORIZON.lerp(NIGHT_HORIZON, night)
	_simple_sky.ground_horizon_color = _simple_sky.sky_horizon_color
