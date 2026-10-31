extends GdUnitTestSuite
## Mansarda (Fase 124): as casas dos investidores de duas águas sem ala ganham a mansarda — a água de baixo íngreme até o
## rebordo, a de cima quase plana, lucarnas com vidro na frente e atrás — e a altura do telhado não muda; a casa com ala, a
## de telhado plano e as outras classes ficam como eram.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _spec(id: int, tier: StringName) -> BuildingKit.Spec:
	var record := BuildingRecord.new(id, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func _mansard_spec() -> BuildingKit.Spec:
	for id: int in range(1, 60):
		var spec := _spec(id, &"investors")
		if spec.mansard:
			return spec
	return null


func _vertices(mesh: Mesh) -> PackedVector3Array:
	var all := PackedVector3Array()
	for surface: int in mesh.get_surface_count():
		var points: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		all.append_array(points)
	return all


func _uv_count(mesh: Mesh, uv: Vector2) -> int:
	var count := 0
	for surface: int in mesh.get_surface_count():
		var uvs: PackedVector2Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
		for each: Vector2 in uvs:
			if each.distance_to(uv) < 0.01:
				count += 1
	return count


func test_only_investor_houses_without_wing_get_the_mansard() -> void:
	var found := false
	for id: int in range(1, 60):
		var spec := _spec(id, &"investors")
		assert_bool(spec.mansard).is_equal(spec.roof != BuildingKit.Roof.FLAT and spec.wing == 0)
		found = found or spec.mansard
		assert_bool(_spec(id, &"engineers").mansard).is_false()
		assert_bool(_spec(id, &"peasants").mansard).is_false()
	assert_bool(found).is_true()


func test_the_mansard_breaks_at_the_curb_and_keeps_the_height() -> void:
	var spec := _mansard_spec()
	assert_object(spec).is_not_null()
	var levels := BuildingKit.mansard_levels(spec)
	var eave: Vector2 = levels[0]
	var curb: Vector2 = levels[1]
	var low: float = levels[3]
	var mid: float = levels[4]
	var high: float = levels[5]
	# a água de baixo é íngreme (mais de 60°) e a de cima, mais deitada que ela
	var lower_angle := atan2(mid - low, eave.y - curb.y)
	assert_float(rad_to_deg(lower_angle)).is_greater(60.0)
	var upper_angle := atan2(high - mid, curb.y)
	assert_float(upper_angle).is_less(lower_angle)
	# o alto do telhado é o de antes
	assert_float(high).is_equal_approx(spec.height_m + spec.roof_m, 0.001)
	var mesh := BuildingKit.mesh(spec)
	var top := -INF
	for point: Vector3 in _vertices(mesh):
		top = maxf(top, point.y)
	assert_float(top).is_greater_equal(high - 0.01)


func test_the_mansard_has_glazed_dormers() -> void:
	var spec := _mansard_spec()
	var with_dormers := _uv_count(BuildingKit.mesh(spec), BuildingKit.UV_GLASS)
	var plain := spec._copy()
	plain.mansard = false
	plain.lucarnes = 0
	assert_bool(plain.key() != spec.key()).is_true()
	var without := _uv_count(BuildingKit.mesh(plain), BuildingKit.UV_GLASS)
	# a malha é indexada: conta os vértices do vidro, não os triângulos
	assert_int(with_dormers).is_greater(without)


func test_the_chimney_still_clears_the_roof() -> void:
	var spec := _mansard_spec()
	var top: Variant = BuildingKit.chimney_top(spec)
	if top == null:
		return
	var mouth: Vector3 = top
	assert_float(mouth.y).is_greater(spec.height_m + spec.roof_m)
