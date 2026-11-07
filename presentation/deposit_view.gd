class_name DepositView
extends Node3D
## Fase 128: as jazidas à vista. Cada mancha de jazida da ilha (as células de `IslandGrid.deposits` ligadas pelos lados)
## que ainda não tem prédio em cima ganha, no meio dela, um afloramento de rocha (as formas da `RockModel` com o material
## da `RockView`) e, espalhadas pela mancha (fora das ruas e dos trilhos), pedras soltas na cor do minério (`ORE_COLORS`:
## carvão preto, ferro ferrugem, ouro com o brilho amarelo) — dá para achar a jazida de longe, antes de abrir a mina. Com
## uma mina na mancha, o afloramento some. Só apresentação; nada no save; refeito na obra, na demolição, na estrada, no
## trilho e ao trocar de mundo.

enum Kind { OUTCROP, ORE }

## Pedras de minério por célula da mancha (em média) e o tamanho delas.
const ORE_PER_CELL := 0.6
const ORE_RADIUS_M := Vector2(0.18, 0.4)
const ORE_SINK := 0.4
const OUTCROP_RADIUS_M := Vector2(1.2, 1.8)
const OUTCROP_HEIGHT_M := Vector2(1.0, 1.7)
const OUTCROP_SINK_M := 0.4
const ORE_COLORS: Dictionary[StringName, Color] = {
	&"coal": Color(0.12, 0.12, 0.13),
	&"iron_ore": Color(0.55, 0.27, 0.16),
	&"gold": Color(0.85, 0.68, 0.22),
}
const ORE_DEFAULT := Color(0.5, 0.48, 0.45)
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _outcrops: Array[MultiMeshInstance3D] = []
var _ores := MultiMeshInstance3D.new()
var _counts: Dictionary[int, int] = {}
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var rock := RockView.material()
	for variant: int in RockModel.VARIANTS:
		var layer := MultiMeshInstance3D.new()
		layer.name = "Outcrop_%d" % variant
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = RockModel.mesh(variant)
		layer.material_override = rock
		add_child(layer)
		_outcrops.append(layer)
	var ore := StandardMaterial3D.new()
	ore.vertex_color_use_as_albedo = true
	ore.vertex_color_is_srgb = true
	ore.roughness = 0.6
	ore.metallic = 0.2
	var pebble := RockModel.mesh(1)
	_ores.name = "Ores"
	_ores.multimesh = MultiMesh.new()
	_ores.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_ores.multimesh.use_colors = true
	_ores.multimesh.mesh = pebble
	_ores.material_override = ore
	add_child(_ores)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func count(kind: int) -> int:
	return _counts.get(kind, 0)


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_counts.clear()
	var outcrops: Array[Array] = []
	for variant: int in RockModel.VARIANTS:
		outcrops.append([])
	var ores: Array[Transform3D] = []
	var colors: Array[Color] = []
	for island_id: int in _simulation.world.islands.size():
		for entry: Array in places(_simulation.world, island_id):
			var kind: int = entry[0]
			var place: Transform3D = entry[1]
			_counts[kind] = _counts.get(kind, 0) + 1
			if kind == Kind.OUTCROP:
				var variant: int = entry[2]
				outcrops[variant].append(place)
			else:
				ores.append(place)
				colors.append(entry[2])
	for variant: int in RockModel.VARIANTS:
		var list: Array = outcrops[variant]
		var multimesh := _outcrops[variant].multimesh
		multimesh.instance_count = list.size()
		for i: int in list.size():
			var place: Transform3D = list[i]
			multimesh.set_instance_transform(i, place)
		multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_ores.multimesh.instance_count = ores.size()
	for i: int in ores.size():
		_ores.multimesh.set_instance_transform(i, ores[i])
		_ores.multimesh.set_instance_color(i, colors[i])
	_ores.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As manchas de jazida da ilha: cada uma [bem, células], as células ligadas pelos lados com o mesmo bem.
static func patches(grid: IslandGrid) -> Array[Array]:
	var result: Array[Array] = []
	if grid == null or grid.deposits.is_empty():
		return result
	var seen := PackedByteArray()
	seen.resize(grid.deposits.size())
	for index: int in grid.deposits.size():
		if grid.deposits[index] == 0 or seen[index] == 1:
			continue
		var kind := grid.deposits[index]
		var cells: Array[Vector2i] = []
		var queue: Array[Vector2i] = [grid.cell_at(index)]
		seen[index] = 1
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			cells.append(cell)
			for side: Vector2i in SIDES:
				var next := cell + side
				if not grid.in_bounds(next):
					continue
				var at := grid.index(next)
				if seen[at] == 0 and grid.deposits[at] == kind:
					seen[at] = 1
					queue.append(next)
		result.append([grid.deposit_goods[kind - 1], cells])
	return result


## O que se desenha nas jazidas livres da ilha: [Kind, lugar, variante (afloramento) ou cor (minério)]. Função pura do
## mundo (testes). Mancha com prédio em qualquer célula fica sem nada (a mina já está lá).
static func places(world: WorldState, island_id: int) -> Array:
	var result: Array = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	for patch: Array in patches(grid):
		var good: StringName = patch[0]
		var cells: Array[Vector2i] = []
		var raw_cells: Array = patch[1]
		cells.assign(raw_cells)
		var taken := false
		var middle := Vector2.ZERO
		for cell: Vector2i in cells:
			taken = taken or grid.building_at(cell) != 0
			middle += Vector2(cell) + Vector2(0.5, 0.5)
		if taken:
			continue
		middle /= cells.size()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([island_id, cells[0], &"deposit"])
		var center := grid.origin_m + middle * grid.cell_size
		var ground := grid.height_at(center.x, center.y)
		var radius := lerpf(OUTCROP_RADIUS_M.x, OUTCROP_RADIUS_M.y, rng.randf())
		var height := lerpf(OUTCROP_HEIGHT_M.x, OUTCROP_HEIGHT_M.y, rng.randf())
		var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(radius, height + OUTCROP_SINK_M, radius * 0.8))
		var variant := rng.randi() % RockModel.VARIANTS
		# o afloramento não fica em cima de uma rua que passe no meio da mancha
		var middle_cell := grid.world_to_cell(Vector3(center.x, 0.0, center.y))
		if not (grid.has_road(middle_cell) or grid.has_rail(middle_cell)):
			result.append([Kind.OUTCROP, Transform3D(basis, Vector3(center.x, ground - OUTCROP_SINK_M, center.y)), variant])
		var color: Color = ORE_COLORS.get(good, ORE_DEFAULT)
		var ores := roundi(cells.size() * ORE_PER_CELL)
		for k: int in ores:
			var cell: Vector2i = cells[rng.randi() % cells.size()]
			var spot := grid.origin_m + (Vector2(cell) + Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.15, 0.85))) \
					* grid.cell_size
			var size := lerpf(ORE_RADIUS_M.x, ORE_RADIUS_M.y, rng.randf())
			# a pedra sorteada na rua ou no trilho não aparece (o sorteio segue igual para as outras)
			if grid.has_road(cell) or grid.has_rail(cell):
				continue
			var y := grid.height_at(spot.x, spot.y) - size * ORE_SINK
			var turn := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(size, size * 0.8, size * 1.1))
			var tone := color.lightened(rng.randf_range(-0.1, 0.15))
			result.append([Kind.ORE, Transform3D(turn, Vector3(spot.x, y, spot.y)), tone])
	return result
