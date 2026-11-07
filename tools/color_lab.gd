extends "res://tools/capture_phase260.gd"
## Laboratório de cor (Fase 255): a vila do roteiro da cor viva fotografada com várias combinações de luz, névoa e tom,
## lado a lado, para escolher a que entra no jogo. Só para comparar; nada aqui muda o jogo.
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/color_lab.tscn -- <pasta>

## Cada variante: nome → {propriedade: valor}. Chaves: fog (multiplica a névoa), tonemap ("agx", "aces", "filmic"),
## agx_contrast, white, saturation, contrast, brightness, ambient (Color), ambient_energy, sky_share, sun_energy (multiplica),
## sun_color (Color), ssao, leaf_fill (a luz própria das folhas, Fase 256), grass_grade, grass_saturation e dry_strength (a grama do terreno).
const WARM_HOUSES := {&"peasants": Color(0.78, 0.64, 0.42), &"workers": Color(0.7, 0.36, 0.26), &"artisans": Color(0.76, 0.56, 0.42),
		&"engineers": Color(0.84, 0.74, 0.56), &"investors": Color(0.93, 0.87, 0.73)}
## As vistas de cada variante: [nome, hora, ponto (0 a vila, 1 os campos, 2 a praia, 3 o meio da ilha, 4 a falésia, 5 a praia
## tropical), distância, giro].
const SHOTS: Array = [["vila", 10.5, 0, 110.0, 0.6], ["perto", 10.5, 0, 42.0, 0.6]]
const VARIANTS: Array = [
	["0_sombra_atual", {"ssao": 1.6, "ambient_energy": 1.0}],
	["1_ssao_09", {"ssao": 0.9}],
	["2_ambiente_15", {"ambient_energy": 1.5}],
	["3_ssao_09_ambiente_15", {"ssao": 0.9, "ambient_energy": 1.5, "sky_share": 0.8}],
]


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	# as fazendas da vila em fases diferentes do ciclo (o trigo quase maduro, a batata no meio)
	for id: int in game.simulation.world.buildings:
		var farm := game.simulation.world.building(id)
		if farm.def_id == &"wheat_farm":
			farm.progress = 0.85
		elif farm.def_id == &"potato_farm":
			farm.progress = 0.6
	var main := game.simulation.world.island(Simulation.MAIN_ISLAND)
	points.append(main.cell_world(_find_cliff(main)))
	points.append(points[2])
	for island_id: int in game.simulation.world.islands.size():
		if game.simulation.world.is_tropical(island_id, game.simulation.data):
			var tropical := game.simulation.world.island(island_id)
			points[5] = tropical.cell_world(_find_beach(tropical))
			break
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
		"saturation": environment.adjustment_saturation,
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
		_apply_rock(game, settings)
		CropView.cover_max = settings.get("cover", CropView.COVER_MAX)
		var moon: float = settings.get("moon", GameConfig.get_default().moon_light_energy)
		game.sky.get_child(0).set(&"moon_energy", moon)
		game.crop_view.rebuild()
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
			var focus: int = shot[2]
			var distance: float = shot[3]
			var yaw: float = shot[4]
			await _shot(game, name + "_" + label + ".png", points[focus], distance, yaw)
	get_tree().quit()


