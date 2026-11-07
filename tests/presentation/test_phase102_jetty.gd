extends GdUnitTestSuite
## Enxaimel saliente (Fase 102): nas casas dos operários e artesãos com a cumeeira ao longo da frente, os andares de cima
## da frente avançam JETTY_M (e tudo o que se põe pela célula acompanha: paredes, janelas acesas); o térreo e os outros
## lados não mudam; o andar saliente fica debaixo do beiral; as outras classes não têm.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _house(tier: StringName, jetty: bool) -> BuildingKit.Spec:
	var record := BuildingRecord.new(5, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	var spec := BuildingKit.spec_for(_sim, record, 2.0)
	spec.roof = BuildingKit.Roof.GABLE_X
	spec.wing = 0
	spec.awning = 0
	spec.jetty = jetty
	return spec


func test_who_gets_the_jetty() -> void:
	var seen := 0
	for id: int in range(1, 60):
		for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
			var record := BuildingRecord.new(id, &"house", 0, Vector2i(10, 10), 0)
			record.tier = tier
			var spec := BuildingKit.spec_for(_sim, record, 2.0)
			var expected := tier in [&"workers", &"artisans"] and spec.roof == BuildingKit.Roof.GABLE_X and spec.floors() >= 2
			assert_bool(spec.jetty).override_failure_message("%s %d" % [tier, id]).is_equal(expected)
			seen += int(spec.jetty)
	assert_int(seen).is_greater(0)


func test_only_the_upper_front_moves_out() -> void:
	var plain := _house(&"workers", false)
	var jettied := _house(&"workers", true)
	var plain_windows := BuildingKit.windows(plain)
	var moved_windows := BuildingKit.windows(jettied)
	assert_int(moved_windows.size()).is_equal(plain_windows.size())
	var moved := 0
	for i: int in plain_windows.size():
		var shift := moved_windows[i].origin - plain_windows[i].origin
		var upper_front := plain_windows[i].origin.y > plain.floor_m() \
				and plain_windows[i].origin.z < -plain.size_m().y * 0.5 + 0.3
		if upper_front:
			# para a rua (−Z), JETTY_M
			assert_float(shift.z).is_equal_approx(-BuildingKit.JETTY_M, 0.001)
			moved += 1
		else:
			assert_float(shift.length()).is_equal_approx(0.0, 0.001)
	assert_int(moved).is_greater(0)


func test_the_jetty_stays_under_the_eave() -> void:
	for tier: StringName in [&"workers", &"artisans"]:
		var spec := _house(tier, true)
		var mesh := BuildingKit.mesh(spec)
		var front := -spec.size_m().y * 0.5
		var deepest := INF
		for surface: int in mesh.get_surface_count():
			var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for point: Vector3 in vertices:
				# o corpo dos andares de cima, abaixo do beiral (o telhado e a cornija passam mais; o peitoril sai 0,15 m)
				if point.y < spec.height_m - 1.0 and point.y > spec.floor_m() + 0.2:
					deepest = minf(deepest, point.z)
		assert_float(deepest).override_failure_message("%s %.3f front %.3f" % [tier, deepest, front]).is_greater_equal(front - BuildingKit.JETTY_M - 0.2)
		assert_float(deepest).override_failure_message(String(tier)).is_less(front - BuildingKit.JETTY_M + 0.05)
		# o beiral passa da frente que avançou
		assert_float(spec.overhang_m).is_greater(BuildingKit.JETTY_M)


func test_the_timber_frame_shows_on_the_upper_front() -> void:
	var plain := _house(&"workers", false)
	var jettied := _house(&"workers", true)
	var timber := Vector2i(floori(BuildingKit.UV_TIMBER.x * 8.0), floori(BuildingKit.UV_TIMBER.y * 4.0))
	var counts: Array[int] = []
	for spec: BuildingKit.Spec in [plain, jettied]:
		var count := 0
		var mesh := BuildingKit.mesh(spec)
		for surface: int in mesh.get_surface_count():
			var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
			for uv: Vector2 in uvs:
				if Vector2i(floori(uv.x * 8.0), floori(uv.y * 4.0)) == timber:
					count += 1
		counts.append(count)
	assert_int(counts[1]).is_greater(counts[0])
