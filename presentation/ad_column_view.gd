class_name AdColumnView
extends Node3D
## Fase 150: a coluna de anúncios. Numa célula livre (sem prédio, estrada, trilho nem árvore) encostada em rua de
## paralelepípedo por dois lados que se cruzam — o canto de dentro de uma esquina calçada —, uma a cada COLUMN_EVERY pelo
## desenho da grade (`cells`), fora do largo, da alameda, das mesas, das bombas e dos outros enfeites, uma coluna redonda de
## cartazes: o soco escuro, o fuste coberto de cartazes de cores desencontradas em duas fiadas (sem texto: só cor e
## moldura), a cornija e o chapéu de ferro em cúpula com o remate (`column_mesh`), no canto da célula junto da esquina.
## O recheio deixa a célula limpa. Um MultiMesh do arquipélago; nada no save; refeito na obra, na demolição, na estrada, no
## trilho, na derrubada de árvores e ao trocar de mundo.

const COLUMN_EVERY := 2
const RADIUS_M := 0.45
const SHAFT_M := 2.5
const SIDES := 16
## A coluna fica tanto do meio da célula para o canto da esquina.
const CORNER_M := 0.35
const POSTERS: Array[Color] = [Color(0.86, 0.8, 0.66), Color(0.72, 0.2, 0.16), Color(0.82, 0.62, 0.22),
		Color(0.24, 0.34, 0.55), Color(0.9, 0.88, 0.82), Color(0.35, 0.5, 0.32)]
const IRON := Color(0.16, 0.24, 0.2)
const DARK := Color(0.22, 0.22, 0.23)

var _simulation: Simulation
var _columns := MultiMeshInstance3D.new()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.75
	var mesh := column_mesh()
	mesh.surface_set_material(0, material)
	_columns.name = "AdColumns"
	_columns.multimesh = MultiMesh.new()
	_columns.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_columns.multimesh.mesh = mesh
	add_child(_columns)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func column_count() -> int:
	return _columns.multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places: Array[Transform3D] = []
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var corner: Vector2i = found[cell]
			var middle := grid.cell_world(cell)
			var at := Vector3(middle.x + corner.x * CORNER_M, 0.0, middle.z + corner.y * CORNER_M)
			at.y = grid.height_at(at.x, at.z) if not grid.flat else 0.0
			var turn := Basis(Vector3.UP, float(posmod(cell.x * 13 + cell.y * 7, 16)) * TAU / 16.0)
			places.append(Transform3D(turn, at))
	var multimesh := _columns.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As células das colunas da ilha → o canto da esquina (a soma dos dois lados de rua calçada, cada um −1, 0 ou 1).
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var taken: Dictionary[Vector2i, bool] = {}
	var looked := false
	# só as células calçadas (o find anda no array em C++; o laço pela ilha inteira pesava na obra e no carregar)
	var index := grid.roads.find(IslandGrid.Road.PAVED)
	while index >= 0:
		var road := grid.cell_at(index)
		index = grid.roads.find(IslandGrid.Road.PAVED, index + 1)
		# a célula ao lado da rua (em x) que também encosta em rua calçada em z: o canto de dentro da esquina
		for diagonal: Vector2i in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var cell := road + Vector2i(diagonal.x, 0)
			if result.has(cell) or posmod(cell.x * 7 + cell.y * 11, COLUMN_EVERY) != 0:
				continue
			var side_a := Vector2i(-diagonal.x, 0)
			var side_b := Vector2i(0, diagonal.y)
			if not _paved(grid, cell + side_a) or not _paved(grid, cell + side_b):
				continue
			if not _free(grid, cell):
				continue
			if not looked:
				# as células dos outros enfeites, só quando há candidata
				taken = _taken(world, data, island_id)
				looked = true
			if taken.has(cell):
				continue
			result[cell] = side_a + side_b
	return result


static func _paved(grid: IslandGrid, cell: Vector2i) -> bool:
	return grid.in_bounds(cell) and grid.roads[grid.index(cell)] == IslandGrid.Road.PAVED


static func _free(grid: IslandGrid, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell) or not grid.is_land(cell):
		return false
	var index := grid.index(cell)
	return grid.occupancy[index] == 0 and grid.roads[index] == IslandGrid.Road.NONE and grid.rails[index] == 0 \
			and (grid.flat or grid.trees[index] == 0)


