extends GdUnitTestSuite
## Covos no cais (Fase 222): poucas pilhas, afastadas umas das outras, no alto do cais de pedra, para dentro da beira, ao longo
## dela, longe dos lampiões, das cisternas, dos mastros, das escadas e dos bancos, fora da frente do entreposto; nada sem cais de
## pedra (ilha plana).

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


func test_the_pots_sit_on_the_quay_along_the_edge() -> void:
	var record := _post()
	var segments := HarborView.stone_quay(_sim, record)
	var pots := LobsterPotView.pots(_sim, record)
	if segments.is_empty():
		assert_array(pots).is_empty()
		return
	assert_int(pots.size()).is_greater(0)
	for pile: Transform3D in pots:
		var found := false
		for i: int in segments.size():
			var segment: Array = segments[i]
			var front: Vector3 = segment[0]
			var outward: Vector3 = segment[1]
			var at := front - outward * LobsterPotView.POT_IN_M
			if Vector2(at.x - pile.origin.x, at.z - pile.origin.z).length() < 0.01:
				found = true
				assert_float(pile.origin.y).is_equal_approx(front.y, 0.001)
				# o x ao longo da beira, o −z para o mar
				assert_float((-pile.basis.z).dot(outward)).is_greater(0.99)
				assert_bool(QuayRailView._in_front(_sim, record, segment)).is_false()
		assert_bool(found).is_true()


func test_the_pots_keep_clear_of_the_other_quay_pieces() -> void:
	var record := _post()
	var others: Array[Vector3] = QuayRailView.lamps(_sim, record)
	for place: Transform3D in HarborView.cistern_places(_sim, record):
		others.append(place.origin)
	others.append_array(QuayMastView.masts(_sim, record))
	for frame: Transform3D in QuayStairsView.flights(_sim, record):
		others.append(frame.origin)
	for bench: Transform3D in QuayBenchView.benches(_sim, record):
		others.append(bench.origin)
	for pile: Transform3D in LobsterPotView.pots(_sim, record):
		for other: Vector3 in others:
			assert_float(Vector2(other.x - pile.origin.x, other.z - pile.origin.z).length()).is_greater_equal(
					LobsterPotView.CLEAR_M)


func test_the_flat_island_has_none() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	var id := SimFixture.port(sim)
	assert_int(LobsterPotView.pots(sim, sim.world.building(id)).size()).is_equal(0)


func test_the_pile_stays_on_the_quay_top() -> void:
	var box := LobsterPotView.pot_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.03)
	assert_float(box.end.y).is_less(LobsterPotView.POT_H * 2.0 + 0.1)
	# ao longo da beira até ~1,4 m de cada lado, e funda o bastante para não passar da beira (POT_IN_M)
	assert_float(box.size.x).is_less(2.8)
	assert_float(box.end.z).is_less(LobsterPotView.POT_IN_M)
	assert_float(-box.position.z).is_less(LobsterPotView.POT_IN_M)


func test_few_piles_spaced_apart() -> void:
	var record := _post()
	var pots := LobsterPotView.pots(_sim, record)
	assert_int(pots.size()).is_less_equal(LobsterPotView.PILES_PER_POST)
	for a: int in pots.size():
		for b: int in range(a + 1, pots.size()):
			assert_float(pots[a].origin.distance_to(pots[b].origin)).is_greater_equal(LobsterPotView.PILE_GAP_M)
