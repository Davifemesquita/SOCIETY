extends GdUnitTestSuite
## Fase 8 (conteúdo): as classes de cima sobem com os materiais delas, estrada de paralelepípedo
## (custo, desbloqueio, carroça mais rápida, A* que a prefere, save), mover prédio sem custo e as
## metas guiadas.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40), 1000)
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))


# --- classes de cima -------------------------------------------------------------------------

## Casa cheia da classe, com todas as necessidades atendidas e os serviços dela no raio.
func _full_house(tier_id: StringName) -> int:
	var tier := _sim.data.tier(tier_id)
	var house := SimFixture.house(_sim, 2, 20, tier_id, float(tier.residents_per_house))
	var x := 10
	for need: NeedCategoryDef in tier.basic_needs:
		for service: StringName in need.services:
			SimFixture.place(_sim, service, Vector2i(x, 21))
			x += _sim.data.building(service).size.x
		for good: StringName in need.goods:
			SimFixture.give(_sim, good, 200.0)
	SimFixture.warm_supply(_sim)
	return house


func test_each_upper_tier_climbs_with_its_own_materials() -> void:
	for pair: Array in [[&"workers", &"artisans"], [&"artisans", &"engineers"], [&"engineers", &"investors"]]:
		before_test()
		var from: StringName = pair[0]
		var to: StringName = pair[1]
		var house := _full_house(from)
		SimFixture.run(_sim, 30.0)
		assert_str(_sim.world.building(house).tier).override_failure_message("%s subiu sem material" % from).is_equal(from)
		var materials := _sim.data.tier(to).upgrade_materials
		for material: StringName in materials:
			SimFixture.give(_sim, material, float(materials[material]))
		SimFixture.run(_sim, 30.0)
		assert_str(_sim.world.building(house).tier).override_failure_message("%s não subiu" % from).is_equal(to)
		for material: StringName in materials:
			assert_float(SimFixture.stock(_sim, material)).is_equal_approx(0.0, 0.0001)


func test_investors_are_the_top() -> void:
	var house := _full_house(&"investors")
	SimFixture.give(_sim, &"steel_beams", 50.0)
	SimFixture.give(_sim, &"windows", 50.0)
	SimFixture.run(_sim, 60.0)
	assert_str(_sim.world.building(house).tier).is_equal(&"investors")


func test_upper_tier_needs_split_like_the_lower_ones() -> void:
	# engenheiros: Lar com máquinas de costura e lâmpadas no estoque divide o consumo entre os dois
	SimFixture.house(_sim, 2, 20, &"engineers", 40.0)
	SimFixture.warm_supply(_sim)
	SimFixture.give(_sim, &"sewing_machines", 100.0)
	SimFixture.give(_sim, &"light_bulbs", 100.0)
	SimFixture.run(_sim, 60.0)
	assert_float(100.0 - SimFixture.stock(_sim, &"sewing_machines")).is_equal_approx(40 * 0.002 / 2.0, 0.005)
	assert_float(100.0 - SimFixture.stock(_sim, &"light_bulbs")).is_equal_approx(40 * 0.0015 / 2.0, 0.005)


# --- paralelepípedo --------------------------------------------------------------------------

func test_cobblestone_costs_money_and_bricks_and_unlocks_with_workers() -> void:
	_sim.free_build = false
	_sim.world.money = 1000.0
	SimFixture.give(_sim, &"bricks", 10.0)
	var cells := RoadPath.l_path(Vector2i(0, 30), Vector2i(4, 30))
	assert_str(_sim.execute(BuildRoadCommand.new(0, cells, true)).reason).is_equal(PlacementRules.LOCKED)
	var config := _sim.config
	var houses := ceili(float(config.paved_road_unlock_residents) / 20.0)
	_sim.free_build = true
	for i: int in houses:
		SimFixture.house(_sim, 40 + i * 3, 20, &"workers", 20.0)
	_sim.free_build = false
	assert_bool(_sim.execute(BuildRoadCommand.new(0, cells, true)).ok()).is_true()
	assert_float(_sim.world.money).is_equal(1000.0 - 5 * config.paved_road_cost_per_cell)
	assert_float(SimFixture.stock(_sim, &"bricks")).is_equal(10.0 - ceili(5 * config.paved_road_bricks_per_cell))
	for cell: Vector2i in cells:
		assert_bool(_sim.world.island(0).is_paved(cell)).is_true()
	# calçar de novo o mesmo trecho não cobra; calçar a terra cobra só o paralelepípedo
	var money := _sim.world.money
	assert_bool(_sim.execute(BuildRoadCommand.new(0, cells, true)).ok()).is_true()
	assert_float(_sim.world.money).is_equal(money)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(10, 30), Vector2i(11, 30))))
	money = _sim.world.money
	assert_bool(_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(10, 30), Vector2i(11, 30)), true)).ok()).is_true()
	assert_float(_sim.world.money).is_equal(money - 2 * config.paved_road_cost_per_cell)


