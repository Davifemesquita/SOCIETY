class_name TreeView
extends Node3D
## Árvores e pedras (seção 7): saem da grade da ilha (árvores por célula, que a simulação gerou
## pela semente) e são desenhadas em MultiMesh por trecho de CHUNK_CELLS × CHUNK_CELLS e por
## modelo. Derrubar árvores ao construir refaz só o trecho atingido (trees_changed). Posição,
## giro e tamanho de cada árvore saem do índice da célula: o mesmo mundo dá sempre a mesma mata.
## Nas ilhas tropicais (Fase 11), palmeiras no lugar da mata; desde a Fase 58, o coqueiro do `TreeModel` (três
## variantes, com a malha de longe), no lugar das palmeiras do Kenney; desde a Fase 59, misturado à folhosa tropical
## (mais coqueiro na terra baixa da costa, mais folhosa no alto). Desde a Fase 22 a mata temperada é gerada no código (`TreeModel`): carvalho e faia entre as
## folhosas, pinheiro-silvestre entre as coníferas, duas variantes de cada, já em metros.
## Desde a Fase 36 as pedras são de rocha de verdade (a textura de rocha do terreno, triplanar, sem o musgo verde
## recolorido), aparecem mais nos barrancos altos e no litoral rochoso e sentam na malha com o detalhe visual
## (TerrainDetail), não na altura lisa da simulação.
## Desde a Fase 57 as pedras são a rocha gerada da Fase 56 (`RockModel`, com o material da `RockView`): faces
## partidas, quatro formas, no lugar das lajes lisas do Kenney.
## Desde a Fase 140 as células de mata cortadas em volta dos lenhadores (`StumpView.cut_cells`) ficam sem árvore no
## desenho (a simulação ainda as conta); refeitas quando um prédio entra ou sai.
## Desde a Fase 275 a conífera da mata é quase sempre o abeto-vermelho (galhos até perto do chão); o pinheiro-silvestre fica
## em PINE_SHARE delas, mais nos patamares altos. Desde a Fase 276 a mata temperada tem uma árvore por célula, só em parte das
## células (`drawn_seeds`); desde a Fase 277, bétulas entre as folhosas, mais na beira e na terra baixa.

const CHUNK_CELLS := 64
## Folhosas e coníferas: [espécie, variante] do TreeModel.
## Fase 277: as bétulas no fim (`broadleaf_pick` escolhe).
const BROADLEAF: Array[Array] = [[TreeModel.Species.OAK, 0], [TreeModel.Species.OAK, 1], [TreeModel.Species.BEECH, 0],
		[TreeModel.Species.BEECH, 1], [TreeModel.Species.BIRCH, 0], [TreeModel.Species.BIRCH, 1]]
## Fase 277: entre as folhosas, a parte de bétulas: BIRCH_SHARE_EDGE na beira da mata (a célula de uma árvore só),
## BIRCH_SHARE_LOW na terra baixa (abaixo de BIRCH_LOW_M) e BIRCH_SHARE no resto.
const BIRCH_SHARE_EDGE := 0.4
const BIRCH_SHARE_LOW := 0.25
const BIRCH_SHARE := 0.1
const BIRCH_LOW_M := 4.0
## Fase 278: a orla da mata. Na célula de mata temperada que dá para o campo (um lado de terra sem árvore), uma árvore nova em
## YOUNG_CHANCE delas, puxada para o lado aberto (YOUNG_OUT da célula) e de YOUNG_SCALE.x a YOUNG_SCALE.y do tamanho: a mata desce
## em degrau até o campo e cobre o pé dos troncos de trás. Abeto, bétula ou folhosa pelas partes YOUNG_SPRUCE e YOUNG_BIRCH.
const YOUNG_CHANCE := 0.75
const YOUNG_OUT := 0.3
const YOUNG_SCALE := Vector2(0.32, 0.55)
const YOUNG_SPRUCE := 0.5
const YOUNG_BIRCH := 0.15
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Fase 275: os abetos primeiro, depois os pinheiros (`conifer_pick` escolhe entre eles).
const CONIFER: Array[Array] = [[TreeModel.Species.NORWAY_SPRUCE, 0], [TreeModel.Species.NORWAY_SPRUCE, 1],
		[TreeModel.Species.SCOTS_PINE, 0], [TreeModel.Species.SCOTS_PINE, 1]]
