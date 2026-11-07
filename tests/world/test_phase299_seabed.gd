extends GdUnitTestSuite
## Fundo à vista no raso (Fase 299): nas temperadas, o terreno debaixo d'água ganha ondulações paralelas à costa, manchas de alga
## e pedrinhas até seabed_detail_m da linha d'água (a TerrainView liga seabed_detail só nelas), e a água rasa perde parte da
## cobertura até clear_depth_m de água, para o fundo aparecer; os shaders compilam com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"
const WATER := "res://shaders/water.gdshader"


func test_the_temperate_seabed_has_ripples_weed_and_stones() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var block := code.find("if (seabed_detail > 0.0 && under > 0.0) {")
	assert_int(block).is_greater(code.find("ground_n = mix(ground_n, sand_n, under);"))
	var body := code.substr(block, 2000)
	for line: String in ["float ripple = sin(shore * 6.2831853 / seabed_ripple_m + warp * 3.0);",
			"ground_a.rgb = mix(ground_a.rgb, seabed_weed_color, weed * 0.85 * zone);",
			"float stone_pick = strata_hash(stone_cell);"]:
		assert_str(body).override_failure_message(line).contains(line)
	# a TerrainView liga só nas temperadas (junto do cascalho e dos seixos)
	var view := FileAccess.get_file_as_string("res://world/terrain/terrain_view.gd")
	var temperate := view.find("material.set_shader_parameter(&\"pebble_beach\", 1.0)")
	assert_int(view.find("material.set_shader_parameter(&\"seabed_detail\", 1.0)")).is_between(temperate, temperate + 200)


func test_shallow_temperate_water_is_clearer() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	for line: String in ["clear = clear_strength * (1.0 - tropic) * (1.0 - smoothstep(clear_depth_m * 0.4, clear_depth_m, z_diff_refracted));",
			"color_shallow.a * (1.0 - clear)",
			"shelf_color.a * shelf * (1.0 - clear)"]:
		assert_str(code).override_failure_message(line).contains(line)


func _uniforms(path: String) -> Array[StringName]:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	return names


func test_the_shaders_compile_with_the_new_uniforms() -> void:
	var terrain := _uniforms(TERRAIN)
	var water := _uniforms(WATER)
	if DisplayServer.get_name() == "headless":
		return
	assert_array(terrain).is_not_empty()
	assert_array(water).is_not_empty()
	for name: StringName in [&"seabed_detail", &"seabed_detail_m", &"seabed_ripple_m", &"seabed_patch_m", &"seabed_weed_color", &"seabed_stone_color"]:
		assert_bool(terrain.has(name)).is_true()
	for name: StringName in [&"clear_depth_m", &"clear_strength"]:
		assert_bool(water.has(name)).is_true()
