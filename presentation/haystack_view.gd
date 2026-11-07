class_name HaystackView
extends Node3D
## Fase 166: as medas de feno. Ao lado de cada fazenda de FARMS (gado e trigo), na célula livre e quase plana encostada nela mais
## perto do meio da face do lado (a de +X da frente; sem prédio, estrada, trilho, árvore, largo, alameda, mesa de taverna, silo,
## monte de rejeito, rede, pátio de tijolos nem horta), duas medas de feno redondas — o corpo em barril e o cocuruto em cúpula,
## com a vara saindo do alto —, uma grande e uma menor, pelo id da fazenda (`cells`, `stack_mesh`). O recheio e as bombas
## deixam a célula limpa. Só a ilha com relevo; nada no save; refeito na obra, na demolição, na estrada e ao trocar de mundo.

const FARMS: Array[StringName] = [&"sheep_farm", &"pig_farm", &"wheat_farm"]
const MAX_RELIEF_M := 0.8
## A meda: o raio do pé, a altura do corpo e da cúpula, a vara e o feno em dois tons (o de cima mais queimado de sol).
const STACK_RADIUS_M := 0.72
const STACK_BODY_M := 1.1
const STACK_DOME_M := 0.75
const POLE_M := 0.45
const SIDES := 12
const HAY := Color(0.78, 0.66, 0.38)
const HAY_SUN := Color(0.7, 0.58, 0.34)
const HAY_FOOT := Color(0.6, 0.5, 0.3)
const POLE := Color(0.42, 0.32, 0.22)

var _simulation: Simulation
var _stacks := MeshInstance3D.new()
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_stacks.name = "Haystacks"
	_stacks.material_override = material
	add_child(_stacks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func stack_count() -> int:
	return _count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_count = 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			var middle := grid.cell_world(cell)
			var turn := float(posmod(found[cell] * 37, 360)) * PI / 180.0
			var place := Transform3D(Basis(Vector3.UP, turn), Vector3(middle.x, corners.x - 0.05, middle.z))
			# a grande e a menor, lado a lado na célula
			stack_mesh(tool, place * Transform3D(Basis.IDENTITY, Vector3(-0.32, 0.0, 0.1)), 1.0)
			stack_mesh(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.55, 0.0, -0.4)), 0.72)
			_count += 1
	if _count == 0:
		_stacks.mesh = null
		return
	tool.generate_normals()
	_stacks.mesh = tool.commit()


## A célula das medas de cada fazenda da ilha → o id da fazenda. Vazio na ilha plana.
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
	for source: Dictionary in [TavernGardenView.cells(world, data, island_id), FarmSiloView.cells(world, data, island_id),
			SpoilTipView.cells(world, data, island_id), FishNetView.cells(world, data, island_id),
			BrickYardView.cells(world, data, island_id), KitchenGardenView.cells(world, data, island_id),
			RainBarrelView.cells(world, data, island_id)]:
		for cell: Vector2i in source:
			taken[cell] = true
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var right := Vector2(-front.y, front.x)
		var size := Vector2(area.size)
		var side := Vector2(area.position) + size * 0.5 + right * (maxf(size.x, size.y) * 0.5 + 0.5)
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
				var meters := (Vector2(cell) + Vector2(0.5, 0.5)).distance_squared_to(side)
				if meters < best_m:
					best_m = meters
					best = cell
		if best_m < INF:
			result[best] = id
	return result


## Uma meda no referencial place (o pé no chão), em scale: o corpo em barril (largo no meio, mais estreito no pé), a cúpula em
## anéis até o cocuruto e a vara saindo dele.
static func stack_mesh(tool: SurfaceTool, place: Transform3D, scale: float) -> void:
	# [altura, raio] de baixo para cima, em frações da meda
	var profile: Array[Vector2] = [Vector2(0.0, 0.86), Vector2(0.35, 1.0), Vector2(0.75, 0.97), Vector2(1.0, 0.86),
			Vector2(1.25, 0.66), Vector2(1.45, 0.38), Vector2(1.55, 0.1)]
	var rings: Array[PackedVector3Array] = []
	for k: int in profile.size():
		var at := profile[k]
		var height := (at.x * STACK_BODY_M if at.x <= 1.0 else STACK_BODY_M + (at.x - 1.0) / 0.55 * STACK_DOME_M) * scale
		var points := PackedVector3Array()
		for i: int in SIDES:
			var angle := TAU * i / SIDES
			# o feno não é liso: cada anel um pouco torto (o ângulo anda no sentido do VertexShapes.cylinder: as faces para fora)
			var lump := 1.0 + 0.05 * sin(angle * 3.0 + k * 1.7)
			points.append(place * Vector3(cos(angle) * STACK_RADIUS_M * at.y * lump * scale, height,
					-sin(angle) * STACK_RADIUS_M * at.y * lump * scale))
		rings.append(points)
	for k: int in rings.size() - 1:
		var color := HAY_FOOT if k == 0 else (HAY_SUN if k >= 4 else HAY)
		for i: int in SIDES:
			var j := (i + 1) % SIDES
			VertexShapes.quad(tool, rings[k][i], rings[k + 1][i], rings[k + 1][j], rings[k][j], color)
	var top := place * Vector3(0.0, (STACK_BODY_M + STACK_DOME_M) * scale, 0.0)
	var last := rings[rings.size() - 1]
	for i: int in SIDES:
		VertexShapes.tri(tool, last[i], top, last[(i + 1) % SIDES], HAY_SUN)
	VertexShapes.cylinder(tool, top - place.basis.y * 0.2, top + place.basis.y * POLE_M * scale, 0.035, POLE, 5)
