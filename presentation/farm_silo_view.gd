class_name FarmSiloView
extends Node3D
## Fase 117: os silos das fazendas. Ao lado de cada fazenda de FARMS, na célula livre e quase plana encostada nela mais
## perto do meio da face de trás (sem prédio, estrada, trilho, árvore, largo, alameda nem mesa de taverna), um silo de
## aduelas com arcos de ferro e telhado cônico ou uma caixa d'água de madeira sobre quatro pés com escoras, pelo id da
## fazenda (`cells`, `silo_mesh`, `tank_mesh`). O recheio deixa a célula limpa (`ScatterView.island_context`). Só a ilha
## com relevo; nada no save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

enum Kind { SILO, TANK }

const FARMS: Array[StringName] = [&"wheat_farm", &"potato_farm", &"hop_farm", &"sheep_farm", &"pig_farm", &"vineyard"]
const MAX_RELIEF_M := 0.8
## O silo afunda um pouco no chão (a célula não é plana de todo).
const SINK_M := 0.15
const SILO_RADIUS_M := 1.0
const SILO_HEIGHT_M := 5.2
const SILO_STAVES := 16
const HOOPS := 4
const ROOF_RISE_M := 1.1
const TANK_RADIUS_M := 0.95
const TANK_HEIGHT_M := 1.5
const LEGS_M := 3.2
## Fase 127: a cisterna do cais (cistern_mesh).
const CISTERN_RADIUS_M := 0.95
const CISTERN_HEIGHT_M := 1.9
const STAVE_LIGHT := Color(0.58, 0.45, 0.31)
const STAVE_DARK := Color(0.5, 0.38, 0.26)
const IRON := Color(0.2, 0.2, 0.21)
const ROOF := Color(0.36, 0.33, 0.31)
const STONE := Color(0.6, 0.58, 0.54)
const LEG_WOOD := Color(0.4, 0.3, 0.2)

var _simulation: Simulation
var _layers: Dictionary[int, MultiMeshInstance3D] = {}
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	for kind: int in Kind.values():
		var mesh := silo_mesh() if kind == Kind.SILO else tank_mesh()
		mesh.surface_set_material(0, material)
		var layer := MultiMeshInstance3D.new()
		layer.name = "Silos" if kind == Kind.SILO else "Tanks"
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = mesh
		add_child(layer)
		_layers[kind] = layer
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func count(kind: int) -> int:
	return _layers[kind].multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places: Dictionary[int, Array] = {Kind.SILO: [], Kind.TANK: []}
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var farm_id: int = found[cell]
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			var x := grid.origin_m.x + (cell.x + 0.5) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + 0.5) * grid.cell_size
			var turn := Basis(Vector3.UP, fposmod(float(absi(hash([farm_id, 3])) % 360), 360.0) * PI / 180.0)
			var list: Array = places[kind_of(farm_id)]
			list.append(Transform3D(turn, Vector3(x, corners.x - SINK_M, z)))
	for kind: int in _layers:
		var multimesh := _layers[kind].multimesh
		var list: Array = places[kind]
		multimesh.instance_count = list.size()
		for i: int in list.size():
			var place: Transform3D = list[i]
			multimesh.set_instance_transform(i, place)
		multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## Silo ou caixa d'água, pelo id da fazenda (dois silos para cada caixa; o hash puxava demais para um lado com ids pequenos).
static func kind_of(farm_id: int) -> int:
	return Kind.SILO if posmod(farm_id, 3) != 0 else Kind.TANK


