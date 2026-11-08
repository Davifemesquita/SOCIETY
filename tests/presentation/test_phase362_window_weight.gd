extends GdUnitTestSuite
## Fase 362: com o MegaKit, a janela da forma só na fachada da frente; nos lados e nos fundos, a larga reta, a mais leve. As casas
## ficam no peso das do Kenney (até 20% a mais numa casa; no pior caso de cada classe, mais leves).

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()


func after_test() -> void:
	BuildingKit.use_megakit(false)


func _spec(def_id: StringName, tier: StringName = &"") -> BuildingKit.Spec:
	var record := BuildingRecord.new(7, def_id, 0, Vector2i(10, 10), 0)
	if tier != &"":
		record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func test_only_the_front_keeps_the_window_of_the_shape() -> void:
	BuildingKit.use_megakit(true)
	var church := _spec(&"church")
	assert_int(BuildingKit.window_index(church, 0)).is_equal(0)
	for face: int in [1, 2, 3]:
		assert_int(BuildingKit.window_index(church, face)).is_equal(1)
		assert_bool(BuildingKit.opening(church, face) == BuildingKit.MEGAKIT_OPENINGS[1]).is_true()


func test_the_kenney_ignores_the_face() -> void:
	var spec := _spec(&"house", &"artisans")
	for face: int in 4:
		assert_int(BuildingKit.window_index(spec, face)).is_equal(posmod(spec.window_style, 3))


func test_houses_stay_near_the_kenney_weight() -> void:
	for tier: StringName in [&"workers", &"artisans", &"engineers", &"investors"]:
		var spec := _spec(&"house", tier)
		BuildingKit.use_megakit(false)
		var kenney := BuildingKit.triangles(spec)
		BuildingKit.use_megakit(true)
		var megakit := BuildingKit.triangles(spec)
		assert_int(megakit).override_failure_message(String(tier)).is_less_equal(int(kenney * 1.2))
