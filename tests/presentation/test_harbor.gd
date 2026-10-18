extends GdUnitTestSuite
## Porto (Fase 15): o píer vira trapiche de tábuas sobre estacas, com a passarela saindo para o mar e os
## cabeços de amarração na ponta; a caixa do píer sai da BuildingView. Fase 21: a volta do cabo no cabeço.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> HarborView:
	var view: HarborView = auto_free(HarborView.new())
	add_child(view)
	view.setup(_sim)
	return view


func test_a_pier_without_berth_reaches_out_to_the_nearest_sea() -> void:
	# borda norte da ilha plana: a passarela vai para o mar (−Z), qualquer que seja o giro do píer
	var pier := SimFixture.place(_sim, &"pier", Vector2i(10, 0), 0)
	var plan := HarborView.walkway(_sim, _sim.world.building(pier))
	var direction: Vector3 = plan["direction"]
	var length: float = plan["length"]
	assert_vector(direction).is_equal(Vector3(0.0, 0.0, -1.0))
	assert_float(length).is_equal(HarborView.WALK_DEFAULT_M)
	var start: Vector3 = plan["start"]
	assert_float(start.z).is_equal_approx(0.0, 0.001)


func test_the_pier_has_planks_piles_and_two_bollards() -> void:
	var view := _view()
	assert_int(view.board_count()).is_equal(0)
	SimFixture.place(_sim, &"pier", Vector2i(10, 0), 2)
	view.rebuild()
	var step := HarborView.BOARD_WIDTH_M + HarborView.BOARD_GAP_M
	var depth := 4 * _sim.config.cell_size_m
	assert_int(view.board_count()).is_equal(int(depth / step) + int(HarborView.WALK_DEFAULT_M / step))
	assert_int(view.bollard_count()).is_equal(2)
	# e um barco amarrado ao lado da passarela, na água
	assert_int(view.boat_count()).is_equal(1)
	# duas fileiras de estacas na área e na passarela
	var area_piles := (int(depth / HarborView.PILE_STEP_M) + 1) * 2
	var walk_piles := (int(HarborView.WALK_DEFAULT_M / HarborView.PILE_STEP_M) + 1) * 2
	assert_int(view.pile_count()).is_equal(area_piles + walk_piles)


func test_the_building_view_draws_no_box_for_the_pier() -> void:
	var buildings: BuildingView = auto_free(BuildingView.new())
	add_child(buildings)
	buildings.setup(_sim, _sim.config.cell_size_m)
	var pier := SimFixture.place(_sim, &"pier", Vector2i(10, 0), 2)
	var node: Node3D = buildings.get_child(buildings.get_child_count() - 1)
	for child: Node in node.get_children():
		assert_bool(child is MeshInstance3D).override_failure_message("caixa no píer %d" % pier).is_false()


func test_the_trading_post_gets_a_quay_with_cargo_and_two_boats() -> void:
	var view := _view()
	var post := SimFixture.place(_sim, &"trading_post", Vector2i(30, 0), 2)
	view.rebuild()
	var def := _sim.data.building(&"trading_post")
	var width := def.size.x * _sim.config.cell_size_m
	assert_int(view.bollard_count()).is_equal(maxi(int(width / HarborView.QUAY_BOLLARD_STEP_M), 1))
	assert_int(view.boat_count()).is_equal(2)
	assert_int(view.cargo_count()).is_equal(HarborView.QUAY_CARGO.size())
	var plan := HarborView.walkway(_sim, _sim.world.building(post))
	var direction: Vector3 = plan["direction"]
	assert_vector(direction).is_equal(Vector3(0.0, 0.0, -1.0))


func test_the_rowboat_is_an_open_hull_with_the_keel_at_zero() -> void:
	var mesh := HarborView.boat_mesh()
	var box := mesh.get_aabb()
	assert_float(box.position.y).is_equal_approx(0.0, 0.001)
	assert_float(box.size.z).is_equal_approx(HarborView.BOAT_LENGTH_M, 0.001)
	assert_float(box.size.x).is_equal_approx(HarborView.BOAT_BEAM_M, 0.001)


