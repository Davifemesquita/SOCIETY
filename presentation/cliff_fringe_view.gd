class_name CliffFringeView
extends Node3D
## Fase 312: o capim na borda das falésias. Na célula de terra do alto de uma falésia (uma vizinha pelo lado DROP_M mais baixa, com
## o mar a até SEA_REACH células naquela direção; desde a Fase 316, também o rio: a borda de cima das gargantas), sem prédio nem estrada, uma franja de folhas compridas que saem da borda e
## pendem sobre a rocha (`fringe_mesh`; desde a Fase 320, em tufos que abrem em leque, e cada pedaço um pouco girado), PER_EDGE
## pedaços por lado de célula, no material das plantas (balançam com o vento). Um
## MultiMesh por ilha, refeito só na ilha que mudou (IslandDirty). Só visual; nada no save.

const DROP_M := 2.0
const SEA_REACH := 4
const PER_EDGE := 2
## Quanto para dentro da borda fica o pé da franja (m) e o tamanho sorteado.
const INSET_M := 0.3
const SCALE := Vector2(0.8, 1.3)
## Fase 320: cada pedaço sai girado até YAW_JITTER_RAD e com o pé até INSET_JITTER_M mais para dentro ou para fora.
const YAW_JITTER_RAD := 0.22
const INSET_JITTER_M := 0.1
## Os tufos (Fase 320): quantos por pedaço, folhas em cada um, o leque, o comprimento, a subida e a queda (frações do comprimento),
## a meia largura e a torção das folhas, e até onde a ponta vai para os lados.
const TUFTS := 4
const BLADES_PER_TUFT := 6
const TUFT_JITTER := 0.06
const FAN_RAD := 1.5
const REACH := Vector2(0.35, 0.95)
const LIFT := Vector2(0.1, 0.35)
const DROOP := Vector2(0.25, 0.6)
const HALF_WIDTH := Vector2(0.018, 0.045)
const TWIST_RAD := 0.7
const EDGE_X := 0.56
const SEGMENTS := 4
const DRY_SHARE := 0.6
const VISIBLE_UNTIL_M := 300.0
const LEAF := Color(0.34, 0.5, 0.2)
const LEAF_DARK := Color(0.22, 0.36, 0.14)
const LEAF_DRY := Color(0.58, 0.56, 0.28)
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
				if not _water_below(grid, cell, side):
					continue
				_edge(grid, config, island_id, cell, side, result)
	return result


## O mar ou (Fase 316) o rio a até SEA_REACH células para o lado da queda (fora da grade conta como mar).
static func _water_below(grid: IslandGrid, cell: Vector2i, side: Vector2i) -> bool:
	for reach: int in range(1, SEA_REACH + 1):
		var at := cell + side * reach
		if not grid.in_bounds(at) or grid.ground[grid.index(at)] != IslandGrid.Ground.LAND:
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
		# Fase 320: o giro e o recuo de cada pedaço, de um sorteio à parte (o lugar e o tamanho da Fase 312 não mudam)
		var turn := FireflyView.cell_hash(island_id, cell.x * 4 + side.x + 1, cell.y * 4 + side.y + 1, 320 + k)
		var yaw := (float(turn % 1000) / 999.0 * 2.0 - 1.0) * YAW_JITTER_RAD
		var inset := INSET_M + (float(turn / 1000 % 1000) / 999.0 * 2.0 - 1.0) * INSET_JITTER_M
		var foot := center + out * (grid.cell_size * 0.5 - inset) + along * slide * grid.cell_size
		foot.y = grid.height_at(foot.x, foot.z) + TerrainDetail.offset_at(grid, config, foot.x, foot.z)
		var scale := SCALE.x + float(noise / 100 % 100) / 100.0 * (SCALE.y - SCALE.x)
		var turned := Basis(along, Vector3.UP, out).rotated(Vector3.UP, yaw)
		result.append(Transform3D(turned.scaled(Vector3.ONE * scale), foot))


