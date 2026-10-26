class_name TerrainDetail
extends RefCounted
## Detalhe visual do relevo (Fase 36): um deslocamento de altura por canto da grade, só na malha desenhada, nunca na
## simulação nem no save. Tira a cara de rampa desenhada dos patamares: os barrancos ganham largura variável (ruído) e
## sulcos de erosão "falsa" (ruído ridged), mais fortes quanto mais íngreme o canto.
##
## Só onde nada da simulação está: um canto só se mexe se as 4 células que o tocam forem todas terra, íngremes demais
## para prédio, sem árvore (nem derrubada: o jogo novo e o save carregado desenham o mesmo) e sem estrada nem prédio.
## Toda célula com algo em cima (ou que possa receber prédio) tem os 4 cantos na altura da simulação, então prédio,
## estrada, árvore, carroça e pedestre ficam nela; o cursor também (ele lê a altura da simulação, não a malha). Estrada
## nova num barranco: a TerrainView zera os cantos da célula (zero_cell) e refaz o trecho.
## (Um anel extra de células vizinhas protegidas, como pedia o plano, zerava o efeito: os barrancos têm 1 a 2 células.)

const EPSILON := 0.001
## Encosta (diferença entre os cantos vizinhos) a partir da qual o detalhe começa, e em quanto ele chega ao máximo.
const START_RELIEF_M := 1.0
const FULL_RELIEF_M := 4.0
## Quanto o barranco anda para fora ou para dentro (ruído suave) e a fundura dos sulcos (ruído ridged), em metros.
const WIDTH_M := 0.6
const GULLY_M := 0.7
const WIDTH_PERIOD_M := 22.0
const GULLY_PERIOD_M := 9.0

static var _cache: Dictionary[int, PackedFloat32Array] = {}


## Deslocamento (m) de cada canto da grade, (size.x + 1) × (size.y + 1), zero onde a simulação manda. Determinístico:
## o ruído sai da posição da ilha. Guardado por ilha (a TerrainView e a TreeView pedem o mesmo).
static func offsets(grid: IslandGrid, config: GameConfig) -> PackedFloat32Array:
	var key := grid.get_instance_id()
	if _cache.has(key):
		return _cache[key]
	if _cache.size() > 32:
		_cache.clear()
	var result := _compute(grid, config)
	_cache[key] = result
	return result


## Deslocamento no ponto do mundo (bilinear entre os cantos), para pôr pedras em cima da malha.
static func offset_at(grid: IslandGrid, config: GameConfig, x_m: float, z_m: float) -> float:
	if grid.flat or grid.corner_heights.is_empty():
		return 0.0
	var values := offsets(grid, config)
	var gx := clampf((x_m - grid.origin_m.x) / grid.cell_size, 0.0, grid.size.x)
	var gz := clampf((z_m - grid.origin_m.y) / grid.cell_size, 0.0, grid.size.y)
	var x0 := mini(floori(gx), grid.size.x - 1)
	var z0 := mini(floori(gz), grid.size.y - 1)
	var width := grid.size.x + 1
	var top := lerpf(values[z0 * width + x0], values[z0 * width + x0 + 1], gx - x0)
	var bottom := lerpf(values[(z0 + 1) * width + x0], values[(z0 + 1) * width + x0 + 1], gx - x0)
	return lerpf(top, bottom, gz - z0)


## Célula onde algo da simulação está ou pode receber prédio: fora da terra, com árvore (ou derrubada), com estrada ou
## prédio, ou plana o bastante para prédio.
static func protected_cell(grid: IslandGrid, config: GameConfig, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell):
		return true
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0:
		return true
	if not grid.cleared_trees.is_empty() and grid.cleared_trees[index] == 1:
		return true
	if grid.roads[index] != IslandGrid.Road.NONE or grid.occupancy[index] != 0:
		return true
	return grid.area_relief(Rect2i(cell, Vector2i.ONE)) <= config.max_build_height_delta_m + EPSILON


