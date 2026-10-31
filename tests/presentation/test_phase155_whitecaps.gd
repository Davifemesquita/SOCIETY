extends GdUnitTestSuite
## Carneirinhos (Fase 155): o global sea_whitecaps existe no projeto; a quantidade sobe com a força do vento, nada com o ar
## quase parado e cheia no vento de chuva; com tela, o shader da água compila com os uniformes novos.


func test_the_global_is_declared() -> void:
	assert_bool(ProjectSettings.has_setting("shader_globals/sea_whitecaps")).is_true()


func test_more_wind_more_whitecaps() -> void:
	assert_float(WeatherView.whitecaps_of(0.0)).is_equal(0.0)
	assert_float(WeatherView.whitecaps_of(WeatherView.WHITECAP_CALM)).is_equal(0.0)
	var config := GameConfig.new()
	var clear := WeatherView.whitecaps_of(config.weather_wind_clear)
	var cloudy := WeatherView.whitecaps_of(config.weather_wind_cloudy)
	var rain := WeatherView.whitecaps_of(config.weather_wind_rain)
	assert_float(clear).is_greater(0.0)
	assert_float(cloudy).is_greater(clear)
	assert_float(rain).is_greater(cloudy)
	assert_float(rain).is_less_equal(1.0)
	assert_float(WeatherView.whitecaps_of(2.0)).is_equal(1.0)


func test_the_water_shader_has_the_whitecap_uniforms() -> void:
	var shader := load("res://shaders/water.gdshader") as Shader
	var names: Array[StringName] = []
	for entry: Dictionary in shader.get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"whitecap_cell_m", &"whitecap_period_s", &"whitecap_share", &"whitecap_open_m"]:
		assert_bool(names.has(uniform_name)).is_true()
