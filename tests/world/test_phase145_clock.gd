extends GdUnitTestSuite
## Relógio da igreja (Fase 145): a igreja tem dois mostradores na torre, para fora dela e acima do beiral; outros prédios
## não têm; os ponteiros marcam a hora.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_the_church_tower_has_two_dials_facing_out() -> void:
	for rotation: int in 4:
		var sim := SimFixture.simulation()
		sim.free_build = true
		var id := SimFixture.place(sim, &"church", Vector2i(20, 10), rotation)
		var record := sim.world.building(id)
		var def := sim.def_of(record)
		var found := ClockView.dials(sim, record)
		assert_int(found.size()).is_equal(2)
		var grid := sim.world.island(0)
		var area := Footprint.rect(record.origin, def.size, rotation)
		var center := grid.rect_world(area)
		var floor_y := BuildingKit.seat(grid, area).y
		var front := Footprint.front_direction(rotation)
		var outs: Array[Vector3] = []
		for dial: Transform3D in found:
			var out := dial.basis.z.normalized()
			outs.append(out)
			# para fora da igreja, na horizontal, acima do beiral
			assert_float(absf(out.y)).is_less(0.01)
			assert_float((dial.origin - center).dot(out)).is_greater(0.0)
			assert_float(dial.origin.y - floor_y).is_greater(def.height_m)
			# no mesmo lugar do modelo: um pouco à frente da face da torre
			var model := BuildingView.model_place(grid, record, area)
			var spec := BuildingKit.spec_for(sim, record, grid.cell_size)
			var local := model.affine_inverse() * dial.origin - BuildingKit.belfry_center(spec)
			assert_float(maxf(absf(local.x), absf(local.z))).is_equal_approx(BuildingKit.BELFRY_SIDE_M * 0.5 + ClockView.OUT_M, 0.001)
		# um para a frente (o lado da porta) e o outro de lado
		# (o modelo gira até meio grau pela variação)
		assert_float(outs[0].dot(Vector3(front.x, 0.0, front.y))).is_greater(0.999)
		assert_float(absf(outs[1].dot(outs[0]))).is_less(0.01)


func test_only_belfries_have_clocks() -> void:
	SimFixture.place(_sim, &"school", Vector2i(20, 10))
	SimFixture.place(_sim, &"house", Vector2i(40, 10))
	var view: ClockView = auto_free(ClockView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.dial_count()).is_equal(0)
	SimFixture.place(_sim, &"church", Vector2i(60, 10))
	view.rebuild()
	assert_int(view.dial_count()).is_equal(2)


func test_the_hands_tell_the_time() -> void:
	assert_vector(ClockView.hand_angles(12.0)).is_equal_approx(Vector2.ZERO, Vector2.ONE * 0.0001)
	assert_vector(ClockView.hand_angles(15.0)).is_equal_approx(Vector2(PI * 0.5, 0.0), Vector2.ONE * 0.0001)
	assert_vector(ClockView.hand_angles(6.5)).is_equal_approx(Vector2(PI * 13.0 / 12.0, PI), Vector2.ONE * 0.0001)
	assert_vector(ClockView.hand_angles(21.25)).is_equal_approx(Vector2(TAU * 9.25 / 12.0, PI * 0.5), Vector2.ONE * 0.0001)
