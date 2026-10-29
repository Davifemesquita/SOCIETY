extends GdUnitTestSuite
## Casa em mais de um volume (Fase 96): a ala tira o último andar da coluna da ponta, ganha telhado próprio mais baixo e
## cruzado com o do corpo; as janelas acesas seguem as paredes; camponeses e telhado plano não têm ala.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _house(tier: StringName, wing: int) -> BuildingKit.Spec:
	var record := BuildingRecord.new(5, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	var spec := BuildingKit.spec_for(_sim, record, 2.0)
	spec.roof = BuildingKit.Roof.GABLE_X
	spec.lucarnes = 0
	spec.wing = wing
	return spec


func test_the_wing_takes_the_top_floor_of_the_end_column() -> void:
	var spec := _house(&"engineers", -1)
	var top := spec.floors() - 1
	assert_int(spec.floors()).is_greater_equal(2)
	# o último andar da coluna de −X (frente e fundo, índice 0) e o lado −X inteiro nesse andar
	assert_str(String(BuildingKit.slot(spec, 0, 0, top))).is_equal("none")
	assert_str(String(BuildingKit.slot(spec, 2, 0, top))).is_equal("none")
	for index: int in spec.cells.y:
		assert_str(String(BuildingKit.slot(spec, 3, index, top))).is_equal("none")
	# o resto fica: a coluna do outro lado, os andares de baixo e o lado +X
	assert_str(String(BuildingKit.slot(spec, 0, spec.cells.x - 1, top))).is_not_equal("none")
	assert_str(String(BuildingKit.slot(spec, 0, 0, top - 1))).is_not_equal("none")
	assert_str(String(BuildingKit.slot(spec, 1, 0, top))).is_not_equal("none")


func test_the_lit_windows_follow_the_walls() -> void:
	var plain := _house(&"engineers", 0)
	var winged := _house(&"engineers", -1)
	var top := winged.floors() - 1
	var removed := 0
	for face: int in 4:
		var count := winged.cells.x if face % 2 == 0 else winged.cells.y
		for index: int in count:
			if BuildingKit.slot(plain, face, index, top) == &"window" and BuildingKit.in_wing(winged, face, index, top):
				removed += 1
	assert_int(removed).is_greater(0)
	assert_int(BuildingKit.windows(winged).size()).is_equal(BuildingKit.windows(plain).size() - removed)
	# nenhuma janela acesa no ar, acima da ala
	var wing_top := winged.height_m - winged.floor_m()
	var edge := -winged.size_m().x * 0.5 + winged.column_m()
	for window: Transform3D in BuildingKit.windows(winged):
		if window.origin.x < edge - 0.05:
			assert_float(window.origin.y).is_less(wing_top)


func test_the_wing_is_lower_than_the_body() -> void:
	var winged := _house(&"engineers", -1)
	var mesh := BuildingKit.mesh(winged)
	var edge := -winged.size_m().x * 0.5 + winged.column_m() - 0.6
	var wing_peak := winged.height_m - winged.floor_m() + winged.wing_part().roof_m
	var highest_over_wing := -INF
	for surface: int in mesh.get_surface_count():
		var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for point: Vector3 in vertices:
			if point.x < edge:
				highest_over_wing = maxf(highest_over_wing, point.y)
	# por cima da ala só o telhado dela (com a capa redonda da cumeeira), bem abaixo do alto do corpo
	assert_float(highest_over_wing).is_less(wing_peak + BuildingKit.RIDGE_CAP_M * 2.0)
	assert_float(highest_over_wing).is_less(winged.height_m)


func test_who_gets_a_wing() -> void:
	var seen_wing := false
	var seen_plain := false
	for id: int in range(1, 60):
		for tier: StringName in [&"peasants", &"workers", &"engineers"]:
			var record := BuildingRecord.new(id, &"house", 0, Vector2i(10, 10), 0)
			record.tier = tier
			var spec := BuildingKit.spec_for(_sim, record, 2.0)
			if tier == &"peasants" or spec.roof == BuildingKit.Roof.FLAT:
				assert_int(spec.wing).is_equal(0)
			elif spec.wing != 0:
				seen_wing = true
			else:
				seen_plain = true
	# metade, mais ou menos: as duas coisas aparecem
	assert_bool(seen_wing).is_true()
	assert_bool(seen_plain).is_true()
