class_name TerrainBake
extends RefCounted
## Texturas de dados do terreno (Fase 34), tiradas só das alturas dos cantos que o region_corners já gera: nada aqui
## muda uma altura nem vai para o save. Uma imagem RGBA8 por região, de 2 em 2 m:
## - r: inclinação (0 plano, 1 vertical);
## - g: curvatura (0,5 reto; acima é vale, abaixo é crista);
## - b: distância até a água (abaixo do nível do mar), 1 a partir de water_distance_m;
## - a: umidade (1 na água, alta perto dela e nos vales).
## Determinística: as mesmas alturas dão os mesmos bytes.

## Quantas células de cada lado a curvatura olha (o laplaciano a 4 m pega o vale e não o ruído de 2 m).
const CURVATURE_CELLS := 2
## Laplaciano (1/m) que vira o canal inteiro: 0,125 já é um vale bem marcado.
const CURVATURE_SCALE := 4.0
const DIAGONAL := 1.41421356


## to_water: a distance_to_water já calculada (a TerrainView a divide com o signed_coast); vazia, calcula aqui.
static func bake(heights: PackedFloat32Array, side: int, spacing: float, water_distance_m: float,
		to_water: PackedFloat32Array = PackedFloat32Array()) -> Image:
	var count := side * side
	var distance := to_water if not to_water.is_empty() else distance_to_water(heights, side)
	var bytes := PackedByteArray()
	bytes.resize(count * 4)
	var reach := CURVATURE_CELLS * spacing
	for y: int in side:
		var up := maxi(y - 1, 0) * side
		var down := mini(y + 1, side - 1) * side
		var far_up := maxi(y - CURVATURE_CELLS, 0) * side
		var far_down := mini(y + CURVATURE_CELLS, side - 1) * side
		var row := y * side
		for x: int in side:
			var i := row + x
			var h := heights[i]
			var left := maxi(x - 1, 0)
			var right := mini(x + 1, side - 1)
			var dx := (heights[row + right] - heights[row + left]) / ((right - left) * spacing)
			var dz := (heights[down + x] - heights[up + x]) / (maxf(down - up, 1) / side * spacing)
			var slope := atan(sqrt(dx * dx + dz * dz)) / (PI * 0.5)
			var laplacian := (heights[row + maxi(x - CURVATURE_CELLS, 0)] + heights[row + mini(x + CURVATURE_CELLS, side - 1)]
					+ heights[far_up + x] + heights[far_down + x] - 4.0 * h) / (reach * reach)
			var curvature := clampf(0.5 + laplacian * CURVATURE_SCALE, 0.0, 1.0)
			var near_water := clampf(distance[i] * spacing / water_distance_m, 0.0, 1.0)
			var moisture := 1.0
			if distance[i] > 0.0:
				moisture = clampf(pow(1.0 - near_water, 1.5) * 0.75 + maxf(curvature - 0.5, 0.0), 0.0, 1.0)
			bytes[i * 4] = roundi(slope * 255.0)
			bytes[i * 4 + 1] = roundi(curvature * 255.0)
			bytes[i * 4 + 2] = roundi(near_water * 255.0)
			bytes[i * 4 + 3] = roundi(moisture * 255.0)
	return Image.create_from_data(side, side, false, Image.FORMAT_RGBA8, bytes)


## Fase 35: distância até a costa com sinal, em metros, de cada canto: positiva na terra (até a água), negativa na água
## (até a terra), com a linha d'água no meio entre os cantos e cortada em ±max_m. A mesma conta de chanfro (erro de
## até ~8% fora dos eixos e das diagonais).
static func signed_coast(heights: PackedFloat32Array, side: int, spacing: float, max_m: float,
		to_water: PackedFloat32Array = PackedFloat32Array()) -> PackedFloat32Array:
	if to_water.is_empty():
		to_water = distance_to_water(heights, side)
	var to_land := distance_to_water(heights, side, true)
	var result := PackedFloat32Array()
	result.resize(side * side)
	for i: int in side * side:
		if heights[i] < 0.0:
			result[i] = -minf((to_land[i] - 0.5) * spacing, max_m)
		else:
			result[i] = minf((to_water[i] - 0.5) * spacing, max_m)
	return result


## Distância (em células) de cada canto até o mais próximo abaixo do nível do mar (ou, com to_land, até o mais próximo
## acima dele), por chanfro em duas passadas (1 de lado, √2 na diagonal). Sem alvo na região, tudo fica longe.
static func distance_to_water(heights: PackedFloat32Array, side: int, to_land: bool = false) -> PackedFloat32Array:
	var far := float(side * 2)
	var distance := PackedFloat32Array()
	distance.resize(side * side)
	for i: int in side * side:
		distance[i] = 0.0 if (heights[i] < 0.0) != to_land else far
	for y: int in side:
		for x: int in side:
			var i := y * side + x
			var best := distance[i]
			if x > 0:
				best = minf(best, distance[i - 1] + 1.0)
			if y > 0:
				best = minf(best, distance[i - side] + 1.0)
				if x > 0:
					best = minf(best, distance[i - side - 1] + DIAGONAL)
				if x < side - 1:
					best = minf(best, distance[i - side + 1] + DIAGONAL)
			distance[i] = best
	for y: int in range(side - 1, -1, -1):
		for x: int in range(side - 1, -1, -1):
			var i := y * side + x
			var best := distance[i]
			if x < side - 1:
				best = minf(best, distance[i + 1] + 1.0)
			if y < side - 1:
				best = minf(best, distance[i + side] + 1.0)
				if x < side - 1:
					best = minf(best, distance[i + side + 1] + DIAGONAL)
				if x > 0:
					best = minf(best, distance[i + side - 1] + DIAGONAL)
			distance[i] = best
	return distance
