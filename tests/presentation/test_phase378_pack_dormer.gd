extends GdUnitTestSuite
## Fase 378: com o MegaKit, a lucarna das casas dos engenheiros e dos investidores é a de telhas redondas do pacote (UV2.x = 8
## nas telhas), com o fundo dentro da água do telhado; as outras classes e o Kenney seguem com a gerada.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(40, 40))


func after_test() -> void:
	BuildingKit.reset_megakit()


## A primeira casa da classe com lucarnas (no telhado de duas águas, sem mansarda).
func _with_lucarnes(tier: StringName) -> BuildingKit.Spec:
	for id: int in range(1, 200):
		var record := BuildingRecord.new(id, &"house", 0, Vector2i(10, 10), 0)
		record.tier = tier
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		if spec.lucarnes > 0 and not spec.mansard:
			return spec
	return null


## Os vértices das telhas redondas do pacote.
func _tiles(spec: BuildingKit.Spec) -> PackedVector3Array:
	var found := PackedVector3Array()
	var mesh := BuildingKit.mesh(spec)
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		if not arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			continue
		var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i: int in uv2s.size():
			if is_equal_approx(uv2s[i].x, 8.0):
				found.append(vertices[i])
	return found


func test_the_piece_is_packed() -> void:
	var path := BuildingKit.MEGAKIT_DIR + BuildingKit.MEGAKIT_DORMER + ".res"
	assert_bool(ResourceLoader.exists(path)).is_true()
	var box := (load(path) as Mesh).get_aabb()
	assert_float(box.end.y).is_equal_approx(BuildingKit.MEGAKIT_DORMER_TOP_M, 0.05)
	assert_float(box.end.x).is_greater(BuildingKit.MEGAKIT_DORMER_DEPTH_M)


func test_the_rich_houses_take_the_pack_dormer() -> void:
	BuildingKit.use_megakit(true)
	for tier: StringName in [&"engineers", &"investors"]:
		var spec := _with_lucarnes(tier)
		if spec == null:
			continue
		var tiles := _tiles(spec)
		assert_int(tiles.size()).override_failure_message(String(tier)).is_greater(0)
		# nada da lucarna passa da cumeeira, e a casa fica no teto de triângulos
		var ridge := spec.height_m + spec.roof_m
		for point: Vector3 in tiles:
			assert_float(point.y).override_failure_message(String(tier)).is_less(ridge + 0.05)
		assert_int(BuildingKit.triangles(spec)).is_less(40000)


func test_the_back_stays_under_the_roof() -> void:
	for slope: float in [0.5, 0.8, 1.2]:
		var depth := BuildingKit.mega_dormer_depth(slope)
		assert_float(depth * slope).is_greater(BuildingKit.MEGAKIT_DORMER_TOP_M * BuildingKit.MEGAKIT_DORMER_SCALE)


func test_the_others_keep_the_generated_one() -> void:
	BuildingKit.use_megakit(true)
	var workers := _with_lucarnes(&"workers")
	assert_object(workers).is_not_null()
	assert_int(_tiles(workers).size()).is_equal(0)
	BuildingKit.use_megakit(false)
	var engineers := _with_lucarnes(&"engineers")
	assert_int(_tiles(engineers).size()).is_equal(0)
