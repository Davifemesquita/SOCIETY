extends GdUnitTestSuite
## Pássaros (Fase 14): bandos de pombos nas ruas, que ciscam no chão e levantam voo uma vez por ciclo, e de
## estorninhos sobre os campos com dono; teto de pássaros e nada à noite.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> BirdView:
	var view: BirdView = auto_free(BirdView.new())
	add_child(view)
	view.setup(_sim)
	return view


func test_pigeons_flock_on_the_streets() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(60, 10))
	var grid := _sim.world.island(SimFixture.ISLAND)
	var sites := BirdView.pigeon_sites(grid)
	assert_int(sites.size()).is_greater(0)
	for cell: Vector2i in sites:
		assert_bool(grid.has_road(cell)).is_true()
	var view := _view()
	assert_int(view.flock_count(BirdView.Kind.PIGEON)).is_equal(sites.size())
	assert_int(view.bird_count()).is_equal(sites.size() * BirdView.PIGEONS_PER_FLOCK)
	# o primeiro bando (semente 0) pousado e depois no ar: cada pássaro só numa das duas malhas
	while BirdView.pigeon_flight(0.0, view.time()) >= 0.0:
		view.advance(0.5)
	var perched := view.perched_count()
	assert_int(perched).is_greater_equal(BirdView.PIGEONS_PER_FLOCK)
	while BirdView.pigeon_flight(0.0, view.time()) < 0.3:
		view.advance(0.5)
	assert_int(view.perched_count()).is_less_equal(perched - BirdView.PIGEONS_PER_FLOCK)
	assert_float(view.bird_transform(0).origin.y).is_greater(view.flock_center(0).y + 1.0)


func test_a_pigeon_pecks_on_the_ground_and_then_flies_a_loop() -> void:
	var center := Vector3(10.0, 1.0, 10.0)
	var seed_value := 0.618
	var ground := -1.0
	var flying := -1.0
	for step: int in 400:
		var time := step * 0.1
		if BirdView.pigeon_flight(seed_value, time) < 0.0:
			ground = time
		elif flying < 0.0 and absf(BirdView.pigeon_flight(seed_value, time) - 0.5) < 0.05:
			flying = time
	assert_float(ground).is_greater_equal(0.0)
	assert_float(flying).is_greater_equal(0.0)
	var on_ground := BirdView.pigeon_pose(center, 0, seed_value, ground)
	assert_float(on_ground.origin.y).is_equal_approx(center.y + 0.05, 0.001)
	assert_float(on_ground.origin.distance_to(center)).is_less(BirdView.PIGEON_SPREAD_M + 0.1)
	var in_flight := BirdView.pigeon_pose(center, 0, seed_value, flying)
	assert_float(in_flight.origin.y).is_greater(center.y + BirdView.PIGEON_FLIGHT_M.y * 0.9)


func test_starlings_circle_over_owned_fields() -> void:
	var farm_def: BuildingDef = null
	for def: BuildingDef in _sim.data.buildings:
		if def.module_id == &"field":
			farm_def = def
			break
	SimFixture.place(_sim, farm_def.id, Vector2i(30, 15), 0)
	var reach := Footprint.rect(Vector2i(30, 15), farm_def.size, 0).grow(farm_def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if placed < farm_def.modules_required:
				if _sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND, &"field", Vector2i(x, y), 0)).ok():
					placed += 1
	var view := _view()
	var flocks := view.flock_count(BirdView.Kind.STARLING)
	assert_int(flocks).is_greater(0)
	assert_int(view.bird_count()).is_equal(flocks * BirdView.STARLINGS_PER_FLOCK)
	for i: int in view.bird_count():
		assert_float(view.bird_transform(i).origin.y).is_greater(BirdView.STARLING_HEIGHT_M.x - 1.0)


func test_there_are_never_more_birds_than_the_budget() -> void:
	for row: int in 30:
		SimFixture.road(_sim, Vector2i(0, row), Vector2i(79, row))
	var view := _view()
	assert_int(view.bird_count()).is_less_equal(BirdView.MAX_BIRDS)
	assert_int(view.bird_count()).is_greater(BirdView.MAX_BIRDS - BirdView.STARLINGS_PER_FLOCK)
