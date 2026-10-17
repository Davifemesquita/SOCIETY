class_name ArchipelagoGenerator
extends RefCounted
## Arquipélago por semente (seção 7): a ilha principal e as menores, cada uma numa região do
## terreno. Relevo = ruído + máscara de ilha, em patamares planos (é neles que se constrói) com
## encostas entre eles; litoral de praia ou de falésia; rios que entram pela planície do litoral;
## floresta e manchas de jazida conforme o perfil da ilha. Tudo sai da semente: a mesma semente
## dá sempre o mesmo arquipélago, e o save guarda só a semente e o que a construção mudou.
## Simulação pura: a apresentação (TerrainView) lê as alturas daqui.

## Versão do gerador: vai no save. Mudou o algoritmo, some 1 (saves antigos refariam outro mapa).
const VERSION := 1
## Regiões vizinhas da principal, onde ficam as outras ilhas (sorteadas pela semente).
const REGION_SLOTS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0),
		Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
## Distância normalizada do centro onde fica o litoral (1 = borda da grade).
const SHORE := 0.86
## Quanto o ruído recorta o litoral. SHORE + COAST_NOISE < 1: fora da grade é sempre mar.
const COAST_NOISE := 0.12
## Faixa da planície do litoral (fração da distância normalizada) na praia e na falésia.
const PLAIN_WIDTH := 0.38
const CLIFF_PLAIN_WIDTH := 0.06
## Largura da descida da terra até o fundo do mar, na praia e na falésia.
const BEACH_BAND := 0.07
const CLIFF_BAND := 0.012
## Célula é terra se todos os cantos ficam acima disto.
const LAND_MIN_M := 0.3
## Sem árvores a menos disto do mar (praia).
const BEACH_CELLS := 2
## Largura da lama na margem do rio, em células (desenho só).
const RIVER_BANK_CELLS := 1
const DEPOSIT_TRIES := 600


## Uma ilha a gerar: tamanho, lugar no mundo, perfil e a semente dela.
class IslandSpec:
	var index: int
	var size: int
	var region: Vector2i
	var origin_m: Vector2
	var profile: IslandProfileDef
	var seed_value: int


## Ruídos de uma ilha, todos derivados da semente dela.
class Noises:
	var coast := FastNoiseLite.new()
	var relief := FastNoiseLite.new()
	var cliff := FastNoiseLite.new()
	var forest := FastNoiseLite.new()

	func _init(seed_value: int) -> void:
		for item: Array in [[coast, 0, 1.0 / 90.0, 3], [relief, 1, 1.0 / 230.0, 4], [cliff, 2, 1.0 / 170.0, 2], [forest, 3, 1.0 / 70.0, 3]]:
			var noise: FastNoiseLite = item[0]
			var salt: int = item[1]
			noise.seed = hash([seed_value, salt]) & 0x7fffffff
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			noise.frequency = item[2]
			noise.fractal_type = FastNoiseLite.FRACTAL_FBM
			noise.fractal_octaves = item[3]


## Mundo novo: o arquipélago da semente, com o dinheiro e o navio inicial (com os materiais) na
## principal. Tamanho do arquipélago e dificuldade negativos = os padrões do GameConfig.
static func new_world(seed_value: int, config: GameConfig, data: GameData, archipelago_size: int = -1, difficulty: int = -1) -> WorldState:
	var world := WorldState.new()
	world.seed = seed_value
	world.terrain_version = VERSION
	world.difficulty = difficulty if difficulty >= 0 else config.default_difficulty
	world.money = config.starting_money_for(world.difficulty)
	var size_index := archipelago_size if archipelago_size >= 0 else config.default_archipelago_size
	var specs := layout(seed_value, config, data, config.island_count_for(size_index))
	specs.append_array(tropical_layout(seed_value, config, data, specs.size()))
	for spec: IslandSpec in specs:
		world.islands.append(build_island(spec, config))
		var economy := IslandEconomy.new()
		economy.profile_id = spec.profile.id
		world.economies.append(economy)
	world.add_starting_fleet(config, data)
	return world


