extends GdUnitTestSuite
## Arco-íris (Fase 188): só no dia de chuva, quando ela passa, e some uma hora e pouco depois; nunca no dia limpo; o anel fica em
## volta do ponto oposto ao sol, do tamanho de 42 graus, e não aparece com o sol abaixo do horizonte nem alto demais.

const SEED := 1840

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()


## O primeiro dia de chuva e o primeiro sem chuva da semente.
func _days() -> Array[int]:
	var rainy := -1
	var dry := -1
	for index: int in 60:
		var kind := WeatherCycle.day(SEED, index, _config).kind
		if kind == WeatherCycle.Kind.RAIN and rainy < 0:
			rainy = index
		elif kind != WeatherCycle.Kind.RAIN and dry < 0:
			dry = index
	return [rainy, dry]


func test_it_shows_when_the_rain_passes_and_fades_after() -> void:
	var days := _days()
	assert_int(days[0]).is_greater_equal(0)
	var today := WeatherCycle.day(SEED, days[0], _config)
	var end := days[0] * 24.0 + today.rain_end
	# no meio da chuva, nada; logo depois dela, cheio; passado o tempo, some
	assert_float(RainbowView.amount_at(SEED, end - 1.0, _config)).is_equal(0.0)
	assert_float(RainbowView.amount_at(SEED, end + 0.3, _config)).is_greater(0.9)
	assert_float(RainbowView.amount_at(SEED, end + RainbowView.AFTER_RAIN_H + 0.1, _config)).is_equal(0.0)


func test_never_on_a_dry_day() -> void:
	var days := _days()
	assert_int(days[1]).is_greater_equal(0)
	for step: int in 48:
		assert_float(RainbowView.amount_at(SEED, days[1] * 24.0 + step * 0.5, _config)).is_equal(0.0)


func test_the_ring_circles_the_point_opposite_the_sun() -> void:
	var eye := Vector3(100.0, 40.0, -50.0)
	var toward_sun := Vector3(0.6, 0.35, 0.2).normalized()
	var found: Variant = RainbowView.place(eye, toward_sun)
	assert_bool(found is Transform3D).is_true()
	var ring: Transform3D = found
	var away := -toward_sun
	assert_float((ring.origin - eye).normalized().dot(away)).is_greater(0.999)
	# o raio do anel visto do olho é de 42 graus
	var edge := ring * Vector3(1.0, 0.0, 0.0)
	var angle := rad_to_deg((edge - eye).angle_to(away))
	assert_float(angle).is_equal_approx(RainbowView.RAINBOW_DEG, 0.1)
	# o alto do arco fica acima do olho (o sol está baixo)
	var top := ring * Vector3(0.0, 1.0, 0.0)
	assert_float(top.y).is_greater(eye.y)


func test_no_ring_with_the_sun_down_or_too_high() -> void:
	assert_object(RainbowView.place(Vector3.ZERO, Vector3(0.5, -0.1, 0.3).normalized())).is_null()
	assert_object(RainbowView.place(Vector3.ZERO, Vector3(0.2, 0.9, 0.1).normalized())).is_null()
