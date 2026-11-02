extends GdUnitTestSuite
## Cruzeiro no morro (Fase 269): em cada ilha temperada com morro, a célula livre e quase plana mais alta vira o cruzeiro, virado
## para o meio da ilha; nada nas tropicais nem na ilha plana; a cruz de pé, com o degrau no chão.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func test_the_cross_stands_on_the_highest_free_cell() -> void:
	var world := _sim.world
	var total := 0
	for island_id: int in world.islands.size():
		var found: Variant = SummitCrossView.summit(world, _sim.data, island_id)
		if world.is_tropical(island_id, _sim.data):
			assert_object(found).is_null()
			continue
		if not found is Vector2i:
			continue
		var cell: Vector2i = found
		var grid := world.island(island_id)
		var index := grid.index(cell)
		assert_int(grid.ground[index]).is_equal(IslandGrid.Ground.LAND)
		assert_int(grid.trees[index]).is_equal(0)
		assert_int(grid.occupancy[index]).is_equal(0)
		var top := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
		assert_float(top.y).is_greater(SummitCrossView.MIN_HEIGHT_M)
		assert_float(top.y - top.x).is_less_equal(SummitCrossView.MAX_RELIEF_M)
		# nenhuma célula livre e quase plana da busca é mais alta
		for y: int in range(1, grid.size.y - 1, SummitCrossView.SEARCH_STEP):
			for x: int in range(1, grid.size.x - 1, SummitCrossView.SEARCH_STEP):
				var other := y * grid.size.x + x
				if grid.ground[other] != IslandGrid.Ground.LAND or grid.trees[other] > 0 or grid.occupancy[other] != 0 \
						or grid.roads[other] != IslandGrid.Road.NONE or grid.rails[other] != 0:
					continue
				var range_other := BuildingKit.corner_range(grid, Rect2i(Vector2i(x, y), Vector2i.ONE))
				if range_other.y - range_other.x <= SummitCrossView.MAX_RELIEF_M:
					assert_float(range_other.y).is_less_equal(top.y)
		# virado para o meio da ilha
		var place := SummitCrossView.place_of(grid, cell)
		var middle := grid.cell_world(grid.size / 2)
		var toward := Vector3(middle.x - place.origin.x, 0.0, middle.z - place.origin.z).normalized()
		assert_float((-place.basis.z).dot(toward)).is_greater(0.99)
		total += 1
	print("cruzeiros: ", total)
	assert_int(total).is_greater(0)


func test_the_flat_island_has_no_cross() -> void:
	var flat := SimFixture.simulation()
	for island_id: int in flat.world.islands.size():
		assert_object(SummitCrossView.summit(flat.world, flat.data, island_id)).is_null()


func test_the_cross_stands_on_its_step() -> void:
	var box := SummitCrossView.cross_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.end.y).is_between(3.0, 3.5)
	# o degrau e o musgo em volta dele
	assert_float(box.size.x).is_between(1.4, 1.9)