## Onde fica cada ilha e com que perfil. A principal fica na região (0, 0), com o canto na origem.
## Com menos ilhas, as primeiras saem iguais às do arquipélago maior da mesma semente.
static func layout(seed_value: int, config: GameConfig, data: GameData, island_count: int = -1) -> Array[IslandSpec]:
	var count := island_count if island_count > 0 else config.island_count_for(config.default_archipelago_size)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "layout"])
	var slots: Array[Vector2i] = REGION_SLOTS.duplicate()
	_shuffle(slots, rng)
	var profiles: Array[StringName] = config.other_island_profiles.duplicate()
	_shuffle(profiles, rng)
	var specs: Array[IslandSpec] = []
	for index: int in mini(count, config.island_sizes_cells.size()):
		var spec := IslandSpec.new()
		spec.index = index
		spec.size = config.island_sizes_cells[index]
		spec.seed_value = hash([seed_value, index]) & 0x7fffffff
		if index == 0:
			spec.region = Vector2i.ZERO
			spec.origin_m = Vector2.ZERO
			spec.profile = data.profile(config.main_island_profile)
		else:
			spec.region = slots[index - 1]
			var side_m := spec.size * config.cell_size_m
			var free_cells := floori((config.terrain_region_m - side_m) / config.cell_size_m)
			var offset := Vector2(rng.randi_range(free_cells / 4, free_cells * 3 / 4), rng.randi_range(free_cells / 4, free_cells * 3 / 4))
			spec.origin_m = Vector2(spec.region) * config.terrain_region_m + offset * config.cell_size_m
			var profile_id: StringName = profiles[(index - 1) % profiles.size()]
			spec.profile = data.profile(profile_id)
		specs.append(spec)
	return specs


## Ilhas tropicais (Fase 11): saem da semente à parte, nas regiões de tropical_regions, e entram
## depois das temperadas (first_index é o índice da primeira). São as mesmas em qualquer tamanho de
## arquipélago, e layout() não muda: os saves de antes continuam com o mesmo terreno.
static func tropical_layout(seed_value: int, config: GameConfig, data: GameData, first_index: int, island_count: int = -1) -> Array[IslandSpec]:
	var count := config.tropical_island_sizes_cells.size() if island_count < 0 else mini(island_count, config.tropical_island_sizes_cells.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "tropical"])
	var regions: Array[Vector2i] = config.tropical_regions.duplicate()
	_shuffle(regions, rng)
	var profiles: Array[StringName] = config.tropical_island_profiles.duplicate()
	_shuffle(profiles, rng)
	var specs: Array[IslandSpec] = []
	for number: int in mini(count, regions.size()):
		var spec := IslandSpec.new()
		spec.index = first_index + number
		spec.size = config.tropical_island_sizes_cells[number]
		spec.seed_value = hash([seed_value, "tropical", number]) & 0x7fffffff
		spec.region = regions[number]
		var free_cells := floori((config.terrain_region_m - spec.size * config.cell_size_m) / config.cell_size_m)
		var offset := Vector2(rng.randi_range(free_cells / 4, free_cells * 3 / 4), rng.randi_range(free_cells / 4, free_cells * 3 / 4))
		spec.origin_m = Vector2(spec.region) * config.terrain_region_m + offset * config.cell_size_m
		spec.profile = data.profile(profiles[number % profiles.size()])
		specs.append(spec)
	return specs


## As ilhas de um mundo gerado, na ordem dele: as temperadas e depois as tropicais (contadas pelo
## perfil da economia de cada ilha).
static func world_specs(world: WorldState, config: GameConfig, data: GameData) -> Array[IslandSpec]:
	var tropical := 0
	for economy: IslandEconomy in world.economies:
		var profile := data.profile(economy.profile_id)
		if profile != null and profile.is_tropical():
			tropical += 1
	var specs := layout(world.seed, config, data, world.islands.size() - tropical)
	specs.append_array(tropical_layout(world.seed, config, data, specs.size(), tropical))
	return specs


