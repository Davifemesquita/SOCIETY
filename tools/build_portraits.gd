extends SceneTree
## Fase 51: os retratos das pessoas (as classes, o conselheiro e o comerciante) a partir de pinturas do século XIX em
## domínio público (Art Institute of Chicago, CC0; créditos no CREDITS.md), em assets/source/portraits/aic_<id>.jpg:
## cada uma recortada pelo centro do rosto em 4:5, reduzida para SIZE e com o acabamento do PhotoGrade (o mesmo das
## fotos dos prédios), em ui/portraits/portrait_<nome>.png.
##   godot --headless --path . --script res://tools/build_portraits.gd

const SOURCES := "res://assets/source/portraits/"
const OUT := "res://ui/portraits/"
const SIZE := Vector2i(256, 320)

## nome do retrato: [id da obra, centro do recorte (fração da imagem), largura do recorte (fração da largura)]
const PORTRAITS := {
	"tier_peasants": [81548, Vector2(0.60, 0.38), 0.80],
	"tier_workers": [59944, Vector2(0.50, 0.27), 0.72],
	"tier_artisans": [11, Vector2(0.45, 0.38), 0.86],
	"tier_engineers": [11704, Vector2(0.50, 0.46), 0.60],
	"tier_investors": [7175, Vector2(0.50, 0.52), 0.64],
	"advisor": [95108, Vector2(0.55, 0.42), 0.72],
	"trader": [95183, Vector2(0.50, 0.30), 0.78],
}


func _init() -> void:
	for name: String in PORTRAITS:
		var entry: Array = PORTRAITS[name]
		var id: int = entry[0]
		var center: Vector2 = entry[1]
		var width: float = entry[2]
		var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCES + "aic_%d.jpg" % id))
		if image == null or image.is_empty():
			push_error("build_portraits: sem a pintura %d" % id)
			continue
		var portrait := crop(image, center, width)
		portrait.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
		PhotoGrade.apply(portrait)
		portrait.save_png(ProjectSettings.globalize_path(OUT + "portrait_%s.png" % name))
		print("retrato ", name, " de ", id)
	quit()


## O recorte 4:5 com o centro e a largura dados (frações), empurrado para dentro da imagem.
static func crop(image: Image, center: Vector2, width_fraction: float) -> Image:
	var size := Vector2(image.get_size())
	var width := minf(size.x * width_fraction, size.y * float(SIZE.x) / SIZE.y)
	var height := width * SIZE.y / SIZE.x
	var corner := (size * center - Vector2(width, height) * 0.5).clamp(Vector2.ZERO, size - Vector2(width, height))
	return image.get_region(Rect2i(Vector2i(corner), Vector2i(roundi(width), roundi(height))))
