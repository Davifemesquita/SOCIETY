extends GdUnitTestSuite
## Chão da mata (Fase 306): no miolo da mata o chão de folhas e agulhas escurece e ganha manchas de musgo, depois da mistura da
## grama com a mata (a beira fica em transição pelo peso dela); o shader do terreno compila com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_deep_forest_floor_is_dark_and_mossy() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var block := code.find("if (forest_floor > 0.0) {")
	assert_int(block).is_greater(code.find("vec4 ground_n = mix(grass_n, forest_n, forest);"))
	var body := code.substr(block, 800)
	for line: String in ["float deep = smoothstep(0.6, 1.0, kinds.g + edge * 0.6) * forest * forest_floor;",
			"vec3 litter = ground_a.rgb * floor_dark;",
			"ground_a.rgb = mix(ground_a.rgb, mix(litter, mossy, moss), deep);"]:
		assert_str(body).override_failure_message(line).contains(line)


func test_the_terrain_shader_compiles_with_the_new_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"forest_floor", &"floor_dark", &"floor_moss_color", &"floor_moss_m", &"floor_moss_share"]:
		assert_bool(names.has(name)).override_failure_message(name).is_true()
