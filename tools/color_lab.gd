extends "res://tools/capture_phase255.gd"
## Laboratório de cor (Fase 255): a vila do roteiro da cor viva fotografada com várias combinações de luz, névoa e tom,
## lado a lado, para escolher a que entra no jogo. Só para comparar; nada aqui muda o jogo.
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/color_lab.tscn -- <pasta>

## Cada variante: nome → {propriedade: valor}. Chaves: fog (multiplica a névoa), tonemap ("agx", "aces", "filmic"),
## agx_contrast, white, saturation, contrast, brightness, ambient (Color), ambient_energy, sky_share, sun_energy (multiplica),
## sun_color (Color), ssao, leaf_fill (a luz própria das folhas, Fase 256), grass_grade, grass_saturation e dry_strength (a grama do terreno).
const WARM_HOUSES := {&"peasants": Color(0.78, 0.64, 0.42), &"workers": Color(0.7, 0.36, 0.26), &"artisans": Color(0.76, 0.56, 0.42),
		&"engineers": Color(0.84, 0.74, 0.56), &"investors": Color(0.93, 0.87, 0.73)}
## As vistas de cada variante: [nome, hora].
const SHOTS: Array = [["dia", 10.5], ["cinco", 17.0], ["tarde", 18.0], ["manha", 6.25]]
const VARIANTS: Array = [
	["0_dourado_175", {"sun_horizon": Color(1.0, 0.72, 0.45), "low_exposure": 1.75}],
	["1_dourado_220", {"sun_horizon": Color(1.0, 0.72, 0.45), "low_exposure": 2.2}],
	["2_ouro_claro_220", {"sun_horizon": Color(1.0, 0.8, 0.55), "low_exposure": 2.2}],
	["3_ouro_claro_260", {"sun_horizon": Color(1.0, 0.8, 0.55), "low_exposure": 2.6}],
]


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	game.weather.set_process(false)
	game.graphics.sun_exposure = false
	var environment := game.sky.environment()
	var sun := game.sky.sun()
	var base := {
		"fog": environment.fog_density, "volumetric": environment.volumetric_fog_density, "tonemap": environment.tonemap_mode,
		"agx_contrast": environment.tonemap_agx_contrast, "white": environment.tonemap_white,
		"ambient": environment.ambient_light_color, "ambient_energy": environment.ambient_light_energy,
		"sky_share": environment.ambient_light_sky_contribution, "sun_energy": sun.light_energy, "sun_color": sun.light_color,
		"ssao": environment.ssao_intensity, "exposure": environment.tonemap_exposure, "sky_fog": _sky_fog(game),
	}
	_terrain_materials = game.terrain_view.materials()
	for key: String in ["grass_grade", "grass_saturation", "dry_strength", "grass_tint", "grass_tint_mix", "sand_grade", "sand_tint", "sand_tint_mix"]:
		_terrain_base[key] = _terrain_materials[0].get_shader_parameter(key)
	_horizon_base = _dome_color()
	print("base ", base, " névoa do clima ", game.weather.sample.mist, " nuvens ", game.weather.sample.coverage)
	for variant: Array in VARIANTS:
		var name: String = variant[0]
		var settings: Dictionary = variant[1]
		_apply(environment, sun, base, settings)
		_apply_buildings(game, settings)
		var horizon: Color = settings.get("sun_horizon", _horizon_base)
		_set_horizon(game, horizon)
		for shot: Array in SHOTS:
			var label: String = shot[0]
			var hour: float = shot[1]
			_set_hour(hour)
			if hour < 8.0 or hour > 16.0:
				environment.tonemap_exposure = settings.get("low_exposure", base["exposure"])
			else:
				environment.tonemap_exposure = settings.get("exposure", base["exposure"])
			await _shot(game, name + "_" + label + ".png", points[0], 110.0, 0.6)
	get_tree().quit()


