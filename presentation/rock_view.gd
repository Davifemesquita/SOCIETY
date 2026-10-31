class_name RockView
extends Node3D
## Fase 56: rocha de verdade nos rochedos do mar e nas faces das falésias (RockModel), no lugar dos montes lisos do
## terreno. Sai das alturas desenhadas de cada região (TerrainView.region_heights), uma vez ao montar o mundo, num
## MultiMesh por ilha e por variante. Só apresentação: nada no save, nada na simulação.
## - Rochedo: cada pedaço pequeno de terra alta solto no mar (cantos acima de STACK_MIN_M ligados, até
##   STACK_MAX_CORNERS, bem menor que a maior terra da região e com quase toda a volta debaixo d'água — um morro no meio
##   da planície não conta, nem o morro colado numa praia onde se constrói) ganha um bloco que cobre o monte, um pilar
##   mais alto e pedras na água em volta.
## - Falésia: canto de terra com queda de CLIFF_DROP_M até o vizinho e mar logo abaixo ganha uma rocha encaixada na
##   encosta, deslocada para baixo e sempre com o topo abaixo do canto de cima (não sobe no lote plano da borda). Nunca
##   numa célula onde caberia estrada ou prédio.

## Acima disto o canto conta como terra do rochedo (a faixa rasa que às vezes o liga à ilha fica abaixo).
const STACK_MIN_M := 2.0
const STACK_MAX_CORNERS := 600
## O rochedo é bem menor que a maior terra da região (uma ilha pequena inteira não vira rochedo).
const STACK_SHARE := 0.2
## Fração de um anel STACK_RING_CELLS além do pedaço que tem de estar debaixo d'água (amostrado em STACK_RING_SAMPLES
## pontos).
const STACK_SEA_SHARE := 0.35
const STACK_RING_CELLS := 3.0
const STACK_RING_SAMPLES := 16
## Quanto o bloco e o pilar passam do topo do monte.
const STACK_TOP_M := 0.4
const PILLAR_RISE := 1.3
const STACK_SATELLITES := Vector2i(2, 4)
const CLIFF_MIN_M := 0.3
const CLIFF_DROP_M := 2.4
## Até quantos cantos descendo tem de haver mar.
const CLIFF_SEA_REACH := 3
## Chance de ficar com a rocha do bloco de 2 × 2 cantos (uma por bloco no máximo).
const CLIFF_KEEP := 0.7
## Raio da rocha da falésia: sorteado nesta faixa, e pelo menos CLIFF_WIDTH vezes a altura (bloco, não dente).
const CLIFF_RADIUS_M := Vector2(1.4, 2.4)
const CLIFF_WIDTH := 0.5
const CLIFF_BELOW_TOP_M := 0.25
const CLIFF_TILT := 0.25
const VISIBLE_UNTIL_M := 900.0
## A rocha do terreno (a mesma textura, no tom do rock_grade do terrain.gdshader) e o tamanho de cada repetição.
const TINT := Color(0.78, 0.74, 0.7)
const TEXTURE_M := 4.0
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

enum Kind { STACK, CLIFF }

var _counts: Dictionary[int, int] = {}
var _material: StandardMaterial3D
## Fase 123: onde o mar bate na rocha (x, z e o raio da rocha), para o borrifo da SurfSprayView.
var _spray_sites := PackedVector3Array()


func setup(terrain: TerrainView, world: WorldState, config: GameConfig) -> void:
	_material = material()
	for index: int in world.islands.size():
		var region := terrain.region_heights(index)
		if region.is_empty():
			continue
		var heights: PackedFloat32Array = region["heights"]
		var side: int = region["side"]
		var origin: Vector2 = region["origin"]
		var entries := places(heights, side, origin, config.cell_size_m, world.island(index), config.max_road_relief_m, index)
		var buffers: Array[PackedFloat32Array] = []
		for variant: int in RockModel.VARIANTS:
			buffers.append(PackedFloat32Array())
		for entry: Array in entries:
			var kind: int = entry[2]
			_counts[kind] = _counts.get(kind, 0) + 1
			var variant: int = entry[0]
			var place: Transform3D = entry[1]
			var b := place.basis
			_spray_sites.append(Vector3(place.origin.x, place.origin.z, Vector2(b.x.x, b.x.z).length()))
			buffers[variant].append_array(PackedFloat32Array([b.x.x, b.y.x, b.z.x, place.origin.x, b.x.y, b.y.y, b.z.y,
					place.origin.y, b.x.z, b.y.z, b.z.z, place.origin.z]))
		for variant: int in RockModel.VARIANTS:
			if buffers[variant].is_empty():
				continue
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = RockModel.mesh(variant)
			multimesh.instance_count = buffers[variant].size() / 12
			multimesh.buffer = buffers[variant]
			var node := MultiMeshInstance3D.new()
			node.name = "Rocks_%d_%d" % [index, variant]
			node.multimesh = multimesh
			node.material_override = _material
			node.visibility_range_end = VISIBLE_UNTIL_M
			add_child(node)


