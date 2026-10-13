extends GdUnitTestSuite
## Multidão no relevo: a rota fica na altura da estrada e o boneco sobe a ladeira em pé.
## Ilha montada à mão: estrada em y = 10 de x = 2 a 40, subindo 0,4 m por célula a partir de x = 20.

var _sim: Simulation


func before_test() -> void:
	var grid := IslandGrid.new(Vector2i(50, 20))
	grid.init_terrain()
	for y: int in 21:
		for x: int in 51:
			grid.corner_heights[grid.corner_index(x, y)] = 1.2 + maxf(0.0, x - 20) * 0.4
	var world := WorldState.new()
	world.islands.append(grid)
	var economy := IslandEconomy.new()
	economy.profile_id = &"main_island"
	world.economies.append(economy)
	var config := GameConfig.new()
	config.instant_logistics = true
	_sim = Simulation.new(config, GameData.get_default(), world)
	_sim.free_build = true
	SimFixture.road(_sim, Vector2i(2, 10), Vector2i(40, 10))
	for i: int in 4:
		SimFixture.house(_sim, 3 + i * 3, 10, &"peasants", 20.0)
	# mercado no alto da ladeira (a área não é plana: posto sem olhar o terreno)
	_sim.ignore_terrain = true
	SimFixture.place(_sim, &"market", Vector2i(34, 11), 0)


func test_walkers_stay_on_the_road_surface_and_upright() -> void:
	var strides: Array[PackedFloat32Array] = [PackedFloat32Array([1.4, 1.4, 0, 0]), PackedFloat32Array([1.4, 1.4, 0, 0])]
	var crowd := Crowd.new(_sim, _sim.config, strides, 2)
	crowd.activity_override = 1.0
	var grid := _sim.world.island(0)
	var checked := 0
	for second: int in 200:
		crowd.update(1.0, 12.0)
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or agent.state != Crowd.State.WALKING or agent.segment == 0 or agent.segment >= agent.points.size() - 2:
				continue
			var point := crowd.position_of(agent)
			assert_float(point.y).is_equal_approx(grid.height_at(point.x, point.z), 0.45)
			var xform := crowd.instance_transform(agent)
			assert_vector(xform.basis.y).is_equal_approx(Vector3.UP, Vector3.ONE * 0.0001)
			checked += 1
	assert_int(checked).is_greater(20)
