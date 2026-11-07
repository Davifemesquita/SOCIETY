extends GdUnitTestSuite
## Marco de légua (Fase 237): na estrada de terra reta e comprida fora das vilas, um marco de pedra a cada STONE_EVERY células
## pelo desenho da grade, na beira da célula e com a face para a estrada; nada no paralelepípedo, perto de casa nem na ilha plana.

var _config: GameConfig
var _sim: Simulation
var _center: Vector2i


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true
	_center = _sim.world.island(0).size / 2


func _road(from: Vector2i, to: Vector2i, paved := false) -> void:
	var result := _sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(from, to), paved))
	assert_bool(result.ok()).is_true()


func test_a_long_straight_road_gets_stones_on_its_verge() -> void:
	_road(_center + Vector2i(-30, 0), _center + Vector2i(30, 0))
	var stones := MilestoneView.stones(_sim.world, _sim.data, 0)
	assert_int(stones.size()).is_greater(0)
	var grid := _sim.world.island(0)
	for stone: Transform3D in stones:
		# o pé fica na beira de uma célula da estrada, OFFSET_M de lado, numa célula do desenho
		var cell := grid.world_to_cell(stone.origin)
		assert_bool(grid.has_road(cell)).is_true()
		assert_int(posmod(7 * cell.x + 13 * cell.y, MilestoneView.STONE_EVERY)).is_equal(0)
		var middle := grid.surface_world(cell)
		assert_float(absf(stone.origin.x - middle.x)).is_less(0.01)
		assert_float(absf(stone.origin.z - middle.z)).is_equal_approx(MilestoneView.OFFSET_M, 0.01)
		# a face (+z do marco) para a estrada
		var face := stone.basis.z.normalized()
		assert_float(face.z * signf(middle.z - stone.origin.z)).is_greater(0.9)
	# um a cada STONE_EVERY células: na estrada de 61 nunca mais que três
	assert_int(stones.size()).is_less_equal(3)


func test_no_stone_on_a_paved_road() -> void:
	_road(_center + Vector2i(-30, 0), _center + Vector2i(30, 0), true)
	assert_array(MilestoneView.stones(_sim.world, _sim.data, 0)).is_empty()


func test_a_house_near_the_road_takes_the_stone_away() -> void:
	_road(_center + Vector2i(-30, 0), _center + Vector2i(30, 0))
	var stones := MilestoneView.stones(_sim.world, _sim.data, 0)
	assert_int(stones.size()).is_greater(0)
	var grid := _sim.world.island(0)
	var cell := grid.world_to_cell(stones[0].origin)
	SimFixture.house(_sim, cell.x + 2, cell.y, &"peasants", 2.0)
	for stone: Transform3D in MilestoneView.stones(_sim.world, _sim.data, 0):
		assert_bool(grid.world_to_cell(stone.origin) == cell).is_false()


func test_a_crossing_road_is_not_straight() -> void:
	_road(_center + Vector2i(-30, 0), _center + Vector2i(30, 0))
	var grid := _sim.world.island(0)
	var cell := grid.world_to_cell(MilestoneView.stones(_sim.world, _sim.data, 0)[0].origin)
	_road(cell + Vector2i(0, -5), cell + Vector2i(0, 5))
	for stone: Transform3D in MilestoneView.stones(_sim.world, _sim.data, 0):
		assert_bool(grid.world_to_cell(stone.origin) == cell).is_false()


func test_a_flat_island_has_none() -> void:
	var sim := SimFixture.simulation(Vector2i(80, 30))
	sim.free_build = true
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(2, 10), Vector2i(76, 10)), false))
	assert_array(MilestoneView.stones(sim.world, sim.data, 0)).is_empty()


func test_the_stone_stands_up_with_a_round_top() -> void:
	var box := MilestoneView.stone_mesh().get_aabb()
	assert_float(box.size.y).is_greater(box.size.x * 1.5)
	assert_float(box.end.y).is_equal_approx(MilestoneView.SHOULDER_M + MilestoneView.HALF_W, 0.01)
	assert_float(box.position.y).is_equal_approx(-MilestoneView.SUNK_M, 0.01)
