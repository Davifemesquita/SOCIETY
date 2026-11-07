extends GdUnitTestSuite
## Poço da vila (Fase 201): um poço junto de uma casa dos camponeses a cada WELL_EVERY (as da bomba ficam de fora), numa célula
## livre encostada nela, com estrada ao lado e sem bomba, virado para a rua; o recheio deixa a célula limpa; outras classes e a
## ilha plana não têm; o poço tem o pé no chão e o telhado em cima.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


## Uma rua com casas espaçadas (uma célula livre entre elas) da classe tier, ids suficientes para o resto do poço.
func _street(tier: StringName) -> void:
	var grid := _sim.world.island(0)
	var base := grid.size / 2 - Vector2i(20, 4)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 4), base + Vector2i(44, 4))))
	for i: int in 11:
		var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", base + Vector2i(i * 4, 1), 2))
		if result.ok():
			_sim.world.building(result.placed[0]).tier = tier


func test_wells_stand_beside_peasant_houses_by_the_street() -> void:
	_street(&"peasants")
	var grid := _sim.world.island(0)
	var cells := WellView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_greater(0)
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, 0)
	for cell: Vector2i in cells:
		assert_bool(pumps.has(cell)).is_false()
		assert_int(grid.building_at(cell)).is_equal(0)
		assert_bool(grid.has_road(cell)).is_false()
		var side: Vector2i = cells[cell]
		assert_bool(grid.has_road(cell + side)).is_true()
		# encostado numa casa da vez
		var beside := false
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var id := grid.building_at(cell + Vector2i(dx, dy))
				if id != 0 and _sim.world.building(id).is_house() and posmod(id, WellView.WELL_EVERY) == WellView.WELL_REST:
					beside = true
		assert_bool(beside).is_true()


func test_the_scatter_leaves_the_well_alone() -> void:
	_street(&"peasants")
	var clear: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	for cell: Vector2i in WellView.cells(_sim.world, _sim.data, 0):
		assert_bool(clear.has(cell)).is_true()


func test_only_peasants_and_not_on_the_flat_island() -> void:
	_street(&"workers")
	assert_int(WellView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	var sim := SimFixture.simulation()
	for i: int in 12:
		var id := SimFixture.place(sim, &"house", Vector2i(4 + i * 4, 10))
		sim.world.building(id).tier = &"peasants"
	assert_int(WellView.cells(sim.world, sim.data, 0).size()).is_equal(0)


func test_the_well_stands_on_the_ground_under_its_roof() -> void:
	var box := WellView.well_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.001)
	assert_float(box.end.y).is_between(WellView.RIDGE_M, WellView.RIDGE_M + 0.1)
	# cabe na célula de 2 m
	assert_float(box.size.x).is_less(2.0)
	assert_float(box.size.z).is_less(2.0)
