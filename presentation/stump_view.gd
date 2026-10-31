class_name StumpView
extends Node3D
## Fase 140: a clareira do lenhador. Em volta de cada lenhador (até `lumberjack_radius_cells` da área dele), parte das
## células de mata fica cortada no desenho (`cut_cells`: mais perto da cabana, mais cortada, pela chance de RING_CHANCE e
## o hash): a `TreeView` não desenha as árvores delas, e aqui elas ganham um toco no lugar de cada árvore (o mesmo ponto
## sorteado da `TreeView._transform`) e, numa a cada LOG_EVERY, uma tora caída ao lado (`stump_mesh`, `log_mesh`). Só o
## desenho: as árvores continuam na simulação (o lenhador as conta). Um MultiMesh de tocos e um de toras por trecho de
## CHUNK_CELLS da ilha, com o alcance de visibilidade dos detalhes. Os lenhadores ficam guardados pelo id: só um lenhador
## que entra ou sai (ou árvores que caem perto de um) refaz a vista, e só na ilha dele. Nada no save.

## Chance de a célula de mata estar cortada, pela distância em células até a área do lenhador (1 a 5).
const RING_CHANCE: Array[float] = [0.0, 0.95, 0.8, 0.55, 0.35, 0.2]
const CHUNK_CELLS := 64
const LOG_EVERY := 3
const STUMP_RADIUS_M := 0.2
const STUMP_HEIGHT_M := 0.38
const LOG_LENGTH_M := 2.2
const LOG_RADIUS_M := 0.16
const BARK := Color(0.33, 0.25, 0.18)
const WOOD := Color(0.78, 0.65, 0.44)
const SIDES := 9

