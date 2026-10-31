extends GdUnitTestSuite
## Terreiro do lenhador (Fase 148): cada lenhador ganha uma célula encostada num lado (nunca na frente), livre; com a mata
## nela, a clareira a corta inteira, sem toco; outros prédios não têm.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_each_lumberjack_gets_a_yard_cell_beside_it() -> void:
	for rotation: int in 4:
		var sim := SimFixture.simulation()
		sim.free_build = true
		var id := SimFixture.place(sim, &"lumberjack", Vector2i(20, 10), rotation)
		var record := sim.world.building(id)
		var area := Footprint.rect(record.origin, Vector2i(3, 3), rotation)
		var found := LumberYardView.cells(sim.world, sim.data, 0)
		assert_int(found.size()).is_equal(1)
		var cell: Vector2i = found.keys()[0]
		var toward: Vector2i = found[cell]
		assert_bool(area.has_point(cell)).is_false()
		# olha para o lenhador, encostada nele
		assert_bool(area.has_point(cell + toward)).is_true()
		# nunca na frente (a porta e a rua)
		assert_bool(-toward == Footprint.front_direction(rotation)).is_false()


func test_a_road_moves_the_yard() -> void:
	SimFixture.place(_sim, &"lumberjack", Vector2i(20, 10), 0)
	var first: Vector2i = LumberYardView.cells(_sim.world, _sim.data, 0).keys()[0]
	SimFixture.road(_sim, first, first + Vector2i(0, 1))
	var second: Vector2i = LumberYardView.cells(_sim.world, _sim.data, 0).keys()[0]
	assert_bool(second == first).is_false()


func test_other_buildings_have_no_yard() -> void:
	SimFixture.place(_sim, &"bakery", Vector2i(20, 10))
	SimFixture.place(_sim, &"fishery", Vector2i(40, 0))
	assert_int(LumberYardView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)


func test_the_clearing_cuts_the_yard_without_a_stump() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([90, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, config, GameData.get_default()))
	sim.free_build = true
	sim.ignore_terrain = true
	var grid := sim.world.island(0)
	# um lenhador onde a célula do terreiro tem mata
	var placed := -1
	for y: int in range(6, grid.size.y - 9, 3):
		for x: int in range(6, grid.size.x - 9, 3):
			if placed >= 0:
				break
			if grid.trees_in(Rect2i(x - 1, y - 1, 5, 5)) < 20:
				continue
			var result := sim.execute(PlaceBuildingCommand.new(0, &"lumberjack", Vector2i(x, y), 0))
			if not result.ok():
				continue
			var pair: Variant = LumberYardView.cell_of(sim.world, sim.data, sim.world.building(result.placed[0]))
			var spot := Vector2i(-1, -1)
			if pair is Array:
				var both: Array = pair
				spot = both[0]
			if pair is Array and grid.trees[grid.index(spot)] > 0:
				placed = result.placed[0]
			else:
				# sem mata no terreiro: tira e tenta outro lugar
				sim.execute(DemolishCommand.new(0, Rect2i(x, y, 3, 3)))
	assert_int(placed).is_greater(0)
	var yard_pair: Array = LumberYardView.cell_of(sim.world, sim.data, sim.world.building(placed))
	var yard: Vector2i = yard_pair[0]
	var cut := StumpView.cut_cells(sim.world, sim.data, config, 0)
	assert_bool(cut.has(yard)).is_true()
	var stumps: StumpView = auto_free(StumpView.new())
	add_child(stumps)
	stumps.setup(sim)
	# um toco por árvore em cada célula cortada, menos na do terreiro
	var expected := 0
	for cell: Vector2i in cut:
		if cell != yard:
			expected += mini(grid.trees[grid.index(cell)], TreeView.DRAWN_PER_CELL)
	assert_int(stumps.stump_count()).is_equal(expected)
