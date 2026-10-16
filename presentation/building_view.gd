class_name BuildingView
extends Node3D
## Prédios. Escuta o EventBus e só lê a simulação; nenhuma regra aqui.
## - Desde 16/10/2026 o prédio é um modelo montado com as peças do Kenney Fantasy Town Kit
##   (BuildingKit): fachadas com janelas e porta, telhado pela forma. Campo, pasto e píer, e tudo se
##   o kit faltar, continuam caixas (o que vem abaixo).
## - Casa: cor e altura da classe; refeita quando sobe de classe. Desde a Fase 8 cada casa tira,
##   pelo id, um de HOUSE_VARIANTS modelos (telhado de duas águas de frente ou de lado, ou telhado
##   plano com chaminé) e um tom da cor da classe: a rua deixa de ser fileira de caixas iguais.
## - Prédio parado: ícone do motivo flutuando em cima (sem estrada, sem entrada, saída cheia…);
##   o texto do motivo fica na dica do painel. Desde a Fase 7 é ícone, não texto.
## - Casa em protesto: ícone de protesto. Campo e pasto não têm ícone.

const DOOR_COLOR := Color(0.25, 0.18, 0.12)
## Tamanho do ícone na tela (Sprite3D de tamanho fixo).
const ICON_PIXEL_SIZE := 0.00028
const SELECTED_COLOR := Color(1.0, 0.85, 0.35, 0.35)
const REFRESH_SECONDS := 0.5
## A caixa desce abaixo do chão: a área pode ter até max_build_height_delta_m de desnível.
const FOUNDATION_M := 0.6
## Modelos placeholder de casa por classe, e quanto o tom da cor varia de uma casa para outra.
const HOUSE_VARIANTS := 3
const HOUSE_SHADE_STEPS := 5
const HOUSE_SHADE := 0.05
## Altura do telhado em fração da altura da casa (ele fica em cima: as janelas não mudam).
const ROOF_FRACTION := 0.35
const ROOF_DARKEN := 0.45
const SCAFFOLD_COLOR := Color(0.52, 0.4, 0.28)
## Só prédio a partir desta altura esconde o que está atrás (ocultador, Fase 9).
const OCCLUDER_MIN_HEIGHT_M := 5.0

var _simulation: Simulation
var _cell_size: float
var _nodes: Dictionary[int, Node3D] = {}
var _labels: Dictionary[int, Sprite3D] = {}
## Texto (chave) do motivo mostrado em cada prédio: o ícone é o desenho dele.
var _label_keys: Dictionary[int, String] = {}
var _materials: Dictionary[String, StandardMaterial3D] = {}
var _door_material := StandardMaterial3D.new()
var _selection: MeshInstance3D
## Detalhes (telhado, chaminé, porta) e ocultadores: até onde aparecem, pelo nível gráfico (Fase 9).
var _detail_range_m: float = 260.0
var _occluders: bool = true
var _details: Array[GeometryInstance3D] = []
var _selected_id: int = 0
var _refresh_left: float = 0.0


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	_door_material.albedo_color = DOOR_COLOR
	_selection = MeshInstance3D.new()
	var selection_material := StandardMaterial3D.new()
	selection_material.albedo_color = SELECTED_COLOR
	selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_material.no_depth_test = true
	_selection.material_override = selection_material
	_selection.visible = false
	add_child(_selection)
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: refresh_labels())
	EventBus.building_state_changed.connect(_refresh_label)
	EventBus.house_upgraded.connect(_on_house_upgraded)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for building_id: int in _nodes.keys():
		_remove(building_id)
	for building_id: int in _simulation.world.building_ids():
		_add(building_id)
	refresh_labels()
	select(0)


func building_count() -> int:
	return _nodes.size()


func label_text(building_id: int) -> String:
	return tr(_label_keys[building_id]) if _labels.has(building_id) and _labels[building_id].visible and _label_keys.has(building_id) else ""


## Nome do ícone mostrado sobre o prédio ("" = nenhum).
func label_icon(building_id: int) -> String:
	var key: String = _label_keys.get(building_id, "")
	return _icon_for(key) if _labels.has(building_id) and _labels[building_id].visible else ""


## Mantido da Fase 1: o prédio mostra algum alerta.
func has_alert(building_id: int) -> bool:
	return not label_text(building_id).is_empty()


func select(building_id: int) -> void:
	_selected_id = building_id
	var record := _simulation.world.building(building_id)
	_selection.visible = record != null
	if record == null:
		return
	var area := _area(record)
	var height := _height(record)
	var box := BoxMesh.new()
	box.size = Vector3(area.size.x * _cell_size + 0.4, height + 0.4, area.size.y * _cell_size + 0.4)
	_selection.mesh = box
	_selection.position = _grid(record).rect_world(area) + Vector3(0.0, height * 0.5, 0.0)


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh_labels()


