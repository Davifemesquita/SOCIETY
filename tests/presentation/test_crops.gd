extends GdUnitTestSuite
## Plantações nos campos (Fase 14): o campo com dono ganha a planta da fazenda, dentro dele, e cresce com o
## ciclo; o campo sem dono fica só com a terra.

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


func test_every_field_farm_grows_its_own_crop() -> void:
	var seen := {}
	for def: BuildingDef in _sim.data.buildings:
		if def.module_id == &"field":
			assert_int(def.crop).override_failure_message(String(def.id)).is_not_equal(BuildingDef.Crop.NONE)
			seen[def.crop] = true
			var mesh := CropView.plant_mesh(def.crop)
			assert_int(mesh.get_surface_count()).is_equal(1)
			assert_float(mesh.get_aabb().position.y).is_greater_equal(-0.01)
		else:
			assert_int(def.crop).override_failure_message(String(def.id)).is_equal(BuildingDef.Crop.NONE)
	assert_int(seen.size()).is_equal(BuildingDef.Crop.size() - 1)


func test_fields_of_a_farm_get_plants_inside_them_and_lone_fields_stay_bare() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var wheat := _farm(&"wheat_farm", Vector2i(10, 21))
	SimFixture.place(_sim, &"field", Vector2i(70, 2), 0)
	var view := _view()
	var fields: Array[int] = wheat[1]
	assert_int(view.plant_count(BuildingDef.Crop.GRAIN)).is_greater(fields.size() * 50)
	assert_int(view.plant_count()).is_equal(view.plant_count(BuildingDef.Crop.GRAIN))
	var grid := _sim.world.island(SimFixture.ISLAND)
	for field_id: int in fields:
		assert_float(view.growth_of(field_id)).is_greater_equal(0.0)
		for index: int in 10:
			var cell := grid.world_to_cell(view.plant_transform(field_id, index).origin)
			assert_int(grid.building_at(cell)).is_equal(field_id)
	assert_float(view.growth_of(grid.building_at(Vector2i(71, 3)))).is_equal(-1.0)


func test_the_crop_grows_with_the_farm_cycle_and_starts_over_at_harvest() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var potato := _farm(&"potato_farm", Vector2i(10, 21))
	var farm_id: int = potato[0]
	var farm := _sim.world.building(farm_id)
	var potato_fields: Array[int] = potato[1]
	var field := potato_fields[0]
	var view := _view()
	farm.progress = 0.1
	view.refresh()
	var young := view.plant_transform(field, 0).basis.get_scale().y
	assert_float(view.growth_of(field)).is_equal_approx(0.1, 0.05)
	farm.progress = 0.9
	view.refresh()
	var grown := view.plant_transform(field, 0).basis.get_scale().y
	assert_float(grown).is_greater(young * 2.0)
	farm.progress = 0.0
	view.refresh()
	assert_float(view.plant_transform(field, 0).basis.get_scale().y).is_equal_approx(CropView.MIN_GROWTH, 0.01)


func test_a_new_farm_brings_its_crop_without_rebuilding_by_hand() -> void:
	var view := _view()
	assert_int(view.plant_count()).is_equal(0)
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	_farm(&"hop_farm", Vector2i(10, 21))
	await await_idle_frame()
	await await_idle_frame()
	assert_int(view.plant_count(BuildingDef.Crop.HOPS)).is_greater(0)
