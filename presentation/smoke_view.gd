class_name SmokeView
extends Node3D
## Chaminés das fábricas (seção 11, Fase 9): cada prédio com fumaça (BuildingDef.smoke) ganha uma
## chaminé de tijolo e um GPUParticles3D em cima dela, que solta vapor claro, fumaça ou fumaça
## pesada só enquanto o prédio produz. A fumaça pesada deixa fuligem no chão em volta (Decal). O
## nível gráfico escolhe quantas partículas, até onde elas aparecem e se há fuligem. Desde a Fase 22,
## a fumaça deita para onde o vento do WeatherView sopra (sobe reta com o ar parado). Só lê o estado;
## nenhuma regra aqui.

const REFRESH_SECONDS := 0.5
## Chaminé: lado e quanto passa acima do telhado.
const STACK_SIDE_M := 1.1
const STACK_ABOVE_M := 3.0
## Partículas por chaminé no nível mais alto, por tipo (vapor, fumaça, pesada).
const AMOUNTS: Array[int] = [0, 10, 16, 28]
const LIFETIMES: Array[float] = [0.0, 3.0, 5.0, 7.0]
const COLORS: Array[Color] = [Color.WHITE, Color(0.92, 0.92, 0.9, 0.5), Color(0.45, 0.43, 0.42, 0.55), Color(0.16, 0.15, 0.15, 0.7)]
const SIZES: Array[float] = [0.0, 1.6, 2.2, 3.2]
## Empuxo para cima da fumaça e o do vento cheio no plano (m/s²).
const RISE_M_S2 := 0.35
const WIND_PUSH_M_S2 := 1.8

var _simulation: Simulation
var _cell_size: float
var _plumes: Dictionary[int, GPUParticles3D] = {}
var _stacks: Dictionary[int, Node3D] = {}
var _soot: Dictionary[int, Decal] = {}
var _ratio: float = 1.0
var _range_m: float = 450.0
var _decals: bool = true
var _refresh_left: float = 0.0
var _process_materials: Array[ParticleProcessMaterial] = []
var _draw_meshes: Array[QuadMesh] = []
var _soot_texture: Texture2D
## De onde vem o vento; sem ele, a fumaça sobe reta.
var weather: WeatherView


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	for kind: int in AMOUNTS.size():
		_process_materials.append(_process_material(kind))
		_draw_meshes.append(_draw_mesh(kind))
	_soot_texture = _make_soot_texture()
	EventBus.building_placed.connect(_add)
	EventBus.building_removed.connect(_remove)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_ratio = preset.particles_ratio
	_range_m = _simulation.config.smoke_visibility_range_m * preset.visibility_scale
	_decals = preset.decals
	rebuild()


func rebuild() -> void:
	for building_id: int in _plumes.keys():
		_remove(building_id)
	for building_id: int in _simulation.world.building_ids():
		_add(building_id)
	refresh()


func plume_count() -> int:
	return _plumes.size()


func emitting_count() -> int:
	return _plumes.values().filter(func(plume: GPUParticles3D) -> bool: return plume.emitting).size()


func soot_count() -> int:
	return _soot.size()


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()