## Gera uma ilha inteira: alturas dos cantos, chão, rios, floresta e jazidas.
static func build_island(spec: IslandSpec, config: GameConfig) -> IslandGrid:
	var grid := IslandGrid.new(Vector2i(spec.size, spec.size))
	grid.origin_m = spec.origin_m
	grid.cell_size = config.cell_size_m
	grid.init_terrain()
	var noises := Noises.new(spec.seed_value)
	for y: int in spec.size + 1:
		for x: int in spec.size + 1:
			grid.corner_heights[grid.corner_index(x, y)] = height_at(spec, noises, config,
					spec.origin_m.x + x * config.cell_size_m, spec.origin_m.y + y * config.cell_size_m)
	_classify_ground(grid)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([spec.seed_value, "features"])
	for river: int in spec.profile.rivers:
		_carve_river(grid, config, rng)
	_place_deposits(grid, spec.profile, config, rng)
	_grow_forest(grid, spec.profile, noises, config)
	grid.invalidate_heights()
	grid.fingerprint = fingerprint(grid)
	return grid


## Altura do terreno num ponto do mundo (metros), dentro ou fora da grade da ilha.
static func height_at(spec: IslandSpec, noises: Noises, config: GameConfig, x: float, z: float) -> float:
	var d := _coast_metric(spec, noises, config, x, z)
	var cliff := smoothstep(0.12, 0.4, noises.cliff.get_noise_2d(x, z))
	var plain := lerpf(PLAIN_WIDTH, CLIFF_PLAIN_WIDTH, cliff)
	var inland := clampf((SHORE - d) / plain, 0.0, 1.0)
	var levels := config.terrace_levels_m
	var top := levels[levels.size() - 1] + 2.0
	var r := smoothstep(0.3, 0.85, noises.relief.get_noise_2d(x, z) * 0.5 + 0.5)
	var land := terrace(r * inland * spec.profile.relief * top, levels, config.terrace_flat_fraction)
	var band := lerpf(BEACH_BAND, CLIFF_BAND, cliff)
	return lerpf(land, config.sea_floor_m, smoothstep(SHORE - band, SHORE + 0.005, d))


## Distância do centro da ilha (1 = borda da grade) num quadrado de cantos redondos, com o litoral
## recortado pelo ruído: o litoral fica em SHORE.
static func _coast_metric(spec: IslandSpec, noises: Noises, config: GameConfig, x: float, z: float) -> float:
	var side := spec.size * config.cell_size_m
	var cx := absf(((x - spec.origin_m.x) / side - 0.5) * 2.0)
	var cz := absf(((z - spec.origin_m.y) / side - 0.5) * 2.0)
	return pow(cx * cx * cx * cx + cz * cz * cz * cz, 0.25) + noises.coast.get_noise_2d(x, z) * COAST_NOISE


## Degraus: cada faixa entre dois patamares fica plana em terrace_flat_fraction e sobe no resto.
static func terrace(raw: float, levels: PackedFloat32Array, flat_fraction: float) -> float:
	if raw <= levels[0]:
		return levels[0]
	for k: int in levels.size() - 1:
		if raw < levels[k + 1]:
			var fraction := (raw - levels[k]) / (levels[k + 1] - levels[k])
			return levels[k] + (levels[k + 1] - levels[k]) * smoothstep(flat_fraction, 1.0, fraction)
	return levels[levels.size() - 1]


## Terra é a célula com os quatro cantos acima de LAND_MIN_M; o resto é mar.
static func _classify_ground(grid: IslandGrid) -> void:
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var low := minf(minf(grid.corner_height(x, y), grid.corner_height(x + 1, y)),
					minf(grid.corner_height(x, y + 1), grid.corner_height(x + 1, y + 1)))
			grid.ground[y * grid.size.x + x] = IslandGrid.Ground.LAND if low >= LAND_MIN_M else IslandGrid.Ground.SEA