## Fase 123: onde o mar bate na rocha — x, z e o raio de cada rocha de rochedo e de falésia (todas encostam no mar).
func spray_sites() -> PackedVector3Array:
	return _spray_sites


## Rochas desenhadas (todas, ou de um tipo).
func rock_count(kind: int = -1) -> int:
	if kind >= 0:
		return _counts.get(kind, 0)
	var total := 0
	for each: int in _counts.values():
		total += each
	return total


## A rocha do terreno, triplanar no mundo (não estica e casa com a falésia em volta).
static func material() -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_texture = load("res://assets/terrain/rock_albedo_height.png")
	result.albedo_color = TINT
	result.normal_enabled = true
	result.normal_texture = load("res://assets/terrain/rock_normal_roughness.png")
	result.uv1_triplanar = true
	result.uv1_world_triplanar = true
	result.uv1_scale = Vector3.ONE / TEXTURE_M
	result.roughness = 0.92
	return result


## As rochas de uma região: [[variante, lugar no mundo, Kind], ...]. Função pura das alturas (testes). grid pode ser
## null (sem conferir onde cabe obra).
static func places(heights: PackedFloat32Array, side: int, origin: Vector2, spacing: float, grid: IslandGrid,
		max_relief: float, salt: int) -> Array:
	var result: Array = []
	_stacks(heights, side, origin, spacing, grid, max_relief, salt, result)
	_cliffs(heights, side, origin, spacing, grid, max_relief, salt, result)
	return result


static func _stacks(heights: PackedFloat32Array, side: int, origin: Vector2, spacing: float, grid: IslandGrid,
		max_relief: float, salt: int, result: Array) -> void:
	# 0 não visto, 1 num pedaço pequeno, 2 em terra grande (passou do teto ou encostou nela): a busca para logo que
	# encosta numa terra grande, então o interior da ilha quase não é visitado
	var state := PackedByteArray()
	state.resize(side * side)
	var largest := 0
	var pieces: Array[PackedInt32Array] = []
	for start: int in side * side:
		if state[start] != 0 or heights[start] <= STACK_MIN_M or not _near_low(heights, side, start):
			continue
		var queue := PackedInt32Array([start])
		state[start] = 1
		var big := false
		var head := 0
		while head < queue.size() and not big:
			var at := queue[head]
			head += 1
			var x := at % side
			var y := at / side
			if x == 0 or y == 0 or x == side - 1 or y == side - 1 or queue.size() > STACK_MAX_CORNERS:
				big = true
				break
			for step: Vector2i in SIDES:
				var next := (y + step.y) * side + x + step.x
				if heights[next] <= STACK_MIN_M:
					continue
				if state[next] == 2:
					big = true
					break
				if state[next] == 0:
					state[next] = 1
					queue.append(next)
		if big:
			for at: int in queue:
				state[at] = 2
			largest = STACK_MAX_CORNERS * 1000
			continue
		largest = maxi(largest, queue.size())
		pieces.append(queue)
	for piece: PackedInt32Array in pieces:
		if piece.size() > largest * STACK_SHARE:
			continue
		var peak := 0.0
		var center := Vector2.ZERO
		var weight := 0.0
		for at: int in piece:
			var h := heights[at]
			peak = maxf(peak, h)
			center += Vector2(at % side, at / side) * h
			weight += h
		center /= weight
		if not _in_the_sea(heights, side, center, sqrt(piece.size() / PI) + STACK_RING_CELLS):
			continue
		center = origin + center * spacing
		# o pedaço é o que passa de STACK_MIN_M: o pé do monte vai uma célula além
		var radius := sqrt(piece.size() / PI) * spacing + spacing
		if grid != null and _covers_low_land(grid, center, radius, max_relief):
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([salt, piece[0], &"rochedo"])
		# o bloco cobre o monte (do fundo até um pouco acima do topo); o pilar, mais estreito, passa do topo
		_add(result, rng, Kind.STACK, Vector3(center.x, -1.0, center.y), Vector3(radius, peak + 1.0 + STACK_TOP_M, radius), 0.0,
				Vector2.ZERO)
		var lean := Vector2.from_angle(rng.randf() * TAU) * radius * 0.25
		_add(result, rng, Kind.STACK, Vector3(center.x + lean.x, -1.0, center.y + lean.y),
				Vector3(radius * 0.55, peak * PILLAR_RISE + 1.0 + STACK_TOP_M, radius * 0.55), 0.0, Vector2.ZERO)
		for k: int in rng.randi_range(STACK_SATELLITES.x, STACK_SATELLITES.y):
			var around := Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.8, 1.1)
			var size := radius * rng.randf_range(0.2, 0.35)
			_add(result, rng, Kind.STACK, Vector3(center.x + around.x, -0.8, center.y + around.y),
					Vector3(size, rng.randf_range(1.3, 2.6), size), 0.0, Vector2.ZERO)


