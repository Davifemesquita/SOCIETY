class_name BeehiveView
extends Node3D
## Fase 190: as colmeias de palha. Ao lado de cada fazenda de FARMS, na célula livre e quase plana encostada nela mais perto do
## meio da face de −X da frente (o lado oposto ao das medas de feno da Fase 166; sem prédio, estrada, trilho nem árvore, fora do
## largo, da alameda, das mesas, dos silos, das medas e das outras peças de célula), o banco de tábua com três colmeias de palha
## trançada em sino, cada uma com a boca escura (`cells`, `hive_mesh`), e as abelhas zunindo em volta de dia
## (`shaders/bee.gdshader`: pontinhos escuros rodando depressa em volta das bocas, no tempo visual). O recheio deixa a célula
## limpa. Só a ilha com relevo; dois MultiMesh; nada no save; refeito na obra, na demolição, na estrada e ao trocar de mundo.

const FARMS: Array[StringName] = [&"hop_farm", &"vineyard", &"potato_farm"]
const MAX_RELIEF_M := 0.8
const BEES_PER_HIVE := 12
## A colmeia: o raio do pé, a altura e as fiadas de palha; o banco.
const SKEP_RADIUS_M := 0.26
const SKEP_M := 0.5
const SIDES := 12
const BENCH_M := 0.42
const STRAW := Color(0.74, 0.6, 0.34)
const STRAW_DARK := Color(0.58, 0.45, 0.24)
const MOUTH := Color(0.08, 0.06, 0.04)
const WOOD := Color(0.42, 0.32, 0.22)
## Até quanto da noite as abelhas voam.
const HIDE_AT := 0.3

var _simulation: Simulation
var _hives := MultiMeshInstance3D.new()
var _bees := MultiMeshInstance3D.new()
## Os lugares dos bancos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_hives.name = "Beehives"
	_hives.multimesh = MultiMesh.new()
	_hives.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_hives.multimesh.mesh = hive_mesh()
	_hives.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_hives.material_override = material
	add_child(_hives)
	var bee_material := ShaderMaterial.new()
	bee_material.shader = load("res://shaders/bee.gdshader") as Shader
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_bees.name = "Bees"
	_bees.multimesh = MultiMesh.new()
	_bees.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_bees.multimesh.use_custom_data = true
	_bees.multimesh.mesh = quad
	_bees.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_bees.material_override = bee_material
	_bees.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bees)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func hive_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _simulation == null:
		return
	if _dirty:
		rebuild()
	_bees.visible = DayClock.night_factor(_simulation.config, GameClock.clock.hour()) < HIDE_AT


func rebuild() -> void:
	_dirty = false
	places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			var middle := grid.cell_world(cell)
			var turn := float(posmod(found[cell] * 41, 360)) * PI / 180.0
			places.append(Transform3D(Basis(Vector3.UP, turn), Vector3(middle.x, corners.x - 0.03, middle.z)))
	_hives.multimesh.instance_count = places.size()
	_bees.multimesh.instance_count = places.size() * BEES_PER_HIVE
	for i: int in places.size():
		_hives.multimesh.set_instance_transform(i, places[i])
		for k: int in BEES_PER_HIVE:
			# cada abelha em volta da boca de uma das colmeias
			var mouth := places[i] * (_skep_at(k % 3) + Vector3(0.0, SKEP_M * 0.25, -SKEP_RADIUS_M))
			var index := i * BEES_PER_HIVE + k
			_bees.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, mouth))
			var seed := FireflyView.cell_hash(i, k, 0, 190)
			_bees.multimesh.set_instance_custom_data(index, Color(float(seed % 997) / 997.0,
					float(seed / 997 % 991) / 991.0, float(seed / 997 / 991 % 13) / 13.0, 0.0))


## A célula das colmeias de cada fazenda da ilha → o id da fazenda. Vazio na ilha plana.
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
			RainBarrelView.cells(world, data, island_id), HaystackView.cells(world, data, island_id)]:
		for cell: Vector2i in source:
			taken[cell] = true
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var left := Vector2(front.y, -front.x)
		var size := Vector2(area.size)
		var side := Vector2(area.position) + size * 0.5 + left * (maxf(size.x, size.y) * 0.5 + 0.5)
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


## O pé da colmeia k (0 a 2) no banco, no referencial dele.
static func _skep_at(k: int) -> Vector3:
	return Vector3((k - 1) * 0.6, BENCH_M + 0.03, 0.0)


## O banco com o pé no zero, ao longo de x, e as três colmeias de palha em sino em cima dele, a boca para −z.
static func hive_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, BENCH_M, 0.0), Vector3(0.95, 0.03, 0.22), WOOD)
	for x: float in [-0.8, 0.8]:
		for z: float in [-0.15, 0.15]:
			VertexShapes.strut(tool, Vector3(x, 0.0, z), Vector3(x, BENCH_M - 0.03, z), 0.03, 0.03, WOOD)
	# [altura, raio] do sino, em frações da colmeia
	var profile: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(0.3, 1.02), Vector2(0.55, 0.92), Vector2(0.75, 0.74),
			Vector2(0.9, 0.48), Vector2(0.98, 0.2), Vector2(1.0, 0.0)]
	for k: int in 3:
		var foot := _skep_at(k)
		for level: int in profile.size() - 1:
			var low := profile[level]
			var high := profile[level + 1]
			var color := STRAW if level % 2 == 0 else STRAW_DARK
			for i: int in SIDES:
				var a0 := TAU * i / SIDES
				var a1 := TAU * (i + 1) / SIDES
				var p0 := Vector3(cos(a0), 0.0, -sin(a0))
				var p1 := Vector3(cos(a1), 0.0, -sin(a1))
				VertexShapes.quad(tool, foot + p0 * low.y * SKEP_RADIUS_M + Vector3.UP * low.x * SKEP_M,
						foot + p0 * high.y * SKEP_RADIUS_M + Vector3.UP * high.x * SKEP_M,
						foot + p1 * high.y * SKEP_RADIUS_M + Vector3.UP * high.x * SKEP_M,
						foot + p1 * low.y * SKEP_RADIUS_M + Vector3.UP * low.x * SKEP_M, color)
		# a boca escura na frente, embaixo
		VertexShapes.box(tool, foot + Vector3(0.0, 0.04, -SKEP_RADIUS_M), Vector3(0.05, 0.03, 0.015), MOUTH)
	tool.generate_normals()
	return tool.commit()
