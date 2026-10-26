class_name GraphicsQuality
extends Node
## Aplica o nível gráfico escolhido nas opções (Settings.preset()) ao que se vê: efeitos do
## ambiente (SSAO, SSIL, glow, neblina volumétrica), sombra do sol, profundidade de campo da
## câmera, pedestres, luzes de área, nuvens e partículas. A janela (antisserrilhado, FSR, LOD, atlas de sombras)
## fica com o Settings.apply(). Refaz tudo quando as opções mudam.

var preset: GraphicsPresetDef

var _config: GameConfig
var _sky: SkyAdapter
var _camera: StrategyCamera
var _crowd: Crowd
var _windows: WindowLightsView
## Quem recebe a fração de partículas e se mostra fuligem: nós com set_quality(preset).
var _effects: Array[Node] = []
var _attributes := CameraAttributesPractical.new()


func setup(config: GameConfig, sky: SkyAdapter, camera: StrategyCamera, crowd: Crowd, windows: WindowLightsView) -> void:
	_config = config
	_sky = sky
	_camera = camera
	_crowd = crowd
	_windows = windows
	if _camera != null:
		_camera.camera.attributes = _attributes
	EventBus.settings_changed.connect(apply_current)
	apply_current()


## Efeito que acompanha o nível (fumaça, chuva, nuvens): recebe set_quality(preset) agora e a cada troca.
func add_effect(effect: Node) -> void:
	_effects.append(effect)
	if preset != null:
		effect.call(&"set_quality", preset)


func apply_current() -> void:
	apply(Settings.preset())


func apply(chosen: GraphicsPresetDef) -> void:
	preset = chosen
	if _sky != null:
		apply_to_environment(_sky.environment(), chosen, _config, Settings.period_look)
		var sun := _sky.sun()
		if sun != null:
			sun.directional_shadow_max_distance = chosen.shadow_distance_m
			# Fase 37: sol com tamanho de verdade liga a sombra suave de contato (PCSS), só no ultra
			sun.light_angular_distance = chosen.sun_angular_distance_deg
	# a meia resolução do SSR é global no RenderingServer (não do Environment)
	RenderingServer.environment_set_ssr_half_size(chosen.ssr_half_size)
	if _crowd != null:
		_crowd.pedestrian_ratio = chosen.pedestrian_ratio
		_crowd.mark_structure_changed()
	if _windows != null:
		_windows.area_light_limit = chosen.area_lights
	for effect: Node in _effects:
		if is_instance_valid(effect):
			effect.call(&"set_quality", chosen)
	_update_depth_of_field()


## Os efeitos do ambiente de um nível (estático para os testes). period: a "Cor de época" (Fase 37), o LUT e o AgX
## ajustado; desligada, o Environment volta ao de antes.
static func apply_to_environment(environment: Environment, chosen: GraphicsPresetDef, config: GameConfig,
		period: bool = false) -> void:
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.ssr_enabled = chosen.ssr
	environment.adjustment_enabled = period
	environment.adjustment_color_correction = PeriodGrade.texture() if period else null
	var defaults := _environment_defaults()
	environment.tonemap_agx_white = config.period_agx_white if period else defaults.tonemap_agx_white
	environment.tonemap_agx_contrast = config.period_agx_contrast if period else defaults.tonemap_agx_contrast
	environment.ssao_enabled = chosen.ssao
	environment.ssao_intensity = config.ssao_intensity
	environment.ssil_enabled = chosen.ssil
	environment.glow_enabled = chosen.glow
	environment.glow_intensity = config.glow_intensity
	environment.glow_bloom = config.glow_bloom
	environment.glow_hdr_threshold = config.glow_hdr_threshold
	environment.volumetric_fog_enabled = chosen.volumetric_fog
	environment.volumetric_fog_density = config.volumetric_fog_density
	environment.volumetric_fog_length = config.volumetric_fog_length_m


static var _defaults: Environment


## Um Environment novo, para voltar aos valores do motor quando a cor de época desliga.
static func _environment_defaults() -> Environment:
	if _defaults == null:
		_defaults = Environment.new()
	return _defaults


func _process(_delta: float) -> void:
	_update_depth_of_field()


## Efeito miniatura (tilt-shift): de perto, o que fica longe e o que fica muito perto da câmera
## desfocam; de longe, nada desfoca (a visão geral precisa ser nítida).
func _update_depth_of_field() -> void:
	if _camera == null or preset == null:
		return
	var distance := _camera.rig.distance
	var on := preset.depth_of_field and distance <= _config.tilt_shift_max_distance_m
	_attributes.dof_blur_far_enabled = on
	_attributes.dof_blur_near_enabled = on
	if on:
		_attributes.dof_blur_far_distance = distance * _config.tilt_shift_far_factor
		_attributes.dof_blur_far_transition = distance * _config.tilt_shift_far_factor
		_attributes.dof_blur_near_distance = distance * _config.tilt_shift_near_factor
		_attributes.dof_blur_near_transition = distance * _config.tilt_shift_near_factor * 0.5
		_attributes.dof_blur_amount = _config.tilt_shift_amount