## As folhas da franja (Fase 320): TUFTS tufos ao longo de x, cada um com BLADES_PER_TUFT folhas saindo do mesmo pé e abrindo em
## leque para fora (+z), de rumo, comprimento, largura, altura, queda, torção e tom sorteados por um gerador de semente fixa (a malha é
## a mesma em toda partida). Antes (Fase 312) eram onze folhas iguais e paralelas: de perto, um pente.
static func tuft_blades() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 320
	var blades: Array[Dictionary] = []
	for t: int in TUFTS:
		var root := Vector3((float(t) + 0.5) / TUFTS - 0.5 + rng.randf_range(-1.0, 1.0) * TUFT_JITTER, 0.0,
				rng.randf_range(-0.12, -0.03))
		for b: int in BLADES_PER_TUFT:
			# o leque cobre FAN_RAD, cada folha num pedaço dele com folga sorteada
			var fan := (float(b) + rng.randf_range(0.15, 0.85)) / BLADES_PER_TUFT * FAN_RAD - FAN_RAD * 0.5
			var reach := rng.randf_range(REACH.x, REACH.y)
			# a ponta não passa de EDGE_X para os lados (o pedaço seguinte começa ali)
			var side := root.x + sin(fan) * reach
			if absf(side) > EDGE_X:
				fan = asin(clampf((signf(side) * EDGE_X - root.x) / reach, -1.0, 1.0))
			var tone := rng.randf()
			var base := LEAF_DARK.lerp(LEAF, tone * 2.0) if tone < 0.5 else LEAF.lerp(LEAF_DRY, (tone - 0.5) * 2.0 * DRY_SHARE)
			blades.append({
				&"root": root + Vector3(rng.randf_range(-0.03, 0.03), 0.0, rng.randf_range(-0.02, 0.02)),
				&"heading": Vector3(sin(fan), 0.0, cos(fan)),
				&"reach": reach,
				&"lift": rng.randf_range(LIFT.x, LIFT.y) * reach,
				&"droop": rng.randf_range(DROOP.x, DROOP.y) * reach,
				&"half": rng.randf_range(HALF_WIDTH.x, HALF_WIDTH.y),
				&"twist": rng.randf_range(-TWIST_RAD, TWIST_RAD),
				&"color": base,
				&"tip": base.lerp(LEAF_TIP, rng.randf_range(0.4, 0.9)),
			})
	return blades


## A franja: as folhas de `tuft_blades`, cada uma uma fita em SEGMENTS pedaços que sai do pé, sobe um pouco para fora (+z) e pende,
## mais fina e mais clara na ponta; faces dos dois lados (o material das plantas não descarta face).
static func fringe_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade: Dictionary in tuft_blades():
		var root: Vector3 = blade[&"root"]
		var heading: Vector3 = blade[&"heading"]
		var reach: float = blade[&"reach"]
		var lift: float = blade[&"lift"]
		var droop: float = blade[&"droop"]
		var half: float = blade[&"half"]
		var twist: float = blade[&"twist"]
		var color: Color = blade[&"color"]
		var tip: Color = blade[&"tip"]
		# a largura da fita, de través do rumo, torcida em volta dele
		var across := Vector3.UP.cross(heading).normalized() * cos(twist) + Vector3.UP * sin(twist)
		var spine: Array[Vector3] = []
		for s: int in SEGMENTS + 1:
			var f := float(s) / SEGMENTS
			# para fora depressa no começo e devagar no fim (a folha curva), subindo e depois pendendo
			var out := reach * (1.0 - (1.0 - f) * (1.0 - f))
			spine.append(root + heading * out + Vector3.UP * (lift * sin(PI * f) - droop * f * f))
		for s: int in SEGMENTS:
			var a := spine[s]
			var b := spine[s + 1]
			var wa := half * pow(1.0 - float(s) / SEGMENTS, 0.7) + 0.003
			var wb := half * pow(1.0 - float(s + 1) / SEGMENTS, 0.7) + 0.003
			var color_a := color.lerp(tip, float(s) / SEGMENTS)
			var color_b := color.lerp(tip, float(s + 1) / SEGMENTS)
			var normal := (b - a).cross(across).normalized()
			if normal.y < 0.0:
				normal = -normal
			var corners: Array[Vector3] = [a - across * wa, a + across * wa, b + across * wb, b - across * wb]
			var colors: Array[Color] = [color_a, color_a, color_b, color_b]
			for tri: Array in [[0, 2, 1], [0, 3, 2]]:
				for corner: int in tri:
					tool.set_color(colors[corner])
					tool.set_normal(normal)
					tool.add_vertex(corners[corner])
	tool.index()
	return tool.commit()
