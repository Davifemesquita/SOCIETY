extends GdUnitTestSuite
## Cunhais (Fase 160): as casas dos artesãos e engenheiros têm os cunhais de pedra nas quinas (a forma muda e soma
## triângulos na mesma casa); camponeses, operários e investidores (parede de pedra clara, no teto de triângulos) não; os
## blocos alternam o lado comprido, encostam na quina, saltam da parede e não passam da cornija; a quina do lado da ala para
## no alto dela.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _spec(tier: StringName) -> BuildingKit.Spec:
	var id := SimFixture.house(_sim, 20 + _sim.world.buildings.size() * 4, 12, tier, 5.0)
	return BuildingKit.spec_for(_sim, _sim.world.building(id), _sim.world.island(0).cell_size)


func _quoin_boxes(spec: BuildingKit.Spec) -> Array[AABB]:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	BuildingKit._quoins(tool, spec)
	var vertices: PackedVector3Array = tool.commit_to_arrays()[Mesh.ARRAY_VERTEX]
	# cada bloco é uma caixa de 36 vértices (seis faces de dois triângulos)
	var boxes: Array[AABB] = []
	for start: int in range(0, vertices.size(), 36):
		var box := AABB(vertices[start], Vector3.ZERO)
		for k: int in range(start, start + 36):
			box = box.expand(vertices[k])
		boxes.append(box)
	return boxes


func test_only_the_upper_tiers_get_quoins() -> void:
	for tier: StringName in [&"artisans", &"engineers"]:
		assert_bool(_spec(tier).quoins).is_true()
	for tier: StringName in [&"peasants", &"workers", &"investors"]:
		assert_bool(_spec(tier).quoins).is_false()


func test_the_quoins_change_the_shape_and_add_triangles() -> void:
	for tier: StringName in [&"artisans", &"engineers"]:
		# as duas formas da mesma casa (outra casa tem outra variação de telhado e ala)
		var id := SimFixture.house(_sim, 20 + _sim.world.buildings.size() * 4, 12, tier, 5.0)
		var record := _sim.world.building(id)
		var with_quoins := BuildingKit.spec_for(_sim, record, _sim.world.island(0).cell_size)
		var without := BuildingKit.spec_for(_sim, record, _sim.world.island(0).cell_size)
		without.quoins = false
		assert_str(with_quoins.key()).is_not_equal(without.key())
		assert_int(BuildingKit.triangles(with_quoins)).is_greater(BuildingKit.triangles(without))


func test_the_blocks_sit_on_the_corners_alternating_and_under_the_cornice() -> void:
	var spec := _spec(&"artisans")
	spec.wing = 0
	spec.jetty = false
	spec.turret = false
	var hall := spec.hall()
	var half := hall.size_m() * 0.5
	var boxes := _quoin_boxes(spec)
	var courses := floori((hall.height_m - BuildingKit.CORNICE_M + 0.001) / BuildingKit.QUOIN_COURSE_M)
	assert_int(boxes.size()).is_equal(courses * 4)
	var long_x := 0
	for box: AABB in boxes:
		var middle := box.get_center() - spec.hall_offset()
		# encosta na quina e salta da parede pelas duas faces
		assert_float(maxf(absf(box.position.x), absf(box.end.x))).is_equal_approx(half.x + BuildingKit.QUOIN_OUT_M, 0.01)
		assert_float(maxf(absf(box.position.z - spec.hall_offset().z), absf(box.end.z - spec.hall_offset().z))).is_equal_approx(
				half.y + BuildingKit.QUOIN_OUT_M, 0.01)
		assert_float(box.end.y).is_less_equal(hall.height_m - BuildingKit.CORNICE_M + 0.001)
		assert_float(box.position.y).is_greater_equal(-0.001)
		if box.size.x > box.size.z:
			long_x += 1
		assert_float(absf(middle.x)).is_less(half.x + BuildingKit.QUOIN_OUT_M)
	# metade das fiadas com o lado comprido em x, metade em z (alternando)
	assert_int(absi(long_x * 2 - boxes.size())).is_less_equal(4)


func test_the_wing_corners_stop_at_the_wing_top() -> void:
	var spec := _spec(&"engineers")
	spec.wing = 1
	spec.turret = false
	var hall := spec.hall()
	if hall.floors() < 2:
		return
	var wing_top := hall.height_m - hall.floor_m() - BuildingKit.CORNICE_M
	for box: AABB in _quoin_boxes(spec):
		if box.get_center().x > 0.0:
			assert_float(box.end.y).is_less_equal(wing_top + 0.001)
