class_name RiverStoneView
extends Node3D
## Fase 122: as pedras do rio. Nas células de rio (`IslandGrid.Ground.RIVER`), uma a cada BOULDER_CHANCE pelo hash da
## célula, um matacão de rocha (a `RockModel` com o material da `RockView`) sentado no leito e saindo EMERGE_M da água,
## onde o leito não é fundo demais; e nas células de terra da margem (encostadas no rio, sem prédio, estrada nem trilho),
## baixas (até BANK_MAX_M), uma a cada PEBBLE_CHANCE, um punhado de seixos no chão (`places`). A espuma em volta sai
## sozinha da água, pela profundidade. A célula de rio com ponte não leva pedra. Só apresentação; nada no save; refeito
## quando estrada ou prédio muda e ao trocar de mundo.

enum Kind { BOULDER, PEBBLE }

const BOULDER_CHANCE := 0.22
const PEBBLE_CHANCE := 0.3
## O leito mais fundo que ainda leva matacão (o meio do rio fica livre para o barco imaginário).
const MAX_BED_DEPTH_M := 1.1
const BOULDER_RADIUS_M := Vector2(0.4, 0.95)
const EMERGE_M := Vector2(0.08, 0.45)
const PEBBLES := Vector2i(2, 4)
const PEBBLE_RADIUS_M := Vector2(0.12, 0.28)
const PEBBLE_SINK := 0.35
## A margem mais alta que ainda leva seixos (o rio que corre numa garganta não tem praia de pedra no alto do barranco).
const BANK_MAX_M := 1.6
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _layers: Array[MultiMeshInstance3D] = []
var _counts: Dictionary[int, int] = {}
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := RockView.material()
	for variant: int in RockModel.VARIANTS:
		var layer := MultiMeshInstance3D.new()
		layer.name = "RiverStones_%d" % variant
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = RockModel.mesh(variant)
		layer.material_override = material
		layer.visibility_range_end = RockView.VISIBLE_UNTIL_M
		add_child(layer)
		_layers.append(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func stone_count(kind: int = -1) -> int:
	if kind >= 0:
		return _counts.get(kind, 0)
	var total := 0
	for each: int in _counts.values():
		total += each
	return total


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_counts.clear()
	var buffers: Array[Array] = []
	for variant: int in RockModel.VARIANTS:
		buffers.append([])
	for island_id: int in _simulation.world.islands.size():
		for entry: Array in places(_simulation.world, island_id):
			var variant: int = entry[0]
			var kind: int = entry[2]
			buffers[variant].append(entry[1])
			_counts[kind] = _counts.get(kind, 0) + 1
	for variant: int in RockModel.VARIANTS:
		var list: Array = buffers[variant]
		var multimesh := _layers[variant].multimesh
		multimesh.instance_count = list.size()
		for i: int in list.size():
			var place: Transform3D = list[i]
			multimesh.set_instance_transform(i, place)
		multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As pedras de uma ilha: [[variante, lugar no mundo, Kind], ...]. Função pura do mundo (testes). Vazio na ilha plana.
static func places(world: WorldState, island_id: int) -> Array:
	var result: Array = []
	var grid := world.island(island_id)
	if grid == null or grid.flat or grid.ground.is_empty():
		return result
	var start := grid.ground.find(IslandGrid.Ground.RIVER)
	if start < 0:
		return result
	var bank: Dictionary[int, bool] = {}
	for index: int in range(start, grid.ground.size()):
		if grid.ground[index] != IslandGrid.Ground.RIVER:
			continue
		var cell := grid.cell_at(index)
		for side: Vector2i in SIDES:
			var next := cell + side
			if grid.in_bounds(next) and grid.ground[grid.index(next)] == IslandGrid.Ground.LAND:
				bank[grid.index(next)] = true
		if grid.roads[index] != IslandGrid.Road.NONE:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([island_id, cell, &"river_stone"])
		if rng.randf() >= BOULDER_CHANCE:
			continue
		var spot := _spot_in(grid, cell, rng, 0.3)
		var bed := grid.height_at(spot.x, spot.y)
		if bed < -MAX_BED_DEPTH_M or bed > 0.0:
			continue
		var radius := lerpf(BOULDER_RADIUS_M.x, BOULDER_RADIUS_M.y, rng.randf())
		var top := lerpf(EMERGE_M.x, EMERGE_M.y, rng.randf())
		_add(result, rng, Kind.BOULDER, Vector3(spot.x, bed, spot.y), Vector3(radius, top - bed, radius * 0.85))
	for index: int in bank:
		if grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 \
				or grid.cell_height(grid.cell_at(index)) > BANK_MAX_M:
			continue
		var cell := grid.cell_at(index)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([island_id, cell, &"river_pebble"])
		if rng.randf() >= PEBBLE_CHANCE:
			continue
		for k: int in rng.randi_range(PEBBLES.x, PEBBLES.y):
			var spot := _spot_in(grid, cell, rng, 0.15)
			var radius := lerpf(PEBBLE_RADIUS_M.x, PEBBLE_RADIUS_M.y, rng.randf())
			var ground := grid.height_at(spot.x, spot.y)
			_add(result, rng, Kind.PEBBLE, Vector3(spot.x, ground - radius * PEBBLE_SINK, spot.y),
					Vector3(radius, radius * 0.9, radius * 1.1))
	return result


## Um ponto sorteado na célula (m do mundo, x e z), longe margin da borda (fração da célula).
static func _spot_in(grid: IslandGrid, cell: Vector2i, rng: RandomNumberGenerator, margin: float) -> Vector2:
	var u := lerpf(margin, 1.0 - margin, rng.randf())
	var v := lerpf(margin, 1.0 - margin, rng.randf())
	return grid.origin_m + (Vector2(cell) + Vector2(u, v)) * grid.cell_size


## Uma pedra: o zero da malha em position, o tamanho em metros (x e z o raio, y do zero ao topo), girada pelo sorteio.
static func _add(result: Array, rng: RandomNumberGenerator, kind: int, position: Vector3, size: Vector3) -> void:
	var basis := Basis(Vector3.UP, rng.randf() * TAU)
	var variant := rng.randi() % RockModel.VARIANTS
	result.append([variant, Transform3D(basis * Basis.from_scale(size), position), kind])
