extends GdUnitTestSuite
## Blocos no pé da garganta (Fase 317): nas células de rio junto de uma parede de terra FALL_DROP_M acima da água, blocos caídos meio
## dentro da água, encostados na parede; o rio de margem baixa não tem; a ponte tira; os matacões e os seixos de antes não mudam.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()


## Uma ilha de 20 × 20 com um rio de duas células no meio (x = 9 e 10), entre margens à altura bank.
func _river_world(bank: float) -> WorldState:
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
			grid.corner_heights[y * side + x] = -1.0 if x >= 9 and x <= 11 else bank
	for y: int in grid.size.y:
		for x: int in [9, 10]:
			grid.ground[grid.index(Vector2i(x, y))] = IslandGrid.Ground.RIVER
	var world := WorldState.new()
	world.islands.append(grid)
	return world


func _fallen(world: WorldState) -> Array:
	return RiverStoneView.places(world, 0).filter(func(entry: Array) -> bool: return entry[2] == RiverStoneView.Kind.FALLEN)


func test_blocks_lie_half_in_the_water_against_the_wall() -> void:
	var world := _river_world(8.0)
	var grid := world.island(0)
	var blocks := _fallen(world)
	assert_int(blocks.size()).is_greater(5)
	for entry: Array in blocks:
		var place: Transform3D = entry[1]
		var cell := grid.world_to_cell(place.origin)
		assert_int(grid.ground_at(cell)).is_equal(IslandGrid.Ground.RIVER)
		# o pé debaixo d'água e o topo pouco acima dela
		assert_float(place.origin.y).is_less(0.0)
		var top := place.origin.y + place.basis.y.length()
		assert_float(top).is_between(RiverStoneView.FALL_TOP_M.x - 0.01, RiverStoneView.FALL_TOP_M.y + 0.01)
		# encostado na parede: na metade da célula do lado da terra
		var u := (place.origin.x - grid.origin_m.x) / grid.cell_size - cell.x
		if cell.x == 9:
			assert_float(u).is_less(0.5)
		else:
			assert_float(u).is_greater(0.5)


func test_a_low_bank_has_no_fallen_blocks() -> void:
	assert_int(_fallen(_river_world(1.0)).size()).is_equal(0)


func test_a_bridge_takes_the_blocks_away() -> void:
	var world := _river_world(8.0)
	var grid := world.island(0)
	var first: Transform3D = _fallen(world)[0][1]
	var cell := grid.world_to_cell(first.origin)
	grid.roads[grid.index(cell)] = IslandGrid.Road.DIRT
	for entry: Array in _fallen(world):
		var place: Transform3D = entry[1]
		assert_bool(grid.world_to_cell(place.origin) == cell).is_false()


func test_the_old_stones_stay_the_same() -> void:
	# os blocos têm o sorteio deles e vêm por último: as pedras de antes saem iguais e na mesma ordem
	var sim := Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	var entries := RiverStoneView.places(sim.world, 0)
	var first_fallen := entries.size()
	for i: int in entries.size():
		if entries[i][2] == RiverStoneView.Kind.FALLEN:
			first_fallen = i
			break
	for i: int in range(first_fallen, entries.size()):
		assert_int(entries[i][2]).is_equal(RiverStoneView.Kind.FALLEN)
	assert_int(RiverStoneView.Kind.FALLEN).is_greater(RiverStoneView.Kind.PEBBLE)
