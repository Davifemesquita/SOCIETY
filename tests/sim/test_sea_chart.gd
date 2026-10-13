extends GdUnitTestSuite
## Carta náutica (Fase 6): a ilha fecha a água por cima dela, o mar em volta é navegável, o
## caminho contorna a terra e a mesma semente dá a mesma carta.


func test_flat_islands_block_the_water_over_them() -> void:
	var sim := SimFixture.two_islands()
	var chart := sim.harbors().chart
	var main_rect := sim.world.island(0).world_rect()
	assert_bool(chart.is_navigable(chart.cell_of(main_rect.get_center()))).is_false()
	assert_bool(chart.is_navigable(chart.cell_of(main_rect.position + Vector2(1, 1)))).is_false()
	assert_bool(chart.is_navigable(chart.cell_of(main_rect.position - Vector2(10, 10)))).is_true()
	# entre as duas ilhas é mar
	var between := (main_rect.end + sim.world.island(1).world_rect().position) * 0.5
	assert_bool(chart.is_navigable(chart.cell_of(Vector2(between.x, main_rect.get_center().y)))).is_true()


func test_route_goes_around_the_island_by_open_water() -> void:
	var sim := SimFixture.two_islands()
	var chart := sim.harbors().chart
	var rect := sim.world.island(0).world_rect()
	# de oeste para leste da ilha principal: a reta cortaria a terra
	var from := Vector2(rect.position.x - 30.0, rect.get_center().y)
	var to := Vector2(rect.end.x + 30.0, rect.get_center().y)
	var path := chart.route(from, to)
	assert_int(path.size()).is_greater(1)
	var previous := chart.cell_of(from)
	for point: Vector2 in path:
		var cell := chart.cell_of(point)
		assert_bool(chart.is_navigable(cell)).is_true()
		assert_bool(chart.clear_line(previous, cell)).override_failure_message("trecho corta a terra em %s" % point).is_true()
		previous = cell
	assert_float(path[path.size() - 1].distance_to(to)).is_less(chart.cell_m)


func test_same_seed_gives_the_same_chart_and_every_port_is_reachable() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var first := SeaChart.new(ArchipelagoGenerator.new_world(1840, config, data), config)
	var again := SeaChart.new(ArchipelagoGenerator.new_world(1840, config, data), config)
	assert_bool(first.navigable == again.navigable).is_true()
	var sim := Simulation.new(config, data, ArchipelagoGenerator.new_world(1840, config, data))
	var harbors := sim.harbors()
	var main := harbors.anchor(0)
	assert_bool(harbors.chart.is_navigable(harbors.chart.cell_of(main))).is_true()
	for island_id: int in range(1, sim.world.islands.size()):
		var path := harbors.chart.route(main, harbors.anchor(island_id))
		assert_int(path.size()).override_failure_message("ilha %d sem caminho por mar" % island_id).is_greater(0)


func test_rivers_are_too_shallow_for_ships() -> void:
	var config := GameConfig.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, GameData.get_default())
	var chart := SeaChart.new(world, config)
	var grid := world.island(0)
	var river := grid.ground.find(IslandGrid.Ground.RIVER)
	assert_int(river).is_greater_equal(0)
	var point := grid.cell_world(grid.cell_at(river))
	assert_bool(chart.is_navigable(chart.cell_of(Vector2(point.x, point.z)))).is_false()
