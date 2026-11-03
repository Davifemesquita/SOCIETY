class_name CliffFringeView
extends Node3D
## Fase 312: o capim na borda das falésias. Na célula de terra do alto de uma falésia (uma vizinha pelo lado DROP_M mais baixa, com
## o mar a até SEA_REACH células naquela direção), sem prédio nem estrada, uma franja de folhas compridas que saem da borda e
## pendem sobre a rocha (`fringe_mesh`), PER_EDGE pedaços por lado de célula, no material das plantas (balançam com o vento). Um
## MultiMesh por ilha, refeito só na ilha que mudou (IslandDirty). Só visual; nada no save.

const DROP_M := 2.0
const SEA_REACH := 4
const PER_EDGE := 2
## Quanto para dentro da borda fica o pé da franja (m) e o tamanho sorteado.
const INSET_M := 0.3
const SCALE := Vector2(0.8, 1.3)
const BLADES := 11
const VISIBLE_UNTIL_M := 300.0
const LEAF := Color(0.34, 0.5, 0.2)
const LEAF_TIP := Color(0.6, 0.62, 0.3)
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _mesh: ArrayMesh
var _material: ShaderMaterial
var _nodes: Dictionary[int, MultiMeshInstance3D] = {}
var _counts: Dictionary[int, int] = {}
var _changes := IslandDirty.new()


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_mesh = fringe_mesh()
	_material = CropView.plant_material(_mesh, 0.08)
	EventBus.building_placed.connect(func(id: int) -> void: _changes.mark_building(_simulation.world, id))
	EventBus.building_removed.connect(func(id: int) -> void: _changes.mark_building(_simulation.world, id))
	EventBus.roads_changed.connect(func(island_id: int) -> void: _changes.mark_island(island_id))
	EventBus.world_replaced.connect(_changes.mark_all)
	rebuild()


func piece_count() -> int:
	var total := 0
	for count: int in _counts.values():
		total += count
	return total


func _process(_delta: float) -> void:
	if _simulation != null and _changes.pending():
		rebuild()


func rebuild() -> void:
	var world := _simulation.world
	for island_id: int in _changes.take(world):
		if _nodes.has(island_id):
			_nodes[island_id].queue_free()
			_nodes.erase(island_id)
		var places := places_of(world, _simulation.config, island_id)
		_counts[island_id] = places.size()
		if places.is_empty():
			continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _mesh
		multimesh.instance_count = places.size()
		for i: int in places.size():
			multimesh.set_instance_transform(i, places[i])
		var node := MultiMeshInstance3D.new()
		node.name = "Fringe_%d" % island_id
		node.multimesh = multimesh
		node.material_override = _material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = VISIBLE_UNTIL_M
		add_child(node)
		_nodes[island_id] = node
	# o mundo trocado tira as ilhas que sobraram do anterior
	for island_id: int in _nodes.keys():
		if island_id >= world.islands.size():
			_nodes[island_id].queue_free()
			_nodes.erase(island_id)
			_counts.erase(island_id)


## Os pedaços de franja da ilha: o pé na borda de cima de cada lado de falésia, +z para fora (sobre a queda), +y para cima.
static func places_of(world: WorldState, config: GameConfig, island_id: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var ground := grid.ground
	var occupancy := grid.occupancy
	var roads := grid.roads
	var heights := grid.cell_heights()
	var width := grid.size.x
	# o laço passa pela grade inteira: índices direto nos arrays, e só a célula com queda chama função
	for y: int in range(1, grid.size.y - 1):
		for x: int in range(1, grid.size.x - 1):
			var index := y * width + x
			if ground[index] != IslandGrid.Ground.LAND or occupancy[index] != 0 or roads[index] != IslandGrid.Road.NONE:
				continue
			var top := heights[index]
			if top < DROP_M:
				continue
			var cell := Vector2i(x, y)
			for side: Vector2i in SIDES:
				var j := index + side.y * width + side.x
				# a vizinha de água conta como o nível do mar
				if top - (heights[j] if ground[j] == IslandGrid.Ground.LAND else 0.0) < DROP_M:
					continue
				if not _sea_below(grid, cell, side):
					continue
				_edge(grid, config, island_id, cell, side, result)
	return result


static func _sea_below(grid: IslandGrid, cell: Vector2i, side: Vector2i) -> bool:
	for reach: int in range(1, SEA_REACH + 1):
		var at := cell + side * reach
		if not grid.in_bounds(at) or grid.ground[grid.index(at)] == IslandGrid.Ground.SEA:
			return true
	return false


static func _edge(grid: IslandGrid, config: GameConfig, island_id: int, cell: Vector2i, side: Vector2i,
		result: Array[Transform3D]) -> void:
	var out := Vector3(side.x, 0.0, side.y)
	var along := Vector3.UP.cross(out)
	var center := grid.cell_world(cell)
	for k: int in PER_EDGE:
		var noise := FireflyView.cell_hash(island_id, cell.x * 4 + side.x + 1, cell.y * 4 + side.y + 1, 312 + k)
		var slide := (float(k) + 0.5) / PER_EDGE - 0.5 + (float(noise % 100) / 100.0 - 0.5) * 0.3
		var foot := center + out * (grid.cell_size * 0.5 - INSET_M) + along * slide * grid.cell_size
		foot.y = grid.height_at(foot.x, foot.z) + TerrainDetail.offset_at(grid, config, foot.x, foot.z)
		var scale := SCALE.x + float(noise / 100 % 100) / 100.0 * (SCALE.y - SCALE.x)
		result.append(Transform3D(Basis(along, Vector3.UP, out).scaled(Vector3.ONE * scale), foot))


## A franja: BLADES folhas lado a lado ao longo de x, cada uma saindo do pé, subindo um pouco para fora (+z) e pendendo, com a ponta
## mais clara; faces dos dois lados (o material das plantas não descarta face).
static func fringe_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in BLADES:
		var x := (float(i) + 0.5) / BLADES - 0.5
		var reach := 0.55 + 0.25 * float((i * 7) % 5) / 4.0
		var spine: Array[Vector3] = [Vector3(x, 0.0, -0.05), Vector3(x + 0.02, 0.16, reach * 0.45),
				Vector3(x + 0.04, 0.02, reach * 0.85), Vector3(x + 0.05, -0.32 * reach, reach)]
		var half := 0.035
		for s: int in spine.size() - 1:
			var a := spine[s]
			var b := spine[s + 1]
			var wa := half * (1.0 - float(s) / (spine.size() - 1))
			var wb := half * (1.0 - float(s + 1) / (spine.size() - 1)) + 0.004
			var color_a := LEAF.lerp(LEAF_TIP, float(s) / (spine.size() - 1))
			var color_b := LEAF.lerp(LEAF_TIP, float(s + 1) / (spine.size() - 1))
			var normal := (b - a).cross(Vector3.RIGHT).normalized()
			if normal.y < 0.0:
				normal = -normal
			var corners: Array[Vector3] = [a - Vector3(wa, 0.0, 0.0), a + Vector3(wa, 0.0, 0.0), b + Vector3(wb, 0.0, 0.0),
					b - Vector3(wb, 0.0, 0.0)]
			var colors: Array[Color] = [color_a, color_a, color_b, color_b]
			for tri: Array in [[0, 2, 1], [0, 3, 2]]:
				for corner: int in tri:
					tool.set_color(colors[corner])
					tool.set_normal(normal)
					tool.add_vertex(corners[corner])
	tool.index()
	return tool.commit()
