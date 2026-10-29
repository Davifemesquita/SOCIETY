extends GdUnitTestSuite
## Cúpulas e torreões (Fase 97): a cúpula de cobre sobre o telhado de quatro águas dos serviços de DOMED e o torreão
## redondo no canto da frente das casas de pórtico com três andares ou mais; as outras formas ficam sem.

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


func _highest(mesh: Mesh) -> float:
	var top := -INF
	for surface: int in mesh.get_surface_count():
		var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for point: Vector3 in vertices:
			top = maxf(top, point.y)
	return top


func _copper_vertices(mesh: Mesh) -> int:
	var count := 0
	for surface: int in mesh.get_surface_count():
		var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
		for uv: Vector2 in uvs:
			if uv.distance_to(BuildingKit.UV_COPPER) < 0.01:
				count += 1
	return count


func test_the_theater_gets_a_copper_dome_above_the_ridge() -> void:
	var spec := _spec(&"theater")
	assert_bool(spec.dome).is_true()
	var mesh := BuildingKit.mesh(spec)
	assert_int(_copper_vertices(mesh)).is_greater(0)
	# o tambor sai acima da cumeeira e a cúpula sobe por cima dele
	assert_float(_highest(mesh)).is_greater(spec.height_m + spec.roof_m + BuildingKit.DRUM_M)


func test_the_dome_fits_inside_the_roof() -> void:
	for id: StringName in BuildingKit.DOMED:
		var spec := _spec(id)
		if not spec.dome:
			continue
		var size := spec.size_m()
		var radius := minf(minf(size.x, size.y) * BuildingKit.DOME_SHARE, BuildingKit.DOME_MAX_M)
		# o tambor nasce dentro das águas: longe das bordas do telhado
		assert_float(radius).is_less(minf(size.x, size.y) * 0.5 - 0.5)


func test_only_the_domed_services_get_the_dome() -> void:
	for id: StringName in [&"church", &"market", &"brewery", &"warehouse"]:
		var spec := _spec(id)
		assert_bool(spec.dome).is_false()
		assert_int(_copper_vertices(BuildingKit.mesh(spec))).is_equal(0)


func test_tall_portico_houses_get_a_turret_at_the_front_corner() -> void:
	var spec := _spec(&"house", &"investors")
	assert_bool(spec.trim == TierDef.HouseTrim.PORTICO and spec.floors() >= 3).is_true()
	assert_bool(spec.turret).is_true()
	var plain := spec._copy()
	plain.turret = false
	var with_turret := BuildingKit.mesh(spec)
	var without := BuildingKit.mesh(plain)
	# o torreão passa do beiral e o meio dele fica na linha da fachada da frente, no canto de +X
	var center := BuildingKit.turret_center(spec)
	assert_float(center.z).is_equal_approx(-spec.size_m().y * 0.5, 0.001)
	assert_float(center.x).is_greater(0.0)
	var reach := -INF
	for surface: int in with_turret.get_surface_count():
		var vertices: PackedVector3Array = with_turret.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for point: Vector3 in vertices:
			if Vector2(point.x - center.x, point.z - center.z).length() < BuildingKit.TURRET_R + 0.4:
				reach = maxf(reach, point.y)
	assert_float(reach).is_greater(spec.height_m + spec.floor_m() * BuildingKit.TURRET_ABOVE)
	assert_float(_highest(with_turret)).is_greater_equal(_highest(without))


func test_lower_houses_have_no_turret() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers"]:
		assert_bool(_spec(&"house", tier).turret).is_false()
