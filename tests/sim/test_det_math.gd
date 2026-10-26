extends GdUnitTestSuite
## DetMath (achado pelo CI, regravado na Fase 47): seno, cosseno, potência, logaritmo e exponencial só com operações que
## o IEEE 754 arredonda igual em toda máquina, para o terreno v2 dar a mesma assinatura no Windows e no Linux. Aqui:
## a precisão contra as funções do motor e a tabela da subida do interior.


func test_sin_and_cos_match_the_engine() -> void:
	var worst := 0.0
	var at := 0.0
	for k: int in 2001:
		var angle := -20.0 + k * 0.02
		var turn := DetMath.sin_cos(angle)
		var error := maxf(absf(turn.x - cos(angle)), absf(turn.y - sin(angle)))
		if error > worst:
			worst = error
			at = angle
	# o Vector2 guarda float de 32 bits: a precisão dele (o arredondamento de 64 para 32 bits é exato e igual em toda máquina)
	assert_float(worst).override_failure_message("erro %s em %s" % [str(worst), str(at)]).is_less(0.0000001)
	# os quadrantes exatos
	assert_vector(DetMath.sin_cos(0.0)).is_equal(Vector2(1.0, 0.0))
	assert_float(DetMath.sin_cos(PI * 0.5).y).is_equal(1.0)
	assert_float(DetMath.sin_cos(PI).x).is_equal(-1.0)


func test_rotate_matches_the_engine() -> void:
	var point := Vector2(0.37, -1.2)
	for angle: float in [0.0, 0.4, 1.9, -2.7, 3.1]:
		var turned := DetMath.rotate(point, DetMath.sin_cos(angle))
		assert_float(turned.distance_to(point.rotated(angle))).is_less(0.000001)


func test_power_log_and_exp_match_the_engine() -> void:
	for x: float in [0.0001, 0.01, 0.2, 0.5, 0.7071, 0.9, 0.999, 1.0, 1.5, 7.3, 1024.0]:
		assert_float(DetMath.ln(x)).override_failure_message("ln %f" % x).is_equal_approx(log(x), 0.000000000001)
		for y: float in [0.25, 0.9, 1.0, 2.5]:
			var expected := pow(x, y)
			assert_float(DetMath.power(x, y)).override_failure_message("%f^%f" % [x, y]) \
					.is_equal_approx(expected, expected * 0.000000000001 + 0.000000000000001)
	for t: float in [-30.0, -1.0, -0.3, 0.0, 0.3, 1.0, 12.0]:
		var expected := exp(t)
		assert_float(DetMath.exp_of(t)).is_equal_approx(expected, expected * 0.000000000001)
	assert_float(DetMath.power(0.0, 0.9)).is_equal(0.0)


func test_the_inland_rise_table_follows_the_power() -> void:
	var worst := 0.0
	for k: int in 1001:
		var core := k / 1000.0
		worst = maxf(worst, absf(ArchipelagoGenerator._rise(core, 0.9) - pow(core, 0.9)))
	# a interpolação entre 1.025 pontos: perto do zero a curva é mais íngreme, o resto fica muito abaixo disso
	assert_float(worst).is_less(0.001)
	assert_float(ArchipelagoGenerator._rise(1.0, 0.9)).is_equal(1.0)
	assert_float(ArchipelagoGenerator._rise(-0.5, 0.9)).is_equal(0.0)