var _simulation: Simulation
## ilha → os nós dela (tocos e toras de cada trecho).
var _layers: Dictionary[int, Array] = {}
## lenhador → ilha.
var _lumberjacks: Dictionary[int, int] = {}
var _stump_mesh: ArrayMesh
var _log_mesh: ArrayMesh
var _stumps := 0
var _logs := 0
## Ilhas a refazer no quadro seguinte.
var _dirty: Dictionary[int, bool] = {}


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_stump_mesh = stump_mesh()
	_stump_mesh.surface_set_material(0, material)
	_log_mesh = log_mesh()
	_log_mesh.surface_set_material(0, material)
	EventBus.building_placed.connect(_on_building_changed)
	EventBus.building_removed.connect(_on_building_changed)
	EventBus.trees_changed.connect(_on_trees_changed)
	# Fase 148: uma estrada pode mudar o lugar do terreiro do lenhador (sem toco)
	EventBus.roads_changed.connect(func(island_id: int) -> void:
		if _lumberjacks.values().has(island_id):
			_dirty[island_id] = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func stump_count() -> int:
	return _stumps


func log_count() -> int:
	return _logs


## Um lenhador entrou ou saiu: a ilha dele fica para o quadro seguinte. Outros prédios não mexem na clareira.
func _on_building_changed(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record != null and record.def_id == &"lumberjack":
		_lumberjacks[building_id] = record.island_id
		_dirty[record.island_id] = true
	elif _lumberjacks.has(building_id):
		_dirty[_lumberjacks[building_id]] = true
		_lumberjacks.erase(building_id)


## Árvores caíram: só refaz se foi perto de um lenhador.
func _on_trees_changed(island_id: int, area: Rect2i) -> void:
	var reach := _simulation.config.lumberjack_radius_cells + 3
	for id: int in _lumberjacks:
		if _lumberjacks[id] != island_id:
			continue
		var record := _simulation.world.building(id)
		if record != null and Rect2i(record.origin, Vector2i(3, 3)).grow(reach).intersects(area):
			_dirty[island_id] = true
			return


func _process(_delta: float) -> void:
	if _dirty.is_empty() or _simulation == null:
		return
	refresh()


## Refaz já as ilhas marcadas (testes; o jogo espera o quadro seguinte).
func refresh() -> void:
	for island_id: int in _dirty:
		_build_island(island_id)
	_dirty.clear()


func rebuild() -> void:
	_dirty.clear()
	_lumberjacks.clear()
	var world := _simulation.world
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.def_id == &"lumberjack":
			_lumberjacks[id] = record.island_id
	for island_id: int in _layers.keys():
		_clear_island(island_id)
	_stumps = 0
	_logs = 0
	for island_id: int in world.islands.size():
		_build_island(island_id)


func _clear_island(island_id: int) -> void:
	var nodes: Array = _layers.get(island_id, [])
	for layer: MultiMeshInstance3D in nodes:
		if layer.multimesh.mesh == _stump_mesh:
			_stumps -= layer.multimesh.instance_count
		else:
			_logs -= layer.multimesh.instance_count
		remove_child(layer)
		layer.queue_free()
	_layers.erase(island_id)


## Refaz os tocos e as toras da ilha, num par de MultiMesh por trecho com clareira.
func _build_island(island_id: int) -> void:
	_clear_island(island_id)
	var world := _simulation.world
	var grid := world.island(island_id)
	if grid == null:
		return
	var ids: Array[int] = []
	for id: int in _lumberjacks:
		if _lumberjacks[id] == island_id:
			ids.append(id)
	if ids.is_empty():
		return
	var cut := cut_cells_of(world, _simulation.data, _simulation.config, island_id, ids)
	# Fase 148: o terreiro do lenhador fica sem toco nem tora
	var yards: Dictionary[Vector2i, bool] = {}
	for id: int in ids:
		if world.building(id) == null:
			continue
		var yard: Variant = LumberYardView.cell_of(world, _simulation.data, world.building(id))
		if yard is Array:
			var pair: Array = yard
			var yard_cell: Vector2i = pair[0]
			yards[yard_cell] = true
	var stumps: Dictionary[Vector2i, Array] = {}
	var logs: Dictionary[Vector2i, Array] = {}
	for cell: Vector2i in cut:
		if yards.has(cell):
			continue
		var chunk := cell / CHUNK_CELLS
		if not stumps.has(chunk):
			stumps[chunk] = []
			logs[chunk] = []
		var list: Array = stumps[chunk]
		list.append_array(stump_places(grid, island_id, cell))
		var fallen: Variant = log_place(grid, island_id, cell)
		if fallen is Transform3D:
			var log_list: Array = logs[chunk]
			log_list.append(fallen)
	var range_m := _simulation.config.building_detail_range_m
	var nodes: Array = []
	for chunk: Vector2i in stumps:
		var stump_list: Array = stumps[chunk]
		var log_list: Array = logs[chunk]
		nodes.append(_layer("Stumps_%d_%d_%d" % [island_id, chunk.x, chunk.y], _stump_mesh, stump_list, range_m))
		_stumps += stump_list.size()
		if not log_list.is_empty():
			nodes.append(_layer("Logs_%d_%d_%d" % [island_id, chunk.x, chunk.y], _log_mesh, log_list, range_m))
			_logs += log_list.size()
	_layers[island_id] = nodes


func _layer(name_text: String, mesh: Mesh, places: Array, range_m: float) -> MultiMeshInstance3D:
	var layer := MultiMeshInstance3D.new()
	layer.name = name_text
	layer.multimesh = MultiMesh.new()
	layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	layer.multimesh.mesh = mesh
	layer.multimesh.instance_count = places.size()
	for i: int in places.size():
		var place: Transform3D = places[i]
		layer.multimesh.set_instance_transform(i, place)
	layer.visibility_range_end = range_m
	add_child(layer)
	return layer


## As células de mata cortadas no desenho na ilha → o lenhador delas (procura os lenhadores entre os prédios).
static func cut_cells(world: WorldState, data: GameData, config: GameConfig, island_id: int) -> Dictionary[Vector2i, int]:
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == &"lumberjack":
			ids.append(id)
	return cut_cells_of(world, data, config, island_id, ids)


## As células de mata cortadas pelos lenhadores ids da ilha: em volta da área de cada um, até o raio, as células com
## árvore que o hash escolhe pela chance do anel (a do lenhador de menor id fica). Vazio na ilha plana.
static func cut_cells_of(world: WorldState, data: GameData, config: GameConfig, island_id: int,
		ids: Array[int]) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var sorted := ids.duplicate()
	sorted.sort()
	var radius := mini(config.lumberjack_radius_cells, RING_CHANCE.size() - 1)
	for id: int in sorted:
		var record := world.building(id)
		if record == null:
			continue
		var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
		var reach := area.grow(radius)
		for y: int in range(reach.position.y, reach.end.y):
			for x: int in range(reach.position.x, reach.end.x):
				var cell := Vector2i(x, y)
				if area.has_point(cell) or not grid.in_bounds(cell) or result.has(cell):
					continue
				if grid.trees[grid.index(cell)] == 0:
					continue
				var ring := maxi(maxi(area.position.x - x, x - area.end.x + 1), maxi(area.position.y - y, y - area.end.y + 1))
				var chance := RING_CHANCE[clampi(ring, 0, radius)]
				if float(absi(hash([id, cell])) % 1000) / 1000.0 < chance:
					result[cell] = id
	# Fase 148: o terreiro de cada lenhador fica cortado inteiro (sem árvore no desenho; a StumpView não põe toco nele)
	for id: int in sorted:
		var record := world.building(id)
		if record == null:
			continue
		var yard: Variant = LumberYardView.cell_of(world, data, record)
		if yard is Array:
			var pair: Array = yard
			var cell: Vector2i = pair[0]
			if grid.trees[grid.index(cell)] > 0:
				result[cell] = id
	return result


## Os tocos da célula cortada: um no ponto de cada árvore que a TreeView desenharia ali, girado e na escala do hash.
static func stump_places(grid: IslandGrid, island_id: int, cell: Vector2i) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var index := grid.index(cell)
	for n: int in mini(grid.trees[index], TreeView.DRAWN_PER_CELL):
		var seed_value := hash([island_id, index, n])
		var floats := TreeView._transform(grid, cell, seed_value, 1.0)
		var at := Vector3(floats[3], floats[7] + 0.05, floats[11])
		var scale := 0.8 + float(seed_value / 13 % 50) / 100.0
		result.append(Transform3D(Basis(Vector3.UP, float(seed_value % 360) * PI / 180.0).scaled(Vector3.ONE * scale), at))
	return result


## A tora caída da célula (numa a cada LOG_EVERY pelo hash), deitada no chão num rumo sorteado, ou null.
static func log_place(grid: IslandGrid, island_id: int, cell: Vector2i) -> Variant:
	var noise := absi(hash([island_id, cell, &"tora"]))
	if noise % LOG_EVERY != 0:
		return null
	var middle := grid.cell_world(cell)
	var offset := Vector2(float(noise / 7 % 100) / 100.0 - 0.5, float(noise / 700 % 100) / 100.0 - 0.5) * grid.cell_size * 0.4
	var x := middle.x + offset.x
	var z := middle.z + offset.y
	var turn := Basis(Vector3.UP, float(noise / 70000 % 360) * PI / 180.0)
	return Transform3D(turn, Vector3(x, grid.height_at(x, z) + LOG_RADIUS_M * 0.8, z))


## O toco, com o pé no zero: o tronco de casca um pouco mais largo embaixo, três raízes abrindo no chão e o corte claro,
## um pouco inclinado, em cima.
static func stump_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low: Array[Vector3] = []
	var high: Array[Vector3] = []
	for k: int in SIDES:
		var angle := TAU * k / SIDES
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		low.append(direction * STUMP_RADIUS_M * 1.25 + Vector3(0.0, -0.05, 0.0))
		# o corte inclinado: mais alto de um lado
		high.append(direction * STUMP_RADIUS_M + Vector3(0.0, STUMP_HEIGHT_M + direction.x * 0.06, 0.0))
	for k: int in SIDES:
		var j := (k + 1) % SIDES
		VertexShapes.quad(tool, low[k], low[j], high[j], high[k], BARK)
		VertexShapes.tri(tool, high[k], high[j], Vector3(0.0, STUMP_HEIGHT_M, 0.0), WOOD)
	for k: int in 3:
		var angle := TAU * k / 3.0 + 0.4
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		VertexShapes.strut(tool, direction * STUMP_RADIUS_M * 0.6 + Vector3(0.0, 0.1, 0.0),
				direction * STUMP_RADIUS_M * 2.3 + Vector3(0.0, -0.04, 0.0), 0.05, 0.04, BARK)
	tool.generate_normals()
	return tool.commit()


## A tora deitada ao longo de x, com o meio na origem: o tronco de casca e as duas pontas cortadas, claras.
static func log_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LOG_LENGTH_M * 0.5
	VertexShapes.cylinder(tool, Vector3(-half, 0.0, 0.0), Vector3(half, 0.0, 0.0), LOG_RADIUS_M, BARK, SIDES)
	for end: float in [-1.0, 1.0]:
		VertexShapes.cylinder(tool, Vector3(end * half, 0.0, 0.0), Vector3(end * (half + 0.01), 0.0, 0.0),
				LOG_RADIUS_M * 0.92, WOOD, SIDES)
	tool.generate_normals()
	return tool.commit()
