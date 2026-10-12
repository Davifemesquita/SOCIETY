class_name DebugOverlay
extends MeshInstance3D
## Grade de construção e camadas de depuração sobre a ilha (seção 15):
## F1 grade e ocupação, F2 rede de estradas colorida por trecho conectado.
## Também mostra um destaque pedido pela partida (raio de serviço, área dos campos).

enum Layer { NONE, OCCUPANCY, ROADS }

const BUILDING_CELL := Color(0.95, 0.55, 0.2, 0.45)
const ROAD_CELL := Color(0.3, 0.3, 0.3, 0.45)
const HEIGHT_M := 0.12

var grid_visible: bool = false:
	set(value):
		grid_visible = value
		_update()
var layer: Layer = Layer.NONE:
	set(value):
		layer = value
		_update()

var _simulation: Simulation
var _custom: Image = null
var _material := ShaderMaterial.new()
var _xray_material := ShaderMaterial.new()


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	var grid := simulation.world.island(Simulation.MAIN_ISLAND)
	var plane := PlaneMesh.new()
	plane.size = Vector2(grid.size) * cell_size
	mesh = plane
	position = Vector3(plane.size.x * 0.5, HEIGHT_M, plane.size.y * 0.5)
	_material.shader = preload("res://shaders/grid_overlay.gdshader")
	_xray_material.shader = preload("res://shaders/grid_overlay_xray.gdshader")
	for material: ShaderMaterial in [_material, _xray_material]:
		material.set_shader_parameter(&"cell_size", cell_size)
		material.set_shader_parameter(&"grid_cells", Vector2(grid.size))
	_xray_material.set_shader_parameter(&"show_cells", true)
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EventBus.building_placed.connect(func(_id: int) -> void: _update())
	EventBus.building_removed.connect(func(_id: int) -> void: _update())
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _update())
	EventBus.world_replaced.connect(_update)
	_update()


func toggle(target: Layer) -> void:
	layer = Layer.NONE if layer == target else target


## Destaque por célula (imagem do tamanho da grade); as camadas F1/F2 têm prioridade.
func show_custom(image: Image) -> void:
	_custom = image
	_update()


func clear_custom() -> void:
	if _custom != null:
		_custom = null
		_update()


func has_custom() -> bool:
	return _custom != null


func _update() -> void:
	if _simulation == null:
		return
	visible = grid_visible or layer != Layer.NONE or _custom != null
	var cells: Image = _layer_image() if layer != Layer.NONE else _custom
	material_override = _material if cells == null else _xray_material
	if visible and cells != null:
		_xray_material.set_shader_parameter(&"cell_data", ImageTexture.create_from_image(cells))


func _layer_image() -> Image:
	var grid := _simulation.world.island(Simulation.MAIN_ISLAND)
	var image := Image.create_empty(grid.size.x, grid.size.y, false, Image.FORMAT_RGBA8)
	var labels := RoadNetwork.components(grid) if layer == Layer.ROADS else PackedInt32Array()
	for i: int in grid.occupancy.size():
		var cell := grid.cell_at(i)
		if layer == Layer.OCCUPANCY:
			if grid.occupancy[i] != 0:
				image.set_pixelv(cell, BUILDING_CELL)
			elif grid.roads[i] != IslandGrid.Road.NONE:
				image.set_pixelv(cell, ROAD_CELL)
		elif labels[i] != 0:
			image.set_pixelv(cell, Color.from_hsv(fmod(labels[i] * 0.618034, 1.0), 0.8, 1.0, 0.7))
	return image
