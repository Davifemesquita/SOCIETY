extends GdUnitTestSuite
## Fase 369: o vidro aceso da janela de volta redonda do MegaKit leva o arco (o shader corta os cantos de cima).

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()


func after_test() -> void:
	BuildingKit.reset_megakit()


func _spec(def_id: StringName, tier: StringName = &"", id: int = 7) -> BuildingKit.Spec:
	var record := BuildingRecord.new(id, def_id, 0, Vector2i(10, 10), 0)
	if tier != &"":
		record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func _all_specs() -> Array[BuildingKit.Spec]:
	var specs: Array[BuildingKit.Spec] = []
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		for id: int in range(1, 13):
			specs.append(_spec(&"house", tier, id))
	for def_id: StringName in [&"church", &"market", &"school", &"theater", &"warehouse", &"trading_post", &"brewery"]:
		var spec := _spec(def_id)
		if spec != null:
			specs.append(spec)
	return specs


func test_one_rise_per_window() -> void:
	for on: bool in [true, false]:
		BuildingKit.use_megakit(on)
		for spec: BuildingKit.Spec in _all_specs():
			assert_int(BuildingKit.window_rises(spec).size()).is_equal(BuildingKit.windows(spec).size())


func test_the_arched_front_takes_the_arch() -> void:
	BuildingKit.use_megakit(true)
	var church := _spec(&"church")
	assert_bool(church.arched).is_true()
	var rises := BuildingKit.window_rises(church)
	var arched := 0
	for rise: float in rises:
		assert_float(rise).is_between(0.0, 0.5)
		if rise > 0.0:
			arched += 1
	assert_int(arched).is_greater(0)


func test_the_kenney_lights_stay_square() -> void:
	BuildingKit.use_megakit(false)
	for spec: BuildingKit.Spec in _all_specs():
		for rise: float in BuildingKit.window_rises(spec):
			assert_float(rise).is_equal(0.0)


func test_the_arch_is_half_the_width() -> void:
	BuildingKit.use_megakit(true)
	var church := _spec(&"church")
	var size := church.size_m()
	var step := size.x / church.cells.x
	var gap := BuildingKit.opening(church, 0)
	var expected := minf(step * gap.x * 0.5 / (church.floor_m() * gap.z), 0.5)
	assert_float(BuildingKit.window_rises(church)[0]).is_equal_approx(expected, 0.001)