func test_carts_run_faster_on_cobblestone() -> void:
	var times: Array[float] = []
	for paved: bool in [false, true]:
		var sim := SimFixture.simulation(Vector2i(120, 40), 50, true)
		SimFixture.port(sim)
		if paved:
			sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(0, 6), Vector2i(119, 6)), true))
		for i: int in 3:
			SimFixture.house_on_main_road(sim, 80 + i * 3, &"peasants", 10.0)
		var lumberjack := SimFixture.place(sim, &"lumberjack", Vector2i(40, 7))
		SimFixture.run(sim, 15.2)
		var cart := SimFixture.cart(sim, lumberjack)
		times.append(SimFixture.run_until(sim, func() -> bool: return cart.state != Cart.State.OUTBOUND, 120.0))
	assert_float(times[1]).override_failure_message("terra %.1f s, paralelepípedo %.1f s" % times).is_less(times[0] * 0.75)


func test_the_router_prefers_cobblestone() -> void:
	# duas pistas paralelas entre os mesmos pontos: a de baixo é mais longa, mas calçada
	var grid := IslandGrid.new(Vector2i(30, 10))
	for x: int in range(0, 21):
		grid.set_road(Vector2i(x, 2), IslandGrid.Road.DIRT)
		grid.set_road(Vector2i(x, 6), IslandGrid.Road.PAVED)
	for y: int in range(3, 6):
		grid.set_road(Vector2i(0, y), IslandGrid.Road.PAVED)
		grid.set_road(Vector2i(20, y), IslandGrid.Road.PAVED)
	grid.set_road(Vector2i(0, 1), IslandGrid.Road.DIRT)
	grid.set_road(Vector2i(20, 1), IslandGrid.Road.DIRT)
	var path := RoadRouter.new(grid, 0.5).path(grid.index(Vector2i(0, 1)), grid.index(Vector2i(20, 1)))
	assert_bool(path.has(grid.index(Vector2i(10, 6)))).is_true()


func test_cobblestone_survives_save_and_load() -> void:
	var cells := RoadPath.l_path(Vector2i(5, 30), Vector2i(9, 30))
	_sim.execute(BuildRoadCommand.new(0, cells, true))
	var copy := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)
	assert_object(copy).is_not_null()
	assert_int(copy.island(0).roads.count(IslandGrid.Road.PAVED)).is_equal(5)
	assert_bool(copy.island(0).is_paved(Vector2i(7, 30))).is_true()
	assert_bool(copy.island(0).has_road(Vector2i(50, 20))).is_true()
	assert_bool(copy.island(0).is_paved(Vector2i(50, 20))).is_false()


func test_phase7_saves_open_with_dirt_roads_and_goals_from_the_start() -> void:
	var state := {"world": _sim.world.to_dict()}
	var world: Dictionary = state["world"]
	for raw: Variant in world["islands"]:
		var island: Dictionary = raw
		island.erase("paved")
	world.erase("goals_done")
	world.erase("goals_catch_up")
	var migrated := SaveMigrations.from_6_to_7(state)
	var migrated_world: Dictionary = migrated["world"]
	var copy := WorldState.from_dict(migrated_world, _sim.data, _sim.config)
	assert_object(copy).is_not_null()
	assert_int(copy.goals_done).is_equal(0)
	assert_bool(copy.goals_catch_up).is_true()
	assert_int(copy.island(0).roads.count(IslandGrid.Road.PAVED)).is_equal(0)


