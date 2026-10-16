extends GdUnitTestSuite
## Prédios de modelo (BuildingKit): toda forma vira malha dentro da área, com a porta na entrada em
## qualquer rotação, as casas iguais dividem a malha e o orçamento de polígonos fica de pé.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func test_the_kit_is_in_the_project() -> void:
	assert_bool(BuildingKit.available()).is_true()
	for piece: String in ["wall", "wall-door", "wall-doorway-round", "wall-window-shutters", "wall-window-glass",
			"wall-window-small", "wall-wood", "wall-wood-door", "wall-wood-doorway-round", "wall-wood-window-shutters",
			"wall-wood-window-glass", "wall-wood-window-small", "chimney"]:
		assert_bool(ResourceLoader.exists(BuildingKit.DIR + piece + ".glb")).override_failure_message(piece).is_true()


func test_every_building_but_fields_and_piers_gets_a_model_inside_its_area() -> void:
	for def: BuildingDef in _sim.data.buildings:
		var record := BuildingRecord.new(1, def.id, 0, Vector2i(10, 10), 0)
		if def.kind == BuildingDef.Kind.RESIDENCE:
			record.tier = &"peasants"
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		if def.kind in [BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER]:
			assert_object(spec).override_failure_message(String(def.id)).is_null()
			continue
		var box := BuildingKit.mesh(spec).get_aabb()
		var reach := Vector3(def.size.x * 2.0, 0.0, def.size.y * 2.0) * 0.5 + Vector3.ONE
		assert_float(absf(box.position.x)).override_failure_message(String(def.id)).is_less_equal(reach.x)
		assert_float(absf(box.position.z)).override_failure_message(String(def.id)).is_less_equal(reach.z)
		assert_float(box.end.y).override_failure_message(String(def.id)).is_greater_equal(spec.height_m)
		assert_float(box.position.y).override_failure_message(String(def.id)).is_less(0.0)
		assert_int(BuildingKit.triangles(spec)).override_failure_message(String(def.id)).is_between(100, 30000)


func test_houses_of_each_class_stay_within_the_polygon_budget_and_share_meshes() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		var record := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
		record.tier = tier
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		assert_int(BuildingKit.triangles(spec)).override_failure_message(String(tier)).is_less_equal(20000)
		var twin := BuildingRecord.new(7, &"house", 0, Vector2i(40, 20), 0)
		twin.tier = tier
		assert_object(BuildingKit.mesh(BuildingKit.spec_for(_sim, twin, 2.0))).is_same(BuildingKit.mesh(spec))
	var wood := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	wood.tier = &"peasants"
	assert_int(BuildingKit.spec_for(_sim, wood, 2.0).walls).is_equal(BuildingKit.Walls.WOOD)
	var brick := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	brick.tier = &"workers"
	assert_int(BuildingKit.spec_for(_sim, brick, 2.0).walls).is_equal(BuildingKit.Walls.PLASTER)


func test_the_door_faces_the_entrance_in_every_rotation() -> void:
	for def_id: StringName in [&"house", &"bakery", &"furnace", &"hospital", &"warehouse"]:
		var def := _sim.data.building(def_id)
		for rotation: int in 4:
			var record := BuildingRecord.new(3, def_id, 0, Vector2i(20, 20), rotation)
			record.tier = &"peasants"
			var spec := BuildingKit.spec_for(_sim, record, 2.0)
			var area := Footprint.rect(record.origin, def.size, rotation)
			var center := GridSpace.rect_center(area, 2.0)
			var place := Transform3D(Basis(Vector3.UP, -PI * 0.5 * rotation), center)
			var door := place * BuildingKit.door_position(spec)
			var entrance := GridSpace.cell_center(Footprint.entrance_cell(record.origin, def.size, rotation), 2.0)
			var gap := Vector2(entrance.x - door.x, entrance.z - door.z)
			var label := "%s rotação %d" % [def_id, rotation]
			# a porta fica na fachada, meia célula atrás do meio da célula de entrada
			assert_float(gap.length()).override_failure_message(label).is_less(1.4)
			var front := Footprint.front_direction(rotation)
			assert_float(gap.dot(Vector2(front))).override_failure_message(label).is_greater(0.5)


func test_roof_shapes_follow_the_building() -> void:
	var house := BuildingRecord.new(1, &"house", 0, Vector2i(10, 10), 0)
	house.tier = &"workers"
	var spec := BuildingKit.spec_for(_sim, house, 2.0)
	assert_int(spec.roof).is_equal([BuildingKit.Roof.GABLE_X, BuildingKit.Roof.GABLE_Z, BuildingKit.Roof.FLAT][BuildingView.house_variant(1)])
	var church := BuildingKit.spec_for(_sim, BuildingRecord.new(2, &"church", 0, Vector2i(10, 10), 0), 2.0)
	assert_int(church.roof).is_equal(BuildingKit.Roof.HIP)
	assert_int(church.door).is_equal(BuildingKit.Door.ARCH)
	var mine := BuildingKit.spec_for(_sim, BuildingRecord.new(3, &"iron_mine", 0, Vector2i(10, 10), 0), 2.0)
	assert_int(mine.roof).is_equal(BuildingKit.Roof.FLAT)
	var warehouse := BuildingKit.spec_for(_sim, BuildingRecord.new(4, &"warehouse", 0, Vector2i(10, 10), 0), 2.0)
	assert_int(warehouse.door).is_equal(BuildingKit.Door.ARCH)


func test_the_view_draws_the_model_and_keeps_boxes_for_fields() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var house := SimFixture.house(_sim, 2, 10, &"workers", 10.0)
	var field := SimFixture.place(_sim, &"field", Vector2i(30, 20), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	var models := view.find_children("Model", "MeshInstance3D", true, false)
	assert_int(models.size()).is_equal(1)
	var model := models[0] as MeshInstance3D
	assert_object(model.material_override).is_same(BuildingMaterials.kit())
	assert_float(model.get_instance_shader_parameter(&"layer")).is_equal(float(BuildingMaterials.Wall.BRICK))
	assert_float(model.get_instance_shader_parameter(&"roof_layer")).is_equal(float(BuildingMaterials.Roof.TILES))
	assert_int(view.building_count()).is_equal(2)
	assert_int(house).is_greater(0)
	assert_int(field).is_greater(0)
