class_name FireView
extends Node3D
## Incêndio na cidade (riscos): o prédio em chamas ganha labaredas, fumaça escura e uma luz laranja
## que tremula, do tamanho dele. Some quando o fogo apaga ou o prédio se perde. O nível gráfico
## escolhe quantas partículas. Só lê o estado; nenhuma regra aqui.

## Partículas no nível mais alto, por metro de lado do prédio.
const FLAMES_PER_M := 6.0
const SMOKE_PER_M := 3.0
const LIGHT_ENERGY := 4.0
## Brilho das labaredas acima de 1 (o glow do nível alto pega).
const FLAME_GLOW := Color(1.5, 0.75, 0.3)
const FLAME_COLOR := Color(1.0, 0.55, 0.15)

var _simulation: Simulation
var _cell_size: float
var _ratio: float = 1.0
var _nodes: Dictionary[int, Node3D] = {}
var _lights: Array[OmniLight3D] = []
var _time: float = 0.0
var _flame_material: ParticleProcessMaterial
var _smoke_material: ParticleProcessMaterial
var _flame_mesh: QuadMesh
var _smoke_mesh: QuadMesh


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	_flame_material = _process_material(Vector2(3.0, 5.5), 1.0, 2.0, _flame_ramp())
	_smoke_material = _process_material(Vector2(2.0, 3.5), 1.5, 4.5, _smoke_ramp())
	_flame_mesh = _mesh(2.6, true)
	_smoke_mesh = _mesh(4.5, false)
	EventBus.fire_started.connect(_add)
	EventBus.fire_ended.connect(func(building_id: int, _lost: bool) -> void: _remove(building_id))
	EventBus.building_removed.connect(_remove)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_ratio = preset.particles_ratio
	rebuild()


func rebuild() -> void:
	for building_id: int in _nodes.keys():
		_remove(building_id)
	for building_id: int in _simulation.world.risks_state.fires:
		_add(building_id)


func burning_count() -> int:
	return _nodes.size()


func _process(delta: float) -> void:
	_time += delta
	for index: int in _lights.size():
		var light := _lights[index]
		light.light_energy = LIGHT_ENERGY * (0.75 + 0.25 * sin(_time * 13.0 + index) * sin(_time * 7.3 + index * 2.0))


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record == null or _nodes.has(building_id):
		return
	var def := _simulation.def_of(record)
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var side_m := float(maxi(area.size.x, area.size.y)) * _cell_size
	var root := Node3D.new()
	root.position = center + Vector3(0.0, def.height_m * 0.85, 0.0)
	add_child(root)
	_nodes[building_id] = root
	var box := Vector3(area.size.x * _cell_size * 0.4, def.height_m * 0.3, area.size.y * _cell_size * 0.4)
	root.add_child(_particles(_flame_material, _flame_mesh, maxi(8, roundi(FLAMES_PER_M * side_m * _ratio)), 1.4, box))
	var smoke := _particles(_smoke_material, _smoke_mesh, maxi(6, roundi(SMOKE_PER_M * side_m * _ratio)), 6.0, box)
	smoke.position.y = def.height_m * 0.4
	root.add_child(smoke)
	var light := OmniLight3D.new()
	light.light_color = FLAME_COLOR
	light.light_energy = LIGHT_ENERGY
	light.omni_range = side_m * 1.6 + 8.0
	light.shadow_enabled = false
	root.add_child(light)
	_lights.append(light)


func _remove(building_id: int) -> void:
	if not _nodes.has(building_id):
		return
	var root := _nodes[building_id]
	for child: Node in root.get_children():
		if child is OmniLight3D:
			_lights.erase(child)
	root.queue_free()
	_nodes.erase(building_id)


func _particles(material: ParticleProcessMaterial, mesh: QuadMesh, amount: int, lifetime: float, box: Vector3) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	var process := material.duplicate() as ParticleProcessMaterial
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = box
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.visibility_aabb = AABB(Vector3(-20, -6, -20), Vector3(40, 50, 40))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


func _process_material(speed: Vector2, scale_min: float, scale_max: float, ramp: GradientTexture1D) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.1, 1.0, 0.05)
	material.spread = 15.0
	material.initial_velocity_min = speed.x
	material.initial_velocity_max = speed.y
	material.gravity = Vector3(0.4, 0.8, 0.2)
	material.scale_min = scale_min
	material.scale_max = scale_max
	material.color_ramp = ramp
	return material


func _flame_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.5, 0.0))
	gradient.set_color(1, Color(0.6, 0.1, 0.0, 0.0))
	gradient.add_point(0.1, Color(1.0, 0.6, 0.15, 0.85))
	gradient.add_point(0.5, Color(0.9, 0.28, 0.04, 0.55))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp


func _smoke_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.1, 0.09, 0.09, 0.0))
	gradient.set_color(1, Color(0.3, 0.29, 0.28, 0.0))
	gradient.add_point(0.15, Color(0.08, 0.07, 0.07, 0.9))
	gradient.add_point(0.6, Color(0.18, 0.17, 0.16, 0.65))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp


## Labareda: sem luz própria e somando cor (brilha); fumaça: com sombreamento, por transparência.
func _mesh(side: float, glow: bool) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(side, side)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if glow else BaseMaterial3D.BLEND_MODE_MIX
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glow else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = SmokeView._puff_texture()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow:
		material.albedo_color = FLAME_GLOW
	quad.material = material
	return quad
