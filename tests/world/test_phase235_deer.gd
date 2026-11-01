extends GdUnitTestSuite
## Cervos na beira da mata (Fase 235): os grupos ficam em capim livre com mata perto, longe das vilas, só nas ilhas temperadas;
## cada grupo tem de dois a quatro cervos, o primeiro com galhada; a cabeça pasta baixada quase sempre e se ergue às vezes.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_herds_graze_on_free_meadow_by_the_forest() -> void:
	var grid := _sim.world.island(0)
	var herds := DeerView.herds(_sim.world, _sim.data, 0)
	assert_int(herds.size()).is_greater(0)
	for cell: Vector2i in herds:
		assert_bool(DeerView._meadow(grid, cell)).is_true()
	var deer := DeerView.deer(_sim.world, _sim.data, 0)
	assert_int(deer.size()).is_between(herds.size() * 2, herds.size() * 4)
	var stags := 0
	for one: Array in deer:
		var stag: bool = one[2]
		if stag:
			stags += 1
	assert_int(stags).is_equal(herds.size())


func test_a_town_keeps_the_deer_away() -> void:
	var herds := DeerView.herds(_sim.world, _sim.data, 0)
	assert_int(herds.size()).is_greater(0)
	var cell := herds[0]
	var found := SiteFinder.find(_sim, &"house", 0, cell)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"house", origin, 0)).ok()).is_true()
	if (Vector2(origin) - Vector2(cell)).length() < SealView.WILD_CELLS:
		assert_bool(DeerView.herds(_sim.world, _sim.data, 0).has(cell)).is_false()


func test_tropical_islands_and_the_flat_island_have_none() -> void:
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			assert_int(DeerView.herds(_sim.world, _sim.data, island_id).size()).is_equal(0)
	var flat := SimFixture.simulation(Vector2i(60, 30))
	assert_int(DeerView.herds(flat.world, flat.data, 0).size()).is_equal(0)


func test_the_head_grazes_most_of_the_time() -> void:
	var down := 0
	for step: int in 1000:
		var pitch := DeerView.head_pitch(4321, step * 0.1)
		assert_float(pitch).is_between(0.0, DeerView.GRAZE_RAD + 0.001)
		if pitch > DeerView.GRAZE_RAD * 0.9:
			down += 1
	assert_int(down).is_between(600, 900)
