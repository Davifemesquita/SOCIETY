class_name RoadView
extends MultiMeshInstance3D
## Estradas de terra e de paralelepípedo (cinza, Fase 8) como ladrilhos num MultiMesh (todas as ilhas), refeito quando a rede muda.
## No relevo o ladrilho inclina com o terreno (a base tem cisalhamento, a espessura fica de pé);
## sobre o rio vira ponte de tábuas, plana, na altura das margens.

const DIRT_COLOR := Color(0.55, 0.45, 0.33)
const BRIDGE_COLOR := Color(0.36, 0.26, 0.17)
const PAVED_COLOR := Color(0.3, 0.3, 0.33)
const THICKNESS_M := 0.08
## O ladrilho fica um pouco acima do chão, para não brigar com o terreno.
const LIFT_M := 0.06

var _simulation: Simulation
var _cell_size: float


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	var tile := BoxMesh.new()
	tile.size = Vector3(cell_size, THICKNESS_M, cell_size)
	# Fase 9: terra batida e paralelepípedo da Poly Haven; a ponte fica na cor da tábua
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/road.gdshader") as Shader
	material.set_shader_parameter(&"albedo_rough", load("res://assets/materials/roads_albedo_rough.png"))
	material.set_shader_parameter(&"normals", load("res://assets/materials/roads_normal.png"))
	tile.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = tile
	EventBus.roads_changed.connect(func(_island_id: int) -> void: rebuild())
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	var tiles: Array[Transform3D] = []
	var colors: Array[Color] = []
	var kinds: Array[Color] = []
	for grid: IslandGrid in _simulation.world.islands:
		for cell: Vector2i in grid.road_cells():
			var bridge := grid.ground_at(cell) == IslandGrid.Ground.RIVER
			tiles.append(tile_transform(grid, cell))
			colors.append(BRIDGE_COLOR if bridge else (PAVED_COLOR if grid.is_paved(cell) else DIRT_COLOR))
			kinds.append(Color(1.0 if grid.is_paved(cell) else 0.0, 1.0 if bridge else 0.0, 0.0, 0.0))
	multimesh.instance_count = tiles.size()
	for i: int in tiles.size():
		multimesh.set_instance_transform(i, tiles[i])
		multimesh.set_instance_color(i, colors[i])
		multimesh.set_instance_custom_data(i, kinds[i])


func tile_count() -> int:
	return multimesh.instance_count


## Ladrilho da célula: centro na altura da estrada; fora do rio, inclinado como o plano dos
## quatro cantos (cisalhamento: x e z sobem com a ladeira, y fica de pé).
static func tile_transform(grid: IslandGrid, cell: Vector2i) -> Transform3D:
	var center := grid.surface_world(cell) + Vector3(0.0, LIFT_M + THICKNESS_M * 0.5, 0.0)
	if grid.ground_at(cell) == IslandGrid.Ground.RIVER or grid.flat:
		return Transform3D(Basis.IDENTITY, center)
	var size := grid.cell_size
	var slope_x := ((grid.corner_height(cell.x + 1, cell.y) + grid.corner_height(cell.x + 1, cell.y + 1))
			- (grid.corner_height(cell.x, cell.y) + grid.corner_height(cell.x, cell.y + 1))) * 0.5 / size
	var slope_z := ((grid.corner_height(cell.x, cell.y + 1) + grid.corner_height(cell.x + 1, cell.y + 1))
			- (grid.corner_height(cell.x, cell.y) + grid.corner_height(cell.x + 1, cell.y))) * 0.5 / size
	return Transform3D(Basis(Vector3(1.0, slope_x, 0.0), Vector3.UP, Vector3(0.0, slope_z, 1.0)), center)
