extends GdUnitTestSuite
## Noite azul (Fase 263): com o sol abaixo do horizonte a exposição fica em 1 + night_exposure_boost vezes a do dia (a noite
## ficava quase preta fora das janelas), sem degrau na passagem do fim da tarde para a noite.


func test_the_night_is_brighter_than_before() -> void:
	var config := GameConfig.get_default()
	assert_array(Array(config.validate())).is_empty()
	assert_float(config.night_exposure_boost).is_between(0.2, 0.8)
	for height: float in [-0.2, -0.5, -0.9]:
		assert_float(GraphicsQuality.dusk_factor(config, height)).is_equal_approx(1.0 + config.night_exposure_boost, 0.0001)
	# a noite fica abaixo do fim da tarde: as janelas e os lampiões seguem mais claros que o resto
	assert_float(config.night_exposure_boost).is_less(config.dusk_exposure_boost)


func test_no_step_from_dusk_to_night() -> void:
	var config := GameConfig.get_default()
	var last := GraphicsQuality.dusk_factor(config, 0.02)
	for step: int in range(1, 41):
		var factor := GraphicsQuality.dusk_factor(config, 0.02 - step * 0.005)
		# descendo do horizonte para a noite, sem degrau
		assert_float(absf(factor - last)).is_less(0.08)
		assert_float(factor).is_less_equal(last + 0.0001)
		last = factor
