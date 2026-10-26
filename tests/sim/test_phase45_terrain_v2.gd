extends GdUnitTestSuite
## Ilhas novas (Fase 45, terrain_version 2): o v2 convive com o v1 (que não muda: o teste dourado confere), é
## determinístico por semente e independente da ordem de chamada, não lê como quadrado, deixa área construível,
## tem lugar para o entreposto, salva e carrega na versão que gravou, e o save de versão desconhecida é recusado.

const SEEDS: Array[int] = [1840, 5, 777, 42]

var _config: GameConfig
var _data: GameData


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([120, 70, 50])
	_config.tropical_island_sizes_cells = PackedInt32Array([50])
	_data = GameData.get_default()


func _fingerprints(world: WorldState) -> PackedInt64Array:
	var result := PackedInt64Array()
	for grid: IslandGrid in world.islands:
		result.append(grid.fingerprint)
	return result


## Células de terra construíveis (lote de 1 célula dentro da tolerância, sem rio).
static func buildable(grid: IslandGrid, config: GameConfig) -> int:
	var count := 0
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell := Vector2i(x, y)
			if grid.ground_at(cell) == IslandGrid.Ground.LAND and grid.area_relief(Rect2i(cell, Vector2i.ONE)) \
					<= config.max_build_height_delta_m + 0.0001:
				count += 1
	return count


## Quanto a terra enche o retângulo em volta dela (1 = um quadrado cheio).
static func squareness(grid: IslandGrid) -> float:
	var low := grid.size
	var high := Vector2i(-1, -1)
	var land := 0
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			if grid.ground_at(Vector2i(x, y)) != IslandGrid.Ground.SEA:
				land += 1
				low = low.min(Vector2i(x, y))
				high = high.max(Vector2i(x, y))
	if land == 0:
		return 0.0
	var box := (high.x - low.x + 1) * (high.y - low.y + 1)
	return float(land) / box


func test_the_new_game_default_stays_on_v1_until_approval() -> void:
	assert_int(GameConfig.get_default().new_game_terrain_version).is_equal(1)
	assert_int(ArchipelagoGenerator.VERSION).is_equal(1)
	var world := ArchipelagoGenerator.new_world(1840, _config, _data)
	assert_int(world.terrain_version).is_equal(1)
	assert_array(Array(TerrainV2Params.get_default().validate())).is_empty()


func test_v2_is_deterministic_and_independent_of_call_order() -> void:
	for seed_value: int in SEEDS:
		var a := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 2)
		var b := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 2)
		assert_int(a.terrain_version).is_equal(2)
		assert_that(_fingerprints(a)).is_equal(_fingerprints(b))
		# uma ilha sozinha, fora da ordem, dá a mesma
		var specs := ArchipelagoGenerator.layout(seed_value, _config, _data, 3)
		var alone := ArchipelagoGenerator.build_island(specs[2], _config, 2)
		assert_int(alone.fingerprint).is_equal(a.islands[2].fingerprint)
		# e é outra ilha que a do v1
		var v1 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 1)
		assert_int(v1.islands[0].fingerprint).is_not_equal(a.islands[0].fingerprint)


func test_v2_islands_are_not_squares_and_keep_building_land() -> void:
	var report := PackedStringArray()
	for seed_value: int in SEEDS:
		var v1 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 1)
		var v2 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 2)
		for index: int in v2.islands.size():
			var grid := v2.islands[index]
			var old := v1.islands[index]
			var square_v1 := squareness(old)
			var square_v2 := squareness(grid)
			var build_v1 := buildable(old, _config)
			var build_v2 := buildable(grid, _config)
			report.append("semente %d ilha %d: enchimento %.2f → %.2f; construível %d → %d (%.0f%%)" % [seed_value, index,
					square_v1, square_v2, build_v1, build_v2, 100.0 * build_v2 / maxi(build_v1, 1)])
			# o v2 enche menos o retângulo em volta (não é quadrado)
			assert_float(square_v2).override_failure_message(report[report.size() - 1]).is_less(square_v1)
			assert_float(square_v2).is_less(0.85)
			# área construível mínima (faixa provisória, à espera do dono): 40% da do v1 e 15% da grade
			assert_float(float(build_v2)).override_failure_message(report[report.size() - 1]).is_greater(build_v1 * 0.4)
			assert_float(float(build_v2) / (grid.size.x * grid.size.y)).is_greater(0.15)
			# a borda da grade é mar
			for x: int in grid.size.x:
				assert_int(grid.ground_at(Vector2i(x, 0))).is_equal(IslandGrid.Ground.SEA)
	print("Fase 45:\n" + "\n".join(report))