## Fase 275: entre as coníferas, a parte de pinheiros; acima de PINE_HEIGHT_M (os patamares mais altos), a de cima. O resto é
## abeto.
const PINE_SHARE := 0.2
const PINE_SHARE_HIGH := 0.6
const PINE_HEIGHT_M := 12.0
## Formas de pedra: as variantes do RockModel.
const ROCKS := RockModel.VARIANTS
const PALMS: Array[Array] = [[TreeModel.Species.COCONUT_PALM, 0], [TreeModel.Species.COCONUT_PALM, 1], [TreeModel.Species.COCONUT_PALM, 2]]
## Fase 59: a folhosa da mata tropical, misturada aos coqueiros.
const TROPICAL: Array[Array] = [[TreeModel.Species.TROPICAL_BROADLEAF, 0], [TreeModel.Species.TROPICAL_BROADLEAF, 1]]
## Na ilha tropical, abaixo desta altura do terreno (a terra baixa da costa) quase tudo é coqueiro; acima, a mata é
## mais de folhosa.
const PALM_HEIGHT_M := 3.0
const PALM_SHARE_LOW := 0.8
const PALM_SHARE_HIGH := 0.3
## Raio da pedra (a RockModel tem raio 1) e quanto ela é mais alta que larga.
const ROCK_SIZE_M := 1.0
const ROCK_TALL := 1.25
## Acima desta altura do terreno, mais pinheiro que folhosa.
const CONIFER_HEIGHT_M := 6.0
## Célula mais íngreme que isto (diferença entre cantos) ganha pedra de vez em quando.
const ROCK_RELIEF_M := 2.5
const ROCK_CHANCE := 0.25
## Litoral rochoso (Fase 36): célula de terra encostada no mar com pelo menos este desnível ganha pedra mais vezes.
const COAST_ROCK_RELIEF_M := 1.2
const COAST_ROCK_CHANCE := 0.35
## As pedras afundam isto no chão (a malha tem detalhe e a base da pedra não pode aparecer flutuando); a parte de
## baixo da RockModel (y abaixo de zero) já fica enterrada.
const ROCK_SINK_M := 0.15
const VISIBLE_UNTIL_M := 900.0
## Até esta distância do trecho (do meio dele) a árvore do TreeModel é a de perto; depois, a de longe
## (Fase 22). O trecho tem 128 m: no pior caso a árvore da borda troca a ~110 m da câmera.
const NEAR_UNTIL_M := 200.0
## Histerese da troca (Fase 41): a árvore que passou para a de longe só volta à de perto LOD_MARGIN_M antes, e
## vice-versa — a câmera parada na divisa não fica piscando entre as duas.
const LOD_MARGIN_M := 24.0
## Desenhadas no máximo tantas árvores por célula (a regra do lenhador conta todas): a copa de
## uma árvore de 8 m já cobre a célula de 2 m. Desde a Fase 276, só nas ilhas tropicais (e nos tocos da clareira).
const DRAWN_PER_CELL := 2
## Fase 276: na mata temperada, no máximo uma árvore por célula, e só em parte das células de mata: DRAWN_SHARE_EDGE nas de uma
## árvore só (a beira), DRAWN_SHARE nas de duas e DRAWN_SHARE_DEEP no miolo (três ou mais). Com duas por célula e a copa de
## ~8 m, a mata era um tapete de bolhas sem vão; agora cada árvore se lê, com o chão e a sombra entre elas, e o miolo fecha mais
## que a beira. Tamanho de cada uma de SCALE_MIN a SCALE_MIN + SCALE_SPREAD (eram 0,75 a 1,25).
const TEMPERATE_PER_CELL := 1
const DRAWN_SHARE_EDGE := 0.5
const DRAWN_SHARE := 0.65
const DRAWN_SHARE_DEEP := 0.8
const SCALE_MIN := 0.65
const SCALE_SPREAD := 0.6