## Rio: um braço de mar que entra pela planície do litoral (fica no nível do mar, sem precisar de
## água própria). Começa numa praia e anda para dentro, desviando de morro. Só os cantos de
## dentro descem: as margens ficam planas e dá para construir encostado (olaria).
static func _carve_river(grid: IslandGrid, config: GameConfig, rng: RandomNumberGenerator) -> void:
	var low_limit := config.terrace_levels_m[0] + 0.2
	var center := Vector2(grid.size) * 0.5
	for attempt: int in 40:
		var start := Vector2i(rng.randi_range(4, grid.size.x - 5), rng.randi_range(4, grid.size.y - 5))
		# anda do ponto sorteado para fora até achar o mar: o rio começa ali
		var outward := (Vector2(start) - center).normalized()
		if outward == Vector2.ZERO:
			continue
		var probe := Vector2(start)
		var mouth := Vector2i(-1, -1)
		for step: int in grid.size.x:
			probe += outward
			var cell := Vector2i(roundi(probe.x), roundi(probe.y))
			if grid.ground_at(cell) == IslandGrid.Ground.SEA:
				mouth = Vector2i(roundi(probe.x - outward.x), roundi(probe.y - outward.y))
				break
		if mouth.x < 0 or grid.cell_height(mouth) > low_limit:
			continue
		var path := _river_path(grid, mouth, -outward, config, low_limit, rng)
		if path.size() >= 20:
			_carve(grid, path, config)
			return


## Curso do rio: entra pela foz e serpenteia para dentro (seno com fase sorteada) enquanto houver
## planície do litoral; para no primeiro morro.
static func _river_path(grid: IslandGrid, mouth: Vector2i, inward: Vector2, config: GameConfig, low_limit: float,
		rng: RandomNumberGenerator) -> Array[Vector2i]:
	var side := Vector2(-inward.y, inward.x)
	var phase := rng.randf() * TAU
	var path: Array[Vector2i] = [mouth]
	var point := Vector2(mouth)
	var step := 0
	while path.size() < config.river_length_cells and step < config.river_length_cells * 3:
		step += 1
		point += inward * 0.6
		var bend := side * sin(step * 0.18 + phase) * 3.5
		var cell := Vector2i(roundi(point.x + bend.x), roundi(point.y + bend.y))
		if cell == path[path.size() - 1]:
			continue
		if not grid.in_bounds(cell) or cell.x < 3 or cell.y < 3 or cell.x > grid.size.x - 4 or cell.y > grid.size.y - 4:
			break
		if not grid.is_land(cell) or grid.cell_height(cell) > low_limit:
			break
		# liga a célula nova à anterior pelos lados (sem diagonal: o rio não pode ter furo)
		var last := path[path.size() - 1]
		if last.x != cell.x and last.y != cell.y:
			path.append(Vector2i(cell.x, last.y))
		path.append(cell)
	return path


## Marca as células do rio (largura river_width_cells) e afunda só os cantos de dentro.
static func _carve(grid: IslandGrid, path: Array[Vector2i], config: GameConfig) -> void:
	var half := config.river_width_cells / 2
	var cells: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in path:
		for dy: int in range(-half, config.river_width_cells - half):
			for dx: int in range(-half, config.river_width_cells - half):
				var river_cell := cell + Vector2i(dx, dy)
				if grid.in_bounds(river_cell) and grid.is_land(river_cell):
					cells[river_cell] = true
	for river_cell: Vector2i in cells:
		grid.ground[grid.index(river_cell)] = IslandGrid.Ground.RIVER
	# canto de dentro = os quatro vizinhos dele são rio (ou mar)
	for river_cell: Vector2i in cells:
		for corner: Vector2i in [river_cell, river_cell + Vector2i(1, 0), river_cell + Vector2i(0, 1), river_cell + Vector2i(1, 1)]:
			var inside := true
			for around: Vector2i in [corner, corner - Vector2i(1, 0), corner - Vector2i(0, 1), corner - Vector2i(1, 1)]:
				if grid.ground_at(around) == IslandGrid.Ground.LAND:
					inside = false
					break
			if inside:
				grid.corner_heights[grid.corner_index(corner.x, corner.y)] = config.river_bed_m


