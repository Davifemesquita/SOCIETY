extends GdUnitTestSuite
## Produção por ciclo: tempo do ciclo, buffers, motivos de parada, módulos, força de trabalho
## e manutenção.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))


func _state(building_id: int) -> BuildingRecord.State:
	return _sim.world.building(building_id).state


func test_lumberjack_makes_one_ton_per_cycle() -> void:
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(10, 21))
	SimFixture.run_production(_sim, 14.8)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(0.0)
	SimFixture.run_production(_sim, 0.4)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(1.0)
	SimFixture.run_production(_sim, 60.0 - 15.2)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(4.0)
	assert_int(_state(lumberjack)).is_equal(BuildingRecord.State.PRODUCING)


func test_processing_waits_for_input_then_consumes_one_ton() -> void:
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	var sawmill := SimFixture.place(_sim, &"sawmill", Vector2i(10, 21))
	SimFixture.run_production(_sim, 1.0)
	assert_int(_state(sawmill)).is_equal(BuildingRecord.State.NO_INPUT)
	SimFixture.give(_sim, &"wood", 2.0)
	SimFixture.run_production(_sim, 30.2)
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(2.0)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(0.0)


func test_without_road_the_building_stops() -> void:
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(10, 30))
	SimFixture.run_production(_sim, 30.0)
	assert_int(_state(lumberjack)).is_equal(BuildingRecord.State.NO_ROAD)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(0.0)


func test_farm_without_all_fields_does_not_work() -> void:
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	var farm := SimFixture.place(_sim, &"wheat_farm", Vector2i(10, 21))
	SimFixture.place(_sim, &"field", Vector2i(13, 21))
	SimFixture.run_production(_sim, 1.0)
	assert_int(_state(farm)).is_equal(BuildingRecord.State.NO_MODULES)
	assert_int(_sim.derived_state().module_count[farm]).is_equal(1)


func test_farm_with_fields_produces() -> void:
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	var farm := SimFixture.farm(_sim, &"wheat_farm", 10, 20)
	SimFixture.run_production(_sim, 60.2)
	assert_int(_state(farm)).is_equal(BuildingRecord.State.PRODUCING)
	assert_float(SimFixture.stock(_sim, &"wheat")).is_equal(1.0)


func test_a_field_serves_only_one_farm() -> void:
	var first := SimFixture.place(_sim, &"wheat_farm", Vector2i(10, 21))
	var second := SimFixture.place(_sim, &"wheat_farm", Vector2i(16, 21))
	for origin: Vector2i in [Vector2i(13, 21), Vector2i(11, 24), Vector2i(14, 24), Vector2i(11, 16), Vector2i(14, 16)]:
		SimFixture.place(_sim, &"field", origin)
	var derived := _sim.derived_state()
	assert_int(derived.module_count[first]).is_equal(5)
	assert_int(derived.module_count[second]).is_equal(0)


func test_missing_workers_slow_every_building_of_the_class_equally() -> void:
	SimFixture.house(_sim, 60, 20, &"peasants", 7.5)
	var a := SimFixture.place(_sim, &"lumberjack", Vector2i(10, 21))
	var b := SimFixture.place(_sim, &"lumberjack", Vector2i(14, 21))
	SimFixture.run_production(_sim, 1.0)
	assert_float(_sim.world.economy(0).workforce(&"peasants")).is_equal(0.75)
	SimFixture.run_production(_sim, 15.0 / 0.75 - 1.0 + 0.2)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(2.0)
	assert_float(_sim.world.building(a).progress).is_equal_approx(_sim.world.building(b).progress, 0.0001)


func test_upper_class_does_not_replace_lower() -> void:
	SimFixture.house(_sim, 60, 20, &"workers", 20.0)
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(10, 21))
	SimFixture.run_production(_sim, 1.0)
	assert_int(_state(lumberjack)).is_equal(BuildingRecord.State.NO_WORKERS)


func test_output_stops_when_buffer_and_stock_are_full() -> void:
	_sim.config.island_storage_capacity_t = 2
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(10, 21))
	SimFixture.run_production(_sim, 15.0 * 7)
	assert_float(SimFixture.stock(_sim, &"wood")).is_equal(2.0)
	assert_float(_sim.world.building(lumberjack).output_buffer).is_equal(4.0)
	assert_int(_state(lumberjack)).is_equal(BuildingRecord.State.OUTPUT_FULL)


func test_paused_building_stops_and_pays_half_upkeep() -> void:
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	var sawmill := SimFixture.place(_sim, &"sawmill", Vector2i(10, 21))
	_sim.world.money = 1000.0
	SimFixture.run(_sim, 60.0)
	var full := 1000.0 - _sim.world.money
	_sim.execute(SetPausedCommand.new(sawmill, true))
	_sim.world.money = 1000.0
	SimFixture.run(_sim, 60.0)
	var paused := 1000.0 - _sim.world.money
	assert_int(_state(sawmill)).is_equal(BuildingRecord.State.PAUSED)
	assert_float(full).is_greater(paused)
	assert_float(_sim.world.upkeep_per_min).is_equal(15.0 * 0.5)
