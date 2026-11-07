extends GdUnitTestSuite
## Bomba d'água (Fase 132): uma bomba junto de uma casa a cada PUMP_EVERY, numa célula livre encostada nela e com estrada ao
## lado, virada para a rua; o recheio deixa a célula limpa; a ilha plana não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


## Uma rua com casas suficientes para ter ids múltiplos de PUMP_EVERY.
func _street() -> void:
	var grid := _sim.world.island(0)
	var base := grid.size / 2 - Vector2i(12, 4)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 4), base + Vector2i(30, 4))))
	for i: int in 8:
		_sim.execute(PlaceBuildingCommand.new(0, &"house", base + Vector2i(i * 4, 1), 2))


func test_pumps_stand_beside_houses_by_the_street() -> void:
	_street()
	var grid := _sim.world.island(0)
	var cells := WaterPumpView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_greater(0)
	for cell: Vector2i in cells:
		assert_int(grid.building_at(cell)).is_equal(0)
		assert_bool(grid.has_road(cell)).is_false()
		var side: Vector2i = cells[cell]
		assert_bool(grid.has_road(cell + side)).is_true()
		# encostada numa casa da vez
		var beside := false
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var id := grid.building_at(cell + Vector2i(dx, dy))
				if id != 0 and _sim.world.building(id).is_house() and posmod(id, WaterPumpView.PUMP_EVERY) == 0:
					beside = true
		assert_bool(beside).is_true()


func test_the_scatter_leaves_the_pump_alone() -> void:
	_street()
	var clear: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	for cell: Vector2i in WaterPumpView.cells(_sim.world, _sim.data, 0):
		assert_bool(clear.has(cell)).is_true()


func test_no_pumps_on_the_flat_island() -> void:
	var sim := SimFixture.simulation()
	for i: int in 12:
		SimFixture.place(sim, &"house", Vector2i(4 + i * 4, 10))
	assert_int(WaterPumpView.cells(sim.world, sim.data, 0).size()).is_equal(0)
