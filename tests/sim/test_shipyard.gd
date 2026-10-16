extends GdUnitTestSuite
## Estaleiro: produção sem bem, no litoral, que constrói um navio por vez por encomenda. A encomenda
## paga na hora shipyard_cost_factor do preço do entreposto, conta no limite de navios e espera o
## desbloqueio do navio; anda na velocidade da força de trabalho e, pronta, o navio aparece no porto da
## ilha. O clíper só sai do estaleiro. Cancelar devolve parte das moedas. Ilha com estaleiro repara
## navio mais depressa. A encomenda vai no save.

var _sim: Simulation
var _yard: int


func before_test() -> void:
	_sim = SimFixture.two_islands()
	_sim.world.money = 100000.0
	# o estaleiro no litoral norte, de frente para um trecho de estrada colado na principal (y = 6)
	_yard = SimFixture.place(_sim, &"shipyard", Vector2i(20, 0), 2)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(20, 5), Vector2i(25, 5))))
	for x: int in [36, 41, 46, 51]:
		SimFixture.house(_sim, x, 6, &"workers", 20.0)
	_sim.free_build = false
	_sim.world.milestones_reached = 3
	SimFixture.give(_sim, &"planks", 40.0)
	SimFixture.give(_sim, &"steel", 20.0)


func _order(def_id: StringName) -> CommandResult:
	return _sim.execute(ShipyardCommand.order(_yard, def_id))


func test_data_defines_the_shipyard_and_the_clipper() -> void:
	var data := GameData.get_default()
	var yard := data.building(&"shipyard")
	assert_bool(yard.is_shipyard()).is_true()
	assert_bool(yard.is_power_plant()).is_false()
	assert_int(yard.terrain).is_equal(BuildingDef.Terrain.COAST)
	assert_array(yard.shipyard_ships).contains([&"merchant_ship", &"clipper", &"frigate"])
	assert_bool(data.ship(&"clipper").shipyard_only).is_true()
	assert_float(data.ship(&"clipper").speed_m_s).is_greater(data.ship(&"merchant_ship").speed_m_s)
	assert_bool(data.specialist(&"foreman").covers(yard)).is_false()
	assert_array(data.validate()).is_empty()
	assert_array(GameConfig.new().validate()).is_empty()


func test_order_is_cheaper_and_the_ship_comes_out_at_the_island() -> void:
	var def := _sim.data.ship(&"merchant_ship")
	var money := _sim.world.money
	var ships := _sim.world.player_ships().size()
	assert_bool(_order(&"merchant_ship").ok()).is_true()
	assert_float(money - _sim.world.money).is_equal(float(ceili(def.cost_money * _sim.config.shipyard_cost_factor)))
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(40.0 - ceili(def.cost_materials[&"planks"] * _sim.config.shipyard_cost_factor))
	var built: Array[int] = []
	var on_built := func(ship_id: int) -> void: built.append(ship_id)
	EventBus.ship_built.connect(on_built)
	SimFixture.run(_sim, def.build_time_s * 0.9)
	assert_int(_sim.world.building(_yard).state).is_equal(BuildingRecord.State.PRODUCING)
	assert_int(_sim.world.player_ships().size()).is_equal(ships)
	SimFixture.run(_sim, def.build_time_s * 0.2)
	EventBus.ship_built.disconnect(on_built)
	assert_int(_sim.world.player_ships().size()).is_equal(ships + 1)
	assert_int(built.size()).is_equal(1)
	var ship := _sim.world.ship(built[0])
	assert_str(ship.def_id).is_equal("merchant_ship")
	assert_int(ship.at).is_equal(0)
	assert_bool(ship.is_placed()).is_true()
	assert_object(_sim.world.shipyard_state.order(_yard)).is_null()
	assert_int(_sim.world.shipyard_state.ships_built).is_equal(1)
	assert_int(_sim.world.building(_yard).state).is_equal(BuildingRecord.State.IDLE)


func test_without_workers_the_order_waits() -> void:
	for building_id: int in _sim.world.building_ids():
		if _sim.world.building(building_id).is_house():
			_sim.world.building(building_id).residents = 0.0
	_sim.execute(DemolishCommand.new(0, Rect2i(36, 3, 20, 3)))
	assert_bool(_order(&"merchant_ship").ok()).is_true()
	SimFixture.run(_sim, 30.0)
	assert_int(_sim.world.building(_yard).state).is_equal(BuildingRecord.State.NO_WORKERS)
	assert_float(_sim.world.shipyard_state.order(_yard).progress).is_equal(0.0)


