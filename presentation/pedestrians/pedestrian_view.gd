class_name PedestrianView
extends Node3D
## Multidão na tela (seção 9): um MultiMesh por classe e corpo, com o shader de VAT. Avança o
## tempo visual (para na pausa, acelera com a velocidade do jogo), roda a Crowd e aplica só as
## instâncias que mudaram. Nenhuma regra aqui.
## Fase 15: cada grupo tem também um MultiMesh de cestos e um de sacos (shaders/carried_vat.gdshader), com uma
## instância por pedestre, mostrada só em quem anda carregando aquilo (Crowd.Agent.load).

const MODEL_PATHS: Array[String] = ["res://assets/vat/pedestrian_male.res", "res://assets/vat/pedestrian_female.res"]
const SHADER := preload("res://shaders/pedestrian_vat.gdshader")
const CARRIED_SHADER := preload("res://shaders/carried_vat.gdshader")
## Onde vai a carga, no referencial do boneco: altura (fração da altura do corpo) e quanto à frente (m).
const HOLD_HEIGHT := 0.54
const HOLD_FORWARD_M := 0.3
const HIDDEN := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)
## Altura da caixa de recorte da multidão (o boneco anda no shader, longe da posição da instância).
const BOUNDS_HEIGHT_M := 4.0

## Os modelos ficam carregados entre partidas (abrir um save ou um jogo novo não relê os .res).
static var _model_cache: Dictionary[String, VatModel] = {}

var crowd: Crowd
## Mede o custo da multidão na CPU por quadro (benchmark).
var last_update_usec: int = 0

var _instances: Array[MultiMeshInstance3D] = []
## Por grupo: a carga (Crowd.Load) → o MultiMesh dela.
var _carried: Array[Dictionary] = []
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
	# a principal e as regiões vizinhas (onde o gerador põe as outras ilhas), para qualquer semente
	var region := config.terrain_region_m
	var bounds := AABB(Vector3(-region, -10.0, -region), Vector3(region * 3.0, 60.0, region * 3.0))
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
		instance.custom_aabb = bounds
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if config.pedestrian_shadows \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		_instances.append(instance)
		var carried: Dictionary[int, MultiMeshInstance3D] = {}
		var hold := Vector3(0.0, model.mesh.get_aabb().size.y * HOLD_HEIGHT, -HOLD_FORWARD_M)
		for load: int in [Crowd.Load.BASKET, Crowd.Load.SACK]:
			var load_material := ShaderMaterial.new()
			load_material.shader = CARRIED_SHADER
			load_material.set_shader_parameter(&"hold", hold)
			var load_multimesh := MultiMesh.new()
			load_multimesh.transform_format = MultiMesh.TRANSFORM_3D
			load_multimesh.use_custom_data = true
			load_multimesh.mesh = CarriedGoods.basket_mesh() if load == Crowd.Load.BASKET else CarriedGoods.sack_mesh()
			var load_instance := MultiMeshInstance3D.new()
			load_instance.multimesh = load_multimesh
			load_instance.material_override = load_material
			load_instance.custom_aabb = bounds
			load_instance.cast_shadow = instance.cast_shadow
			add_child(load_instance)
			carried[load] = load_instance
		_carried.append(carried)
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
		for load_instance: MultiMeshInstance3D in _carried[slot.x].values():
			if slot.y < load_instance.multimesh.instance_count:
				load_instance.multimesh.set_instance_transform(slot.y, HIDDEN)
	crowd.cleared.clear()
	for agent: Crowd.Agent in crowd.take_changes():
		if not agent.removed:
			_write(agent.group, agent)


func _rebuild_group(index: int) -> void:
	var multimeshes: Array[MultiMesh] = [_instances[index].multimesh]
	for load_instance: MultiMeshInstance3D in _carried[index].values():
		multimeshes.append(load_instance.multimesh)
	for multimesh: MultiMesh in multimeshes:
		multimesh.instance_count = crowd.groups[index].capacity
		for slot: int in multimesh.instance_count:
			multimesh.set_instance_transform(slot, HIDDEN)
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.group == index:
			_write(index, agent)


func _write(index: int, agent: Crowd.Agent) -> void:
	var multimesh := _instances[index].multimesh
	if agent.slot >= multimesh.instance_count:
		return
	var place := crowd.instance_transform(agent)
	var custom := crowd.instance_custom(agent)
	multimesh.set_instance_transform(agent.slot, place)
	multimesh.set_instance_color(agent.slot, agent.color)
	multimesh.set_instance_custom_data(agent.slot, custom)
	# a carga: só em quem anda carregando; w leva o passo da animação (o balanço)
	var walking := agent.state == Crowd.State.WALKING and agent.clip == Crowd.CLIP_WALK_CARRY
	for load: int in _carried[index]:
		var holder: MultiMeshInstance3D = _carried[index][load]
		var carried := holder.multimesh
		if agent.slot >= carried.instance_count:
			continue
		if walking and agent.load == load:
			carried.set_instance_transform(agent.slot, place)
			carried.set_instance_custom_data(agent.slot, Color(custom.r, custom.g, custom.b, crowd.stride_of(agent)))
		else:
			carried.set_instance_transform(agent.slot, HIDDEN)


## Cargas à vista agora (cestos ou sacos, Crowd.Load), para os testes.
func carried_count(load: int) -> int:
	var total := 0
	for carried: Dictionary in _carried:
		var holder: MultiMeshInstance3D = carried[load]
		var multimesh := holder.multimesh
		for slot: int in multimesh.instance_count:
			if multimesh.get_instance_transform(slot).basis.determinant() != 0.0:
				total += 1
	return total


func instance_count() -> int:
	var total := 0
	for instance: MultiMeshInstance3D in _instances:
		total += instance.multimesh.instance_count
	return total
