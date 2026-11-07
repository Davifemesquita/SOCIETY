extends GdUnitTestSuite
## Água de noite (Fase 282): as cores postas da água (fundo, raso, plataforma, recife) escurecem pelo night_light para o fator
## night_water, mais azul que vermelho; o shader compila com o uniforme novo (com tela).

const WATER := "res://shaders/water.gdshader"


func test_the_shader_has_the_night_water_uniform() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	assert_bool(names.has(&"night_water")).is_true()


func test_every_painted_water_color_follows_the_night() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	assert_str(code).contains("vec3 water_light = mix(vec3(1.0), night_water, night_light);")
	for painted: String in ["color_shallow.rgb * water_light", "deep_color.rgb * water_light", "shelf_color.rgb * water_light",
			"reef_color.rgb * water_light"]:
		assert_str(code).override_failure_message(painted).contains(painted)
	# o fator de noite é escuro e puxa para o azul
	var at := code.find("uniform vec3 night_water = vec3(")
	assert_int(at).is_greater(0)
	var parts := code.substr(at + 32, 20).split(")")[0].split(",")
	var night := Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	assert_float(night.z).is_greater(night.x)
	assert_float(night.length()).is_less(0.6)
