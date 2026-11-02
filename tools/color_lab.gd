extends "res://tools/capture_phase255.gd"
## Laboratório de cor (Fase 255): a vila do roteiro da cor viva fotografada com várias combinações de luz, névoa e tom,
## lado a lado, para escolher a que entra no jogo. Só para comparar; nada aqui muda o jogo.
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/color_lab.tscn -- <pasta>

## Cada variante: nome → {propriedade: valor}. Chaves: fog (multiplica a névoa), tonemap ("agx", "aces", "filmic"),
## agx_contrast, white, saturation, contrast, brightness, ambient (Color), ambient_energy, sky_share, sun_energy (multiplica),
## sun_color (Color), ssao, leaf_fill (a luz própria das folhas, Fase 256).
const VARIANTS: Array = [
	["0_folha0", {"leaf_fill": 0.0}],
	["1_folha22", {"leaf_fill": 0.22}],
	["2_folha35", {"leaf_fill": 0.35}],
	["3_folha22_ssao1", {"leaf_fill": 0.22, "ssao": 1.0}],
]


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	game.weather.set_process(false)
	var environment := game.sky.environment()
	var sun := game.sky.sun()
	var base := {
		"fog": environment.fog_density, "volumetric": environment.volumetric_fog_density, "tonemap": environment.tonemap_mode,
		"agx_contrast": environment.tonemap_agx_contrast, "white": environment.tonemap_white,
		"ambient": environment.ambient_light_color, "ambient_energy": environment.ambient_light_energy,
		"sky_share": environment.ambient_light_sky_contribution, "sun_energy": sun.light_energy, "sun_color": sun.light_color,
		"ssao": environment.ssao_intensity, "exposure": environment.tonemap_exposure, "sky_fog": _sky_fog(game),
	}
	print("base ", base, " névoa do clima ", game.weather.sample.mist, " nuvens ", game.weather.sample.coverage)
	for variant: Array in VARIANTS:
		var name: String = variant[0]
		var settings: Dictionary = variant[1]
		_apply(environment, sun, base, settings)
		await _shot(game, name + "_vila.png", points[0], 110.0, 0.6)
		await _shot(game, name + "_perto.png", points[0], 42.0, 0.6)
		await _shot(game, name + "_ilha.png", points[3], 520.0, 0.3)
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
	var fill: float = settings.get("leaf_fill", TreeModel.LEAF_FILL)
	for mesh: ArrayMesh in TreeModel._cache.values():
		for surface: int in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as ShaderMaterial
			if material != null:
				material.set_shader_parameter(&"leaf_fill", fill)


var _dome: Node


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
