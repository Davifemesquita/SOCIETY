class_name BuildingView
extends Node3D
## Caixas cinza dos prédios. Escuta o EventBus e só lê a simulação; nenhuma regra aqui.
## Cada prédio mostra a porta na face de entrada e um "!" laranja quando não toca estrada.

const DOOR_COLOR := Color(0.25, 0.18, 0.12)
const ALERT_COLOR := Color(1.0, 0.55, 0.1)
const SELECTED_COLOR := Color(1.0, 0.85, 0.35, 0.35)

var _simulation: Simulation
var _cell_size: float
var _nodes: Dictionary[int, Node3D] = {}
var _alerts: Dictionary[int, Label3D] = {}
var _materials: Dictionary[StringName, StandardMaterial3D] = {}
var _door_material := StandardMaterial3D.new()
var _selection: MeshInstance3D
var _selected_id: int = 0


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
	EventBus.roads_changed.connect(_on_roads_changed)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for building_id: int in _nodes.keys():
		_remove(building_id)
	for building_id: int in _simulation.world.building_ids():
		_add(building_id)
	_refresh_alerts()
	select(0)


func building_count() -> int:
	return _nodes.size()


func select(building_id: int) -> void:
	_selected_id = building_id
	var record := _simulation.world.building(building_id)
	_selection.visible = record != null
	if record == null:
		return
	var def := _simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var box := BoxMesh.new()
	box.size = Vector3(area.size.x * _cell_size + 0.4, def.height_m + 0.4, area.size.y * _cell_size + 0.4)
	_selection.mesh = box
	_selection.position = GridSpace.rect_center(area, _cell_size) + Vector3(0.0, def.height_m * 0.5, 0.0)


func has_alert(building_id: int) -> bool:
	return _alerts.has(building_id) and _alerts[building_id].visible


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	var def := _simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var root := Node3D.new()
	root.position = GridSpace.rect_center(area, _cell_size)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(area.size.x * _cell_size - 0.3, def.height_m, area.size.y * _cell_size - 0.3)
	body.mesh = box
	body.material_override = _material_for(def)
	body.position.y = def.height_m * 0.5
	root.add_child(body)
	root.add_child(_door(record, def, area))
	var alert := Label3D.new()
	alert.text = "!"
	alert.font_size = 96
	alert.outline_size = 18
	alert.modulate = ALERT_COLOR
	alert.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alert.fixed_size = true
	alert.pixel_size = 0.0004
	alert.no_depth_test = true
	alert.position.y = def.height_m + 2.0
	alert.visible = false
	root.add_child(alert)
	add_child(root)
	_nodes[building_id] = root
	_alerts[building_id] = alert


## Porta: bloco escuro encostado no meio da face de entrada.
func _door(record: BuildingRecord, def: BuildingDef, area: Rect2i) -> MeshInstance3D:
	var door := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.4, 2.4, 1.4)
	door.mesh = mesh
	door.material_override = _door_material
	var entrance := GridSpace.cell_center(Footprint.entrance_cell(record.origin, def.size, record.rotation), _cell_size)
	var front := Footprint.front_direction(record.rotation)
	var center := GridSpace.rect_center(area, _cell_size)
	door.position = entrance - center - Vector3(front.x, 0.0, front.y) * (_cell_size * 0.5 + 0.3) + Vector3(0.0, 1.2, 0.0)
	return door


func _material_for(def: BuildingDef) -> StandardMaterial3D:
	if not _materials.has(def.id):
		var material := StandardMaterial3D.new()
		material.albedo_color = def.color
		material.roughness = 0.9
		_materials[def.id] = material
	return _materials[def.id]


func _remove(building_id: int) -> void:
	if _nodes.has(building_id):
		_nodes[building_id].queue_free()
		_nodes.erase(building_id)
		_alerts.erase(building_id)


func _refresh_alerts() -> void:
	for building_id: int in _alerts:
		_alerts[building_id].visible = not _simulation.has_road_access(building_id)


func _on_building_placed(building_id: int) -> void:
	_add(building_id)
	_alerts[building_id].visible = not _simulation.has_road_access(building_id)


func _on_building_removed(building_id: int) -> void:
	_remove(building_id)
	if building_id == _selected_id:
		select(0)


func _on_roads_changed(_island_id: int) -> void:
	_refresh_alerts()