## Manchas quadradas de jazida em lugar plano, de preferência nos morros.
static func _place_deposits(grid: IslandGrid, profile: IslandProfileDef, config: GameConfig, rng: RandomNumberGenerator) -> void:
	grid.deposit_goods = profile.deposits.duplicate()
	var spot := config.deposit_spot_cells
	for good_index: int in profile.deposits.size():
		for spot_number: int in profile.deposit_spots:
			var best := Rect2i()
			var best_height := -INF
			for attempt: int in DEPOSIT_TRIES:
				var area := Rect2i(rng.randi_range(2, grid.size.x - spot - 2), rng.randi_range(2, grid.size.y - spot - 2), spot, spot)
				if not grid.area_is_land(area) or grid.area_relief(area) > config.max_build_height_delta_m:
					continue
				if _has_deposit(grid, area.grow(2)):
					continue
				var height := grid.area_height(area)
				if height > best_height:
					best = area
					best_height = height
			if best_height == -INF:
				continue
			for y: int in range(best.position.y, best.end.y):
				for x: int in range(best.position.x, best.end.x):
					grid.deposits[y * grid.size.x + x] = good_index + 1


static func _has_deposit(grid: IslandGrid, area: Rect2i) -> bool:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	for y: int in range(clipped.position.y, clipped.end.y):
		for x: int in range(clipped.position.x, clipped.end.x):
			if grid.deposits[y * grid.size.x + x] != 0:
				return true
	return false


## Floresta: as células de terra com o ruído mais alto, até cobrir forest_coverage da terra.
## Mais árvores por célula no miolo da mancha; nada na praia nem em cima de jazida.
static func _grow_forest(grid: IslandGrid, profile: IslandProfileDef, noises: Noises, config: GameConfig) -> void:
	var values := PackedFloat32Array()
	var candidates := PackedInt32Array()
	var coastal := near_sea(grid, BEACH_CELLS)
	for i: int in grid.ground.size():
		if grid.ground[i] != IslandGrid.Ground.LAND or grid.deposits[i] != 0 or coastal[i] == 1:
			continue
		var cell := grid.cell_at(i)
		var world := grid.cell_world(cell)
		values.append(noises.forest.get_noise_2d(world.x, world.z))
		candidates.append(i)
	if candidates.is_empty() or profile.forest_coverage <= 0.0:
		return
	var sorted := values.duplicate()
	sorted.sort()
	var land_cells := grid.ground.count(IslandGrid.Ground.LAND)
	var keep := clampi(roundi(land_cells * profile.forest_coverage), 0, sorted.size())
	if keep == 0:
		return
	var threshold := sorted[sorted.size() - keep]
	var peak := sorted[sorted.size() - 1]
	for k: int in candidates.size():
		if values[k] >= threshold:
			var depth := (values[k] - threshold) / maxf(peak - threshold, 0.0001)
			grid.trees[candidates[k]] = clampi(1 + floori(depth * config.max_trees_per_cell * 1.6), 1, config.max_trees_per_cell)


## 1 nas células a até reach do mar (dilatação do mar, direto nos arrays: roda na ilha toda).
static func near_sea(grid: IslandGrid, reach: int) -> PackedByteArray:
	var width := grid.size.x
	var height := grid.size.y
	var near := PackedByteArray()
	near.resize(grid.ground.size())
	for i: int in grid.ground.size():
		var x := i % width
		var y := i / width
		if grid.ground[i] == IslandGrid.Ground.SEA or x == 0 or y == 0 or x == width - 1 or y == height - 1:
			near[i] = 1
	for ring: int in reach:
		var grown := near.duplicate()
		for i: int in near.size():
			if near[i] == 1:
				continue
			var x := i % width
			if near[i - width] == 1 or near[i + width] == 1 or (x > 0 and near[i - 1] == 1) or (x < width - 1 and near[i + 1] == 1):
				grown[i] = 1
		near = grown
	return near


## Células de terra a até `reach` células do rio, e o próprio rio (a lama da margem).
static func near_river(grid: IslandGrid, reach: int) -> PackedByteArray:
	var width := grid.size.x
	var near := PackedByteArray()
	near.resize(grid.ground.size())
	for i: int in grid.ground.size():
		if grid.ground[i] == IslandGrid.Ground.RIVER:
			near[i] = 1
	for ring: int in reach:
		var grown := near.duplicate()
		for i: int in near.size():
			if near[i] == 1:
				continue
			var x := i % width
			if (i >= width and near[i - width] == 1) or (i + width < near.size() and near[i + width] == 1) \
					or (x > 0 and near[i - 1] == 1) or (x < width - 1 and near[i + 1] == 1):
				grown[i] = 1
		near = grown
	return near


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap


