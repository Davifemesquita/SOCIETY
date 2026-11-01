extends GdUnitTestSuite
## Lagar no vinhedo (Fase 240): cada vinhedo ganha as duas células do meio de um lado (nunca a frente), encostadas nele e fora
## das colmeias e do silo; com uma delas bloqueada, o lagar vai para outro lado; outros prédios não têm; o recheio e as bombas
## deixam as células; o lagar cabe nas duas células.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_press_sits_beside_the_vineyard_never_in_front() -> void:
	for rotation: int in 4:
		_sim = SimFixture.simulation(Vector2i(60, 40))
		_sim.free_build = true
		var id := SimFixture.place(_sim, &"vineyard", Vector2i(20, 15), rotation)
		var record := _sim.world.building(id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var found := WinePressView.sites(_sim.world, _sim.data, 0)
		assert_bool(found.has(id)).is_true()
		var site: Array = found[id]
		var pair: Array[Vector2i] = site[0]
		var side: Vector2i = site[1]
		var front := Footprint.front_direction(rotation)
		assert_bool(side == front).is_false()
		var others := BeehiveView.cells(_sim.world, _sim.data, 0)
		var silos := FarmSiloView.cells(_sim.world, _sim.data, 0)
		for cell: Vector2i in pair:
			assert_bool(area.has_point(cell)).is_false()
			assert_bool(area.has_point(cell - side)).is_true()
			assert_bool(others.has(cell)).is_false()
			assert_bool(silos.has(cell)).is_false()


func test_a_blocked_cell_moves_the_press() -> void:
	var id := SimFixture.place(_sim, &"vineyard", Vector2i(20, 15), 0)
	var first: Array = WinePressView.sites(_sim.world, _sim.data, 0)[id]
	var pair: Array[Vector2i] = first[0]
	SimFixture.road(_sim, pair[0], pair[0] + Vector2i(0, 1))
	var found := WinePressView.sites(_sim.world, _sim.data, 0)
	assert_bool(found.has(id)).is_true()
	var second: Array = found[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_bool(side_after == side_before).is_false()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"hop_farm", Vector2i(5, 15), 0)
	assert_int(WinePressView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"vineyard", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.taken_cells(_sim.world, _sim.data, 0)
	var found := WinePressView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(2)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_true()


func test_the_press_fits_its_cells() -> void:
	var box := WinePressView.press_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.end.y).is_less(2.2)
	assert_float(box.position.x).is_greater_equal(-2.0)
	assert_float(box.end.x).is_less_equal(2.0)
	assert_float(box.position.z).is_greater_equal(-1.0)
	assert_float(box.end.z).is_less_equal(1.0)