func test_a_boat_is_never_moored_on_land() -> void:
	# píer no meio da ilha plana, longe do mar: o trapiche fica, o barco não
	var view := _view()
	SimFixture.place(_sim, &"pier", Vector2i(40, 18), 0)
	view.rebuild()
	assert_int(view.board_count()).is_greater(0)
	assert_int(view.boat_count()).is_equal(0)


func test_each_boat_is_tied_by_bow_and_stern_lines_that_sag_between_bollard_and_hull() -> void:
	var view := _view()
	assert_int(view.rope_count()).is_equal(0)
	SimFixture.place(_sim, &"pier", Vector2i(10, 0), 2)
	view.rebuild()
	assert_int(view.boat_count()).is_equal(1)
	assert_int(view.rope_count()).is_equal(2)
	for index: int in view.rope_count():
		var points := view.rope_points(index)
		var from := points[0]
		var to := points[points.size() - 1]
		# do alto do cabeço, acima do tabuleiro, até a borda do barco, mais baixa
		assert_float(from.y).is_greater(to.y)
		assert_float(from.distance_to(to)).is_less(HarborView.ROPE_MAX_M)
		var middle := points[points.size() / 2]
		assert_float(middle.y).is_less((from.y + to.y) * 0.5 - 0.01)
	# o cais do entreposto amarra os dois barcos dele
	SimFixture.place(_sim, &"trading_post", Vector2i(30, 0), 2)
	view.rebuild()
	assert_int(view.rope_count()).is_equal(6)
	var ropes: MeshInstance3D = view.get_node("Ropes")
	assert_object(ropes.mesh).is_not_null()



func test_each_line_takes_two_turns_round_its_bollard_and_leaves_it_towards_the_boat() -> void:
	var view := _view()
	SimFixture.place(_sim, &"trading_post", Vector2i(30, 0), 2)
	view.rebuild()
	assert_int(view.hitch_count()).is_equal(view.rope_count())
	for index: int in view.hitch_count():
		var coil := view.hitch_points(index)
		var rope := view.rope_points(index)
		# o cabo começa onde a volta começa
		assert_vector(rope[0]).is_equal(coil[0])
		# a volta fica colada no fuste, desce e dá HITCH_TURNS voltas
		var center := Vector2.ZERO
		for point: Vector3 in coil:
			center += Vector2(point.x, point.z)
		center /= coil.size()
		for point: Vector3 in coil:
			var gap := Vector2(point.x, point.z).distance_to(center)
			assert_float(gap).is_between(HarborView.BOLLARD_RADIUS_M, HarborView.BOLLARD_RADIUS_M * 1.6)
		assert_float(coil[coil.size() - 1].y).is_less(coil[0].y)
		assert_int(coil.size()).is_equal(int(HarborView.HITCH_TURNS * HarborView.HITCH_SEGMENTS) + 1)
		# e sai do lado do barco: o começo é o ponto da volta mais perto da outra ponta do cabo
		var boat_end := rope[rope.size() - 1]
		for point: Vector3 in coil:
			assert_float(Vector2(coil[0].x, coil[0].z).distance_to(Vector2(boat_end.x, boat_end.z))).is_less_equal(
					Vector2(point.x, point.z).distance_to(Vector2(boat_end.x, boat_end.z)) + 0.001)


func test_a_second_line_on_the_same_bollard_turns_below_the_first() -> void:
	var first := HarborView.hitch(Vector3.ZERO, Vector3(3.0, 0.0, 0.0))
	var second := HarborView.hitch(Vector3.ZERO, Vector3(0.0, 0.0, 3.0), 1)
	assert_float(second[0].y).is_less(first[first.size() - 1].y)
