extends GdUnitTestSuite
## Garças no rio (Fase 265): pela busca das margens das canoas, numa rede própria e fora das margens com canoa, uma garça de pé
## na água rasa junto da terra, de frente para o rio e virando de um lado para o outro, longe das vilas; nada na ilha plana.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func test_herons_wade_at_low_river_banks_without_canoes() -> void:
	var world := _sim.world
	var total := 0
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var canoes: Dictionary[Vector2i, bool] = {}
		for bank: Array in CanoeView.banks(world, _sim.data, island_id):
			canoes[bank[0]] = true
		for bank: Array in CanoeView.river_banks(world, island_id, HeronView.HERON_STEP, HeronView.SALT,
				HeronView.HERON_CHANCE):
			var cell: Vector2i = bank[0]
			var river: Vector2i = bank[1]
			assert_int(grid.ground_at(cell)).is_equal(IslandGrid.Ground.LAND)
			assert_int(grid.ground_at(cell + river)).is_equal(IslandGrid.Ground.RIVER)
			if canoes.has(cell):
				continue
			var foot := HeronView.spot(grid, cell, river)
			# na água rasa: o pé no máximo WADE_M abaixo da água, para o lado do rio
			assert_float(foot.y).is_greater_equal(-HeronView.WADE_M - 0.001)
			var middle := grid.cell_world(cell)
			assert_float((foot - middle).dot(Vector3(river.x, 0.0, river.y))).is_greater(0.0)
			total += 1
	print("garças: ", total)
	assert_int(total).is_greater(0)


func test_the_view_faces_the_river_and_swings() -> void:
	var view: HeronView = auto_free(HeronView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.heron_count()).is_greater(0)
	for i: int in view.heron_count():
		var turn := angle_difference(view.faces[i], view.headings[i])
		assert_float(absf(turn)).is_less_equal(HeronView.SWING + 0.001)
	var before_turns := view.headings.duplicate()
	view.advance(600.0)
	var moved := 0
	for i: int in view.heron_count():
		if not is_equal_approx(before_turns[i], view.headings[i]):
			moved += 1
	assert_int(moved).is_greater(0)


func test_the_flat_island_has_no_herons() -> void:
	var flat := SimFixture.simulation()
	for island_id: int in flat.world.islands.size():
		assert_array(CanoeView.river_banks(flat.world, island_id, HeronView.HERON_STEP, HeronView.SALT,
				HeronView.HERON_CHANCE)).is_empty()


func test_the_heron_stands_on_its_feet() -> void:
	var aabb := HeronView.heron_mesh().get_aabb()
	assert_float(aabb.position.y).is_greater_equal(-0.001)
	assert_float(aabb.end.y).is_between(0.8, 1.05)
	# o bico para a frente (−z)
	assert_float(aabb.position.z).is_less(-0.3)
