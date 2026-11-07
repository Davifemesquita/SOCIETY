extends GdUnitTestSuite
## Cormorões nas estacas (Fase 231): os cormorões ficam no alto da estaca do meio de parte dos feixes de atracação do entreposto,
## nunca fora de um feixe; outros prédios não têm; o cormorão de asas abertas é mais largo que alto.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _post() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found := SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_birds_perch_on_top_of_some_mooring_piles() -> void:
	var record := _post()
	var def := _sim.def_of(record)
	var clusters := MooringPileView.spots(_sim.world, record, def, _config.cell_size_m)
	var birds := CormorantView.perches(_sim.world, record, def, _config.cell_size_m)
	assert_int(birds.size()).is_less_equal(clusters.size())
	if not clusters.is_empty():
		assert_int(birds.size()).is_greater(0)
	for bird: Transform3D in birds:
		var found := false
		for cluster: Transform3D in clusters:
			var top := cluster * Vector3(0.0, MooringPileView.TOPS_M[0], 0.0) - Vector3(0.0, CormorantView.SIT_M, 0.0)
			if top.distance_to(bird.origin) < 0.01:
				found = true
		assert_bool(found).is_true()


func test_other_buildings_have_none() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	var id := SimFixture.place(sim, &"house", Vector2i(10, 10), 0)
	var record := sim.world.building(id)
	assert_int(CormorantView.perches(sim.world, record, sim.def_of(record), 2.0).size()).is_equal(0)


func test_the_wings_are_spread() -> void:
	var box := CormorantView.cormorant_mesh().get_aabb()
	assert_float(box.size.x).is_greater(box.size.y)
	assert_float(box.position.y).is_greater_equal(-0.01)
