extends GdUnitTestSuite
## Critérios de pronto da Fase 2: a cadeia do pão roda em 2:1:2 por uma hora de jogo, as
## estatísticas mostram t/min corretos, e salvar e carregar a economia volta idêntico.

const SaveSystemScript := preload("res://core/save_system.gd")
const TEST_DIR := "user://test_saves_phase2"

var _sim: Simulation
var _farms: Array[int] = []
var _mill: int
var _bakeries: Array[int] = []


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(140, 40), 100000)
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(139, 20))
	_farms = [SimFixture.farm(_sim, &"wheat_farm", 8, 20), SimFixture.farm(_sim, &"wheat_farm", 34, 20)]
	_mill = SimFixture.place(_sim, &"mill", Vector2i(60, 21))
	_bakeries = [SimFixture.place(_sim, &"bakery", Vector2i(66, 21)), SimFixture.place(_sim, &"bakery", Vector2i(72, 21))]
	for i: int in 3:
		SimFixture.house(_sim, 80 + i * 3, 20, &"peasants", 10.0)
	for i: int in 5:
		SimFixture.house(_sim, 95 + i * 3, 20, &"workers", 20.0)


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
	DirAccess.remove_absolute(TEST_DIR)


func test_bread_chain_runs_two_one_two_for_an_hour() -> void:
	SimFixture.run_production(_sim, 300.0)
	var bread_at_five := SimFixture.stock(_sim, &"bread")
	var max_wheat := 0.0
	var max_flour := 0.0
	for minute: int in 55:
		SimFixture.run_production(_sim, 60.0)
		max_wheat = maxf(max_wheat, SimFixture.stock(_sim, &"wheat"))
		max_flour = maxf(max_flour, SimFixture.stock(_sim, &"flour"))
	# depois de aquecer, 2 padarias a 1 t/min: 110 t em 55 min, sem sobra de trigo nem de farinha
	assert_float(SimFixture.stock(_sim, &"bread") - bread_at_five).is_between(109.0, 111.0)
	assert_float(max_wheat).is_less_equal(2.0)
	assert_float(max_flour).is_less_equal(2.0)
	for building_id: int in _farms + [_mill] + _bakeries:
		assert_float(_sim.world.building(building_id).productivity).override_failure_message("prédio %d" % building_id).is_greater(0.99)


func test_statistics_show_correct_tons_per_minute() -> void:
	SimFixture.run_production(_sim, 600.0)
	var report := _sim.statistics()
	for good: StringName in [&"wheat", &"flour", &"bread"]:
		assert_float(report.line(good).produced).override_failure_message(str(good)).is_equal_approx(2.0, 0.0001)
		assert_float(report.line(good).potential).override_failure_message(str(good)).is_equal_approx(2.0, 0.0001)
	assert_float(report.line(&"wheat").consumed_by_buildings).is_equal_approx(2.0, 0.0001)
	assert_float(report.line(&"flour").consumed_by_buildings).is_equal_approx(2.0, 0.0001)
	assert_float(report.line(&"bread").consumed()).is_equal(0.0)
	assert_int(report.population[&"peasants"]).is_equal(30)
	assert_int(report.population[&"workers"]).is_equal(100)


func test_statistics_count_house_consumption() -> void:
	# peixe é a única opção de alimento em estoque: as duas classes comem só peixe
	# o consumo mostrado é média de 20 s: depois de 2 min acompanha os moradores de agora
	SimFixture.give(_sim, &"fish", 100.0)
	SimFixture.run(_sim, 120.0)
	var report := _sim.statistics()
	assert_float(report.line(&"fish").consumed_by_houses).is_equal_approx(SimFixture.residents(_sim) * 0.005, 0.02)


func test_save_and_load_economy_without_difference() -> void:
	SimFixture.give(_sim, &"fish", 37.5)
	SimFixture.run(_sim, 333.0)
	_sim.execute(SetTaxLevelCommand.new(&"workers", WorldState.TaxLevel.LOW))
	_sim.execute(SetPausedCommand.new(_bakeries[1], true))
	var saves: SaveSystemScript = auto_free(SaveSystemScript.new())
	saves.save_dir = TEST_DIR
	assert_int(saves.save_game("economia", {"world": _sim.world.to_dict()})).is_equal(OK)
	var loaded := saves.load_game("economia")
	var world_data: Dictionary = loaded["world"]
	var restored := WorldState.from_dict(world_data, _sim.data)
	assert_object(restored).is_not_null()
	assert_bool(restored.to_dict() == _sim.world.to_dict()).is_true()
	var copy := Simulation.new(_sim.config, _sim.data, restored)
	SimFixture.run(_sim, 120.0)
	SimFixture.run(copy, 120.0)
	assert_bool(copy.world.to_dict() == _sim.world.to_dict()).override_failure_message("a simulação divergiu depois de carregar").is_true()


func test_phase_one_save_migrates_to_phase_two() -> void:
	var phase_one := {"world": {
		"islands": [{"size": Vector2i(250, 250), "roads": PackedInt32Array([0, 1, 2])}],
		"buildings": [{"id": 1, "def": &"placeholder_house", "island": 0, "origin": Vector2i(5, 5), "rotation": 0}],
		"next_building_id": 2,
	}}
	var migrated := SaveMigrations.from_5_to_6(SaveMigrations.from_4_to_5(SaveMigrations.from_3_to_4(SaveMigrations.from_2_to_3(SaveMigrations.from_1_to_2(phase_one)))))
	var world_data: Dictionary = migrated["world"]
	var world := WorldState.from_dict(world_data, GameData.get_default())
	assert_object(world).is_not_null()
	assert_int(world.buildings.size()).is_equal(0)
	assert_int(world.island(0).road_cells().size()).is_equal(3)
	assert_float(world.money).is_equal(50000.0)
	assert_float(world.economy(0).amount(&"planks")).is_equal(40.0)
