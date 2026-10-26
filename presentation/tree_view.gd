class_name TreeView
extends Node3D
## Árvores e pedras (seção 7): saem da grade da ilha (árvores por célula, que a simulação gerou
## pela semente) e são desenhadas em MultiMesh por trecho de CHUNK_CELLS × CHUNK_CELLS e por
## modelo. Derrubar árvores ao construir refaz só o trecho atingido (trees_changed). Posição,
## giro e tamanho de cada árvore saem do índice da célula: o mesmo mundo dá sempre a mesma mata.
## Pedras e palmeiras do Kenney Nature Kit (CC0); nas ilhas tropicais (Fase 11), palmeiras no lugar da
## mata. Desde a Fase 22 a mata temperada é gerada no código (`TreeModel`): carvalho e faia entre as
## folhosas, pinheiro-silvestre entre as coníferas, duas variantes de cada, já em metros.
## Desde a Fase 36 as pedras são de rocha de verdade (a textura de rocha do terreno, triplanar, sem o musgo verde
## recolorido), aparecem mais nos barrancos altos e no litoral rochoso e sentam na malha com o detalhe visual
## (TerrainDetail), não na altura lisa da simulação.

const CHUNK_CELLS := 64
## Folhosas e coníferas: [espécie, variante] do TreeModel.
const BROADLEAF: Array[Array] = [[TreeModel.Species.OAK, 0], [TreeModel.Species.OAK, 1], [TreeModel.Species.BEECH, 0], [TreeModel.Species.BEECH, 1]]
const CONIFER: Array[Array] = [[TreeModel.Species.SCOTS_PINE, 0], [TreeModel.Species.SCOTS_PINE, 1]]
const ROCKS: Array[String] = ["rock_largeA", "rock_largeB"]
const PALMS: Array[String] = ["tree_palm", "tree_palmTall", "tree_palmBend"]
const MODEL_DIR := "res://assets/models/nature/%s.glb"
## Altura de uma palmeira adulta e das pedras, em metros (as árvores do TreeModel já vêm no tamanho).
const TREE_HEIGHT_M := 8.0
const ROCK_SIZE_M := 1.6
## Acima desta altura do terreno, mais pinheiro que folhosa.
const CONIFER_HEIGHT_M := 6.0
## Célula mais íngreme que isto (diferença entre cantos) ganha pedra de vez em quando.
const ROCK_RELIEF_M := 2.5
const ROCK_CHANCE := 0.25
## Litoral rochoso (Fase 36): célula de terra encostada no mar com pelo menos este desnível ganha pedra mais vezes.
const COAST_ROCK_RELIEF_M := 1.2
const COAST_ROCK_CHANCE := 0.35
## As pedras afundam isto no chão (a malha tem detalhe e a base da pedra não pode aparecer flutuando).
const ROCK_SINK_M := 0.3
## Textura de rocha do terreno nas pedras, em metros por repetição.
const ROCK_TEXTURE_M := 3.0
const VISIBLE_UNTIL_M := 900.0
## Até esta distância do trecho (do meio dele) a árvore do TreeModel é a de perto; depois, a de longe
## (Fase 22). O trecho tem 128 m: no pior caso a árvore da borda troca a ~110 m da câmera.
const NEAR_UNTIL_M := 200.0
## Histerese da troca (Fase 41): a árvore que passou para a de longe só volta à de perto LOD_MARGIN_M antes, e
## vice-versa — a câmera parada na divisa não fica piscando entre as duas.
const LOD_MARGIN_M := 24.0
## Desenhadas no máximo tantas árvores por célula (a regra do lenhador conta todas): a copa de
## uma árvore de 8 m já cobre a célula de 2 m.
const DRAWN_PER_CELL := 2
## Cores das superfícies dos modelos do pacote (as dele são de desenho animado): pedra, musgo e palmeira.
const STONE_COLOR := Color(0.47, 0.46, 0.43)
const MOSS_COLOR := Color(0.3, 0.37, 0.22)
const PALM_COLOR := Color(0.24, 0.42, 0.14)
const PALM_TRUNK_COLOR := Color(0.46, 0.36, 0.24)

