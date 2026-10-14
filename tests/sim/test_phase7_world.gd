extends GdUnitTestSuite
## Fase 7 na simulação: o tamanho do arquipélago e a dificuldade do jogo novo, o histórico das
## estatísticas (amostras, teto, save) e a migração do save da Fase 6.


## Arquipélago pequeno nos três tamanhos: gerado em uma fração do tempo.
func _small_config() -> GameConfig:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60, 30, 30, 20, 20, 30, 20, 30, 20])
	return config


func test_archipelago_sizes_have_four_six_and_eight_smaller_islands() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	for size_index: int in 3:
		var world := ArchipelagoGenerator.new_world(5, config, data, size_index)
		assert_int(world.islands.size()).is_equal([5, 7, 9][size_index])
		assert_int(world.economies.size()).is_equal(world.islands.size())


func test_a_bigger_archipelago_keeps_the_islands_of_the_smaller_one() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var small := ArchipelagoGenerator.new_world(5, config, data, 0)
	var large := ArchipelagoGenerator.new_world(5, config, data, 2)
	for index: int in small.islands.size():
		assert_int(large.island(index).fingerprint).is_equal(small.island(index).fingerprint)
		assert_vector(large.island(index).origin_m).is_equal(small.island(index).origin_m)


func test_the_save_rebuilds_the_archipelago_with_its_own_number_of_islands() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(9, config, data, 1)
	var back := WorldState.from_dict(world.to_dict(), data, config)
	assert_object(back).is_not_null()
	assert_int(back.islands.size()).is_equal(7)
	for index: int in world.islands.size():
		assert_int(back.island(index).fingerprint).is_equal(world.island(index).fingerprint)


func test_difficulty_sets_the_starting_money_and_the_debt_limit() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var easy := ArchipelagoGenerator.new_world(5, config, data, 0, 0)
	var normal := ArchipelagoGenerator.new_world(5, config, data, 0, 1)
	var hard := ArchipelagoGenerator.new_world(5, config, data, 0, 2)
	assert_float(normal.money).is_equal(50000.0)
	assert_float(easy.money).is_equal(100000.0)
	assert_float(hard.money).is_equal(25000.0)
	assert_float(config.min_balance_for(normal.difficulty)).is_equal(-10000.0)
	assert_float(config.min_balance_for(hard.difficulty)).is_equal(-5000.0)
	assert_int(WorldState.from_dict(hard.to_dict(), data, config).difficulty).is_equal(2)


func test_hard_difficulty_blocks_building_sooner() -> void:
	var sim := SimFixture.simulation()
	sim.free_build = false
	sim.world.difficulty = 2
	sim.world.money = -4900.0
	var def := sim.data.building(&"house")
	assert_str(PlacementRules.check_cost(sim.world, sim.world.economy(0), sim.config, 200, def.cost_materials)).is_equal(PlacementRules.NO_MONEY)
	sim.world.difficulty = 1
	assert_str(PlacementRules.check_cost(sim.world, sim.world.economy(0), sim.config, 200, {})).is_equal(PlacementRules.OK)


func test_history_takes_one_sample_per_interval_with_production_and_population() -> void:
	var sim := SimFixture.simulation()
	SimFixture.road(sim, Vector2i(2, 10), Vector2i(60, 10))
	SimFixture.place(sim, &"lumberjack", Vector2i(10, 6), 0)
	SimFixture.house(sim, 30, 10, &"peasants", 8.0)
	var every := roundi(sim.config.history_interval_s * sim.config.ticks_per_second)
	sim.run_ticks(every * 3)
	var history := sim.world.history
	assert_int(history.size()).is_equal(3)
	assert_array(Array(history.ticks)).is_equal([every, every * 2, every * 3])
	assert_float(history.population[&"peasants"][2]).is_greater(0.0)
	assert_bool(history.produced.has(StatisticsHistory.key(0, &"wood"))).is_true()
	assert_int(history.good_series(0, &"wood", true).size()).is_equal(3)
	assert_int(history.good_series(-1, &"wood", true).size()).is_equal(3)


func test_history_keeps_only_the_last_samples() -> void:
	var sim := SimFixture.simulation()
	sim.config.history_samples = 4
	sim.config.history_interval_s = 1.0
	sim.run_ticks(sim.config.ticks_per_second * 10)
	assert_int(sim.world.history.size()).is_equal(4)
	assert_int(sim.world.history.ticks[3]).is_equal(sim.config.ticks_per_second * 10)
	for series: PackedFloat32Array in sim.world.history.population.values():
		assert_int(series.size()).is_equal(4)


func test_history_survives_save_and_load() -> void:
	var sim := SimFixture.simulation()
	SimFixture.road(sim, Vector2i(2, 10), Vector2i(60, 10))
	SimFixture.place(sim, &"lumberjack", Vector2i(10, 6), 0)
	sim.run_ticks(roundi(sim.config.history_interval_s * sim.config.ticks_per_second) * 2)
	var saved := sim.world.to_dict()
	var packed: Variant = JSON.to_native(JSON.parse_string(JSON.stringify(JSON.from_native(SaveSystem.pack_floats(saved)))))
	var data: Dictionary = SaveSystem.unpack_floats(packed)
	var back := WorldState.from_dict(data, sim.data, sim.config)
	assert_object(back).is_not_null()
	assert_bool(back.history.to_dict() == sim.world.history.to_dict()).is_true()


func test_a_tampered_history_refuses_the_save() -> void:
	var sim := SimFixture.simulation()
	sim.run_ticks(roundi(sim.config.history_interval_s * sim.config.ticks_per_second))
	var saved := sim.world.to_dict()
	var history: Dictionary = saved["history"]
	history["money"] = PackedFloat32Array([1.0, 2.0, 3.0])
	assert_object(WorldState.from_dict(saved, sim.data, sim.config)).is_null()


func test_phase_six_save_opens_with_normal_difficulty_and_an_empty_history() -> void:
	var sim := SimFixture.simulation()
	var saved := sim.world.to_dict()
	saved.erase("difficulty")
	saved.erase("history")
	var migrated := SaveMigrations.from_5_to_6({"world": saved})
	var world_data: Dictionary = migrated["world"]
	var back := WorldState.from_dict(world_data, sim.data, sim.config)
	assert_object(back).is_not_null()
	assert_int(back.difficulty).is_equal(1)
	assert_int(back.history.size()).is_equal(0)