## Zera os 4 cantos da célula (estrada nova num barranco); devolve se algum estava mexido.
static func zero_cell(grid: IslandGrid, cell: Vector2i) -> bool:
	var values := offsets_cached(grid)
	if values.is_empty():
		return false
	var width := grid.size.x + 1
	var changed := false
	for corner: int in [cell.y * width + cell.x, cell.y * width + cell.x + 1, (cell.y + 1) * width + cell.x,
			(cell.y + 1) * width + cell.x + 1]:
		if values[corner] != 0.0:
			values[corner] = 0.0
			changed = true
	if changed:
		_cache[grid.get_instance_id()] = values
	return changed


## Os deslocamentos já calculados da ilha (vazio se ainda não foram).
static func offsets_cached(grid: IslandGrid) -> PackedFloat32Array:
	return _cache.get(grid.get_instance_id(), PackedFloat32Array())


static func _compute(grid: IslandGrid, config: GameConfig) -> PackedFloat32Array:
	var width := grid.size.x + 1
	var result := PackedFloat32Array()
	result.resize(width * (grid.size.y + 1))
	if grid.flat or grid.corner_heights.is_empty():
		return result
	# células livres: o contrário do protected_cell, direto nos arrays (chamar a função por célula custava caro na ilha
	# inteira)
	var heights := grid.corner_heights
	var flat_enough := config.max_build_height_delta_m + EPSILON
	var cleared := grid.cleared_trees
	var free := PackedByteArray()
	free.resize(grid.size.x * grid.size.y)
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell := y * grid.size.x + x
			if grid.ground[cell] != IslandGrid.Ground.LAND or grid.trees[cell] > 0 \
					or (not cleared.is_empty() and cleared[cell] == 1) or grid.roads[cell] != IslandGrid.Road.NONE \
					or grid.occupancy[cell] != 0:
				continue
			var c := y * width + x
			var a := heights[c]
			var b := heights[c + 1]
			var d := heights[c + width]
			var e := heights[c + width + 1]
			if maxf(maxf(a, b), maxf(d, e)) - minf(minf(a, b), minf(d, e)) > flat_enough:
				free[cell] = 1
	var seed_value := hash([grid.origin_m, grid.size])
	var wide := FastNoiseLite.new()
	wide.seed = seed_value
	wide.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	wide.frequency = 1.0 / WIDTH_PERIOD_M
	var gully := FastNoiseLite.new()
	gully.seed = seed_value + 1
	gully.noise_type = FastNoiseLite.TYPE_PERLIN
	gully.frequency = 1.0 / GULLY_PERIOD_M
	for y: int in range(1, grid.size.y):
		for x: int in range(1, grid.size.x):
			if not _corner_free(free, grid.size.x, x, y):
				continue
			var i := y * width + x
			var h := heights[i]
			var low := h
			var high := h
			for neighbor: int in [i - 1, i + 1, i - width, i + width]:
				low = minf(low, heights[neighbor])
				high = maxf(high, heights[neighbor])
			var strength := clampf((high - low - START_RELIEF_M) / (FULL_RELIEF_M - START_RELIEF_M), 0.0, 1.0)
			if strength <= 0.0:
				continue
			var wx := grid.origin_m.x + x * grid.cell_size
			var wz := grid.origin_m.y + y * grid.cell_size
			var ridged := 1.0 - absf(gully.get_noise_2d(wx, wz))
			result[i] = strength * (wide.get_noise_2d(wx, wz) * WIDTH_M - pow(ridged, 3.0) * GULLY_M)
	return result


## As 4 células que tocam o canto (x, y) estão livres.
static func _corner_free(free: PackedByteArray, columns: int, x: int, y: int) -> bool:
	return free[(y - 1) * columns + x - 1] == 1 and free[(y - 1) * columns + x] == 1 \
			and free[y * columns + x - 1] == 1 and free[y * columns + x] == 1
