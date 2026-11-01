class_name WaterPumpView
extends Node3D
## Fase 132: a bomba d'água dos bairros. Junto de uma casa a cada PUMP_EVERY (pelo id), na célula livre encostada nela que
## dá para a rua e fica mais perto da porta (sem prédio, estrada, trilho, árvore, largo, alameda, mesa nem silo, e quase
## plana), uma bomba de ferro fundido com a alavanca, a bica, a laje de pedra com o ralo e dois baldes de madeira
## (`cells`, `pump_mesh`), virada para a rua. O recheio deixa a célula limpa (`ScatterView.island_context`). Só a ilha com
## relevo; nada no save; refeito na obra, na demolição, na estrada e ao trocar de mundo.

const PUMP_EVERY := 6
const MAX_RELIEF_M := 0.6
const IRON := Color(0.13, 0.16, 0.14)
const STONE := Color(0.58, 0.56, 0.52)
const WOOD := Color(0.45, 0.33, 0.21)
const HOOP := Color(0.25, 0.25, 0.26)
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _pumps := MultiMeshInstance3D.new()
var _dirty := true

## Fase 204: as listas das buscas junto da rua (as células tomadas, as bombas, os carrinhos de feira) guardadas por ilha
## enquanto o mundo não muda. O recheio, a bomba, o poço e o carrinho as pediam várias vezes depois de cada obra, e com a cidade
## cheia cada uma percorre todos os prédios (o carregar do benchmark subiu ~0,4 s). Só com esta vista na árvore: ela esquece
## tudo a cada obra, demolição, estrada, trilho, árvore derrubada, subida de classe e troca de mundo (as vistas só refazem no
## quadro seguinte); sem ela (testes, ferramentas) nada fica guardado.
static var _memo: Dictionary = {}
static var _memo_world: WorldState = null
static var _memo_on := false


## O valor guardado em key para o mundo world, ou o de compute (guardado se a memória está ligada).
static func remembered(world: WorldState, key: String, compute: Callable) -> Variant:
	if not _memo_on:
		return compute.call()
	if _memo_world != world:
		_memo.clear()
		_memo_world = world
	if not _memo.has(key):
		_memo[key] = compute.call()
	return _memo[key]


static func forget() -> void:
	_memo.clear()


func _exit_tree() -> void:
	_memo_on = false
	_memo.clear()
	_memo_world = null


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_memo_on = true
	_memo.clear()
	for changed: Signal in [EventBus.building_placed, EventBus.building_removed, EventBus.roads_changed,
			EventBus.rails_changed, EventBus.house_upgraded]:
		changed.connect(func(_id: int) -> void: forget())
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: forget())
	EventBus.world_replaced.connect(forget)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	material.metallic = 0.2
	var mesh := pump_mesh()
	mesh.surface_set_material(0, material)
	_pumps.name = "Pumps"
	_pumps.multimesh = MultiMesh.new()
	_pumps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pumps.multimesh.mesh = mesh
	add_child(_pumps)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pump_count() -> int:
	return _pumps.multimesh.instance_count


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
			var toward: Vector2i = found[cell]
			var x := grid.origin_m.x + (cell.x + 0.5) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + 0.5) * grid.cell_size
			# a bica (−Z da malha) virada para a rua
			var basis := Basis.looking_at(Vector3(toward.x, 0.0, toward.y), Vector3.UP)
			places.append(Transform3D(basis, Vector3(x, grid.height_at(x, z), z)))
	var multimesh := _pumps.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As células das bombas na ilha → o lado da rua (para onde a bica vira): para uma casa a cada PUMP_EVERY, a célula livre
## encostada nela, com estrada num dos lados, mais perto da porta. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var found: Dictionary[Vector2i, Vector2i] = remembered(world, "pumps/%d" % island_id,
			func() -> Dictionary[Vector2i, Vector2i]: return _cells_now(world, data, island_id))
	var copy: Dictionary[Vector2i, Vector2i] = {}
	copy.merge(found)
	return copy


