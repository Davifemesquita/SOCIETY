class_name PeriodGrade
extends RefCounted
## Gradação de cor de época (Fase 37): um LUT 3D de 33³ para o Environment.adjustment_color_correction, gerado no
## código a partir do neutro (não há LUT CC0 de época pronto). Realces âmbar, sombras levemente frias, verdes e azuis
## menos saturados e o preto levemente erguido: o "século XIX" sem virar sépia chapado. Só liga com a opção "Cor de
## época" (Settings.period_look), para o dono do produto comparar com o visual de antes.

const SIZE := 33
## Quanto o preto sobe, quanto os realces esquentam e as sombras esfriam, e quanto verdes e azuis perdem saturação.
const LIFT := 0.025
const WARM_HIGHLIGHTS := Vector3(0.045, 0.018, -0.03)
const COOL_SHADOWS := Vector3(-0.015, 0.0, 0.02)
const GREEN_DESATURATION := 0.85
const BLUE_DESATURATION := 0.85

static var _texture: ImageTexture3D


## A cor depois da gradação (função pura: o LUT é ela amostrada numa grade de 33³).
static func grade(color: Color) -> Color:
	var c := Vector3(color.r, color.g, color.b)
	var luma := c.dot(Vector3(0.2126, 0.7152, 0.0722))
	c += WARM_HIGHLIGHTS * smoothstep(0.45, 1.0, luma)
	c += COOL_SHADOWS * (1.0 - smoothstep(0.0, 0.45, luma))
	var shifted := Color(clampf(c.x, 0.0, 1.0), clampf(c.y, 0.0, 1.0), clampf(c.z, 0.0, 1.0))
	var hue := shifted.h
	var saturation := shifted.s
	if hue > 0.17 and hue < 0.47:
		saturation *= GREEN_DESATURATION
	elif hue > 0.5 and hue < 0.72:
		saturation *= BLUE_DESATURATION
	shifted = Color.from_hsv(hue, saturation, shifted.v)
	return Color(LIFT + shifted.r * (1.0 - LIFT), LIFT + shifted.g * (1.0 - LIFT), LIFT + shifted.b * (1.0 - LIFT))


## O LUT (feito uma vez): fatia z é o azul, dentro dela x é o vermelho e y o verde.
static func texture() -> ImageTexture3D:
	if _texture == null:
		var slices: Array[Image] = []
		for b: int in SIZE:
			var bytes := PackedByteArray()
			bytes.resize(SIZE * SIZE * 3)
			for g: int in SIZE:
				for r: int in SIZE:
					var graded := grade(Color(r / float(SIZE - 1), g / float(SIZE - 1), b / float(SIZE - 1)))
					var at := (g * SIZE + r) * 3
					bytes[at] = roundi(graded.r * 255.0)
					bytes[at + 1] = roundi(graded.g * 255.0)
					bytes[at + 2] = roundi(graded.b * 255.0)
			slices.append(Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGB8, bytes))
		_texture = ImageTexture3D.new()
		_texture.create(Image.FORMAT_RGB8, SIZE, SIZE, SIZE, false, slices)
	return _texture
