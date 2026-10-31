class_name ScatterView
extends Node3D
## Recheio (Fase 41): o fim do gramado vazio entre as casas. Em cada célula de terra livre (sem árvore, estrada, prédio
## nem porta), pelo que há em volta: arbustos, capim e flores na beira da mata; capim, flores e pedrinhas na beira da
## estrada; capim de duna no litoral; e, encostados nos prédios, arbustos e flores, barris, caixotes e lenha. Tudo
## determinístico pela célula (o mesmo mundo dá sempre o mesmo recheio), nada no save, em MultiMesh por trecho de
## CHUNK_CELLS e por peça, até VISIBLE_UNTIL_M da câmera. Refaz só os trechos que uma obra, uma estrada ou uma
## derrubada de árvores atingiu. Só lê o mundo. A ilha plana dos testes e saves antigos não tem recheio.
## Fase 60: nas ilhas tropicais o arbusto temperado vira sub-bosque tropical — bananeira (BANANA_SHARE das vezes) ou
## samambaia —; as ilhas temperadas não mudam (o sorteio extra só acontece na tropical). Fase 61: lá, as flores do
## campo viram helicônias (folhas em remo e brácteas vermelhas de ponta amarela em zigue-zague). Fase 105: a árvore de
## quintal (macieira pequena, no meio da célula, não encostada na parede) nas células junto das casas; na tropical, a
## bananeira. Ela vem por último na lista: o sorteio das peças de antes não muda. Fase 112: na beira das ruas das ilhas
## tropicais, coqueiros pequenos (o da Fase 58, reduzido a STREET_PALM_SCALE), também no fim da lista NEAR_ROAD.

enum Kind { BUSH, TUFT, FLOWERS, PEBBLE, BARREL, CRATE, WOODPILE, BANANA, FERN, HELICONIA, YARD_TREE, STREET_PALM }

const CHUNK_CELLS := 32
const VISIBLE_UNTIL_M := 220.0
const VISIBLE_MARGIN_M := 20.0
## As peças que fazem sombra (as miúdas não: são milhares).
const SHADOWED: Array[int] = [Kind.BUSH, Kind.BARREL, Kind.CRATE, Kind.WOODPILE, Kind.BANANA, Kind.YARD_TREE, Kind.STREET_PALM]
## As plantas (material da folhagem, balançam).
const PLANTS: Array[int] = [Kind.BUSH, Kind.TUFT, Kind.FLOWERS, Kind.BANANA, Kind.FERN, Kind.HELICONIA, Kind.YARD_TREE]
const BANANA_SHARE := 0.4
const BANANA_LEAF := Color(0.36, 0.58, 0.18)
const BANANA_STEM := Color(0.42, 0.46, 0.2)
const FERN_LEAF := Color(0.18, 0.4, 0.12)
const HELICONIA_LEAF := Color(0.26, 0.5, 0.16)
## As brácteas da helicônia: vermelhas com a ponta amarela.
const HELICONIA_BRACT := Color(0.85, 0.12, 0.1)
const HELICONIA_TIP := Color(0.95, 0.8, 0.2)
## Chances por célula, pelo que há em volta: [peça, chance].
const NEAR_HOUSE: Array[Array] = [[Kind.BUSH, 0.25], [Kind.FLOWERS, 0.3], [Kind.BARREL, 0.1], [Kind.WOODPILE, 0.08],
		[Kind.CRATE, 0.05], [Kind.YARD_TREE, YARD_TREE_CHANCE]]
## Fase 105: a árvore de quintal — a chance por célula junto de casa, o tronco, a copa (raio que não chega à parede da
## casa: a célula tem 2 m e a parede fica a 15 cm da divisa) e as frutas vermelhas.
const YARD_TREE_CHANCE := 0.14
const YARD_TRUNK_M := 1.5
const YARD_CROWN_M := 0.75
const YARD_LEAF := Color(0.24, 0.42, 0.16)
const YARD_BARK := Color(0.32, 0.24, 0.17)
const YARD_FRUIT := Color(0.75, 0.14, 0.1)
const NEAR_WORKS: Array[Array] = [[Kind.CRATE, 0.18], [Kind.BARREL, 0.14], [Kind.BUSH, 0.12], [Kind.TUFT, 0.2]]
const NEAR_FOREST: Array[Array] = [[Kind.BUSH, 0.35], [Kind.TUFT, 0.4], [Kind.FLOWERS, 0.12]]
const NEAR_ROAD: Array[Array] = [[Kind.TUFT, 0.45], [Kind.PEBBLE, 0.12], [Kind.FLOWERS, 0.12], [Kind.BUSH, 0.05],
		[Kind.STREET_PALM, STREET_PALM_CHANCE]]