## A célula do silo de cada fazenda da ilha → o id da fazenda: das livres encostadas nela (lados e cantos), de terra, sem
## árvore, fora do largo, da alameda e das mesas e quase planas, a mais perto do meio da face de trás. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id in FARMS:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	taken.merge(ForecourtView.cells(world, data, island_id))
	taken.merge(AvenueView.cells(world, island_id))
	for cell: Vector2i in TavernGardenView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 136: nem no trilho e no monte de rejeito das minas
	for cell: Vector2i in SpoilTipView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 139: nem nas redes de pesca
	for cell: Vector2i in FishNetView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var size := Vector2(area.size)
		var back := Vector2(area.position) + size * 0.5 - Vector2(Footprint.front_direction(record.rotation)) \
				* (maxf(size.x, size.y) * 0.5 + 0.5)
		var best := Vector2i(-1, -1)
		var best_m := INF
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
				var meters := (Vector2(cell) + Vector2(0.5, 0.5)).distance_squared_to(back)
				if meters < best_m:
					best_m = meters
					best = cell
		if best_m < INF:
			result[best] = id
	return result


## O silo de aduelas: soco de pedra, o corpo em SILO_STAVES aduelas de tons alternados, HOOPS arcos de ferro, a portinhola
## de cima e o telhado cônico com o remate.
static func silo_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3.ZERO, Vector3(0.0, 0.45, 0.0), SILO_RADIUS_M + 0.08, STONE, SILO_STAVES)
	_staves(tool, 0.45, SILO_HEIGHT_M, SILO_RADIUS_M)
	for k: int in HOOPS:
		var y := 0.45 + (SILO_HEIGHT_M - 0.45) * (k + 0.5) / HOOPS
		VertexShapes.cylinder(tool, Vector3(0.0, y - 0.04, 0.0), Vector3(0.0, y + 0.04, 0.0), SILO_RADIUS_M + 0.03, IRON,
				SILO_STAVES)
	VertexShapes.box(tool, Vector3(0.0, SILO_HEIGHT_M - 0.9, SILO_RADIUS_M + 0.02), Vector3(0.3, 0.4, 0.04), LEG_WOOD)
	_cone(tool, SILO_HEIGHT_M, SILO_RADIUS_M + 0.18, ROOF_RISE_M, ROOF)
	VertexShapes.cylinder(tool, Vector3(0.0, SILO_HEIGHT_M + ROOF_RISE_M - 0.05, 0.0),
			Vector3(0.0, SILO_HEIGHT_M + ROOF_RISE_M + 0.35, 0.0), 0.05, IRON, 6)
	tool.generate_normals()
	return tool.commit()


## A caixa d'água: quatro pés de LEGS_M com as escoras em xis, o estrado, a tina de aduelas com os arcos e a tampa cônica.
static func tank_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spread := TANK_RADIUS_M * 0.8
	var feet: Array[Vector3] = [Vector3(-spread, 0.0, -spread), Vector3(spread, 0.0, -spread), Vector3(spread, 0.0, spread),
			Vector3(-spread, 0.0, spread)]
	for i: int in feet.size():
		var foot := feet[i]
		var top := foot * 0.85 + Vector3(0.0, LEGS_M, 0.0)
		VertexShapes.strut(tool, foot, top, 0.09, 0.09, LEG_WOOD)
		var next := feet[(i + 1) % feet.size()]
		var next_top := next * 0.85 + Vector3(0.0, LEGS_M, 0.0)
		VertexShapes.strut(tool, foot + Vector3(0.0, 0.3, 0.0), next_top - Vector3(0.0, 0.3, 0.0), 0.04, 0.04, LEG_WOOD)
		VertexShapes.strut(tool, next + Vector3(0.0, 0.3, 0.0), top - Vector3(0.0, 0.3, 0.0), 0.04, 0.04, LEG_WOOD)
	VertexShapes.box(tool, Vector3(0.0, LEGS_M + 0.06, 0.0), Vector3(spread + 0.25, 0.06, spread + 0.25), LEG_WOOD)
	_staves(tool, LEGS_M + 0.12, LEGS_M + 0.12 + TANK_HEIGHT_M, TANK_RADIUS_M)
	for k: int in 2:
		var y := LEGS_M + 0.12 + TANK_HEIGHT_M * (0.25 + 0.5 * k)
		VertexShapes.cylinder(tool, Vector3(0.0, y - 0.04, 0.0), Vector3(0.0, y + 0.04, 0.0), TANK_RADIUS_M + 0.03, IRON,
				SILO_STAVES)
	_cone(tool, LEGS_M + 0.12 + TANK_HEIGHT_M, TANK_RADIUS_M + 0.1, 0.5, ROOF)
	# a escada de mão encostada num pé
	var ladder := feet[0] + Vector3(-0.35, 0.0, 0.0)
	for side: float in [-0.18, 0.18]:
		VertexShapes.strut(tool, ladder + Vector3(0.0, 0.0, side), ladder + Vector3(0.25, LEGS_M + 0.1, side), 0.03, 0.03,
				LEG_WOOD)
	for rung: int in 9:
		var t := (rung + 0.5) / 9.0
		var at := ladder + Vector3(0.25 * t, (LEGS_M + 0.1) * t, 0.0)
		VertexShapes.strut(tool, at + Vector3(0.0, 0.0, -0.18), at + Vector3(0.0, 0.0, 0.18), 0.02, 0.02, LEG_WOOD)
	tool.generate_normals()
	return tool.commit()


