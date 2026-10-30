extends GdUnitTestSuite
## Cais de pedra (Fase 106): dos dois lados do entreposto, lanços retos de cantaria ao longo da costa, na frente do cais
## de tábuas e um pouco abaixo dele; param onde a terra sobe; o píer e a ilha plana não têm.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _trading_post() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_quay_runs_straight_along_the_front_of_the_trading_post() -> void:
	var record := _trading_post()
	var plan := HarborView.walkway(_sim, record)
	var direction: Vector3 = plan["direction"]
	var start: Vector3 = plan["start"]
	var deck: float = plan["deck"]
	var segments := HarborView.stone_quay(_sim, record)
	assert_int(segments.size()).is_greater(0)
	var front_line := Vector2(start.x, start.z).dot(Vector2(direction.x, direction.z)) + HarborView.QUAY_DEPTH_M
	for segment: Array in segments:
		var front: Vector3 = segment[0]
		var outward: Vector3 = segment[1]
		# todos na mesma linha (reto, não na escada das células), para o mar, abaixo das tábuas
		assert_float(Vector2(front.x, front.z).dot(Vector2(direction.x, direction.z))).is_equal_approx(front_line, 0.01)
		assert_float(outward.distance_to(direction)).is_less(0.001)
		assert_float(front.y).is_equal_approx(deck - HarborView.STONE_QUAY_BELOW_DECK_M, 0.001)
		# e nunca enterrado num morro: a terra atrás do lanço não sobe além do limite
		var inland := front - outward * (HarborView.QUAY_DEPTH_M + HarborView.STONE_QUAY_BACK_M)
		assert_float(_sim.world.surface_height(inland.x, inland.z)).is_less_equal(front.y + HarborView.STONE_QUAY_RISE_M)


func test_the_quay_reaches_past_the_building_but_not_forever() -> void:
	var record := _trading_post()
	var plan := HarborView.walkway(_sim, record)
	var half: Vector2 = plan["half"]
	var direction: Vector3 = plan["direction"]
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	var segments := HarborView.stone_quay(_sim, record)
	var most := ceili((width * 0.5 + HarborView.STONE_QUAY_REACH_M) / HarborView.STONE_QUAY_STEP_M) * 2
	assert_int(segments.size()).is_less_equal(most)


func test_no_stone_quay_on_the_flat_island() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 30))
	sim.free_build = true
	sim.ignore_terrain = true
	var id := SimFixture.place(sim, &"trading_post", Vector2i(10, 0), 2)
	assert_int(HarborView.stone_quay(sim, sim.world.building(id)).size()).is_equal(0)
