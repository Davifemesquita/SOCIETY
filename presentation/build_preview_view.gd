class_name BuildPreviewView
extends Node3D
## Prévia da ferramenta de construção: fantasma do prédio, traçado da estrada ou área de
## demolição, em verde quando pode e vermelho quando não pode.
## Desde a Fase 33 o fantasma é o próprio modelo do kit (BuildingKit), girado como vai ficar, e quem não
## pode (e a demolição) leva listras, além da cor (shaders/build_ghost.gdshader). A caixa fica para o que
## não tem modelo (campo, pasto, píer, decoração).

const VALID_COLOR := Color(0.35, 0.9, 0.4, 0.45)
const INVALID_COLOR := Color(0.95, 0.25, 0.2, 0.5)
const DEMOLISH_COLOR := Color(0.95, 0.3, 0.15, 0.35)
## Acima da água e da fumaça, que também são transparentes.
const RENDER_PRIORITY := 20

var _tool: BuildTool
var _simulation: Simulation
var _cell_size: float
var _ghost := MeshInstance3D.new()
var _model := MeshInstance3D.new()
var _door := MeshInstance3D.new()
var _roads := MultiMeshInstance3D.new()
var _material := ShaderMaterial.new()


func setup(tool: BuildTool, cell_size: float, simulation: Simulation = null) -> void:
	_tool = tool
	_simulation = simulation
	_cell_size = cell_size
	_material.shader = preload("res://shaders/build_ghost.gdshader")
	_material.render_priority = RENDER_PRIORITY
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(1.4, 2.4, 1.4)
	_door.mesh = door_mesh
	var tile := BoxMesh.new()
	tile.size = Vector3(cell_size * 0.9, 0.25, cell_size * 0.9)
	_roads.multimesh = MultiMesh.new()
	_roads.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_roads.multimesh.mesh = tile
	_model.name = "Model"
	for node: GeometryInstance3D in [_ghost, _model, _door, _roads]:
		node.material_override = _material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	tool.changed.connect(refresh)
	EventBus.building_placed.connect(func(_id: int) -> void: refresh())
	EventBus.building_removed.connect(func(_id: int) -> void: refresh())
	EventBus.roads_changed.connect(func(_island_id: int) -> void: refresh())
	refresh()


func refresh() -> void:
	_ghost.visible = false
	_model.visible = false
	_door.visible = false
	_roads.visible = false
	var valid := _tool.preview_reason() == PlacementRules.OK
	_set_look(VALID_COLOR if valid else INVALID_COLOR, not valid)
	match _tool.mode:
		BuildTool.Mode.BUILDING when _tool.dragging:
			# Fase 49: o retângulo de substituir
			_set_look(DEMOLISH_COLOR, true)
			_show_box(_tool.demolish_rect(), 3.0)
		BuildTool.Mode.BUILDING when _tool.plan_mode and valid:
			_set_look(PlanView.PLAN_COLOR, false)
			_show_building()
		BuildTool.Mode.BUILDING, BuildTool.Mode.MOVE:
			_show_building()
		BuildTool.Mode.ROAD:
			_show_roads()
		BuildTool.Mode.DEMOLISH:
			_set_look(DEMOLISH_COLOR, true)
			_show_box(_tool.demolish_rect(), 3.0)


## O fantasma mostra o modelo do prédio (testes).
func shows_model() -> bool:
	return _model.visible


## O fantasma está listrado: não pode, ou é demolição (testes).
func is_striped() -> bool:
	return _material.get_shader_parameter(&"striped")


func _set_look(color: Color, striped: bool) -> void:
	_material.set_shader_parameter(&"tint", color)
	_material.set_shader_parameter(&"striped", striped)


func _show_building() -> void:
	var def := _tool.building_def
	if not _show_model():
		_show_box(_tool.building_rect(), def.height_m)
	var origin := _tool.building_origin()
	var front := Footprint.front_direction(_tool.rotation)
	var grid := _tool.grid()
	var entrance := grid.cell_world(Footprint.entrance_cell(origin, def.size, _tool.rotation))
	var base := grid.area_height(_tool.building_rect().intersection(Rect2i(Vector2i.ZERO, grid.size)))
	_door.position = Vector3(entrance.x, base + 1.2, entrance.z) - Vector3(front.x, 0.0, front.y) * (_cell_size * 0.5)
	_door.visible = true


## O modelo do kit no lugar e na rotação da ferramenta, como a BuildingView o montaria; false se o prédio não tem
## modelo (ou sem a simulação).
func _show_model() -> bool:
	if _simulation == null:
		return false
	var def := _tool.building_def
	var record := BuildingRecord.new(0, def.id, _tool.island_id, _tool.building_origin(), _tool.rotation)
	var moving := _simulation.world.building(_tool.moving_id) if _tool.mode == BuildTool.Mode.MOVE else null
	if moving != null:
		# o mesmo modelo do prédio que se move: o id escolhe a variante da casa, e a classe e o nível contam
		record.id = moving.id
		record.tier = moving.tier
		record.level = moving.level
	elif def.kind == BuildingDef.Kind.RESIDENCE:
		record.tier = _simulation.data.tiers[0].id
	var spec := BuildingKit.spec_for(_simulation, record, _cell_size)
	if spec == null:
		return false
	var area := _tool.building_rect()
	var grid := _tool.grid()
	var inside := area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	var center := grid.rect_world(area)
	_model.mesh = BuildingKit.mesh(spec)
	# como o prédio construído (Fase 39): o piso no canto mais alto do lote
	var base := 0.0
	if inside.has_area():
		base = grid.area_height(inside) + BuildingKit.seat_lift(grid, inside)
	_model.position = Vector3(center.x, base, center.z)
	_model.rotation.y = -PI * 0.5 * posmod(_tool.rotation, 4)
	_model.visible = true
	return true


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
