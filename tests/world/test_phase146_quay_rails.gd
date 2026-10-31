extends GdUnitTestSuite
## Grade e lampiões no cais (Fase 146): a grade corre na beira do cais de pedra, para dentro dela e no alto do capeamento,
## aberta nos cabeços e diante do entreposto; os lampiões ficam num lanço a cada LAMP_EVERY, fora dos cabeços; a ilha
## plana (sem cais de pedra) não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _post() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_rail_runs_along_the_quay_edge_open_at_the_bollards() -> void:
	var record := _post()
	var segments := HarborView.stone_quay(_sim, record)
	if segments.is_empty():
		return
	var spans := QuayRailView.rails(_sim, record)
	assert_int(spans.size()).is_greater(0)
	assert_int(spans.size()).is_less(segments.size())
	for span: Array in spans:
		var a: Vector3 = span[0]
		var b: Vector3 = span[1]
		var middle := (a + b) * 0.5
		# casa com um lanço que não é de cabeço: a grade fica RAIL_IN_M para dentro da beira dele
		var matched := false
		for i: int in segments.size():
			var segment: Array = segments[i]
			var front: Vector3 = segment[0]
			var outward: Vector3 = segment[1]
			var inside := front - outward * QuayRailView.RAIL_IN_M
			if Vector2(inside.x - middle.x, inside.z - middle.z).length() < 0.01:
				matched = true
				assert_int(i % HarborView.SEA_WALL_BOLLARD_EVERY).is_not_equal(1)
				assert_float(middle.y).is_equal_approx(front.y + HarborView.COPING_M.x, 0.001)
		assert_bool(matched).is_true()
		assert_float(a.distance_to(b)).is_equal_approx(HarborView.STONE_QUAY_STEP_M, 0.01)


func test_the_lamps_stand_on_the_quay_away_from_the_bollards() -> void:
	var record := _post()
	var segments := HarborView.stone_quay(_sim, record)
	for foot: Vector3 in QuayRailView.lamps(_sim, record):
		var found := false
		for i: int in segments.size():
			var segment: Array = segments[i]
			var front: Vector3 = segment[0]
			var outward: Vector3 = segment[1]
			var spot := front - outward * QuayRailView.LAMP_IN_M
			if Vector2(spot.x - foot.x, spot.z - foot.z).length() < 0.01:
				found = true
				assert_int(i % QuayRailView.LAMP_EVERY).is_equal(QuayRailView.LAMP_REST)
				assert_int(i % HarborView.SEA_WALL_BOLLARD_EVERY).is_not_equal(1)
		assert_bool(found).is_true()


func test_the_flat_island_has_no_quay_rail() -> void:
	var flat := SimFixture.simulation()
	flat.free_build = true
	var id := SimFixture.port(flat)
	var record := flat.world.building(id)
	assert_int(QuayRailView.rails(flat, record).size()).is_equal(0)
	assert_int(QuayRailView.lamps(flat, record).size()).is_equal(0)
