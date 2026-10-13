extends GdUnitTestSuite
## Navios (Fase 6): porão por compartimento, viagem pela carta, rota repetida com carga e
## descarga, fila do porto com o píer abrindo vaga, tempo no cais pelas toneladas, ordem à mão,
## manutenção, compra pelo marco e salvar com navio no meio da viagem.

const SaveSystemScript := preload("res://core/save_system.gd")
const TEST_DIR := "user://test_saves_ships"

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.two_islands()


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
	DirAccess.remove_absolute(TEST_DIR)


func test_hold_fills_one_good_per_slot() -> void:
	var ship := Ship.new(1, _sim.data.ship(&"merchant_ship"))
	assert_float(ship.load_good(&"planks", 120.0, 50.0)).is_equal(120.0)
	assert_array(ship.slot_goods).is_equal([&"planks", &"planks", &"planks", &""])
	assert_float(ship.room_for(&"planks", 50.0)).is_equal(80.0)
	assert_float(ship.room_for(&"fish", 50.0)).is_equal(50.0)
	assert_float(ship.load_good(&"fish", 70.0, 50.0)).is_equal(50.0)
	assert_float(ship.unload_good(&"planks", 60.0)).is_equal(60.0)
	assert_float(ship.tons_of(&"planks")).is_equal(60.0)
	# o compartimento que esvaziou fica livre para outro bem
	assert_int(ship.slot_goods.count(&"")).is_equal(1)
	assert_float(ship.total_tons()).is_equal(110.0)


func test_bought_ship_anchors_off_the_port_and_sails_to_the_other_island() -> void:
	var ship_id := SimFixture.ship(_sim, 0)
	var ship := _sim.world.ship(ship_id)
	assert_bool(ship.is_placed()).is_true()
	assert_bool(_sim.harbors().chart.is_navigable(_sim.harbors().chart.cell_of(ship.position))).is_true()
	assert_bool(_sim.execute(MoveShipCommand.new(ship_id, 1)).ok()).is_true()
	var seconds := SimFixture.run_until(_sim, func() -> bool: return ship.state == Ship.State.IDLE and ship.at == 1, 300.0)
	assert_int(ship.at).is_equal(1)
	assert_float(ship.position.distance_to(_sim.harbors().roadstead(1))).is_less(0.01)
	# 6 m/s: a viagem leva pelo menos a distância em linha reta dividida pela velocidade
	var straight := _sim.harbors().roadstead(0).distance_to(_sim.harbors().roadstead(1))
	assert_float(seconds).is_greater_equal(straight / _sim.data.ship(&"merchant_ship").speed_m_s - 0.5)


func test_route_repeats_carrying_goods_from_one_island_to_the_other() -> void:
	_sim.world.economy(0).stock[&"bricks"] = 50.0
	var route := SimFixture.route(_sim, [[0, [[&"bricks", true, 20]]], [1, [[&"bricks", false, 20]]]])
	var ship_id := SimFixture.ship(_sim, 0)
	_sim.execute(SetShipRouteCommand.new(ship_id, route))
	SimFixture.run(_sim, 600.0)
	# várias voltas de 20 t: a ilha 0 esvazia até o que não completa uma carga cheia
	assert_float(_sim.world.economy(1).amount(&"bricks")).is_equal(50.0)
	assert_float(_sim.world.economy(0).amount(&"bricks")).is_equal(0.0)
	assert_float(_sim.world.ship(ship_id).tons_of(&"bricks")).is_equal(0.0)


func test_time_at_the_quay_follows_the_tons_moved() -> void:
	_sim.world.economy(0).stock[&"bricks"] = 40.0
	var route := SimFixture.route(_sim, [[0, [[&"bricks", true, 40]]], [1, [[&"bricks", false, 40]]]])
	var ship_id := SimFixture.ship(_sim, 0)
	var ship := _sim.world.ship(ship_id)
	_sim.execute(SetShipRouteCommand.new(ship_id, route))
	SimFixture.run_until(_sim, func() -> bool: return ship.state == Ship.State.DOCKED, 120.0)
	assert_float(ship.timer).is_equal_approx(40.0 * _sim.config.ship_seconds_per_ton, 0.001)
	# a carga só passa para o porão quando o tempo do cais acaba
	assert_float(ship.tons_of(&"bricks")).is_equal(0.0)
	SimFixture.run_until(_sim, func() -> bool: return ship.state == Ship.State.SAILING, 120.0)
	assert_float(ship.tons_of(&"bricks")).is_equal(40.0)
	assert_float(_sim.world.economy(0).amount(&"bricks")).is_equal(0.0)


