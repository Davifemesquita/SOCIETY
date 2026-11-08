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
## Fase 362: a moldura da janela e da porta fica inteira (1,0): o primeiro nível de detalhe do Godot já corta metade dela ou
## mais, e ela virava cacos.
const TRIM_KEEP_SHARE := 1.0
## As camadas das pilhas, na ordem: [nome, cor, aspereza (arquivo, canal), normal]. A aspereza "" é o valor fixo.
const LAYERS := [
	["plaster", "T_Plaster_BaseColor", "T_Plaster_ORM:g", "T_Plaster_Normal"],
	["wood", "T_WoodTrim_BaseColor", "T_WoodTrim_Roughness:r", "T_WoodTrim_Normal"],
	["brick", "T_Brick_BaseColor", "T_Brick_Roughness:r", "T_Brick_Normal"],
	["uneven_brick", "T_UnevenBrick_BaseColor", "T_UnevenBrick_Roughness:r", "T_UnevenBrick_Normal"],
	["rock", "T_RockTrim_BaseColor", "T_RockTrim_ORM:g", "T_RockTrim_Normal"],
	["glass", "T_WindowGradient", "", ""],
	# Fase 370: as ferragens das portas (só há essa textura na pasta glTF)
	["metal", "../glTF/T_MetalOrnaments_BaseColor", "../glTF/T_MetalOrnaments_Roughness:r", ""],
	# Fase 371: as telhas redondas, que o shader do kit projeta nas águas de telha (nenhuma peça empacotada usa)
	["round_tiles", "T_RoundTiles_BaseColor", "T_RoundTiles_Roughness:r", "T_RoundTiles_Normal"],
]
const GLASS_LAYER := 5
## O material do glTF (pelo começo do nome) → a camada.
const MATERIALS := {
	"MI_Plaster": 0, "MI_WoodTrim": 1, "MI_RedBrick": 2, "MI_Brick": 2, "MI_UnevenBrick": 3, "MI_RockTrim": 4,
	"MI_WindowGlass": 5, "MI_MetalOrnaments": 6, "MI_RoundTiles": 7,
}
## A peça do BuildingKit → as peças do pacote que a compõem (no mesmo lugar, como foram desenhadas para encaixar).
const PIECES := {
	"wall": ["Wall_Plaster_Straight"],
	"wall-window-shutters": ["Wall_Plaster_Window_Wide_Round", "Window_Wide_Round1"],
	"wall-window-glass": ["Wall_Plaster_Window_Wide_Flat", "Window_Wide_Flat1"],
	"wall-window-small": ["Wall_Plaster_Window_Thin_Round", "Window_Thin_Round1"],
	"wall-door": ["Wall_Plaster_Door_Flat", "Door_1_Flat"],
	# Fase 370: as outras portas do pacote, no mesmo vão (a Door_2 tem 4 mil vértices: fica de fora)
	"wall-door-4": ["Wall_Plaster_Door_Flat", "Door_4_Flat"],
	"wall-door-8": ["Wall_Plaster_Door_Flat", "Door_8_Flat"],
	"wall-doorway-round": ["Wall_Plaster_Door_Round"],
	"wall-wood": ["Wall_Plaster_WoodGrid"],
}

## Fase 373: peças soltas do pacote, inteiras, cada uma com a transformação que a põe no lugar: o guarda-corpo de madeira em xis
## da sacada, em metros (2 m ao longo de x, centrado em z = 0, do piso para cima). Fase 375: a cerca de tábuas, no referencial da
## peça "fence" do Kenney (a face em x = 0,5, de z −0,5 a 0,5, 0,38 de altura), que ela substitui com o MegaKit.
var PROPS := {
	"balcony-cross": ["Balcony_Cross_Straight", Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -1.0))],
	"fence": ["Prop_WoodenFence_Single", Transform3D(Basis(Vector3(0.0, 0.0, 1.0 / 2.06), Vector3(0.0, 0.38 / 0.81, 0.0),
			Vector3(-0.08 / 0.12, 0.0, 0.0)), Vector3(0.46, 0.0, 0.0))],
	# Fase 378: a lucarna de telhas redondas, em metros do pacote (a janela para +x, o fundo em x ≈ 0, o pé em y ≈ 0); o
	# BuildingKit a encolhe e estica até a água do telhado
	"dormer": ["Roof_Dormer_RoundTile", Transform3D.IDENTITY],
	# Fase 379: o caixote de tábuas, em metros do pacote (o CargoKit o encolhe ao lado da peça de carga)
	"crate": ["Prop_Crate", Transform3D.IDENTITY],
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
	for prop: String in PROPS:
		var spec: Array = PROPS[prop]
		var source: String = spec[0]
		var place: Transform3D = spec[1]
		var mesh := _convert_prop(source, place)
		ResourceSaver.save(mesh, OUT + prop + ".res", ResourceSaver.FLAG_COMPRESS)
		print("%s ← %s: %d vértices" % [prop, source, mesh.surface_get_array_len(0)])
	quit()


