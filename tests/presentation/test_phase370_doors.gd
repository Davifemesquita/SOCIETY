extends GdUnitTestSuite
## Fase 370: as portas do MegaKit (uma, quatro e oito tábuas) pelo tipo do prédio (as casas ficam com a simples).

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()


func after_test() -> void:
	BuildingKit.reset_megakit()


func _spec(def_id: StringName, tier: StringName = &"") -> BuildingKit.Spec:
	var record := BuildingRecord.new(7, def_id, 0, Vector2i(10, 10), 0)
	if tier != &"":
		record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func test_every_door_piece_is_packed() -> void:
	BuildingKit.use_megakit(true)
	for piece: String in BuildingKit.MEGAKIT_DOORS:
		assert_bool(ResourceLoader.exists(BuildingKit.MEGAKIT_DIR + piece + ".res")).override_failure_message(piece).is_true()


func test_the_door_is_stable_and_varied() -> void:
	var styles := {}
	for name: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors", &"church", &"bakery",
			&"tavern", &"school", &"warehouse", &"sawmill", &"brewery"]:
		var style := BuildingKit.door_style_of(name)
		assert_int(style).is_equal(BuildingKit.door_style_of(name))
		assert_int(style).is_between(0, BuildingKit.MEGAKIT_DOORS.size() - 1)
		styles[style] = true
	assert_int(styles.size()).is_greater_equal(2)


func test_the_house_keeps_the_plain_door() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		assert_int(_spec(&"house", tier).door_style).is_equal(0)


func test_the_other_buildings_take_the_door_of_their_kind() -> void:
	for def_id: StringName in [&"bakery", &"tavern", &"sawmill", &"brewery"]:
		var spec := _spec(def_id)
		assert_int(spec.door_style).is_equal(BuildingKit.door_style_of(def_id))
		assert_int(spec.hall().door_style).is_equal(spec.door_style)


func test_another_door_changes_the_mesh() -> void:
	BuildingKit.use_megakit(true)
	var spec := _spec(&"house", &"workers")
	var counts := {}
	for style: int in BuildingKit.MEGAKIT_DOORS.size():
		spec.door_style = style
		counts[BuildingKit.triangles(spec)] = true
	assert_int(counts.size()).is_greater(1)
