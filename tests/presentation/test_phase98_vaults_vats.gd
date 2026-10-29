extends GdUnitTestSuite
## Abóbadas e tonéis (Fase 98): o telhado de duas águas dos de VAULTED vira abóbada (arco liso, sem passar da altura do
## telhado de antes); cervejaria, destilarias e adega ganham os tonéis no pátio da frente, fora do caminho da porta; a
## chaminé das fábricas é redonda.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _spec(id: StringName, rotation: int = 0) -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, BuildingRecord.new(5, id, 0, Vector2i(10, 10), rotation), 2.0)


func test_the_vaulted_ones_get_the_vault() -> void:
	for id: StringName in BuildingKit.VAULTED:
		assert_bool(_spec(id).vault).override_failure_message(String(id)).is_true()
	for id: StringName in [&"church", &"theater", &"brewery", &"warehouse", &"furnace"]:
		assert_bool(_spec(id).vault).override_failure_message(String(id)).is_false()


func test_the_vault_is_a_smooth_arch_under_the_old_ridge() -> void:
	var spec := _spec(&"weavery")
	var size := spec.size_m()
	var hv := (size.y if spec.roof == BuildingKit.Roof.GABLE_X else size.x) * 0.5
	var width := hv + spec.overhang_m
	var crown: float = BuildingKit.vault_profile(spec, 0.0)[0]
	assert_float(crown).is_equal_approx(spec.height_m + spec.roof_m * BuildingKit.VAULT_RISE, 0.001)
	# desce sem degrau do alto ao beiral, simétrica, e a normal do alto aponta para cima
	var last := crown
	for step: int in range(1, 11):
		var v := width * step / 10.0
		var y: float = BuildingKit.vault_profile(spec, v)[0]
		assert_float(y).is_less(last)
		var mirror: float = BuildingKit.vault_profile(spec, -v)[0]
		assert_float(y).is_equal_approx(mirror, 0.0001)
		last = y
	var normal: Vector2 = BuildingKit.vault_profile(spec, 0.0)[1]
	assert_float(normal.y).is_equal_approx(1.0, 0.001)
	# nada passa do alto da abóbada (mais as quinas redondas do beiral)
	var top := -INF
	var mesh := BuildingKit.mesh(spec)
	for surface: int in mesh.get_surface_count():
		var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for point: Vector3 in vertices:
			top = maxf(top, point.y)
	assert_float(top).is_less(crown + 0.3)


func test_the_vats_stand_in_the_front_row_clear_of_the_door() -> void:
	for id: StringName in [&"brewery", &"distillery", &"rum_distillery", &"champagne_cellar"]:
		for rotation: int in 4:
			var spec := _spec(id, rotation)
			assert_int(spec.court_rows).is_equal(1)
			var vats := BuildingKit.vat_layout(spec)
			assert_int(vats.size()).override_failure_message(String(id)).is_greater_equal(2)
			var size := spec.size_m()
			var step := size.x / spec.cells.x
			var door_x := -size.x * 0.5 + step * (spec.door_index + 0.5)
			var front := -size.y * 0.5
			for vat: Array in vats:
				var base: Vector3 = vat[0]
				var radius: float = vat[1]
				# dentro do lote, na fileira da frente, e longe do caminho da porta
				assert_float(absf(base.x) + radius).is_less(size.x * 0.5)
				assert_float(base.z - radius).is_greater(front)
				assert_float(base.z + radius).is_less(front + spec.cell_m)
				assert_float(absf(base.x - door_x) - radius).is_greater(0.5)


func test_other_buildings_have_no_vats() -> void:
	for id: StringName in [&"weavery", &"bakery", &"tavern"]:
		assert_int(BuildingKit.vat_layout(_spec(id)).size()).is_equal(0)


func test_the_chimney_is_round() -> void:
	var mesh := SmokeView.stack_mesh()
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bottom := 0.0
	var smallest := INF
	var low := -(SmokeView.STACK_ABOVE_M + 1.0) * 0.5
	for point: Vector3 in vertices:
		var r := Vector2(point.x, point.z).length()
		if absf(point.y - low) < 0.01:
			bottom = maxf(bottom, r)
	# embaixo, todos os pontos à mesma distância do eixo (um círculo, não um quadrado)
	for point: Vector3 in vertices:
		if absf(point.y - low) < 0.01 and Vector2(point.x, point.z).length() > 0.01:
			smallest = minf(smallest, Vector2(point.x, point.z).length())
	assert_float(bottom).is_equal_approx(SmokeView.STACK_SIDE_M * 0.5, 0.01)
	assert_float(smallest).is_equal_approx(bottom, 0.01)
