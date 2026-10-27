extends GdUnitTestSuite
## Ilhas v3 (Fase 52, a pedido do dono olhando o Anno 1800): alongadas, com enseadas de praia baixa, falésias altas no
## resto da costa e rochedos soltos; determinísticas por semente, com terra para construir, lugar para o entreposto,
## salvam e carregam na versão 3, e a plataforma desenhada acompanha a costa.

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


## Quanto a terra é mais comprida que larga: a raiz da razão entre os autovalores da covariância das células de terra.
static func elongation(grid: IslandGrid) -> float:
	var count := 0
	var mean := Vector2.ZERO
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			if grid.ground_at(Vector2i(x, y)) != IslandGrid.Ground.SEA:
				mean += Vector2(x, y)
				count += 1
	mean /= maxi(count, 1)
	var xx := 0.0
	var yy := 0.0
	var xy := 0.0
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			if grid.ground_at(Vector2i(x, y)) != IslandGrid.Ground.SEA:
				var d := Vector2(x, y) - mean
				xx += d.x * d.x
				yy += d.y * d.y
				xy += d.x * d.y
	var half_trace := (xx + yy) * 0.5
	var spread := sqrt(maxf(half_trace * half_trace - (xx * yy - xy * xy), 0.0))
	return sqrt((half_trace + spread) / maxf(half_trace - spread, 0.0001))


## Pedaços de terra separados (4-vizinhança): a ilha e os rochedos.
static func land_pieces(grid: IslandGrid) -> int:
	var seen := PackedByteArray()
	seen.resize(grid.size.x * grid.size.y)
	var pieces := 0
	for start: int in seen.size():
		if seen[start] == 1 or grid.ground[start] == IslandGrid.Ground.SEA:
			continue
		pieces += 1
		var stack: Array[int] = [start]
		seen[start] = 1
		while not stack.is_empty():
			var i: int = stack.pop_back()
			var x := i % grid.size.x
			for next: int in [i - 1 if x > 0 else -1, i + 1 if x < grid.size.x - 1 else -1, i - grid.size.x, i + grid.size.x]:
				if next >= 0 and next < seen.size() and seen[next] == 0 and grid.ground[next] != IslandGrid.Ground.SEA:
					seen[next] = 1
					stack.append(next)
	return pieces


func test_v3_is_deterministic_and_independent_of_call_order() -> void:
	for seed_value: int in SEEDS:
		var a := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 3)
		var b := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 3)
		assert_int(a.terrain_version).is_equal(3)
		assert_that(_fingerprints(a)).is_equal(_fingerprints(b))
		var specs := ArchipelagoGenerator.layout(seed_value, _config, _data, 3)
		assert_int(ArchipelagoGenerator.build_island(specs[2], _config, 3).fingerprint).is_equal(a.islands[2].fingerprint)
		var v2 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 2)
		assert_int(v2.islands[0].fingerprint).is_not_equal(a.islands[0].fingerprint)
	assert_array(Array(TerrainV3Params.get_v3().validate())).is_empty()


func test_v3_islands_are_elongated_with_coves_and_sea_stacks() -> void:
	var params := TerrainV3Params.get_v3()
	var report := PackedStringArray()
	var stretched := 0
	var islands := 0
	var with_stacks := 0
	for seed_value: int in SEEDS:
		var world := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 3)
		var v2 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 2)
		var specs := ArchipelagoGenerator.world_specs(world, _config, _data)
		for index: int in world.islands.size():
			var grid := world.islands[index]
			var shape := ArchipelagoGenerator.shape_v3(specs[index], params)
			var long_v3 := elongation(grid)
			report.append("semente %d ilha %d: alongamento %.2f (v2 %.2f), enseadas %d, pedaços de terra %d" % [seed_value,
					index, long_v3, elongation(v2.islands[index]), shape.bays.size(), land_pieces(grid)])
			islands += 1
			if long_v3 > 1.3:
				stretched += 1
			if land_pieces(grid) > 1:
				with_stacks += 1
			# toda ilha tem enseada
			assert_int(shape.bays.size()).override_failure_message(report[report.size() - 1]).is_greater(0)
	print("Fase 52:\n" + "\n".join(report))
	# a maioria é bem mais comprida que larga, e os rochedos aparecem soltos na maioria
	assert_float(float(stretched) / islands).is_greater(0.6)
	assert_float(float(with_stacks) / islands).is_greater(0.5)


func test_cove_beaches_are_low_and_the_rest_of_the_coast_is_cliff() -> void:
	var params := TerrainV3Params.get_v3()
	var cliff_level := params.terrace_levels_m[params.cliff_plain_level] - 0.6
	for seed_value: int in SEEDS:
		var world := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 3)
		var grid := world.islands[0]
		var coastal := 0
		var high := 0
		var near := ArchipelagoGenerator.near_sea(grid, 1)
		for i: int in grid.ground.size():
			if grid.ground[i] != IslandGrid.Ground.LAND or near[i] == 0:
				continue
			# a célula logo atrás da beira: a altura da planície do litoral
			var cell := grid.cell_at(i)
			coastal += 1
			if grid.cell_height(cell) >= cliff_level:
				high += 1
		var share := float(high) / maxi(coastal, 1)
		print("Fase 52: semente %d, costa alta (falésia) %.0f%%" % [seed_value, share * 100.0])
		# há praia e há falésia
		assert_float(share).override_failure_message("semente %d: %.2f" % [seed_value, share]).is_between(0.1, 0.9)


