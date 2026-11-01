extends GdUnitTestSuite
## Placa na encruzilhada (Fase 187): no T e no cruzamento de estradas de terra fora das vilas, o poste num canto da célula e uma
## tábua apontando cada estrada; nada na estrada reta, no paralelepípedo nem perto de casa; nada na ilha plana.

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


func test_a_crossing_gets_a_post_with_four_arms() -> void:
	_road(_center + Vector2i(-6, 0), _center + Vector2i(6, 0))
	_road(_center + Vector2i(0, -6), _center + Vector2i(0, 6))
	var found := SignpostView.junctions(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(1)
	var grid := _sim.world.island(0)
	var post: Transform3D = found[0][0]
	var arms: Array[Transform3D] = found[0][1]
	assert_int(arms.size()).is_equal(4)
	assert_bool(grid.world_to_cell(post.origin) == _center).is_true()
	var middle := grid.surface_world(_center)
	var offset := Vector2(post.origin.x - middle.x, post.origin.z - middle.z)
	assert_float(offset.length()).is_equal_approx(SignpostView.POST_OFFSET_M, 0.01)
	# cada tábua aponta uma das estradas, cada uma numa altura
	var pointed: Array[Vector2i] = []
	var heights: Array[float] = []
	for arm: Transform3D in arms:
		var x := arm.basis.x.normalized()
		pointed.append(Vector2i(roundi(x.x), roundi(x.z)))
		heights.append(snappedf(arm.origin.y - post.origin.y, 0.01))
	for side: Vector2i in SignpostView.SIDES:
		assert_bool(side in pointed).override_failure_message(str(side)).is_true()
	heights.sort()
	for k: int in heights.size() - 1:
		assert_float(heights[k + 1] - heights[k]).is_greater(0.1)


func test_a_t_junction_puts_the_post_on_the_side_without_road() -> void:
	_road(_center + Vector2i(-6, 0), _center + Vector2i(6, 0))
	_road(_center, _center + Vector2i(0, 6))
	var found := SignpostView.junctions(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(1)
	var arms: Array[Transform3D] = found[0][1]
	assert_int(arms.size()).is_equal(3)
	var post: Transform3D = found[0][0]
	var middle := _sim.world.island(0).surface_world(_center)
	# o lado sem estrada é o de −z
	assert_float(post.origin.z - middle.z).is_less(-0.5)


func test_no_post_on_paved_roads_straight_roads_or_in_town() -> void:
	_road(_center + Vector2i(-6, 0), _center + Vector2i(6, 0))
	assert_array(SignpostView.junctions(_sim.world, _sim.data, 0)).is_empty()
	_road(_center + Vector2i(0, -6), _center + Vector2i(0, 6))
	assert_int(SignpostView.junctions(_sim.world, _sim.data, 0).size()).is_equal(1)
	# uma casa perto: a encruzilhada já é da vila
	SimFixture.house(_sim, _center.x + 3, _center.y + 4, &"peasants", 2.0)
	assert_array(SignpostView.junctions(_sim.world, _sim.data, 0)).is_empty()


func test_no_post_on_a_paved_crossing() -> void:
	_road(_center + Vector2i(-6, 0), _center + Vector2i(6, 0), true)
	_road(_center + Vector2i(0, -6), _center + Vector2i(0, 6), true)
	assert_array(SignpostView.junctions(_sim.world, _sim.data, 0)).is_empty()


func test_none_on_the_flat_island() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 40))
	SimFixture.road(sim, Vector2i(2, 10), Vector2i(30, 10))
	SimFixture.road(sim, Vector2i(10, 2), Vector2i(10, 30))
	assert_array(SignpostView.junctions(sim.world, sim.data, SimFixture.ISLAND)).is_empty()
