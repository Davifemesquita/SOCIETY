extends GdUnitTestSuite
## Escada do cais (Fase 194): os lances descem do alto do cais de pedra até dentro da água, encostados no paredão do lado do
## mar e longe do prédio; os degraus descem um a um; nada sem cais de pedra (ilha plana).

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


func test_flights_go_down_from_the_quay_into_the_water() -> void:
	var record := _post()
	var frames := QuayStairsView.flights(_sim, record)
	if HarborView.stone_quay(_sim, record).is_empty():
		assert_array(frames).is_empty()
		return
	for frame: Transform3D in frames:
		var flight := QuayStairsView.step_places(frame)
		assert_int(flight.size()).is_greater(2)
		# cada degrau mais baixo que o anterior, e o pé de todos dentro da água
		var last_top := INF
		for step: Transform3D in flight:
			var top := step.origin.y + step.basis.y.length() * 0.5
			var bottom := step.origin.y - step.basis.y.length() * 0.5
			assert_float(top).is_less(last_top)
			assert_float(bottom).is_less(0.0)
			last_top = top
		# o último degrau perto da água
		assert_float(last_top).is_less(QuayStairsView.STEP_RISE_M * 1.5)
		# do lado do mar do paredão (o z do lance sai para o mar)
		var center := flight[0].origin - frame.origin
		assert_float(center.dot(frame.basis.z.normalized())).is_greater(0.0)


func test_no_flight_without_a_stone_quay() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 60))
	sim.free_build = true
	sim.ignore_terrain = true
	var id := SimFixture.place(sim, &"trading_post", Vector2i(10, 0), 0)
	assert_array(QuayStairsView.flights(sim, sim.world.building(id))).is_empty()
