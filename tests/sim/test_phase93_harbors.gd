extends GdUnitTestSuite
## Porto em toda ilha (Fase 93): no terreno v4 toda ilha tem lugar de entreposto pelas regras do jogo (o v3 deixava ilhas
## pequenas sem nenhum, e elas não podiam ser colonizadas); a ilha que já tinha lugar sai igual à do v3; o jogo novo usa
## o v4 e os saves do v3 seguem abrindo o v3.

const SEEDS: Array[int] = [1840, 1, 8, 20, 26, 28]


func _site(world: WorldState, island: int) -> Array:
	var sim := Simulation.new(GameConfig.get_default(), GameData.get_default(), world)
	var grid := world.island(island)
	return SiteFinder.find(sim, &"trading_post", island, Vector2i(grid.size.x / 2, 0), 400)


func test_every_v4_island_has_a_trading_post_site() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	for seed_value: int in SEEDS:
		var world := ArchipelagoGenerator.new_world(seed_value, config, data, -1, -1, ArchipelagoGenerator.VERSION_V4)
		for island: int in world.islands.size():
			assert_array(_site(world, island)).override_failure_message("semente %d, ilha %d sem lugar de entreposto" % [
					seed_value, island]).is_not_empty()


func test_the_site_passes_the_real_placement_rules() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data, -1, -1, ArchipelagoGenerator.VERSION_V4)
	var sim := Simulation.new(config, data, world)
	sim.free_build = true
	# as duas ilhas que o v3 deixava sem lugar
	for island: int in [3, 4]:
		var site := _site(world, island)
		var origin: Vector2i = site[0]
		var rotation: int = site[1]
		var result := sim.execute(PlaceBuildingCommand.new(island, &"trading_post", origin, rotation))
		assert_bool(result.ok()).override_failure_message("ilha %d: %s" % [island, result.reason]).is_true()


func test_islands_that_had_a_harbor_stay_as_in_v3() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	for seed_value: int in [1840, 3]:
		var v3 := ArchipelagoGenerator.new_world(seed_value, config, data, -1, -1, ArchipelagoGenerator.VERSION_V3)
		var v4 := ArchipelagoGenerator.new_world(seed_value, config, data, -1, -1, ArchipelagoGenerator.VERSION_V4)
		for island: int in v3.islands.size():
			var had := ArchipelagoGenerator.harbor_site(v3.island(island), config) != ArchipelagoGenerator.NO_HARBOR
			var same := v3.island(island).fingerprint == v4.island(island).fingerprint
			assert_bool(same).override_failure_message("semente %d, ilha %d" % [seed_value, island]).is_equal(had)


func test_the_harbor_is_as_big_as_the_trading_post() -> void:
	var size := GameData.get_default().building(&"trading_post").size
	assert_int(ArchipelagoGenerator.HARBOR_CELLS).is_equal(maxi(size.x, size.y))
	assert_int(size.x).is_equal(size.y)


func test_new_games_use_v4_and_old_saves_keep_v3() -> void:
	assert_int(GameConfig.get_default().new_game_terrain_version).is_equal(ArchipelagoGenerator.VERSION_V4)
	assert_array(ArchipelagoGenerator.VERSIONS).contains([ArchipelagoGenerator.VERSION_V3, ArchipelagoGenerator.VERSION_V4])
	# um mundo v3 continua v3 depois de salvar e abrir
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(7, config, data, -1, -1, ArchipelagoGenerator.VERSION_V3)
	var loaded := WorldState.from_dict(world.to_dict(), data, config)
	assert_object(loaded).is_not_null()
	assert_int(loaded.terrain_version).is_equal(ArchipelagoGenerator.VERSION_V3)
	assert_bool(loaded.terrain_mismatch).is_false()
