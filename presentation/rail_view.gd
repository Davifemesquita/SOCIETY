class_name RailView
extends Node3D
## Ferrovia (Fase 70): o trilho de cada ilha numa malha só — lastro de brita, dormentes de madeira e as duas barras de
## aço —, em cada célula do meio até o lado de cada vizinho com trilho (a célula sozinha vira um trecho reto), sentado na
## malha do terreno com o detalhe das encostas. Refeito quando o trilho da ilha muda. Também desenha os campos de
## petróleo (Fase 70) ainda livres: manchas escuras e brilhantes no chão. Só lê o mundo.

const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Medidas (m): bitola (entre as barras), barra, dormente, lastro e quanto tudo fica acima do chão.
const GAUGE_M := 1.0
const BAR_M := Vector2(0.09, 0.12)
const TIE_M := Vector3(1.6, 0.08, 0.22)
const TIE_EVERY_M := 0.5
const BALLAST_W := 1.9
const LIFT_M := 0.04
const BALLAST_COLOR := Color(0.42, 0.4, 0.38)
const TIE_COLOR := Color(0.36, 0.25, 0.16)
const BAR_COLOR := Color(0.55, 0.55, 0.58)
const OIL_COLOR := Color(0.03, 0.03, 0.035)
const VISIBLE_UNTIL_M := 700.0

var _simulation: Simulation
var _config: GameConfig
var _material := StandardMaterial3D.new()
var _oil_material := StandardMaterial3D.new()
## ilha → o nó do trilho dela; e os campos de petróleo.
var _rails: Dictionary[int, MeshInstance3D] = {}
var _oil: Dictionary[int, MeshInstance3D] = {}


func setup(simulation: Simulation, config: GameConfig) -> void:
	_simulation = simulation
	_config = config
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 0.75
	_oil_material.albedo_color = OIL_COLOR
	_oil_material.roughness = 0.05
	_oil_material.metallic = 0.3
	EventBus.rails_changed.connect(_rebuild_island)
	EventBus.world_replaced.connect(rebuild)
	EventBus.building_placed.connect(func(_id: int) -> void: _rebuild_oil())
	EventBus.building_removed.connect(func(_id: int) -> void: _rebuild_oil())
	rebuild()


func rebuild() -> void:
	for index: int in _simulation.world.islands.size():
		_rebuild_island(index)
	_rebuild_oil()


func rail_mesh(island_id: int) -> Mesh:
	var node: MeshInstance3D = _rails.get(island_id)
	return node.mesh if node != null else null


func oil_patch_count() -> int:
	var total := 0
	for node: MeshInstance3D in _oil.values():
		total += 1 if node.mesh != null else 0
	return total


func _rebuild_island(island_id: int) -> void:
	if _rails.has(island_id):
		_rails[island_id].queue_free()
		_rails.erase(island_id)
	var grid := _simulation.world.island(island_id)
	if grid == null:
		return
	var cells := grid.rail_cells()
	if cells.is_empty():
		return
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell: Vector2i in cells:
		var center := _ground(grid, grid.cell_world(cell))
		var linked := false
		for side: Vector2i in SIDES:
			if grid.has_rail(cell + side):
				linked = true
				_segment(tool, grid, center, Vector3(side.x, 0.0, side.y))
		if not linked:
			_segment(tool, grid, center, Vector3.RIGHT)
			_segment(tool, grid, center, Vector3.LEFT)
	var node := MeshInstance3D.new()
	node.name = "Rails_%d" % island_id
	node.mesh = tool.commit()
	node.material_override = _material
	node.visibility_range_end = VISIBLE_UNTIL_M
	add_child(node)
	_rails[island_id] = node


