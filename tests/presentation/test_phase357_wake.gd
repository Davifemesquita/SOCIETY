extends GdUnitTestSuite
## Esteira em V (Fase 357): a espuma do rastro sai da popa para trás e para os lados, no plano da água, vive mais e é mais numerosa.


func test_the_wake_opens_into_a_v() -> void:
	var view: ShipView = auto_free(ShipView.new())
	var wake := view._build_wake(20.0, 5.0)
	auto_free(wake)
	assert_float(wake.lifetime).is_greater_equal(9.0)
	var process := wake.process_material as ParticleProcessMaterial
	assert_bool(process.direction.is_equal_approx(Vector3(-1.0, 0.0, 0.0))).is_true()
	assert_float(process.spread).is_between(40.0, 80.0)
	assert_float(process.flatness).is_equal_approx(1.0, 0.001)
	assert_float(process.initial_velocity_max).is_greater(0.0)
	assert_int(ShipView.WAKE_PARTICLES).is_greater(40)
