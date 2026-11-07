extends GdUnitTestSuite
## Ramas de tecido (Fase 208): cada tecelagem ganha três células em fila encostadas no meio de um lado (o de trás primeiro);
## com uma delas bloqueada, a fila vai para outro lado; outros prédios não têm; o recheio deixa as células; a rama cabe na fila.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_tenters_line_up_behind_the_weavery() -> void:
	var id := SimFixture.place(_sim, &"weavery", Vector2i(20, 15), 0)
	var record := _sim.world.building(id)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var found := TenterView.sites(_sim.world, _sim.data, 0)
	assert_bool(found.has(id)).is_true()
	var site: Array = found[id]
	var side: Vector2i = site[1]
	# atrás: o contrário da frente
	assert_bool(side == -Footprint.front_direction(record.rotation)).is_true()
	var cells := TenterView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_equal(3)
	for cell: Vector2i in cells:
		assert_bool(area.has_point(cell)).is_false()
		assert_bool(area.has_point(cell - side)).is_true()
		assert_int(_sim.world.island(0).building_at(cell)).is_equal(0)


func test_a_blocked_cell_moves_the_tenters() -> void:
	var id := SimFixture.place(_sim, &"weavery", Vector2i(20, 15), 0)
	var first: Array = TenterView.sites(_sim.world, _sim.data, 0)[id]
	var middle: Vector2i = first[0]
	SimFixture.road(_sim, middle, middle + Vector2i(0, 1))
	var second: Array = TenterView.sites(_sim.world, _sim.data, 0)[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_bool(side_after == side_before).is_false()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"bakery", Vector2i(20, 15), 0)
	assert_int(TenterView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"weavery", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	for cell: Vector2i in TenterView.cells(_sim.world, _sim.data, 0):
		assert_bool(doors.has(cell)).is_true()


func test_the_tenter_fits_its_row() -> void:
	var box := TenterView.tenter_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.001)
	# três células de 2 m ao comprido, uma de largura
	assert_float(box.size.x).is_less(6.0)
	assert_float(box.size.z).is_less(2.0)
	assert_float(box.end.y).is_between(TenterView.TOP_M, TenterView.TOP_M + 0.2)
