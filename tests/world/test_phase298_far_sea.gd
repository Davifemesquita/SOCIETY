extends GdUnitTestSuite
## Mar escuro de longe (Fase 298): a cor do fundo escurece com a distância da câmera e o reflexo do céu cai (o céu claro no
## ângulo raso deixava o mar leitoso); o shader compila com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func _uniform(code: String, name: String) -> float:
	var at := code.find("uniform float %s = " % name)
	return code.substr(at + name.length() + 17, 8).split(";")[0].to_float()


func test_the_far_sea_darkens_and_reflects_more() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var deep := code.find("vec4 deep_color = mix(cold_deep, color_deep, tropic);")
	assert_int(deep).is_greater(0)
	var body := code.substr(deep, 400)
	assert_str(body).contains("float far_sea = smoothstep(far_sea_from_m, far_sea_to_m, length(VERTEX));")
	assert_str(body).contains("deep_color.rgb *= mix(1.0, far_sea_dark, far_sea);")
	# antes de virar a cor da tela
	assert_int(code.find("deep_color.rgb *= mix(1.0, far_sea_dark", deep)).is_less(code.find("vec3 deep_screen_color", deep))
	assert_str(code).contains("SPECULAR *= mix(1.0, far_sea_specular, smoothstep(far_sea_from_m, far_sea_to_m, length(VERTEX)));")
	assert_float(_uniform(code, "far_sea_from_m")).is_less(_uniform(code, "far_sea_to_m"))
	assert_float(_uniform(code, "far_sea_dark")).is_between(0.4, 0.95)
	assert_float(_uniform(code, "far_sea_specular")).is_between(0.2, 0.95)


func test_the_shader_compiles_with_the_far_sea_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"far_sea_from_m", &"far_sea_to_m", &"far_sea_dark", &"far_sea_specular"]:
		assert_bool(names.has(name)).is_true()
