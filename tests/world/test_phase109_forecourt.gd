extends GdUnitTestSuite
## Largo calçado (Fase 109): as células livres encostadas nos serviços de PLAZA_SERVICES viram lajes de pedra no relevo; o
## recheio fica fora delas; outros prédios não têm largo; a ilha plana não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _place(def_id: StringName) -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_forecourt_rings_the_service() -> void:
	var record := _place(&"church")
	var grid := _sim.world.island(0)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var court := ForecourtView.cells(_sim.world, _sim.data, 0)
	assert_int(court.size()).is_greater(0)
	for cell: Vector2i in court:
		# encostada no prédio (no anel de uma célula), livre e quase plana
		assert_bool(area.grow(1).has_point(cell) and not area.has_point(cell)).is_true()
		var index := grid.index(cell)
		assert_int(grid.occupancy[index]).is_equal(0)
		assert_int(grid.roads[index]).is_equal(IslandGrid.Road.NONE)
		assert_int(grid.trees[index]).is_equal(0)
		var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
		assert_float(corners.y - corners.x).is_less_equal(ForecourtView.MAX_RELIEF_M)


func test_the_slabs_sit_on_the_ground() -> void:
	_place(&"church")
	var grid := _sim.world.island(0)
	for cell: Vector2i in ForecourtView.cells(_sim.world, _sim.data, 0):
		var slabs := ForecourtView.slabs(grid, cell)
		assert_int(slabs.size()).is_equal(ForecourtView.SLABS * ForecourtView.SLABS)
		for slab: Array in slabs:
			var place: Transform3D = slab[0]
			var top := place.origin.y + ForecourtView.SLAB_THICK_M * 0.5
			assert_float(top - grid.height_at(place.origin.x, place.origin.z)).is_equal_approx(ForecourtView.SLAB_LIFT_M, 0.001)
			assert_bool(grid.world_to_cell(place.origin) == cell).is_true()


func test_the_scatter_stays_off_the_forecourt() -> void:
	_place(&"church")
	var court := ForecourtView.cells(_sim.world, _sim.data, 0)
	var grid := _sim.world.island(0)
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, 0, Vector2i(cx, cy))
			for kind: int in items.keys():
				var list: Array = items[kind]
				for item: Array in list:
					var place: Transform3D = item[0]
					assert_bool(court.has(grid.world_to_cell(place.origin))).is_false()


func test_other_buildings_and_the_flat_island_have_none() -> void:
	_place(&"bakery")
	assert_int(ForecourtView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	var sim := SimFixture.simulation(Vector2i(40, 30))
	sim.free_build = true
	SimFixture.place(sim, &"church", Vector2i(10, 10), 0)
	assert_int(ForecourtView.cells(sim.world, sim.data, 0).size()).is_equal(0)
