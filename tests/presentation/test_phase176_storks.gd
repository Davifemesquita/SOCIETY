extends GdUnitTestSuite
## Cegonha na chaminé (Fase 176): o ninho só nas casas de camponeses e operários do resto certo que têm chaminé; assentado no
## capitel, acima do telhado e dentro da planta da casa; a chaminé com ninho não fumega; a cegonha vira com o tempo; a cegonha
## tem cerca de um metro e cabe no ninho.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true
	SimFixture.road(_sim, Vector2i(2, 10), Vector2i(110, 10))


func _view() -> StorkView:
	var view: StorkView = auto_free(StorkView.new())
	add_child(view)
	view.setup(_sim)
	return view


func _street(tier: StringName) -> Array[int]:
	var ids: Array[int] = []
	for x: int in range(4, 100, 3):
		ids.append(SimFixture.house(_sim, x, 10, tier, 5.0))
	return ids


func _nested(ids: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for id: int in ids:
		var record := _sim.world.building(id)
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		if StorkView.has_nest(_sim, record) and spec.chimney:
			result.append(id)
	return result


func test_only_the_right_peasant_and_worker_houses_with_a_chimney_get_a_nest() -> void:
	var ids := _street(&"workers")
	var expected := _nested(ids)
	assert_int(expected.size()).is_greater(0)
	var view := _view()
	assert_int(view.stork_count()).is_equal(expected.size())
	for id: int in ids:
		var has := StorkView.nest_place(_sim, _sim.world.building(id)) != null
		assert_bool(has).is_equal(id in expected)


func test_no_nest_on_richer_houses() -> void:
	_street(&"artisans")
	var view := _view()
	assert_int(view.stork_count()).is_equal(0)


func test_the_nest_sits_on_the_chimney_above_the_roof() -> void:
	var ids := _nested(_street(&"peasants"))
	assert_int(ids.size()).is_greater(0)
	for id: int in ids:
		var record := _sim.world.building(id)
		var nest: Transform3D = StorkView.nest_place(_sim, record)
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		var model := BuildingView.model_place(_sim.world.island(record.island_id), record,
				Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation))
		var mouth: Vector3 = BuildingKit.chimney_top(spec)
		# o pé do ninho no capitel, os potes dentro dele
		assert_float(nest.origin.distance_to(model * (mouth - Vector3(0.0, BuildingKit.CHIMNEY_POT_M, 0.0)))).is_less(0.001)
		assert_float(StorkView.NEST_M).is_greater(BuildingKit.CHIMNEY_POT_M - 0.05)
		assert_float(nest.origin.y).is_greater(model.origin.y + spec.height_m)
		var area := _sim.world.island(record.island_id).rect_world(Footprint.rect(record.origin, Vector2i(3, 3), 0))
		assert_float(absf(nest.origin.x - area.x)).is_less(3.0)
		assert_float(absf(nest.origin.z - area.z)).is_less(3.0)


func test_a_chimney_with_a_nest_does_not_smoke() -> void:
	var ids := _nested(_street(&"workers"))
	assert_int(ids.size()).is_greater(0)
	for id: int in ids:
		assert_object(ChimneySmokeView.chimney_world(_sim, _sim.world.building(id))).is_null()


func test_the_stork_turns_now_and_then() -> void:
	_street(&"workers")
	var view := _view()
	assert_int(view.stork_count()).is_greater(0)
	var before := view.headings.duplicate()
	var changed := false
	for step: int in 20:
		view.advance(3.0)
		if view.headings != before:
			changed = true
			break
	assert_bool(changed).is_true()
	# ela fica no alto do ninho
	assert_float(view.spots[0].y).is_greater(0.0)


func test_the_stork_is_about_a_metre_tall_and_fits_the_nest() -> void:
	var stork := StorkView.stork_mesh().get_aabb()
	assert_float(stork.end.y).is_between(0.9, 1.1)
	assert_float(maxf(stork.size.x, stork.size.z)).is_less(StorkView.NEST_RADIUS_M * 2.0)
	var nest := StorkView.nest_mesh().get_aabb()
	assert_float(nest.size.x).is_between(StorkView.NEST_RADIUS_M * 2.0, StorkView.NEST_RADIUS_M * 2.0 + 0.5)
