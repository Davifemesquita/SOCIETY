extends SceneTree
## Fase 360: converte as peças de parede do Medieval Village MegaKit (Quaternius, CC0) para o referencial das peças do Kenney
## (largura de -0,5 a 0,5 em z, a face de fora em x = 0,5, um andar de 0 a 1 em y), uma malha .res por peça do BuildingKit em
## assets/models/megakit/, com o material de cada vértice na UV2.x (a camada da pilha + 1). E empacota as texturas dele nas
## pilhas que o shader do kit lê como Texture2DArray (cor + aspereza e normal OpenGL, 1024 px por camada).
##   godot --headless --path . --script res://tools/pack_megakit.gd -- <pasta do pacote, com glTF/ e Textures/>

const OUT := "res://assets/models/megakit/"
const SIZE := 1024
## Altura de um andar das peças do pacote e o fundo da célula do kit que serve de régua (2 m menos o recuo das paredes).
const MK_FLOOR_M := 3.12
const MK_WIDTH_M := 2.0
const DEPTH_REF_M := 1.7
## A moldura mais saliente das paredes do pacote (−z) e a fração dos triângulos que fica (o nível de detalhe gerado pelo
## Godot mais perto dela, sem passar).
const OUTER_M := 0.315
const KEEP_SHARE := 0.55
## As camadas das pilhas, na ordem: [nome, cor, aspereza (arquivo, canal), normal]. A aspereza "" é o valor fixo.
const LAYERS := [
	["plaster", "T_Plaster_BaseColor", "T_Plaster_ORM:g", "T_Plaster_Normal"],
	["wood", "T_WoodTrim_BaseColor", "T_WoodTrim_Roughness:r", "T_WoodTrim_Normal"],
	["brick", "T_Brick_BaseColor", "T_Brick_Roughness:r", "T_Brick_Normal"],
	["uneven_brick", "T_UnevenBrick_BaseColor", "T_UnevenBrick_Roughness:r", "T_UnevenBrick_Normal"],
	["rock", "T_RockTrim_BaseColor", "T_RockTrim_ORM:g", "T_RockTrim_Normal"],
	["glass", "T_WindowGradient", "", ""],
]
const GLASS_LAYER := 5
## O material do glTF (pelo começo do nome) → a camada.
const MATERIALS := {
	"MI_Plaster": 0, "MI_WoodTrim": 1, "MI_RedBrick": 2, "MI_Brick": 2, "MI_UnevenBrick": 3, "MI_RockTrim": 4,
	"MI_WindowGlass": 5,
}
## A peça do BuildingKit → as peças do pacote que a compõem (no mesmo lugar, como foram desenhadas para encaixar).
const PIECES := {
	"wall": ["Wall_Plaster_Straight"],
	"wall-window-shutters": ["Wall_Plaster_Window_Wide_Round", "Window_Wide_Round1"],
	"wall-window-glass": ["Wall_Plaster_Window_Wide_Flat", "Window_Wide_Flat1"],
	"wall-window-small": ["Wall_Plaster_Window_Thin_Round", "Window_Thin_Round1"],
	"wall-door": ["Wall_Plaster_Door_Flat", "Door_1_Flat"],
	"wall-doorway-round": ["Wall_Plaster_Door_Round"],
	"wall-wood": ["Wall_Plaster_WoodGrid"],
}

var _folder: String


func _initialize() -> void:
	_folder = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_pack_textures()
	# a moldura mais saliente (não o reboco) fica na face da peça do Kenney: nada passa do lote
	var face := OUTER_M
	print("face de fora do reboco a %.3f m (−z)" % _exterior_plane("Wall_Plaster_Straight"))
	for piece: String in PIECES:
		var sources: Array = PIECES[piece]
		var mesh := _convert(sources, face)
		ResourceSaver.save(mesh, OUT + piece + ".res", ResourceSaver.FLAG_COMPRESS)
		print("%s ← %s: %d vértices" % [piece, str(sources), mesh.surface_get_array_len(0)])
	quit()


func _pack_textures() -> void:
	var color := Image.create_empty(SIZE, SIZE * LAYERS.size(), false, Image.FORMAT_RGBA8)
	var normal := Image.create_empty(SIZE, SIZE * LAYERS.size(), false, Image.FORMAT_RGBA8)
	for layer: int in LAYERS.size():
		var spec: Array = LAYERS[layer]
		var albedo := _image("Textures/%s.png" % spec[1])
		var rough: Image = null
		var channel := 0
		var rough_spec: String = spec[2]
		if rough_spec != "":
			var parts: PackedStringArray = rough_spec.split(":")
			rough = _image("Textures/%s.png" % parts[0])
			channel = "rgb".find(parts[1])
		var bump: Image = _image("Textures/Normals Godot-Unity/%s.png" % spec[3]) if spec[3] != "" else null
		for y: int in SIZE:
			for x: int in SIZE:
				var pixel := albedo.get_pixel(x, y)
				pixel.a = rough.get_pixel(x, y)[channel] if rough else 0.08
				color.set_pixel(x, y + layer * SIZE, pixel)
				normal.set_pixel(x, y + layer * SIZE, bump.get_pixel(x, y) if bump else Color(0.5, 0.5, 1.0))
	color.save_png(OUT + "megakit_albedo_rough.png")
	normal.save_png(OUT + "megakit_normal.png")


