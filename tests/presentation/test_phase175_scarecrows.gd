extends GdUnitTestSuite
## Espantalho no campo (Fase 175): só nos campos do resto certo das fazendas de trigo e de batata; dentro do campo, no vão
## entre duas fileiras, no chão; nenhum no campo do lúpulo nem no campo sem dono; o espantalho tem a altura de gente e os
## braços abertos.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> ScarecrowView:
	var view: ScarecrowView = auto_free(ScarecrowView.new())
	add_child(view)
	view.setup(_sim)
	return view


## A fazenda e os campos que ela pede; devolve os campos.
func _farm(def_id: StringName, origin: Vector2i) -> Array[int]:
	SimFixture.place(_sim, def_id, origin, 0)
	var def := _sim.data.building(def_id)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var fields: Array[int] = []
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if fields.size() >= def.modules_required:
				break
			var result := _sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND, def.module_id, Vector2i(x, y), 0))
			if result.ok():
				fields.append(result.placed[0])
	assert_int(fields.size()).is_equal(def.modules_required)
	return fields


func _expected(fields: Array[int]) -> int:
	var count := 0
	for id: int in fields:
		if posmod(id, ScarecrowView.SCARECROW_EVERY) == ScarecrowView.SCARECROW_REST:
			count += 1
	return count


func test_wheat_and_potato_fields_of_the_right_rest_get_a_scarecrow() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var wheat := _farm(&"wheat_farm", Vector2i(10, 21))
	var potato := _farm(&"potato_farm", Vector2i(50, 21))
	var view := _view()
	var expected := _expected(wheat) + _expected(potato)
	assert_int(expected).is_greater(0)
	assert_int(view.scarecrow_count()).is_equal(expected)


func test_the_scarecrow_stands_in_a_gap_between_rows_inside_the_field() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var fields := _farm(&"potato_farm", Vector2i(10, 21))
	var owners := _sim.derived_state().module_owner
	var grid := _sim.world.island(SimFixture.ISLAND)
	var spacing: Vector2 = CropView.SPACING[BuildingDef.Crop.TUBER]
	var checked := 0
	for id: int in fields:
		var record := _sim.world.building(id)
		var found: Variant = ScarecrowView.spot(_sim, record, owners)
		if posmod(id, ScarecrowView.SCARECROW_EVERY) != ScarecrowView.SCARECROW_REST:
			assert_object(found).is_null()
			continue
		assert_bool(found is Transform3D).is_true()
		var place: Transform3D = found
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var center := grid.rect_world(area)
		var local := CropView._row_frame(record).inverse() * (place.origin - center)
		var half := Vector2(area.size) * _sim.config.cell_size_m * 0.5
		assert_float(absf(local.x)).is_less(half.x - CropView.HEADLAND_M)
		assert_float(absf(local.z)).is_less(half.y - CropView.MARGIN_M)
		# no vão: meia fileira de cada planta
		var rows := maxi(1, floori((half.y - CropView.MARGIN_M) * 2.0 / spacing.y) + 1)
		var from_row := fposmod(local.z + (rows - 1) * spacing.y * 0.5, spacing.y)
		assert_float(absf(from_row - spacing.y * 0.5)).is_less(0.01)
		assert_float(place.origin.y).is_equal_approx(grid.height_at(place.origin.x, place.origin.z), 0.01)
		# de pé: torto só um pouco
		assert_float(place.basis.y.normalized().dot(Vector3.UP)).is_greater(0.99)
		checked += 1
	assert_int(checked).is_greater(0)


func test_no_scarecrow_in_hops_or_in_fields_without_a_farm() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	_farm(&"hop_farm", Vector2i(10, 21))
	for x: int in [50, 54, 58]:
		_sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND, &"field", Vector2i(x, 30), 0))
	var view := _view()
	assert_int(view.scarecrow_count()).is_equal(0)


func test_the_scarecrow_is_as_tall_as_a_man_with_open_arms() -> void:
	var box := ScarecrowView.scarecrow_mesh().get_aabb()
	assert_float(box.end.y).is_between(1.9, 2.1)
	assert_float(box.size.x).is_between(1.2, 1.5)
	assert_float(box.size.z).is_less(0.7)


func test_the_view_follows_new_farms() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var view := _view()
	assert_int(view.scarecrow_count()).is_equal(0)
	var fields := _farm(&"wheat_farm", Vector2i(10, 21))
	view.rebuild()
	assert_int(view.scarecrow_count()).is_equal(_expected(fields))
