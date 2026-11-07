extends GdUnitTestSuite
## Caixas da colheita (Fase 157): nenhum caixote ou saco no campo novo; eles vão aparecendo a partir do degrau HARVEST_FROM
## e estão todos à vista no degrau cheio; somem na colheita; ficam dentro do campo, entre as fileiras, no chão; a batata
## usa caixote e saco, o trigo só saco, a parreira só caixote.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> CropView:
	var view: CropView = auto_free(CropView.new())
	add_child(view)
	view.setup(_sim)
	return view


## A fazenda e os campos que ela pede; devolve [fazenda, campos].
func _farm(def_id: StringName, origin: Vector2i) -> Array:
	var farm := SimFixture.place(_sim, def_id, origin, 0)
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
	return [farm, fields]


func test_the_harvest_shows_up_near_the_end_of_the_cycle() -> void:
	assert_int(CropView.harvest_shown_at(0)).is_equal(0)
	assert_int(CropView.harvest_shown_at(CropView.HARVEST_FROM - 1)).is_equal(0)
	assert_int(CropView.harvest_shown_at(CropView.HARVEST_FROM)).is_greater(0)
	assert_int(CropView.harvest_shown_at(CropView.GROWTH_STEPS)).is_equal(CropView.HARVEST_SPOTS)
	var last := 0
	for step: int in CropView.GROWTH_STEPS + 1:
		var shown := CropView.harvest_shown_at(step)
		assert_int(shown).is_greater_equal(last)
		last = shown


func test_crates_and_sacks_come_and_go_with_the_farm_cycle() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var potato := _farm(&"potato_farm", Vector2i(10, 21))
	var farm_id: int = potato[0]
	var farm := _sim.world.building(farm_id)
	var fields: Array[int] = potato[1]
	var field := fields[0]
	var view := _view()
	farm.progress = 0.1
	view.refresh()
	assert_int(view.harvest_count(field)).is_equal(0)
	farm.progress = 0.75
	view.refresh()
	var middle := view.harvest_count(field)
	assert_int(middle).is_greater(0)
	farm.progress = 1.0
	view.refresh()
	assert_int(view.harvest_count(field)).is_equal(CropView.HARVEST_SPOTS)
	assert_int(view.harvest_count(field)).is_greater_equal(middle)
	# colhido: o ciclo volta a zero e as caixas somem
	farm.progress = 0.0
	view.refresh()
	assert_int(view.harvest_count(field)).is_equal(0)


func test_the_harvest_lies_inside_the_field_between_the_rows_on_the_ground() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var potato := _farm(&"potato_farm", Vector2i(10, 21))
	var fields: Array[int] = potato[1]
	var view := _view()
	var grid := _sim.world.island(SimFixture.ISLAND)
	var spacing: Vector2 = CropView.SPACING[BuildingDef.Crop.TUBER]
	# as fileiras de plantas, como a CropView as põe: a primeira em "first", uma a cada spacing.y
	var half := 3.0 * _sim.config.cell_size_m * 0.5 - CropView.MARGIN_M
	var rows := maxi(1, floori(half * 2.0 / spacing.y) + 1)
	var first := -(rows - 1) * spacing.y * 0.5
	for field_id: int in fields:
		var record := _sim.world.building(field_id)
		var places := view.harvest_places(field_id)
		assert_int(places.size()).is_equal(CropView.HARVEST_SPOTS * 2)
		var center := grid.rect_world(Footprint.rect(record.origin, Vector2i(3, 3), record.rotation))
		var across := Vector3.BACK if CropView.rows_along_x(record) else Vector3.RIGHT
		for place: Transform3D in places:
			assert_int(grid.building_at(grid.world_to_cell(place.origin))).is_equal(field_id)
			var ground := grid.height_at(place.origin.x, place.origin.z) + CropView.SOIL_M
			assert_float(place.origin.y).is_equal_approx(ground, 0.01)
			# no vão: a meia fileira das plantas, dentro das fileiras
			var rows_away := ((place.origin - center).dot(across) - first) / spacing.y
			assert_float(rows_away - floorf(rows_away)).is_equal_approx(0.5, 0.01)
			assert_float(rows_away).is_between(0.0, rows - 1.0)
			assert_float(place.basis.get_scale().x).is_equal_approx(CropView.HARVEST_SCALE, 0.01)


func test_each_crop_is_harvested_in_its_own_pieces() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var wheat := _farm(&"wheat_farm", Vector2i(4, 21))
	var vine := _farm(&"vineyard", Vector2i(40, 21))
	var potato := _farm(&"potato_farm", Vector2i(4, 4))
	var view := _view()
	var kinds := {}
	for pair: Array in [[wheat, "trigo"], [vine, "parreira"], [potato, "batata"]]:
		var farm: Array = pair[0]
		var fields: Array[int] = farm[1]
		var sacks := 0
		var crates := 0
		for spot: Array in view._harvest[fields[0]]:
			if spot[1]:
				sacks += 1
			else:
				crates += 1
		kinds[pair[1]] = [sacks, crates]
	assert_array(kinds["trigo"]).is_equal([CropView.HARVEST_SPOTS * 2, 0])
	assert_array(kinds["parreira"]).is_equal([0, CropView.HARVEST_SPOTS * 2])
	var mixed: Array = kinds["batata"]
	assert_int(mixed[0]).is_greater(0)
	assert_int(mixed[1]).is_greater(0)
