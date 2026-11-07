extends GdUnitTestSuite
## Barris na cervejaria (Fase 221): a cervejaria, as destilarias e a adega ganham as duas células do meio de um lado (nunca a
## frente), encostadas nelas; com uma delas bloqueada, a pilha vai para o outro lado; outros prédios não têm; o recheio e as
## bombas deixam as células; a pirâmide e os barris de pé cabem nas duas células.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_barrels_sit_beside_the_brewery_never_in_front() -> void:
	for rotation: int in 4:
		_sim = SimFixture.simulation(Vector2i(60, 40))
		_sim.free_build = true
		var id := SimFixture.place(_sim, &"brewery", Vector2i(20, 15), rotation)
		var record := _sim.world.building(id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var found := BarrelRackView.sites(_sim.world, _sim.data, 0)
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
	var id := SimFixture.place(_sim, &"brewery", Vector2i(20, 15), 0)
	var first: Array = BarrelRackView.sites(_sim.world, _sim.data, 0)[id]
	var pair: Array[Vector2i] = first[0]
	SimFixture.road(_sim, pair[1], pair[1] + Vector2i(0, 1))
	var second: Array = BarrelRackView.sites(_sim.world, _sim.data, 0)[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_bool(side_after == -side_before).is_true()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"church", Vector2i(5, 15), 0)
	assert_int(BarrelRackView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"brewery", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.taken_cells(_sim.world, _sim.data, 0)
	var found := BarrelRackView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(2)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_true()


func test_every_vat_building_gets_a_pile() -> void:
	var x := 2
	for kind: StringName in BarrelRackView.KINDS:
		SimFixture.place(_sim, kind, Vector2i(x, 15), 0)
		x += 8
	assert_int(BarrelRackView.sites(_sim.world, _sim.data, 0).size()).is_equal(BarrelRackView.KINDS.size())


func test_the_pile_fits_its_cells() -> void:
	var box := BarrelRackView.rack_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(2.2)
	assert_float(box.position.x).is_greater_equal(-2.0)
	assert_float(box.end.x).is_less_equal(2.0)
	assert_float(box.position.z).is_greater_equal(-1.0)
	assert_float(box.end.z).is_less_equal(1.0)
	# cada fileira da pirâmide tem um barril a menos que a de baixo e cabe sobre ela
	for row: int in range(1, BarrelRackView.ROWS.size()):
		assert_int(BarrelRackView.ROWS[row]).is_equal(BarrelRackView.ROWS[row - 1] - 1)
