extends GdUnitTestSuite
## Botes no porto (Fase 142): o entreposto ganha uma roda de água funda do lado do mar; os botes andam nela, um em cada
## sentido, de proa para a frente; os remos varrem e a pá desce até a água; outros prédios não têm botes.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _loop() -> Array:
	var id := SimFixture.port(_sim)
	var record := _sim.world.building(id)
	return RowboatView.loop(_sim.world, record, _sim.def_of(record), _sim.config.cell_size_m)


func test_the_loop_floats_off_the_trading_post() -> void:
	var found := _loop()
	assert_int(found.size()).is_equal(2)
	var center: Vector3 = found[0]
	var radius: float = found[1]
	assert_bool(HarborView.afloat(_sim.world, center)).is_true()
	for n: int in 16:
		var angle := TAU * n / 16.0
		assert_bool(HarborView.afloat(_sim.world, center + Vector3(cos(angle), 0.0, sin(angle)) * radius)).is_true()


func test_the_boats_row_round_the_loop_bow_first() -> void:
	var found := _loop()
	var center: Vector3 = found[0]
	var radius: float = found[1]
	var turns: Array[float] = []
	for k: int in 2:
		var before := RowboatView.pose(center, radius, k, 0.0)
		var after := RowboatView.pose(center, radius, k, 3.0)
		for place: Transform3D in [before, after]:
			var flat := Vector2(place.origin.x - center.x, place.origin.z - center.z)
			assert_float(flat.length()).is_equal_approx(radius, 0.01)
			# a proa (−Z) aponta ao longo da roda, de través do raio
			var bow := -place.basis.z
			assert_float(absf(Vector2(bow.x, bow.z).normalized().dot(flat.normalized()))).is_less(0.15)
		var a := Vector2(before.origin.x - center.x, before.origin.z - center.z)
		var b := Vector2(after.origin.x - center.x, after.origin.z - center.z)
		turns.append(signf(a.cross(b)))
		# anda para onde a proa aponta
		var moved := after.origin - before.origin
		assert_float(Vector2(moved.x, moved.z).dot(Vector2(-before.basis.z.x, -before.basis.z.z))).is_greater(0.0)
	# um em cada sentido
	assert_float(turns[0]).is_equal(-turns[1])


func test_the_oars_sweep_and_dip_to_the_water() -> void:
	var tips: Array[Vector3] = []
	for step: int in 8:
		var time := RowboatView.STROKE_S * step / 8.0
		for side: float in [1.0, -1.0]:
			var oar := RowboatView.oar_pose(side, 0, time)
			var blade := oar * Vector3(RowboatView.OAR_LENGTH_M - 0.28, 0.0, 0.0)
			# para fora do bote, do lado dele, e abaixo do tolete
			assert_float(blade.x * side).is_greater(HarborView.BOAT_BEAM_M * 0.5)
			assert_float(blade.y).is_less(oar.origin.y)
			if side > 0.0:
				tips.append(blade)
	var span := 0.0
	for tip: Vector3 in tips:
		span = maxf(span, absf(tip.z - tips[0].z))
	assert_float(span).is_greater(0.5)


func test_only_trading_posts_have_rowboats() -> void:
	SimFixture.port(_sim)
	SimFixture.place(_sim, &"lumberjack", Vector2i(40, 10))
	var view: RowboatView = auto_free(RowboatView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.boat_count()).is_equal(RowboatView.BOATS_PER_POST)
