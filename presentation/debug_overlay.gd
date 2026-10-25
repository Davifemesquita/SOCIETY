class_name DebugOverlay
extends MeshInstance3D
## Grade de construção e camadas de depuração sobre a ilha (seção 15):
## F1 grade e ocupação, F2 rede de estradas colorida por trecho conectado.
## Também mostra um destaque pedido pela partida (raio de serviço, área dos campos, terreno).
## Desde a Fase 5 é uma malha que acompanha o relevo da ilha da ferramenta (set_island).
## Desde a Fase 33 são duas passadas: as linhas, sempre com teste de profundidade e só em volta do cursor (set_focus),
## e as células destacadas por cima de tudo (material_overlay, sem linhas). Antes o destaque trocava a malha inteira
## para o raio-X e a grade da ilha toda aparecia sobre as copas e os prédios.

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
var _island_id: int = -1
var _custom: Image = null
var _material := ShaderMaterial.new()
var _xray_material := ShaderMaterial.new()


## grid_radius_m: até onde do cursor as linhas aparecem (0: a ilha toda).
func setup(simulation: Simulation, cell_size: float, grid_radius_m: float = 0.0) -> void:
	_simulation = simulation
	_material.shader = preload("res://shaders/grid_overlay.gdshader")
	_xray_material.shader = preload("res://shaders/grid_overlay_xray.gdshader")
	for material: ShaderMaterial in [_material, _xray_material]:
		material.set_shader_parameter(&"cell_size", cell_size)
	_material.set_shader_parameter(&"focus_radius_m", grid_radius_m)
	_xray_material.set_shader_parameter(&"show_cells", true)
	_xray_material.set_shader_parameter(&"show_lines", false)
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EventBus.building_placed.connect(func(_id: int) -> void: _update())
	EventBus.building_removed.connect(func(_id: int) -> void: _update())
	EventBus.roads_changed.connect(func(_island: int) -> void: _update())
	EventBus.world_replaced.connect(func() -> void:
		_island_id = -1
		set_island(Simulation.MAIN_ISLAND))
	set_island(Simulation.MAIN_ISLAND)


## Põe a grade na ilha dada (a da ferramenta), refazendo a malha no relevo dela.
func set_island(island_id: int) -> void:
	if island_id == _island_id:
		return
	_island_id = island_id
	var grid := _simulation.world.island(island_id)
	mesh = terrain_mesh(grid, HEIGHT_M)
	position = Vector3.ZERO
	for material: ShaderMaterial in [_material, _xray_material]:
		material.set_shader_parameter(&"grid_cells", Vector2(grid.size))
		material.set_shader_parameter(&"grid_origin", grid.origin_m)
	_update()


func island_id() -> int:
	return _island_id


## Ponto do mundo em volta do qual as linhas aparecem (o cursor).
func set_focus(point: Vector3) -> void:
	_material.set_shader_parameter(&"focus_point", Vector2(point.x, point.z))


## Material das linhas e o das células destacadas (testes).
func lines_material() -> ShaderMaterial:
	return _material


func cells_material() -> ShaderMaterial:
	return _xray_material


## Malha de um vértice por canto de célula, na altura do terreno mais a folga dada.
static func terrain_mesh(grid: IslandGrid, lift: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var width := grid.size.x + 1
	vertices.resize(width * (grid.size.y + 1))
	for y: int in grid.size.y + 1:
		for x: int in width:
			vertices[y * width + x] = Vector3(grid.origin_m.x + x * grid.cell_size, grid.corner_height(x, y) + lift,
					grid.origin_m.y + y * grid.cell_size)
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var a := y * width + x
			indices.append_array(PackedInt32Array([a, a + 1, a + width, a + 1, a + width + 1, a + width]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result


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
	_material.set_shader_parameter(&"show_lines", grid_visible)
	material_override = _material
	material_overlay = _xray_material if cells != null else null
	if visible and cells != null:
		_xray_material.set_shader_parameter(&"cell_data", ImageTexture.create_from_image(cells))


func _layer_image() -> Image:
	var grid := _simulation.world.island(_island_id)
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
