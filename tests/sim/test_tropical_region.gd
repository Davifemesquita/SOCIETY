extends GdUnitTestSuite
## Segunda região climática (Fase 11): ilhas tropicais a leste, geradas à parte das temperadas (que
## não mudam), no save desde a versão 8 (a migração as acrescenta), colonizáveis só no marco
## tropical, com cana, café, tabaco e ouro que só crescem lá e chegam às fábricas pelas rotas.

const SEED := 1840


## Arquipélago pequeno: as mesmas regras, gerado em uma fração do tempo.
func _small_config() -> GameConfig:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60, 30, 30, 20, 20, 30, 20, 30, 20])
	config.tropical_island_sizes_cells = PackedInt32Array([40, 30, 30])
	return config


func test_tropical_islands_come_after_the_temperate_ones_in_their_own_regions() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(SEED, config, data)
	var temperate := config.island_count_for(config.default_archipelago_size)
	assert_int(world.islands.size()).is_equal(temperate + 3)
	var specs := ArchipelagoGenerator.layout(SEED, config, data, temperate)
	for index: int in world.islands.size():
		if index < temperate:
			assert_bool(world.is_tropical(index, data)).is_false()
			# as temperadas são as mesmas de antes da Fase 11 (o gerador delas não mudou)
			var alone := ArchipelagoGenerator.build_island(specs[index], config)
			assert_int(world.island(index).fingerprint).is_equal(alone.fingerprint)
			continue
		assert_bool(world.is_tropical(index, data)).is_true()
		var rect := world.island(index).world_rect()
		var region := Vector2i(floori(rect.position.x / config.terrain_region_m), floori(rect.position.y / config.terrain_region_m))
		assert_bool(config.tropical_regions.has(region)).is_true()
		assert_bool(Rect2(Vector2(region) * config.terrain_region_m, Vector2.ONE * config.terrain_region_m).encloses(rect)).is_true()
	var again := ArchipelagoGenerator.new_world(SEED, config, data)
	for index: int in world.islands.size():
		assert_int(again.island(index).fingerprint).is_equal(world.island(index).fingerprint)


func test_tropical_islands_are_the_same_in_every_archipelago_size() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var small := ArchipelagoGenerator.new_world(5, config, data, 0)
	var large := ArchipelagoGenerator.new_world(5, config, data, 2)
	for number: int in 3:
		var a := small.island(small.islands.size() - 3 + number)
		var b := large.island(large.islands.size() - 3 + number)
		assert_int(b.fingerprint).is_equal(a.fingerprint)
		assert_vector(b.origin_m).is_equal(a.origin_m)


## A ilha de café tem a jazida de ouro, e só ilha tropical tem cana, café, tabaco ou ouro.
func test_gold_deposit_and_tropical_crops_only_on_tropical_islands() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(SEED, config, data)
	var gold := 0
	for index: int in world.islands.size():
		var grid := world.island(index)
		var profile := data.profile(world.economy(index).profile_id)
		if grid.deposit_goods.has(&"gold"):
			assert_bool(profile.is_tropical()).is_true()
			for i: int in grid.deposits.size():
				if grid.deposits[i] > 0 and grid.deposit_goods[grid.deposits[i] - 1] == &"gold":
					gold += 1
		if not profile.is_tropical():
			for good: StringName in [&"sugar", &"coffee_beans", &"tobacco"]:
				assert_bool(profile.fertilities.has(good)).is_false()
	assert_int(gold).is_greater(0)


func test_save_rebuilds_the_tropical_islands_and_refuses_them_out_of_order() -> void:
	var config := _small_config()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(9, config, data, 1)
	var saved := world.to_dict()
	var back := WorldState.from_dict(saved, data, config)
	assert_object(back).is_not_null()
	assert_int(back.islands.size()).is_equal(world.islands.size())
	for index: int in world.islands.size():
		assert_int(back.island(index).fingerprint).is_equal(world.island(index).fingerprint)
		assert_str(back.economy(index).profile_id).is_equal(world.economy(index).profile_id)
	# uma tropical no meio das temperadas: o save é recusado inteiro
	var islands: Array = saved["islands"]
	var first: Variant = islands[1]
	islands[1] = islands[islands.size() - 1]
	islands[islands.size() - 1] = first
	assert_object(WorldState.from_dict(saved, data, config)).is_null()


## Save da Fase 10 (versão 7): o arquipélago ganha as ilhas tropicais da semente, virgens; a ilha
## plana antiga fica como estava.
func test_migration_adds_the_tropical_islands_to_generated_worlds_only() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var temperate := ArchipelagoGenerator.layout(SEED, config, data, 2)
	var islands: Array = []
	for spec: ArchipelagoGenerator.IslandSpec in temperate:
		var economy := IslandEconomy.new()
		economy.profile_id = spec.profile.id
		islands.append({"size": Vector2i(spec.size, spec.size), "economy": economy.to_dict()})
	var state := {"world": {"seed": SEED, "terrain_version": ArchipelagoGenerator.VERSION, "islands": islands}}
	var migrated := SaveMigrations.from_7_to_8(state)
	var world: Dictionary = migrated["world"]
	var after: Array = world["islands"]
	assert_int(after.size()).is_equal(2 + config.tropical_island_sizes_cells.size())
	var expected := ArchipelagoGenerator.tropical_layout(SEED, config, data, 2)
	for number: int in expected.size():
		var island: Dictionary = after[2 + number]
		var economy: Dictionary = island["economy"]
		assert_str(economy["profile"]).is_equal(expected[number].profile.id)
		assert_that(island["size"]).is_equal(Vector2i(expected[number].size, expected[number].size))
		var roads: PackedInt32Array = island["roads"]
		assert_int(roads.size()).is_equal(0)
	assert_int(WorldState.tropical_count(after, data)).is_equal(expected.size())
	var flat := {"world": {"seed": 0, "terrain_version": 0, "islands": [{"size": Vector2i(40, 40)}]}}
	var flat_world: Dictionary = SaveMigrations.from_7_to_8(flat)["world"]
	var flat_islands: Array = flat_world["islands"]
	assert_int(flat_islands.size()).is_equal(1)
	assert_int(SaveSystem.SAVE_VERSION).is_greater_equal(8)


