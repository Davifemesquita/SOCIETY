extends GdUnitTestSuite
## Rede na varanda (Fase 199): só as casas com o alpendre tropical (e uma a cada HAMMOCK_EVERY) têm a rede, num vão que não é
## o da porta, entre dois esteios, no assoalho e na linha deles; a rede fica dentro da varanda (entre o guarda-corpo e a parede,
## abaixo da viga do beiral); o balanço gira em volta da linha dos nós.

var _config: GameConfig
var _sim: Simulation
var _tropical := -1


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	for index: int in _sim.world.islands.size():
		if _sim.world.is_tropical(index, _sim.data):
			_tropical = index


func _spec(island: int, tier: StringName, id: int) -> BuildingKit.Spec:
	var record := BuildingRecord.new(id, &"house", island, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func test_the_hammock_hangs_between_two_posts_off_the_door_bay() -> void:
	assert_int(_tropical).is_greater_equal(0)
	var count := 0
	for tier: StringName in [&"workers", &"artisans"]:
		for id: int in range(2, 24, HammockView.HAMMOCK_EVERY):
			var spec := _spec(_tropical, tier, id)
			var found: Variant = HammockView.hang(spec, id)
			assert_bool(found is Transform3D).is_true()
			var place: Transform3D = found
			count += 1
			var posts := HammockView.post_xs(spec)
			var bay := -1
			for k: int in spec.cells.x:
				if absf((posts[k] + posts[k + 1]) * 0.5 - place.origin.x) < 0.001:
					bay = k
			assert_int(bay).is_greater_equal(0)
			assert_int(bay).is_not_equal(spec.door_index)
			assert_float(place.origin.y).is_equal_approx(BuildingKit.VERANDA_DECK_M, 0.001)
			# esticada até o vão entre as faces de dentro dos dois esteios
			var inner := posts[bay + 1] - posts[bay] - BuildingKit.VERANDA_POST_M
			assert_float(place.basis.x.length() * HammockView.SPAN_M).is_equal_approx(inner, 0.001)
	assert_int(count).is_greater(0)


func test_the_hammock_stays_inside_the_porch() -> void:
	var spec := _spec(_tropical, &"workers", 4)
	var place: Transform3D = HammockView.hang(spec, 4)
	var box := BuildingKit.veranda_box(spec)
	var bounds := place * HammockView.hammock_mesh().get_aabb()
	# entre o guarda-corpo (a linha dos esteios) e a parede do corpo, acima do assoalho e abaixo da viga do beiral
	assert_float(bounds.position.z).is_greater_equal(place.origin.z - 0.001)
	assert_float(bounds.end.z).is_less(box.end.z)
	assert_float(bounds.position.y).is_greater(BuildingKit.VERANDA_DECK_M + 0.3)
	assert_float(bounds.end.y).is_less(spec.hall().floor_m() * BuildingKit.VERANDA_EAVE)


func test_only_the_tropical_porch_and_every_other_house() -> void:
	for tier: StringName in [&"workers", &"artisans"]:
		assert_object(HammockView.hang(_spec(0, tier, 4), 4)).is_null()
	assert_object(HammockView.hang(_spec(_tropical, &"peasants", 4), 4)).is_null()
	var record := BuildingRecord.new(3, &"house", _tropical, Vector2i(10, 10), 0)
	record.tier = &"workers"
	assert_object(HammockView.spot(_sim, record)).is_null()


func test_the_swing_turns_about_the_knots() -> void:
	var knot := Vector3(0.4, HammockView.ANCHOR_UP_M, 0.1)
	for step: int in 20:
		var turn := HammockView.swing(777, step * 0.37)
		assert_float(turn.origin.distance_to(Vector3.ZERO) - 0.0).is_less(HammockView.ANCHOR_UP_M * HammockView.SWING_RAD * 1.2)
		# a linha dos nós não sai do lugar
		assert_float((turn * knot).distance_to(knot)).is_less(0.0001)
		assert_float(absf(turn.basis.get_euler().x)).is_less_equal(HammockView.SWING_RAD + 0.0001)