var _world: WorldState
var _models: Array[Mesh] = []
## A malha de longe de cada modelo (null nas pedras, que não têm).
var _far_models: Array[Mesh] = []
## Fator de escala de cada modelo para chegar à altura certa.
var _scales: PackedFloat32Array = []
## Ilhas de clima tropical (desenham palmeiras).
var _tropical: Dictionary[int, bool] = {}
## chave "ilha/cx/cy" → os MultiMeshInstance3D do trecho, um por modelo.
var _chunks: Dictionary[String, Array] = {}
var _config: GameConfig
var _data: GameData
## Fase 140: ilha → as células de mata cortadas em volta dos lenhadores (sem árvore no desenho).
var _cut: Dictionary[int, Dictionary] = {}
## Fase 140: lenhador → ilha, e os trechos a refazer no quadro seguinte.
var _lumberjacks: Dictionary[int, int] = {}
var _pending: Dictionary[String, bool] = {}
var _recut_islands: Dictionary[int, bool] = {}


func setup(world: WorldState, data: GameData = GameData.get_default(), config: GameConfig = null) -> void:
	_world = world
	_config = config if config != null else GameConfig.get_default()
	_data = data
	for id: int in world.buildings:
		if world.buildings[id].def_id == &"lumberjack":
			_lumberjacks[id] = world.buildings[id].island_id
	_add_trees(BROADLEAF + CONIFER)
	for variant: int in ROCKS:
		_models.append(_stone(RockModel.mesh(variant)))
		_far_models.append(null)
		_scales.append(ROCK_SIZE_M)
	_add_trees(PALMS)
	_add_trees(TROPICAL)
	for index: int in world.islands.size():
		if world.is_tropical(index, data):
			_tropical[index] = true
		var grid := world.island(index)
		if grid.flat:
			continue
		_cut[index] = StumpView.cut_cells(world, data, _config, index)
		for cy: int in ceili(grid.size.y / float(CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(CHUNK_CELLS)):
				_build_chunk(index, Vector2i(cx, cy))
	EventBus.trees_changed.connect(_on_trees_changed)
	EventBus.roads_changed.connect(_recut)
	EventBus.building_placed.connect(_on_buildings_changed)
	EventBus.building_removed.connect(_on_buildings_changed)


## Os modelos de [espécie, variante] do TreeModel, perto e longe, já em metros.
func _add_trees(trees: Array) -> void:
	for tree: Array in trees:
		var species: TreeModel.Species = tree[0]
		var variant: int = tree[1]
		_models.append(TreeModel.mesh(species, variant))
		_far_models.append(TreeModel.mesh(species, variant, TreeModel.DETAIL_FAR))
		_scales.append(1.0)


## Árvores e pedras desenhadas (a camada de longe repete as de perto e não conta).
func instance_count() -> int:
	var total := 0
	for instances: Array in _chunks.values():
		for node: MultiMeshInstance3D in instances:
			# a camada de longe começa longe (o nome não serve: o Godot renomeia os repetidos de outros trechos)
			if node.visibility_range_begin == 0.0:
				total += node.multimesh.instance_count
	return total


## As camadas de um trecho, perto e longe, para os testes do nível de detalhe.
func chunk_layers(island_id: int, chunk: Vector2i) -> Array:
	return _chunks.get("%d/%d/%d" % [island_id, chunk.x, chunk.y], [])


## Palmeiras desenhadas numa ilha (as das ilhas tropicais; a camada de longe não conta).
func palm_count(island_id: int) -> int:
	return _count_layers(island_id, "Palm")


## Folhosas tropicais desenhadas numa ilha (Fase 59; a camada de longe não conta).
func tropical_count(island_id: int) -> int:
	return _count_layers(island_id, "Tropical")


func _count_layers(island_id: int, kind: String) -> int:
	var total := 0
	for key: String in _chunks:
		if key.begins_with("%d/" % island_id):
			for node: MultiMeshInstance3D in _chunks[key]:
				if String(node.name).contains(kind) and node.visibility_range_begin == 0.0:
					total += node.multimesh.instance_count
	return total


func _on_trees_changed(island_id: int, area: Rect2i) -> void:
	# Fase 148: as árvores caídas podem mudar o terreiro do lenhador
	_recut(island_id)
	var first := area.position / CHUNK_CELLS
	var last := (area.end - Vector2i.ONE) / CHUNK_CELLS
	for cy: int in range(first.y, last.y + 1):
		for cx: int in range(first.x, last.x + 1):
			_build_chunk(island_id, Vector2i(cx, cy))


## Fase 140: um lenhador entrou ou saiu: refaz o corte da ilha dele e marca para o quadro seguinte os trechos das células
## que mudaram (vários lenhadores no mesmo quadro refazem o trecho uma vez). Outros prédios não mexem no corte.
func _on_buildings_changed(building_id: int) -> void:
	var record := _world.building(building_id)
	var island_id := -1
	if record != null and record.def_id == &"lumberjack":
		_lumberjacks[building_id] = record.island_id
		island_id = record.island_id
	elif _lumberjacks.has(building_id):
		island_id = _lumberjacks[building_id]
		_lumberjacks.erase(building_id)
	_recut(island_id)


## Refaz o corte da ilha (com os lenhadores dela) e marca para o quadro seguinte os trechos das células que mudaram. Fase
## 148: também quando uma estrada ou uma derrubada de árvores muda o lugar do terreiro do lenhador (só ilha com lenhador).
func _recut(island_id: int) -> void:
	if _cut.has(island_id):
		_recut_islands[island_id] = true


## O recálculo de fato (no quadro seguinte: a montagem de uma cidade manda centenas de estradas no mesmo quadro).
func _recut_now(island_id: int) -> void:
	var ids: Array[int] = []
	for id: int in _lumberjacks:
		if _lumberjacks[id] == island_id:
			ids.append(id)
	var before: Dictionary = _cut[island_id]
	if ids.is_empty() and before.is_empty():
		return
	var after := StumpView.cut_cells_of(_world, _data, _config, island_id, ids)
	for cell: Vector2i in before:
		if not after.has(cell):
			_pending["%d/%d/%d" % [island_id, cell.x / CHUNK_CELLS, cell.y / CHUNK_CELLS]] = true
	for cell: Vector2i in after:
		if not before.has(cell):
			_pending["%d/%d/%d" % [island_id, cell.x / CHUNK_CELLS, cell.y / CHUNK_CELLS]] = true
	_cut[island_id] = after


func _process(_delta: float) -> void:
	if not _pending.is_empty() or not _recut_islands.is_empty():
		flush()


## Refaz já o corte das ilhas marcadas e os trechos que mudaram (testes; o jogo espera o quadro seguinte).
func flush() -> void:
	for island_id: int in _recut_islands:
		_recut_now(island_id)
	_recut_islands.clear()
	for key: String in _pending:
		var parts := key.split("/")
		_build_chunk(parts[0].to_int(), Vector2i(parts[1].to_int(), parts[2].to_int()))
	_pending.clear()


## Fase 140: a célula está cortada no desenho (sem árvore).
func is_cut(island_id: int, cell: Vector2i) -> bool:
	var cut: Dictionary = _cut.get(island_id, {})
	return cut.has(cell)


## Refaz o trecho: junta as árvores (e pedras) das células dele por modelo e escreve os buffers.
func _build_chunk(island_id: int, chunk: Vector2i) -> void:
	var key := "%d/%d/%d" % [island_id, chunk.x, chunk.y]
	if _chunks.has(key):
		# o antigo sai da árvore antes: o novo de mesmo nome ganharia nome gerado (sem o "Far")
		for node: MultiMeshInstance3D in _chunks[key]:
			remove_child(node)
			node.queue_free()
		_chunks.erase(key)
	var grid := _world.island(island_id)
	var tropical := _tropical.has(island_id)
	var cut: Dictionary = _cut.get(island_id, {})
	# cada entrada: [modelo, 12 floats da transformação]; o buffer de cada modelo é montado numa
	# variável local (array empacotado dentro de outro array pode ser alterado numa cópia)
	var entries: Array[Array] = []
	var area := Rect2i(chunk * CHUNK_CELLS, Vector2i(CHUNK_CELLS, CHUNK_CELLS)).intersection(Rect2i(Vector2i.ZERO, grid.size))
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			var index := grid.index(cell)
			var count := grid.trees[index]
			if count > 0 and cut.has(cell):
				# Fase 140: cortada em volta do lenhador (os tocos são da StumpView)
				continue
			if count > 0:
				var high := grid.cell_height(cell) >= CONIFER_HEIGHT_M
				for seed_value: int in drawn_seeds(island_id, index, count, tropical):
					if tropical:
						# coqueiro na terra baixa da costa, folhosa tropical mais para o alto
						var share := PALM_SHARE_LOW if grid.cell_height(cell) < PALM_HEIGHT_M else PALM_SHARE_HIGH
						var first_palm := BROADLEAF.size() + CONIFER.size() + ROCKS
						var pick := first_palm + (seed_value / 7) % PALMS.size()
						if (seed_value / 3 % 100) >= share * 100.0:
							pick = first_palm + PALMS.size() + (seed_value / 7) % TROPICAL.size()
						entries.append([pick, _transform(grid, cell, seed_value, _scales[pick] * (0.75 + (seed_value / 13 % 50) / 100.0))])
						continue
					var conifer := (seed_value % 100) < (70 if high else 20)
					var model := broadleaf_pick(seed_value, count, grid.cell_height(cell))
					if conifer:
						model = BROADLEAF.size() + conifer_pick(seed_value, grid.cell_height(cell))
					entries.append([model, _transform(grid, cell, seed_value, _scales[model] * tree_scale(seed_value))])
				if not tropical:
					var young := young_entry(grid, island_id, cell)
					if not young.is_empty():
						entries.append(young)
			elif grid.ground[index] == IslandGrid.Ground.LAND:
				var chance := rock_chance(grid, cell)
				var seed_value := hash([island_id, index, "pedra"])
				if chance > 0.0 and (seed_value % 1000) < chance * 1000.0:
					var model := BROADLEAF.size() + CONIFER.size() + seed_value % ROCKS
					var placed := _transform(grid, cell, seed_value, _scales[model] * (0.7 + (seed_value / 11 % 60) / 100.0))
					# mais alta que larga: o eixo y da base (colunas 1, 5 e 9 do buffer) esticado
					for column: int in [1, 5, 9]:
						placed[column] *= ROCK_TALL
					# em cima da malha desenhada (com o detalhe das encostas), afundada um pouco
					placed[7] += TerrainDetail.offset_at(grid, _config, placed[3], placed[11]) - ROCK_SINK_M
					entries.append([model, placed])
	var nodes: Array = []
	for model: int in _models.size():
		if _models[model] == null:
			continue
		var buffer := PackedFloat32Array()
		for entry: Array in entries:
			if entry[0] == model:
				var floats: PackedFloat32Array = entry[1]
				buffer.append_array(floats)
		if buffer.is_empty():
			continue
		var first_palm := BROADLEAF.size() + CONIFER.size() + ROCKS
		var name_text := "Trees%d" % model
		if model >= first_palm + PALMS.size():
			name_text = "Tropical%d" % model
		elif model >= first_palm:
			name_text = "Palm%d" % model
		var far := _far_models[model]
		var near := _layer(name_text, _models[model], buffer, 0.0, NEAR_UNTIL_M if far != null else VISIBLE_UNTIL_M)
		nodes.append(near)
		if far != null:
			nodes.append(_layer(name_text + "Far", far, buffer, NEAR_UNTIL_M, VISIBLE_UNTIL_M))
	_chunks[key] = nodes


## Uma camada do trecho: as instâncias do buffer com a malha dada, visível entre as duas distâncias.
func _layer(name_text: String, mesh: Mesh, buffer: PackedFloat32Array, from_m: float, until_m: float) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = buffer.size() / 12
	multimesh.buffer = buffer
	var node := MultiMeshInstance3D.new()
	node.name = name_text
	node.multimesh = multimesh
	node.visibility_range_begin = from_m
	node.visibility_range_end = until_m
	if from_m > 0.0:
		node.visibility_range_begin_margin = LOD_MARGIN_M
	if until_m < VISIBLE_UNTIL_M:
		node.visibility_range_end_margin = LOD_MARGIN_M
	add_child(node)
	return node


## Uma instância: num ponto sorteado da célula, no chão, girada e na escala dada (12 floats, na
## ordem do buffer do MultiMesh).
static func _transform(grid: IslandGrid, cell: Vector2i, seed_value: int, scale: float) -> PackedFloat32Array:
	var jitter := Vector2((seed_value % 97) / 97.0, (seed_value / 97 % 89) / 89.0) * 0.8 + Vector2(0.1, 0.1)
	var x := grid.origin_m.x + (cell.x + jitter.x) * grid.cell_size
	var z := grid.origin_m.y + (cell.y + jitter.y) * grid.cell_size
	var basis := Basis(Vector3.UP, (seed_value % 360) * PI / 180.0).scaled(Vector3.ONE * scale)
	return PackedFloat32Array([basis.x.x, basis.y.x, basis.z.x, x, basis.x.y, basis.y.y, basis.z.y,
			grid.height_at(x, z) - 0.1, basis.x.z, basis.y.z, basis.z.z, z])


## Fase 276: os sorteios das árvores que o desenho põe na célula de índice index com count árvores: na ilha tropical até
## DRAWN_PER_CELL; na temperada uma, e só em parte das células (`draws_tree`). Os tocos da clareira (StumpView) saem dos mesmos.
static func drawn_seeds(island_id: int, index: int, count: int, tropical: bool) -> Array[int]:
	var seeds: Array[int] = []
	for n: int in mini(count, DRAWN_PER_CELL if tropical else TEMPERATE_PER_CELL):
		var seed_value := hash([island_id, index, n])
		if tropical or draws_tree(seed_value, count):
			seeds.append(seed_value)
	return seeds


## Fase 276: se a árvore temperada de sorteio seed_value, numa célula de count árvores, é desenhada (vãos na mata).
static func draws_tree(seed_value: int, count: int) -> bool:
	var share := DRAWN_SHARE_EDGE if count <= 1 else (DRAWN_SHARE if count == 2 else DRAWN_SHARE_DEEP)
	return (seed_value / 29 % 100) < share * 100.0


## Fase 276: o tamanho da árvore temperada pelo sorteio dela, de SCALE_MIN a SCALE_MIN + SCALE_SPREAD.
static func tree_scale(seed_value: int) -> float:
	return SCALE_MIN + (seed_value / 13 % 100) / 100.0 * SCALE_SPREAD


## Fase 278: a árvore nova da orla na célula de mata temperada: [modelo, 12 floats da transformação], ou vazio se a célula não
## dá para o campo ou o sorteio não pôs árvore. Fica puxada para o lado aberto (a soma dos lados de terra sem árvore).
static func young_entry(grid: IslandGrid, island_id: int, cell: Vector2i) -> Array:
	var open := Vector2.ZERO
	for side: Vector2i in SIDES:
		var other := cell + side
		if not grid.in_bounds(other):
			continue
		var index := grid.index(other)
		if grid.trees[index] == 0 and grid.ground[index] == IslandGrid.Ground.LAND:
			open += Vector2(side)
	if open == Vector2.ZERO:
		return []
	var seed_value := hash([island_id, grid.index(cell), "orla"])
	if (seed_value % 100) >= YOUNG_CHANCE * 100.0:
		return []
	var roll := (seed_value / 7 % 100) / 100.0
	var model := (seed_value / 3) % 4
	if roll < YOUNG_SPRUCE:
		model = BROADLEAF.size() + (seed_value / 3) % 2
	elif roll < YOUNG_SPRUCE + YOUNG_BIRCH:
		model = 4 + (seed_value / 3) % 2
	var scale := YOUNG_SCALE.x + (seed_value / 11 % 100) / 100.0 * (YOUNG_SCALE.y - YOUNG_SCALE.x)
	var floats := _transform(grid, cell, seed_value, scale)
	# puxada para o lado aberto, sem sair da célula (a vizinha pode ser estrada ou lote), na altura do chão de lá
	var shift := open.normalized() * YOUNG_OUT * grid.cell_size
	var low := Vector2(grid.origin_m) + Vector2(cell) * grid.cell_size + Vector2.ONE * 0.15
	var high := low + Vector2.ONE * (grid.cell_size - 0.3)
	floats[3] = clampf(floats[3] + shift.x, low.x, high.x)
	floats[11] = clampf(floats[11] + shift.y, low.y, high.y)
	floats[7] = grid.height_at(floats[3], floats[11]) - 0.1
	return [model, floats]


## Fase 277: a folhosa da árvore (índice em BROADLEAF) pelo sorteio dela, pelas árvores da célula (count) e pela altura do chão:
## bétula mais na beira e na terra baixa; carvalho e faia pelo mesmo sorteio de antes.
static func broadleaf_pick(seed_value: int, count: int, height_m: float) -> int:
	var share := BIRCH_SHARE
	if count <= 1:
		share = BIRCH_SHARE_EDGE
	elif height_m < BIRCH_LOW_M:
		share = BIRCH_SHARE_LOW
	if (seed_value / 31 % 100) < share * 100.0:
		return 4 + (seed_value / 7) % 2
	return (seed_value / 7) % 4


## Fase 275: a conífera da árvore (índice em CONIFER) pelo sorteio dela e pela altura do chão: abeto na maior parte, pinheiro
## em PINE_SHARE (PINE_SHARE_HIGH acima de PINE_HEIGHT_M); a variante pelo mesmo sorteio de antes.
static func conifer_pick(seed_value: int, height_m: float) -> int:
	var share := PINE_SHARE_HIGH if height_m >= PINE_HEIGHT_M else PINE_SHARE
	var pine := (seed_value / 11 % 100) < share * 100.0
	return (2 if pine else 0) + (seed_value / 7) % 2


## Chance de pedra na célula de terra sem árvore: barranco alto, ou litoral rochoso (terra encostada no mar com
## desnível). Zero no resto.
static func rock_chance(grid: IslandGrid, cell: Vector2i) -> float:
	var relief := grid.area_relief(Rect2i(cell, Vector2i.ONE))
	if relief > ROCK_RELIEF_M:
		return ROCK_CHANCE
	if relief > COAST_ROCK_RELIEF_M and grid.area_touches(Rect2i(cell, Vector2i.ONE), IslandGrid.Ground.SEA):
		return COAST_ROCK_CHANCE
	return 0.0


## Cópia da malha da pedra com o material de rocha da RockView (a textura de rocha do terreno, triplanar no mundo:
## não estica em pedra nenhuma e casa com a falésia e os rochedos em volta). A malha guardada da RockModel não muda.
static func _stone(mesh: ArrayMesh) -> Mesh:
	var copy := mesh.duplicate() as ArrayMesh
	var material := RockView.material()
	for surface: int in copy.get_surface_count():
		copy.surface_set_material(surface, material)
	return copy


## Material da primeira superfície da pedra (testes).
func rock_material() -> Material:
	var model := _models[BROADLEAF.size() + CONIFER.size()]
	return model.surface_get_material(0) if model != null else null
