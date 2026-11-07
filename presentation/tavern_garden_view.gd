class_name TavernGardenView
extends Node3D
## Fase 116: as mesas da taverna. Nas células livres e quase planas encostadas na taverna (sem prédio, estrada, trilho,
## árvore, largo calçado nem alameda), até MAX_TABLES por taverna, as mais perto da frente primeiro (`cells`), uma mesa
## redonda com dois bancos e um guarda-sol listrado (`sets`): de dia aberto, em gomos brancos e na cor da taverna (pelo
## id, de PARASOL_COLORS); à noite fechado em volta da haste. O recheio deixa essas células limpas
## (`ScatterView.island_context`). Só a ilha com relevo; nada no save; refeito na obra, na demolição, na estrada, na
## derrubada de árvores e ao trocar de mundo.

const TAVERNS: Array[StringName] = [&"tavern"]
const MAX_TABLES := 6
const MAX_RELIEF_M := 0.6
const TABLE_TOP_M := 0.75
const TABLE_RADIUS_M := 0.45
const BENCH_M := Vector3(1.1, 0.42, 0.28)
const BENCH_GAP_M := 0.62
const POLE_M := 2.35
const CANOPY_RADIUS_M := 0.92
const CANOPY_RISE_M := 0.42
const CANOPY_SEGMENTS := 8
const FURLED_RADIUS_M := 0.11
const FURLED_DROP_M := 0.9
## A noite (DayClock.night_factor) a partir da qual os guarda-sóis ficam fechados.
const FURL_AT := 0.5
const WOOD := Color(0.47, 0.34, 0.22)
const DARK_WOOD := Color(0.35, 0.25, 0.17)
const POLE_COLOR := Color(0.85, 0.82, 0.74)
const CANVAS_WHITE := Color(0.93, 0.91, 0.85)
const PARASOL_COLORS: Array[Color] = [Color(0.7, 0.16, 0.13), Color(0.16, 0.42, 0.25), Color(0.17, 0.3, 0.55),
		Color(0.85, 0.62, 0.15)]

var _simulation: Simulation
var _sets := MultiMeshInstance3D.new()
var _white := MultiMeshInstance3D.new()
var _tint := MultiMeshInstance3D.new()
var _furled := MultiMeshInstance3D.new()
var _dirty := true
var _closed := false


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var parts: Array = [[_sets, "Tables", set_mesh(), false], [_white, "CanopyWhite", canopy_mesh(false), false],
			[_tint, "CanopyTint", canopy_mesh(true), true], [_furled, "Furled", furled_mesh(), true]]
	for part: Array in parts:
		var layer: MultiMeshInstance3D = part[0]
		var mesh: ArrayMesh = part[2]
		mesh.surface_set_material(0, material)
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = part[3]
		layer.multimesh.mesh = mesh
		add_child(layer)
	_furled.visible = false
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func table_count() -> int:
	return _sets.multimesh.instance_count


func is_furled() -> bool:
	return _closed


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _simulation == null:
		return
	if _dirty:
		rebuild()
	set_furled(DayClock.night_factor(_simulation.config, GameClock.clock.hour()) >= FURL_AT)


## Abre (de dia) ou fecha (à noite) os guarda-sóis.
func set_furled(closed: bool) -> void:
	_closed = closed
	_white.visible = not closed
	_tint.visible = not closed
	_furled.visible = closed


func rebuild() -> void:
	_dirty = false
	var places: Array[Transform3D] = []
	var colors: Array[Color] = []
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var taken := cells(world, _simulation.data, island_id)
		for cell: Vector2i in taken:
			var x := grid.origin_m.x + (cell.x + 0.5) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + 0.5) * grid.cell_size
			var turn := Basis(Vector3.UP, PI * 0.5 * (absi(hash(cell)) % 2) + 0.15 * ((absi(hash([cell, 1])) % 5) - 2))
			places.append(Transform3D(turn, Vector3(x, grid.height_at(x, z), z)))
			colors.append(PARASOL_COLORS[absi(taken[cell]) % PARASOL_COLORS.size()])
	for layer: MultiMeshInstance3D in [_sets, _white, _tint, _furled]:
		var multimesh := layer.multimesh
		multimesh.instance_count = places.size()
		for i: int in places.size():
			multimesh.set_instance_transform(i, places[i])
			if multimesh.use_colors:
				multimesh.set_instance_color(i, colors[i])
		multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As células das mesas na ilha → o id da taverna (que dá a cor dos guarda-sóis): em volta de cada taverna, as livres
