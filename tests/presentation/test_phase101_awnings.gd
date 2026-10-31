extends GdUnitTestSuite
## Toldos listrados (Fase 101): as lojas e uma parte das casas dos artesãos e engenheiros têm toldo no térreo da frente,
## sobre a porta e as janelas; a lona alterna a cor e o creme; as células da paleta da lona não são usadas pelo kit.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _spec(id: StringName, tier: StringName = &"", building_id: int = 5) -> BuildingKit.Spec:
	var record := BuildingRecord.new(building_id, id, 0, Vector2i(10, 10), 0)
	if tier != &"":
		record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func _cell(uv: Vector2) -> Vector2i:
	return Vector2i(floori(uv.x * 8.0), floori(uv.y * 4.0))


func _count_uv(mesh: Mesh, uv: Vector2) -> int:
	var count := 0
	for surface: int in mesh.get_surface_count():
		var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
		for at: Vector2 in uvs:
			if _cell(at) == _cell(uv):
				count += 1
	return count


func test_the_shops_get_an_awning() -> void:
	for id: StringName in BuildingKit.AWNING_SHOPS:
		var spec := _spec(id)
		assert_int(spec.awning).override_failure_message(String(id)).is_greater(0)
		assert_int(BuildingKit.awning_cells(spec).size()).override_failure_message(String(id)).is_greater(0)
	for id: StringName in [&"church", &"weavery", &"warehouse", &"market"]:
		assert_int(_spec(id).awning).override_failure_message(String(id)).is_equal(0)


func test_some_artisan_and_engineer_houses_have_a_shop_downstairs() -> void:
	for tier: StringName in [&"artisans", &"engineers"]:
		var with_awning := 0
		for id: int in range(1, 100):
			if _spec(&"house", tier, id).awning > 0:
				with_awning += 1
		# uma em AWNING_HOUSE_SHARE, mais ou menos
		assert_int(with_awning).override_failure_message(String(tier)).is_between(15, 50)
	for tier: StringName in [&"peasants", &"workers", &"investors"]:
		for id: int in range(1, 60):
			assert_int(_spec(&"house", tier, id).awning).is_equal(0)


func test_the_awning_hangs_over_the_ground_floor_front() -> void:
	var spec := _spec(&"bakery")
	# (a placa da padaria, Fase 151, também usa a lona creme e as cores: aqui só o toldo)
	spec.shop_sign = 0
	var plain := spec._copy()
	plain.awning = 0
	var mesh := BuildingKit.mesh(spec)
	var color := BuildingKit.UV_AWNING_COLORS[spec.awning - 1]
	assert_int(_count_uv(mesh, color)).is_greater(0)
	assert_int(_count_uv(mesh, BuildingKit.UV_CANVAS)).is_greater(0)
	assert_int(_count_uv(BuildingKit.mesh(plain), BuildingKit.UV_CANVAS)).is_equal(0)
	# a lona fica no térreo, saindo da fachada da frente para a rua, abaixo do primeiro andar
	var front := -spec.size_m().y * 0.5
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i: int in vertices.size():
			if _cell(uvs[i]) in [_cell(color), _cell(BuildingKit.UV_CANVAS)]:
				assert_float(vertices[i].y).is_less(spec.floor_m())
				assert_float(vertices[i].y).is_greater(spec.floor_m() * 0.3)
				assert_float(vertices[i].z).is_less(front + 0.1)
				assert_float(vertices[i].z).is_greater(front - BuildingKit.AWNING_OUT_M - 0.1)


func test_the_kit_never_uses_the_canvas_cells() -> void:
	var cells: Array[Vector2i] = [_cell(BuildingKit.UV_CANVAS)]
	for color: Vector2 in BuildingKit.UV_AWNING_COLORS:
		cells.append(_cell(color))
	# todas as peças do kit na pasta dele
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
					assert_bool(_cell(uv) in cells).override_failure_message(piece).is_false()