## Fase 373: a peça solta inteira (sem simplificar), posta por "place", com a camada na UV2.x.
func _convert_prop(source: String, place: Transform3D) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var root := _scene(source)
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		var local := place * _to_root(root, instance)
		var turn := local.basis.inverse().transposed()
		for surface: int in instance.mesh.get_surface_count():
			var layer := _layer_of(instance.mesh.surface_get_material(surface))
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for v: int in indices:
				tool.set_normal((turn * normals[v]).normalized())
				tool.set_uv(uvs[v] if not uvs.is_empty() else Vector2.ZERO)
				tool.set_uv2(Vector2(layer + 1, 0.0))
				tool.add_vertex(local * vertices[v])
	root.free()
	tool.index()
	tool.generate_tangents()
	return tool.commit()


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
	# o vidro fica à parte e inteiro: a simplificação o apagava (é um plano atrás da moldura)
	var glass := SurfaceTool.new()
	glass.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glass_vertices := 0
	var trim := SurfaceTool.new()
	trim.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trim_vertices := 0
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
				# só a parede se simplifica: a janela e a porta (a moldura fina) ficam inteiras, como o vidro
				var is_trim := layer != GLASS_LAYER and not source.begins_with("Wall_")
				var target := glass if layer == GLASS_LAYER else (trim if is_trim else tool)
				if layer == GLASS_LAYER:
					glass_vertices += indices.size()
				elif is_trim:
					trim_vertices += indices.size()
				for i: int in range(0, indices.size(), 3):
					for order: Array in sides:
						for k: int in order:
							var v := indices[i + k]
							var flip := 1.0 if order[1] == 1 else -1.0
							target.set_normal((turn * normals[v]).normalized() * flip)
							target.set_uv(uvs[v] if not uvs.is_empty() else Vector2.ZERO)
							target.set_uv2(Vector2(layer + 1, 0.0))
							target.add_vertex(whole * vertices[v])
		root.free()
	tool.index()
	tool.generate_tangents()
	var simplified := _simplified(tool.commit_to_arrays(), KEEP_SHARE)
	var merged := SurfaceTool.new()
	merged.begin(Mesh.PRIMITIVE_TRIANGLES)
	merged.append_from(simplified, 0, Transform3D.IDENTITY)
	if trim_vertices > 0:
		trim.index()
		trim.generate_tangents()
		merged.append_from(_simplified(trim.commit_to_arrays(), TRIM_KEEP_SHARE), 0, Transform3D.IDENTITY)
	if glass_vertices > 0:
		glass.index()
		glass.generate_tangents()
		merged.append_from(glass.commit(), 0, Transform3D.IDENTITY)
	return merged.commit()


func _to_root(root: Node3D, node: Node3D) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform


## A peça simplificada: o primeiro nível de detalhe gerado com até KEEP_SHARE dos triângulos (as peças do pacote são 2 a 3
## vezes mais pesadas que as do Kenney).
func _simplified(arrays: Array, share: float) -> ArrayMesh:
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	importer.generate_lods(25.0, 60.0, [])
	var full: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var chosen := full
	if share >= 1.0:
		var whole := ArrayMesh.new()
		whole.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return whole
	for lod: int in importer.get_surface_lod_count(0):
		var indices := importer.get_surface_lod_indices(0, lod)
		if indices.size() <= full.size() * share:
			chosen = indices
			break
	arrays[Mesh.ARRAY_INDEX] = chosen
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	print("  triângulos %d → %d" % [full.size() / 3, chosen.size() / 3])
	return mesh
