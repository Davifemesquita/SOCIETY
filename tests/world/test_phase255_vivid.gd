extends GdUnitTestSuite
## Ar limpo e tom vivo (Fase 255): menos névoa, AgX com mais contraste, saturação e exposição com a "Cor de época" desligada,
## e o sol do Sky3D quente e mais forte.


func test_the_haze_is_thin() -> void:
	var config := GameConfig.get_default()
	# antes: 0,0018 na volumétrica e 0,0002 no domo do Sky3D
	assert_float(config.volumetric_fog_density).is_less_equal(0.0005)
	# (Fase 333: a do domo é mais densa, mas só depois de 200 m: perto, o ar segue limpo)
	assert_bool(config.sky_fog_density <= 0.0001 or config.sky_fog_start_m >= 200.0).is_true()
	assert_array(Array(config.validate())).is_empty()


func test_the_vivid_grade_is_the_default() -> void:
	var config := GameConfig.get_default()
	var environment := Environment.new()
	GraphicsQuality.apply_to_environment(environment, config.graphics_presets[2], config)
	assert_int(environment.tonemap_mode).is_equal(Environment.TONE_MAPPER_AGX)
	assert_bool(environment.adjustment_enabled).is_true()
	assert_object(environment.adjustment_color_correction).is_null()
	assert_float(environment.adjustment_saturation).is_equal_approx(config.vivid_saturation, 0.0001)
	assert_float(environment.tonemap_exposure).is_equal_approx(config.vivid_exposure, 0.0001)
	assert_float(environment.tonemap_agx_contrast).is_equal_approx(config.vivid_agx_contrast, 0.0001)
	# mais vivo que o motor: mais saturação, contraste e exposição
	var engine := Environment.new()
	assert_float(config.vivid_saturation).is_greater(1.0)
	assert_float(config.vivid_exposure).is_greater(engine.tonemap_exposure)
	assert_float(config.vivid_agx_contrast).is_greater(engine.tonemap_agx_contrast)


func test_the_period_look_keeps_its_own_grade() -> void:
	var config := GameConfig.get_default()
	var environment := Environment.new()
	GraphicsQuality.apply_to_environment(environment, config.graphics_presets[2], config, true)
	assert_object(environment.adjustment_color_correction).is_same(PeriodGrade.texture())
	assert_float(environment.adjustment_saturation).is_equal_approx(1.0, 0.0001)
	assert_float(environment.tonemap_exposure).is_equal_approx(Environment.new().tonemap_exposure, 0.0001)
	assert_float(environment.tonemap_agx_contrast).is_equal_approx(config.period_agx_contrast, 0.0001)


func test_the_sun_is_warm_and_stronger() -> void:
	var config := GameConfig.get_default()
	assert_float(config.sun_light_energy).is_greater(1.0)
	# branco quente: o vermelho cheio e o azul abaixo do verde
	assert_float(config.sun_light_color.r).is_equal_approx(1.0, 0.0001)
	assert_float(config.sun_light_color.b).is_less(config.sun_light_color.g)
	var sky: SkyAdapter = auto_free(SkyAdapter.new())
	add_child(sky)
	sky.setup(config, true)
	var sky3d := sky.get_child(0)
	var dome: Node = sky3d.get(&"sky")
	var color: Color = dome.get(&"sun_light_color")
	assert_bool(color.is_equal_approx(config.sun_light_color)).is_true()
	var energy: float = sky3d.get(&"sun_energy")
	assert_float(energy).is_equal_approx(config.sun_light_energy, 0.0001)
	# ao meio-dia o sol tem a cor quente (perto do horizonte o Sky3D a puxa para o laranja)
	sky.set_hour(12.0)
	assert_float(sky.sun().light_color.b).is_less(sky.sun().light_color.r)
