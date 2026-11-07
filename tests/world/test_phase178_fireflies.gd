extends GdUnitTestSuite
## Vaga-lumes (Fase 178): os enxames ficam em terra sem árvore, longe de prédio, estrada e trilho, na beira da mata e no
## capim aberto; cada um com FLIES pontinhos baixos em volta do meio; o mesmo mundo dá os mesmos vaga-lumes; nada na ilha
## plana; uma estrada nova tira o enxame de perto dela.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_swarms_sit_on_open_land_away_from_works() -> void:
	var total := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for center: Vector3 in FireflyView.swarms(_world, island_id):
			var cell := grid.world_to_cell(center)
			assert_int(grid.ground[grid.index(cell)]).is_equal(IslandGrid.Ground.LAND)
			assert_int(grid.trees[grid.index(cell)]).is_equal(0)
			for dy: int in range(-FireflyView.CLEAR_CELLS, FireflyView.CLEAR_CELLS + 1):
				for dx: int in range(-FireflyView.CLEAR_CELLS, FireflyView.CLEAR_CELLS + 1):
					var j := grid.index(cell + Vector2i(dx, dy))
					assert_int(grid.occupancy[j]).is_equal(0)
					assert_int(grid.roads[j]).is_equal(IslandGrid.Road.NONE)
			assert_float(center.y).is_equal_approx(grid.height_at(center.x, center.z), 0.01)
			total += 1
	assert_int(total).is_greater(10)


func test_swarms_by_the_forest_and_in_the_open() -> void:
	var by_forest := 0
	var in_open := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for center: Vector3 in FireflyView.swarms(_world, island_id):
			var cell := grid.world_to_cell(center)
			var forest := false
			for dy: int in range(-FireflyView.CLEAR_CELLS, FireflyView.CLEAR_CELLS + 1):
				for dx: int in range(-FireflyView.CLEAR_CELLS, FireflyView.CLEAR_CELLS + 1):
					if grid.trees[grid.index(cell + Vector2i(dx, dy))] > 0:
						forest = true
			if forest:
				by_forest += 1
			else:
				in_open += 1
	assert_int(by_forest).is_greater(0)
	assert_int(in_open).is_greater(0)


func test_each_swarm_has_its_fireflies_low_around_it() -> void:
	var island_id := 0
	var grid := _world.island(island_id)
	var centers := FireflyView.swarms(_world, island_id)
	var flies := FireflyView.flies(_world, island_id)
	assert_int(flies.size()).is_equal(centers.size() * FireflyView.FLIES)
	for i: int in flies.size():
		var center := centers[i / FireflyView.FLIES]
		var fly := flies[i]
		assert_float(Vector2(fly.x - center.x, fly.z - center.z).length()).is_less_equal(FireflyView.SPREAD_M + 0.001)
		var above := fly.y - grid.height_at(fly.x, fly.z)
		assert_float(above).is_between(FireflyView.LOW_M - 0.001, FireflyView.HIGH_M + 0.001)
	# o mesmo mundo, os mesmos vaga-lumes
	assert_array(FireflyView.flies(_world, island_id)).is_equal(flies)


func test_none_on_the_flat_island() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 60))
	assert_array(FireflyView.swarms(sim.world, SimFixture.ISLAND)).is_empty()


func test_a_new_road_clears_the_swarm_next_to_it() -> void:
	var island_id := 0
	var grid := _world.island(island_id)
	var centers := FireflyView.swarms(_world, island_id)
	assert_int(centers.size()).is_greater(0)
	var cell := grid.world_to_cell(centers[0])
	grid.set_road(cell + Vector2i(1, 0), IslandGrid.Road.DIRT)
	for center: Vector3 in FireflyView.swarms(_world, island_id):
		assert_bool(grid.world_to_cell(center) == cell).is_false()
