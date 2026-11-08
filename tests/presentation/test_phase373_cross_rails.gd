extends GdUnitTestSuite
## Fase 373: com o MegaKit, a sacada dos engenheiros leva o guarda-corpo de madeira em xis do pacote (a peça empacotada, um lanço
## por célula e as pontas); a dos investidores segue com a balaustrada de pedra, e sem o MegaKit a grade de ferro volta.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(40, 40))


func after_test() -> void:
	BuildingKit.reset_megakit()


func _spec(tier: StringName, building_id := 7) -> BuildingKit.Spec:
	var record := BuildingRecord.new(building_id, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


## Quantos vértices da madeira do pacote (UV2.x = 2) a malha tem.
func _wood(spec: BuildingKit.Spec) -> int:
	var mesh := BuildingKit.mesh(spec)
	var count := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		# a malha do Kenney não tem UV2
		if not arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			continue
		var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		for uv2: Vector2 in uv2s:
			if is_equal_approx(uv2.x, 2.0):
				count += 1
	return count


func test_the_piece_is_packed() -> void:
	var path := BuildingKit.MEGAKIT_DIR + BuildingKit.CROSS_RAIL + ".res"
	assert_bool(ResourceLoader.exists(path)).is_true()
	var mesh := load(path) as Mesh
	var box := mesh.get_aabb()
	# 2 m ao longo de x, fino em z e centrado nele, do piso para cima
	assert_float(box.size.x).is_equal_approx(BuildingKit.CROSS_RAIL_LENGTH_M, 0.05)
	assert_float(box.size.z).is_less(0.4)
	assert_float(box.get_center().z).is_equal_approx(0.0, 0.05)
	assert_float(box.end.y).is_between(0.9, 1.3)


func test_the_engineers_balcony_takes_the_wooden_rail() -> void:
	BuildingKit.use_megakit(true)
	var spec := _spec(&"engineers")
	assert_int(spec.trim).is_equal(TierDef.HouseTrim.BALCONIES)
	var plain := _spec(&"engineers")
	plain.trim = TierDef.HouseTrim.NONE
	assert_int(_wood(spec)).is_greater(_wood(plain))


func test_the_investors_and_the_kenney_keep_theirs() -> void:
	BuildingKit.use_megakit(true)
	var investors := _spec(&"investors")
	assert_int(investors.trim).is_equal(TierDef.HouseTrim.PORTICO)
	var bare := _spec(&"investors")
	bare.trim = TierDef.HouseTrim.NONE
	assert_int(_wood(investors)).is_equal(_wood(bare))
	BuildingKit.use_megakit(false)
	assert_int(_wood(_spec(&"engineers"))).is_equal(0)
