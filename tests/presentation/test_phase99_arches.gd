extends GdUnitTestSuite
## Arcos (Fase 99): as janelas dos serviços de pedra e das casas dos investidores ganham a cabeça em arco (tímpano de vidro
## e arquivolta), cabendo no andar; o mercado ganha a arcada na fileira do pátio junto do corpo, com as bancas na da rua.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _spec(id: StringName, tier: StringName = &"") -> BuildingKit.Spec:
	var record := BuildingRecord.new(5, id, 0, Vector2i(10, 10), 0)
	if tier != &"":
		record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func _glass_triangles(mesh: ArrayMesh) -> int:
	var cell := Vector2i(floori(BuildingKit.UV_GLASS.x * 8.0), floori(BuildingKit.UV_GLASS.y * 4.0))
	var count := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i: int in range(0, uvs.size(), 3):
				if Vector2i(floori(uvs[i].x * 8.0), floori(uvs[i].y * 4.0)) == cell:
					count += 1
		else:
			for i: int in range(0, indices.size(), 3):
				var at := uvs[indices[i]]
				if Vector2i(floori(at.x * 8.0), floori(at.y * 4.0)) == cell:
					count += 1
	return count


func test_who_gets_arched_windows() -> void:
	for id: StringName in [&"church", &"theater", &"university", &"town_hall", &"museum"]:
		assert_bool(_spec(id).arched).override_failure_message(String(id)).is_true()
	assert_bool(_spec(&"house", &"investors").arched).is_true()
	for id: StringName in [&"bakery", &"market", &"tavern", &"warehouse", &"weavery"]:
		assert_bool(_spec(id).arched).override_failure_message(String(id)).is_false()
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers"]:
		assert_bool(_spec(&"house", tier).arched).override_failure_message(String(tier)).is_false()


func test_each_window_gets_its_glass_fan() -> void:
	for spec: BuildingKit.Spec in [_spec(&"theater"), _spec(&"house", &"investors")]:
		var flat := spec._copy()
		flat.arched = false
		var added := _glass_triangles(BuildingKit.mesh(spec)) - _glass_triangles(BuildingKit.mesh(flat))
		assert_int(added).is_equal(BuildingKit.windows(spec).size() * BuildingKit.ARCH_SEGMENTS)


func test_the_arch_fits_inside_the_floor() -> void:
	for spec: BuildingKit.Spec in [_spec(&"theater"), _spec(&"university"), _spec(&"house", &"investors")]:
		var hall := spec.hall()
		var step := hall.size_m().x / hall.cells.x
		var crown := BuildingKit.arch_spring(hall.floor_m()) + BuildingKit.arch_radius(step) + BuildingKit.ARCH_BAND_M * 1.4
		# o alto da arquivolta (com a pedra de fecho) fica abaixo do chão do andar de cima
		assert_float(crown).is_less(hall.floor_m())


func test_the_market_gets_the_arcade_with_stalls_in_front() -> void:
	var market := _spec(&"market")
	assert_int(market.court_rows).is_greater_equal(2)
	assert_int(BuildingKit.arcade_bays(market)).is_equal(market.cells.x)
	assert_int(BuildingKit.arcade_bays(_spec(&"bakery"))).is_equal(0)
	# a arcada põe pedra clara na frente do corpo, do chão até perto do beiral, sem passar do lote
	var mesh := BuildingKit.mesh(market)
	var size := market.size_m()
	var wall_z := market.hall_offset().z - market.hall().size_m().y * 0.5
	var stone := Vector2i(floori(BuildingKit.UV_LIGHT_STONE.x * 8.0), floori(BuildingKit.UV_LIGHT_STONE.y * 4.0))
	var in_front := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i: int in vertices.size():
			var point := vertices[i]
			if Vector2i(floori(uvs[i].x * 8.0), floori(uvs[i].y * 4.0)) == stone and point.z < wall_z - 0.5:
				in_front += 1
				assert_float(absf(point.x)).is_less(size.x * 0.5 + 0.2)
				assert_float(point.z).is_greater(-size.y * 0.5)
				assert_float(point.y).is_less(market.hall().height_m)
	assert_int(in_front).is_greater(0)