func _grid(record: BuildingRecord) -> IslandGrid:
	return _simulation.world.island(record.island_id)


func _area(record: BuildingRecord) -> Rect2i:
	return Footprint.rect(record.origin, _simulation.def_of(record).size, record.rotation)


func _height(record: BuildingRecord) -> float:
	return _simulation.data.tier(record.tier).house_height_m if record.is_house() else _simulation.def_of(record).height_m


func _color(record: BuildingRecord) -> Color:
	if not record.is_house():
		return _simulation.def_of(record).color
	var shade := (house_hash(record.id) / HOUSE_VARIANTS % HOUSE_SHADE_STEPS - HOUSE_SHADE_STEPS / 2) * HOUSE_SHADE
	var base := _simulation.data.tier(record.tier).house_color
	return base.lightened(shade) if shade >= 0.0 else base.darkened(-shade)


## Número estável sorteado pelo id da casa (o mesmo modelo depois de salvar e carregar).
static func house_hash(building_id: int) -> int:
	return absi(hash(building_id * 7919))


static func house_variant(building_id: int) -> int:
	return house_hash(building_id) % HOUSE_VARIANTS


## Telhado da casa pelo modelo: duas águas com a cumeeira de lado a lado (0) ou de frente para
## trás (1), ou plano com chaminé (2).
func _add_roof(root: Node3D, record: BuildingRecord, body_size: Vector3, height: float) -> void:
	var variant := house_variant(record.id)
	var tier := _simulation.data.tier(record.tier)
	var roof_color := _color(record).darkened(ROOF_DARKEN)
	var top := height
	var roof := MeshInstance3D.new()
	roof.material_override = BuildingMaterials.roofs()
	BuildingMaterials.dress(roof, tier.roof_material, roof_color.lightened(0.35), root.position.y)
	_detail(roof)
	if variant == 2:
		var cap := BoxMesh.new()
		cap.size = Vector3(body_size.x + 0.3, 0.3, body_size.z + 0.3)
		roof.mesh = cap
		roof.position.y = top + 0.15
		var chimney := MeshInstance3D.new()
		var stack := BoxMesh.new()
		stack.size = Vector3(0.7, height * ROOF_FRACTION, 0.7)
		chimney.mesh = stack
		chimney.material_override = BuildingMaterials.walls()
		BuildingMaterials.dress(chimney, BuildingMaterials.Wall.BRICK, roof_color, root.position.y)
		_detail(chimney)
		chimney.position = Vector3(body_size.x * 0.25, top + height * ROOF_FRACTION * 0.5, -body_size.z * 0.2)
		root.add_child(chimney)
	else:
		var prism := PrismMesh.new()
		prism.size = Vector3(body_size.x + 0.4, height * ROOF_FRACTION, body_size.z + 0.4)
		roof.mesh = prism
		roof.position.y = top + height * ROOF_FRACTION * 0.5
		# o prisma do Godot tem a cumeeira ao longo de z; o modelo 0 a põe ao longo de x
		if variant == 0:
			prism.size = Vector3(body_size.z + 0.4, height * ROOF_FRACTION, body_size.x + 0.4)
			roof.rotation.y = PI * 0.5
	root.add_child(roof)


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	var def := _simulation.def_of(record)
	var area := _area(record)
	var height := _height(record)
	var root := Node3D.new()
	root.position = _grid(record).rect_world(area)
	var spec := BuildingKit.spec_for(_simulation, record, _cell_size)
	var body := MeshInstance3D.new()
	var soot: float = _simulation.derived_state().pollution.get(building_id, 0.0)
	var inset := 0.3 if def.kind != BuildingDef.Kind.MODULE else 0.15
	var box_size := Vector3(area.size.x * _cell_size - inset, height + FOUNDATION_M, area.size.y * _cell_size - inset)
	if spec != null:
		body.name = "Model"
		body.mesh = BuildingKit.mesh(spec)
		body.rotation.y = -PI * 0.5 * posmod(record.rotation, 4)
		body.material_override = BuildingMaterials.kit()
		var tier := _simulation.data.tier(record.tier) if record.is_house() else null
		var wall_layer := tier.wall_material if tier != null else def.wall_material
		var roof_layer: int = tier.roof_material if tier != null else (BuildingMaterials.Roof.PLANKS
				if def.wall_material == BuildingMaterials.Wall.WOOD else BuildingMaterials.Roof.TILES)
		var color := _color(record)
		BuildingMaterials.dress_kit(body, wall_layer, color, roof_layer, color.darkened(ROOF_DARKEN).lightened(0.35),
				root.position.y, soot)
		if _occluders and height >= OCCLUDER_MIN_HEIGHT_M:
			root.add_child(_occluder(box_size, Vector3(0.0, (height - FOUNDATION_M) * 0.5, 0.0)))
		root.add_child(body)
	else:
		var box := BoxMesh.new()
		box.size = box_size
		body.mesh = box
		body.position.y = (height - FOUNDATION_M) * 0.5
		if def.kind == BuildingDef.Kind.MODULE:
			body.material_override = _material_for(_color(record))
		else:
			body.material_override = BuildingMaterials.walls()
			var layer := _simulation.data.tier(record.tier).wall_material if record.is_house() else def.wall_material
			BuildingMaterials.dress(body, layer, _color(record), root.position.y, soot)
			if _occluders and height >= OCCLUDER_MIN_HEIGHT_M:
				root.add_child(_occluder(box.size, body.position))
		root.add_child(body)
		if record.is_house():
			_add_roof(root, record, box.size, height)
	if def.kind != BuildingDef.Kind.MODULE:
		if spec == null:
			var door := _door(record, def, area)
			_detail(door)
			root.add_child(door)
		var label := Sprite3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size = true
		label.pixel_size = ICON_PIXEL_SIZE
		label.no_depth_test = true
		label.shaded = false
		label.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		label.render_priority = 10
		# alterna a altura entre vizinhos para as etiquetas não encostarem umas nas outras
		label.position.y = height + 2.0 + (building_id % 2) * 2.5
		label.visible = false
		root.add_child(label)
		_labels[building_id] = label
	add_child(root)
	_nodes[building_id] = root


