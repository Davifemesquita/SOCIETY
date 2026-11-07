extends GdUnitTestSuite
## Sujeira nas paredes (Fase 302): só nas células de parede viradas para o lado, o respingo de terra no pé (borda de cima
## irregular, na cor de terra) e os escorridos de chuva verticais, fora do vidro; o shader compila com os uniformes novos (com tela).

const KIT := "res://shaders/building_kit.gdshader"


func test_walls_get_splash_and_streaks() -> void:
	var code := FileAccess.get_file_as_string(KIT)
	var block := code.find("// Fase 302: o respingo de terra no pé da parede e os escorridos de chuva")
	assert_int(block).is_greater(0)
	# no ramo de fora do vidro, depois da sujeira de antes e antes do musgo da Fase 39
	assert_int(block).is_greater(code.find("color *= 1.0 - (1.0 - smoothstep(0.0, grime_height, above)) * grime_strength;"))
	assert_int(block).is_less(code.find("float moss = (1.0 - smoothstep(0.0, moss_height, above))"))
	assert_str(code.substr(block - 60, 60)).contains("if (wall && abs(world_normal.y) < 0.5) {")
	var body := code.substr(block, 900)
	for line: String in ["float splash_top = splash_height_m * (0.55 + 0.9 * moss_noise(vec2(wall_along * 1.3, 2.0)));",
			"color = mix(color, splash_color.rgb * (0.75 + 0.5 * kit_luma), splash * splash_strength);",
			"wall_streak_strength"]:
		assert_str(body).override_failure_message(line).contains(line)


func test_the_shader_compiles_with_the_grime_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(KIT) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"splash_color", &"splash_height_m", &"splash_strength", &"wall_streak_strength"]:
		assert_bool(names.has(name)).is_true()
