extends GdUnitTestSuite
## Critério da Fase 5 (seção 16): 1 ilha grande e 4 menores saem sempre iguais para a mesma
## semente; a principal tem lugar para o jogo base (litoral do entreposto, jazidas, rio, floresta).

const SEED := 1840

static var _world: WorldState


func before() -> void:
	_world = ArchipelagoGenerator.new_world(SEED, GameConfig.get_default(), GameData.get_default())


## Arquipélago pequeno: as mesmas regras, gerado em uma fração do tempo.
func _small_config() -> GameConfig:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40, 30])
	return config


func test_same_seed_same_archipelago_and_another_seed_another() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var first := ArchipelagoGenerator.new_world(7, config, data)
	var again := ArchipelagoGenerator.new_world(7, config, data)
	var other := ArchipelagoGenerator.new_world(8, config, data)
	var differs := false
	for index: int in first.islands.size():
		assert_int(again.island(index).fingerprint).is_equal(first.island(index).fingerprint)
		assert_vector(again.island(index).origin_m).is_equal(first.island(index).origin_m)
		differs = differs or other.island(index).fingerprint != first.island(index).fingerprint
	assert_bool(differs).is_true()


func test_one_large_and_four_smaller_islands_each_in_its_own_region() -> void:
	var config := GameConfig.get_default()
	assert_int(_world.islands.size()).is_equal(5)
	var sizes: Array[int] = []
	var regions: Array[Vector2i] = []
	for index: int in _world.islands.size():
		var grid := _world.island(index)
		sizes.append(grid.size.x)
		var rect := grid.world_rect()
		var region := Vector2i(floori(rect.position.x / config.terrain_region_m), floori(rect.position.y / config.terrain_region_m))
		assert_bool(Rect2(Vector2(region) * config.terrain_region_m, Vector2.ONE * config.terrain_region_m).encloses(rect)).is_true()
		assert_bool(regions.has(region)).is_false()
		regions.append(region)
	assert_array(sizes).is_equal([250, 150, 150, 80, 80])
	assert_str(_world.economy(0).profile_id).is_equal("main_island")
	var profiles: Array[StringName] = []
	for index: int in range(1, 5):
		assert_bool(profiles.has(_world.economy(index).profile_id)).is_false()
		profiles.append(_world.economy(index).profile_id)


## O litoral fica sempre dentro da grade: o terreno desenhado conta com isso e põe o fundo do mar
## fora dela sem refazer a conta do relevo.
func test_outside_the_grid_is_always_sea_floor() -> void:
	var config := GameConfig.get_default()
	var specs := ArchipelagoGenerator.layout(SEED, config, GameData.get_default())
	for index: int in _world.islands.size():
		var spec: ArchipelagoGenerator.IslandSpec = specs[index]
		var noises := ArchipelagoGenerator.Noises.new(spec.seed_value)
		var rect := _world.island(index).world_rect()
		for k: int in 400:
			var t := k / 400.0
			for gap: float in [0.5, 30.0]:
				for point: Vector2 in [Vector2(rect.position.x + rect.size.x * t, rect.position.y - gap),
						Vector2(rect.position.x + rect.size.x * t, rect.end.y + gap),
						Vector2(rect.position.x - gap, rect.position.y + rect.size.y * t),
						Vector2(rect.end.x + gap, rect.position.y + rect.size.y * t)]:
					assert_float(ArchipelagoGenerator.height_at(spec, noises, config, point.x, point.y)).is_equal_approx(config.sea_floor_m, 0.001)


func test_main_island_has_room_for_the_base_game() -> void:
	var grid := _world.island(0)
	var land := grid.ground.count(IslandGrid.Ground.LAND)
	assert_float(land / float(grid.ground.size())).is_greater(0.5)
	var flat := 0
	for i: int in grid.ground.size():
		if grid.ground[i] == IslandGrid.Ground.LAND and grid.area_relief(Rect2i(grid.cell_at(i), Vector2i.ONE)) <= 0.5:
			flat += 1
	assert_float(flat / float(land)).is_greater(0.6)
	assert_int(grid.ground.count(IslandGrid.Ground.RIVER)).is_greater(20)
	var forest := 0
	for value: int in grid.trees:
		forest += int(value > 0)
	assert_float(forest / float(land)).is_between(0.25, 0.36)
	var sim := Simulation.new(GameConfig.get_default(), GameData.get_default(), _world)
	for def_id: StringName in [&"trading_post", &"fishery", &"coal_mine", &"iron_mine", &"clay_pit", &"potato_farm", &"wheat_farm", &"hop_farm"]:
		assert_array(SiteFinder.find(sim, def_id, 0, grid.size / 2, 130)).override_failure_message("sem lugar para %s" % def_id).is_not_empty()


