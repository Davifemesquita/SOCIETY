class_name RoadView
extends MultiMeshInstance3D
## Estradas de terra e de paralelepípedo (cinza, Fase 8) como ladrilhos num MultiMesh (todas as ilhas), refeito quando a rede muda.
## No relevo o ladrilho inclina com o terreno (a base tem cisalhamento, a espessura fica de pé);
## sobre o rio vira ponte de tábuas, plana, na altura das margens.
## Fase 14: a rua de paralelepípedo ganha meio-fio de pedra nos lados que não dão para outra estrada, e a de
## terra, dois sulcos de roda na direção dela (no shader, pelo dado da instância).

const DIRT_COLOR := Color(0.55, 0.45, 0.33)
const BRIDGE_COLOR := Color(0.36, 0.26, 0.17)
const PAVED_COLOR := Color(0.3, 0.3, 0.33)
const THICKNESS_M := 0.08
## O ladrilho fica um pouco acima do chão, para não brigar com o terreno.
const LIFT_M := 0.06
## Meio-fio: largura, altura acima do calçamento e cor da pedra.
const CURB_WIDTH_M := 0.22
const CURB_HEIGHT_M := 0.1
const CURB_COLOR := Color(0.58, 0.57, 0.54)
## Direção dos sulcos no dado da instância (b): nenhum, ao longo de x, ao longo de z, os dois (cruzamento).
enum Ruts { NONE, ALONG_X, ALONG_Z, BOTH }
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _cell_size: float
var _curbs := MultiMeshInstance3D.new()


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
	var curb := BoxMesh.new()
	curb.size = Vector3(CURB_WIDTH_M, THICKNESS_M + CURB_HEIGHT_M, cell_size)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = CURB_COLOR
	stone.roughness = 0.9
	curb.material = stone
	_curbs.name = "Curbs"
	_curbs.multimesh = MultiMesh.new()
	_curbs.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_curbs.multimesh.mesh = curb
	add_child(_curbs)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: rebuild())
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	var tiles: Array[Transform3D] = []
	var colors: Array[Color] = []
	var kinds: Array[Color] = []
	var curbs: Array[Transform3D] = []
	for grid: IslandGrid in _simulation.world.islands:
		for cell: Vector2i in grid.road_cells():
			var bridge := grid.ground_at(cell) == IslandGrid.Ground.RIVER
			var paved := grid.is_paved(cell)
			var tile := tile_transform(grid, cell)
			tiles.append(tile)
			colors.append(BRIDGE_COLOR if bridge else (PAVED_COLOR if paved else DIRT_COLOR))
			kinds.append(Color(1.0 if paved else 0.0, 1.0 if bridge else 0.0, float(ruts(grid, cell)), 0.0))
			if paved and not bridge:
				for side: Vector2i in SIDES:
					if not grid.has_road(cell + side):
						curbs.append(tile * curb_place(side, _cell_size))
	multimesh.instance_count = tiles.size()
	for i: int in tiles.size():
		multimesh.set_instance_transform(i, tiles[i])
		multimesh.set_instance_color(i, colors[i])
		multimesh.set_instance_custom_data(i, kinds[i])
	_curbs.multimesh.instance_count = curbs.size()
	for i: int in curbs.size():
		_curbs.multimesh.set_instance_transform(i, curbs[i])


func tile_count() -> int:
	return multimesh.instance_count


func curb_count() -> int:
	return _curbs.multimesh.instance_count


## Para onde vão os sulcos de roda da célula: ao longo da rua reta, os dois no cruzamento e na curva,
## nenhum na célula solta.
static func ruts(grid: IslandGrid, cell: Vector2i) -> int:
	var along_x := grid.has_road(cell + Vector2i(1, 0)) or grid.has_road(cell + Vector2i(-1, 0))
	var along_z := grid.has_road(cell + Vector2i(0, 1)) or grid.has_road(cell + Vector2i(0, -1))
	if along_x and along_z:
		return Ruts.BOTH
	if along_x:
		return Ruts.ALONG_X
	return Ruts.ALONG_Z if along_z else Ruts.NONE


## O meio-fio do lado side, no referencial do ladrilho: encostado na borda, de pé sobre o calçamento.
static func curb_place(side: Vector2i, cell_size: float) -> Transform3D:
	var basis := Basis.IDENTITY if side.x != 0 else Basis(Vector3.UP, PI * 0.5)
	var out := Vector3(side.x, 0.0, side.y) * (cell_size * 0.5 - CURB_WIDTH_M * 0.5)
	return Transform3D(basis, out + Vector3(0.0, CURB_HEIGHT_M * 0.5, 0.0))


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