## Fase 112: o coqueiro da rua tropical — a chance por célula na beira da rua e o tamanho dele (o coqueiro da mata reduzido).
const STREET_PALM_CHANCE := 0.16
const STREET_PALM_SCALE := 0.55
const NEAR_SEA: Array[Array] = [[Kind.TUFT, 0.35], [Kind.PEBBLE, 0.08]]
const OPEN: Array[Array] = [[Kind.TUFT, 0.25], [Kind.FLOWERS, 0.05], [Kind.BUSH, 0.04]]
## O capim do recheio é a touceira das plantações aumentada (a de 30 cm some a 50 m).
const TUFT_SCALE := Vector2(1.4, 2.4)
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const AROUND: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1),
		Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const FLOWER_COLORS: Array[Color] = [Color(0.8, 0.15, 0.15), Color(0.9, 0.78, 0.25), Color(0.85, 0.5, 0.65),
		Color(0.9, 0.9, 0.85), Color(0.5, 0.45, 0.8)]

var _world: WorldState
var _simulation: Simulation
var _built_frame: int = -1
var _built_world: WorldState
var _data: GameData
var _config: GameConfig
var _meshes: Dictionary[int, Mesh] = {}
var _materials: Dictionary[int, Material] = {}
## chave "ilha/cx/cy" → os nós do trecho e as peças dele (para os testes: sem tela o MultiMesh devolve zeros).
var _chunks: Dictionary[String, Array] = {}
var _items: Dictionary[String, Dictionary] = {}
var _dirty: Dictionary[String, bool] = {}
var _roads: Dictionary[int, PackedByteArray] = {}
## Trechos refeitos desde o começo (testes).
var rebuilt_chunks: int = 0


func setup(world: WorldState, data: GameData = GameData.get_default(), config: GameConfig = null,
		simulation: Simulation = null) -> void:
	_world = world
	_simulation = simulation
	_data = data
	_config = config if config != null else GameConfig.get_default()
	var plain := StandardMaterial3D.new()
	plain.vertex_color_use_as_albedo = true
	plain.vertex_color_is_srgb = true
	plain.roughness = 0.9
	for kind: int in Kind.values():
		_meshes[kind] = piece_mesh(kind)
		_materials[kind] = CropView.plant_material(_meshes[kind], 0.1) if kind in PLANTS else plain
		if kind == Kind.STREET_PALM:
			# o coqueiro traz o material da folhagem das árvores (o vento das copas)
			_materials[kind] = _meshes[kind].surface_get_material(0)
	EventBus.building_placed.connect(_on_building_changed)
	EventBus.building_removed.connect(_on_building_changed)
	EventBus.roads_changed.connect(_on_roads_changed)
	# o trilho (Fase 70) tira o recheio das células dele (raro: refaz a ilha)
	EventBus.rails_changed.connect(func(island_id: int) -> void:
		var grid := _world.island(island_id)
		if grid != null:
			_mark(island_id, Rect2i(Vector2i.ZERO, grid.size)))
	EventBus.trees_changed.connect(func(island_id: int, area: Rect2i) -> void: _mark(island_id, area.grow(1)))
	EventBus.world_replaced.connect(_on_world_replaced)
	rebuild()


## Carregar troca o mundo: segue o da simulação. A vista nova que a GameScreen cria no mesmo quadro (save de outro
## mundo) já nasceu desenhada: não refaz duas vezes (custava ~0,7 s a mais no carregar).
func _on_world_replaced() -> void:
	if _simulation != null:
		_world = _simulation.world
	if Engine.get_process_frames() == _built_frame and _built_world == _world:
		return
	rebuild()


