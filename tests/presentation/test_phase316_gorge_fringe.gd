extends GdUnitTestSuite
## Capim pendendo na garganta (Fase 316): a franja da Fase 312 também na borda de cima das gargantas dos rios (a queda de DROP_M
## com o rio logo abaixo, sem mar), virada para a queda; e uma garganta feita à mão numa ilha plana ganha a franja dos dois lados.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()


func _gorge_world() -> WorldState:
	# planalto a 8 m com um rio de duas células no fundo de uma garganta (x = 9 e 10); nada de mar perto
	var grid := IslandGrid.new(Vector2i(20, 20))
	grid.flat = false
	var cells := grid.size.x * grid.size.y
	grid.ground.resize(cells)
	grid.trees.resize(cells)
	grid.cleared_trees.resize(cells)
	grid.deposits.resize(cells)
	var side := grid.size.x + 1
	grid.corner_heights.resize(side * side)
	for y: int in side:
		for x: int in side:
			grid.corner_heights[y * side + x] = -1.2 if x >= 9 and x <= 11 else 8.0
	for y: int in grid.size.y:
		for x: int in [9, 10]:
			grid.ground[grid.index(Vector2i(x, y))] = IslandGrid.Ground.RIVER
	var world := WorldState.new()
	world.islands.append(grid)
	return world


func test_the_gorge_rims_get_the_fringe_facing_the_river() -> void:
	var world := _gorge_world()
	var grid := world.island(0)
	var places := CliffFringeView.places_of(world, _config, 0)
	assert_int(places.size()).is_greater(0)
	var left := 0
	var right := 0
	for place: Transform3D in places:
		var cell := grid.world_to_cell(place.origin)
		assert_int(grid.ground[grid.index(cell)]).is_equal(IslandGrid.Ground.LAND)
		# o rio a até SEA_REACH células para o lado da queda (como o mar nas falésias)
		var out := place.basis.z.normalized()
		var step := Vector2i(roundi(out.x), roundi(out.z))
		var river := false
		for reach: int in range(1, CliffFringeView.SEA_REACH + 1):
			if grid.ground[grid.index(cell + step * reach)] == IslandGrid.Ground.RIVER:
				river = true
		assert_bool(river).is_true()
		if cell.x < 9:
			left += 1
		else:
			right += 1
	assert_int(left).is_greater(0)
	assert_int(right).is_greater(0)


func test_a_drop_with_no_water_below_stays_bare() -> void:
	var world := _gorge_world()
	var grid := world.island(0)
	# o mesmo vale, mas seco: vira terra
	for y: int in grid.size.y:
		for x: int in [9, 10]:
			grid.ground[grid.index(Vector2i(x, y))] = IslandGrid.Ground.LAND
	assert_int(CliffFringeView.places_of(world, _config, 0).size()).is_equal(0)