func test_tropical_colony_waits_for_the_tropical_milestone() -> void:
	var sim := _tropical_pair()
	var post := sim.data.building(&"trading_post")
	sim.free_build = false
	sim.execute(DemolishCommand.new(1, Rect2i(0, 0, 6, 6)))
	sim.world.milestones_reached = sim.config.tropical_milestone - 1
	assert_str(sim.placement_reason(post, Vector2i(0, 0), 2, 1)).is_equal(PlacementRules.TROPICAL_LOCKED)
	sim.world.milestones_reached = sim.config.tropical_milestone
	assert_str(sim.placement_reason(post, Vector2i(0, 0), 2, 1)).is_equal(PlacementRules.NEEDS_SHIP)
	# a ilha temperada não pede o marco tropical
	sim.world.economy(1).profile_id = &"test_island"
	sim.world.milestones_reached = 1
	assert_str(sim.placement_reason(post, Vector2i(0, 0), 2, 1)).is_equal(PlacementRules.NEEDS_SHIP)


func test_tropical_crops_grow_only_on_tropical_islands() -> void:
	var sim := _tropical_pair()
	var farm := sim.data.building(&"sugar_cane_farm")
	assert_str(sim.placement_reason(farm, Vector2i(10, 7), 0, 0)).is_equal(PlacementRules.NO_FERTILITY)
	assert_str(sim.placement_reason(farm, Vector2i(10, 7), 0, 1)).is_equal(PlacementRules.OK)
	var mine := sim.data.building(&"gold_mine")
	sim.world.economy(1).profile_id = &"coffee_hills"
	assert_str(sim.placement_reason(sim.data.building(&"coffee_plantation"), Vector2i(10, 7), 0, 1)).is_equal(PlacementRules.OK)
	assert_str(sim.placement_reason(sim.data.building(&"tobacco_plantation"), Vector2i(10, 7), 0, 1)).is_equal(PlacementRules.NO_FERTILITY)
	assert_object(mine).is_not_null()


## A cana do canavial tropical vai de navio para a destilaria de rum da principal: a cadeia roda com
## matéria-prima própria, sem o comerciante.
func test_route_brings_tropical_sugar_to_the_rum_distillery() -> void:
	var sim := _tropical_pair()
	_house(sim, 1, 40, &"peasants", 10.0)
	_farm(sim, 1, &"sugar_cane_farm", 10)
	_house(sim, 0, 40, &"artisans", 30.0)
	var distillery := sim.execute(PlaceBuildingCommand.new(0, &"rum_distillery", Vector2i(10, 7), 0))
	assert_bool(distillery.ok()).override_failure_message(str(distillery.reason)).is_true()
	var route := SimFixture.route(sim, [[1, [[&"sugar", true, 4]]], [0, [[&"sugar", false, 4]]]])
	var ship_id := SimFixture.ship(sim, 1)
	sim.execute(SetShipRouteCommand.new(ship_id, route))
	SimFixture.run_until(sim, func() -> bool: return sim.world.economy(0).amount(&"rum") >= 1.0, 900.0)
	assert_float(sim.world.economy(0).amount(&"rum")).is_greater_equal(1.0)


## Duas ilhas planas: a principal temperada e a segunda com o perfil da costa da cana.
func _tropical_pair() -> Simulation:
	var sim := SimFixture.two_islands()
	sim.world.economy(1).profile_id = &"cane_coast"
	return sim


func _house(sim: Simulation, island: int, x: int, tier: StringName, residents: float) -> void:
	var result := sim.execute(PlaceBuildingCommand.new(island, &"house", Vector2i(x, 3), 2))
	assert_bool(result.ok()).override_failure_message(str(result.reason)).is_true()
	var record := sim.world.building(result.placed[0])
	record.tier = tier
	record.residents = residents


## Fazenda abaixo da estrada principal (y = 6), com os campos em volta.
func _farm(sim: Simulation, island: int, def_id: StringName, x: int) -> void:
	var origin := Vector2i(x, 7)
	var result := sim.execute(PlaceBuildingCommand.new(island, def_id, origin, 0))
	assert_bool(result.ok()).override_failure_message(str(result.reason)).is_true()
	var def := sim.data.building(def_id)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var module := sim.data.building(def.module_id)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - module.size.y + 1):
		for x_cell: int in range(reach.position.x, reach.end.x - module.size.x + 1):
			if placed < def.modules_required and sim.execute(PlaceBuildingCommand.new(island, def.module_id, Vector2i(x_cell, y), 0)).ok():
				placed += 1
	assert_int(placed).is_equal(def.modules_required)
