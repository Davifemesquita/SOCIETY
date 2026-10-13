class_name BuildPreviewView
extends Node3D
## Prévia da ferramenta de construção: fantasma do prédio, traçado da estrada ou área de
## demolição, em verde quando pode e vermelho quando não pode.

const VALID_COLOR := Color(0.35, 0.9, 0.4, 0.45)
const INVALID_COLOR := Color(0.95, 0.25, 0.2, 0.5)
const DEMOLISH_COLOR := Color(0.95, 0.3, 0.15, 0.35)

var _tool: BuildTool
var _cell_size: float
var _ghost := MeshInstance3D.new()
var _door := MeshInstance3D.new()
var _roads := MultiMeshInstance3D.new()
var _material := StandardMaterial3D.new()


func setup(tool: BuildTool, cell_size: float) -> void:
	_tool = tool
	_cell_size = cell_size
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.material_override = _material
	_door.material_override = _material
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(1.4, 2.4, 1.4)
	_door.mesh = door_mesh
	var tile := BoxMesh.new()
	tile.size = Vector3(cell_size * 0.9, 0.25, cell_size * 0.9)
	_roads.multimesh = MultiMesh.new()
	_roads.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_roads.multimesh.mesh = tile
	_roads.material_override = _material
	for node: Node3D in [_ghost, _door, _roads]:
		add_child(node)
	tool.changed.connect(refresh)
	EventBus.building_placed.connect(func(_id: int) -> void: refresh())
	EventBus.building_removed.connect(func(_id: int) -> void: refresh())
	EventBus.roads_changed.connect(func(_island_id: int) -> void: refresh())
	refresh()


func refresh() -> void:
	_ghost.visible = false
	_door.visible = false
	_roads.visible = false
	var valid := _tool.preview_reason() == PlacementRules.OK
	_material.albedo_color = VALID_COLOR if valid else INVALID_COLOR
	match _tool.mode:
		BuildTool.Mode.BUILDING:
			_show_building()
		BuildTool.Mode.ROAD:
			_show_roads()
		BuildTool.Mode.DEMOLISH:
			_material.albedo_color = DEMOLISH_COLOR
			_show_box(_tool.demolish_rect(), 3.0)


func _show_building() -> void:
	var def := _tool.building_def
	_show_box(_tool.building_rect(), def.height_m)
	var origin := _tool.building_origin()
	var front := Footprint.front_direction(_tool.rotation)
	var grid := _tool.grid()
	var entrance := grid.cell_world(Footprint.entrance_cell(origin, def.size, _tool.rotation))
	var base := grid.area_height(_tool.building_rect().intersection(Rect2i(Vector2i.ZERO, grid.size)))
	_door.position = Vector3(entrance.x, base + 1.2, entrance.z) - Vector3(front.x, 0.0, front.y) * (_cell_size * 0.5)
	_door.visible = true


## Caixa da área, assentada na altura média do terreno dentro da ilha.
func _show_box(area: Rect2i, height: float) -> void:
	var grid := _tool.grid()
	var box := BoxMesh.new()
	box.size = Vector3(area.size.x * _cell_size, height, area.size.y * _cell_size)
	_ghost.mesh = box
	var inside := area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	var base := grid.area_height(inside) if inside.has_area() else 0.0
	var center := grid.rect_world(area)
	_ghost.position = Vector3(center.x, base + height * 0.5, center.z)
	_ghost.visible = true


func _show_roads() -> void:
	var grid := _tool.grid()
	var cells := _tool.road_cells()
	_roads.multimesh.instance_count = cells.size()
	for i: int in cells.size():
		var position := grid.surface_world(cells[i]) if grid.in_bounds(cells[i]) else grid.cell_world(cells[i])
		_roads.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, position + Vector3(0.0, 0.15, 0.0)))
	_roads.visible = true
