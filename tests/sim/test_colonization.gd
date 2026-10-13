extends GdUnitTestSuite
## Colonização e marcos (Fase 6): o jogo começa com o navio trazendo as tábuas, que descem no
## primeiro entreposto; colonizar outra ilha pede o marco, um navio ancorado nela com os materiais
## e o dinheiro, e o resto do porão vai para o estoque novo. Os marcos de população liberam navios
## e ilhas.


func test_starting_ship_carries_the_planks_and_unloads_at_the_first_trading_post() -> void:
	var sim := Simulation.new(GameConfig.get_default(), GameData.get_default())
	assert_float(sim.world.money).is_equal(50000.0)
	assert_float(sim.world.economy(0).amount(&"planks")).is_equal(0.0)
	var ships := sim.world.player_ships()
	assert_int(ships.size()).is_equal(1)
	assert_float(ships[0].tons_of(&"planks")).is_equal(40.0)
	assert_int(ships[0].at).is_equal(0)
	assert_bool(ships[0].is_placed()).is_true()
	assert_bool(sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(0, 0), 2)).ok()).is_true()
	# o primeiro entreposto é grátis e o navio descarrega tudo nele
	assert_float(sim.world.economy(0).amount(&"planks")).is_equal(40.0)
	assert_float(ships[0].total_tons()).is_equal(0.0)


func test_colony_needs_the_milestone_a_ship_with_materials_and_unloads_the_rest() -> void:
	var sim := _colonizable()
	var post := sim.data.building(&"trading_post")
	assert_str(sim.placement_reason(post, Vector2i(0, 0), 2, 1)).is_equal(PlacementRules.ISLAND_LOCKED)
	sim.world.milestones_reached = 1
	assert_str(sim.placement_reason(post, Vector2i(0, 0), 2, 1)).is_equal(PlacementRules.NEEDS_SHIP)
	sim.free_build = true
	var ship := sim.world.ship(SimFixture.ship(sim, 0))
	sim.free_build = false
	sim.execute(MoveShipCommand.new(ship.id, 1))
	SimFixture.run_until(sim, func() -> bool: return ship.state == Ship.State.IDLE and ship.at == 1, 300.0)
	assert_str(sim.placement_reason(post, Vector2i(0, 0), 2, 1)).is_equal(PlacementRules.NO_MATERIALS)
	ship.load_good(&"planks", 30.0, 50.0)
	ship.load_good(&"fish", 12.0, 50.0)
	assert_str(sim.placement_reason(post, Vector2i(0, 0), 2, 1)).is_equal(PlacementRules.OK)
	var colonized: Array[int] = []
	EventBus.island_colonized.connect(func(island_id: int) -> void: colonized.append(island_id))
	var money := sim.world.money
	assert_bool(sim.execute(PlaceBuildingCommand.new(1, &"trading_post", Vector2i(0, 0), 2)).ok()).is_true()
	assert_array(colonized).contains([1])
	assert_float(money - sim.world.money).is_equal(float(post.cost_money))
	# as 10 tábuas do entreposto saem do porão; o resto desce no estoque novo
	assert_float(sim.world.economy(1).amount(&"planks")).is_equal(30.0 - float(post.cost_materials[&"planks"]))
	assert_float(sim.world.economy(1).amount(&"fish")).is_equal(12.0)
	assert_float(ship.total_tons()).is_equal(0.0)


func test_population_milestones_are_reached_once_and_raise_the_limits() -> void:
	var sim := SimFixture.simulation()
	var reached: Array[int] = []
	EventBus.milestone_reached.connect(func(count: int) -> void: reached.append(count))
	SimFixture.road(sim, Vector2i(0, 10), Vector2i(119, 10))
	for i: int in 11:
		SimFixture.house(sim, 2 + i * 3, 10, &"peasants", 10.0)
	SimFixture.warm_supply(sim)
	sim.run_ticks(sim.config.house_update_groups)
	assert_int(sim.world.milestones_reached).is_equal(1)
	assert_array(reached).is_equal([1])
	assert_int(MilestoneSystem.ship_limit(sim.world, sim.config)).is_equal(sim.config.ships_by_milestone[1])
	assert_int(MilestoneSystem.island_limit(sim.world, sim.config)).is_equal(sim.config.islands_by_milestone[1])
	sim.run_ticks(sim.config.house_update_groups)
	assert_array(reached).is_equal([1])


## Duas ilhas, entreposto só na principal, cobrando custo.
func _colonizable() -> Simulation:
	var sim := SimFixture.two_islands()
	sim.execute(DemolishCommand.new(1, Rect2i(0, 0, 6, 6)))
	assert_bool(sim.world.has_trading_post(1, sim.data)).is_false()
	sim.free_build = false
	return sim