func test_trading_post_does_not_sell_the_clipper_and_the_shipyard_waits_for_the_milestone() -> void:
	assert_str(_sim.execute(BuyShipCommand.new(0, &"clipper")).reason).is_equal(PlacementRules.SHIPYARD_ONLY)
	_sim.world.milestones_reached = 2
	assert_str(_order(&"clipper").reason).is_equal(PlacementRules.SHIP_LOCKED)
	_sim.world.milestones_reached = 3
	assert_bool(_order(&"clipper").ok()).is_true()
	assert_str(_order(&"merchant_ship").reason).is_equal(ShipyardCommand.BUSY)
	assert_str(_sim.execute(ShipyardCommand.order(_yard, &"trader_ship")).reason).is_equal(ShipyardCommand.WRONG_SHIP)


func test_cancel_returns_part_of_the_money_and_orders_count_in_the_fleet_limit() -> void:
	assert_bool(_order(&"merchant_ship").ok()).is_true()
	var paid := _sim.world.shipyard_state.order(_yard).paid_money
	var money := _sim.world.money
	assert_bool(_sim.execute(ShipyardCommand.cancel_order(_yard)).ok()).is_true()
	assert_float(_sim.world.money - money).is_equal(floorf(paid * _sim.config.shipyard_cancel_refund))
	assert_str(_sim.execute(ShipyardCommand.cancel_order(_yard)).reason).is_equal(ShipyardCommand.NO_ORDER)
	# com o limite cheio pelas encomendas, nem o entreposto vende
	_sim.world.milestones_reached = 0
	var limit := MilestoneSystem.ship_limit(_sim.world, _sim.config)
	while _sim.world.player_ships().size() < limit - 1:
		_sim.free_build = true
		SimFixture.ship(_sim, 0)
		_sim.free_build = false
	assert_bool(_order(&"merchant_ship").ok()).is_true()
	assert_str(_sim.execute(BuyShipCommand.new(0)).reason).is_equal(PlacementRules.SHIP_LIMIT)


func test_island_with_a_shipyard_repairs_faster() -> void:
	var ship_id := SimFixture.ship(_sim, 0)
	var ship := _sim.world.ship(ship_id)
	SimFixture.run(_sim, 1.0)
	ship.hp = 10.0
	SimFixture.run(_sim, 10.0)
	var expected := 10.0 + _sim.config.ship_repair_per_s * _sim.config.shipyard_repair_factor * 10.0
	assert_float(ship.hp).is_equal_approx(minf(expected, _sim.data.ship(ship.def_id).hull_points), 1.0)


func test_save_keeps_the_order_and_demolish_drops_it() -> void:
	assert_bool(_order(&"merchant_ship").ok()).is_true()
	SimFixture.run(_sim, 30.0)
	var progress := _sim.world.shipyard_state.order(_yard).progress
	assert_float(progress).is_greater(0.0)
	var loaded := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)
	assert_object(loaded).is_not_null()
	assert_float(loaded.shipyard_state.order(_yard).progress).is_equal(progress)
	assert_str(loaded.shipyard_state.order(_yard).def_id).is_equal("merchant_ship")
	_sim.world.shipyard_state.order(_yard).def_id = &"trader_ship"
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()
	_sim.world.shipyard_state.order(_yard).def_id = &"merchant_ship"
	_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(20, 0), Vector2i.ONE)))
	assert_bool(_sim.world.shipyard_state.orders.is_empty()).is_true()
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_not_null()


func test_old_saves_start_without_orders() -> void:
	var migrated := SaveMigrations.from_13_to_14({"world": {}})
	var world: Dictionary = migrated["world"]
	var saved: Dictionary = world["shipyard"]
	var loaded := ShipyardState.from_dict(saved, WorldState.new(), GameData.get_default())
	assert_object(loaded).is_not_null()
	assert_bool(loaded.orders.is_empty()).is_true()
	assert_int(SaveMigrations.all().size()).is_equal(SaveSystem.SAVE_VERSION - 1)