# --- mover prédio ----------------------------------------------------------------------------

func test_moving_a_house_keeps_who_lives_there_and_costs_nothing() -> void:
	var house := SimFixture.house(_sim, 2, 20, &"workers", 17.0)
	_sim.free_build = false
	_sim.world.money = 500.0
	var record := _sim.world.building(house)
	record.happiness = 66.0
	var old_area := Footprint.rect(record.origin, Vector2i(3, 3), record.rotation)
	var result := _sim.execute(MoveBuildingCommand.new(house, Vector2i(30, 21), 0))
	assert_bool(result.ok()).is_true()
	assert_float(_sim.world.money).is_equal(500.0)
	assert_str(record.tier).is_equal(&"workers")
	assert_float(record.residents).is_equal(17.0)
	assert_float(record.happiness).is_equal(66.0)
	assert_int(_sim.world.island(0).building_at(Vector2i(31, 22))).is_equal(house)
	assert_int(_sim.world.island(0).building_at(old_area.position)).is_equal(0)
	# a área antiga ficou livre para outra casa
	SimFixture.give(_sim, &"planks", 5.0)
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"house", old_area.position, 2)).ok()).is_true()


func test_moving_follows_the_placement_rules() -> void:
	var house := SimFixture.house(_sim, 2, 20, &"peasants", 10.0)
	var other := SimFixture.house(_sim, 5, 20, &"peasants", 10.0)
	var record := _sim.world.building(house)
	assert_str(_sim.execute(MoveBuildingCommand.new(house, record.origin, record.rotation)).reason).is_equal(MoveBuildingCommand.SAME_PLACE)
	assert_str(_sim.execute(MoveBuildingCommand.new(house, _sim.world.building(other).origin, 2)).reason).is_equal(PlacementRules.OCCUPIED)
	assert_str(_sim.execute(MoveBuildingCommand.new(house, Vector2i(10, 19), 0)).reason).is_equal(PlacementRules.ON_ROAD)
	assert_str(_sim.execute(MoveBuildingCommand.new(house, Vector2i(118, 0), 0)).reason).is_equal(PlacementRules.OUT_OF_ISLAND)
	# encostado em si mesmo (meia casa para o lado) pode
	assert_bool(_sim.execute(MoveBuildingCommand.new(house, record.origin + Vector2i(-1, 0), 2)).ok()).is_true()
	assert_str(_sim.move_reason(house, Vector2i(40, 30), 1)).is_equal(PlacementRules.OK)


func test_a_moved_workshop_calls_its_cart_home_with_the_cargo() -> void:
	var sim := SimFixture.simulation(Vector2i(120, 40), 50, true)
	SimFixture.port(sim)
	for i: int in 3:
		SimFixture.house_on_main_road(sim, 80 + i * 3, &"peasants", 10.0)
	var lumberjack := SimFixture.place(sim, &"lumberjack", Vector2i(40, 7))
	SimFixture.run(sim, 16.0)
	var cart := SimFixture.cart(sim, lumberjack)
	assert_int(cart.state).is_equal(Cart.State.OUTBOUND)
	var cargo := cart.tons()
	assert_bool(sim.execute(MoveBuildingCommand.new(lumberjack, Vector2i(28, 7), 0)).ok()).is_true()
	assert_int(cart.state).is_equal(Cart.State.HOME)
	assert_float(cart.tons()).is_equal(cargo)
	# e a carga segue na próxima viagem
	SimFixture.run(sim, 60.0)
	assert_float(SimFixture.stock(sim, &"wood")).is_greater_equal(cargo)


func test_a_berth_with_a_ship_moored_stays_put() -> void:
	var sim := SimFixture.two_islands()
	var ship_id := SimFixture.ship(sim, 0)
	var post := sim.world.colonized_islands(sim.data)
	assert_int(post.size()).is_equal(2)
	var trading_post := 0
	for record: BuildingRecord in sim.world.buildings.values():
		if record.island_id == 0 and sim.def_of(record).is_trading_post:
			trading_post = record.id
	sim.world.ship(ship_id).berth_id = trading_post
	assert_str(sim.execute(MoveBuildingCommand.new(trading_post, Vector2i(20, 0), 2)).reason).is_equal(MoveBuildingCommand.SHIP_AT_BERTH)


