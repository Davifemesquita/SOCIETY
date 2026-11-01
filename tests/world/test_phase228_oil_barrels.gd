extends GdUnitTestSuite
## Barris de petróleo (Fase 228): cada poço de petróleo ganha as duas células do meio de um lado (nunca a frente), encostadas
## nele; com uma delas bloqueada, os barris vão para o outro lado; outros prédios não têm; o recheio e as bombas deixam as
## células; os barris e a mancha cabem nas duas células.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func test_the_barrels_sit_beside_the_well_never_in_front() -> void:
	for rotation: int in 4:
		_sim = SimFixture.simulation(Vector2i(60, 40))
		_sim.free_build = true
		_sim.ignore_terrain = true
		var id := SimFixture.place(_sim, &"oil_well", Vector2i(20, 15), rotation)
		var record := _sim.world.building(id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var found := OilBarrelView.sites(_sim.world, _sim.data, 0)
		assert_bool(found.has(id)).is_true()
		var site: Array = found[id]
		var pair: Array[Vector2i] = site[0]
		var side: Vector2i = site[1]
		var front := Footprint.front_direction(rotation)
		assert_int(side.x * front.x + side.y * front.y).is_equal(0)
		for cell: Vector2i in pair:
			assert_bool(area.has_point(cell)).is_false()
			assert_bool(area.has_point(cell - side)).is_true()


func test_a_blocked_cell_moves_the_barrels_to_the_other_side() -> void:
	var id := SimFixture.place(_sim, &"oil_well", Vector2i(20, 15), 0)
	var first: Array = OilBarrelView.sites(_sim.world, _sim.data, 0)[id]
	var pair: Array[Vector2i] = first[0]
	SimFixture.road(_sim, pair[0], pair[0] + Vector2i(0, 1))
	var second: Array = OilBarrelView.sites(_sim.world, _sim.data, 0)[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_bool(side_after == -side_before).is_true()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"oil_power_station", Vector2i(5, 15), 0)
	assert_int(OilBarrelView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"oil_well", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.taken_cells(_sim.world, _sim.data, 0)
	var found := OilBarrelView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(2)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_true()


func test_the_barrels_fit_their_cells() -> void:
	var box := OilBarrelView.barrels_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(1.2)
	assert_float(box.position.x).is_greater_equal(-2.0)
	assert_float(box.end.x).is_less_equal(2.0)
	assert_float(box.position.z).is_greater_equal(-1.0)
	assert_float(box.end.z).is_less_equal(1.0)
