extends GdUnitTestSuite
## Lampião, grade e chaminé (Fase 104): a chaminé das casas é de tijolo (a célula do tijolo, que o kit não usa) e a boca
## dela fica no alto dos potes; os serviços e as casas dos artesãos para cima sem toldo têm o lampião ao lado da porta, que
## entra na lista das janelas que acendem; o pátio do museu tem a grade de ferro com o portão diante da porta.

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


func _vertices_in(mesh: Mesh, uv: Vector2) -> PackedVector3Array:
	var found := PackedVector3Array()
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i: int in vertices.size():
			if _cell(uvs[i]) == _cell(uv):
				found.append(vertices[i])
	return found


func test_the_chimney_is_brick_and_the_smoke_leaves_from_the_pots() -> void:
	var spec := _spec(&"house", &"workers")
	spec.chimney = true
	var bricks := _vertices_in(BuildingKit.mesh(spec), BuildingKit.UV_BRICK)
	assert_int(bricks.size()).is_greater(0)
	var top_brick := -INF
	for point: Vector3 in bricks:
		top_brick = maxf(top_brick, point.y)
	# o fuste passa da cumeeira, e a boca fica acima dele (o alto dos potes)
	assert_float(top_brick).is_greater(spec.height_m + spec.roof_m)
	var mouth: Vector3 = BuildingKit.chimney_top(spec)
	assert_float(mouth.y).is_greater(top_brick)
	assert_float(mouth.y - top_brick).is_less(BuildingKit.CHIMNEY_POT_M + 0.1)
	spec.chimney = false
	assert_int(_vertices_in(BuildingKit.mesh(spec), BuildingKit.UV_BRICK).size()).is_equal(0)


func test_the_kit_never_uses_the_brick_cell() -> void:
	for file: String in DirAccess.get_files_at(BuildingKit.DIR):
		if not file.ends_with(".glb"):
			continue
		for part: Array in BuildingKit._parts_of(file.get_basename()):
			var mesh: Mesh = part[0]
			for surface: int in mesh.get_surface_count():
				var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
				for uv: Vector2 in uvs:
					assert_bool(_cell(uv) == _cell(BuildingKit.UV_BRICK)).override_failure_message(file).is_false()


func test_who_gets_a_wall_lantern() -> void:
	for id: StringName in [&"church", &"school", &"hospital", &"museum"]:
		assert_bool(_spec(id).lantern).override_failure_message(String(id)).is_true()
	for id: StringName in [&"market", &"tavern", &"bakery", &"warehouse"]:
		assert_bool(_spec(id).lantern).override_failure_message(String(id)).is_false()
	for id: int in range(1, 60):
		for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
			var spec := _spec(&"house", tier, id)
			var expected := tier in [&"artisans", &"engineers", &"investors"] and spec.awning == 0
			assert_bool(spec.lantern).override_failure_message("%s %d" % [tier, id]).is_equal(expected)


func test_the_lantern_hangs_beside_the_door_and_lights_up() -> void:
	for spec: BuildingKit.Spec in [_spec(&"church"), _spec(&"house", &"investors")]:
		var pane: Transform3D = BuildingKit.lantern_pane(spec)
		var door := BuildingKit.door_position(spec)
		# na frente, fora da parede, ao lado da porta e acima dela
		assert_float(pane.origin.z).is_less(door.z)
		assert_float(absf(pane.origin.x - door.x)).is_between(0.4, 2.0)
		assert_float(pane.origin.y).is_between(1.0, spec.hall().floor_m())
		assert_bool(BuildingKit.windows(spec).has(pane)).is_true()
	assert_object(BuildingKit.lantern_pane(_spec(&"market"))).is_null()


func test_the_museum_court_has_the_iron_fence_with_a_gate() -> void:
	var spec := _spec(&"museum")
	assert_int(spec.court_rows).is_greater(0)
	var iron := _vertices_in(BuildingKit.mesh(spec), BuildingKit.UV_IRON)
	var front := -spec.size_m().y * 0.5
	var step := spec.size_m().x / spec.cells.x
	var door_x := -spec.size_m().x * 0.5 + step * (spec.door_index + 0.5)
	var on_front := 0
	for point: Vector3 in iron:
		if point.z < front + 0.3 and point.y < BuildingKit.GALLERY_FENCE_M + 0.1:
			on_front += 1
			# o portão: nada de grade no caminho da porta
			assert_float(absf(point.x - door_x)).is_greater(0.5)
	assert_int(on_front).is_greater(0)
