extends GdUnitTestSuite
## Lençóis no hospital (Fase 223): cada hospital ganha as duas células do meio de um lado (nunca a frente), encostadas
## nele; com uma delas bloqueada, os varais vão para o outro lado; outros prédios não têm; o recheio e as bombas deixam as
## células; os varais e os lençóis cabem nas duas células, sem lençol arrastando no chão.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_linen_hangs_beside_the_hospital_never_in_front() -> void:
	for rotation: int in 4:
		_sim = SimFixture.simulation(Vector2i(60, 40))
		_sim.free_build = true
		var id := SimFixture.place(_sim, &"hospital", Vector2i(20, 15), rotation)
		var record := _sim.world.building(id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var found := LinenView.sites(_sim.world, _sim.data, 0)
		assert_bool(found.has(id)).is_true()
		var site: Array = found[id]
		var pair: Array[Vector2i] = site[0]
		var side: Vector2i = site[1]
		var front := Footprint.front_direction(rotation)
		assert_int(side.x * front.x + side.y * front.y).is_equal(0)
		for cell: Vector2i in pair:
			assert_bool(area.has_point(cell)).is_false()
			assert_bool(area.has_point(cell - side)).is_true()


func test_a_blocked_cell_moves_the_linen_to_the_other_side() -> void:
	var id := SimFixture.place(_sim, &"hospital", Vector2i(20, 15), 0)
	var first: Array = LinenView.sites(_sim.world, _sim.data, 0)[id]
	var pair: Array[Vector2i] = first[0]
	SimFixture.road(_sim, pair[1], pair[1] + Vector2i(0, 1))
	var second: Array = LinenView.sites(_sim.world, _sim.data, 0)[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_bool(side_after == -side_before).is_true()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"church", Vector2i(5, 15), 0)
	assert_int(LinenView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"hospital", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.taken_cells(_sim.world, _sim.data, 0)
	var found := LinenView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(2)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_true()


func test_the_lines_and_the_sheets_fit_their_cells() -> void:
	var box := LinenView.linen_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.03)
	assert_float(box.end.y).is_less(LinenView.LINE_M + 0.3)
	assert_float(box.position.x).is_greater_equal(-2.0)
	assert_float(box.end.x).is_less_equal(2.0)
	assert_float(box.position.z).is_greater_equal(-1.0)
	assert_float(box.end.z).is_less_equal(1.0)
	# a barra do lençol fica bem acima do chão e os lençóis cabem no varal
	assert_float(LinenView.LINE_M - LinenView.SHEET_H_M - 0.05).is_greater(0.5)
	assert_float(LinenView.SHEETS * LinenView.SHEET_W_M).is_less(LinenView.LINE_X * 2.0 - 0.3)
