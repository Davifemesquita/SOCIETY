extends GdUnitTestSuite
## Desfazer o trilho (Fase 72): o trilho posto volta atrás com o dinheiro e as tábuas, e o refazer o põe de novo; o
## trilho demolido volta com o desfazer; o desfazer é recusado se o trilho mudou desde então.

const ROW := 23


func _sim() -> Simulation:
	var sim := SimFixture.simulation()
	SimFixture.port(sim)
	sim.free_build = false
	SimFixture.give(sim, &"planks", 20.0)
	return sim


func _cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x: int in range(40, 46):
		cells.append(Vector2i(x, ROW))
	return cells


func test_undo_and_redo_laying_rail() -> void:
	var sim := _sim()
	var grid := sim.world.island(SimFixture.ISLAND)
	var money := sim.world.money
	assert_bool(sim.execute_undoable(BuildRailCommand.new(SimFixture.ISLAND, _cells())).ok()).is_true()
	assert_int(grid.rail_cells().size()).is_equal(6)
	assert_bool(sim.undo_last().ok()).is_true()
	assert_int(grid.rail_cells().size()).is_equal(0)
	assert_float(sim.world.money).is_equal_approx(money, 0.001)
	assert_float(SimFixture.stock(sim, &"planks")).is_equal(20.0)
	assert_bool(sim.redo_last().ok()).is_true()
	assert_int(grid.rail_cells().size()).is_equal(6)
	assert_float(sim.world.money).is_equal_approx(money - 6 * sim.config.rail_cost_per_cell, 0.001)


func test_undo_brings_demolished_rail_back() -> void:
	var sim := _sim()
	var grid := sim.world.island(SimFixture.ISLAND)
	sim.execute(BuildRailCommand.new(SimFixture.ISLAND, _cells()))
	assert_bool(sim.execute_undoable(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(41, ROW), Vector2i(3, 1)))).ok()).is_true()
	assert_bool(grid.has_rail(Vector2i(42, ROW))).is_false()
	var result := sim.undo_last()
	assert_bool(result.ok()).is_true()
	assert_bool(result.rails_changed).is_true()
	assert_int(grid.rail_cells().size()).is_equal(6)


func test_undo_is_refused_when_the_rail_changed() -> void:
	var sim := _sim()
	var grid := sim.world.island(SimFixture.ISLAND)
	sim.execute_undoable(BuildRailCommand.new(SimFixture.ISLAND, _cells()))
	# alguém tirou um pedaço fora do histórico
	sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(43, ROW), Vector2i(1, 1))))
	assert_str(String(sim.undo_last().reason)).is_equal(String(UndoHistory.CHANGED))
	assert_int(grid.rail_cells().size()).is_equal(5)
