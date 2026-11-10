extends GdUnitTestSuite
## Fase 386: a conferência do mundo (WorldInvariants) passa no mundo certo e pega cada erro plantado.


func _sim_with_buildings() -> Simulation:
	var sim := SimFixture.simulation(Vector2i(120, 40), 50, true)
	SimFixture.port(sim)
	SimFixture.place(sim, &"lumberjack", Vector2i(20, 7))
	SimFixture.house_on_main_road(sim, 30, &"peasants", 5.0)
	return sim


func _problems(sim: Simulation) -> PackedStringArray:
	return WorldInvariants.check(sim.world, sim.data)


func test_a_fresh_world_has_no_problems() -> void:
	var sim := _sim_with_buildings()
	assert_array(Array(_problems(sim))).is_empty()
	for i: int in 200:
		sim.tick(i)
	assert_array(Array(_problems(sim))).is_empty()


func test_the_archipelago_has_no_problems() -> void:
	var world := ArchipelagoGenerator.new_world(1840, GameConfig.get_default(), GameData.get_default())
	assert_array(Array(WorldInvariants.check(world, GameData.get_default()))).is_empty()


func test_bad_money_and_stock_are_caught() -> void:
	var sim := _sim_with_buildings()
	sim.world.money = NAN
	sim.world.economy(0).stock[&"planks"] = -3.0
	var found := "\n".join(_problems(sim))
	assert_str(found).contains("dinheiro")
	assert_str(found).contains("planks")


func test_occupancy_out_of_step_is_caught() -> void:
	var sim := _sim_with_buildings()
	var grid := sim.world.island(0)
	grid.occupancy[grid.index(Vector2i(100, 5))] = 999
	assert_str("\n".join(_problems(sim))).contains("ocupação")


func test_dangling_references_are_caught() -> void:
	var sim := _sim_with_buildings()
	var lumberjack_id := 0
	for record: BuildingRecord in sim.world.buildings.values():
		if record.def_id == &"lumberjack":
			lumberjack_id = record.id
	sim.world.risks_state.fires[4242] = 0
	sim.world.carts[lumberjack_id].warehouse_id = 4242
	sim.world.carts[lumberjack_id].state = Cart.State.OUTBOUND
	sim.world.carts[lumberjack_id].path = PackedInt32Array([1, 2, 3])
	var found := "\n".join(_problems(sim))
	assert_str(found).contains("fogo num prédio que não existe")
	assert_str(found).contains("armazém que não existe")


func test_a_house_with_nan_residents_is_caught() -> void:
	var sim := _sim_with_buildings()
	for record: BuildingRecord in sim.world.buildings.values():
		if record.is_house():
			record.residents = INF
	assert_str("\n".join(_problems(sim))).contains("moradores")