func rebuild() -> void:
	_built_frame = Engine.get_process_frames()
	_built_world = _world
	_occupancy.clear()
	for nodes: Array in _chunks.values():
		for node: Node in nodes:
			node.queue_free()
	_chunks.clear()
	_items.clear()
	_dirty.clear()
	_roads.clear()
	for index: int in _world.islands.size():
		var grid := _world.island(index)
		if grid.flat:
			continue
		_roads[index] = grid.roads.duplicate()
		var context := island_context(_world, _data, index)
		for cy: int in ceili(grid.size.y / float(CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(CHUNK_CELLS)):
				_build_chunk(index, Vector2i(cx, cy), context)


func _process(_delta: float) -> void:
	if _dirty.is_empty():
		return
	var contexts: Dictionary[int, Array] = {}
	for key: String in _dirty:
		var parts := key.split("/")
		var island_id := parts[0].to_int()
		if not contexts.has(island_id):
			contexts[island_id] = island_context(_world, _data, island_id)
		_build_chunk(island_id, Vector2i(parts[1].to_int(), parts[2].to_int()), contexts[island_id])
	_dirty.clear()


## Peças à vista (todas, ou de um tipo).
func item_count(kind: int = -1) -> int:
	var total := 0
	for items: Dictionary in _items.values():
		for each: int in items:
			if kind < 0 or each == kind:
				var list: Array = items[each]
				total += list.size()
	return total


## As peças de um trecho, por tipo (lugares no mundo).
func chunk_items(island_id: int, chunk: Vector2i) -> Dictionary:
	return _items.get("%d/%d/%d" % [island_id, chunk.x, chunk.y], {})


## Refaz no quadro seguinte os trechos que cruzam a área (células).
func _mark(island_id: int, area: Rect2i) -> void:
	var grid := _world.island(island_id)
	if grid == null or grid.flat:
		return
	var inside := area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	if not inside.has_area():
		return
	var first := inside.position / CHUNK_CELLS
	var last := (inside.end - Vector2i.ONE) / CHUNK_CELLS
	for cy: int in range(first.y, last.y + 1):
		for cx: int in range(first.x, last.x + 1):
			_dirty["%d/%d/%d" % [island_id, cx, cy]] = true


func _on_building_changed(building_id: int) -> void:
	var record := _world.building(building_id)
	if record == null:
		# demolido: a área já saiu do mundo; refaz a ilha toda é caro, então os trechos marcados pelas portas e pela
		# ocupação de agora bastam — o prédio removido some do trecho que ele ocupava, marcado pela diferença
		for index: int in _world.islands.size():
			_mark_changed_occupancy(index)
		return
	var def := _data.building(record.def_id)
	_mark(record.island_id, Footprint.rect(record.origin, def.size, record.rotation).grow(2))


## Depois de uma demolição: os trechos onde a ocupação mudou desde o último desenho.
var _occupancy: Dictionary[int, PackedInt32Array] = {}


func _mark_changed_occupancy(island_id: int) -> void:
	var grid := _world.island(island_id)
	if grid.flat:
		return
	var before: PackedInt32Array = _occupancy.get(island_id, PackedInt32Array())
	var now := grid.occupancy
	if before.size() == now.size():
		var width := grid.size.x
		for y: int in grid.size.y:
			var row := y * width
			if before.slice(row, row + width) == now.slice(row, row + width):
				continue
			for x: int in width:
				if before[row + x] != now[row + x]:
					_mark(island_id, Rect2i(x - 2, y - 2, 5, 5))
	_occupancy[island_id] = now.duplicate()


func _on_roads_changed(island_id: int) -> void:
	var grid := _world.island(island_id)
	if grid == null or grid.flat:
		return
	var before: PackedByteArray = _roads.get(island_id, PackedByteArray())
	var now := grid.roads
	var width := grid.size.x
	if before.size() == now.size():
		for y: int in grid.size.y:
			var row := y * width
			if before.slice(row, row + width) == now.slice(row, row + width):
				continue
			for x: int in width:
				if before[row + x] != now[row + x]:
					_mark(island_id, Rect2i(x - 1, y - 1, 3, 3))
	_roads[island_id] = now.duplicate()


func _build_chunk(island_id: int, chunk: Vector2i, context: Array) -> void:
	var key := "%d/%d/%d" % [island_id, chunk.x, chunk.y]
	if _chunks.has(key):
		for node: Node in _chunks[key]:
			remove_child(node)
			node.queue_free()
	if not _occupancy.has(island_id):
		_occupancy[island_id] = _world.island(island_id).occupancy.duplicate()
	var items := places(_world, _data, _config, island_id, chunk, context)
	_items[key] = items
	var nodes: Array = []
	for kind: int in items:
		var list: Array = items[kind]
		if list.is_empty():
			continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = _meshes[kind]
		multimesh.instance_count = list.size()
		for i: int in list.size():
			var item: Array = list[i]
			var place: Transform3D = item[0]
			var color: Color = item[1]
			multimesh.set_instance_transform(i, place)
			multimesh.set_instance_color(i, color)
		var node := MultiMeshInstance3D.new()
		node.name = "%s_%d_%d" % [Kind.keys()[kind], chunk.x, chunk.y]
		node.multimesh = multimesh
		node.material_override = _materials[kind]
		node.visibility_range_end = VISIBLE_UNTIL_M
		node.visibility_range_end_margin = VISIBLE_MARGIN_M
		if kind not in SHADOWED:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		nodes.append(node)
	_chunks[key] = nodes
	rebuilt_chunks += 1


## As portas (células da entrada), o tipo de cada prédio da ilha e se ela é tropical: [portas, tipos, tropical]. Feito
## uma vez por ilha a cada desenho (não por trecho).
static func island_context(world: WorldState, data: GameData, island_id: int) -> Array:
	var doors: Dictionary[Vector2i, bool] = {}
	var kinds: Dictionary[int, int] = {}
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id:
			continue
		var def := data.building(record.def_id)
		if def == null:
			continue
		kinds[id] = def.kind
		doors[Footprint.entrance_cell(record.origin, def.size, record.rotation)] = true
	# Fase 109: o largo calçado em volta dos serviços também fica limpo
	for cell: Vector2i in ForecourtView.cells(world, data, island_id):
		doors[cell] = true
	# Fase 113: e as árvores da alameda
	for cell: Vector2i in AvenueView.cells(world, island_id):
		doors[cell] = true
	# Fase 116: e as mesas da taverna
	for cell: Vector2i in TavernGardenView.cells(world, data, island_id):
		doors[cell] = true
	# Fase 117: e os silos das fazendas
	for cell: Vector2i in FarmSiloView.cells(world, data, island_id):
		doors[cell] = true
	return [doors, kinds, world.is_tropical(island_id, data)]


## As peças de um trecho: tipo → [[lugar no mundo, cor da instância], ...]. Função pura do mundo (testes, save).
static func places(world: WorldState, data: GameData, config: GameConfig, island_id: int, chunk: Vector2i,
		context: Array = []) -> Dictionary:
	var result: Dictionary = {}
	for kind: int in Kind.values():
		result[kind] = []
	var grid := world.island(island_id)
	if grid.flat:
		return result
	var area := Rect2i(chunk * CHUNK_CELLS, Vector2i(CHUNK_CELLS, CHUNK_CELLS)).intersection(Rect2i(Vector2i.ZERO, grid.size))
	if context.is_empty():
		context = island_context(world, data, island_id)
	# as portas dos prédios ficam limpas: é por onde se passa
	var doors: Dictionary[Vector2i, bool] = context[0]
	var kinds: Dictionary[int, int] = context[1]
	var tropical: bool = context[2]
	var trees := grid.trees
	var roads := grid.roads
	var rails := grid.rails
	var ground := grid.ground
	var occupancy := grid.occupancy
	var width := grid.size.x
	var height := grid.size.y
	# o laço é por célula do arquipélago inteiro (~0,7 s no jogo novo): índices direto nos arrays, sem chamar a grade
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var index := y * width + x
			if ground[index] != IslandGrid.Ground.LAND or trees[index] > 0 or roads[index] != IslandGrid.Road.NONE \
					or occupancy[index] != 0 or rails[index] != 0:
				continue
			var cell := Vector2i(x, y)
			if doors.has(cell):
				continue
			var forest := false
			var road := false
			var sea := false
			var house := Vector2i.ZERO
			var works := Vector2i.ZERO
			for step: Vector2i in AROUND:
				var ox := x + step.x
				var oy := y + step.y
				var side := absi(step.x) + absi(step.y) == 1
				if ox < 0 or oy < 0 or ox >= width or oy >= height:
					# fora da grade é mar
					sea = sea or side
					continue
				var j := oy * width + ox
				if trees[j] > 0:
					forest = true
				if not side:
					continue
				if roads[j] != IslandGrid.Road.NONE:
					road = true
				if ground[j] == IslandGrid.Ground.SEA:
					sea = true
				var building := occupancy[j]
				if building != 0 and kinds.has(building):
					var kind := kinds[building]
					if kind == BuildingDef.Kind.RESIDENCE:
						house = step
					elif kind == BuildingDef.Kind.PRODUCTION or kind == BuildingDef.Kind.WAREHOUSE \
							or kind == BuildingDef.Kind.SERVICE:
						works = step
			var rules: Array[Array] = OPEN
			var lean := Vector2i.ZERO
			if house != Vector2i.ZERO:
				rules = NEAR_HOUSE
				lean = house
			elif works != Vector2i.ZERO:
				rules = NEAR_WORKS
				lean = works
			elif forest:
				rules = NEAR_FOREST
			elif road:
				rules = NEAR_ROAD
			elif sea:
				rules = NEAR_SEA
			_cell_items(grid, config, island_id, cell, rules, lean, tropical, result)
	return result


## As peças de uma célula: cada regra sorteia pela célula; encostadas no prédio do lado "lean" (se houver). Na ilha
## tropical o arbusto vira bananeira ou samambaia.
static func _cell_items(grid: IslandGrid, config: GameConfig, island_id: int, cell: Vector2i, rules: Array[Array],
		lean: Vector2i, tropical: bool, result: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([island_id, cell, &"recheio"])
	for rule: Array in rules:
		var kind: int = rule[0]
		var chance: float = rule[1]
		if rng.randf() >= chance:
			continue
		if tropical and kind == Kind.BUSH:
			kind = Kind.BANANA if rng.randf() < BANANA_SHARE else Kind.FERN
		elif tropical and kind == Kind.FLOWERS:
			kind = Kind.HELICONIA
		elif tropical and kind == Kind.YARD_TREE:
			kind = Kind.BANANA
		elif kind == Kind.STREET_PALM and not tropical:
			# coqueiro de rua só nas tropicais (o sorteio já foi feito: as outras peças da célula não mudam)
			continue
		var offset := Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.35, 0.35))
		if kind == Kind.YARD_TREE or kind == Kind.STREET_PALM:
			# no meio da célula: a copa não encosta na parede da casa
			offset *= 0.15
		elif lean != Vector2i.ZERO:
			# junto da parede do prédio vizinho, espalhado ao longo dela
			offset = Vector2(lean) * 0.32 + Vector2(-lean.y, lean.x) * rng.randf_range(-0.35, 0.35)
		var x := grid.origin_m.x + (cell.x + 0.5 + offset.x) * grid.cell_size
		var z := grid.origin_m.y + (cell.y + 0.5 + offset.y) * grid.cell_size
		var y := grid.height_at(x, z) + TerrainDetail.offset_at(grid, config, x, z)
		var scale := rng.randf_range(TUFT_SCALE.x, TUFT_SCALE.y) if kind == Kind.TUFT else rng.randf_range(0.75, 1.25)
		if kind == Kind.YARD_TREE:
			# a copa nunca passa do raio dela
			scale = minf(scale, 1.0)
		elif kind == Kind.STREET_PALM:
			scale = STREET_PALM_SCALE * rng.randf_range(0.85, 1.15)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale)
		var color := Color.WHITE
		match kind:
			Kind.FLOWERS:
				color = FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]
			Kind.BUSH, Kind.TUFT, Kind.BANANA, Kind.FERN, Kind.HELICONIA, Kind.YARD_TREE, Kind.STREET_PALM:
				var shade := rng.randf_range(0.82, 1.12)
				color = Color(shade, shade, shade)
		var list: Array = result[kind]
		list.append([Transform3D(basis, Vector3(x, y, z)), color])


