class_name WeatherView
extends Node3D
## O clima na tela (Fase 9): lê o WeatherCycle na hora do GameClock e repassa às nuvens (cobertura),
## à neblina (de distância e volumétrica), ao chão molhado (uniforme global wetness, que os
## shaders de prédio, estrada e terreno usam) e à chuva (partículas em volta do ponto que a câmera
## olha). Nenhuma regra de jogo aqui.

var sample := WeatherCycle.Sample.new()

var _config: GameConfig
var _simulation: Simulation
var _sky: SkyAdapter
var _clouds: CloudsAdapter
var _camera: StrategyCamera
var _rain := GPUParticles3D.new()
var _particles_ratio: float = 1.0
var _base_fog: float = 0.0
var _base_volumetric: float = 0.0
## Hora fixa para capturas e testes (negativa = a do GameClock).
var hours_override: float = -1.0


func setup(config: GameConfig, simulation: Simulation, sky: SkyAdapter, clouds: CloudsAdapter, camera: StrategyCamera) -> void:
	_config = config
	_simulation = simulation
	_sky = sky
	_clouds = clouds
	_camera = camera
	var environment := sky.environment()
	_base_fog = environment.fog_density
	_base_volumetric = config.volumetric_fog_density
	_build_rain()
	refresh()


func set_quality(preset: GraphicsPresetDef) -> void:
	_particles_ratio = preset.particles_ratio
	_base_volumetric = _config.volumetric_fog_density
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if _config == null:
		return
	var hours := hours_override if hours_override >= 0.0 else GameClock.clock.total_hours()
	sample = WeatherCycle.sample(_simulation.world.seed, hours, _config)
	if _clouds != null:
		_clouds.set_coverage(sample.coverage)
	var environment := _sky.environment()
	var haze := sample.mist * _config.weather_mist_fog_density + sample.rain * _config.weather_rain_fog_density
	environment.fog_density = _base_fog + haze
	environment.volumetric_fog_density = _base_volumetric + haze * 2.0
	RenderingServer.global_shader_parameter_set(&"wetness", sample.wetness)
	var drops := roundi(_config.rain_max_drops * _particles_ratio * sample.rain)
	_rain.emitting = drops > 0
	if drops > 0:
		if _rain.amount != drops:
			_rain.amount = drops
		var focus := _camera.rig.focus if _camera != null else Vector3.ZERO
		_rain.global_position = Vector3(focus.x, focus.y + _config.rain_box_m.y * 0.6, focus.z)


func rain_drops() -> int:
	return _rain.amount if _rain.emitting else 0


func _build_rain() -> void:
	_rain.name = "Rain"
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = _config.rain_box_m * Vector3(0.5, 0.1, 0.5)
	process.direction = Vector3(0.15, -1.0, 0.05)
	process.spread = 3.0
	process.initial_velocity_min = _config.rain_fall_speed_m_s
	process.initial_velocity_max = _config.rain_fall_speed_m_s * 1.15
	process.gravity = Vector3(0.0, -9.8, 0.0)
	_rain.process_material = process
	var drop := BoxMesh.new()
	drop.size = Vector3(0.02, 0.7, 0.02)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.75, 0.8, 0.88, 0.45)
	drop.material = material
	_rain.draw_pass_1 = drop
	_rain.lifetime = _config.rain_box_m.y / _config.rain_fall_speed_m_s
	_rain.amount = 1
	_rain.emitting = false
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rain.visibility_aabb = AABB(-_config.rain_box_m, _config.rain_box_m * 2.0)
	add_child(_rain)
