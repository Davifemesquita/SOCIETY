extends GdUnitTestSuite
## Fogareiro de castanhas (Fase 234): o fogareiro fica no canto de dentro das esquinas calçadas, numa célula livre do resto
## certo, que nunca é a de uma coluna de anúncios; rua de terra não tem; o carrinho fica de pé e cabe na célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


## A rua de y = 10 e várias ruas de través, uma a cada 5 células.
func _crossings(paved: bool) -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(2, 10), Vector2i(60, 10)), paved))
	for x: int in range(8, 58, 5):
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(x, 2), Vector2i(x, 18)), paved))


func test_the_roasters_stand_in_inner_corners_away_from_the_columns() -> void:
	_crossings(true)
	var found := ChestnutRoasterView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_greater(0)
	var columns := AdColumnView.cells(_sim.world, _sim.data, 0)
	var grid := _sim.world.island(0)
	for cell: Vector2i in found:
		var corner: Vector2i = found[cell]
		assert_int(posmod(cell.x * 7 + cell.y * 11, ChestnutRoasterView.ROASTER_EVERY)).is_equal(ChestnutRoasterView.ROASTER_REST)
		assert_bool(columns.has(cell)).is_false()
		assert_bool(grid.has_road(cell)).is_false()
		assert_int(grid.building_at(cell)).is_equal(0)
		assert_bool(AdColumnView._paved(grid, cell + Vector2i(corner.x, 0))).is_true()
		assert_bool(AdColumnView._paved(grid, cell + Vector2i(0, corner.y))).is_true()


func test_dirt_crossings_have_none() -> void:
	_crossings(false)
	assert_int(ChestnutRoasterView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)


func test_the_cart_stands_in_its_cell() -> void:
	var box := ChestnutRoasterView.roaster_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.end.y).is_less(1.8)
	assert_float(box.size.x).is_less(1.2)
	assert_float(box.size.z).is_less(1.8)
