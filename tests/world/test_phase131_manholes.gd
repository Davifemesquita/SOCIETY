extends GdUnitTestSuite
## Bueiros (Fase 131): só nas ruas de paralelepípedo, no meio de uma rua reta (nunca na esquina nem na ponta), pelo desenho
## da grade; a rua de terra não tem; a vista acompanha a estrada.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_manholes_sit_mid_street_on_paved_roads() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(5, 20), Vector2i(60, 20)), true))
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(30, 5), Vector2i(30, 35)), true))
	var grid := _sim.world.island(0)
	var cells := ManholeView.cells(grid)
	assert_int(cells.size()).is_greater(3)
	for cell: Vector2i in cells:
		assert_bool(grid.is_paved(cell)).is_true()
		var along_x := grid.has_road(cell + Vector2i(1, 0)) and grid.has_road(cell + Vector2i(-1, 0))
		var along_y := grid.has_road(cell + Vector2i(0, 1)) and grid.has_road(cell + Vector2i(0, -1))
		# rua reta: uma direção só (o cruzamento fica de fora)
		assert_bool(along_x != along_y).is_true()
		assert_int(posmod(5 * cell.x + 3 * cell.y, ManholeView.MANHOLE_EVERY)).is_equal(0)


func test_dirt_roads_have_none() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(5, 20), Vector2i(60, 20)), false))
	assert_int(ManholeView.cells(_sim.world.island(0)).size()).is_equal(0)


func test_the_view_follows_the_roads() -> void:
	var view: ManholeView = auto_free(ManholeView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.cover_count()).is_equal(0)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(5, 20), Vector2i(60, 20)), true))
	view.rebuild()
	assert_int(view.cover_count()).is_equal(ManholeView.cells(_sim.world.island(0)).size())
	assert_int(view.cover_count()).is_greater(0)


func test_the_cover_sits_above_the_paving() -> void:
	# o calçamento da grade dual fica PavedDual.LIFT_M acima do chão: abaixo dele a tampa sumia
	assert_float(ManholeView.LIFT_M).is_greater(PavedDual.LIFT_M)
	assert_float(ManholeView.LIFT_M).is_less(PavedDual.LIFT_M + PavedDual.CURB_HEIGHT_M)


func test_no_cover_under_a_lamp_or_a_pole() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(5, 20), Vector2i(100, 20)), true))
	for cell: Vector2i in ManholeView.cells(_sim.world.island(0)):
		var rest := posmod(cell.x + 3 * cell.y, LampView.LAMP_EVERY)
		assert_int(rest).is_not_equal(0)
		assert_int(rest).is_not_equal(PowerLineView.POLE_REST)
