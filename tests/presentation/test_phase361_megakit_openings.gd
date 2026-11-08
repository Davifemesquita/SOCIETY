extends GdUnitTestSuite
## Fase 361: com as paredes do MegaKit, os enfeites e as janelas acesas seguem o vão da peça dele.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()


func after_test() -> void:
	BuildingKit.use_megakit(false)


func _spec(tier: StringName) -> BuildingKit.Spec:
	var record := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func test_the_opening_is_the_kenney_one_when_off_and_the_piece_one_when_on() -> void:
	var spec := _spec(&"workers")
	var kenney := BuildingKit.opening(spec)
	assert_float(kenney.x).is_equal_approx(BuildingKit.WINDOW_WIDTH, 0.0001)
	assert_float(kenney.y).is_equal_approx(BuildingKit.WINDOW_CENTER, 0.0001)
	BuildingKit.use_megakit(true)
	var megakit := BuildingKit.opening(spec)
	assert_bool(megakit in BuildingKit.MEGAKIT_OPENINGS).is_true()
	# o vidro do pacote fica no fundo da parede grossa, atrás do da peça do Kenney
	assert_float(megakit.w).is_less(BuildingKit.GLASS_X)


func test_arched_houses_take_the_round_window() -> void:
	BuildingKit.use_megakit(true)
	var spec := _spec(&"investors")
	assert_bool(spec.arched).is_true()
	assert_int(BuildingKit.window_index(spec)).is_equal(0)


func test_the_lit_windows_take_the_size_and_depth_of_the_opening() -> void:
	var spec := _spec(&"workers")
	var kenney := BuildingKit.windows(spec)
	BuildingKit.use_megakit(true)
	var gap := BuildingKit.opening(spec)
	var megakit := BuildingKit.windows(spec)
	assert_int(megakit.size()).is_equal(kenney.size())
	assert_int(megakit.size()).is_greater(0)
	var size := spec.size_m()
	var step := size.x / spec.cells.x
	var floor_m := spec.floor_m()
	for window: Transform3D in megakit:
		# a largura e a altura do vão da peça; o meio na altura dele dentro do andar
		var width := window.basis.x.length()
		var side_step := size.y / spec.cells.y
		assert_bool(absf(width - step * gap.x) < 0.01 or absf(width - side_step * gap.x) < 0.01).is_true()
		assert_float(window.basis.y.length()).is_equal_approx(floor_m * gap.z, 0.01)
		assert_float(fposmod(window.origin.y, floor_m)).is_equal_approx(floor_m * gap.y, 0.02)
	# o vidro aceso fica mais para dentro que o do Kenney (atrás da moldura do pacote)
	var inside := 0
	for i: int in megakit.size():
		var center := Vector3(0.0, megakit[i].origin.y, 0.0)
		if (megakit[i].origin - center).length() < (kenney[i].origin - Vector3(0.0, kenney[i].origin.y, 0.0)).length():
			inside += 1
	assert_int(inside).is_equal(megakit.size())


func test_no_stone_lintel_goes_on_the_megakit_window() -> void:
	var spec := _spec(&"artisans")
	var kenney_stone := _light_stone(BuildingKit.mesh(spec))
	BuildingKit.use_megakit(true)
	var megakit_stone := _light_stone(BuildingKit.mesh(spec))
	# a verga, o peitoril e a guarnição saem; a cornija e as faixas ficam
	assert_int(megakit_stone).is_greater(0)
	assert_int(megakit_stone).is_less(kenney_stone)


func _light_stone(mesh: Mesh) -> int:
	var cell := Vector2i(floori(BuildingKit.UV_LIGHT_STONE.x * 8.0), floori(BuildingKit.UV_LIGHT_STONE.y * 4.0))
	var count := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var uv2 := PackedVector2Array()
		if arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			uv2 = arrays[Mesh.ARRAY_TEX_UV2]
		for i: int in uvs.size():
			if not uv2.is_empty() and uv2[i].x > 0.5:
				continue
			if Vector2i(floori(uvs[i].x * 8.0), floori(uvs[i].y * 4.0)) == cell:
				count += 1
	return count