## Fase 127: a cisterna do cais — baixa e larga, de aduelas com três arcos, sobre um soco de pedra, com a tampa cônica
## rasa e uma bica de ferro; de raio CISTERN_RADIUS_M e altura CISTERN_HEIGHT_M, a base em y = 0.
static func cistern_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := CISTERN_RADIUS_M
	VertexShapes.cylinder(tool, Vector3.ZERO, Vector3(0.0, 0.35, 0.0), radius + 0.1, STONE, SILO_STAVES)
	_staves(tool, 0.35, CISTERN_HEIGHT_M, radius)
	for k: int in 3:
		var y := 0.35 + (CISTERN_HEIGHT_M - 0.35) * (k + 0.5) / 3.0
		VertexShapes.cylinder(tool, Vector3(0.0, y - 0.035, 0.0), Vector3(0.0, y + 0.035, 0.0), radius + 0.03, IRON,
				SILO_STAVES)
	_cone(tool, CISTERN_HEIGHT_M, radius + 0.08, 0.32, ROOF)
	VertexShapes.strut(tool, Vector3(radius, 0.6, 0.0), Vector3(radius + 0.25, 0.55, 0.0), 0.03, 0.03, IRON)
	tool.generate_normals()
	return tool.commit()


## O corpo de aduelas de y0 a y1, com as aduelas em tons alternados (faces chapadas).
static func _staves(tool: SurfaceTool, y0: float, y1: float, radius: float) -> void:
	for i: int in SILO_STAVES:
		var a0 := TAU * i / SILO_STAVES
		var a1 := TAU * (i + 1) / SILO_STAVES
		var p0 := Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		var color := STAVE_LIGHT if i % 2 == 0 else STAVE_DARK
		VertexShapes.quad(tool, p0 + Vector3(0.0, y0, 0.0), p1 + Vector3(0.0, y0, 0.0), p1 + Vector3(0.0, y1, 0.0),
				p0 + Vector3(0.0, y1, 0.0), color)


## O telhado cônico de base em y, com o beiral de raio radius e o topo rise acima, fechado por baixo.
static func _cone(tool: SurfaceTool, y: float, radius: float, rise: float, color: Color) -> void:
	var apex := Vector3(0.0, y + rise, 0.0)
	var center := Vector3(0.0, y, 0.0)
	for i: int in SILO_STAVES:
		var a0 := TAU * i / SILO_STAVES
		var a1 := TAU * (i + 1) / SILO_STAVES
		var p0 := Vector3(cos(a0) * radius, y, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, y, sin(a1) * radius)
		VertexShapes.tri(tool, apex, p0, p1, color)
		VertexShapes.tri(tool, center, p1, p0, color)