## Assinatura do terreno de uma ilha (alturas, chão, árvores, jazidas): a mesma semente tem que dar
## a mesma assinatura; o save a confere ao carregar.
static func fingerprint(grid: IslandGrid) -> int:
	return hash([grid.corner_heights, grid.ground, grid.trees, grid.deposits])


## Tipos de chão do terreno desenhado (a apresentação vira textura).
enum Surface { AUTO = 0, SAND = 1, FOREST = 2, MUD = 3 }


## Região do terreno de uma ilha gerada, de 2 em 2 m, cantos inclusive: {side, heights
## (PackedFloat32Array), surface (PackedByteArray, Surface)}. Dentro da grade, as alturas da ilha
## (com os rios); fora, o fundo do mar (o litoral fica sempre dentro da grade). No mar, o fundo
## desenhado desce até deep_sea_floor_m pela distância da costa e, na borda da região, já está lá
## (sem degrau contra o mar aberto, onde não há terreno): é só o desenho, a simulação fica com
## sea_floor_m. Percorre a região inteira em GDScript, então lê os arrays da grade direto.
static func region_corners(world: WorldState, index: int, config: GameConfig, data: GameData) -> Dictionary:
	var spec := world_specs(world, config, data)[index]
	var grid := world.island(index)
	var noises := Noises.new(spec.seed_value)
	var cell_m := config.cell_size_m
	var side := roundi(config.terrain_region_m / cell_m) + 1
	var origin := Vector2(spec.region) * config.terrain_region_m
	var heights := PackedFloat32Array()
	var surface := PackedByteArray()
	heights.resize(side * side)
	surface.resize(side * side)
	var first := Vector2i(roundi((grid.origin_m.x - origin.x) / cell_m), roundi((grid.origin_m.y - origin.y) / cell_m))
	# areia: o mar, o rio e a faixa de praia junto ao mar
	var beach := near_sea(grid, BEACH_CELLS + 1)
	# lama: o leito do rio e a margem dele, onde não é praia
	var bank := near_river(grid, RIVER_BANK_CELLS)
	var corner_heights := grid.corner_heights
	var ground := grid.ground
	var trees := grid.trees
	var corner_side := grid.size.x + 1
	var drop := config.sea_floor_m - config.deep_sea_floor_m
	var shelf_start := SHORE + 0.005
	var shelf_end := shelf_start + config.sea_shelf_width_m / (spec.size * cell_m * 0.5)
	for py: int in side:
		var gy := py - first.y
		var z := origin.y + py * cell_m
		var edge_y := mini(py, side - 1 - py)
		for px: int in side:
			var gx := px - first.x
			var height := config.sea_floor_m
			var kind := Surface.SAND
			var sea := true
			if gx >= 0 and gy >= 0 and gx <= grid.size.x and gy <= grid.size.y:
				height = corner_heights[gy * corner_side + gx]
				var cell := mini(gy, grid.size.y - 1) * grid.size.x + mini(gx, grid.size.x - 1)
				sea = ground[cell] == IslandGrid.Ground.SEA
				if ground[cell] == IslandGrid.Ground.LAND and beach[cell] == 0:
					kind = Surface.FOREST if trees[cell] > 0 else Surface.AUTO
				if bank[cell] == 1 and beach[cell] == 0:
					kind = Surface.MUD
			if sea and height < 0.0:
				var x := origin.x + px * cell_m
				var from_coast := smoothstep(shelf_start, shelf_end, _coast_metric(spec, noises, config, x, z))
				var edge := mini(edge_y, mini(px, side - 1 - px)) * cell_m
				height -= drop * maxf(from_coast, 1.0 - smoothstep(0.0, config.sea_shelf_width_m, edge))
			heights[py * side + px] = height
			surface[py * side + px] = kind
	return {"side": side, "origin": origin, "heights": heights, "surface": surface}