func test_terraces_are_flat_and_slopes_are_not() -> void:
	var levels := GameConfig.get_default().terrace_levels_m
	assert_float(ArchipelagoGenerator.terrace(0.3, levels, 0.7)).is_equal(levels[0])
	assert_float(ArchipelagoGenerator.terrace(levels[1] + 0.5, levels, 0.7)).is_equal(levels[1])
	var middle := ArchipelagoGenerator.terrace(lerpf(levels[1], levels[2], 0.9), levels, 0.7)
	assert_bool(middle > levels[1] and middle < levels[2]).is_true()


func test_river_banks_stay_flat_for_the_clay_pit() -> void:
	var grid := _world.island(0)
	var found := false
	for i: int in grid.ground.size():
		if grid.ground[i] != IslandGrid.Ground.RIVER:
			continue
		var cell := grid.cell_at(i)
		for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var bank := cell + side
			if grid.is_land(bank) and grid.area_relief(Rect2i(bank, Vector2i.ONE)) <= 0.5:
				found = true
	assert_bool(found).is_true()


func test_save_rebuilds_the_terrain_from_the_seed_and_keeps_what_construction_changed() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var sim := Simulation.new(config, data, ArchipelagoGenerator.new_world(11, config, data))
	sim.free_build = true
	var grid := sim.world.island(0)
	var forest := -1
	for i: int in grid.trees.size():
		if grid.trees[i] > 0 and grid.area_relief(Rect2i(grid.cell_at(i), Vector2i.ONE)) <= 2.0:
			forest = i
			break
	assert_int(forest).is_greater_equal(0)
	var road: Array[Vector2i] = [grid.cell_at(forest)]
	assert_bool(sim.execute(BuildRoadCommand.new(0, road)).ok()).is_true()
	assert_int(grid.trees[forest]).is_equal(0)
	var saved_dict: Dictionary = SaveSystem.unpack_floats(SaveSystem.pack_floats(sim.world.to_dict()))
	var restored := WorldState.from_dict(saved_dict, data, config)
	assert_object(restored).is_not_null()
	assert_bool(restored.terrain_mismatch).is_false()
	for index: int in sim.world.islands.size():
		assert_bool(restored.island(index).corner_heights == sim.world.island(index).corner_heights).is_true()
		assert_bool(restored.island(index).trees == sim.world.island(index).trees).is_true()
	assert_bool(restored.island(0).has_road(grid.cell_at(forest))).is_true()


func test_a_different_terrain_on_load_is_flagged_not_refused() -> void:
	var config := _small_config()
	var world := ArchipelagoGenerator.new_world(3, config, GameData.get_default())
	var data := world.to_dict()
	var islands: Array = data["islands"]
	var first: Dictionary = islands[0]
	first["fingerprint"] = 12345
	var restored := WorldState.from_dict(data, GameData.get_default(), config)
	assert_object(restored).is_not_null()
	assert_bool(restored.terrain_mismatch).is_true()


func test_phase_four_save_stays_on_the_flat_island() -> void:
	var phase_four := {"world": {
		"islands": [{"size": Vector2i(60, 30), "roads": PackedInt32Array([65, 66]),
			"economy": {"profile": &"test_island", "stock": {}, "category_supply": {}, "good_supply": {}, "shortage_announced": {}}}],
		"buildings": [], "next_building_id": 1, "money": 1000.0, "tax_levels": {}, "tick": 0, "carts": [],
	}}
	var world_data: Dictionary = SaveMigrations.from_3_to_4(phase_four)["world"]
	var world := WorldState.from_dict(world_data, GameData.get_default())
	assert_object(world).is_not_null()
	assert_int(world.terrain_version).is_equal(0)
	assert_bool(world.island(0).flat).is_true()
	assert_int(world.island(0).road_cells().size()).is_equal(2)
