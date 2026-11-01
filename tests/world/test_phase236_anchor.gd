extends GdUnitTestSuite
## Âncora no cais (Fase 236): a âncora fica num lanço do cais de pedra do entreposto, para dentro da beira e longe das outras peças
## do cais (lampiões, cisternas, mastros, escadas, bancos e covos); a ilha plana não tem cais e não tem âncora; deitada, ela é
## mais comprida que alta, com o pé no chão e um braço erguido.

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


func test_the_anchor_lies_on_the_stone_quay_away_from_the_other_pieces() -> void:
	var record := _post()
	var segments := HarborView.stone_quay(_sim, record)
	var found: Variant = AnchorView.spot(_sim, record)
	if segments.size() < 4:
		return
	assert_bool(found is Transform3D).is_true()
	var place: Transform3D = found
	var on_quay := false
	for segment: Array in segments:
		var front: Vector3 = segment[0]
		var outward: Vector3 = segment[1]
		if (front - outward * AnchorView.ANCHOR_IN_M).distance_to(place.origin) < 0.01:
			on_quay = true
			# o −z do lugar aponta para o mar
			assert_float((-place.basis.z).dot(outward)).is_greater(0.99)
	assert_bool(on_quay).is_true()
	var others: Array[Vector3] = QuayRailView.lamps(_sim, record)
	others.append_array(QuayMastView.masts(_sim, record))
	for pile: Transform3D in LobsterPotView.pots(_sim, record):
		others.append(pile.origin)
	for bench: Transform3D in QuayBenchView.benches(_sim, record):
		others.append(bench.origin)
	for other: Vector3 in others:
		assert_float(Vector2(other.x - place.origin.x, other.z - place.origin.z).length()).is_greater_equal(AnchorView.CLEAR_M)


func test_a_flat_island_has_no_anchor() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	var id := SimFixture.place(sim, &"house", Vector2i(10, 10), 0)
	assert_object(AnchorView.spot(sim, sim.world.building(id))).is_null()


func test_the_anchor_lies_down_with_one_arm_raised() -> void:
	var box := AnchorView.anchor_mesh().get_aabb()
	assert_float(box.size.x).is_greater(box.size.y * 1.5)
	assert_float(box.position.y).is_greater(-0.1)
	assert_float(box.end.y).is_greater(0.6)
