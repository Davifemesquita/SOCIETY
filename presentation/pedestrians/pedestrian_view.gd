class_name PedestrianView
extends Node3D
## Multidão na tela (seção 9): um MultiMesh por classe e corpo, com o shader de VAT. Avança o
## tempo visual (para na pausa, acelera com a velocidade do jogo), roda a Crowd e aplica só as
## instâncias que mudaram. Nenhuma regra aqui.

const MODEL_PATHS: Array[String] = ["res://assets/vat/pedestrian_male.res", "res://assets/vat/pedestrian_female.res"]
const SHADER := preload("res://shaders/pedestrian_vat.gdshader")
const HIDDEN := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)
## Altura da caixa de recorte da multidão (o boneco anda no shader, longe da posição da instância).
const BOUNDS_HEIGHT_M := 4.0

## Os modelos ficam carregados entre partidas (abrir um save ou um jogo novo não relê os .res).
static var _model_cache: Dictionary[String, VatModel] = {}

var crowd: Crowd
## Mede o custo da multidão na CPU por quadro (benchmark).
var last_update_usec: int = 0

var _instances: Array[MultiMeshInstance3D] = []
var _models: Array[VatModel] = []


func setup(simulation: Simulation, config: GameConfig, seed_value: int = 1) -> void:
	var strides: Array[PackedFloat32Array] = []
	for path: String in MODEL_PATHS:
		if not _model_cache.has(path):
			var loaded := load(path) as VatModel
			if loaded != null:
				_model_cache[path] = loaded
		var model: VatModel = _model_cache.get(path)
		if model == null:
			push_error("PedestrianView: falta %s (rode tools/bake_pedestrians.gd)" % path)
			return
		_models.append(model)
		strides.append(model.clip_strides_m)
	crowd = Crowd.new(simulation, config, strides, seed_value)
	var grid := simulation.world.island(Simulation.MAIN_ISLAND)
	var size := Vector3(grid.size.x * config.cell_size_m, BOUNDS_HEIGHT_M, grid.size.y * config.cell_size_m)
	for group: Crowd.Group in crowd.groups:
		var model := _models[group.body]
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter(&"vat_positions", model.positions)
		material.set_shader_parameter(&"vat_normals", model.normals)
		material.set_shader_parameter(&"clips", model.clip_uniforms())
		material.set_shader_parameter(&"trousers_color", simulation.data.tier(group.tier).trousers_color)
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.use_custom_data = true
		multimesh.mesh = model.mesh
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = material
		instance.custom_aabb = AABB(Vector3(-2.0, -1.0, -2.0), size + Vector3(4.0, 1.0, 4.0))
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if config.pedestrian_shadows \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		_instances.append(instance)
	var changed := func(_id: int) -> void: crowd.mark_structure_changed()
	EventBus.building_placed.connect(changed)
	EventBus.building_removed.connect(changed)
	EventBus.house_upgraded.connect(changed)
	EventBus.roads_changed.connect(changed)
	EventBus.world_replaced.connect(crowd.reset)


func _process(delta: float) -> void:
	if crowd == null:
		return
	var started := Time.get_ticks_usec()
	crowd.update(delta * GameClock.clock.speed_multiplier(), GameClock.clock.hour())
	apply()
	last_update_usec = Time.get_ticks_usec() - started
	RenderingServer.global_shader_parameter_set(&"visual_time", crowd.time)


## Leva as mudanças da Crowd para os MultiMesh.
func apply() -> void:
	for index: int in crowd.groups.size():
		var group := crowd.groups[index]
		if group.resized:
			group.resized = false
			_rebuild_group(index)
	var multimeshes: Array[MultiMesh] = []
	for instance: MultiMeshInstance3D in _instances:
		multimeshes.append(instance.multimesh)
	for slot: Vector2i in crowd.cleared:
		multimeshes[slot.x].set_instance_transform(slot.y, HIDDEN)
	crowd.cleared.clear()
	for agent: Crowd.Agent in crowd.take_changes():
		if not agent.removed:
			_write(multimeshes[agent.group], agent)


func _rebuild_group(index: int) -> void:
	var multimesh := _instances[index].multimesh
	multimesh.instance_count = crowd.groups[index].capacity
	for slot: int in multimesh.instance_count:
		multimesh.set_instance_transform(slot, HIDDEN)
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.group == index:
			_write(multimesh, agent)


func _write(multimesh: MultiMesh, agent: Crowd.Agent) -> void:
	if agent.slot >= multimesh.instance_count:
		return
	multimesh.set_instance_transform(agent.slot, crowd.instance_transform(agent))
	multimesh.set_instance_color(agent.slot, agent.color)
	multimesh.set_instance_custom_data(agent.slot, crowd.instance_custom(agent))


func instance_count() -> int:
	var total := 0
	for instance: MultiMeshInstance3D in _instances:
		total += instance.multimesh.instance_count
	return total
