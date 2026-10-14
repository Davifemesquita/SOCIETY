extends SceneTree
## Empacota as texturas da Poly Haven (CC0) dos prédios e das estradas (Fase 9) em pilhas que o
## shader lê como Texture2DArray: cor + aspereza (RGBA) e normal OpenGL (RGB), 1024 px por camada,
## em assets/materials/. A ordem das camadas é a de BuildingMaterials.WALLS e ROADS.
##   tools/godot.sh godot --headless --path . --script res://tools/pack_material_textures.gd -- /pasta/baixada
## A pasta tem <nome>_Diffuse.jpg, _nor_gl.jpg e _Rough.jpg de cada textura.

const STACKS := {
	"walls": ["brick_wall_02", "painted_plaster_wall", "weathered_planks", "castle_brick_07"],
	"roofs": ["clay_roof_tiles_02", "weathered_planks"],
	"roads": ["dirt_floor", "cobblestone_floor_001"],
}
const SIZE := 1024
const OUT := "res://assets/materials/"


func _initialize() -> void:
	var folder := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for stack: String in STACKS:
		var names: Array = STACKS[stack]
		var color := Image.create_empty(SIZE, SIZE * names.size(), false, Image.FORMAT_RGBA8)
		var normal := Image.create_empty(SIZE, SIZE * names.size(), false, Image.FORMAT_RGBA8)
		for layer: int in names.size():
			var source: String = names[layer]
			var albedo := _load(folder, source, "Diffuse")
			var rough := _load(folder, source, "Rough")
			var bump := _load(folder, source, "nor_gl")
			for y: int in SIZE:
				for x: int in SIZE:
					var pixel := albedo.get_pixel(x, y)
					pixel.a = rough.get_pixel(x, y).r
					color.set_pixel(x, y + layer * SIZE, pixel)
					normal.set_pixel(x, y + layer * SIZE, bump.get_pixel(x, y))
		color.save_png(OUT + "%s_albedo_rough.png" % stack)
		normal.save_png(OUT + "%s_normal.png" % stack)
		print("%s ← %s" % [stack, ", ".join(names)])
	quit()


func _load(folder: String, source: String, map: String) -> Image:
	var image := Image.load_from_file(folder.path_join("%s_%s.jpg" % [source, map]))
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() != SIZE:
		image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	return image