func _image(path: String) -> Image:
	var image := Image.load_from_file(_folder.path_join(path))
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() != SIZE:
		image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	return image


func _scene(piece: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_file(_folder.path_join("glTF/%s.gltf" % piece), state)
	return doc.generate_scene(state) as Node3D


## Onde fica a face de fora do reboco (a distância para −z, média pela área dos triângulos de reboco virados para −z).
func _exterior_plane(piece: String) -> float:
	var root := _scene(piece)
	var area := 0.0
	var weighted := 0.0
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		for surface: int in instance.mesh.get_surface_count():
			if _layer_of(instance.mesh.surface_get_material(surface)) != 0:
				continue
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for i: int in range(0, indices.size(), 3):
				var a := vertices[indices[i]]
				var b := vertices[indices[i + 1]]
				var c := vertices[indices[i + 2]]
				var cross := (b - a).cross(c - a)
				var normal := normals[indices[i]]
				# a face de fora: virada para −z
				if normal.z > -0.9:
					continue
				var size := cross.length() * 0.5
				area += size
				weighted += size * -(a.z + b.z + c.z) / 3.0
	root.free()
	return weighted / area if area > 0.0 else 0.0


func _layer_of(material: Material) -> int:
	if material == null:
		return 0
	for prefix: String in MATERIALS:
		if material.resource_name.begins_with(prefix):
			return MATERIALS[prefix]
	push_warning("material sem camada: %s" % material.resource_name)
	return 1


func _convert(sources: Array, face: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# x' = 0,5 + (−z − face)/DEPTH_REF; y' = y/andar; z' = x/largura (girar −90° em y mantém a mão)
	var basis := Basis(Vector3(0.0, 0.0, 1.0 / MK_WIDTH_M), Vector3(0.0, 1.0 / MK_FLOOR_M, 0.0),
			Vector3(-1.0 / DEPTH_REF_M, 0.0, 0.0))
	var to_unit := Transform3D(basis, Vector3(0.5 - face / DEPTH_REF_M, 0.0, 0.0))
	var normal_basis := basis.inverse().transposed()
	for source: String in sources:
		var root := _scene(source)
		for node: Node in root.find_children("*", "MeshInstance3D", true, false):
			var instance := node as MeshInstance3D
			var local := _to_root(root, instance)
			for surface: int in instance.mesh.get_surface_count():
				var layer := _layer_of(instance.mesh.surface_get_material(surface))
				var arrays := instance.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var whole := to_unit * local
				var turn := normal_basis * local.basis.inverse().transposed()
				# o vidro do pacote é de duas faces (o material dele desenha os dois lados): vai também ao contrário
				var sides: Array[Array] = [[0, 1, 2]]
				if layer == GLASS_LAYER:
					sides.append([0, 2, 1])
				for i: int in range(0, indices.size(), 3):
					for order: Array in sides:
						for k: int in order:
							var v := indices[i + k]
							var flip := 1.0 if order[1] == 1 else -1.0
							tool.set_normal((turn * normals[v]).normalized() * flip)
							tool.set_uv(uvs[v] if not uvs.is_empty() else Vector2.ZERO)
							tool.set_uv2(Vector2(layer + 1, 0.0))
							tool.add_vertex(whole * vertices[v])
		root.free()
	tool.index()
	tool.generate_tangents()
	return _simplified(tool.commit_to_arrays())


func _to_root(root: Node3D, node: Node3D) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform


## A peça simplificada: o primeiro nível de detalhe gerado com até KEEP_SHARE dos triângulos (as peças do pacote são 2 a 3
## vezes mais pesadas que as do Kenney).
func _simplified(arrays: Array) -> ArrayMesh:
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	importer.generate_lods(25.0, 60.0, [])
	var full: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var chosen := full
	for lod: int in importer.get_surface_lod_count(0):
		var indices := importer.get_surface_lod_indices(0, lod)
		if indices.size() <= full.size() * KEEP_SHARE:
			chosen = indices
			break
	arrays[Mesh.ARRAY_INDEX] = chosen
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	print("  triângulos %d → %d" % [full.size() / 3, chosen.size() / 3])
	return mesh
