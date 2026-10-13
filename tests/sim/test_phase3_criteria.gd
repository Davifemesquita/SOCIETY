extends GdUnitTestSuite
## Critérios de pronto da Fase 3: cortar a estrada para a produção que depende dela e o prédio
## mostra o alerta; com carroças, a cadeia do pão ainda roda em 2:1:2; salvar e carregar com
## carroças no meio do caminho volta idêntico e segue igual; o save da Fase 2 abre.

const SaveSystemScript := preload("res://core/save_system.gd")
const TEST_DIR := "user://test_saves_phase3"

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(140, 40), 50, true)
	SimFixture.port(_sim)
	for i: int in 4:
		SimFixture.house_on_main_road(_sim, 100 + i * 3, &"peasants", 10.0)
	for i: int in 6:
		SimFixture.house_on_main_road(_sim, 115 + i * 3, &"workers", 20.0)


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
	DirAccess.remove_absolute(TEST_DIR)


func test_cutting_the_road_stops_production_and_raises_the_alert() -> void:
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(30, 7))
	SimFixture.run(_sim, 60.0)
	assert_int(_sim.world.building(lumberjack).state).is_equal(BuildingRecord.State.PRODUCING)
	var states: Array[int] = []
	EventBus.building_state_changed.connect(func(building_id: int) -> void:
		if building_id == lumberjack:
			states.append(_sim.world.building(lumberjack).state))
	_sim.execute(DemolishCommand.new(0, Rect2i(20, 6, 1, 1)))
	SimFixture.run(_sim, 1.0)
	assert_int(_sim.world.building(lumberjack).state).is_equal(BuildingRecord.State.NO_WAREHOUSE)
	assert_array(states).contains([BuildingRecord.State.NO_WAREHOUSE])
	var progress := _sim.world.building(lumberjack).progress
	SimFixture.run(_sim, 60.0)
	assert_float(_sim.world.building(lumberjack).progress).override_failure_message("a produção parou").is_equal(progress)
	SimFixture.road(_sim, Vector2i(20, 6), Vector2i(20, 6))
	SimFixture.run(_sim, 1.0)
	assert_int(_sim.world.building(lumberjack).state).is_equal(BuildingRecord.State.PRODUCING)


func test_bread_chain_still_runs_two_one_two_with_carts() -> void:
	# moinho e padarias ficam a mais de 40 células do entreposto: precisam do armazém ao lado
	SimFixture.place(_sim, &"warehouse", Vector2i(46, 7))
	SimFixture.farm(_sim, &"wheat_farm", 10, 6)
	SimFixture.farm(_sim, &"wheat_farm", 30, 6)
	var mill := SimFixture.place(_sim, &"mill", Vector2i(50, 7))
	var bakeries := [SimFixture.place(_sim, &"bakery", Vector2i(56, 7)), SimFixture.place(_sim, &"bakery", Vector2i(62, 7))]
	SimFixture.run_production(_sim, 300.0)
	SimFixture.give(_sim, &"bread", 0.0)
	var bread := 0.0
	var max_wheat := 0.0
	var max_flour := 0.0
	for minute: int in 55:
		SimFixture.run_production(_sim, 60.0)
		bread += SimFixture.stock(_sim, &"bread")
		SimFixture.give(_sim, &"bread", 0.0)
		max_wheat = maxf(max_wheat, SimFixture.stock(_sim, &"wheat"))
		max_flour = maxf(max_flour, SimFixture.stock(_sim, &"flour"))
	# 2 padarias a 1 t/min por 55 min, com carroças: a entrega chega com atraso, não com perda
	assert_float(bread).is_between(106.0, 112.0)
	assert_float(max_wheat).is_less_equal(6.0)
	assert_float(max_flour).is_less_equal(6.0)
	for building_id: int in [mill] + bakeries:
		assert_float(_sim.world.building(building_id).productivity).override_failure_message("prédio %d" % building_id).is_greater(0.95)


func test_save_and_load_with_carts_on_the_road() -> void:
	SimFixture.place(_sim, &"lumberjack", Vector2i(30, 7))
	SimFixture.place(_sim, &"sawmill", Vector2i(34, 7))
	SimFixture.place(_sim, &"warehouse", Vector2i(70, 7))
	SimFixture.run(_sim, 47.3)
	var away := _sim.world.carts.values().filter(func(cart: Cart) -> bool: return cart.is_away())
	assert_int(away.size()).is_greater(0)
	var saves: SaveSystemScript = auto_free(SaveSystemScript.new())
	saves.save_dir = TEST_DIR
	saves.save_game("carrocas", {"world": _sim.world.to_dict()})
	var world_data: Dictionary = saves.load_game("carrocas")["world"]
	var restored := WorldState.from_dict(world_data, _sim.data)
	assert_object(restored).is_not_null()
	assert_bool(restored.to_dict() == _sim.world.to_dict()).is_true()
	var copy := Simulation.new(_sim.config, _sim.data, restored)
	SimFixture.run(_sim, 90.0)
	SimFixture.run(copy, 90.0)
	assert_bool(copy.world.to_dict() == _sim.world.to_dict()).override_failure_message("a simulação divergiu depois de carregar").is_true()


func test_phase_two_save_opens_and_waits_for_the_trading_post() -> void:
	var phase_two := {"world": {
		"islands": [{"size": Vector2i(140, 40), "roads": PackedInt32Array([6 * 140 + 30, 6 * 140 + 31, 6 * 140 + 32]),
			"economy": {"profile": &"test_island", "stock": {&"planks": 40.0}, "category_supply": {}, "good_supply": {}, "shortage_announced": {}}}],
		"buildings": [{"id": 1, "def": &"lumberjack", "island": 0, "origin": Vector2i(30, 7), "rotation": 0, "paused": false,
			"production": {"in_cycle": false, "progress": 0.0, "input_buffer": {}, "output_buffer": 0.0, "productivity": 0.0}}],
		"next_building_id": 2, "money": 1000.0, "tax_levels": {}, "tick": 0,
	}}
	var world_data: Dictionary = SaveMigrations.from_3_to_4(SaveMigrations.from_2_to_3(phase_two))["world"]
	var world := WorldState.from_dict(world_data, GameData.get_default())
	assert_object(world).is_not_null()
	assert_object(world.cart(1)).is_not_null()
	var sim := Simulation.new(_sim.config, _sim.data, world)
	sim.free_build = false
	sim.run_ticks(5)
	assert_int(world.building(1).state).is_equal(BuildingRecord.State.NO_WAREHOUSE)
	assert_str(sim.execute(PlaceBuildingCommand.new(0, &"sawmill", Vector2i(40, 7), 0)).reason).is_equal(PlacementRules.NEEDS_TRADING_POST)
