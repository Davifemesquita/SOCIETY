extends SceneTree
## Ícone do jogo (Fase 10): medalhão bordô com aro dourado e a fábrica do game-icons.net (CC BY 3.0)
## em tom de papel, nos tamanhos do Windows. Grava assets/icon/society_<lado>.png; o .ico sai deles
## por tools/build_app_icon.py.
##   tools/godot.sh godot --headless --path . --script res://tools/build_app_icon.gd

const SOURCE := "res://assets/source/game-icons/delapouite/factory.svg"
const OUT := "res://assets/icon/"
const SIZES: Array[int] = [16, 32, 48, 64, 128, 256]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var big := _medallion(512)
	for side: int in SIZES:
		var image := big.duplicate() as Image
		image.resize(side, side, Image.INTERPOLATE_LANCZOS)
		image.save_png(OUT + "society_%d.png" % side)
	print("build_app_icon: %d tamanhos em %s" % [SIZES.size(), OUT])
	quit()


func _medallion(side: int) -> Image:
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var center := Vector2(side, side) * 0.5
	var radius := side * 0.48
	for y: int in side:
		for x: int in side:
			var d := (Vector2(x + 0.5, y + 0.5) - center).length()
			var color := UiPalette.BURGUNDY.lerp(Color.BLACK, clampf(d / radius * 0.45, 0.0, 0.45))
			if d > radius - side * 0.04:
				color = UiPalette.GOLD
			if d > radius - side * 0.015:
				color = UiPalette.WOOD
			var alpha := clampf(radius - d + 0.5, 0.0, 1.0)
			if alpha > 0.0:
				image.set_pixel(x, y, Color(color, alpha))
	var svg := FileAccess.get_file_as_string(SOURCE)
	var glyph := Image.new()
	glyph.load_svg_from_string(svg, side * 0.62 / 512.0)
	glyph.convert(Image.FORMAT_RGBA8)
	var offset := (Vector2i(side, side) - glyph.get_size()) / 2
	for y: int in glyph.get_height():
		for x: int in glyph.get_width():
			# o desenho do game-icons é branco sobre um quadrado preto: o brilho é a máscara
			var pixel := glyph.get_pixel(x, y)
			var a := pixel.a * pixel.r
			if a > 0.0:
				var under := image.get_pixel(x + offset.x, y + offset.y)
				image.set_pixel(x + offset.x, y + offset.y, under.lerp(Color(UiPalette.PAPER, under.a), a))
	return image