func test_one_ship_per_berth_and_a_pier_opens_another() -> void:
	var route := SimFixture.route(_sim, [[0, [[&"planks", true, 50]]], [1, [[&"planks", false, 50]]]])
	_sim.world.economy(0).stock[&"planks"] = 50.0
	var first := _sim.world.ship(SimFixture.ship(_sim, 0))
	var second := _sim.world.ship(SimFixture.ship(_sim, 0))
	_sim.execute(SetShipRouteCommand.new(first.id, route))
	_sim.execute(SetShipRouteCommand.new(second.id, route))
	SimFixture.run_until(_sim, func() -> bool: return first.state == Ship.State.DOCKED or second.state == Ship.State.DOCKED, 60.0)
	SimFixture.run(_sim, 1.0)
	var states := [first.state, second.state]
	assert_array(states).contains_exactly_in_any_order([Ship.State.DOCKED, Ship.State.WAITING])
	# píer no litoral norte, com um ramal até a estrada principal: mais uma vaga
	SimFixture.place(_sim, &"pier", Vector2i(20, 0), 2)
	SimFixture.road(_sim, Vector2i(21, 4), Vector2i(21, 6))
	assert_array(_sim.derived_state().berths[0]).has_size(2)
	SimFixture.run(_sim, 30.0)
	assert_bool(first.state != Ship.State.WAITING and second.state != Ship.State.WAITING).is_true()
	assert_int(first.berth_id).is_not_equal(second.berth_id)


func test_pier_without_road_to_the_trading_post_is_no_berth() -> void:
	SimFixture.place(_sim, &"pier", Vector2i(30, 0), 0)
	assert_array(_sim.derived_state().berths[0]).has_size(1)


func test_editing_the_route_restarts_it_and_deleting_leaves_ships_anchored() -> void:
	var route := SimFixture.route(_sim, [[0, []], [1, []]])
	var ship_id := SimFixture.ship(_sim, 0)
	var ship := _sim.world.ship(ship_id)
	_sim.execute(SetShipRouteCommand.new(ship_id, route))
	SimFixture.run_until(_sim, func() -> bool: return ship.stop_index == 1 and ship.state == Ship.State.SAILING, 120.0)
	var stops: Array[TradeRoute.Stop] = [TradeRoute.Stop.new(1), TradeRoute.Stop.new(0)]
	assert_bool(_sim.execute(EditRouteCommand.new(route, stops)).ok()).is_true()
	assert_int(ship.stop_index).is_equal(0)
	SimFixture.run(_sim, 1.0)
	assert_int(ship.destination).is_equal(1)
	assert_bool(_sim.execute(DeleteRouteCommand.new(route)).ok()).is_true()
	assert_int(ship.route_id).is_equal(0)
	assert_int(ship.state).is_equal(Ship.State.IDLE)


func test_manual_cargo_only_with_the_ship_anchored_in_port() -> void:
	_sim.world.economy(0).stock[&"planks"] = 30.0
	var ship_id := SimFixture.ship(_sim, 0)
	var ship := _sim.world.ship(ship_id)
	assert_bool(_sim.execute(TransferCargoCommand.new(ship_id, &"planks", 50.0)).ok()).is_true()
	assert_float(ship.tons_of(&"planks")).is_equal(30.0)
	assert_float(_sim.world.economy(0).amount(&"planks")).is_equal(0.0)
	assert_bool(_sim.execute(TransferCargoCommand.new(ship_id, &"planks", -10.0)).ok()).is_true()
	assert_float(ship.tons_of(&"planks")).is_equal(20.0)
	_sim.execute(MoveShipCommand.new(ship_id, 1))
	assert_str(_sim.execute(TransferCargoCommand.new(ship_id, &"planks", -10.0)).reason).is_equal(ShipRules.NOT_IN_PORT)


func test_ships_pay_upkeep() -> void:
	var before := _sim.derived_state().upkeep_per_min
	SimFixture.ship(_sim, 0)
	assert_float(_sim.derived_state().upkeep_per_min - before).is_equal(float(_sim.data.ship(&"merchant_ship").upkeep_per_min))