static func _cells_now(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.is_house() and posmod(id, PUMP_EVERY) == 0:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken := taken_cells(world, data, island_id)
	# Fases 203 e 206: nem no carrinho de feira nem no bebedouro (ficam fora de taken_cells: eles usam a lista)
	taken.merge(street_pieces(world, data, island_id))
	return beside_street(world, data, island_id, ids, taken)


## As células que outras peças já tomam em volta das casas e dos serviços (o largo, a alameda, as mesas, os silos, as hortas,
## a lenha...): a bomba e o poço da Fase 201 ficam fora delas.
static func taken_cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var found: Dictionary[Vector2i, bool] = remembered(world, "taken/%d" % island_id,
			func() -> Dictionary[Vector2i, bool]: return _taken_now(world, data, island_id))
	var copy: Dictionary[Vector2i, bool] = {}
	copy.merge(found)
	return copy


static func _taken_now(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
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
	# Fase 159: nem no pátio de tijolos das olarias
	for cell: Vector2i in BrickYardView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 163: nem nas hortas atrás das casas
	for cell: Vector2i in KitchenGardenView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 166: nem nas medas de feno
	for cell: Vector2i in HaystackView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 169: nem nos barris de chuva
	for cell: Vector2i in RainBarrelView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 171: nem na lenha na parede
	for cell: Vector2i in LogPileView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 172: nem nos carrinhos de mão
	for cell: Vector2i in WheelbarrowView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in FarmSiloView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 197: nem na casinha do cão
	for cell: Vector2i in KennelView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 214: nem nas escadas de mão
	for cell: Vector2i in LadderView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 215: nem nas tábuas das serrarias
	for cell: Vector2i in PlankStackView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 216: nem nos montes de carvão das usinas
	for cell: Vector2i in CoalHeapView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 219: nem no balanço e na gangorra das escolas
	for cell: Vector2i in PlaygroundView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 220: nem na bomba de incêndio dos quartéis
	for cell: Vector2i in FirePumpView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 221: nem nos barris da cervejaria
	for cell: Vector2i in BarrelRackView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 223: nem nos varais dos hospitais
	for cell: Vector2i in LinenView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 226: nem nos fardos de lã
	for cell: Vector2i in WoolBaleView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 228: nem nos barris de petróleo
	for cell: Vector2i in OilBarrelView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 240: nem nos lagares dos vinhedos
	for cell: Vector2i in WinePressView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 211: nem nas mós dos moinhos
	for cell: Vector2i in MillstoneView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 208: nem nas ramas de tecido
	for cell: Vector2i in TenterView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 202: nem nos secadouros de peixe
	for cell: Vector2i in FishRackView.cells(world, data, island_id):
		taken[cell] = true
	# Fase 195: nem no cemitério
	for cell: Vector2i in GraveyardView.cells(world, data, island_id):
		taken[cell] = true
	return taken


## Para cada prédio de ids (em ordem), a célula livre encostada nele (sem prédio, estrada, trilho, árvore nem uma das taken, e
## quase plana) com estrada num dos lados e mais perto da porta → o lado da rua.
static func beside_street(world: WorldState, data: GameData, island_id: int, ids: Array[int],
		taken: Dictionary[Vector2i, bool]) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var door := Vector2(Footprint.entrance_cell(record.origin, def.size, record.rotation)) + Vector2(0.5, 0.5)
		var best := Vector2i(-1, -1)
		var best_side := Vector2i.ZERO
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
				var street := Vector2i.ZERO
				for side: Vector2i in SIDES:
					if grid.has_road(cell + side):
						street = side
						break
				if street == Vector2i.ZERO:
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				var meters := (Vector2(cell) + Vector2(0.5, 0.5)).distance_squared_to(door)
				if meters < best_m:
					best_m = meters
					best = cell
					best_side = street
		if best_m < INF:
			result[best] = best_side
	return result


## A bomba de frente para −Z: a laje de pedra com o ralo, o corpo de ferro com o capitel e a tampa, a bica para a frente, a
## alavanca para trás e dois baldes de aduelas com os arcos.
static func pump_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.05, -0.15), Vector3(0.55, 0.05, 0.6), STONE)
	VertexShapes.box(tool, Vector3(0.0, 0.105, -0.45), Vector3(0.18, 0.005, 0.12), Color(0.2, 0.2, 0.2))
	VertexShapes.cylinder(tool, Vector3(0.0, 0.1, 0.1), Vector3(0.0, 1.05, 0.1), 0.085, IRON, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.1, 0.1), Vector3(0.0, 0.22, 0.1), 0.12, IRON, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, 1.05, 0.1), Vector3(0.0, 1.12, 0.1), 0.11, IRON, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, 1.12, 0.1), Vector3(0.0, 1.2, 0.1), 0.05, IRON, 8)
	# a bica: sai do corpo para a frente e desce na ponta
	VertexShapes.strut(tool, Vector3(0.0, 0.78, 0.05), Vector3(0.0, 0.78, -0.22), 0.035, 0.035, IRON)
	VertexShapes.strut(tool, Vector3(0.0, 0.8, -0.22), Vector3(0.0, 0.7, -0.25), 0.035, 0.035, IRON)
	# a alavanca: o pivô no alto e o braço descendo para trás
	VertexShapes.strut(tool, Vector3(0.0, 1.08, 0.15), Vector3(0.0, 1.22, 0.5), 0.025, 0.025, IRON)
	VertexShapes.strut(tool, Vector3(0.0, 1.22, 0.5), Vector3(0.0, 1.0, 0.72), 0.022, 0.022, IRON)
	# dois baldes, um debaixo da bica e outro ao lado
	for bucket: Vector3 in [Vector3(0.0, 0.1, -0.35), Vector3(0.32, 0.1, -0.05)]:
		VertexShapes.cylinder(tool, bucket, bucket + Vector3(0.0, 0.3, 0.0), 0.13, WOOD, 10)
		for h: float in [0.07, 0.23]:
			VertexShapes.cylinder(tool, bucket + Vector3(0.0, h, 0.0), bucket + Vector3(0.0, h + 0.025, 0.0), 0.135, HOOP, 10)
	tool.generate_normals()
	return tool.commit()


## As peças junto da rua escolhidas antes das bombas e dos poços (o carrinho de feira da Fase 203 e o bebedouro da Fase 206):
## a bomba e o poço desviam delas. Ficam fora de taken_cells porque elas mesmas a usam (a lista chamaria a si mesma).
static func street_pieces(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in MarketCartView.cells(world, data, island_id):
		result[cell] = true
	for cell: Vector2i in HorseTroughView.cells(world, data, island_id):
		result[cell] = true
	return result
