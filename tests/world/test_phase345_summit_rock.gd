extends GdUnitTestSuite
## Granito no alto (Fase 345): grupos de rocha no alto dos morros (acima de SUMMIT_SHARE da altura mais alta da ilha), só em células
## livres; a célula que recebe estrada perde a rocha; nada na ilha plana; o mesmo resultado para o mesmo mundo.

var _world: WorldState


func before_test() -> void:
	_world = ArchipelagoGenerator.new_world(1840, GameConfig.get_default(), GameData.get_default())


func test_rocks_crown_the_hills_on_free_cells() -> void:
	var total := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var top := 0.0
		for height: float in grid.corner_heights:
			top = maxf(top, height)
		for entry: Array in SummitRockView.places(_world, island_id):
			var place: Transform3D = entry[0]
			var cell := grid.world_to_cell(place.origin)
			assert_bool(SummitRockView._free(grid, cell)).is_true()
			# as de volta podem descer um pouco do alto, nunca muito
			assert_float(grid.cell_height(cell)).is_greater(top * SummitRockView.SUMMIT_SHARE - SummitRockView.SIDE_REACH_M)
			total += 1
	print("granito no alto da semente 1840: %d rochas" % total)
	assert_int(total).is_greater(30)


func test_a_road_takes_the_rock_away() -> void:
	var grid := _world.island(0)
	var before := SummitRockView.places(_world, 0)
	assert_int(before.size()).is_greater(0)
	var place: Transform3D = before[0][0]
	var cell := grid.world_to_cell(place.origin)
	grid.roads[grid.index(cell)] = IslandGrid.Road.DIRT
	for entry: Array in SummitRockView.places(_world, 0):
		var other: Transform3D = entry[0]
		assert_bool(grid.world_to_cell(other.origin) == cell).is_false()
	assert_bool(before == SummitRockView.places(ArchipelagoGenerator.new_world(1840, GameConfig.get_default(), GameData.get_default()), 0)).is_true()


func test_no_rocks_on_the_flat_island() -> void:
	var world := WorldState.new()
	world.islands.append(IslandGrid.new(Vector2i(40, 40)))
	assert_int(SummitRockView.places(world, 0).size()).is_equal(0)


func test_the_rebuild_is_quick() -> void:
	for island_id: int in _world.islands.size():
		SummitRockView.places(_world, island_id)
	var started := Time.get_ticks_usec()
	for island_id: int in _world.islands.size():
		SummitRockView.places(_world, island_id)
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	print("granito no alto: refazer o arquipélago em %.1f ms" % ms)
	assert_float(ms).is_less(25.0)


func test_the_rocks_sit_on_crests_not_on_the_plateau() -> void:
	var grid := _world.island(0)
	var crests := 0
	var flat := 0
	for y: int in range(3, grid.size.y - 3, 4):
		for x: int in range(3, grid.size.x - 3, 4):
			if SummitRockView._crest(grid, Vector2i(x, y)):
				crests += 1
			else:
				flat += 1
	# poucos pontos da ilha são topo ou crista
	assert_int(crests).is_greater(0)
	assert_float(float(crests) / (crests + flat)).is_less(0.35)
