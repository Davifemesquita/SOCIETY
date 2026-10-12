extends GdUnitTestSuite
## Logística (seção 6): entreposto primeiro, carroça leva a saída e traz a entrada, alcance de
## 40 células por estrada, armazém ligado ao entreposto, fila nas rampas, upgrades, estrada
## cortada e estoque cheio.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40), 50, true)


func _place(def_id: StringName, origin: Vector2i, rotation: int = 0) -> CommandResult:
	return _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))


func _workers() -> void:
	for i: int in 3:
		SimFixture.house_on_main_road(_sim, 80 + i * 3, &"peasants", 10.0)
	for i: int in 3:
		SimFixture.house_on_main_road(_sim, 100 + i * 3, &"workers", 20.0)


func test_only_the_trading_post_before_it_exists() -> void:
	_sim.free_build = false
	_sim.world.money = 5000.0
	SimFixture.give(_sim, &"planks", 40.0)
	assert_str(_place(&"lumberjack", Vector2i(20, 7)).reason).is_equal(PlacementRules.NEEDS_TRADING_POST)
	assert_str(_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(0, 6), Vector2i(9, 6)))).reason).is_equal(PlacementRules.NEEDS_TRADING_POST)
	assert_str(_place(&"trading_post", Vector2i(30, 10), 2).reason).is_equal(PlacementRules.NEEDS_COAST)
	assert_bool(_place(&"trading_post", Vector2i(0, 0), 2).ok()).is_true()
	assert_float(_sim.world.money).override_failure_message("o primeiro entreposto é gratuito").is_equal(5000.0)
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(40.0)
	assert_bool(_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(0, 6), Vector2i(30, 6)))).ok()).is_true()
	assert_bool(_place(&"lumberjack", Vector2i(20, 7)).ok()).is_true()
	assert_bool(_place(&"trading_post", Vector2i(100, 0), 2).ok()).is_true()
	assert_float(_sim.world.money).override_failure_message("o segundo entreposto é pago").is_less(5000.0 - 100.0 - 155.0)


func test_output_reaches_the_stock_only_when_the_cart_arrives() -> void:
	SimFixture.port(_sim)
	_workers()
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(20, 7))
	SimFixture.run(_sim, 15.2)
	assert_int(SimFixture.cart(_sim, lumberjack).state).is_equal(Cart.State.OUTBOUND)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(0.0)
	# 15 células a 2 células/s = 7,5 s; 1 t na rampa = 2 s
	SimFixture.run(_sim, 9.0)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(0.0)
	SimFixture.run(_sim, 1.0)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(1.0)
	# volta em ~32 s e sai de novo com a segunda tonelada, pronta aos 30 s
	SimFixture.run(_sim, 8.0)
	var cart := SimFixture.cart(_sim, lumberjack)
	assert_int(cart.state).is_equal(Cart.State.OUTBOUND)
	assert_dict(cart.cargo).is_equal({&"wood": 1.0})


func test_the_cart_brings_the_input_back_on_the_same_trip() -> void:
	SimFixture.port(_sim)
	_workers()
	SimFixture.give(_sim, &"wood", 10.0)
	var sawmill := SimFixture.place(_sim, &"sawmill", Vector2i(20, 7))
	SimFixture.run(_sim, 0.4)
	var cart := SimFixture.cart(_sim, sawmill)
	assert_int(cart.state).is_equal(Cart.State.OUTBOUND)
	assert_dict(cart.wanted).is_equal({&"wood": 2.0})
	SimFixture.run(_sim, 7.6 + 4.2 + 7.6)
	assert_float(_sim.world.building(sawmill).input_buffer.get(&"wood", 0.0) + (1.0 if _sim.world.building(sawmill).in_cycle else 0.0)).is_equal(2.0)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(8.0)


func test_logistics_range_is_forty_road_cells() -> void:
	SimFixture.port(_sim)
	var near := SimFixture.place(_sim, &"lumberjack", Vector2i(45, 7))
	var far := SimFixture.place(_sim, &"lumberjack", Vector2i(49, 7))
	var derived := _sim.derived_state()
	var near_entry := derived.entry_of(near)
	assert_int(near_entry.warehouse_distance).is_equal(40)
	assert_int(near_entry.warehouse_id).is_not_equal(0)
	assert_int(derived.entry_of(far).warehouse_distance).is_equal(44)
	assert_int(derived.entry_of(far).warehouse_id).is_equal(0)
	SimFixture.run(_sim, 1.0)
	assert_int(_sim.world.building(far).state).is_equal(BuildingRecord.State.NO_WAREHOUSE)


func test_warehouse_works_only_when_linked_to_the_trading_post() -> void:
	SimFixture.place(_sim, &"trading_post", Vector2i(0, 0), 2)
	SimFixture.road(_sim, Vector2i(0, 6), Vector2i(20, 6))
	SimFixture.road(_sim, Vector2i(60, 6), Vector2i(119, 6))
	var warehouse := SimFixture.place(_sim, &"warehouse", Vector2i(70, 7))
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(80, 7))
	assert_bool(_sim.derived_state().warehouse_connected[warehouse]).is_false()
	assert_int(_sim.derived_state().entry_of(lumberjack).warehouse_id).is_equal(0)
	SimFixture.road(_sim, Vector2i(20, 6), Vector2i(60, 6))
	assert_bool(_sim.derived_state().warehouse_connected[warehouse]).is_true()
	assert_int(_sim.derived_state().entry_of(lumberjack).warehouse_id).is_equal(warehouse)


