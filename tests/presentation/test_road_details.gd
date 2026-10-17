extends GdUnitTestSuite
## Detalhe das estradas (Fase 14): meio-fio só no paralelepípedo e só nos lados que não dão para outra
## estrada; sulcos de roda na direção da rua de terra.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> RoadView:
	var view: RoadView = auto_free(RoadView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	return view


func test_paved_streets_get_curbs_on_their_open_sides() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(9, 10))
	var view := _view()
	assert_int(view.curb_count()).is_equal(0)
	var grid := _sim.world.island(SimFixture.ISLAND)
	for cell: Vector2i in RoadPath.l_path(Vector2i(0, 20), Vector2i(9, 20)):
		grid.set_road(cell, IslandGrid.Road.PAVED)
	view.rebuild()
	# dez células retas: dois lados cada, mais as duas pontas
	assert_int(view.curb_count()).is_equal(10 * 2 + 2)
	# o meio-fio fica na borda da célula, dentro dela
	var place := RoadView.curb_place(Vector2i(0, 1), _sim.config.cell_size_m)
	assert_float(place.origin.z).is_equal_approx(_sim.config.cell_size_m * 0.5 - RoadView.CURB_WIDTH_M * 0.5, 0.001)


func test_dirt_ruts_follow_the_street() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(9, 10))
	SimFixture.road(_sim, Vector2i(5, 11), Vector2i(5, 15))
	var grid := _sim.world.island(SimFixture.ISLAND)
	assert_int(RoadView.ruts(grid, Vector2i(2, 10))).is_equal(RoadView.Ruts.ALONG_X)
	assert_int(RoadView.ruts(grid, Vector2i(5, 13))).is_equal(RoadView.Ruts.ALONG_Z)
	assert_int(RoadView.ruts(grid, Vector2i(5, 10))).is_equal(RoadView.Ruts.BOTH)
	SimFixture.road(_sim, Vector2i(30, 30), Vector2i(30, 30))
	assert_int(RoadView.ruts(grid, Vector2i(30, 30))).is_equal(RoadView.Ruts.NONE)


## Ilha de 20 × 10 plana a 1,2 m com um rio de duas células em x = 8..9 (o canto do meio no leito).
func _river_simulation() -> Simulation:
	var grid := IslandGrid.new(Vector2i(20, 10))
	grid.init_terrain()
	for y: int in 11:
		for x: int in 21:
			grid.corner_heights[grid.corner_index(x, y)] = -1.2 if x == 9 else 1.2
	for y: int in 10:
		for x: int in 20:
			grid.ground[y * 20 + x] = IslandGrid.Ground.RIVER if x == 8 or x == 9 else IslandGrid.Ground.LAND
	var world := WorldState.new()
	world.islands.append(grid)
	var economy := IslandEconomy.new()
	economy.profile_id = &"main_island"
	world.economies.append(economy)
	var sim := Simulation.new(GameConfig.new(), GameData.get_default(), world)
	sim.free_build = true
	return sim


func test_the_bridge_gets_railings_and_piles() -> void:
	_sim = _river_simulation()
	var grid := _sim.world.island(0)
	for cell: Vector2i in RoadPath.l_path(Vector2i(6, 5), Vector2i(11, 5)):
		grid.set_road(cell, IslandGrid.Road.DIRT)
	var view := _view()
	# as duas células da ponte, dois lados abertos cada, duas travessas por lado
	assert_int(view.rail_count()).is_equal(2 * 2 * 2)
	# por lado: o poste do meio, o do canto de trás e a estaca; o canto da frente só no fim da ponte
	assert_int(view.post_count()).is_equal(2 * 2 * 3 + 2)
	assert_bool(RoadView.railed(grid, Vector2i(8, 5), Vector2i(0, 1))).is_true()
	assert_bool(RoadView.railed(grid, Vector2i(8, 5), Vector2i(1, 0))).is_false()
	assert_bool(RoadView.railed(grid, Vector2i(6, 5), Vector2i(0, 1))).is_false()
	assert_int(view.curb_count()).is_equal(0)
