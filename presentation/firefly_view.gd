class_name FireflyView
extends Node3D
## Fase 178: os vaga-lumes. Numa rede de pontos de SWARM_STEP células (cada um deslocado pelo hash), o ponto em terra sem árvore,
## sem prédio, estrada nem trilho a até CLEAR_CELLS células vira um enxame — mais na beira da mata (FOREST_CHANCE) que no capim
## aberto (OPEN_CHANCE) —, com FLIES pontinhos espalhados até SPREAD_M em volta, de LOW_M a HIGH_M acima do chão (`swarms`,
## `flies`). O `shaders/firefly.gdshader` os faz vagar e piscar no tempo visual, acesos com a noite. Um MultiMesh do arquipélago,
## escondido de dia; nada no save; refeito (só quando à vista) na obra, na demolição, na estrada, nas árvores e ao trocar de mundo.

const SWARM_STEP := 6
const CLEAR_CELLS := 2
const FOREST_CHANCE := 0.5
const OPEN_CHANCE := 0.12
const FLIES := 12
const SPREAD_M := 3.2
const LOW_M := 0.35
const HIGH_M := 1.5
## A partir de quanto da noite (DayClock.night_factor) eles aparecem.
const SHOW_AT := 0.12

var _simulation: Simulation
var _flies := MultiMeshInstance3D.new()
## Onde fica cada vaga-lume (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Vector3] = []
## Os vaga-lumes de cada ilha (refeitos só na ilha que mudou: IslandDirty).
var _by_island: Dictionary[int, Array] = {}
var _changes := IslandDirty.new()


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/firefly.gdshader") as Shader
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_flies.name = "Fireflies"
	_flies.multimesh = MultiMesh.new()
	_flies.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_flies.multimesh.use_custom_data = true
	_flies.multimesh.mesh = quad
	_flies.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_flies.material_override = material
	_flies.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flies.visible = false
	add_child(_flies)
	EventBus.building_placed.connect(_mark_building)
	EventBus.building_removed.connect(_mark_building)
	EventBus.roads_changed.connect(_mark_island)
	EventBus.trees_changed.connect(_mark_area)
	EventBus.world_replaced.connect(_on_world_replaced)


func fly_count() -> int:
	return places.size()


func _mark_building(building_id: int) -> void:
	_changes.mark_building(_simulation.world, building_id)


func _mark_island(island_id: int) -> void:
	_changes.mark_island(island_id)


func _mark_area(island_id: int, _area: Rect2i) -> void:
	_changes.mark_island(island_id)


func _on_world_replaced() -> void:
	_by_island.clear()
	_changes.mark_all()


func _process(_delta: float) -> void:
	if _simulation == null:
		return
	var night := DayClock.night_factor(_simulation.config, GameClock.clock.hour())
	_flies.visible = night >= SHOW_AT
	if _flies.visible and _changes.pending():
		rebuild()


func rebuild() -> void:
	places.clear()
	var world := _simulation.world
	for island_id: int in _changes.take(world):
		_by_island[island_id] = flies(world, island_id)
	for island_id: int in world.islands.size():
		if _by_island.has(island_id):
			var list: Array[Vector3] = _by_island[island_id]
			places.append_array(list)
	var multimesh := _flies.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, places[i]))
		var seed := cell_hash(i, 0, 0, 178)
		multimesh.set_instance_custom_data(i, Color(float(seed % 997) / 997.0, float(seed / 997 % 991) / 991.0,
				float(seed / 997 / 991 % 13) / 13.0, 0.0))


## O meio de cada enxame da ilha (mundo, no chão). Vazio na ilha plana.
static func swarms(world: WorldState, island_id: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var width := grid.size.x
	var height := grid.size.y
	var ground := grid.ground
	var trees := grid.trees
	var roads := grid.roads
	var rails := grid.rails
	var occupancy := grid.occupancy
	for y: int in range(CLEAR_CELLS, height - CLEAR_CELLS, SWARM_STEP):
		for x: int in range(CLEAR_CELLS, width - CLEAR_CELLS, SWARM_STEP):
			var pick := cell_hash(island_id, x, y, 1781)
			var cell := Vector2i(clampi(x + pick % 3 - 1, CLEAR_CELLS, width - 1 - CLEAR_CELLS),
					clampi(y + pick / 3 % 3 - 1, CLEAR_CELLS, height - 1 - CLEAR_CELLS))
			var index := cell.y * width + cell.x
			if ground[index] != IslandGrid.Ground.LAND or trees[index] > 0:
				continue
			var forest := false
			var clear := true
			for dy: int in range(-CLEAR_CELLS, CLEAR_CELLS + 1):
				for dx: int in range(-CLEAR_CELLS, CLEAR_CELLS + 1):
					var j := index + dy * width + dx
					if occupancy[j] != 0 or roads[j] != IslandGrid.Road.NONE or rails[j] != 0:
						clear = false
					if trees[j] > 0:
						forest = true
			if not clear:
				continue
			var chance := FOREST_CHANCE if forest else OPEN_CHANCE
			if float(pick / 9 % 1000) / 1000.0 >= chance:
				continue
			var at := grid.cell_world(cell)
			result.append(Vector3(at.x, grid.height_at(at.x, at.z), at.z))
	return result


## Os vaga-lumes da ilha (mundo): FLIES por enxame, espalhados em volta do meio dele e acima do chão.
static func flies(world: WorldState, island_id: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var grid := world.island(island_id)
	for center: Vector3 in swarms(world, island_id):
		var random := RandomNumberGenerator.new()
		random.seed = cell_hash(island_id, roundi(center.x * 10.0), roundi(center.z * 10.0), 1782)
		for k: int in FLIES:
			var angle := random.randf() * TAU
			var reach := sqrt(random.randf()) * SPREAD_M
			var x := center.x + cos(angle) * reach
			var z := center.z + sin(angle) * reach
			result.append(Vector3(x, grid.height_at(x, z) + random.randf_range(LOW_M, HIGH_M), z))
	return result


## Hash inteiro de uma célula (sem o hash() de um Array, que custava dezenas de ms ao passar por todas as ilhas): positivo, de
## 32 bits.
static func cell_hash(island_id: int, x: int, y: int, salt: int) -> int:
	var h := (x * 374761393 + y * 668265263 + island_id * 1442695041 + salt * 2246822519) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return h ^ (h >> 16)
