class_name RivalView
extends Node3D
## Vilas das companhias rivais (Fase 11): em cada ilha de rival, um entreposto com a bandeira dela
## e casas (paredes claras, telhado na cor dela) que aparecem conforme a vila cresce. A rival não
## tem prédios na simulação: os lugares saem da grade da ilha (células de terra plana, em espiral a
## partir do meio), sempre os mesmos para a mesma ilha. Só lê a simulação.

## Lado da casa e passo da malha das casas, em células.
const HOUSE_CELLS := 3
const LATTICE := 5
const WALL_COLOR := Color(0.86, 0.82, 0.72)
const POST_COLOR := Color(0.45, 0.34, 0.24)

var _simulation: Simulation
## ilha → nó da vila
var _villages: Dictionary[int, Node3D] = {}
## ilha → casas mostradas agora
var _shown: Dictionary[int, int] = {}
## ilha → lugares das casas (o primeiro é o do entreposto)
var _slots: Dictionary[int, Array] = {}
var _refresh_left: float = 0.0
var _materials: Dictionary[Color, StandardMaterial3D] = {}


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	name = "RivalView"
	EventBus.world_replaced.connect(rebuild)
	EventBus.rival_colonized.connect(func(_rival: StringName, _island: int) -> void: refresh())
	rebuild()


func rebuild() -> void:
	for node: Node3D in _villages.values():
		node.queue_free()
	_villages.clear()
	_shown.clear()
	_slots.clear()
	refresh()


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = 2.0
		refresh()


## Casas que a vila mostra agora (uma por rival_residents_per_house moradores).
func houses_shown(island_id: int) -> int:
	return _shown.get(island_id, 0)


func village(island_id: int) -> Node3D:
	return _villages.get(island_id)


func refresh() -> void:
	var state := _simulation.world.rivals_state
	if not state.enabled:
		return
	for rival: RivalState in state.rivals:
		for island_id: int in rival.island_ids():
			var slots := _slots_of(island_id)
			var wanted := clampi(ceili(rival.islands[island_id] / _simulation.config.rival_residents_per_house), 1, maxi(slots.size() - 1, 1))
			if _villages.has(island_id) and _shown[island_id] == wanted:
				continue
			if _villages.has(island_id):
				_villages[island_id].queue_free()
			var node := _build(island_id, rival.def.color, slots, wanted)
			add_child(node)
			_villages[island_id] = node
			_shown[island_id] = wanted


func _slots_of(island_id: int) -> Array:
	if not _slots.has(island_id):
		_slots[island_id] = _find_slots(_simulation.world.island(island_id), _simulation.config)
	return _slots[island_id]


## Lugares de casa em terra plana e sem árvore, do meio da ilha para fora.
static func _find_slots(grid: IslandGrid, config: GameConfig) -> Array:
	var found: Array[Vector2i] = []
	var center := grid.size / 2
	var reach := maxi(grid.size.x, grid.size.y) / (2 * LATTICE) + 1
	var cells: Array[Vector2i] = []
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			cells.append(Vector2i(dx, dy))
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.length_squared() < b.length_squared() or (a.length_squared() == b.length_squared() and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	for offset: Vector2i in cells:
		var origin := center + offset * LATTICE
		var area := Rect2i(origin, Vector2i(HOUSE_CELLS, HOUSE_CELLS))
		if not grid.contains_rect(area) or not grid.area_is_land(area):
			continue
		if grid.area_relief(area) > config.max_build_height_delta_m or grid.trees_in(area) > 0:
			continue
		found.append(origin)
		if found.size() >= config.rival_max_houses:
			break
	return found


func _build(island_id: int, color: Color, slots: Array, count: int) -> Node3D:
	var grid := _simulation.world.island(island_id)
	var root := Node3D.new()
	root.name = "Village%d" % island_id
	if slots.is_empty():
		return root
	var size_m := HOUSE_CELLS * grid.cell_size
	var walls := MultiMesh.new()
	walls.transform_format = MultiMesh.TRANSFORM_3D
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(size_m * 0.8, 3.0, size_m * 0.8)
	wall_mesh.material = _material(WALL_COLOR)
	walls.mesh = wall_mesh
	var roofs := MultiMesh.new()
	roofs.transform_format = MultiMesh.TRANSFORM_3D
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(size_m * 0.9, 1.6, size_m * 0.9)
	roof_mesh.material = _material(color)
	roofs.mesh = roof_mesh
	walls.instance_count = count
	roofs.instance_count = count
	for index: int in count:
		var origin: Vector2i = slots[index + 1] if index + 1 < slots.size() else slots[index]
		var area := Rect2i(origin, Vector2i(HOUSE_CELLS, HOUSE_CELLS))
		var base := grid.rect_world(area)
		var turn := Basis(Vector3.UP, (index % 2) * PI * 0.5)
		walls.set_instance_transform(index, Transform3D(turn, base + Vector3(0.0, 1.5, 0.0)))
		roofs.set_instance_transform(index, Transform3D(turn, base + Vector3(0.0, 3.8, 0.0)))
	for multimesh: MultiMesh in [walls, roofs]:
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		root.add_child(instance)
	var post_origin: Vector2i = slots[0]
	var post_area := Rect2i(post_origin, Vector2i(HOUSE_CELLS, HOUSE_CELLS))
	var post_base := grid.rect_world(post_area)
	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(size_m, 4.5, size_m)
	post_mesh.material = _material(POST_COLOR)
	post.mesh = post_mesh
	post.position = post_base + Vector3(0.0, 2.25, 0.0)
	root.add_child(post)
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.1
	pole_mesh.height = 6.0
	pole_mesh.material = _material(POST_COLOR.darkened(0.3))
	pole.mesh = pole_mesh
	pole.position = post_base + Vector3(0.0, 7.5, 0.0)
	root.add_child(pole)
	root.add_child(WindFlag.make(Vector3(2.2, 1.3, 0.05), _material(color), post_base + Vector3(0.05, 9.6, 0.0)))
	return root


func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.85
		_materials[color] = material
	return _materials[color]