## Lotes de casa (3 × 3) válidos pelas regras da simulação na ilha, a cada 3 células.
static func house_lots(grid: IslandGrid, data: GameData) -> int:
	var def := data.building(&"house")
	var count := 0
	for y: int in range(0, grid.size.y - 2, 3):
		for x: int in range(0, grid.size.x - 2, 3):
			if PlacementRules.check_building(grid, def, Vector2i(x, y), 0) == PlacementRules.OK \
					and PlacementRules.check_terrain(grid, null, def, Vector2i(x, y), 0) == PlacementRules.OK:
				count += 1
	return count


## O que o jogador-robô precisaria do terreno (ele joga numa ilha plana, então a comparação é pelas regras): lotes de
## casa, jazidas e lugar para o entreposto, v1 contra v2, nas sementes de referência.
func test_the_metrics_the_robot_depends_on_stay_in_range() -> void:
	var report := PackedStringArray()
	for seed_value: int in SEEDS:
		var v1 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 1)
		var v2 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 2)
		var lots_v1 := house_lots(v1.islands[0], _data)
		var lots_v2 := house_lots(v2.islands[0], _data)
		var deposits_v1 := v1.islands[0].deposits.size() - v1.islands[0].deposits.count(0)
		var deposits_v2 := v2.islands[0].deposits.size() - v2.islands[0].deposits.count(0)
		report.append("semente %d, ilha principal: lotes de casa %d → %d (%.0f%%); células de jazida %d → %d" % [seed_value,
				lots_v1, lots_v2, 100.0 * lots_v2 / maxi(lots_v1, 1), deposits_v1, deposits_v2])
		assert_float(float(lots_v2)).override_failure_message(report[report.size() - 1]).is_greater(lots_v1 * 0.4)
		# onde o v1 tem jazida, o v2 também tem
		for index: int in v2.islands.size():
			var old := v1.islands[index]
			var grid := v2.islands[index]
			if old.deposits.size() - old.deposits.count(0) > 0:
				assert_int(grid.deposits.size() - grid.deposits.count(0)).override_failure_message(
						"semente %d ilha %d sem jazida" % [seed_value, index]).is_greater(0)
	print("Fase 45 (métricas do robô):\n" + "\n".join(report))


func test_the_trading_post_finds_a_coast_on_every_v2_main_island() -> void:
	for seed_value: int in SEEDS:
		var sim := Simulation.new(_config, _data, ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 2))
		var found: Array = SiteFinder.find(sim, &"trading_post", 0, sim.world.island(0).size / 2)
		assert_bool(found.is_empty()).override_failure_message("semente %d" % seed_value).is_false()


func test_saves_rebuild_the_terrain_of_the_version_they_wrote() -> void:
	for version: int in [1, 2]:
		var world := ArchipelagoGenerator.new_world(1840, _config, _data, -1, -1, version)
		var loaded := WorldState.from_dict(world.to_dict(), _data, _config)
		assert_object(loaded).is_not_null()
		assert_int(loaded.terrain_version).is_equal(version)
		assert_that(_fingerprints(loaded)).is_equal(_fingerprints(world))
	# versão que este jogo não conhece: recusado
	var future := ArchipelagoGenerator.new_world(1840, _config, _data).to_dict()
	future["terrain_version"] = 3
	assert_object(WorldState.from_dict(future, _data, _config)).is_null()


func test_generating_v2_costs_about_the_same_as_v1() -> void:
	var config := GameConfig.get_default()
	var times: Array[int] = []
	for version: int in [1, 2]:
		var started := Time.get_ticks_msec()
		ArchipelagoGenerator.new_world(1840, config, _data, -1, -1, version)
		times.append(Time.get_ticks_msec() - started)
	print("Fase 45: arquipélago padrão da semente 1840 em série: v1 %d ms, v2 %d ms" % [times[0], times[1]])
	assert_int(times[1]).is_less(times[0] * 3)


func test_the_threaded_job_and_the_preview_follow_the_version() -> void:
	var job := ArchipelagoJob.new(5, _config, _data, -1, -1, 2)
	job.start(false)
	assert_int(job.result().terrain_version).is_equal(2)
	assert_that(_fingerprints(job.result())).is_equal(_fingerprints(ArchipelagoGenerator.new_world(5, _config, _data, -1, -1, 2)))
	var preview := ArchipelagoPreview.new(5, 0, _config, _data, ArchipelagoPreview.SCALE, 2)
	preview.start(false)
	assert_int(preview.world().terrain_version).is_equal(2)
