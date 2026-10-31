class_name ManholeView
extends Node3D
## Fase 131: os bueiros. Nas células de paralelepípedo, uma a cada MANHOLE_EVERY pelo desenho da grade
## (`posmod(5x + 3y, MANHOLE_EVERY) = 0`, fora das células dos postes de gás e dos postes dos fios), e só onde a célula tem
## estrada dos dois lados de uma direção (o meio da rua, não a esquina nem a ponta), uma tampa redonda de ferro fundido
## rente ao calçamento, com o aro e a grade em cruz (`cells`, `cover_mesh`). Sem ponte (a ponte de pedra tem o tabuleiro
## dela). Só apresentação; nada no save; refeito quando a estrada muda e ao trocar de mundo.

const MANHOLE_EVERY := 7
const RADIUS_M := 0.42
const RIM_M := 0.06
## Acima do chão: o calçamento da grade dual (PavedDual.LIFT_M) e mais um pouco, para a tampa ficar rente a ele.
const LIFT_M := PavedDual.LIFT_M + 0.015
const SIDES := 16
const IRON := Color(0.17, 0.17, 0.18)
const IRON_DARK := Color(0.1, 0.1, 0.11)

var _simulation: Simulation
var _covers := MultiMeshInstance3D.new()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.55
	material.metallic = 0.5
	var mesh := cover_mesh()
	mesh.surface_set_material(0, material)
	_covers.name = "Manholes"
	_covers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_covers.multimesh = MultiMesh.new()
	_covers.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_covers.multimesh.mesh = mesh
	add_child(_covers)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func cover_count() -> int:
	return _covers.multimesh.instance_count


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places: Array[Transform3D] = []
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for cell: Vector2i in cells(grid):
			var at := grid.cell_world(cell)
			at.y = grid.height_at(at.x, at.z) if not grid.flat else grid.road_height(cell)
			places.append(Transform3D(Basis(Vector3.UP, float(posmod(cell.x * 13 + cell.y * 7, 8)) * PI / 4.0),
					at + Vector3(0.0, LIFT_M, 0.0)))
	var multimesh := _covers.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As células com bueiro na ilha: calçadas, da vez pelo desenho da grade, no meio de uma rua reta (estrada dos dois lados
## numa direção) e fora do rio.
static func cells(grid: IslandGrid) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if grid == null or grid.roads.is_empty():
		return result
	var start := grid.roads.find(IslandGrid.Road.PAVED)
	if start < 0:
		return result
	for index: int in range(start, grid.roads.size()):
		if grid.roads[index] != IslandGrid.Road.PAVED:
			continue
		var cell := grid.cell_at(index)
		if posmod(5 * cell.x + 3 * cell.y, MANHOLE_EVERY) != 0:
			continue
		# a célula do poste de gás (Fase 13) e a do poste dos fios (Fase 120): a tampa ficava debaixo do pé deles
		var lamp_rest := posmod(cell.x + 3 * cell.y, LampView.LAMP_EVERY)
		if lamp_rest == 0 or lamp_rest == PowerLineView.POLE_REST:
			continue
		if not grid.ground.is_empty() and grid.ground[index] == IslandGrid.Ground.RIVER:
			continue
		var along_x := grid.has_road(cell + Vector2i(1, 0)) and grid.has_road(cell + Vector2i(-1, 0))
		var along_y := grid.has_road(cell + Vector2i(0, 1)) and grid.has_road(cell + Vector2i(0, -1))
		if along_x != along_y:
			result.append(cell)
	return result


## A tampa: o disco de ferro, o aro mais alto em volta e a grade em cruz com dois anéis, deitados em y = 0.
static func cover_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3(0.0, -0.03, 0.0), Vector3(0.0, 0.0, 0.0), RADIUS_M, IRON_DARK, SIDES)
	for i: int in SIDES:
		var a0 := TAU * i / SIDES
		var a1 := TAU * (i + 1) / SIDES
		var inner := RADIUS_M - RIM_M
		var p0 := Vector3(cos(a0), 0.0, sin(a0))
		var p1 := Vector3(cos(a1), 0.0, sin(a1))
		VertexShapes.quad(tool, p0 * inner + Vector3(0.0, 0.012, 0.0), p0 * RADIUS_M + Vector3(0.0, 0.012, 0.0),
				p1 * RADIUS_M + Vector3(0.0, 0.012, 0.0), p1 * inner + Vector3(0.0, 0.012, 0.0), IRON)
	for k: int in 2:
		var angle := PI * 0.5 * k
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		VertexShapes.strut(tool, -dir * (RADIUS_M - RIM_M) + Vector3(0.0, 0.008, 0.0),
				dir * (RADIUS_M - RIM_M) + Vector3(0.0, 0.008, 0.0), 0.025, 0.006, IRON)
	for ring: float in [0.45, 0.75]:
		for i: int in SIDES:
			var a0 := TAU * i / SIDES
			var a1 := TAU * (i + 1) / SIDES
			var r := (RADIUS_M - RIM_M) * ring
			VertexShapes.strut(tool, Vector3(cos(a0) * r, 0.008, sin(a0) * r), Vector3(cos(a1) * r, 0.008, sin(a1) * r),
					0.018, 0.006, IRON)
	tool.generate_normals()
	return tool.commit()
