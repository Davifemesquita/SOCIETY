extends GdUnitTestSuite
## Vagoneta e rejeito (Fase 136): cada mina ganha duas células em linha encostadas num lado, livres; o trilho sai da parede
## e vai até a beira do monte; a vagoneta sai cheia, vira na ponta e volta vazia só com a mina produzindo; outros prédios
## não têm.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_each_mine_gets_two_free_cells_in_line_beside_it() -> void:
	for rotation: int in 4:
		var sim := SimFixture.simulation()
		sim.free_build = true
		var id := SimFixture.place(sim, &"coal_mine", Vector2i(20, 10), rotation)
		var record := sim.world.building(id)
		var area := Footprint.rect(record.origin, sim.def_of(record).size, record.rotation)
		var found := SpoilTipView.sites(sim.world, sim.data, 0)
		assert_bool(found.has(id)).is_true()
		var site: Array = found[id]
		var first: Vector2i = site[0]
		var side: Vector2i = site[1]
		assert_bool(area.has_point(first)).is_false()
		assert_bool(area.has_point(first - side)).is_true()
		assert_int(side.length_squared()).is_equal(1)
		# nunca para o lado da frente (a porta e a rua)
		assert_bool(side == Footprint.front_direction(record.rotation)).is_false()
		var cells := SpoilTipView.cells(sim.world, sim.data, 0)
		assert_int(cells.size()).is_equal(2)
		assert_bool(cells.has(first + side)).is_true()


func test_a_blocked_side_moves_the_heap_to_another() -> void:
	var id := SimFixture.place(_sim, &"iron_mine", Vector2i(20, 10), 0)
	var first_try: Array = SpoilTipView.sites(_sim.world, _sim.data, 0)[id]
	var blocked: Vector2i = first_try[0]
	SimFixture.road(_sim, blocked, blocked + Vector2i(0, 1))
	var second_try: Array = SpoilTipView.sites(_sim.world, _sim.data, 0)[id]
	assert_bool(second_try[1] == first_try[1]).is_false()


func test_the_track_runs_from_the_wall_to_the_heap() -> void:
	var id := SimFixture.place(_sim, &"coal_mine", Vector2i(20, 10), 2)
	var record := _sim.world.building(id)
	var grid := _sim.world.island(0)
	var site: Array = SpoilTipView.sites(_sim.world, _sim.data, 0)[id]
	var ends := SpoilTipView.track(grid, _sim.def_of(record), record, site)
	var first: Vector2i = site[0]
	var side: Vector2i = site[1]
	var heap := grid.cell_world(first + side)
	# a ponta fica antes do meio do monte e acima do pé dele
	assert_float(Vector2(ends[1].x, ends[1].z).distance_to(Vector2(heap.x, heap.z))).is_less(1.0)
	assert_float(ends[1].y).is_greater(ends[2].y + 0.5)
	# o começo fica junto da parede da mina
	var wall := grid.cell_world(first) - Vector3(side.x, 0.0, side.y) * grid.cell_size * 0.5
	assert_float(Vector2(ends[0].x, ends[0].z).distance_to(Vector2(wall.x, wall.z))).is_less(0.3)


func test_the_cart_runs_only_while_the_mine_works() -> void:
	var start := Vector3(0.0, 1.0, 0.0)
	var tip := Vector3(3.0, 1.6, 0.0)
	var parked := SpoilTipView.cart_pose(start, tip, 0.0, false).origin
	for step: int in 20:
		assert_vector(SpoilTipView.cart_pose(start, tip, step * 0.7, false).origin).is_equal_approx(parked,
				Vector3.ONE * 0.001)
	var farthest := 0.0
	var tipped := false
	for step: int in 140:
		var pose := SpoilTipView.cart_pose(start, tip, step * 0.1, true)
		farthest = maxf(farthest, pose.origin.distance_to(start))
		# virando, a frente (−Z) aponta para baixo da rampa
		if (-pose.basis.z).normalized().y < -0.3:
			tipped = true
	assert_float(farthest).is_greater(2.0)
	assert_bool(tipped).is_true()
	# volta à boca no fim da volta
	assert_vector(SpoilTipView.cart_pose(start, tip, SpoilTipView.CYCLE_S - 0.5, true).origin).is_equal_approx(parked,
			Vector3.ONE * 0.001)


func test_the_cart_goes_out_full_and_comes_back_empty() -> void:
	assert_bool(SpoilTipView.loaded(1.0, true)).is_true()
	assert_bool(SpoilTipView.loaded(SpoilTipView.OUT_S + SpoilTipView.TIP_S + 1.0, true)).is_false()
	assert_bool(SpoilTipView.loaded(SpoilTipView.CYCLE_S - 0.5, true)).is_true()
	assert_bool(SpoilTipView.loaded(7.0, false)).is_true()


func test_other_buildings_have_no_heap() -> void:
	SimFixture.place(_sim, &"bakery", Vector2i(20, 10))
	SimFixture.place(_sim, &"lumberjack", Vector2i(40, 10))
	assert_int(SpoilTipView.sites(_sim.world, _sim.data, 0).size()).is_equal(0)


func test_the_view_counts_the_mines() -> void:
	SimFixture.place(_sim, &"coal_mine", Vector2i(20, 10))
	SimFixture.place(_sim, &"iron_mine", Vector2i(40, 10))
	var view: SpoilTipView = auto_free(SpoilTipView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.tip_count()).is_equal(2)