func _apply(environment: Environment, sun: DirectionalLight3D, base: Dictionary, settings: Dictionary) -> void:
	environment.tonemap_exposure = settings.get("exposure", base["exposure"])
	var base_sky_fog: float = base["sky_fog"]
	var sky_fog: float = settings.get("sky_fog", 1.0)
	_set_sky_fog(base_sky_fog * sky_fog)
	var fog: float = settings.get("fog", 1.0)
	var base_fog: float = base["fog"]
	var base_volumetric: float = base["volumetric"]
	environment.fog_density = base_fog * fog
	environment.volumetric_fog_density = base_volumetric * fog
	var tonemap: String = settings.get("tonemap", "agx")
	match tonemap:
		"aces":
			environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		"filmic":
			environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		_:
			environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_agx_contrast = settings.get("agx_contrast", base["agx_contrast"])
	environment.tonemap_white = settings.get("white", base["white"])
	var saturation: float = settings.get("saturation", 1.0)
	var contrast: float = settings.get("contrast", 1.0)
	var brightness: float = settings.get("brightness", 1.0)
	environment.adjustment_enabled = saturation != 1.0 or contrast != 1.0 or brightness != 1.0
	environment.adjustment_saturation = saturation
	environment.adjustment_contrast = contrast
	environment.adjustment_brightness = brightness
	environment.ambient_light_color = settings.get("ambient", base["ambient"])
	environment.ambient_light_energy = settings.get("ambient_energy", base["ambient_energy"])
	environment.ambient_light_sky_contribution = settings.get("sky_share", base["sky_share"])
	var base_sun: float = base["sun_energy"]
	var sun_factor: float = settings.get("sun_energy", 1.0)
	sun.light_energy = base_sun * sun_factor
	sun.light_color = settings.get("sun_color", base["sun_color"])
	environment.ssao_intensity = settings.get("ssao", base["ssao"])
	for material: ShaderMaterial in _terrain_materials:
		for key: String in ["grass_grade", "grass_saturation", "dry_strength", "grass_tint", "grass_tint_mix", "sand_grade", "sand_tint", "sand_tint_mix"]:
			var value: Variant = settings.get(key, _terrain_base[key])
			material.set_shader_parameter(key, value)
	var fill: float = settings.get("leaf_fill", TreeModel.LEAF_FILL)
	for mesh: ArrayMesh in TreeModel._cache.values():
		for surface: int in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as ShaderMaterial
			if material != null:
				material.set_shader_parameter(&"leaf_fill", fill)


var _dome: Node
var _terrain_materials: Array[ShaderMaterial] = []
var _terrain_base: Dictionary = {}


## A névoa do domo do Sky3D (a do ar, desenhada por cima de tudo).
func _sky_fog(game: GameScreen) -> float:
	var sky3d := game.sky.get_child(0)
	var dome: Variant = sky3d.get(&"sky")
	if dome is Node:
		_dome = dome
		var density: float = _dome.get(&"fog_density")
		return density
	return 0.0


func _set_sky_fog(density: float) -> void:
	if _dome != null:
		_dome.set(&"fog_density", density)


var _kit_base: Dictionary = {}
var _house_base: Dictionary = {}


## Os parâmetros do material dos prédios ("kit") e as cores das casas por classe ("houses"); com as cores, refaz os prédios.
func _apply_buildings(game: GameScreen, settings: Dictionary) -> void:
	var kit := BuildingMaterials.kit()
	var params: Dictionary = settings.get("kit", {})
	for key: String in params:
		if not _kit_base.has(key):
			_kit_base[key] = kit.get_shader_parameter(key)
	for key: String in _kit_base:
		kit.set_shader_parameter(key, params.get(key, _kit_base[key]))
	var houses: Dictionary = settings.get("houses", {})
	var changed := false
	for tier_id: StringName in houses:
		var tier := game.simulation.data.tier(tier_id)
		if not _house_base.has(tier_id):
			_house_base[tier_id] = tier.house_color
		tier.house_color = houses[tier_id]
		changed = true
	for tier_id: StringName in _house_base:
		if not houses.has(tier_id):
			game.simulation.data.tier(tier_id).house_color = _house_base[tier_id]
			changed = true
	if changed:
		game.building_view.rebuild()


var _horizon_base := Color.WHITE


## A cor do sol perto do horizonte no domo do Sky3D (o Sky3D a mistura com a do alto pela altura do sol).
func _dome_color() -> Color:
	if _dome == null:
		return Color.WHITE
	var color: Color = _dome.get(&"sun_horizon_light_color")
	return color


func _set_horizon(_game: GameScreen, color: Color) -> void:
	if _dome != null:
		_dome.set(&"sun_horizon_light_color", color)
