class_name SummitRockView
extends Node3D
## Fase 345: o granito no alto dos morros. No Anno o alto dos morros abre em massas de rocha cinza; nos nossos o capim cobria tudo até a
## crista. Numa rede de pontos a cada STEP células, o ponto em terra no alto da ilha (a altura passa de SUMMIT_SHARE da mais alta dela e
## de SUMMIT_MIN_M) e que se destaca da volta (`_crest`: um topo ou uma crista, não o planalto) ganha, pelo hash, um grupo de rochas (as formas da `RockModel` com o material da `RockView`): uma grande no meio e
## de duas a quatro menores em volta, cada uma numa célula livre (sem prédio, estrada, trilho nem árvore), meio enterradas. Só
## apresentação; nada no save; a célula que recebe prédio, estrada ou trilho perde a rocha (refeito na obra, na demolição, na estrada,
## no trilho, na derrubada e ao trocar de mundo).

const STEP := 5
const CHANCE := 0.55
const SUMMIT_SHARE := 0.62
const SUMMIT_MIN_M := 5.0
const KNOLL_CELLS := 5.0
const KNOLL_M := 0.8
## A rocha do meio e as de volta: raio, altura (vezes o raio) e quanto ficam enterradas (vezes a altura).
const MAIN_RADIUS_M := Vector2(2.5, 4.0)
const SIDE_RADIUS_M := Vector2(1.0, 2.0)
const SIDES_COUNT := Vector2i(3, 5)
const SIDE_REACH_M := 4.5
const HEIGHT := Vector2(0.7, 1.25)
const SINK := 0.35

var _simulation: Simulation
var _layers: Array[MultiMeshInstance3D] = []
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var rock := RockView.material()
	for variant: int in RockModel.VARIANTS:
		var layer := MultiMeshInstance3D.new()
		layer.name = "Summit_%d" % variant
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = RockModel.mesh(variant)
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = rock
		add_child(layer)
		_layers.append(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island: int, _area: Rect2i) -> void: _mark())
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rock_count() -> int:
	return _count


func _mark(_id: int = 0) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var lists: Array[Array] = []
	for variant: int in RockModel.VARIANTS:
		lists.append([])
	_count = 0
	for island_id: int in _simulation.world.islands.size():
		for entry: Array in places(_simulation.world, island_id):
			var variant: int = entry[1]
			lists[variant].append(entry[0])
			_count += 1
	for variant: int in RockModel.VARIANTS:
		var list: Array = lists[variant]
		var multimesh := _layers[variant].multimesh
		multimesh.instance_count = list.size()
		for i: int in list.size():
			var place: Transform3D = list[i]
			multimesh.set_instance_transform(i, place)


## As rochas da ilha: [transformação, forma]. Vazio na ilha plana.
static func places(world: WorldState, island_id: int) -> Array:
	var result: Array = []
	var grid := world.island(island_id)
	if grid == null or grid.flat or grid.corner_heights.is_empty():
		return result
	var top := _top_of(grid)
	var floor_m := maxf(SUMMIT_MIN_M, top * SUMMIT_SHARE)
	if top < floor_m:
		return result
	for y: int in range(STEP / 2, grid.size.y, STEP):
		for x: int in range(STEP / 2, grid.size.x, STEP):
			var cell := Vector2i(x, y)
			if not _free(grid, cell) or grid.cell_height(cell) < floor_m or not _crest(grid, cell):
				continue
			var noise := FireflyView.cell_hash(island_id, x, y, 345)
			if float(noise % 1000) / 1000.0 >= CHANCE:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = noise
			var center := grid.cell_world(cell)
			_add(result, grid, center, lerpf(MAIN_RADIUS_M.x, MAIN_RADIUS_M.y, rng.randf()), rng)
			for k: int in rng.randi_range(SIDES_COUNT.x, SIDES_COUNT.y):
				var angle := rng.randf() * TAU
				var at := center + Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(2.2, SIDE_REACH_M)
				if not _free(grid, grid.world_to_cell(at)):
					continue
				_add(result, grid, at, lerpf(SIDE_RADIUS_M.x, SIDE_RADIUS_M.y, rng.randf()), rng)
	return result


static func _add(result: Array, grid: IslandGrid, at: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	var height := radius * lerpf(HEIGHT.x, HEIGHT.y, rng.randf())
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(radius, height, radius * rng.randf_range(0.75, 1.0)))
	var ground := TerrainDetail.shown_at(grid, at.x, at.z)
	result.append([Transform3D(basis, Vector3(at.x, ground - height * SINK, at.z)), rng.randi() % RockModel.VARIANTS])


static var _tops: Dictionary[int, float] = {}


## A altura mais alta da ilha (guardada: o terreno não muda).
static func _top_of(grid: IslandGrid) -> float:
	var key := grid.get_instance_id()
	if _tops.has(key):
		return _tops[key]
	if _tops.size() > 32:
		_tops.clear()
	var top := 0.0
	for height: float in grid.corner_heights:
		top = maxf(top, height)
	_tops[key] = top
	return top


## O ponto se destaca da volta (topo ou crista): pelo menos KNOLL_M acima da média de oito pontos a KNOLL_CELLS células. No alto
## largo e plano da ilha (onde fica a vila) não há rocha.
static func _crest(grid: IslandGrid, cell: Vector2i) -> bool:
	var around := 0.0
	var count := 0
	for k: int in 8:
		var step := Vector2(KNOLL_CELLS, 0.0).rotated(TAU * k / 8.0)
		var at := cell + Vector2i(roundi(step.x), roundi(step.y))
		if grid.in_bounds(at):
			around += grid.cell_height(at)
			count += 1
	return count > 0 and grid.cell_height(cell) >= around / count + KNOLL_M


## A célula sem nada da simulação em cima (nem árvore) e em terra.
static func _free(grid: IslandGrid, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell) or not grid.is_land(cell):
		return false
	var index := grid.index(cell)
	return grid.occupancy[index] == 0 and grid.roads[index] == IslandGrid.Road.NONE and grid.trees[index] == 0 \
			and (grid.rails.is_empty() or grid.rails[index] == 0)
