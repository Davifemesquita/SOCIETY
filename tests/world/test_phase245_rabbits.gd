extends GdUnitTestSuite
## Coelhos no prado (Fase 245): as tocas ficam em capim aberto, longe das vilas, só nas ilhas temperadas; cada toca tem de três a
## cinco coelhos; o coelho fica agachado quase sempre e senta de vez em quando.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_warrens_sit_on_open_meadow() -> void:
	var grid := _sim.world.island(0)
	var warrens := RabbitView.warrens(_sim.world, _sim.data, 0)
	assert_int(warrens.size()).is_greater(0)
	for cell: Vector2i in warrens:
		assert_bool(RabbitView._open(grid, cell)).is_true()
	var rabbits := RabbitView.rabbits(_sim.world, _sim.data, 0)
	assert_int(rabbits.size()).is_between(warrens.size() * 3, warrens.size() * 5)


func test_a_town_keeps_the_rabbits_away() -> void:
	var warrens := RabbitView.warrens(_sim.world, _sim.data, 0)
	assert_int(warrens.size()).is_greater(0)
	var cell := warrens[0]
	var found := SiteFinder.find(_sim, &"house", 0, cell)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"house", origin, 0)).ok()).is_true()
	if (Vector2(origin) - Vector2(cell)).length() < SealView.WILD_CELLS:
		assert_bool(RabbitView.warrens(_sim.world, _sim.data, 0).has(cell)).is_false()


func test_tropical_islands_and_the_flat_island_have_none() -> void:
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			assert_int(RabbitView.warrens(_sim.world, _sim.data, island_id).size()).is_equal(0)
	var flat := SimFixture.simulation(Vector2i(60, 30))
	assert_int(RabbitView.warrens(flat.world, flat.data, 0).size()).is_equal(0)


func test_the_rabbit_crouches_most_of_the_time() -> void:
	var down := 0
	for step: int in 1000:
		var lift := RabbitView.sit_up(2468, step * 0.1)
		assert_float(lift).is_between(0.0, RabbitView.SIT_RAD + 0.001)
		if lift < 0.05:
			down += 1
	assert_int(down).is_between(650, 900)


func test_the_rabbit_is_small_with_long_ears() -> void:
	var box := RabbitView.rabbit_mesh().get_aabb()
	assert_float(box.size.z).is_less(0.5)
	assert_float(box.end.y).is_greater(0.3)
	assert_float(box.position.y).is_greater_equal(-0.01)
