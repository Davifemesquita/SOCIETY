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

## Fase 329: a beira da praia em rampa. Os cantos baixos da terra (até BEACH_MAX_M) descem e os do mar logo em frente sobem
## até uma rampa de BEACH_SLOPE (m por m, variando BEACH_SLOPE_VARIATION pelo ruído) pela distância até a linha d'água, a
## até BEACH_REACH cantos dela: some o degrau de 1,2 m do patamar da praia sobre a água e a borda de cima dele, que seguia a
## escada das células. A linha d'água fica onde estava (a rampa é a mesma dos dois lados). Só onde nada da simulação está
## (prédio, estrada, trilho, árvore ou derrubada, rio): a célula plana da praia pode receber prédio, e a TerrainView a volta à
## altura da simulação quando ele chega.
const BEACH_MAX_M := 2.5
const BEACH_SLOPE := 0.3
const BEACH_SLOPE_VARIATION := 0.25
const BEACH_SLOPE_PERIOD_M := 26.0
const BEACH_REACH := 4
## O fundo do mar sobe no máximo isto (m): a rampa debaixo d'água não vira banco de areia.
const BEACH_SEA_RAISE_M := 1.5

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


## Altura desenhada num ponto (Fase 329): a da simulação mais o detalhe já calculado (zero antes da TerrainView montar a
## ilha, nos testes sem ela). Para quem põe coisas na praia, onde a rampa baixa o chão.
static func shown_at(grid: IslandGrid, x_m: float, z_m: float) -> float:
	var height := grid.height_at(x_m, z_m)
	var values := offsets_cached(grid)
	if values.is_empty():
		return height
	var gx := clampf((x_m - grid.origin_m.x) / grid.cell_size, 0.0, grid.size.x)
	var gz := clampf((z_m - grid.origin_m.y) / grid.cell_size, 0.0, grid.size.y)
	var x0 := mini(floori(gx), grid.size.x - 1)
	var z0 := mini(floori(gz), grid.size.y - 1)
	var width := grid.size.x + 1
	var top := lerpf(values[z0 * width + x0], values[z0 * width + x0 + 1], gx - x0)
	var bottom := lerpf(values[(z0 + 1) * width + x0], values[(z0 + 1) * width + x0 + 1], gx - x0)
	return height + lerpf(top, bottom, gz - z0)


## Célula onde algo da simulação está (Fase 329): prédio, estrada, trilho, árvore (ou derrubada) ou rio. A rampa da praia
## não mexe nos cantos dela.
static func holds_something(grid: IslandGrid, cell: Vector2i) -> bool:
	var index := grid.index(cell)
	if grid.ground[index] == IslandGrid.Ground.RIVER or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
			or grid.roads[index] != IslandGrid.Road.NONE:
		return true
	if not grid.rails.is_empty() and grid.rails[index] != 0:
		return true
	return not grid.cleared_trees.is_empty() and grid.cleared_trees[index] == 1


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
	_add_beach(grid, result, seed_value)
	return result


## Fase 329: a rampa da beira da praia (ver BEACH_MAX_M) somada nos cantos que o detalhe das encostas não mexeu.
static func _add_beach(grid: IslandGrid, result: PackedFloat32Array, seed_value: int) -> void:
	var width := grid.size.x + 1
	var rows := grid.size.y + 1
	var heights := grid.corner_heights
	# os pontos da linha d'água: onde a altura cruza o zero em cada lado de canto a canto, com o mar de verdade (o rio fica
	# de fora) e a altura da terra daquele lado (a falésia não ganha rampa nem embaixo d'água)
	var points := PackedVector2Array()
	var lands := PackedFloat32Array()
	for y: int in rows:
		var row := y * width
		for x: int in width:
			var h := heights[row + x]
			var below := h < 0.0
			# o lado para +x e o para +y, um a um (a ilha inteira passa aqui: nada de montar array por canto)
			if x + 1 < width:
				var other := heights[row + x + 1]
				if below != (other < 0.0) and (_touches_sea(grid, x, y) if below else _touches_sea(grid, x + 1, y)):
					points.append(Vector2(x + h / (h - other), y))
					lands.append(maxf(h, other))
			if y + 1 < rows:
				var other := heights[row + width + x]
				if below != (other < 0.0) and (_touches_sea(grid, x, y) if below else _touches_sea(grid, x, y + 1)):
					points.append(Vector2(x, y + h / (h - other)))
					lands.append(maxf(h, other))
	if points.is_empty():
		return
	var best := PackedFloat32Array()
	best.resize(width * rows)
	best.fill(INF)
	var best_land := PackedFloat32Array()
	best_land.resize(width * rows)
	for p: int in points.size():
		var point := points[p]
		for y: int in range(maxi(0, ceili(point.y) - BEACH_REACH), mini(rows, floori(point.y) + BEACH_REACH + 1)):
			for x: int in range(maxi(0, ceili(point.x) - BEACH_REACH), mini(width, floori(point.x) + BEACH_REACH + 1)):
				var d := point.distance_to(Vector2(x, y))
				var i := y * width + x
				if d < best[i]:
					best[i] = d
					best_land[i] = lands[p]
	var slope_noise := FastNoiseLite.new()
	slope_noise.seed = seed_value + 2
	slope_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	slope_noise.frequency = 1.0 / BEACH_SLOPE_PERIOD_M
	for i: int in best.size():
		if best[i] > BEACH_REACH:
			continue
		if result[i] != 0.0 or best_land[i] > BEACH_MAX_M:
			continue
		var x := i % width
		var y := i / width
		if _corner_holds_something(grid, x, y):
			continue
		var h := heights[i]
		var wx := grid.origin_m.x + x * grid.cell_size
		var wz := grid.origin_m.y + y * grid.cell_size
		var slope := BEACH_SLOPE * (1.0 + slope_noise.get_noise_2d(wx, wz) * BEACH_SLOPE_VARIATION)
		var ramp := best[i] * grid.cell_size * slope
		if h > 0.0 and h <= BEACH_MAX_M:
			result[i] = minf(h, ramp) - h
		elif h < 0.0:
			result[i] = minf(maxf(h, -ramp) - h, BEACH_SEA_RAISE_M)


## O canto (x, y) toca uma célula de mar.
static func _touches_sea(grid: IslandGrid, x: int, y: int) -> bool:
	for cell: Vector2i in [Vector2i(x - 1, y - 1), Vector2i(x, y - 1), Vector2i(x - 1, y), Vector2i(x, y)]:
		if grid.in_bounds(cell) and grid.ground[grid.index(cell)] == IslandGrid.Ground.SEA:
			return true
	return false


## Alguma das células que tocam o canto (x, y) tem algo da simulação (holds_something).
static func _corner_holds_something(grid: IslandGrid, x: int, y: int) -> bool:
	for cell: Vector2i in [Vector2i(x - 1, y - 1), Vector2i(x, y - 1), Vector2i(x - 1, y), Vector2i(x, y)]:
		if grid.in_bounds(cell) and holds_something(grid, cell):
			return true
	return false


## As 4 células que tocam o canto (x, y) estão livres.
static func _corner_free(free: PackedByteArray, columns: int, x: int, y: int) -> bool:
	return free[(y - 1) * columns + x - 1] == 1 and free[(y - 1) * columns + x] == 1 \
			and free[y * columns + x - 1] == 1 and free[y * columns + x] == 1
