extends SceneTree
## Empacota as texturas da Poly Haven (CC0) no formato que o shader de terreno lê (o mesmo do
## Terrain3D, para a volta dele não pedir texturas novas): cor + altura (RGBA) e normal OpenGL +
## aspereza (RGBA), 1024 px, em assets/terrain/.
##   tools/godot.sh godot --headless --path . --script res://tools/pack_terrain_textures.gd -- /pasta/baixada
## A pasta tem <nome>_Diffuse.jpg, _nor_gl.jpg, _Rough.jpg e _Displacement.jpg de cada textura.

const NAMES := {"grass": "aerial_grass_rock", "rock": "aerial_rocks_02", "sand": "aerial_beach_01", "forest": "forest_ground_04"}
const SIZE := 1024


func _initialize() -> void:
	var folder := OS.get_cmdline_user_args()[0]
	for target: String in NAMES:
		var source: String = NAMES[target]
		var albedo := _load(folder, source, "Diffuse")
		var height := _load(folder, source, "Displacement")
		var normal := _load(folder, source, "nor_gl")
		var rough := _load(folder, source, "Rough")
		var packed_albedo := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		var packed_normal := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		for y: int in SIZE:
			for x: int in SIZE:
				var color := albedo.get_pixel(x, y)
				color.a = height.get_pixel(x, y).r
				packed_albedo.set_pixel(x, y, color)
				var n := normal.get_pixel(x, y)
				n.a = rough.get_pixel(x, y).r
				packed_normal.set_pixel(x, y, n)
		packed_albedo.save_png("res://assets/terrain/%s_albedo_height.png" % target)
		packed_normal.save_png("res://assets/terrain/%s_normal_roughness.png" % target)
		print("%s ← %s" % [target, source])
	quit()


func _load(folder: String, source: String, map: String) -> Image:
	var image := Image.load_from_file(folder.path_join("%s_%s.jpg" % [source, map]))
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() != SIZE:
		image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	return image
