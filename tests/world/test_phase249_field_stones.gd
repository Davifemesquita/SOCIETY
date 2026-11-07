extends GdUnitTestSuite
## Montes de pedra nos campos (Fase 249): um campo com dono a cada STONE_EVERY ganha o monte de pedras num canto da cabeceira,
## dentro do lote dele e fora das fileiras; o campo sem dono e o pasto não têm; o monte é baixo e largo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_heaps_sit_in_a_headland_corner_of_some_fields() -> void:
	SimFixture.road(_sim, Vector2i(2, 10), Vector2i(56, 10))
	SimFixture.farm(_sim, &"wheat_farm", 20, 10)
	var owners := _sim.derived_state().module_owner
	var fields := 0
	var heaps := 0
	for id: int in _sim.world.building_ids():
		var record := _sim.world.building(id)
		var def := _sim.def_of(record)
		if def.kind != BuildingDef.Kind.MODULE:
			continue
		fields += 1
		var found: Variant = FieldStoneView.spot(_sim, record, owners)
		if posmod(id, FieldStoneView.STONE_EVERY) != FieldStoneView.STONE_REST:
			assert_object(found).is_null()
			continue
		assert_bool(found is Transform3D).is_true()
		heaps += 1
		var place: Transform3D = found
		var grid := _sim.world.island(0)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		assert_bool(area.has_point(grid.world_to_cell(place.origin))).is_true()
		# na cabeceira: além do fim das fileiras, ao longo delas
		var local := CropView._row_frame(record).inverse() * (place.origin - grid.rect_world(area))
		var half := Vector2(area.size) * _sim.config.cell_size_m * 0.5
		assert_float(absf(local.x)).is_greater(half.x - CropView.HEADLAND_M - 0.01)
	assert_int(fields).is_greater(0)
	assert_int(heaps).is_greater(0)


func test_fields_without_a_farm_have_none() -> void:
	var owners := _sim.derived_state().module_owner
	for x: int in 6:
		var id := SimFixture.place(_sim, &"field", Vector2i(5 + x * 4, 25), 0)
		assert_object(FieldStoneView.spot(_sim, _sim.world.building(id), owners)).is_null()


func test_the_heap_is_low_and_wide() -> void:
	var box := FieldStoneView.heap_mesh().get_aabb()
	assert_float(box.size.x).is_greater(box.size.y * 1.5)
	assert_float(box.end.y).is_less(0.7)
	assert_float(box.position.y).is_greater(-0.1)
