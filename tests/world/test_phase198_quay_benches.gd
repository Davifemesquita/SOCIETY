extends GdUnitTestSuite
## Bancos no cais (Fase 198): os bancos ficam no alto do cais de pedra, para dentro da beira, virados para o mar, longe dos
## lampiões, das cisternas, dos mastros e das escadas, fora da frente do entreposto; nada sem cais de pedra (ilha plana).

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


func test_the_benches_sit_on_the_quay_facing_the_sea() -> void:
	var record := _post()
	var segments := HarborView.stone_quay(_sim, record)
	var benches := QuayBenchView.benches(_sim, record)
	if segments.is_empty():
		assert_array(benches).is_empty()
		return
	assert_int(benches.size()).is_greater(0)
	for bench: Transform3D in benches:
		# num lanço do cais: o pé no alto dele, BENCH_IN_M para dentro da beira, a frente (−z) para o mar
		var found := false
		for segment: Array in segments:
			var front: Vector3 = segment[0]
			var outward: Vector3 = segment[1]
			var at := front - outward * QuayBenchView.BENCH_IN_M
			if Vector2(at.x - bench.origin.x, at.z - bench.origin.z).length() < 0.01:
				found = true
				assert_float(bench.origin.y).is_equal_approx(front.y, 0.001)
				assert_float((-bench.basis.z).dot(outward)).is_greater(0.99)
				assert_bool(QuayRailView._in_front(_sim, record, segment)).is_false()
		assert_bool(found).is_true()


func test_the_benches_keep_clear_of_the_other_quay_pieces() -> void:
	var record := _post()
	var others: Array[Vector3] = QuayRailView.lamps(_sim, record)
	for place: Transform3D in HarborView.cistern_places(_sim, record):
		others.append(place.origin)
	others.append_array(QuayMastView.masts(_sim, record))
	for frame: Transform3D in QuayStairsView.flights(_sim, record):
		others.append(frame.origin)
	for bench: Transform3D in QuayBenchView.benches(_sim, record):
		for other: Vector3 in others:
			assert_float(Vector2(other.x - bench.origin.x, other.z - bench.origin.z).length()).is_greater_equal(QuayBenchView.CLEAR_M)


func test_the_flat_island_has_none() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	var id := SimFixture.port(sim)
	assert_int(QuayBenchView.benches(sim, sim.world.building(id)).size()).is_equal(0)


func test_the_bench_faces_minus_z() -> void:
	var box := QuayBenchView.bench_mesh().get_aabb()
	# o encosto fica em +z, mais alto que o assento
	assert_float(box.position.y).is_greater_equal(-0.001)
	assert_float(box.end.z).is_greater(0.15)
	assert_float(box.size.x).is_between(1.2, 1.8)