func test_v3_keeps_building_land_and_room_for_the_trading_post() -> void:
	var suite := load("res://tests/sim/test_phase45_terrain_v2.gd") as GDScript
	var total_v1 := 0
	var total_v3 := 0
	for seed_value: int in SEEDS:
		var v1 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 1)
		var v3 := ArchipelagoGenerator.new_world(seed_value, _config, _data, -1, -1, 3)
		var lots_v1: int = suite.call(&"house_lots", v1.islands[0], _data)
		var lots_v3: int = suite.call(&"house_lots", v3.islands[0], _data)
		print("Fase 52: semente %d, lotes de casa na principal %d → %d" % [seed_value, lots_v1, lots_v3])
		# menos terra que o v1 (enseadas e falésias comem a borda; faixa provisória, à espera do dono): cada principal com
		# pelo menos um quarto dos lotes, e as quatro juntas com 45%
		assert_float(float(lots_v3)).is_greater(lots_v1 * 0.25)
		total_v1 += lots_v1
		total_v3 += lots_v3
		for index: int in v3.islands.size():
			var old := v1.islands[index]
			if old.deposits.size() - old.deposits.count(0) > 0:
				var grid := v3.islands[index]
				assert_int(grid.deposits.size() - grid.deposits.count(0)).override_failure_message(
						"semente %d ilha %d sem jazida" % [seed_value, index]).is_greater(0)
		var sim := Simulation.new(_config, _data, v3)
		var found: Array = SiteFinder.find(sim, &"trading_post", 0, sim.world.island(0).size / 2)
		assert_bool(found.is_empty()).override_failure_message("semente %d sem entreposto" % seed_value).is_false()
	assert_float(float(total_v3)).is_greater(total_v1 * 0.45)


func test_saves_rebuild_v3() -> void:
	var world := ArchipelagoGenerator.new_world(1840, _config, _data, -1, -1, 3)
	var loaded := WorldState.from_dict(world.to_dict(), _data, _config)
	assert_object(loaded).is_not_null()
	assert_int(loaded.terrain_version).is_equal(3)
	assert_that(_fingerprints(loaded)).is_equal(_fingerprints(world))


func test_the_drawn_shelf_follows_the_real_coast() -> void:
	var world := ArchipelagoGenerator.new_world(1840, _config, _data, -1, -1, 3)
	var region := ArchipelagoGenerator.region_corners(world, 0, _config, _data)
	var side: int = region["side"]
	var heights: PackedFloat32Array = region["heights"]
	var grid := world.islands[0]
	var origin: Vector2 = region["origin"]
	var first := Vector2i(roundi((grid.origin_m.x - origin.x) / _config.cell_size_m), roundi((grid.origin_m.y - origin.y) / _config.cell_size_m))
	# junto à costa (a uma célula do mar) o fundo é raso; longe da ilha, fundo
	var near := ArchipelagoGenerator.near_sea(grid, 1)
	var shallow := 0
	var checked := 0
	for i: int in grid.ground.size():
		if grid.ground[i] != IslandGrid.Ground.SEA:
			continue
		var cell := grid.cell_at(i)
		var touches := false
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if grid.is_land(cell + step):
				touches = true
		if not touches:
			continue
		checked += 1
		if heights[(cell.y + first.y) * side + cell.x + first.x] > _config.sea_floor_m - 3.0:
			shallow += 1
	assert_float(float(shallow) / maxi(checked, 1)).is_greater(0.9)
	assert_float(heights[0]).is_equal_approx(_config.deep_sea_floor_m, 0.5)
	assert_int(near.size()).is_equal(grid.ground.size())


func test_generating_v3_costs_about_the_same_as_v1() -> void:
	var config := GameConfig.get_default()
	var times: Array[int] = []
	for version: int in [1, 3]:
		var started := Time.get_ticks_msec()
		ArchipelagoGenerator.new_world(1840, config, _data, -1, -1, version)
		times.append(Time.get_ticks_msec() - started)
	print("Fase 52: arquipélago padrão da semente 1840 em série: v1 %d ms, v3 %d ms" % [times[0], times[1]])
	assert_int(times[1]).is_less(times[0] * 3)


func test_the_new_game_dialog_offers_the_coves() -> void:
	assert_int(NewGameDialog.TERRAIN_KEYS.size()).is_equal(ArchipelagoGenerator.VERSIONS.size())
	assert_str(NewGameDialog.TERRAIN_KEYS[ArchipelagoGenerator.VERSION_V3 - 1]).is_equal("NEW_GAME_TERRAIN_COVES")