## Liga a fumaça de quem está produzindo agora e deita a fumaça no vento.
func refresh() -> void:
	if weather != null:
		var push := drift(weather.sample.wind_direction, weather.sample.wind)
		for material: ParticleProcessMaterial in _process_materials:
			material.gravity = push
	for building_id: int in _plumes:
		var record := _simulation.world.building(building_id)
		_plumes[building_id].emitting = record != null and record.state == BuildingRecord.State.PRODUCING and not record.paused


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record == null or _plumes.has(building_id):
		return
	var def := _simulation.def_of(record)
	if def.smoke == BuildingDef.Smoke.NONE:
		return
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	# a chaminé fica num canto de trás do telhado
	var back := -Footprint.front_direction(record.rotation)
	var side := Vector2(back.y, -back.x)
	var offset := (Vector2(back) * 0.3 + side * 0.3) * Vector2(area.size) * _cell_size
	var top := center + Vector3(offset.x, def.height_m + STACK_ABOVE_M, offset.y)
	var stack := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(STACK_SIDE_M, STACK_ABOVE_M + 1.0, STACK_SIDE_M)
	stack.mesh = box
	stack.material_override = BuildingMaterials.walls()
	BuildingMaterials.dress(stack, BuildingMaterials.Wall.BRICK, Color(0.55, 0.32, 0.25), center.y)
	stack.position = top - Vector3(0.0, (STACK_ABOVE_M + 1.0) * 0.5, 0.0)
	stack.visibility_range_end = _range_m
	add_child(stack)
	_stacks[building_id] = stack
	var amount := roundi(AMOUNTS[def.smoke] * _ratio)
	if amount > 0:
		var plume := GPUParticles3D.new()
		plume.amount = amount
		plume.lifetime = LIFETIMES[def.smoke]
		plume.process_material = _process_materials[def.smoke]
		plume.draw_pass_1 = _draw_meshes[def.smoke]
		plume.position = top + Vector3(0.0, 0.3, 0.0)
		plume.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 40, 24))
		plume.visibility_range_end = _range_m
		plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plume.emitting = false
		add_child(plume)
		_plumes[building_id] = plume
	if def.smoke == BuildingDef.Smoke.HEAVY and _decals:
		var decal := Decal.new()
		var reach := maxf(float(def.pollution_radius_cells), 6.0) * _cell_size
		decal.size = Vector3(reach, 12.0, reach)
		decal.texture_albedo = _soot_texture
		decal.modulate = Color(1.0, 1.0, 1.0, _simulation.config.soot_decal_alpha)
		decal.position = center + Vector3(0.0, 2.0, 0.0)
		decal.distance_fade_enabled = true
		decal.distance_fade_begin = _range_m * 0.8
		decal.distance_fade_length = _range_m * 0.2
		add_child(decal)
		_soot[building_id] = decal


func _remove(building_id: int) -> void:
	for nodes: Dictionary in [_plumes, _stacks, _soot]:
		if nodes.has(building_id):
			var node: Node = nodes[building_id]
			node.queue_free()
			nodes.erase(building_id)


## Também usado pela fumaça da locomotiva (TrainView, Fase 76).
static func _process_material(kind: int) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = 12.0
	material.initial_velocity_min = 1.2
	material.initial_velocity_max = 2.2
	material.gravity = drift(Vector2.RIGHT, 0.0)
	material.damping_min = 0.2
	material.damping_max = 0.4
	material.scale_min = 0.6
	material.scale_max = 1.0
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 0.4))
	growth.add_point(Vector2(1.0, 2.6))
	var scale_curve := CurveTexture.new()
	scale_curve.curve = growth
	material.scale_curve = scale_curve
	var fade := Gradient.new()
	var color: Color = COLORS[kind]
	fade.set_color(0, Color(color, 0.0))
	fade.set_color(1, Color(color, 0.0))
	fade.add_point(0.12, color)
	fade.add_point(0.6, Color(color, color.a * 0.6))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	material.color_ramp = ramp
	return material


## Aceleração da fumaça: sobe e deita para onde o vento sopra, mais quanto mais forte.
static func drift(direction: Vector2, strength: float) -> Vector3:
	return Vector3(direction.x * WIND_PUSH_M_S2 * strength, RISE_M_S2, direction.y * WIND_PUSH_M_S2 * strength)


static func _draw_mesh(kind: int) -> QuadMesh:
	var quad := QuadMesh.new()
	var side: float = SIZES[kind]
	quad.size = Vector2(side, side)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if kind == BuildingDef.Smoke.STEAM else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _puff_texture()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.proximity_fade_enabled = true
	material.proximity_fade_distance = 1.5
	quad.material = material
	return quad


## Bolota macia (gradiente radial) para cada partícula.
static func _puff_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 64
	texture.height = 64
	return texture


## Fuligem: mancha escura que some para a borda, com um pouco de ruído.
static func _make_soot_texture() -> Texture2D:
	var size := 128
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.06
	noise.seed = 1840
	for y: int in size:
		for x: int in size:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / size * 2.0 - Vector2.ONE
			var falloff := clampf(1.0 - p.length(), 0.0, 1.0)
			var grain := noise.get_noise_2d(x, y) * 0.5 + 0.5
			image.set_pixel(x, y, Color(0.05, 0.045, 0.04, clampf(falloff * falloff * (0.55 + grain * 0.6), 0.0, 1.0)))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
