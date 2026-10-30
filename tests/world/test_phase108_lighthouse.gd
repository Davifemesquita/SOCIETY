extends GdUnitTestSuite
## Farol (Fase 108): a ponta escolhida é terra livre, baixa, perto do entreposto e cercada de mar; muda se alguém
## constrói nela; um farol por ilha com entreposto; nenhum na ilha plana.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _trading_post() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_site_is_a_free_low_headland_near_the_trading_post() -> void:
	var record := _trading_post()
	var found: Variant = LighthouseView.site(_sim, record)
	assert_object(found).is_not_null()
	var cell: Vector2i = found
	var grid := _sim.world.island(0)
	var index := grid.index(cell)
	assert_int(grid.ground[index]).is_equal(IslandGrid.Ground.LAND)
	assert_int(grid.occupancy[index]).is_equal(0)
	assert_int(grid.roads[index]).is_equal(IslandGrid.Road.NONE)
	var spot := grid.cell_world(cell)
	assert_float(grid.height_at(spot.x, spot.z)).is_less_equal(LighthouseView.MAX_HEIGHT_M)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	assert_bool(area.grow(LighthouseView.SEARCH_CELLS).has_point(cell)).is_true()
	var sea := 0
	for dy: int in range(-LighthouseView.EXPOSURE_CELLS, LighthouseView.EXPOSURE_CELLS + 1):
		for dx: int in range(-LighthouseView.EXPOSURE_CELLS, LighthouseView.EXPOSURE_CELLS + 1):
			var other := cell + Vector2i(dx, dy)
			if not grid.in_bounds(other) or grid.ground_at(other) == IslandGrid.Ground.SEA:
				sea += 1
	assert_int(sea).is_greater_equal(LighthouseView.MIN_SEA_CELLS)


func test_building_on_the_headland_moves_the_lighthouse() -> void:
	var record := _trading_post()
	var first: Vector2i = LighthouseView.site(_sim, record)
	_sim.ignore_terrain = true
	var result := _sim.execute(BuildRoadCommand.new(0, [first]))
	_sim.ignore_terrain = false
	assert_bool(result.ok()).is_true()
	var second: Variant = LighthouseView.site(_sim, record)
	assert_object(second).is_not_null()
	assert_bool(second == first).is_false()


func test_one_lighthouse_per_island_with_a_trading_post() -> void:
	var view: LighthouseView = auto_free(LighthouseView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.tower_count()).is_equal(0)
	_trading_post()
	view._process(0.0)
	assert_int(view.tower_count()).is_equal(1)
	assert_object(view.tower_of(0)).is_not_null()


func test_no_lighthouse_on_the_flat_island() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 30))
	sim.free_build = true
	sim.ignore_terrain = true
	var id := SimFixture.place(sim, &"trading_post", Vector2i(10, 0), 2)
	assert_object(LighthouseView.site(sim, sim.world.building(id))).is_null()
