extends GdUnitTestSuite
## Secadouro de peixe (Fase 202): cada cabana de pesca das ilhas temperadas ganha uma célula livre encostada nela, de um dos
## lados, na fileira da terra (o contrário das redes); fora das redes; com a célula bloqueada, vai para outra; outros prédios e
## as ilhas tropicais não têm; o recheio deixa a célula; a peça cabe na célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_the_rack_goes_beside_the_hut_toward_the_land() -> void:
	# a ilha plana tem mar em volta: a cabana encostada na borda de cima (y = 0) olha o mar para −z
	var id := SimFixture.place(_sim, &"fishery", Vector2i(20, 0), 0)
	var record := _sim.world.building(id)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var found := FishRackView.sites(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(1)
	var cell: Vector2i = found.keys()[0]
	var out: Vector3 = found[cell]
	assert_vector(out).is_equal_approx(Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.001)
	assert_bool(area.has_point(cell)).is_false()
	assert_bool(area.grow(1).has_point(cell)).is_true()
	# de um lado da cabana, na fileira de trás (a da terra), e fora das redes
	assert_bool(cell.x < area.position.x or cell.x >= area.end.x).is_true()
	assert_int(cell.y).is_equal(area.end.y - 1)
	assert_bool(FishNetView.cells(_sim.world, _sim.data, 0).has(cell)).is_false()


func test_a_taken_cell_moves_the_rack() -> void:
	SimFixture.place(_sim, &"fishery", Vector2i(20, 0), 0)
	var first: Vector2i = FishRackView.sites(_sim.world, _sim.data, 0).keys()[0]
	SimFixture.road(_sim, first, first + Vector2i(0, 1))
	var found := FishRackView.sites(_sim.world, _sim.data, 0)
	if not found.is_empty():
		assert_bool(found.keys()[0] == first).is_false()


func test_other_buildings_and_the_tropics_have_none() -> void:
	SimFixture.place(_sim, &"lumberjack", Vector2i(20, 10))
	SimFixture.place(_sim, &"pier", Vector2i(40, 0))
	assert_int(FishRackView.sites(_sim.world, _sim.data, 0).size()).is_equal(0)
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([60])
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, config, GameData.get_default()))
	sim.free_build = true
	for index: int in sim.world.islands.size():
		if sim.world.is_tropical(index, sim.data):
			var grid := sim.world.island(index)
			var found := SiteFinder.find(sim, &"fishery", index, grid.size / 2)
			if not found.is_empty():
				var origin: Vector2i = found[0]
				var rotation: int = found[1]
				sim.execute(PlaceBuildingCommand.new(index, &"fishery", origin, rotation))
			assert_int(FishRackView.sites(sim.world, sim.data, index).size()).is_equal(0)


func test_the_scatter_keeps_off_and_the_rack_fits() -> void:
	SimFixture.place(_sim, &"fishery", Vector2i(20, 0), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	for cell: Vector2i in FishRackView.cells(_sim.world, _sim.data, 0):
		assert_bool(doors.has(cell)).is_true()
	var box := FishRackView.rack_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.size.x).is_less(2.0)
	assert_float(box.size.z).is_less(2.0)
	assert_float(box.end.y).is_between(FishRackView.TOP_M, FishRackView.TOP_M + 0.3)
