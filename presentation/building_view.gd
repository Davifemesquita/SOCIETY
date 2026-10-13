class_name BuildingView
extends Node3D
## Caixas dos prédios. Escuta o EventBus e só lê a simulação; nenhuma regra aqui.
## - Casa: cor e altura da classe; refeita quando sobe de classe.
## - Prédio parado: etiqueta com o motivo (sem estrada, sem entrada, saída cheia…).
## - Casa em protesto: etiqueta vermelha. Campo e pasto não têm etiqueta.

const DOOR_COLOR := Color(0.25, 0.18, 0.12)
const ALERT_COLOR := Color(1.0, 0.55, 0.1)
const PROTEST_COLOR := Color(1.0, 0.3, 0.25)
const PAUSED_COLOR := Color(0.85, 0.85, 0.85)
const SELECTED_COLOR := Color(1.0, 0.85, 0.35, 0.35)
const REFRESH_SECONDS := 0.5
## A caixa desce abaixo do chão: a área pode ter até max_build_height_delta_m de desnível.
const FOUNDATION_M := 0.6

var _simulation: Simulation
var _cell_size: float
var _nodes: Dictionary[int, Node3D] = {}
var _labels: Dictionary[int, Label3D] = {}
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
	return _labels[building_id].text if _labels.has(building_id) and _labels[building_id].visible else ""


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
		var label := Label3D.new()
		label.font_size = 34
		label.outline_size = 10
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size = true
		label.pixel_size = 0.0005
		label.no_depth_test = true
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


func refresh_labels() -> void:
	for building_id: int in _labels:
		_refresh_label(building_id)


## Produção mostra o estado quando parada; casa e serviço mostram só a falta de estrada.
## Texto curto da etiqueta sobre o prédio (o painel mostra o texto completo). Vira ícone na Fase 7.
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
	var text := ""
	var color := ALERT_COLOR
	if record.is_house() and record.happiness < _simulation.config.protest_happiness_threshold and record.residents > 0.0:
		text = tr("LABEL_PROTEST")
		color = PROTEST_COLOR
	elif not _simulation.has_road_access(building_id):
		text = tr("LABEL_NO_ROAD")
	elif _simulation.def_of(record).is_warehouse() and not _simulation.derived_state().warehouse_connected.get(building_id, false):
		text = tr("LABEL_DISCONNECTED")
	elif _simulation.def_of(record).is_production():
		var state := SelectionPanel.shown_state(record)
		if state not in [BuildingRecord.State.PRODUCING, BuildingRecord.State.IDLE]:
			text = tr(label_key(state))
			color = PAUSED_COLOR if record.paused else ALERT_COLOR
	label.text = text
	label.modulate = color
	label.visible = not text.is_empty()


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
