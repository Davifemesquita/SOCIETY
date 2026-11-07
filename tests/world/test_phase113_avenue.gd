extends GdUnitTestSuite
## Alameda (Fase 113): ao longo das ruas calçadas, a cada AVENUE_EVERY células, as células livres dos lados ganham árvore;
## a rua de terra não tem; o recheio fica fora delas; a vista acompanha a estrada.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 30))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _paved() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(5, 10), Vector2i(40, 10)), true))


func test_paved_streets_get_trees_on_both_sides() -> void:
	_paved()
	var cells := AvenueView.cells(_sim.world, 0)
	assert_int(cells.size()).is_greater(10)
	var grid := _sim.world.island(0)
	var above := 0
	var below := 0
	for cell: Vector2i in cells:
		assert_bool(grid.has_road(cell)).is_false()
		# encostada numa célula calçada da vez (as pontas da avenida também ganham, na linha dela)
		var touches := false
		for side: Vector2i in AvenueView.SIDES:
			var road := cell + side
			if grid.in_bounds(road) and grid.is_paved(road) and posmod(road.x + road.y, AvenueView.AVENUE_EVERY) == 0:
				touches = true
		assert_bool(touches).is_true()
		above += int(cell.y == 9)
		below += int(cell.y == 11)
	# dos dois lados da rua
	assert_int(above).is_greater(0)
	assert_int(below).is_greater(0)

func test_dirt_streets_have_none() -> void:
	SimFixture.road(_sim, Vector2i(5, 10), Vector2i(40, 10))
	assert_int(AvenueView.cells(_sim.world, 0).size()).is_equal(0)


func test_buildings_take_the_place_of_the_trees() -> void:
	_paved()
	var before := AvenueView.cells(_sim.world, 0).size()
	SimFixture.house(_sim, 9, 10, &"workers", 0.0)
	var after := AvenueView.cells(_sim.world, 0)
	assert_int(after.size()).is_less(before)
	for cell: Vector2i in after:
		assert_int(_sim.world.island(0).occupancy[_sim.world.island(0).index(cell)]).is_equal(0)


func test_the_view_follows_the_roads() -> void:
	var view: AvenueView = auto_free(AvenueView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.tree_count()).is_equal(0)
	_paved()
	view._process(0.0)
	assert_int(view.tree_count()).is_equal(AvenueView.cells(_sim.world, 0).size())
