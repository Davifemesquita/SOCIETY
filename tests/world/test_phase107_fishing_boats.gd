extends GdUnitTestSuite
## Barcos de pesca (Fase 107): cada cabana de pesca tem um barco; o ponto de amarra e o pesqueiro ficam em água funda; a
## volta sai da amarra, passa pelo pesqueiro e volta, sem salto; com a cabana parada o barco fica amarrado.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _fishery() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"fishery", 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"fishery", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_route_stays_in_deep_water() -> void:
	var record := _fishery()
	var path := FishingBoatView.route(_sim, record)
	assert_int(path.size()).is_equal(2)
	for spot: Vector3 in path:
		assert_bool(HarborView.afloat(_sim.world, spot)).is_true()
	# o pesqueiro fica mar adentro, mais longe da cabana que a amarra
	var def := _sim.def_of(record)
	var center := _sim.world.island(0).rect_world(Footprint.rect(record.origin, def.size, record.rotation))
	assert_float(path[1].distance_to(center)).is_greater(path[0].distance_to(center))


func test_the_trip_goes_out_and_back_without_jumps() -> void:
	var home := Vector3(10.0, 0.0, 0.0)
	var far := Vector3(10.0, 0.0, -40.0)
	assert_float(FishingBoatView.pose(home, far, 0.0).origin.distance_to(home)).is_less(0.01)
	assert_float(FishingBoatView.pose(home, far, FishingBoatView.OUT_END).origin.distance_to(far)).is_less(0.01)
	assert_float(FishingBoatView.pose(home, far, FishingBoatView.FISH_END).origin.distance_to(far)).is_less(0.01)
	assert_float(FishingBoatView.pose(home, far, 0.9999).origin.distance_to(home)).is_less(0.05)
	# passo a passo, o barco nunca anda mais que um pedaço da volta de uma vez
	var last := FishingBoatView.pose(home, far, 0.0).origin
	for step: int in range(1, 1001):
		var at := FishingBoatView.pose(home, far, step / 1000.0).origin
		assert_float(at.distance_to(last)).is_less(0.5)
		last = at
	# na ida a proa (−Z do casco) olha para o pesqueiro
	var going := FishingBoatView.pose(home, far, FishingBoatView.OUT_END * 0.5)
	assert_float((-going.basis.z).dot((far - home).normalized())).is_greater(0.99)


func test_one_boat_per_fishery_moored_when_idle() -> void:
	var record := _fishery()
	var view: FishingBoatView = auto_free(FishingBoatView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.boat_count()).is_equal(1)
	var path := FishingBoatView.route(_sim, record)
	record.state = BuildingRecord.State.IDLE
	view._process(30.0)
	var boat := view.boat_of(record.id)
	assert_float(Vector2(boat.position.x, boat.position.z).distance_to(Vector2(path[0].x, path[0].z))).is_less(0.01)
