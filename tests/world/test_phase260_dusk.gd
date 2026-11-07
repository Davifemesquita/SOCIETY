extends GdUnitTestSuite
## Hora dourada (Fase 260): o sol perto do horizonte em ouro claro (o laranja-avermelhado do Sky3D deixava o chão cor de tijolo
## escuro), a exposição subindo com o sol baixo e voltando à do dia e à da noite, e a luz própria das folhas pela altura do sol.


func test_the_exposure_rises_with_the_sun_low() -> void:
	var config := GameConfig.get_default()
	assert_array(Array(config.validate())).is_empty()
	# sol alto: a exposição de sempre; de noite, a da Fase 263
	assert_float(GraphicsQuality.dusk_factor(config, 0.8)).is_equal_approx(1.0, 0.0001)
	assert_float(GraphicsQuality.dusk_factor(config, -0.3)).is_equal_approx(1.0 + config.night_exposure_boost, 0.0001)
	# no horizonte, o máximo
	assert_float(GraphicsQuality.dusk_factor(config, 0.02)).is_equal_approx(1.0 + config.dusk_exposure_boost, 0.0001)
	# descendo do horizonte para o alto, sem degrau
	var last := INF
	for step: int in range(0, 46):
		var factor := GraphicsQuality.dusk_factor(config, 0.02 + step * 0.01)
		assert_float(factor).is_less_equal(last)
		last = factor


func test_the_horizon_sun_is_light_gold() -> void:
	var config := GameConfig.get_default()
	var sky3d_default := Color(0.98, 0.523, 0.294)
	assert_float(config.sun_horizon_color.g).is_greater(sky3d_default.g + 0.15)
	assert_float(config.sun_horizon_color.b).is_greater(sky3d_default.b + 0.15)
	var sky: SkyAdapter = auto_free(SkyAdapter.new())
	add_child(sky)
	sky.setup(config, true)
	var dome: Node = sky.get_child(0).get(&"sky")
	var color: Color = dome.get(&"sun_horizon_light_color")
	assert_bool(color.is_equal_approx(config.sun_horizon_color)).is_true()


func test_the_frame_follows_the_sun() -> void:
	var config := GameConfig.get_default()
	var sky: SkyAdapter = auto_free(SkyAdapter.new())
	add_child(sky)
	sky.setup(config, false)
	var graphics: GraphicsQuality = auto_free(GraphicsQuality.new())
	add_child(graphics)
	graphics.setup(config, sky, null, null, null)
	var base := Environment.new().tonemap_exposure if Settings.period_look else config.vivid_exposure
	graphics.follow_sun(0.05)
	assert_float(sky.environment().tonemap_exposure).is_equal_approx(base * GraphicsQuality.dusk_factor(config, 0.05), 0.0001)
	graphics.follow_sun(0.9)
	assert_float(sky.environment().tonemap_exposure).is_equal_approx(base, 0.0001)
	# o laboratório de cor desliga
	graphics.sun_exposure = false
	graphics.follow_sun(0.05)
	assert_float(sky.environment().tonemap_exposure).is_equal_approx(base, 0.0001)