func test_buildings_use_the_nearest_warehouse_by_road() -> void:
	SimFixture.port(_sim)
	var warehouse := SimFixture.place(_sim, &"warehouse", Vector2i(60, 7))
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(50, 7))
	assert_int(_sim.derived_state().entry_of(lumberjack).warehouse_id).is_equal(warehouse)


func test_third_cart_waits_in_the_ramp_queue() -> void:
	_sim.config.cart_seconds_per_ton = 30.0
	SimFixture.port(_sim)
	_workers()
	var carts: Array[Cart] = []
	for x: int in [10, 13, 16]:
		carts.append(SimFixture.cart(_sim, SimFixture.place(_sim, &"lumberjack", Vector2i(x, 7))))
	SimFixture.run(_sim, 15.2 + 8.0)
	var states := carts.map(func(cart: Cart) -> int: return cart.state)
	assert_int(states.count(Cart.State.AT_RAMP)).is_equal(2)
	assert_int(states.count(Cart.State.QUEUED)).is_equal(1)


func test_upgrades_add_ramps_and_storage() -> void:
	var post := SimFixture.port(_sim)
	var warehouse := SimFixture.place(_sim, &"warehouse", Vector2i(60, 7))
	assert_float(_sim.storage_capacity()).is_equal(50.0)
	assert_bool(_sim.execute(UpgradeBuildingCommand.new(post)).ok()).is_true()
	assert_bool(_sim.execute(UpgradeBuildingCommand.new(warehouse)).ok()).is_true()
	assert_float(_sim.storage_capacity()).is_equal(100.0)
	assert_int(_sim.derived_state().ramps[warehouse]).is_equal(4)
	_sim.execute(UpgradeBuildingCommand.new(post))
	assert_str(_sim.execute(UpgradeBuildingCommand.new(post)).reason).is_equal(&"REASON_MAX_LEVEL")
	assert_float(_sim.storage_capacity()).is_equal(150.0)


func test_upgrade_charges_the_level_cost() -> void:
	var post := SimFixture.port(_sim)
	_sim.free_build = false
	_sim.world.money = 3000.0
	SimFixture.give(_sim, &"planks", 20.0)
	assert_str(_sim.execute(UpgradeBuildingCommand.new(post)).reason).is_equal(PlacementRules.NO_MATERIALS)
	SimFixture.give(_sim, &"bricks", 6.0)
	assert_bool(_sim.execute(UpgradeBuildingCommand.new(post)).ok()).is_true()
	assert_float(_sim.world.money).is_equal(1000.0)
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(10.0)


func test_cut_road_makes_the_cart_wait_and_rebuilding_releases_it() -> void:
	SimFixture.port(_sim)
	_workers()
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(30, 7))
	SimFixture.run(_sim, 15.2 + 2.0)
	var cart := SimFixture.cart(_sim, lumberjack)
	assert_int(cart.state).is_equal(Cart.State.OUTBOUND)
	_sim.execute(DemolishCommand.new(0, Rect2i(15, 6, 1, 1)))
	SimFixture.run(_sim, 10.0)
	assert_bool(cart.blocked).is_true()
	assert_int(_sim.world.building(lumberjack).state).is_equal(BuildingRecord.State.NO_WAREHOUSE)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(0.0)
	SimFixture.road(_sim, Vector2i(15, 6), Vector2i(15, 6))
	SimFixture.run(_sim, 15.0)
	assert_bool(cart.blocked).is_false()
	assert_float(SimFixture.stock(_sim, &"wood")).is_greater_equal(1.0)


func test_full_stock_sends_the_cart_home_with_the_rest() -> void:
	SimFixture.port(_sim)
	_workers()
	SimFixture.give(_sim, &"wood", 49.0)
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(20, 7))
	_sim.world.building(lumberjack).output_buffer = 2.0
	SimFixture.run(_sim, 30.0)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(50.0)
	assert_float(SimFixture.cart(_sim, lumberjack).cargo.get(&"wood", 0.0)).is_greater_equal(1.0)


func test_houses_keep_consuming_straight_from_the_stock() -> void:
	SimFixture.port(_sim)
	SimFixture.house_on_main_road(_sim, 40, &"peasants", 10.0)
	SimFixture.give(_sim, &"fish", 10.0)
	SimFixture.run(_sim, 60.0)
	assert_float(SimFixture.stock(_sim, &"fish")).is_less(10.0)


func test_demolishing_the_home_removes_its_cart() -> void:
	SimFixture.port(_sim)
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(20, 7))
	_sim.execute(DemolishCommand.new(0, Rect2i(20, 7, 1, 1)))
	assert_object(_sim.world.cart(lumberjack)).is_null()
