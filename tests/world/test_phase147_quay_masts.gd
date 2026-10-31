extends GdUnitTestSuite
## Mastros no cais (Fase 147): um mastro na ponta de cada lado do cais de pedra, longe da frente do entreposto e para
## dentro da beira; a flâmula é uma WindFlag (o tempo a vira); a ilha plana não tem; a flâmula afina até o rabo.

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


func test_one_mast_at_each_end_of_the_stone_quay() -> void:
	var record := _post()
	var feet := QuayMastView.masts(_sim, record)
	assert_int(feet.size()).is_less_equal(2)
	var plan := HarborView.walkway(_sim, record)
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	var sides: Array[float] = []
	for foot: Vector3 in feet:
		var t := (foot - start).dot(across)
		# fora da frente do prédio, um de cada lado
		assert_float(absf(t)).is_greater(width * 0.5)
		sides.append(signf(t))
		# para dentro da beira do cais (do lado da terra)
		assert_float((foot - start).dot(direction)).is_less(HarborView.QUAY_DEPTH_M)
	if sides.size() == 2:
		assert_float(sides[0]).is_equal(-sides[1])


func test_the_view_hangs_wind_flags() -> void:
	_post()
	var view: QuayMastView = auto_free(QuayMastView.new())
	add_child(view)
	view.setup(_sim)
	var flags := 0
	for node: Node in get_tree().get_nodes_in_group(WindFlag.GROUP):
		if view.is_ancestor_of(node):
			flags += 1
	assert_int(flags).is_equal(view.mast_count())


func test_the_flat_island_has_no_masts() -> void:
	var flat := SimFixture.simulation()
	flat.free_build = true
	var id := SimFixture.port(flat)
	assert_int(QuayMastView.masts(flat, flat.world.building(id)).size()).is_equal(0)


func test_the_pennant_tapers_to_a_swallowtail() -> void:
	var box := QuayMastView.pennant_mesh().get_aabb()
	assert_float(box.position.x).is_equal_approx(0.0, 0.001)
	assert_float(box.size.x).is_equal_approx(QuayMastView.PENNANT_M.x, 0.001)
	assert_float(box.size.y).is_equal_approx(QuayMastView.PENNANT_M.y, 0.001)
