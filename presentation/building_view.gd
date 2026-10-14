class_name BuildingView
extends Node3D
## Caixas dos prédios. Escuta o EventBus e só lê a simulação; nenhuma regra aqui.
## - Casa: cor e altura da classe; refeita quando sobe de classe.
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

var _simulation: Simulation
var _cell_size: float
var _nodes: Dictionary[int, Node3D] = {}
var _labels: Dictionary[int, Sprite3D] = {}
## Texto (chave) do motivo mostrado em cada prédio: o ícone é o desenho dele.
var _label_keys: Dictionary[int, String] = {}
var _materials: Dictionary[String, StandardMaterial3D] = {}
var _door_material := StandardMaterial3D.new()
var _selection: MeshInstance3D
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
	return _simulation.data.tier(record.tier).house_color if record.is_house() else _simulation.def_of(record).color


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	var def := _simulation.def_of(record)
	var area := _area(record)
	var height := _height(record)
	var root := Node3D.new()
	root.position = _grid(record).rect_world(area)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	var inset := 0.3 if def.kind != BuildingDef.Kind.MODULE else 0.15
	box.size = Vector3(area.size.x * _cell_size - inset, height + FOUNDATION_M, area.size.y * _cell_size - inset)
	body.mesh = box
	body.material_override = _material_for(_color(record))
	body.position.y = (height - FOUNDATION_M) * 0.5
	root.add_child(body)
	if def.kind != BuildingDef.Kind.MODULE:
		root.add_child(_door(record, def, area))
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
	_refresh_label(building_id)
	if building_id == _selected_id:
		select(building_id)
