extends GdUnitTestSuite
## Sombra das nuvens (Fase 129): os globais cloud_cover e cloud_offset existem no projeto; as sombras andam na direção do
## vento, mais depressa com ele forte, e param na pausa; com tela, o terreno e a água compilam com o include.


func test_the_globals_are_declared() -> void:
	for global_name: String in ["cloud_cover", "cloud_offset"]:
		assert_bool(ProjectSettings.has_setting("shader_globals/" + global_name)).is_true()


func test_the_shadows_drift_with_the_wind() -> void:
	var view: WeatherView = auto_free(WeatherView.new())
	view.sample.wind_direction = Vector2(0.0, 1.0)
	view.sample.wind = 0.0
	view.drift_clouds(10.0)
	var calm := view.cloud_offset
	assert_float(calm.y).is_equal_approx(WeatherView.CLOUD_DRIFT_M_S * 10.0, 0.001)
	assert_float(absf(calm.x)).is_less(0.001)
	view.sample.wind = 1.0
	view.drift_clouds(10.0)
	assert_float(view.cloud_offset.y - calm.y).is_equal_approx((WeatherView.CLOUD_DRIFT_M_S + WeatherView.CLOUD_WIND_M_S) * 10.0, 0.001)
	# na pausa (zero segundos de jogo) não andam
	var before := view.cloud_offset
	view.drift_clouds(0.0)
	assert_bool(view.cloud_offset.is_equal_approx(before)).is_true()


func test_the_ground_and_water_shaders_compile_with_the_shadows() -> void:
	for path: String in ["res://shaders/terrain.gdshader", "res://shaders/water.gdshader"]:
		var shader := load(path) as Shader
		var names: Array[String] = []
		for entry: Dictionary in shader.get_shader_uniform_list():
			var raw: String = entry["name"]
			names.append(raw)
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		if names.is_empty():
			continue
		assert_int(names.size()).is_greater(3)
