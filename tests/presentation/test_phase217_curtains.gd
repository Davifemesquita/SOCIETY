extends GdUnitTestSuite
## Cortinas (Fase 217): todas as casas têm os dois panos e a sanefa em cada janela do corpo, e os outros prédios não; o pano fica
## entre o vidro e o caixilho; a casa dos investidores continua no teto de triângulos; nenhuma peça do kit nem outra peça gerada
## cai na célula da cortina.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(40, 40))


func _spec(tier: StringName, building_id := 7) -> BuildingKit.Spec:
	var record := BuildingRecord.new(building_id, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func _cell(uv: Vector2) -> Vector2i:
	return Vector2i(floori(uv.x * 8.0), floori(uv.y * 4.0))


func _window_slots(spec: BuildingKit.Spec) -> int:
	var hall := spec.hall()
	var count := 0
	for face: int in 4:
		var cells := hall.cells.x if face % 2 == 0 else hall.cells.y
		for level: int in hall.floors():
			for index: int in cells:
				if BuildingKit.slot(hall, face, index, level) == &"window":
					count += 1
	return count


func test_every_house_has_curtains_and_other_buildings_none() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		assert_bool(_spec(tier).curtains).override_failure_message(String(tier)).is_true()
	var bakery := BuildingRecord.new(3, &"bakery", 0, Vector2i(10, 10), 0)
	assert_bool(BuildingKit.spec_for(_sim, bakery, 2.0).curtains).is_false()


func test_two_panels_and_a_valance_on_every_window_of_the_body() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		for building_id: int in [7, 8, 9, 10]:
			var spec := _spec(tier, building_id)
			var bare := _spec(tier, building_id)
			bare.curtains = false
			var windows := _window_slots(spec)
			assert_int(windows).is_greater(0)
			# três quadriláteros (dois panos e a sanefa) por janela
			var extra := BuildingKit.triangles(spec) - BuildingKit.triangles(bare)
			assert_int(extra).override_failure_message("%s %d" % [tier, building_id]).is_equal(windows * 6)


func test_the_cloth_hangs_between_the_glass_and_the_mullions() -> void:
	assert_float(BuildingKit.CURTAIN_X).is_greater(BuildingKit.GLASS_X)
	assert_float(BuildingKit.CURTAIN_X).is_less(BuildingKit.MULLION_X)
	# os dois panos juntos nunca fecham a janela
	assert_float(BuildingKit.CURTAIN_MAX * 2.0).is_less(0.9)


func test_the_investors_stay_under_the_triangle_cap() -> void:
	# a mesma casa do teto do test_building_kit (cada id tem a sua variação de telhado e de ala)
	assert_int(BuildingKit.triangles(_spec(&"investors"))).is_less_equal(20000)


func test_the_curtain_cell_is_its_own() -> void:
	var mesh := BuildingKit.mesh(_spec(&"workers"))
	var painted := 0
	for surface: int in mesh.get_surface_count():
		var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
		for uv: Vector2 in uvs:
			if _cell(uv) == _cell(BuildingKit.UV_CURTAIN):
				painted += 1
	assert_int(painted).is_greater(0)
	for other: Vector2 in [BuildingKit.UV_GLASS, BuildingKit.UV_COPPER, BuildingKit.UV_CANVAS, BuildingKit.UV_BRICK,
			BuildingKit.UV_SHUTTER, BuildingKit.UV_IRON, BuildingKit.UV_BRONZE, BuildingKit.UV_FOLIAGE]:
		assert_bool(_cell(other) == _cell(BuildingKit.UV_CURTAIN)).is_false()
	var pieces: Array[String] = []
	for file: String in DirAccess.get_files_at(BuildingKit.DIR):
		if file.ends_with(".glb"):
			pieces.append(file.get_basename())
	assert_int(pieces.size()).is_greater(10)
	for piece: String in pieces:
		for part: Array in BuildingKit._parts_of(piece):
			var part_mesh: Mesh = part[0]
			for surface: int in part_mesh.get_surface_count():
				var uvs: PackedVector2Array = part_mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
				for uv: Vector2 in uvs:
					assert_bool(_cell(uv) == _cell(BuildingKit.UV_CURTAIN)).override_failure_message(piece).is_false()


func test_the_shader_paints_the_curtains() -> void:
	var code := (load("res://shaders/building_kit.gdshader") as Shader).code
	assert_str(code).contains("cell == ivec2(0, 0)")
	assert_str(code).contains("curtain_pick")