## Nível gráfico: até onde os detalhes aparecem e se os prédios ocultam o que está atrás.
func set_quality(preset: GraphicsPresetDef) -> void:
	_detail_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	var occluders := preset.visibility_scale >= 0.75
	_details.assign(_details.filter(func(node: GeometryInstance3D) -> bool: return is_instance_valid(node)))
	for node: GeometryInstance3D in _details:
		node.visibility_range_end = _detail_range_m
	if occluders != _occluders:
		_occluders = occluders
		rebuild()


func _detail(node: GeometryInstance3D) -> void:
	node.visibility_range_end = _detail_range_m
	node.visibility_range_end_margin = _detail_range_m * 0.1
	node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_details.append(node)


## Casa que acabou de subir de classe (Fase 9): andaime de madeira em volta e uma nuvem de poeira,
## que somem sozinhos depois de upgrade_scaffold_seconds.
func _scaffold(building_id: int) -> void:
	var root: Node3D = _nodes.get(building_id)
	if root == null:
		return
	var record := _simulation.world.building(building_id)
	var area := _area(record)
	var height := _height(record)
	var size := Vector3(area.size.x * _cell_size + 0.6, height + 1.0, area.size.y * _cell_size + 0.6)
	var frame := Node3D.new()
	frame.name = "Scaffold"
	var wood := _material_for(SCAFFOLD_COLOR)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		frame.add_child(_beam(Vector3(0.18, size.y, 0.18), Vector3(corner.x * size.x * 0.5, size.y * 0.5, corner.y * size.z * 0.5), wood))
	for level: float in [0.35, 0.7]:
		for side: int in 2:
			var along_x := side == 0
			var length := size.x if along_x else size.z
			for sign_value: float in [-1.0, 1.0]:
				var center := Vector3(0.0, size.y * level, sign_value * size.z * 0.5) if along_x \
						else Vector3(sign_value * size.x * 0.5, size.y * level, 0.0)
				frame.add_child(_beam(Vector3(length, 0.12, 0.12) if along_x else Vector3(0.12, 0.12, length), center, wood))
	var dust := GPUParticles3D.new()
	dust.one_shot = true
	dust.amount = 24
	dust.lifetime = 2.5
	dust.explosiveness = 0.8
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = size * 0.5
	process.direction = Vector3.UP
	process.spread = 60.0
	process.initial_velocity_min = 0.5
	process.initial_velocity_max = 1.5
	process.gravity = Vector3(0.0, -0.3, 0.0)
	dust.process_material = process
	var puff := QuadMesh.new()
	puff.size = Vector2(2.0, 2.0)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_color = Color(0.72, 0.64, 0.52, 0.45)
	material.albedo_texture = SmokeView._puff_texture()
	puff.material = material
	dust.draw_pass_1 = puff
	dust.emitting = true
	frame.add_child(dust)
	root.add_child(frame)
	get_tree().create_timer(_simulation.config.upgrade_scaffold_seconds).timeout.connect(frame.queue_free)