## Meio trecho de trilho do meio da célula até o lado (direction), com lastro, dormentes e as barras, seguindo o chão.
func _segment(tool: SurfaceTool, grid: IslandGrid, center: Vector3, direction: Vector3) -> void:
	var half := grid.cell_size * 0.5
	var end_flat := center + direction * half
	var end := _ground(grid, end_flat)
	var across := direction.cross(Vector3.UP).normalized()
	# lastro: faixa um pouco acima do chão
	_quad(tool, center + across * BALLAST_W * 0.5, center - across * BALLAST_W * 0.5, end - across * BALLAST_W * 0.5,
			end + across * BALLAST_W * 0.5, BALLAST_COLOR)
	var ties := maxi(1, roundi(half / TIE_EVERY_M))
	for k: int in ties:
		var at := center.lerp(end, (k + 0.5) / ties)
		_box(tool, at + Vector3(0.0, TIE_M.y * 0.5, 0.0), across * TIE_M.x * 0.5, direction * TIE_M.z * 0.5, TIE_M.y, TIE_COLOR)
	for bar_side: float in [-0.5, 0.5]:
		var offset := across * GAUGE_M * bar_side
		var mid := center.lerp(end, 0.5) + offset + Vector3(0.0, TIE_M.y + BAR_M.y * 0.5, 0.0)
		var along := (end - center) * 0.5
		_box(tool, mid, across * BAR_M.x * 0.5, along, BAR_M.y, BAR_COLOR)


## A altura do chão desenhado no ponto (com o detalhe das encostas), um pouco acima.
func _ground(grid: IslandGrid, point: Vector3) -> Vector3:
	var y := grid.height_at(point.x, point.z)
	if not grid.flat:
		y += TerrainDetail.offset_at(grid, _config, point.x, point.z)
	return Vector3(point.x, y + LIFT_M, point.z)


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.set_color(color)
		tool.set_normal(Vector3.UP)
		tool.add_vertex(point)


## Caixa centrada em center, com meias medidas nos eixos x_half e z_half (no plano) e altura height.
static func _box(tool: SurfaceTool, center: Vector3, x_half: Vector3, z_half: Vector3, height: float, color: Color) -> void:
	var up := Vector3(0.0, height * 0.5, 0.0)
	var corners: Array[Vector3] = [-x_half - z_half, x_half - z_half, x_half + z_half, -x_half + z_half]
	# tampa
	_quad(tool, center + corners[0] + up, center + corners[1] + up, center + corners[2] + up, center + corners[3] + up, color)
	# lados
	for i: int in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var normal := ((a + b) * 0.5).normalized()
		for point: Vector3 in [center + a - up, center + a + up, center + b + up, center + a - up, center + b + up, center + b - up]:
			tool.set_color(color.darkened(0.12))
			tool.set_normal(normal)
			tool.add_vertex(point)


## Os campos de petróleo sem prédio em cima: três manchas escuras sobrepostas em cada um.
func _rebuild_oil() -> void:
	for node: MeshInstance3D in _oil.values():
		node.queue_free()
	_oil.clear()
	for island_id: int in _simulation.world.islands.size():
		var grid := _simulation.world.island(island_id)
		if grid.oil_spots.is_empty():
			continue
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var any := false
		for spot: int in grid.oil_spots:
			var cell := grid.cell_at(spot)
			if grid.building_at(cell) != 0:
				continue
			any = true
			var center := _ground(grid, grid.cell_world(cell))
			for k: int in 3:
				var offset := Vector3(cos(k * 2.1) * 0.9, 0.01 * k, sin(k * 2.1) * 0.9)
				_puddle(tool, center + offset, 1.1 - k * 0.2)
		if not any:
			continue
		var node := MeshInstance3D.new()
		node.name = "Oil_%d" % island_id
		node.mesh = tool.commit()
		node.material_override = _oil_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = VISIBLE_UNTIL_M
		add_child(node)
		_oil[island_id] = node


static func _puddle(tool: SurfaceTool, center: Vector3, radius: float) -> void:
	var sides := 10
	for i: int in sides:
		var a := TAU * i / sides
		var b := TAU * (i + 1) / sides
		for point: Vector3 in [center, center + Vector3(cos(b), 0.0, sin(b)) * radius, center + Vector3(cos(a), 0.0, sin(a)) * radius]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(point)
