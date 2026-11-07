extends GdUnitTestSuite
## Onda de perto (Fase 356): três trens de ondas médias entre o marulho e o picado, na normal, só de perto, com a crista mais clara no fim;
## o shader compila (com tela).

const WATER := "res://shaders/water.gdshader"


func test_the_mid_waves_sit_between_swell_and_chop() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var waves := code.find("// Society (Fase 356): a onda de perto, entre o marulho e o picado")
	assert_int(waves).is_greater(code.find("if (swell_strength > 0.0) {"))
	assert_int(waves).is_less(code.find("if (chop_strength > 0.0 && chop_near > 0.0) {"))
	assert_int(code.find("EMISSION *= 1.0 + mid_crest * wave_crest_light;")).is_greater(code.find("glint * glint_strength * cliff_dark;"))


func test_the_shader_compiles_with_the_waves() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	for wanted: StringName in [&"wave_lengths_m", &"wave_slopes", &"wave_crest_light", &"wave_far_m"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()


func test_one_train_and_soft_glints() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	# um trem só (os três cruzados faziam um favo de bolinhas) e a crista pesada pela inclinação de cada trem
	assert_str(code).contains("uniform vec3 wave_slopes = vec3(0.11, 0.0, 0.0);")
	assert_str(code).contains("wave_height += sin(phase) * wave_slopes[i] / max(wave_slopes.x, 0.001);")
	# a cintilação mais fraca, agora que o sol fica na frente da câmera
	assert_str(code).contains("uniform float glint_strength = 1.0;")
