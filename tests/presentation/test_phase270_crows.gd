extends GdUnitTestSuite
## Corvos no campo (Fase 270): nos campos novos (até YOUNG_UNTIL de crescimento), um a cada CROW_EVERY, corvos nos vãos entre
## as fileiras (os lugares da colheita); somem quando a plantação cresce; bicam em rajadas; o corvo de pé com o bico para a frente.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 60))


func test_crows_sit_in_young_fields_only() -> void:
	var places: Array[Transform3D] = []
	for k: int in 5:
		places.append(Transform3D(Basis.IDENTITY, Vector3(k, 0.0, 0.0)))
	# o campo da vez, novo: um a cada CROW_SPOT_EVERY lugares
	var young := CrowView.crow_spots(0, 0.1, places)
	assert_int(young.size()).is_equal(ceili(places.size() / float(CrowView.CROW_SPOT_EVERY)))
	# crescido, nenhum; o campo que não é da vez, nenhum; o campo sem conta (-1), nenhum
	assert_array(CrowView.crow_spots(0, CrowView.YOUNG_UNTIL + 0.05, places)).is_empty()
	assert_array(CrowView.crow_spots(1, 0.1, places)).is_empty()
	assert_array(CrowView.crow_spots(0, -1.0, places)).is_empty()


func test_the_view_follows_the_fields() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var farm := SimFixture.farm(_sim, &"wheat_farm", 10, 20)
	var record := _sim.world.building(farm)
	record.progress = 0.0
	var crops: CropView = auto_free(CropView.new())
	add_child(crops)
	crops.setup(_sim)
	var crows: CrowView = auto_free(CrowView.new())
	add_child(crows)
	crows.setup(crops, _sim.config)
	var young := 0
	for field_id: int in crops.field_ids():
		young += CrowView.crow_spots(field_id, crops.growth_of(field_id), crops.harvest_places(field_id)).size()
	assert_int(crows.crow_count()).is_equal(young)
	assert_int(young).is_greater(0)
	# com a plantação crescida, os corvos vão embora
	record.progress = 0.9
	crops.refresh()
	crows.refresh()
	assert_int(crows.crow_count()).is_equal(0)


func test_the_crow_pecks_in_bursts() -> void:
	var tilted := 0
	var still := 0
	for step: int in 400:
		var tilt := CrowView.peck(12345, step * 0.02)
		assert_float(tilt).is_between(0.0, CrowView.PECK_TILT + 0.001)
		if tilt > 0.05:
			tilted += 1
		elif tilt == 0.0:
			still += 1
	assert_int(tilted).is_greater(0)
	assert_int(still).is_greater(tilted)


func test_the_crow_stands_with_the_beak_ahead() -> void:
	var box := CrowView.crow_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_between(0.25, 0.35)
	assert_float(box.position.z).is_less(-0.2)