var _world: WorldState
var _models: Array[Mesh] = []
## A malha de longe de cada modelo (null nos que não têm: pedras e palmeiras).
var _far_models: Array[Mesh] = []
## Fator de escala de cada modelo para chegar à altura certa.
var _scales: PackedFloat32Array = []
## Ilhas de clima tropical (desenham palmeiras).
var _tropical: Dictionary[int, bool] = {}
## chave "ilha/cx/cy" → os MultiMeshInstance3D do trecho, um por modelo.
var _chunks: Dictionary[String, Array] = {}
var _config: GameConfig


func setup(world: WorldState, data: GameData = GameData.get_default(), config: GameConfig = null) -> void:
	_world = world
	_config = config if config != null else GameConfig.get_default()
	for tree: Array in BROADLEAF + CONIFER:
		var species: TreeModel.Species = tree[0]
		var variant: int = tree[1]
		_models.append(TreeModel.mesh(species, variant))
		_far_models.append(TreeModel.mesh(species, variant, TreeModel.DETAIL_FAR))
		_scales.append(1.0)
	for name: String in ROCKS + PALMS:
		var foliage := PALM_COLOR if PALMS.has(name) else MOSS_COLOR
		var wood := PALM_TRUNK_COLOR if PALMS.has(name) else STONE_COLOR
		var mesh := _stone(_load_mesh(MODEL_DIR % name)) if ROCKS.has(name) else _recolor(_load_mesh(MODEL_DIR % name), foliage, wood)
		_models.append(mesh)
		_far_models.append(null)
		var height := mesh.get_aabb().size.y if mesh != null else 1.0
		var target := ROCK_SIZE_M if ROCKS.has(name) else TREE_HEIGHT_M
		_scales.append(target / maxf(height, 0.01))
	for index: int in world.islands.size():
		if world.is_tropical(index, data):
			_tropical[index] = true
		var grid := world.island(index)
		if grid.flat:
			continue
		for cy: int in ceili(grid.size.y / float(CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(CHUNK_CELLS)):
				_build_chunk(index, Vector2i(cx, cy))
	EventBus.trees_changed.connect(_on_trees_changed)


## Árvores e pedras desenhadas (a camada de longe repete as de perto e não conta).
func instance_count() -> int:
	var total := 0
	for instances: Array in _chunks.values():
		for node: MultiMeshInstance3D in instances:
			if not node.name.ends_with("Far"):
				total += node.multimesh.instance_count
	return total


## As camadas de um trecho, perto e longe, para os testes do nível de detalhe.
func chunk_layers(island_id: int, chunk: Vector2i) -> Array:
	return _chunks.get("%d/%d/%d" % [island_id, chunk.x, chunk.y], [])


## Palmeiras desenhadas numa ilha (as das ilhas tropicais).
func palm_count(island_id: int) -> int:
	var total := 0
	for key: String in _chunks:
		if key.begins_with("%d/" % island_id):
			for node: MultiMeshInstance3D in _chunks[key]:
				if node.name.begins_with("Palm"):
					total += node.multimesh.instance_count
	return total


func _on_trees_changed(island_id: int, area: Rect2i) -> void:
	var first := area.position / CHUNK_CELLS
	var last := (area.end - Vector2i.ONE) / CHUNK_CELLS
	for cy: int in range(first.y, last.y + 1):
		for cx: int in range(first.x, last.x + 1):
			_build_chunk(island_id, Vector2i(cx, cy))


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
	# cada entrada: [modelo, 12 floats da transformação]; o buffer de cada modelo é montado numa
	# variável local (array empacotado dentro de outro array pode ser alterado numa cópia)
	var entries: Array[Array] = []
	var area := Rect2i(chunk * CHUNK_CELLS, Vector2i(CHUNK_CELLS, CHUNK_CELLS)).intersection(Rect2i(Vector2i.ZERO, grid.size))
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			var index := grid.index(cell)
			var count := grid.trees[index]
			if count > 0:
				var high := grid.cell_height(cell) >= CONIFER_HEIGHT_M
				for n: int in mini(count, DRAWN_PER_CELL):
					var seed_value := hash([island_id, index, n])
					if tropical:
						var palm := BROADLEAF.size() + CONIFER.size() + ROCKS.size() + (seed_value / 7) % PALMS.size()
						entries.append([palm, _transform(grid, cell, seed_value, _scales[palm] * (0.75 + (seed_value / 13 % 50) / 100.0))])
						continue
					var conifer := (seed_value % 100) < (70 if high else 20)
					var family := CONIFER if conifer else BROADLEAF
					var model := (0 if not conifer else BROADLEAF.size()) + (seed_value / 7) % family.size()
					entries.append([model, _transform(grid, cell, seed_value, _scales[model] * (0.75 + (seed_value / 13 % 50) / 100.0))])
			elif grid.ground[index] == IslandGrid.Ground.LAND:
				var chance := rock_chance(grid, cell)
				var seed_value := hash([island_id, index, "pedra"])
				if chance > 0.0 and (seed_value % 1000) < chance * 1000.0:
					var model := BROADLEAF.size() + CONIFER.size() + seed_value % ROCKS.size()
					var placed := _transform(grid, cell, seed_value, _scales[model] * (0.7 + (seed_value / 11 % 60) / 100.0))
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
		var name_text := "Palm%d" % model if model >= BROADLEAF.size() + CONIFER.size() + ROCKS.size() else "Trees%d" % model
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


## Cópia da malha com os materiais trocados: a superfície esverdeada vira folhagem (ou musgo) e a
## outra, casca (ou pedra).
## Troca as cores do pacote pelas do jogo; desde a Fase 9 o material é o da folhagem, que balança
## ao vento (a pedra não balança).
static func _recolor(mesh: Mesh, foliage: Color, wood: Color, sways: bool = true) -> Mesh:
	if mesh == null:
		return null
	var copy := mesh.duplicate() as Mesh
	var shader := load("res://shaders/foliage.gdshader") as Shader
	for surface: int in copy.get_surface_count():
		var original := copy.surface_get_material(surface) as BaseMaterial3D
		var greenish := original != null and original.albedo_color.g > original.albedo_color.r + 0.15
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter(&"albedo", foliage if greenish else wood)
		material.set_shader_parameter(&"model_height", maxf(mesh.get_aabb().end.y, 0.1))
		material.set_shader_parameter(&"sway", 0.035 if sways else 0.0)
		var array_mesh := copy as ArrayMesh
		if array_mesh != null:
			array_mesh.surface_set_material(surface, material)
	return copy


## Chance de pedra na célula de terra sem árvore: barranco alto, ou litoral rochoso (terra encostada no mar com
## desnível). Zero no resto.
static func rock_chance(grid: IslandGrid, cell: Vector2i) -> float:
	var relief := grid.area_relief(Rect2i(cell, Vector2i.ONE))
	if relief > ROCK_RELIEF_M:
		return ROCK_CHANCE
	if relief > COAST_ROCK_RELIEF_M and grid.area_touches(Rect2i(cell, Vector2i.ONE), IslandGrid.Ground.SEA):
		return COAST_ROCK_CHANCE
	return 0.0


## Cópia da malha da pedra com o material de rocha (a textura de rocha do terreno, triplanar no mundo: não estica em
## pedra nenhuma e casa com a falésia em volta). Sem o recolorido verde-cinza de antes.
static func _stone(mesh: Mesh) -> Mesh:
	if mesh == null:
		return null
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/terrain/rock_albedo_height.png")
	material.normal_enabled = true
	material.normal_texture = load("res://assets/terrain/rock_normal_roughness.png")
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / ROCK_TEXTURE_M
	material.roughness = 0.9
	var copy := mesh.duplicate() as ArrayMesh
	if copy == null:
		return mesh
	for surface: int in copy.get_surface_count():
		copy.surface_set_material(surface, material)
	return copy


## Material da primeira superfície da pedra (testes).
func rock_material() -> Material:
	var model := _models[BROADLEAF.size() + CONIFER.size()]
	return model.surface_get_material(0) if model != null else null


## Malha do primeiro MeshInstance3D da cena .glb (os materiais vêm junto, por superfície).
static func _load_mesh(path: String) -> Mesh:
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	var root := scene.instantiate()
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var mesh: Mesh = (meshes[0] as MeshInstance3D).mesh if not meshes.is_empty() else null
	root.free()
	return mesh