## Num anel de raio ring (em cantos) em volta do centro, pelo menos STACK_SEA_SHARE debaixo d'água (fora da região
## conta como mar).
static func _in_the_sea(heights: PackedFloat32Array, side: int, center: Vector2, ring: float) -> bool:
	var wet := 0
	for k: int in STACK_RING_SAMPLES:
		var at := Vector2i((center + Vector2.from_angle(TAU * k / STACK_RING_SAMPLES) * ring).round())
		if at.x < 0 or at.y < 0 or at.x >= side or at.y >= side or heights[at.y * side + at.x] < 0.0:
			wet += 1
	return wet >= STACK_RING_SAMPLES * STACK_SEA_SHARE


## A borda do bloco (a 0,7 e a 1 raio) cai em terra baixa onde caberia estrada ou prédio (a praia do lado de um morro
## da costa): aí não é rochedo.
static func _covers_low_land(grid: IslandGrid, center: Vector2, radius: float, max_relief: float) -> bool:
	for k: int in STACK_RING_SAMPLES:
		for reach: float in [0.7, 1.0]:
			var point := center + Vector2.from_angle(TAU * k / STACK_RING_SAMPLES) * radius * reach
			var cell := grid.world_to_cell(Vector3(point.x, 0.0, point.y))
			if not grid.in_bounds(cell) or grid.ground[grid.index(cell)] != IslandGrid.Ground.LAND:
				continue
			if grid.cell_height(cell) < STACK_MIN_M and grid.area_relief(Rect2i(cell, Vector2i.ONE)) <= max_relief:
				return true
	return false


## O canto tem vizinho baixo (ou fora da região): só dali começa a busca de um pedaço.
static func _near_low(heights: PackedFloat32Array, side: int, at: int) -> bool:
	var x := at % side
	var y := at / side
	for step: Vector2i in SIDES:
		var nx := x + step.x
		var ny := y + step.y
		if nx < 0 or ny < 0 or nx >= side or ny >= side or heights[ny * side + nx] <= STACK_MIN_M:
			return true
	return false


static func _cliffs(heights: PackedFloat32Array, side: int, origin: Vector2, spacing: float, grid: IslandGrid,
		max_relief: float, salt: int, result: Array) -> void:
	for y: int in range(1, side - 1):
		for x: int in range(1, side - 1):
			var h := heights[y * side + x]
			if h < CLIFF_MIN_M:
				continue
			var low := h
			var down := Vector2i.ZERO
			for step: Vector2i in SIDES:
				var other := heights[(y + step.y) * side + x + step.x]
				if other < low:
					low = other
					down = step
			if h - low < CLIFF_DROP_M:
				continue
			# uma por bloco de 2 × 2 cantos, no canto sorteado do bloco
			var block := hash([salt, x / 2, y / 2, &"falesia"])
			if block % 4 != (x % 2) + (y % 2) * 2 or float(block / 4 % 1000) >= CLIFF_KEEP * 1000.0:
				continue
			var sea := false
			for reach: int in range(1, CLIFF_SEA_REACH + 1):
				var at := Vector2i(x, y) + down * reach
				if at.x < 0 or at.y < 0 or at.x >= side or at.y >= side or heights[at.y * side + at.x] < 0.0:
					sea = true
					break
			if not sea:
				continue
			var dir := Vector2(down)
			var spot := origin + (Vector2(x, y) + dir * 0.6) * spacing
			if grid != null and not _rock_allowed(grid, spot, max_relief):
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = block
			var base := low - 0.6
			var top := h - CLIFF_BELOW_TOP_M
			var radius := maxf(rng.randf_range(CLIFF_RADIUS_M.x, CLIFF_RADIUS_M.y), (top - base) * CLIFF_WIDTH)
			_add(result, rng, Kind.CLIFF, Vector3(spot.x, base, spot.y), Vector3(radius, top - base, radius * 0.8),
					CLIFF_TILT, dir)


## Rocha só onde não cabe obra: mar, fora da grade da ilha ou célula íngreme demais para estrada (e sem nada em cima).
static func _rock_allowed(grid: IslandGrid, spot: Vector2, max_relief: float) -> bool:
	var cell := grid.world_to_cell(Vector3(spot.x, 0.0, spot.y))
	if not grid.in_bounds(cell):
		return true
	var index := grid.index(cell)
	if grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE:
		return false
	match grid.ground[index]:
		IslandGrid.Ground.SEA:
			return true
		IslandGrid.Ground.LAND:
			return grid.area_relief(Rect2i(cell, Vector2i.ONE)) > max_relief
	return false


## Uma rocha: base em position (o zero da malha), tamanho em metros (x e z o raio, y a altura do zero ao topo), giro
## sorteado e, na falésia, inclinada para baixo (dir) pela fração tilt.
static func _add(result: Array, rng: RandomNumberGenerator, kind: int, position: Vector3, size: Vector3, tilt: float,
		dir: Vector2) -> void:
	var basis := Basis(Vector3.UP, rng.randf() * TAU)
	if tilt > 0.0 and dir != Vector2.ZERO:
		# girar em torno do eixo de lado com ângulo negativo leva o topo para o lado de dir (e só o abaixa)
		basis = Basis(Vector3(-dir.y, 0.0, dir.x).normalized(), -tilt) * basis
	var variant := rng.randi() % RockModel.VARIANTS
	result.append([variant, Transform3D(basis * Basis.from_scale(size), position), kind])
