extends GdUnitTestSuite
## Sombra funda (Fase 330): o sol do dia fica na frente e de lado da câmera padrão (que olha para −z), não às costas dela, e a
## sombra das casas e das árvores se vê; e a luz ambiente fica mais fraca de dia, com o sol alto, e volta inteira com ele baixo
## e de noite.


func _sky(config: GameConfig, use_sky3d: bool) -> SkyAdapter:
	var sky: SkyAdapter = auto_free(SkyAdapter.new())
	add_child(sky)
	sky.setup(config, use_sky3d)
	return sky


## A direção (no chão) para onde fica o sol.
func _toward_sun(sky: SkyAdapter) -> Vector2:
	var z := sky.sun().global_basis.z
	return Vector2(z.x, z.z).normalized()


func test_the_morning_sun_is_in_front_of_the_default_camera() -> void:
	var config := GameConfig.get_default()
	assert_array(Array(config.validate())).is_empty()
	var sky := _sky(config, true)
	sky.set_hour(10.5)
	var turned := _toward_sun(sky)
	# a câmera padrão fica em +z olhando para −z: o sol na frente dela
	assert_float(turned.y).is_less(-0.3)
	# sem o giro ele ficava às costas
	var plain: GameConfig = config.duplicate()
	plain.sun_azimuth_offset_deg = 0.0
	var plain_sky := _sky(plain, true)
	plain_sky.set_hour(10.5)
	var behind := _toward_sun(plain_sky)
	assert_float(behind.y).is_greater(0.3)
	# o giro é o da configuração
	assert_float(rad_to_deg(absf(angle_difference(behind.angle(), turned.angle())))).is_equal_approx(config.sun_azimuth_offset_deg, 2.0)


func test_the_turn_does_not_add_up_hour_after_hour() -> void:
	var config := GameConfig.get_default()
	var sky := _sky(config, true)
	sky.set_hour(10.5)
	var first := _toward_sun(sky)
	for hour: float in [11.0, 14.0, 9.0, 10.5]:
		sky.set_hour(hour)
	assert_float(_toward_sun(sky).distance_to(first)).is_less(0.01)
	sky.refresh()
	assert_float(_toward_sun(sky).distance_to(first)).is_less(0.01)


func test_the_simple_sky_turns_too() -> void:
	var config := GameConfig.get_default()
	var sky := _sky(config, false)
	sky.set_hour(12.5)
	assert_float(_toward_sun(sky).y).is_less(-0.3)


func test_the_ambient_light_is_weaker_with_the_sun_high() -> void:
	var config := GameConfig.get_default()
	assert_float(config.ambient_day_energy).is_less(1.0)
	assert_float(GraphicsQuality.ambient_factor(config, 0.9)).is_equal_approx(config.ambient_fill_energy * config.ambient_day_energy, 0.0001)
	assert_float(GraphicsQuality.ambient_factor(config, 0.0)).is_equal_approx(config.ambient_fill_energy, 0.0001)
	assert_float(GraphicsQuality.ambient_factor(config, -0.4)).is_equal_approx(config.ambient_fill_energy, 0.0001)
	# do sol baixo para o alto, sem degrau
	var last := INF
	for step: int in 60:
		var factor := GraphicsQuality.ambient_factor(config, step * 0.015)
		assert_float(factor).is_less_equal(last + 0.0001)
		last = factor
	var sky := _sky(config, false)
	var graphics: GraphicsQuality = auto_free(GraphicsQuality.new())
	add_child(graphics)
	graphics.setup(config, sky, null, null, null)
	graphics.follow_sun(0.9)
	assert_float(sky.environment().ambient_light_energy).is_equal_approx(GraphicsQuality.ambient_factor(config, 0.9), 0.0001)
	graphics.follow_sun(-0.3)
	assert_float(sky.environment().ambient_light_energy).is_equal_approx(config.ambient_fill_energy, 0.0001)


## Com o sol na frente, o mar de longe não pode virar manchas brancas: a rugosidade sobe com a distância e a cintilação usa o
## hash sem seno (o fract(sin(...)) juntava os pontos em bolhas com as coordenadas do arquipélago).
func test_the_far_sea_spreads_the_sun_reflection() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/water.gdshader")
	assert_int(code.find("uniform float far_sea_roughness")).is_greater(0)
	assert_int(code.find("ROUGHNESS = mix(ROUGHNESS, far_sea_roughness")).is_greater(0)
	var glint := code.find("float sparkle")
	assert_int(glint).is_greater(0)
	assert_str(code.substr(glint, 200)).contains("reef_hash")
	assert_str(code.substr(glint, 200)).not_contains("sin(")
