extends GdUnitTestSuite
## Porto (Fase 15): o píer vira trapiche de tábuas sobre estacas, com a passarela saindo para o mar e os
## cabeços de amarração na ponta; a caixa do píer sai da BuildingView.

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
