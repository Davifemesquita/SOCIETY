class_name PhotoGrade
extends RefCounted
## Fase 51: o acabamento das fotos dos prédios e dos retratos (o papel do jogo por cima de uma imagem): um tom quente de
## óleo envelhecido (as sombras puxam para o sépia, o branco para o creme), saturação um pouco menor e a vinheta que
## escurece as bordas. Só soma e multiplica por pixel: o mesmo resultado em toda máquina.

## Quanto da cor vai para o sépia, quanto a saturação cai e quanto a vinheta escurece nos cantos.
const WARMTH := 0.18
const DESATURATE := 0.12
const VIGNETTE := 0.35
const SEPIA_SHADOW := Color(0.36, 0.26, 0.16)
const SEPIA_LIGHT := Color(0.97, 0.91, 0.78)


## O maior retângulo 4:3 centrado que cabe em "fraction" da altura da imagem.
static func crop_4_3(image: Image, fraction: float) -> Image:
	var height := roundi(image.get_height() * fraction)
	var width := mini(roundi(height * 4.0 / 3.0), image.get_width())
	height = roundi(width * 3.0 / 4.0)
	var corner := Vector2i((image.get_width() - width) / 2, (image.get_height() - height) / 2)
	return image.get_region(Rect2i(corner, Vector2i(width, height)))


static func apply(image: Image) -> void:
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var size := Vector2(image.get_size())
	var center := size * 0.5
	var reach := center.length()
	for y: int in image.get_height():
		for x: int in image.get_width():
			image.set_pixel(x, y, graded(image.get_pixel(x, y), (Vector2(x, y) - center).length() / reach))


## Uma cor com o acabamento, a "edge" (0 no meio, 1 no canto) da borda.
static func graded(color: Color, edge: float) -> Color:
	var luma := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
	var tone := SEPIA_SHADOW.lerp(SEPIA_LIGHT, luma)
	var out := color.lerp(Color(luma, luma, luma), DESATURATE).lerp(tone, WARMTH)
	var dark := 1.0 - VIGNETTE * smoothstep(0.55, 1.0, edge)
	return Color(out.r * dark, out.g * dark, out.b * dark, color.a)
