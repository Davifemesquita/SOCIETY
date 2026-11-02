extends GdUnitTestSuite
## Rebentação fina (Fase 281): a espuma por profundidade do Ocean presa a shore_line_m da linha d'água (antes cobria a praia
## rasa inteira) e as bandas que chegam na praia em linhas finas e quebradas; o shader compila com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func test_the_shader_has_the_surf_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"shore_line_m", &"band_sharpness"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_depth_foam_hugs_the_waterline_and_the_bands_are_thin() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	# a espuma do Ocean (SHORE_FOAM) cortada pela distância à linha d'água
	var shore_block := code.find("#ifdef SHORE_FOAM\n\tfloat z_diff")
	assert_int(shore_block).is_greater(0)
	var clamp_at := code.find("shore_alpha *= 1.0 - smoothstep(shore_line_m * 0.4, shore_line_m, from_line)")
	assert_int(clamp_at).is_greater(shore_block)
	assert_str(code).contains("uniform float shore_line_m = 3.0;")
	# as bandas: mais finas que as de antes (0,8) e quebradas pela textura
	assert_str(code).contains("smoothstep(band_sharpness, 1.0, sin(coast_phase(")
	assert_str(code).contains("band *= smoothstep(0.3, 0.6, foam_tex.a);")
	var sharpness := code.substr(code.find("uniform float band_sharpness = ") + 31, 4).to_float()
	assert_float(sharpness).is_greater(0.8)