func test_buying_a_ship_costs_and_respects_the_milestone_limit() -> void:
	_sim.free_build = false
	_sim.world.economy(0).stock[&"planks"] = 100.0
	var def := _sim.data.ship(&"merchant_ship")
	assert_bool(_sim.execute(BuyShipCommand.new(0)).ok()).is_true()
	assert_float(_sim.world.money).is_equal(50000.0 - def.cost_money)
	assert_float(_sim.world.economy(0).amount(&"planks")).is_equal(100.0 - def.cost_materials[&"planks"])
	# sem marco atingido, só um navio
	assert_str(_sim.execute(BuyShipCommand.new(0)).reason).is_equal(PlacementRules.SHIP_LIMIT)
	_sim.world.milestones_reached = 1
	assert_bool(_sim.execute(BuyShipCommand.new(0)).ok()).is_true()


func test_saved_fleet_comes_back_identical_and_keeps_sailing_the_same() -> void:
	_sim.world.economy(0).stock[&"bricks"] = 50.0
	var route := SimFixture.route(_sim, [[0, [[&"bricks", true, 20]]], [1, [[&"bricks", false, 20]]]])
	var ship_id := SimFixture.ship(_sim, 0)
	_sim.execute(SetShipRouteCommand.new(ship_id, route))
	SimFixture.run(_sim, 47.0)
	assert_int(_sim.world.ship(ship_id).state).is_equal(Ship.State.SAILING)
	var saves: SaveSystemScript = auto_free(SaveSystemScript.new())
	saves.save_dir = TEST_DIR
	saves.save_game("navios", {"world": _sim.world.to_dict()})
	var world_data: Dictionary = saves.load_game("navios")["world"]
	var restored := WorldState.from_dict(world_data, _sim.data)
	assert_object(restored).is_not_null()
	assert_bool(restored.to_dict() == _sim.world.to_dict()).is_true()
	var copy := Simulation.new(_sim.config, _sim.data, restored)
	copy.free_build = true
	SimFixture.run(_sim, 120.0)
	SimFixture.run(copy, 120.0)
	assert_bool(copy.world.to_dict() == _sim.world.to_dict()).override_failure_message("a frota divergiu depois de carregar").is_true()


func test_ship_casts_off_while_the_route_is_computed_in_the_background() -> void:
	var ship := _sim.world.ship(SimFixture.ship(_sim, 0))
	_sim.execute(MoveShipCommand.new(ship.id, 1))
	var start := ship.position
	var ticks := roundi(_sim.config.ship_cast_off_seconds / _sim.config.tick_interval())
	for i: int in ticks - 1:
		_sim.tick(0)
	# içando velas: parado, sem caminho ainda
	assert_int(ship.state).is_equal(Ship.State.SAILING)
	assert_bool(ship.waypoints.is_empty()).is_true()
	assert_bool(ship.position.is_equal_approx(start)).is_true()
	_sim.tick(0)
	assert_bool(ship.waypoints.is_empty()).is_false()
	_sim.tick(0)
	assert_bool(ship.position.is_equal_approx(start)).is_false()


func test_saved_while_casting_off_keeps_sailing_the_same() -> void:
	var route := SimFixture.route(_sim, [[1, []], [0, []]])
	var ship_id := SimFixture.ship(_sim, 0)
	_sim.execute(SetShipRouteCommand.new(ship_id, route))
	_sim.tick(0)
	_sim.tick(0)
	var ship := _sim.world.ship(ship_id)
	assert_int(ship.state).is_equal(Ship.State.SAILING)
	assert_bool(ship.waypoints.is_empty()).is_true()
	var saves: SaveSystemScript = auto_free(SaveSystemScript.new())
	saves.save_dir = TEST_DIR
	saves.save_game("icando", {"world": _sim.world.to_dict()})
	var world_data: Dictionary = saves.load_game("icando")["world"]
	var copy := Simulation.new(_sim.config, _sim.data, WorldState.from_dict(world_data, _sim.data))
	copy.free_build = true
	SimFixture.run(_sim, 90.0)
	SimFixture.run(copy, 90.0)
	assert_bool(copy.world.to_dict() == _sim.world.to_dict()).override_failure_message("divergiu depois de carregar içando velas").is_true()