## Põe a variante: só mexe no que alguma variante da lista mexe (o resto fica como o jogo deixou, inclusive a luz e o
## ambiente que o Sky3D refaz com a hora); o que uma variante não diz volta ao que era no começo.
func _apply(environment: Environment, sun: DirectionalLight3D, base: Dictionary, settings: Dictionary) -> void:
	var used := {}
	for variant: Array in VARIANTS:
		var keys: Dictionary = variant[1]
		for key: String in keys:
			used[key] = true
	if used.has("exposure"):
		environment.tonemap_exposure = settings.get("exposure", base["exposure"])
	if used.has("sky_fog"):
		var base_sky_fog: float = base["sky_fog"]
		var sky_fog: float = settings.get("sky_fog", 1.0)
		_set_sky_fog(base_sky_fog * sky_fog)
	if used.has("fog"):
		var fog: float = settings.get("fog", 1.0)
		var base_fog: float = base["fog"]
		var base_volumetric: float = base["volumetric"]
		environment.fog_density = base_fog * fog
		environment.volumetric_fog_density = base_volumetric * fog
	if used.has("tonemap"):
		var tonemap: String = settings.get("tonemap", "agx")
		match tonemap:
			"aces":
				environment.tonemap_mode = Environment.TONE_MAPPER_ACES
			"filmic":
				environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			_:
				environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	if used.has("agx_contrast"):
		environment.tonemap_agx_contrast = settings.get("agx_contrast", base["agx_contrast"])
	if used.has("white"):
		environment.tonemap_white = settings.get("white", base["white"])
	if used.has("saturation"):
		environment.adjustment_saturation = settings.get("saturation", base["saturation"])
	for pair: Array in [["ambient", "ambient_light_color"], ["ambient_energy", "ambient_light_energy"],
			["sky_share", "ambient_light_sky_contribution"], ["ssao", "ssao_intensity"]]:
		var key: String = pair[0]
		var property: StringName = pair[1]
		if used.has(key):
			environment.set(property, settings.get(key, base[key]))
	if used.has("sun_energy"):
		var base_sun: float = base["sun_energy"]
		var sun_factor: float = settings.get("sun_energy", 1.0)
		sun.light_energy = base_sun * sun_factor
	if used.has("sun_color"):
		sun.light_color = settings.get("sun_color", base["sun_color"])
	for material: ShaderMaterial in _terrain_materials:
		for key: String in _terrain_base:
			if used.has(key):
				material.set_shader_parameter(key, settings.get(key, _terrain_base[key]))
	if not used.has("leaf_fill"):
		return
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


var _stone_base: Dictionary = {}
var _rock_terrain_base: Dictionary = {}


## Os parâmetros da pedra ("stone": os materiais do shaders/sea_rock.gdshader na cena) e da rocha do terreno ("terrain").
func _apply_rock(game: GameScreen, settings: Dictionary) -> void:
	var stone: Dictionary = settings.get("stone", {})
	var materials: Array[ShaderMaterial] = []
	_rock_materials(game, materials)
	for key: String in stone:
		if not _stone_base.has(key) and not materials.is_empty():
			_stone_base[key] = materials[0].get_shader_parameter(key)
	for material: ShaderMaterial in materials:
		for key: String in _stone_base:
			material.set_shader_parameter(key, stone.get(key, _stone_base[key]))
	var terrain: Dictionary = settings.get("terrain", {})
	for key: String in terrain:
		if not _rock_terrain_base.has(key):
			_rock_terrain_base[key] = _terrain_materials[0].get_shader_parameter(key)
	for material: ShaderMaterial in _terrain_materials:
		for key: String in _rock_terrain_base:
			material.set_shader_parameter(key, terrain.get(key, _rock_terrain_base[key]))


func _rock_materials(node: Node, found: Array[ShaderMaterial]) -> void:
	var candidates: Array[Material] = []
	if node is GeometryInstance3D:
		candidates.append((node as GeometryInstance3D).material_override)
	var mesh: Mesh = null
	if node is MeshInstance3D:
		mesh = (node as MeshInstance3D).mesh
	elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
		mesh = (node as MultiMeshInstance3D).multimesh.mesh
	if mesh != null:
		for surface: int in mesh.get_surface_count():
			candidates.append(mesh.surface_get_material(surface))
	for material: Material in candidates:
		var shader_material := material as ShaderMaterial
		if shader_material != null and shader_material.shader != null \
				and shader_material.shader.resource_path == "res://shaders/sea_rock.gdshader" and shader_material not in found:
			found.append(shader_material)
	for child: Node in node.get_children():
		_rock_materials(child, found)