static func _beam(size: Vector3, center: Vector3, material: Material) -> MeshInstance3D:
	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	beam.mesh = box
	beam.material_override = material
	beam.position = center
	return beam


static func _occluder(size: Vector3, center: Vector3) -> OccluderInstance3D:
	var occluder := OccluderInstance3D.new()
	var shape := BoxOccluder3D.new()
	# um pouco menor que a caixa: o ocultador nunca pode passar da parede
	shape.size = size * 0.92
	occluder.occluder = shape
	occluder.position = center
	return occluder


## Porta: bloco escuro encostado no meio da face de entrada.
func _door(record: BuildingRecord, def: BuildingDef, area: Rect2i) -> MeshInstance3D:
	var door := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.4, 2.4, 1.4)
	door.mesh = mesh
	door.material_override = _door_material
	var grid := _grid(record)
	var entrance := grid.cell_world(Footprint.entrance_cell(record.origin, def.size, record.rotation))
	var front := Footprint.front_direction(record.rotation)
	var center := grid.rect_world(area)
	door.position = Vector3(entrance.x - center.x, 1.2, entrance.z - center.z) - Vector3(front.x, 0.0, front.y) * (_cell_size * 0.5 + 0.3)
	return door


func _material_for(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		_materials[key] = material
	return _materials[key]


func _remove(building_id: int) -> void:
	if _nodes.has(building_id):
		_nodes[building_id].queue_free()
		_nodes.erase(building_id)
		_labels.erase(building_id)
		_label_keys.erase(building_id)


func refresh_labels() -> void:
	for building_id: int in _labels:
		_refresh_label(building_id)


## Produção mostra o estado quando parada; casa e serviço mostram só a falta de estrada.
## Texto curto do motivo (dica e testes); o ícone sai de _icon_for.
static func label_key(state: BuildingRecord.State) -> String:
	match state:
		BuildingRecord.State.NO_INPUT:
			return "LABEL_NO_INPUT"
		BuildingRecord.State.NO_WORKERS:
			return "LABEL_NO_WORKERS"
		BuildingRecord.State.OUTPUT_FULL:
			return "LABEL_OUTPUT_FULL"
		BuildingRecord.State.NO_ROAD:
			return "LABEL_NO_ROAD"
		BuildingRecord.State.NO_MODULES:
			return "LABEL_NO_MODULES"
		BuildingRecord.State.PAUSED:
			return "LABEL_PAUSED"
		BuildingRecord.State.NO_WAREHOUSE:
			return "LABEL_NO_WAREHOUSE"
		BuildingRecord.State.NO_TREES:
			return "LABEL_NO_TREES"
	return ""


func _refresh_label(building_id: int) -> void:
	if not _labels.has(building_id):
		return
	var label := _labels[building_id]
	var record := _simulation.world.building(building_id)
	var key := ""
	if record.is_house() and record.happiness < _simulation.config.protest_happiness_threshold and record.residents > 0.0:
		key = "LABEL_PROTEST"
	elif not _simulation.has_road_access(building_id):
		key = "LABEL_NO_ROAD"
	elif _simulation.def_of(record).is_warehouse() and not _simulation.derived_state().warehouse_connected.get(building_id, false):
		key = "LABEL_DISCONNECTED"
	elif _simulation.def_of(record).is_production():
		var state := SelectionPanel.shown_state(record)
		if state not in [BuildingRecord.State.PRODUCING, BuildingRecord.State.IDLE]:
			key = label_key(state)
	if key != _label_keys.get(building_id, ""):
		_label_keys[building_id] = key
		if not key.is_empty():
			var icon := Icons.get_icon(_icon_for(key)) as AtlasTexture
			# Sprite3D desenha o atlas inteiro de uma AtlasTexture: usa a região
			label.texture = icon.atlas
			label.region_enabled = true
			label.region_rect = icon.region
	label.visible = not key.is_empty()


## Ícone do motivo: LABEL_NO_ROAD → state_no_road.
static func _icon_for(key: String) -> String:
	return "state_" + key.trim_prefix("LABEL_").to_lower() if not key.is_empty() else ""


func _on_building_placed(building_id: int) -> void:
	_add(building_id)
	_refresh_label(building_id)


func _on_building_removed(building_id: int) -> void:
	_remove(building_id)
	if building_id == _selected_id:
		select(0)


func _on_house_upgraded(building_id: int) -> void:
	_remove(building_id)
	_add(building_id)
	_scaffold(building_id)
	_refresh_label(building_id)
	if building_id == _selected_id:
		select(building_id)
