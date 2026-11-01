extends GdUnitTestSuite
## Monte de carvão na usina (Fase 216): cada usina a carvão ganha as duas células do meio de um lado (o de −X do modelo
## primeiro), encostadas nela e nunca na frente; com uma delas bloqueada, o monte vai para o outro lado; outros prédios não têm;
## o recheio e as bombas deixam as células; o monte fica de pé, encostado na parede e dentro das duas células.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_heap_sits_beside_the_station_never_in_front() -> void:
	for rotation: int in 4:
		_sim = SimFixture.simulation(Vector2i(60, 40))
		_sim.free_build = true
		var id := SimFixture.place(_sim, &"power_station", Vector2i(20, 15), rotation)
		var record := _sim.world.building(id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var found := CoalHeapView.sites(_sim.world, _sim.data, 0)
		assert_bool(found.has(id)).is_true()
		var site: Array = found[id]
		var pair: Array[Vector2i] = site[0]
		var side: Vector2i = site[1]
		var front := Footprint.front_direction(rotation)
		assert_int(side.x * front.x + side.y * front.y).is_equal(0)
		for cell: Vector2i in pair:
			assert_bool(area.has_point(cell)).is_false()
			assert_bool(area.has_point(cell - side)).is_true()
		# as duas células lado a lado ao longo da parede
		assert_int(absi(pair[0].x - pair[1].x) + absi(pair[0].y - pair[1].y)).is_equal(1)


func test_a_blocked_cell_moves_the_heap_to_the_other_side() -> void:
	var id := SimFixture.place(_sim, &"power_station", Vector2i(20, 15), 0)
	var first: Array = CoalHeapView.sites(_sim.world, _sim.data, 0)[id]
	var pair: Array[Vector2i] = first[0]
	SimFixture.road(_sim, pair[0], pair[0] + Vector2i(0, 1))
	var found := CoalHeapView.sites(_sim.world, _sim.data, 0)
	assert_bool(found.has(id)).is_true()
	var second: Array = found[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_bool(side_after == -side_before).is_true()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"oil_power_station", Vector2i(10, 15), 0)
	assert_int(CoalHeapView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"power_station", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.taken_cells(_sim.world, _sim.data, 0)
	var found := CoalHeapView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(2)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_true()


func test_the_heap_leans_on_the_wall_inside_its_cells() -> void:
	var box := CoalHeapView.heap_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.end.y).is_between(CoalHeapView.PEAK_M * 0.9, 2.2)
	# as duas células ao longo da parede (4 m) e uma para fora (de −1 m, a parede, até +1 m)
	assert_float(box.size.x).is_less(4.0)
	assert_float(box.position.z).is_greater_equal(-1.05)
	assert_float(box.end.z).is_less_equal(1.0)
	# o monte é mais alto junto da parede que na frente
	assert_float(CoalHeapView.height_at(-0.75, -0.65)).is_greater(CoalHeapView.height_at(-0.75, 0.8) + 0.5)
