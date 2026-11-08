extends GdUnitTestSuite
## Fase 365: nas paredes do MegaKit, a viga de madeira entre os andares cobre a emenda (sem ela, uma fresta escura).

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()


func after_test() -> void:
	BuildingKit.reset_megakit()


func _spec(tier: StringName) -> BuildingKit.Spec:
	var record := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


## Vértices de madeira perto da altura y, a até "reach" fora do corpo: a escura da paleta (UV_TIMBER) ou, desde a Fase 376,
## a do pacote (UV2.x = 2).
func _timber_at(mesh: Mesh, y: float, half: Vector2, reach: float) -> int:
	var cell := Vector2i(floori(BuildingKit.UV_TIMBER.x * 8.0), floori(BuildingKit.UV_TIMBER.y * 4.0))
	var count := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var uv2 := PackedVector2Array()
		if arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			uv2 = arrays[Mesh.ARRAY_TEX_UV2]
		for i: int in vertices.size():
			var packed := not uv2.is_empty() and uv2[i].x > 0.5
			if packed and not is_equal_approx(uv2[i].x, 2.0):
				continue
			if not packed and Vector2i(floori(uvs[i].x * 8.0), floori(uvs[i].y * 4.0)) != cell:
				continue
			var point := vertices[i]
			if absf(point.y - y) < BuildingKit.FLOOR_BEAM_M and absf(point.x) <= half.x + reach and absf(point.z) <= half.y + reach:
				count += 1
	return count


func test_each_upper_floor_gets_a_beam_with_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	var spec := _spec(&"artisans")
	var hall := spec.hall()
	assert_int(hall.floors()).is_greater_equal(2)
	var mesh := BuildingKit.mesh(spec)
	var half := hall.size_m() * 0.5
	for level: int in range(1, hall.floors()):
		var y := spec.hall_offset().y + level * hall.floor_m()
		assert_int(_timber_at(mesh, y, half, BuildingKit.FLOOR_BEAM_OUT_M + 0.6)).override_failure_message(str(level)).is_greater(0)


func test_the_beam_stays_close_to_the_wall() -> void:
	BuildingKit.use_megakit(true)
	var spec := _spec(&"workers")
	var box := BuildingKit.mesh(spec).get_aabb()
	var size := spec.size_m()
	# a viga sai FLOOR_BEAM_OUT_M da parede: nada passa do lote mais do que já passava (o beiral, a sacada)
	assert_float(box.size.x).is_less(size.x + 2.0)
	assert_float(box.size.z).is_less(size.y + 2.0)


func test_the_kenney_walls_take_no_beam() -> void:
	BuildingKit.use_megakit(false)
	var spec := _spec(&"engineers")
	var with_beams := BuildingKit.triangles(spec)
	BuildingKit.use_megakit(true)
	# só confere que a troca refaz a malha (a viga é do MegaKit); o Kenney tem a faixa de pedra dele
	assert_int(BuildingKit.triangles(spec)).is_not_equal(with_beams)
