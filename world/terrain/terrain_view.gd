class_name TerrainView
extends Node3D
## Adaptador do terreno (seção 13): desenha o relevo das ilhas geradas. A especificação pede o
## Terrain3D, mas o 1.0.2 derruba o Godot 4.7.2 assim que recebe um relevo de verdade (condição
## de corrida no material, issue #945 do Terrain3D, corrigida só na versão noturna): até sair uma
## versão estável compatível, o terreno é próprio — uma malha por trecho de cada região, de 2 em
## 2 m (os cantos da grade, os mesmos que a simulação usa), e o shader de terreno com as texturas
## da Poly Haven. Trocar de volta mexe só aqui.

const TEXTURES: Array[String] = ["grass", "rock", "sand", "forest"]
const SHADER := preload("res://shaders/terrain.gdshader")
## Vértices de lado em cada trecho de malha (recorte por câmera trecho a trecho).
const CHUNK_VERTICES := 64

var _world: WorldState
var _config: GameConfig
var _data: GameData
## Por ilha: a textura do tipo de chão e a imagem dela (as árvores derrubadas mudam pixels).
var _surfaces: Dictionary[int, ImageTexture] = {}
var _surface_images: Dictionary[int, Image] = {}
var _chunks: int = 0


func setup(world: WorldState, config: GameConfig, data: GameData) -> void:
	_world = world
	_config = config
	_data = data
	var textures: Dictionary[String, Texture2D] = {}
	for name: String in TEXTURES:
		textures[name + "_albedo"] = load("res://assets/terrain/%s_albedo_height.png" % name)
		textures[name + "_normal"] = load("res://assets/terrain/%s_normal_roughness.png" % name)
	for index: int in world.islands.size():
		if not world.island(index).flat:
			_build_island(index, textures)
	EventBus.trees_changed.connect(_on_trees_changed)


func chunk_count() -> int:
	return _chunks


## Altura desenhada num ponto (para conferir com a simulação): a mesma interpolação da grade.
func shown_height(x: float, z: float) -> float:
	return _world.surface_height(x, z)


func _build_island(index: int, textures: Dictionary[String, Texture2D]) -> void:
	var region := ArchipelagoGenerator.region_corners(_world, index, _config, _data)
	var side: int = region["side"]
	var origin: Vector2 = region["origin"]
	var heights: PackedFloat32Array = region["heights"]
	var surface: PackedByteArray = region["surface"]
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	for i: int in surface.size():
		image.set_pixel(i % side, i / side, _surface_color(surface[i]))
	_surface_images[index] = image
	_surfaces[index] = ImageTexture.create_from_image(image)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	for key: String in textures:
		material.set_shader_parameter(StringName(key), textures[key])
	material.set_shader_parameter(&"surface_weights", _surfaces[index])
	var size := (side - 1) * _config.cell_size_m
	material.set_shader_parameter(&"region_bounds", Vector4(origin.x, origin.y, size, size))
	for cy: int in range(0, side - 1, CHUNK_VERTICES):
		for cx: int in range(0, side - 1, CHUNK_VERTICES):
			var instance := MeshInstance3D.new()
			instance.mesh = _chunk_mesh(heights, side, origin, cx, cy)
			instance.material_override = material
			add_child(instance)
			_chunks += 1


## Malha de um trecho: vértices nos cantos (x, z de 2 em 2 m) com a normal pelas alturas vizinhas.
func _chunk_mesh(heights: PackedFloat32Array, side: int, origin: Vector2, cx: int, cy: int) -> ArrayMesh:
	var spacing := _config.cell_size_m
	var count_x := mini(CHUNK_VERTICES, side - 1 - cx) + 1
	var count_y := mini(CHUNK_VERTICES, side - 1 - cy) + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.resize(count_x * count_y)
	normals.resize(count_x * count_y)
	for y: int in count_y:
		for x: int in count_x:
			var gx := cx + x
			var gy := cy + y
			var h := heights[gy * side + gx]
			vertices[y * count_x + x] = Vector3(origin.x + gx * spacing, h, origin.y + gy * spacing)
			var left := heights[gy * side + maxi(gx - 1, 0)]
			var right := heights[gy * side + mini(gx + 1, side - 1)]
			var up := heights[maxi(gy - 1, 0) * side + gx]
			var down := heights[mini(gy + 1, side - 1) * side + gx]
			normals[y * count_x + x] = Vector3(left - right, 2.0 * spacing, up - down).normalized()
	for y: int in count_y - 1:
		for x: int in count_x - 1:
			var a := y * count_x + x
			indices.append_array(PackedInt32Array([a, a + 1, a + count_x, a + 1, a + count_x + 1, a + count_x]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _surface_color(kind: int) -> Color:
	match kind:
		ArchipelagoGenerator.Surface.SAND:
			return Color(1.0, 0.0, 0.0)
		ArchipelagoGenerator.Surface.FOREST:
			return Color(0.0, 1.0, 0.0)
	return Color(0.0, 0.0, 0.0)


## Derrubar árvores tira o chão de floresta da área.
func _on_trees_changed(island_id: int, area: Rect2i) -> void:
	if not _surface_images.has(island_id):
		return
	var grid := _world.island(island_id)
	var image := _surface_images[island_id]
	var region := ArchipelagoGenerator.layout(_world.seed, _config, _data)[island_id].region
	var first := Vector2i((grid.origin_m - Vector2(region) * _config.terrain_region_m) / _config.cell_size_m)
	for y: int in range(area.position.y, area.end.y + 1):
		for x: int in range(area.position.x, area.end.x + 1):
			var pixel := first + Vector2i(x, y)
			if pixel.x < image.get_width() and pixel.y < image.get_height() and image.get_pixelv(pixel).g > 0.5:
				image.set_pixelv(pixel, _surface_color(ArchipelagoGenerator.Surface.AUTO))
	_surfaces[island_id].update(image)
