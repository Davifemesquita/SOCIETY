extends GdUnitTestSuite
## Postigos (Fase 177): as casas dos camponeses, operários e artesãos têm as duas folhas abertas em cada janela do corpo; as
## dos engenheiros e investidores não; as folhas cabem na célula ao lado do vão; nenhuma peça do kit cai na célula da tinta
## dos postigos.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(40, 40))


func _spec(tier: StringName, building_id := 7) -> BuildingKit.Spec:
	var record := BuildingRecord.new(building_id, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func _cell(uv: Vector2) -> Vector2i:
	return Vector2i(floori(uv.x * 8.0), floori(uv.y * 4.0))


## Janelas do corpo (as que a ala tira têm o slot &"none").
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


func test_only_the_plainer_houses_have_shutters() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans"]:
		assert_bool(_spec(tier).shutters).override_failure_message(String(tier)).is_true()
	for tier: StringName in [&"engineers", &"investors"]:
		assert_bool(_spec(tier).shutters).override_failure_message(String(tier)).is_false()


func test_two_leaves_on_every_window_of_the_body() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans"]:
		for building_id: int in [7, 8, 9, 10]:
			var spec := _spec(tier, building_id)
			var bare := _spec(tier, building_id)
			bare.shutters = false
			var windows := _window_slots(spec)
			assert_int(windows).is_greater(0)
			# cada folha é uma caixa de 12 triângulos
			var extra := BuildingKit.triangles(spec) - BuildingKit.triangles(bare)
			assert_int(extra).override_failure_message("%s %d" % [tier, building_id]).is_equal(windows * 2 * 12)


func test_the_leaves_fit_beside_the_opening_inside_the_cell() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans"]:
		var hall := _spec(tier).hall()
		for along: int in 2:
			var count := hall.cells.x if along == 0 else hall.cells.y
			var step := (hall.size_m().x if along == 0 else hall.size_m().y) / count
			var opening := step * BuildingKit.WINDOW_WIDTH
			# a borda de fora da folha antes da divisa da célula (a folha da janela vizinha não encosta)
			var reach := opening * 0.5 + BuildingKit.SHUTTER_GAP_M + opening * 0.5
			assert_float(reach).override_failure_message(String(tier)).is_less(step * 0.5 - 0.05)


func test_the_shutters_use_their_own_palette_cell() -> void:
	var spec := _spec(&"workers")
	var mesh := BuildingKit.mesh(spec)
	var painted := 0
	for surface: int in mesh.get_surface_count():
		var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
		for uv: Vector2 in uvs:
			if _cell(uv) == _cell(BuildingKit.UV_SHUTTER):
				painted += 1
	assert_int(painted).is_greater(0)
	# e a célula não é de nenhuma das cores já usadas pelas peças geradas
	for other: Vector2 in [BuildingKit.UV_GLASS, BuildingKit.UV_COPPER, BuildingKit.UV_CANVAS, BuildingKit.UV_BRICK]:
		assert_bool(_cell(other) == _cell(BuildingKit.UV_SHUTTER)).is_false()
	for other: Vector2 in BuildingKit.UV_AWNING_COLORS:
		assert_bool(_cell(other) == _cell(BuildingKit.UV_SHUTTER)).is_false()


func test_the_kit_never_uses_the_shutter_cell() -> void:
	var pieces: Array[String] = []
	for file: String in DirAccess.get_files_at(BuildingKit.DIR):
		if file.ends_with(".glb"):
			pieces.append(file.get_basename())
	assert_int(pieces.size()).is_greater(10)
	for piece: String in pieces:
		for part: Array in BuildingKit._parts_of(piece):
			var mesh: Mesh = part[0]
			for surface: int in mesh.get_surface_count():
				var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
				for uv: Vector2 in uvs:
					assert_bool(_cell(uv) == _cell(BuildingKit.UV_SHUTTER)).override_failure_message(piece).is_false()
