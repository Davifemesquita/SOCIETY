class_name CoastField
extends RefCounted
## Distância até a costa com sinal (Fase 35), no arquipélago inteiro: positiva na terra, negativa na água, em metros,
## cortada em ±max_m. Junta os campos de cada região (TerrainBake.signed_coast) num mapa só, de 2 em 2 m, porque a água
## é uma malha só que segue a câmera; fora das regiões é mar fundo (-max_m). Só apresentação: sai das alturas, nunca
## vai para o save.

## Canto (x, z) do pixel (0, 0) no mundo, metros por pixel e tamanho do mapa.
var origin := Vector2.ZERO
var spacing: float = 2.0
var size := Vector2i.ZERO
var max_m: float = 64.0
var distances := PackedFloat32Array()


## regions: um Dictionary por região com "origin" (Vector2, canto no mundo), "side" (cantos de lado) e "coast"
## (PackedFloat32Array de side × side).
static func compose(regions: Array[Dictionary], spacing_m: float, limit_m: float) -> CoastField:
	var field := CoastField.new()
	field.spacing = spacing_m
	field.max_m = limit_m
	if regions.is_empty():
		return field
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for region: Dictionary in regions:
		var corner: Vector2 = region["origin"]
		var side: int = region["side"]
		low = low.min(corner)
		high = high.max(corner + Vector2.ONE * (side - 1) * spacing_m)
	field.origin = low
	field.size = Vector2i(roundi((high.x - low.x) / spacing_m) + 1, roundi((high.y - low.y) / spacing_m) + 1)
	field.distances.resize(field.size.x * field.size.y)
	field.distances.fill(-limit_m)
	for region: Dictionary in regions:
		var corner: Vector2 = region["origin"]
		var side: int = region["side"]
		var coast: PackedFloat32Array = region["coast"]
		var first := Vector2i(roundi((corner.x - low.x) / spacing_m), roundi((corner.y - low.y) / spacing_m))
		for y: int in side:
			var row := (first.y + y) * field.size.x + first.x
			for x: int in side:
				field.distances[row + x] = coast[y * side + x]
	return field


## Distância no ponto do mundo (pixel mais próximo); fora do mapa, mar fundo.
func at(x: float, z: float) -> float:
	var pixel := Vector2i(roundi((x - origin.x) / spacing), roundi((z - origin.y) / spacing))
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= size.x or pixel.y >= size.y:
		return -max_m
	return distances[pixel.y * size.x + pixel.x]


## Textura de um canal float (metros) para os shaders.
func texture() -> ImageTexture:
	if size == Vector2i.ZERO:
		return null
	return ImageTexture.create_from_image(Image.create_from_data(size.x, size.y, false, Image.FORMAT_RF,
			distances.to_byte_array()))


## Canto (x, z) e tamanho (largura, profundidade) em metros, como os shaders leem: com meio pixel de margem, para o
## centro de cada pixel cair no canto da grade que ele guarda.
func bounds() -> Vector4:
	return Vector4(origin.x - spacing * 0.5, origin.y - spacing * 0.5, size.x * spacing, size.y * spacing)
