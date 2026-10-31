extends GdUnitTestSuite
## Gradil das casas ricas (Fase 114): na frente das casas dos engenheiros, um gradil de ferro na faixa entre a parede e a
## divisa do lote, com o vão da porta; as outras classes não têm.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _house(tier: StringName) -> BuildingKit.Spec:
	var record := BuildingRecord.new(5, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func _iron_in_front(spec: BuildingKit.Spec) -> PackedVector3Array:
	var found := PackedVector3Array()
	var iron := Vector2i(floori(BuildingKit.UV_IRON.x * 8.0), floori(BuildingKit.UV_IRON.y * 4.0))
	var wall := -spec.size_m().y * 0.5
	var mesh := BuildingKit.mesh(spec)
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i: int in vertices.size():
			var point := vertices[i]
			if Vector2i(floori(uvs[i].x * 8.0), floori(uvs[i].y * 4.0)) == iron and point.z < wall \
					and point.y < BuildingKit.FRONT_RAIL_M + 0.2:
				found.append(point)
	return found


func test_engineer_houses_have_the_railing_between_wall_and_lot_edge() -> void:
	var spec := _house(&"engineers")
	spec.lantern = false
	var iron := _iron_in_front(spec)
	assert_int(iron.size()).is_greater(0)
	var lot_edge := -(spec.cells.y * spec.cell_m) * 0.5
	var size := spec.size_m()
	var step := size.x / spec.cells.x
	var door_x := -size.x * 0.5 + step * (spec.door_index + 0.5)
	for point: Vector3 in iron:
		# dentro do lote, sem passar para a rua, e fora do vão da porta
		assert_float(point.z).is_greater_equal(lot_edge - 0.05)
		assert_float(absf(point.x - door_x)).is_greater(step * 0.3)


func test_other_classes_have_no_front_railing() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans"]:
		var spec := _house(tier)
		spec.lantern = false
		assert_int(_iron_in_front(spec).size()).override_failure_message(String(tier)).is_equal(0)


func test_the_spans_leave_the_door_open() -> void:
	var spec := _house(&"engineers")
	var spans := BuildingKit.front_railing_spans(spec)
	assert_int(spans.size()).is_between(1, 2)
	var size := spec.size_m()
	var step := size.x / spec.cells.x
	var door_x := -size.x * 0.5 + step * (spec.door_index + 0.5)
	for span: Vector2 in spans:
		assert_bool(door_x > span.x and door_x < span.y).is_false()
