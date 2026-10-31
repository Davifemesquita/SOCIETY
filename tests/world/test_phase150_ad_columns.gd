extends GdUnitTestSuite
## Coluna de anúncios (Fase 150): a coluna fica no canto de dentro das esquinas calçadas, numa célula livre, uma a cada
## COLUMN_EVERY pelo desenho; rua de terra não tem; um prédio na célula a tira.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


## Duas ruas que se cruzam em (20, 10): a de y = 10 e a de x = 20.
func _crossing(paved: bool) -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(2, 10), Vector2i(40, 10)), paved))
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(20, 1), Vector2i(20, 30)), paved))


func test_the_columns_stand_in_the_inner_corners_of_paved_crossings() -> void:
	_crossing(true)
	var found := AdColumnView.cells(_sim.world, _sim.data, 0)
	assert_bool(found.has(Vector2i(21, 9))).is_true()
	assert_that(found[Vector2i(21, 9)]).is_equal(Vector2i(-1, 1))
	var grid := _sim.world.island(0)
	for cell: Vector2i in found:
		var corner: Vector2i = found[cell]
		assert_int(posmod(cell.x * 7 + cell.y * 11, AdColumnView.COLUMN_EVERY)).is_equal(0)
		assert_bool(grid.has_road(cell)).is_false()
		assert_int(grid.building_at(cell)).is_equal(0)
		# os dois lados da esquina são rua calçada
		assert_bool(AdColumnView._paved(grid, cell + Vector2i(corner.x, 0))).is_true()
		assert_bool(AdColumnView._paved(grid, cell + Vector2i(0, corner.y))).is_true()


func test_dirt_crossings_have_no_columns() -> void:
	_crossing(false)
	assert_int(AdColumnView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)


func test_a_building_on_the_corner_takes_the_column_away() -> void:
	_crossing(true)
	SimFixture.place(_sim, &"house", Vector2i(21, 7), 0)
	assert_bool(AdColumnView.cells(_sim.world, _sim.data, 0).has(Vector2i(21, 9))).is_false()


func test_the_view_draws_the_columns() -> void:
	_crossing(true)
	var view: AdColumnView = auto_free(AdColumnView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.column_count()).is_equal(AdColumnView.cells(_sim.world, _sim.data, 0).size())
	assert_int(view.column_count()).is_greater(0)
