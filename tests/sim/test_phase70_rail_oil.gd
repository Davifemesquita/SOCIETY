extends GdUnitTestSuite
## Ferrovia e petróleo (Fase 70): os campos de petróleo saem da semente nas ilhas temperadas (sem mudar a assinatura);
## o poço só vai num campo; trilho não divide célula com prédio nem estrada; o petróleo só anda por trilho — o poço
## ligado à usina por trilho contínuo a abastece e ela produz, o poço sem trilho enche e para, e o petróleo nunca vai
## ao estoque; demolir tira o trilho; o trilho vai no save (o antigo carrega sem trilho).

const STREET := 20


func _sim() -> Simulation:
	var sim := SimFixture.simulation()
	sim.free_build = true
	SimFixture.road(sim, Vector2i(0, STREET), Vector2i(119, STREET))
	# trabalhadores para o poço e a usina (engenheiros) e um campo de petróleo à mão na ilha plana
	for k: int in 8:
		SimFixture.house(sim, 60 + k * 3, STREET, &"engineers", 30.0)
	var grid := sim.world.island(SimFixture.ISLAND)
	grid.oil_spots = PackedInt32Array([grid.index(Vector2i(11, STREET + 2))])
	return sim


## Poço no campo (abaixo da rua) e usina mais adiante; devolve [poço, usina].
func _plant(sim: Simulation) -> Array[int]:
	var well := SimFixture.place(sim, &"oil_well", Vector2i(10, STREET + 1), 0)
	var station := SimFixture.place(sim, &"oil_power_station", Vector2i(30, STREET + 1), 0)
	return [well, station]


## Trilho embaixo dos dois, encostado no lado de baixo de cada lote (o poço tem 3 células de fundo, a usina 5).
func _rail(sim: Simulation) -> void:
	var path: Array[Vector2i] = []
	for x: int in range(10, 35):
		path.append(Vector2i(x, STREET + 6))
	for y: int in range(STREET + 4, STREET + 6):
		path.append(Vector2i(11, y))
	assert_bool(sim.execute(BuildRailCommand.new(SimFixture.ISLAND, path)).ok()).is_true()


func test_oil_fields_come_from_the_seed_on_temperate_islands() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	var again := ArchipelagoGenerator.new_world(1840, config, data)
	var temperate := 0
	for index: int in world.islands.size():
		var grid := world.island(index)
		assert_bool(grid.oil_spots == again.island(index).oil_spots).is_true()
		if world.is_tropical(index, data):
			assert_int(grid.oil_spots.size()).is_equal(0)
			continue
		temperate += 1
		for spot: int in grid.oil_spots:
			var area := Rect2i(grid.cell_at(spot) - Vector2i.ONE, Vector2i(3, 3))
			assert_bool(grid.area_is_land(area)).is_true()
	assert_int(temperate).is_greater(0)
	assert_int(world.island(0).oil_spots.size()).is_equal(OilFields.COUNT)


func test_the_well_needs_an_oil_field_and_rails_block_buildings_and_roads() -> void:
	var sim := _sim()
	var grid := sim.world.island(SimFixture.ISLAND)
	var def := sim.data.building(&"oil_well")
	assert_str(String(PlacementRules.check_terrain(grid, null, def, Vector2i(50, STREET + 1), 0))).is_equal(String(PlacementRules.NEEDS_OIL))
	assert_str(String(PlacementRules.check_terrain(grid, null, def, Vector2i(10, STREET + 1), 0))).is_equal("")
	var cells: Array[Vector2i] = [Vector2i(40, STREET + 3), Vector2i(41, STREET + 3)]
	assert_bool(sim.execute(BuildRailCommand.new(SimFixture.ISLAND, cells)).ok()).is_true()
	assert_str(String(PlacementRules.check_road_cell(grid, Vector2i(40, STREET + 3)))).is_equal(String(PlacementRules.ON_RAIL))
	assert_str(String(PlacementRules.check_area(grid, Rect2i(Vector2i(39, STREET + 2), Vector2i(3, 3))))).is_equal(String(PlacementRules.ON_RAIL))
	# e a estrada bloqueia o trilho
	var on_road: Array[Vector2i] = [Vector2i(5, STREET)]
	assert_str(String(sim.execute(BuildRailCommand.new(SimFixture.ISLAND, on_road)).reason)).is_equal(String(PlacementRules.ON_ROAD))


func test_rails_cost_money_and_planks_and_demolish_removes_them() -> void:
	var sim := _sim()
	SimFixture.port(sim)
	sim.free_build = false
	SimFixture.give(sim, &"planks", 20.0)
	var money := sim.world.money
	var cells: Array[Vector2i] = [Vector2i(40, STREET + 3), Vector2i(41, STREET + 3), Vector2i(42, STREET + 3)]
	assert_bool(sim.execute(BuildRailCommand.new(SimFixture.ISLAND, cells)).ok()).is_true()
	assert_float(sim.world.money).is_equal_approx(money - 3 * sim.config.rail_cost_per_cell, 0.001)
	assert_float(SimFixture.stock(sim, &"planks")).is_equal(18.0)
	assert_bool(sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(40, STREET + 3), Vector2i(3, 1)))).ok()).is_true()
	assert_bool(sim.world.island(SimFixture.ISLAND).has_rail(Vector2i(41, STREET + 3))).is_false()


func test_oil_runs_only_by_rail_to_the_power_station() -> void:
	var sim := _sim()
	var ids := _plant(sim)
	SimFixture.run(sim, 120.0)
	var well := sim.world.building(ids[0])
	var station := sim.world.building(ids[1])
	# sem trilho: o poço enche e para, a usina não recebe nada, o estoque nunca tem petróleo
	assert_int(well.state).is_equal(BuildingRecord.State.OUTPUT_FULL)
	assert_float(station.input_buffer.get(&"oil", 0.0)).is_equal(0.0)
	assert_float(SimFixture.stock(sim, &"oil")).is_equal(0.0)
	_rail(sim)
	var feeds: Array = sim.derived_state().rail_feeds.get(ids[1], [])
	assert_int(feeds.size()).is_equal(1)
	SimFixture.run(sim, 120.0)
	assert_int(station.state).is_equal(BuildingRecord.State.PRODUCING)
	assert_float(SimFixture.stock(sim, &"oil")).is_equal(0.0)


func test_a_broken_rail_cuts_the_supply() -> void:
	var sim := _sim()
	var ids := _plant(sim)
	_rail(sim)
	var feeds: Array = sim.derived_state().rail_feeds.get(ids[1], [])
	assert_int(feeds.size()).is_equal(1)
	sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(20, STREET + 6), Vector2i(1, 1))))
	assert_bool(sim.derived_state().rail_feeds.has(ids[1])).is_false()


func test_rails_go_in_the_save() -> void:
	var sim := _sim()
	var cells: Array[Vector2i] = [Vector2i(40, STREET + 3), Vector2i(41, STREET + 3)]
	sim.execute(BuildRailCommand.new(SimFixture.ISLAND, cells))
	var saved := sim.world.to_dict()
	var loaded := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(loaded).is_not_null()
	assert_bool(loaded.island(SimFixture.ISLAND).has_rail(Vector2i(41, STREET + 3))).is_true()
	# o save de antes da fase carrega sem trilho
	var islands: Array = saved["islands"]
	var first: Dictionary = islands[0]
	first.erase("rails")
	var from_old := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(from_old).is_not_null()
	assert_bool(from_old.island(SimFixture.ISLAND).has_rail(Vector2i(41, STREET + 3))).is_false()
