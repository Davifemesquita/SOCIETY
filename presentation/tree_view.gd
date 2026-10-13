class_name TreeView
extends Node3D
## Árvores e pedras (seção 7): saem da grade da ilha (árvores por célula, que a simulação gerou
## pela semente) e são desenhadas em MultiMesh por trecho de CHUNK_CELLS × CHUNK_CELLS e por
## modelo. Derrubar árvores ao construir refaz só o trecho atingido (trees_changed). Posição,
## giro e tamanho de cada árvore saem do índice da célula: o mesmo mundo dá sempre a mesma mata.
## Modelos do Kenney Nature Kit (CC0).

const CHUNK_CELLS := 64
const BROADLEAF: Array[String] = ["tree_default", "tree_oak", "tree_fat"]
const CONIFER: Array[String] = ["tree_pineDefaultA", "tree_pineRoundA"]
const ROCKS: Array[String] = ["rock_largeA", "rock_largeB"]
const MODEL_DIR := "res://assets/models/nature/%s.glb"
## Altura de uma árvore adulta e das pedras, em metros.
const TREE_HEIGHT_M := 8.0
const ROCK_SIZE_M := 1.6
## Acima desta altura do terreno, mais pinheiro que folhosa.
const CONIFER_HEIGHT_M := 6.0
## Célula mais íngreme que isto (diferença entre cantos) ganha pedra de vez em quando.
const ROCK_RELIEF_M := 2.5
const ROCK_CHANCE := 0.12
const VISIBLE_UNTIL_M := 900.0
## Desenhadas no máximo tantas árvores por célula (a regra do lenhador conta todas): a copa de
## uma árvore de 8 m já cobre a célula de 2 m.
const DRAWN_PER_CELL := 2
## Cores das superfícies dos modelos (as do pacote são de desenho animado): folhagem de cada
## família, casca e pedra.
const BROADLEAF_COLOR := Color(0.24, 0.36, 0.16)
const CONIFER_COLOR := Color(0.13, 0.26, 0.15)
const BARK_COLOR := Color(0.32, 0.23, 0.16)
const STONE_COLOR := Color(0.47, 0.46, 0.43)
const MOSS_COLOR := Color(0.3, 0.37, 0.22)

var _world: WorldState
var _models: Array[Mesh] = []
## Fator de escala de cada modelo para chegar à altura certa.
var _scales: PackedFloat32Array = []
## chave "ilha/cx/cy" → os MultiMeshInstance3D do trecho, um por modelo.
var _chunks: Dictionary[String, Array] = {}


func setup(world: WorldState) -> void:
	_world = world
	for name: String in BROADLEAF + CONIFER + ROCKS:
		var foliage := CONIFER_COLOR if CONIFER.has(name) else (MOSS_COLOR if ROCKS.has(name) else BROADLEAF_COLOR)
		var wood := STONE_COLOR if ROCKS.has(name) else BARK_COLOR
		var mesh := _recolor(_load_mesh(MODEL_DIR % name), foliage, wood)
		_models.append(mesh)
		var height := mesh.get_aabb().size.y if mesh != null else 1.0
		var target := ROCK_SIZE_M if ROCKS.has(name) else TREE_HEIGHT_M
		_scales.append(target / maxf(height, 0.01))
	for index: int in world.islands.size():
		var grid := world.island(index)
		if grid.flat:
			continue
		for cy: int in ceili(grid.size.y / float(CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(CHUNK_CELLS)):
				_build_chunk(index, Vector2i(cx, cy))
	EventBus.trees_changed.connect(_on_trees_changed)


func instance_count() -> int:
	var total := 0
	for instances: Array in _chunks.values():
		for node: MultiMeshInstance3D in instances:
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
		for node: MultiMeshInstance3D in _chunks[key]:
			node.queue_free()
		_chunks.erase(key)
	var grid := _world.island(island_id)
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
					var conifer := (seed_value % 100) < (70 if high else 20)
					var family := CONIFER if conifer else BROADLEAF
					var model := (0 if not conifer else BROADLEAF.size()) + (seed_value / 7) % family.size()
					entries.append([model, _transform(grid, cell, seed_value, _scales[model] * (0.75 + (seed_value / 13 % 50) / 100.0))])
			elif grid.ground[index] == IslandGrid.Ground.LAND and grid.area_relief(Rect2i(cell, Vector2i.ONE)) > ROCK_RELIEF_M:
				var seed_value := hash([island_id, index, "pedra"])
				if (seed_value % 1000) < ROCK_CHANCE * 1000.0:
					var model := BROADLEAF.size() + CONIFER.size() + seed_value % ROCKS.size()
					entries.append([model, _transform(grid, cell, seed_value, _scales[model] * (0.7 + (seed_value / 11 % 60) / 100.0))])
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
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _models[model]
		multimesh.instance_count = buffer.size() / 12
		multimesh.buffer = buffer
		var node := MultiMeshInstance3D.new()
		node.multimesh = multimesh
		node.visibility_range_end = VISIBLE_UNTIL_M
		add_child(node)
		nodes.append(node)
	_chunks[key] = nodes


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
static func _recolor(mesh: Mesh, foliage: Color, wood: Color) -> Mesh:
	if mesh == null:
		return null
	var copy := mesh.duplicate() as Mesh
	for surface: int in copy.get_surface_count():
		var original := copy.surface_get_material(surface) as BaseMaterial3D
		var greenish := original != null and original.albedo_color.g > original.albedo_color.r + 0.15
		var material := StandardMaterial3D.new()
		material.albedo_color = foliage if greenish else wood
		material.roughness = 0.95
		var array_mesh := copy as ArrayMesh
		if array_mesh != null:
			array_mesh.surface_set_material(surface, material)
	return copy


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
