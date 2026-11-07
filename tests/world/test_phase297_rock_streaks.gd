extends GdUnitTestSuite
## Fiapos de espuma nas pedras (Fase 297): espuma comprida ao longo do vento e fina de través, andando com ele, perto da costa, do
## lado de baixo do vento e só na água funda junto da pedra (na praia rasa, nada), somada por max à espuma de antes; o shader
## compila com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func _uniform(code: String, name: String) -> float:
	var at := code.find("uniform float %s = " % name)
	return code.substr(at + name.length() + 17, 8).split(";")[0].to_float()


func test_streaks_trail_downwind_from_deep_rocky_coast() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var block := code.find("#ifdef SHORE_FOAM\n\tfloat z_diff")
	var streak := code.find("// Fase 297: os fiapos levados das pedras pelo vento", block)
	assert_int(streak).is_greater(block)
	# depois do anel das pedras (Fase 293) e somados por max
	assert_int(streak).is_greater(code.find("shore_alpha = max(shore_alpha, ring);", block))
	var body := code.substr(streak, 2200)
	for line: String in ["- TIME * float(!freeze_time) * streak_drift_m_s",
			"/ vec2(streak_length_m, streak_width_m)",
			"coast_at(world_coordinates.xz - streak_wind * streak_reach_m * 0.5)",
			"smoothstep(streak_deep_m, streak_deep_m * 2.0, z_diff)",
			"(1.0 - channel)",
			"shore_alpha = max(shore_alpha, streak);"]:
		assert_str(body).override_failure_message(line).contains(line)
	# fiapos: muito mais compridos que largos, e a praia rasa (−1,2 m, vista de lado ~1,7 m) fica de fora
	assert_float(_uniform(code, "streak_length_m") / _uniform(code, "streak_width_m")).is_greater(5.0)
	assert_float(_uniform(code, "streak_deep_m")).is_greater(1.8)


func test_the_shader_compiles_with_the_streak_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"streak_strength", &"streak_length_m", &"streak_width_m", &"streak_drift_m_s", &"streak_reach_m", &"streak_deep_m"]:
		assert_bool(names.has(name)).is_true()
