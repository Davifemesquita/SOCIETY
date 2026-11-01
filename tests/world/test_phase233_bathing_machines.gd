extends GdUnitTestSuite
## Cabines de banho (Fase 233): perto do entreposto das ilhas temperadas, na areia livre junto do mar, afastadas umas das outras,
## com a porta virada para o mar; nada na ilha plana nem nas tropicais.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_the_machines_stand_on_free_sand_by_the_sea_facing_it() -> void:
	var grid := _sim.world.island(0)
	var found := SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation)).ok()).is_true()
	var cells := BathingMachineView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_less_equal(BathingMachineView.PER_POST)
	for cell: Vector2i in cells:
		assert_bool(PalapaView._sand(grid, cell)).is_true()
		for other: Vector2i in cells:
			if other != cell:
				assert_float(Vector2(other).distance_to(Vector2(cell))).is_greater_equal(BathingMachineView.SPACING_CELLS)
		var place := BathingMachineView.place_of(grid, cell)
		# a porta (−z) olha para um mar a poucas células
		var ahead := grid.world_to_cell(place.origin - place.basis.z * grid.cell_size * 1.5)
		var sea := false
		for dy: int in range(-2, 3):
			for dx: int in range(-2, 3):
				var next := ahead + Vector2i(dx, dy)
				if grid.in_bounds(next) and grid.ground[grid.index(next)] == IslandGrid.Ground.SEA:
					sea = true
		assert_bool(sea).is_true()


func test_the_flat_island_has_none() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	SimFixture.port(sim)
	assert_int(BathingMachineView.cells(sim.world, sim.data, 0).size()).is_equal(0)


func test_the_machine_stands_on_its_wheels() -> void:
	var box := BathingMachineView.machine_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.end.y).is_less(3.2)
	assert_float(box.size.x).is_less(2.0)
	assert_float(box.size.z).is_less(2.8)