# --- metas guiadas ---------------------------------------------------------------------------

func _goal_sim() -> Simulation:
	var sim := SimFixture.simulation(Vector2i(120, 40), 1000)
	sim.world.money = 0.0
	return sim


func test_goals_come_one_at_a_time_and_pay_the_reward() -> void:
	var sim := _goal_sim()
	var goals := sim.data.goals
	assert_str(goals[0].id).is_equal(&"trading_post")
	var completed: Array[int] = []
	var listener := func(index: int) -> void: completed.append(index)
	EventBus.goal_completed.connect(listener)
	SimFixture.run(sim, 2.0)
	assert_int(sim.world.goals_done).is_equal(0)
	SimFixture.place(sim, &"trading_post", Vector2i(0, 0), 2)
	SimFixture.run(sim, 2.0)
	EventBus.goal_completed.disconnect(listener)
	assert_int(sim.world.goals_done).is_equal(1)
	assert_array(completed).is_equal([0])
	assert_object(GoalSystem.current(sim.world, sim.data)).is_same(goals[1])
	assert_float(sim.world.money).is_greater_equal(goals[0].reward_money - 50.0)


func test_supply_goal_counts_only_residents_whose_need_is_met() -> void:
	var sim := _goal_sim()
	var fish: GoalDef = null
	for goal: GoalDef in sim.data.goals:
		if goal.id == &"fish":
			fish = goal
	SimFixture.road(sim, Vector2i(0, 20), Vector2i(119, 20))
	for i: int in 6:
		SimFixture.house(sim, 2 + i * 3, 20, &"peasants", 10.0)
	assert_int(GoalSystem.progress(sim.world, sim.data, sim.config, sim.derived_state(), fish)).is_equal(0)
	SimFixture.warm_supply(sim)
	SimFixture.give(sim, &"fish", 100.0)
	SimFixture.run(sim, 2.0)
	assert_int(GoalSystem.progress(sim.world, sim.data, sim.config, sim.derived_state(), fish)).is_greater_equal(50)


func test_a_milestone_goal_waits_for_its_milestone() -> void:
	var sim := _goal_sim()
	var colony_index := -1
	for index: int in sim.data.goals.size():
		if sim.data.goals[index].id == &"colony":
			colony_index = index
	assert_int(sim.data.goals[colony_index].after_milestone).is_equal(1)
	sim.world.goals_done = colony_index
	# duas ilhas com entreposto já cumprem a quantidade, mas o marco ainda não veio
	var two := SimFixture.two_islands()
	two.world.goals_done = colony_index
	SimFixture.run(two, 2.0)
	assert_int(two.world.goals_done).is_equal(colony_index)
	two.world.milestones_reached = 1
	SimFixture.run(two, 2.0)
	assert_int(two.world.goals_done).is_greater(colony_index)


func test_an_old_save_catches_up_without_rewards() -> void:
	var sim := _goal_sim()
	SimFixture.place(sim, &"trading_post", Vector2i(0, 0), 2)
	SimFixture.road(sim, Vector2i(0, 20), Vector2i(119, 20))
	for i: int in 6:
		SimFixture.house(sim, 2 + i * 3, 20, &"peasants", 10.0)
	sim.world.goals_catch_up = true
	var completed: Array[int] = []
	var listener := func(index: int) -> void: completed.append(index)
	EventBus.goal_completed.connect(listener)
	sim.tick(0)
	EventBus.goal_completed.disconnect(listener)
	assert_int(sim.world.goals_done).is_equal(2)
	assert_array(completed).is_empty()
	assert_bool(sim.world.goals_catch_up).is_false()
	assert_float(sim.world.money).is_less(1.0)


func test_goals_survive_save_and_load() -> void:
	var sim := _goal_sim()
	sim.world.goals_done = 3
	var copy := WorldState.from_dict(sim.world.to_dict(), sim.data, sim.config)
	assert_int(copy.goals_done).is_equal(3)
	var state := sim.world.to_dict()
	state["goals_done"] = sim.data.goals.size() + 1
	assert_object(WorldState.from_dict(state, sim.data, sim.config)).is_null()
