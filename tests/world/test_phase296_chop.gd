extends GdUnitTestSuite
## Água picada de perto (Fase 296): quatro trens de ondinhas curtas cruzando em volta do vento, com a fase torcida por um ruído,
## só na normal, sumindo com a distância da câmera; o shader compila com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func test_the_chop_bends_the_normal_only_near_the_camera() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var fragment := code.find("void fragment()")
	var chop := code.find("float chop_near = 1.0 - smoothstep(chop_near_m, chop_far_m, length(VERTEX));", fragment)
	assert_int(chop).is_greater(fragment)
	# depois do marulho e antes do Fresnel e do brilho (que seguem a normal nova)
	assert_int(chop).is_greater(code.find("slope *= swell_strength", fragment))
	assert_int(chop).is_less(code.find("float fresnel_factor", fragment))
	for line: String in ["float twist = reef_noise(world_coordinates.xz / 6.0) * 9.0;",
			"for (int i = 0; i < 4; i++) {",
			"NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(chop.x, 0.0, chop.y, 0.0)).xyz);"]:
		assert_str(code.substr(chop, 2000)).override_failure_message(line).contains(line)
	# os vértices não mudam: nada de VERTEX += no bloco
	assert_str(code.substr(chop, 1500)).not_contains("VERTEX +=")


func test_the_shader_compiles_with_the_chop_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"chop_strength", &"chop_lengths_m", &"chop_speed", &"chop_near_m", &"chop_far_m"]:
		assert_bool(names.has(name)).is_true()