## As células já tomadas por outros enfeites (o largo, a alameda, as mesas, os silos, as bombas e o resto).
static func _taken(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var taken: Dictionary[Vector2i, bool] = {}
	taken.merge(ForecourtView.cells(world, data, island_id))
	taken.merge(AvenueView.cells(world, island_id))
	for cell: Vector2i in TavernGardenView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in WaterPumpView.cells(world, data, island_id):
		taken[cell] = true
	return taken


## A coluna com o pé no zero: o soco escuro, o fuste de cartazes (SIDES faces, duas fiadas, cada cartaz numa cor, com a
## moldura escura entre eles), a cornija, o chapéu em cúpula de ferro e o remate.
static func column_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3.ZERO, Vector3(0.0, 0.3, 0.0), RADIUS_M + 0.08, DARK, SIDES)
	var rows: Array[Vector2] = [Vector2(0.3, 1.35), Vector2(1.4, 2.45)]
	VertexShapes.cylinder(tool, Vector3(0.0, 0.3, 0.0), Vector3(0.0, SHAFT_M, 0.0), RADIUS_M - 0.01, DARK, SIDES)
	for r: int in rows.size():
		var row := rows[r]
		var k := 0
		while k < SIDES:
			var width := 2 + (k + r) % 3
			var color := POSTERS[(k * 5 + r * 3 + width) % POSTERS.size()]
			var last := mini(k + width, SIDES)
			# a figura do cartaz (sem texto): uma faixa de outro tom no meio dele, acompanhando a curva da coluna
			var inner := color.darkened(0.35) if color.get_luminance() > 0.5 else color.lightened(0.4)
			var band := Vector2(lerpf(row.x, row.y, 0.3), lerpf(row.x, row.y, 0.62))
			for s: int in range(k, last):
				var f0 := float(s) + (0.35 if s == k else 0.0)
				var f1 := float(s + 1) - (0.35 if s == last - 1 else 0.0)
				var b0 := TAU * (f0 + r * 0.5) / SIDES
				var b1 := TAU * (f1 + r * 0.5) / SIDES
				var m0 := Vector3(cos(b0), 0.0, sin(b0)) * (RADIUS_M + 0.006)
				var m1 := Vector3(cos(b1), 0.0, sin(b1)) * (RADIUS_M + 0.006)
				VertexShapes.quad(tool, m0 + Vector3(0.0, band.x, 0.0), m1 + Vector3(0.0, band.x, 0.0),
						m1 + Vector3(0.0, band.y, 0.0), m0 + Vector3(0.0, band.y, 0.0), inner)
			for s: int in range(k, last):
				var a0 := TAU * (s + r * 0.5) / SIDES
				var a1 := TAU * (s + 1 + r * 0.5) / SIDES
				var d0 := Vector3(cos(a0), 0.0, sin(a0)) * RADIUS_M
				var d1 := Vector3(cos(a1), 0.0, sin(a1)) * RADIUS_M
				var low := row.x + 0.04
				var high := row.y - 0.04
				VertexShapes.quad(tool, d0 + Vector3(0.0, low, 0.0), d1 + Vector3(0.0, low, 0.0),
						d1 + Vector3(0.0, high, 0.0), d0 + Vector3(0.0, high, 0.0), color)
			k = last
	VertexShapes.cylinder(tool, Vector3(0.0, SHAFT_M, 0.0), Vector3(0.0, SHAFT_M + 0.12, 0.0), RADIUS_M + 0.1, IRON, SIDES)
	var rings := 4
	for k: int in rings:
		var t0 := float(k) / rings
		var t1 := float(k + 1) / rings
		var r0 := (RADIUS_M + 0.1) * cos(t0 * PI * 0.5)
		var r1 := (RADIUS_M + 0.1) * cos(t1 * PI * 0.5)
		var y0 := SHAFT_M + 0.12 + 0.45 * sin(t0 * PI * 0.5)
		var y1 := SHAFT_M + 0.12 + 0.45 * sin(t1 * PI * 0.5)
		for s: int in SIDES:
			var a0 := TAU * s / SIDES
			var a1 := TAU * (s + 1) / SIDES
			var p0 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p1 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var q0 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var q1 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			VertexShapes.quad(tool, p0, p1, q1, q0, IRON)
	var top := SHAFT_M + 0.57
	VertexShapes.cylinder(tool, Vector3(0.0, top - 0.02, 0.0), Vector3(0.0, top + 0.18, 0.0), 0.03, IRON, 6)
	VertexShapes.box(tool, Vector3(0.0, top + 0.24, 0.0), Vector3(0.06, 0.06, 0.06), Color(0.8, 0.64, 0.25))
	tool.generate_normals()
	return tool.commit()