## A malha de cada peça, com a base em y = 0 (cor no vértice; a das flores vem da instância).
static func piece_mesh(kind: int) -> ArrayMesh:
	if kind == Kind.STREET_PALM:
		return TreeModel.mesh(TreeModel.Species.COCONUT_PALM, 0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		Kind.BUSH:
			for i: int in 3:
				var angle := TAU * i / 3.0
				CropView._part(tool, CropView._sphere(0.42 - i * 0.05), Transform3D(Basis.from_scale(Vector3(1.0, 0.85, 1.0)),
						Vector3(cos(angle) * 0.25, 0.36 + i * 0.06, sin(angle) * 0.25)),
						Color(0.22, 0.35, 0.14) if i % 2 == 0 else Color(0.28, 0.42, 0.17))
		Kind.TUFT:
			return CropView.tuft_mesh()
		Kind.FLOWERS:
			for i: int in 5:
				var angle := TAU * i / 5.0
				CropView._part(tool, CropView._box(Vector3(0.025, 0.3, 0.025)), Transform3D(Basis.IDENTITY,
						Vector3(cos(angle) * 0.1, 0.15, sin(angle) * 0.1)), Color(0.3, 0.48, 0.2))
				# a flor é branca no vértice: a cor sai da instância
				CropView._part(tool, CropView._sphere(0.05), Transform3D(Basis.IDENTITY, Vector3(cos(angle) * 0.1, 0.32,
						sin(angle) * 0.1)), Color.WHITE)
		Kind.PEBBLE:
			for i: int in 3:
				CropView._part(tool, CropView._sphere(0.12 - i * 0.03), Transform3D(Basis.from_scale(Vector3(1.3, 0.6, 1.0)),
						Vector3(-0.12 + i * 0.12, 0.03, (i % 2) * 0.1)), Color(0.5, 0.49, 0.45).darkened(0.1 * i))
		Kind.BARREL:
			CropView._part(tool, CropView._cylinder(0.27, 0.8), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.4, 0.0)),
					Color(0.45, 0.32, 0.2))
			for height: float in [0.15, 0.65]:
				CropView._part(tool, CropView._cylinder(0.285, 0.05), Transform3D(Basis.IDENTITY, Vector3(0.0, height, 0.0)),
						Color(0.25, 0.25, 0.27))
		Kind.CRATE:
			CropView._part(tool, CropView._box(Vector3(0.6, 0.55, 0.6)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.275, 0.0)),
					Color(0.55, 0.42, 0.27))
			CropView._part(tool, CropView._box(Vector3(0.45, 0.42, 0.45)), Transform3D(Basis(Vector3.UP, 0.4),
					Vector3(0.15, 0.76, 0.05)), Color(0.5, 0.38, 0.24))
		Kind.WOODPILE:
			for row: int in 3:
				for k: int in 4 - row:
					CropView._part(tool, CropView._cylinder(0.09, 1.0), Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(0.0, 0.09 + row * 0.16, -0.27 + k * 0.18 + row * 0.09)),
							Color(0.5, 0.36, 0.22).darkened(0.08 * ((row + k) % 2)))
		Kind.BANANA:
			# pseudocaule e seis folhas largas em remo, arqueadas para fora (~2,6 m)
			CropView._part(tool, CropView._cylinder(0.1, 1.5), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.75, 0.0)), BANANA_STEM)
			for i: int in 6:
				_leaf(tool, Vector3(0.0, 1.4 + (i % 2) * 0.12, 0.0), TAU * i / 6.0 + (i % 2) * 0.3, 1.4, 0.32,
						1.0 if i % 2 == 0 else 0.6, 0.9, 6, false, BANANA_LEAF.lerp(BANANA_STEM, 0.15 * (i % 3)))
		Kind.FERN:
			# roseta de oito frondes recortadas e arqueadas, rente ao chão (~0,6 m)
			for i: int in 8:
				_leaf(tool, Vector3(0.0, 0.05, 0.0), TAU * i / 8.0 + (i % 2) * 0.2, 0.75, 0.12, 0.7, 0.08, 5, true,
						FERN_LEAF.lightened(0.08 * (i % 2)))
		Kind.YARD_TREE:
			# macieira pequena: o tronco, a copa em quatro massas e meia dúzia de frutas por fora (~2,8 m)
			CropView._part(tool, CropView._cylinder(0.08, YARD_TRUNK_M), Transform3D(Basis.IDENTITY,
					Vector3(0.0, YARD_TRUNK_M * 0.5, 0.0)), YARD_BARK)
			for i: int in 4:
				var angle := TAU * i / 4.0 + 0.4
				var lump := Vector3(cos(angle) * 0.3, YARD_TRUNK_M + 0.35 + (i % 2) * 0.2, sin(angle) * 0.3)
				CropView._part(tool, CropView._sphere(YARD_CROWN_M * (0.62 - (i % 2) * 0.08)), Transform3D(Basis.IDENTITY, lump),
						YARD_LEAF.lightened(0.07 * (i % 2)))
			CropView._part(tool, CropView._sphere(YARD_CROWN_M * 0.55), Transform3D(Basis.IDENTITY,
					Vector3(0.0, YARD_TRUNK_M + 0.75, 0.0)), YARD_LEAF.lightened(0.05))
			for i: int in 6:
				var angle := TAU * i / 6.0
				CropView._part(tool, CropView._sphere(0.06), Transform3D(Basis.IDENTITY, Vector3(cos(angle) * 0.62,
						YARD_TRUNK_M + 0.25 + (i % 3) * 0.2, sin(angle) * 0.62)), YARD_FRUIT)
		Kind.HELICONIA:
			# quatro folhas em remo, em pé, e duas hastes com brácteas vermelhas de ponta amarela alternadas em
			# zigue-zague (~1,2 m); a instância só varia o tom, como no arbusto
			for i: int in 4:
				_leaf(tool, Vector3(0.0, 0.05, 0.0), TAU * i / 4.0 + 0.4, 0.45, 0.12, 0.7, -0.35, 4, false, HELICONIA_LEAF)
			for stalk: int in 2:
				var foot := Vector3(0.1 * (1 - 2 * stalk), 0.0, 0.06)
				CropView._part(tool, CropView._box(Vector3(0.03, 1.15, 0.03)), Transform3D(Basis.IDENTITY,
						foot + Vector3(0.0, 0.575, 0.0)), HELICONIA_LEAF)
				for b: int in 5:
					var side := 1.0 if b % 2 == 0 else -1.0
					var bract := Basis(Vector3.BACK, side * 0.9)
					var at := foot + Vector3(side * 0.09, 1.2 - b * 0.14, 0.0)
					CropView._part(tool, CropView._box(Vector3(0.08, 0.22, 0.03)), Transform3D(bract, at), HELICONIA_BRACT)
					CropView._part(tool, CropView._box(Vector3(0.06, 0.05, 0.035)), Transform3D(bract,
							at + bract.y * 0.12), HELICONIA_TIP)
	tool.index()
	return tool.commit()


