class_name RoadFenceView
extends Node3D
## Fase 339: as cercas de mourão na beira das estradas de campo. Nas estradas de terra das ilhas com relevo, nas células de um trecho
## reto (`MilestoneView._straight_axis`), sem casa a até `SignpostView.TOWN_CELLS` células (fora das vilas): a estrada se divide em
## blocos de BLOCK_CELLS células ao longo dela, e o bloco cercado (o hash dele abaixo de FENCED_SHARE) ganha um lanço por célula na
## beira do lado sorteado, se a célula vizinha estiver livre (terra, sem estrada nem prédio) e o chão ao longo dele não subir mais
## de MAX_RISE_M. O lanço (`fence_mesh`) é um mourão em
## cada ponta e duas travessas de pau roliço de ponta a ponta, na madeira gasta, inclinado com o chão ao longo da estrada. Um
## MultiMesh; nada no save; refeito quando as estradas mudam, na obra, na demolição e ao trocar de mundo.

const BLOCK_CELLS := 4
const FENCED_SHARE := 0.35
## Quanto o lanço sai do meio da célula para a beira.
const OFFSET_M := 0.9
## Na ladeira de mais que isto ao longo do lanço, sem cerca (inclinada demais, parecia caída).
const MAX_RISE_M := 0.8
## O mourão (meia seção e altura acima do chão), as travessas (raio e alturas) e o enterrado.
const POST_HALF := 0.06
const POST_M := 0.85
const RAIL_RADIUS := 0.035
const RAIL_HEIGHTS: Array[float] = [0.38, 0.72]
const SUNK_M := 0.1
const POST_COLOR := Color(0.42, 0.36, 0.29)
const RAIL_COLOR := Color(0.5, 0.44, 0.35)

var _simulation: Simulation
var _fences := MultiMeshInstance3D.new()
## Os lugares dos lanços (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_fences.name = "RoadFences"
	_fences.multimesh = MultiMesh.new()
	_fences.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_fences.multimesh.mesh = fence_mesh()
	_fences.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_fences.material_override = material
	add_child(_fences)
	EventBus.roads_changed.connect(_mark)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func fence_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		places.append_array(fences(world, _simulation.data, island_id))
	_fences.multimesh.instance_count = places.size()
	for i: int in places.size():
		_fences.multimesh.set_instance_transform(i, places[i])


## Os lanços da ilha: o meio no chão, o +x ao longo da estrada (inclinado com o chão). Vazio na ilha plana.
static func fences(world: WorldState, data: GameData, island_id: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var houses: Array[Vector2i] = []
	var houses_ready := false
	for cell: Vector2i in grid.road_cells():
		if grid.is_paved(cell):
			continue
		var axis := MilestoneView._straight_axis(grid, cell)
		if axis == Vector2i.ZERO:
			continue
		# o bloco ao longo da estrada (e a linha dela, para duas estradas paralelas não dividirem o bloco)
		var along := cell.x if axis.x != 0 else cell.y
		var line := cell.y if axis.x != 0 else cell.x
		var block := floori(float(along) / BLOCK_CELLS)
		var noise := FireflyView.cell_hash(island_id, block, line, 339)
		if float(noise % 1000) / 1000.0 >= FENCED_SHARE:
			continue
		if not houses_ready:
			houses = SignpostView._house_cells(world, data, island_id)
			houses_ready = true
		if SignpostView._near_town(houses, cell):
			continue
		var across := Vector2i(axis.y, axis.x)
		var side := across * (1 if noise / 1000 % 2 == 0 else -1)
		var beside := cell + side
		if not grid.in_bounds(beside) or not grid.is_land(beside) or grid.has_road(beside) or grid.building_at(beside) != 0:
			continue
		var out := Vector3(side.x, 0.0, side.y)
		var dir := Vector3(axis.x, 0.0, axis.y)
		var middle := grid.surface_world(cell) + out * OFFSET_M
		var half := dir * grid.cell_size * 0.5
		var start := middle - half
		var end := middle + half
		start.y = grid.height_at(start.x, start.z)
		end.y = grid.height_at(end.x, end.z)
		if absf(end.y - start.y) > MAX_RISE_M:
			continue
		middle.y = (start.y + end.y) * 0.5
		var x := (end - start).normalized()
		var z := x.cross(Vector3.UP).normalized()
		var y := z.cross(x).normalized()
		# o +x esticado até as pontas (o lanço tem 1 m de cada lado no plano)
		var stretch := (end - start).length() / grid.cell_size
		result.append(Transform3D(Basis(x * stretch, y, z), middle))
	return result


## O lanço com o meio no zero e o +x ao longo da estrada, de −1 a +1 m: um mourão em cada ponta (enterrado SUNK_M) e as duas
## travessas de pau roliço de ponta a ponta.
static func fence_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(x * 0.97, (POST_M - SUNK_M) * 0.5, 0.0), Vector3(POST_HALF, (POST_M + SUNK_M) * 0.5,
				POST_HALF), POST_COLOR)
	for height: float in RAIL_HEIGHTS:
		VertexShapes.cylinder(tool, Vector3(-1.0, height, 0.0), Vector3(1.0, height, 0.0), RAIL_RADIUS, RAIL_COLOR, 6)
	tool.generate_normals()
	return tool.commit()