## encostadas nela (lados e cantos), de terra, sem árvore, fora do largo calçado e da alameda e quase planas, até
## MAX_TABLES, as mais perto da frente primeiro. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var taken: Dictionary[Vector2i, bool] = {}
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id in TAVERNS:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	taken.merge(ForecourtView.cells(world, data, island_id))
	taken.merge(AvenueView.cells(world, island_id))
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var size := Vector2(area.size)
		var door := Vector2(area.position) + size * 0.5 + Vector2(front) * (maxf(size.x, size.y) * 0.5 + 1.0)
		var candidates: Array[Vector2i] = []
		var ring := area.grow(1)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				if area.has_point(cell) or not grid.in_bounds(cell) or taken.has(cell) or result.has(cell):
					continue
				var index := grid.index(cell)
				if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
						or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				candidates.append(cell)
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da := (Vector2(a) + Vector2(0.5, 0.5)).distance_squared_to(door)
			var db := (Vector2(b) + Vector2(0.5, 0.5)).distance_squared_to(door)
			return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
		for cell: Vector2i in candidates.slice(0, MAX_TABLES):
			result[cell] = id
	return result


## A mesa redonda no pé central, os dois bancos dos lados (em x) e a haste do guarda-sol, no meio da célula.
static func set_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3(0.0, TABLE_TOP_M - 0.05, 0.0), Vector3(0.0, TABLE_TOP_M, 0.0), TABLE_RADIUS_M, WOOD, 12)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, TABLE_TOP_M - 0.05, 0.0), 0.06, DARK_WOOD, 6)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.05, 0.0), 0.25, DARK_WOOD, 8)
	for side: float in [-1.0, 1.0]:
		var middle := Vector3(side * BENCH_GAP_M, BENCH_M.y, 0.0)
		VertexShapes.box(tool, middle, Vector3(BENCH_M.z * 0.5, 0.03, BENCH_M.x * 0.5), WOOD)
		for end: float in [-1.0, 1.0]:
			VertexShapes.box(tool, Vector3(side * BENCH_GAP_M, BENCH_M.y * 0.5, end * BENCH_M.x * 0.4),
					Vector3(BENCH_M.z * 0.45, BENCH_M.y * 0.5, 0.03), DARK_WOOD)
	VertexShapes.cylinder(tool, Vector3(0.0, TABLE_TOP_M, 0.0), Vector3(0.0, POLE_M + CANOPY_RISE_M, 0.0), 0.025,
			POLE_COLOR, 6)
	tool.generate_normals()
	return tool.commit()


## O guarda-sol aberto: CANOPY_SEGMENTS gomos do aro (em POLE_M) ao topo; tinted escolhe os gomos ímpares (a cor da
## taverna, pela instância) ou os pares (brancos).
static func canopy_mesh(tinted: bool) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := Vector3(0.0, POLE_M + CANOPY_RISE_M, 0.0)
	for i: int in CANOPY_SEGMENTS:
		if (i % 2 == 1) != tinted:
			continue
		var a0 := TAU * i / CANOPY_SEGMENTS
		var a1 := TAU * (i + 1) / CANOPY_SEGMENTS
		var p0 := Vector3(cos(a0) * CANOPY_RADIUS_M, POLE_M, sin(a0) * CANOPY_RADIUS_M)
		var p1 := Vector3(cos(a1) * CANOPY_RADIUS_M, POLE_M, sin(a1) * CANOPY_RADIUS_M)
		var color := Color.WHITE if tinted else CANVAS_WHITE
		VertexShapes.tri(tool, apex, p1, p0, color)
		# a aba caída na borda do gomo
		var drop := Vector3(0.0, -0.12, 0.0)
		VertexShapes.quad(tool, p0, p1, p1 + drop, p0 + drop, color)
	tool.generate_normals()
	return tool.commit()


## O guarda-sol fechado: um fuso estreito pendendo do topo da haste, na cor da taverna.
static func furled_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0.0, POLE_M + CANOPY_RISE_M, 0.0)
	var belly := Vector3(0.0, POLE_M + CANOPY_RISE_M - FURLED_DROP_M * 0.65, 0.0)
	var bottom := Vector3(0.0, POLE_M + CANOPY_RISE_M - FURLED_DROP_M, 0.0)
	for i: int in CANOPY_SEGMENTS:
		var a0 := TAU * i / CANOPY_SEGMENTS
		var a1 := TAU * (i + 1) / CANOPY_SEGMENTS
		var r0 := Vector3(cos(a0), 0.0, sin(a0)) * FURLED_RADIUS_M
		var r1 := Vector3(cos(a1), 0.0, sin(a1)) * FURLED_RADIUS_M
		VertexShapes.tri(tool, top, belly + r1, belly + r0, Color.WHITE)
		VertexShapes.tri(tool, bottom, belly + r0, belly + r1, Color.WHITE)
	tool.generate_normals()
	return tool.commit()