## Uma folha: a nervura sai de base para o lado de angle, length metros, subindo rise e caindo droop até a ponta; a
## lâmina em volta tem meia largura width (afinando nas pontas) e, se serrated, alterna estreita (frondes recortadas).
static func _leaf(tool: SurfaceTool, base: Vector3, angle: float, length: float, width: float, rise: float, droop: float,
		steps: int, serrated: bool, color: Color) -> void:
	var out := Vector3(cos(angle), 0.0, sin(angle))
	var side := Vector3(-out.z, 0.0, out.x)
	var spine: Array[Vector3] = []
	for s: int in steps + 1:
		var t := float(s) / steps
		spine.append(base + out * length * t + Vector3.UP * (rise * 4.0 * t * (1.0 - t) - droop * t * t))
	for s: int in steps:
		var widths: Array[float] = []
		for k: int in [s, s + 1]:
			var w := width * sin(PI * float(k) / steps)
			if serrated and k % 2 == 1:
				w *= 0.45
			widths.append(w)
		var along := (spine[s + 1] - spine[s]).normalized()
		var normal := side.cross(along).normalized()
		if normal.y < 0.0:
			normal = -normal
		for edge: float in [-1.0, 1.0]:
			var a := spine[s]
			var b := spine[s + 1]
			var c := b + side * edge * widths[1] + Vector3.DOWN * widths[1] * 0.15
			var d := a + side * edge * widths[0] + Vector3.DOWN * widths[0] * 0.15
			for point: Vector3 in [a, b, c, a, c, d]:
				tool.set_color(color)
				tool.set_normal(normal)
				tool.add_vertex(point)
